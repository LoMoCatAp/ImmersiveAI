import { MessageRecord, MessageStatus, ConversationRecord } from '../model/ChatModels';
import { ChatMessage, StreamDelta, ProtocolAdapter, StreamRequestOptions } from '../model/ProtocolModels';
import { ProviderRecord } from '../model/ProviderModels';
import { ChatRepository } from '../data/ChatRepository';
import { StreamingChatService } from '../service/StreamingChatService';
import { AssetCredentialStore } from '../data/AssetCredentialStore';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class ChatViewModel {
  messages: MessageRecord[] = [];
  isGenerating: boolean = false;
  statusText: string = '可以开始聊天';
  errorMessage: string = '';
  currentConversationId: string = '';
  private repository: ChatRepository;
  private service: StreamingChatService;
  private credentials: AssetCredentialStore;
  private lastProvider: ProviderRecord | undefined = undefined;
  private lastAdapter: ProtocolAdapter | undefined = undefined;
  private stateObserver: () => void = (): void => {};
  private streamRevision: number = 0;
  private renderedAssistantContent: Record<string, string> = {};
  private renderedAssistantReasoning: Record<string, string> = {};

  constructor(repository: ChatRepository, service: StreamingChatService, credentials: AssetCredentialStore) {
    this.repository = repository;
    this.service = service;
    this.credentials = credentials;
  }

  setStateObserver(observer: () => void): void {
    this.stateObserver = observer;
  }

  private notifyStateChanged(): void {
    this.streamRevision += 1;
    AppStorage.setOrCreate('chat_stream_revision', this.streamRevision);
    this.stateObserver();
  }

  private publishAssistantContent(id: string, content: string): void {
    this.renderedAssistantContent[id] = content;
    AppStorage.setOrCreate('chat_rendered_assistant_content', JSON.stringify(this.renderedAssistantContent));
  }

  private publishAssistantReasoning(id: string, reasoning: string): void {
    this.renderedAssistantReasoning[id] = reasoning;
    AppStorage.setOrCreate('chat_rendered_assistant_reasoning', JSON.stringify(this.renderedAssistantReasoning));
  }

  async load(conversationId: string): Promise<void> {
    if (this.isGenerating && this.currentConversationId !== conversationId) this.stop();
    this.currentConversationId = conversationId;
    this.messages = await this.repository.messagesFor(conversationId);
    if (!this.isGenerating) {
      for (let index = 0; index < this.messages.length; index++) {
        const message: MessageRecord = this.messages[index];
        if (message.status === MessageStatus.Generating) {
          message.status = MessageStatus.Stopped;
          message.errorSummary = '生成已中断';
          message.updatedAt = Date.now();
          await this.repository.saveMessage(message);
        }
      }
    }
    this.notifyStateChanged();
  }

  async messagesFor(conversationId: string): Promise<MessageRecord[]> {
    return this.repository.messagesFor(conversationId);
  }

  async newConversation(provider: ProviderRecord): Promise<string> {
    const now: number = Date.now();
    const id: string = `${now}-${Math.floor(Math.random() * 1000000)}`;
    const item: ConversationRecord = {
      id,
      title: '新会话',
      providerId: provider.id,
      modelName: provider.modelName,
      status: MessageStatus.Completed,
      createdAt: now,
      updatedAt: now
    };
    await this.repository.saveConversation(item);
    AppStorage.setOrCreate('history_revision', now);
    AppStorage.set('history_revision', now);
    await this.load(id);
    return id;
  }

  stop(): void {
    this.service.stop();
    this.isGenerating = false;
    this.statusText = '已停止生成';
    this.notifyStateChanged();
  }

  async retry(): Promise<void> {
    if (this.isGenerating) {
      this.statusText = '正在生成，请稍候';
      return;
    }
    if (this.lastProvider === undefined || this.lastAdapter === undefined || this.messages.length < 2) {
      this.statusText = '暂无可重试的消息';
      return;
    }
    const lastUser: MessageRecord | undefined = this.messages.slice().reverse().find((item: MessageRecord): boolean => item.role === 'user');
    if (lastUser === undefined) return;
    const credential: string | undefined = await this.credentials.get(this.lastProvider.credentialAlias);
    if (credential === undefined) {
      this.statusText = '密钥不可用，请检查供应商设置';
      return;
    }
    await this.send(this.lastProvider, this.currentConversationId, credential, this.lastAdapter, lastUser.content);
  }

  private conversationTitle(text: string): string {
    const compact: string = text.replace(new RegExp('\\s+', 'g'), ' ').trim();
    return compact.length > 24 ? `${compact.slice(0, 24)}…` : compact || '新会话';
  }

  async send(provider: ProviderRecord, conversationId: string, credential: string, adapter: ProtocolAdapter, text: string, systemPrompt: string = '', contextCount: number = 0, enableWebSearch: boolean = false, sourceData: string = ''): Promise<void> {
    if (this.isGenerating || text.trim().length === 0 || !provider.enabled || conversationId.length === 0) return;
    if (this.currentConversationId !== conversationId) await this.load(conversationId);

    const now: number = Date.now();
    const messageId: string = `${now}-${Math.floor(Math.random() * 1000000)}`;
    const user: MessageRecord = {
      id: `${messageId}-user`, conversationId, sequence: this.messages.length, role: 'user', content: text.trim(), reasoningContent: '', sourceData: '', status: MessageStatus.Completed, errorSummary: '', createdAt: now, updatedAt: now
    };
    const assistant: MessageRecord = {
      id: `${messageId}-assistant`, conversationId, sequence: this.messages.length + 1, role: 'assistant', content: '', reasoningContent: '', sourceData, status: MessageStatus.Generating, errorSummary: '', createdAt: now, updatedAt: now, inputTokens: 0, outputTokens: 0, totalTokens: 0
    };

    AppStorage.setOrCreate('chat_live_assistant_id', assistant.id);
    AppStorage.setOrCreate('chat_live_conversation_id', conversationId);
    AppStorage.setOrCreate('chat_live_assistant_content', '');
    AppStorage.setOrCreate('chat_live_assistant_reasoning', '');
    AppStorage.setOrCreate('chat_live_assistant_status', MessageStatus.Generating);
    this.publishAssistantContent(assistant.id, '');
    this.publishAssistantReasoning(assistant.id, '');

    this.messages = this.messages.concat([user, assistant]);
    await this.repository.saveMessage(user);
    await this.repository.saveMessage(assistant);
    await this.repository.updateConversation({
      id: conversationId,
      title: this.conversationTitle(user.content),
      providerId: provider.id,
      modelName: provider.modelName,
      status: MessageStatus.Generating,
      createdAt: now,
      updatedAt: now
    });

    this.isGenerating = true;
    this.statusText = '正在发送';
    this.errorMessage = '';
    this.lastProvider = provider;
    this.lastAdapter = adapter;
    this.notifyStateChanged();

    const available: ChatMessage[] = this.messages
      .filter((item: MessageRecord): boolean => item.id !== assistant.id && item.status === MessageStatus.Completed && item.content.trim().length > 0)
      .map((item: MessageRecord): ChatMessage => ({ role: item.role, content: item.content, reasoningContent: item.reasoningContent }));
    const contextual: ChatMessage[] = contextCount > 0 ? available.slice(Math.max(0, available.length - contextCount)) : available;
    const systemMessage: ChatMessage = { role: 'system', content: systemPrompt.trim(), reasoningContent: '' };
    const requestMessages: ChatMessage[] = systemPrompt.trim().length > 0 ? [systemMessage].concat(contextual) : contextual;

    try {
      const options: StreamRequestOptions = { enableWebSearch };
      await this.service.stream(provider, requestMessages, credential, adapter, options, (delta: StreamDelta): void => {
        assistant.content += delta.content;
        assistant.reasoningContent += delta.reasoning;
        if (delta.usage !== undefined) {
          assistant.inputTokens = delta.usage.inputTokens;
          assistant.outputTokens = delta.usage.outputTokens;
          assistant.totalTokens = delta.usage.totalTokens;
          hilog.info(0x0000, 'AIBoxStream', 'usage input=%{public}d output=%{public}d total=%{public}d', assistant.inputTokens, assistant.outputTokens, assistant.totalTokens);
        }
        this.publishAssistantContent(assistant.id, assistant.content);
        this.publishAssistantReasoning(assistant.id, assistant.reasoningContent);
        if (delta.content.length > 0 || delta.reasoning.length > 0 || delta.finishReason.length > 0 || delta.error.length > 0) {
          hilog.info(0x0000, 'AIBoxStream', 'view model content=%{public}d reasoning=%{public}d finish=%{public}s error=%{public}s', assistant.content.length, assistant.reasoningContent.length, delta.finishReason, delta.error.length > 0 ? 'yes' : 'no');
        }
        if (delta.error.length > 0) {
          assistant.status = MessageStatus.Failed;
          assistant.errorSummary = delta.error;
          this.errorMessage = assistant.errorSummary;
        }
        if (delta.finishReason.length > 0) assistant.status = MessageStatus.Completed;
        AppStorage.setOrCreate('chat_live_assistant_content', assistant.content);
        AppStorage.setOrCreate('chat_live_assistant_reasoning', assistant.reasoningContent);
        if (assistant.status === MessageStatus.Generating) AppStorage.setOrCreate('chat_live_assistant_status', assistant.status);
        if (delta.content.length > 0 || delta.reasoning.length > 0 || delta.finishReason.length > 0 || delta.error.length > 0) {
          this.messages = this.messages.map((item: MessageRecord): MessageRecord => item.id === assistant.id ? {
            id: assistant.id,
            conversationId: assistant.conversationId,
            sequence: assistant.sequence,
            role: assistant.role,
            content: assistant.content,
            reasoningContent: assistant.reasoningContent,
            sourceData: assistant.sourceData,
            status: assistant.status,
            errorSummary: assistant.errorSummary,
            createdAt: assistant.createdAt,
            updatedAt: assistant.updatedAt
          } : item);
          this.notifyStateChanged();
        }
      });
      if (assistant.status === MessageStatus.Generating) assistant.status = MessageStatus.Completed;
      this.statusText = assistant.status === MessageStatus.Failed ? '回答生成失败，请重试' : '';
    } catch (error) {
      const detail: string = error instanceof Error ? error.message : '';
      hilog.error(0x0000, 'AIBoxStream', 'stream failed detail=%{public}s', detail);
      assistant.status = MessageStatus.Failed;
      assistant.errorSummary = detail.length > 0 ? detail : '请求未完成，请稍后重试。';
      this.errorMessage = assistant.errorSummary;
      this.statusText = '回答生成失败，请重试';
    } finally {
      assistant.updatedAt = Date.now();
      AppStorage.setOrCreate('chat_live_assistant_content', assistant.content);
      AppStorage.setOrCreate('chat_live_assistant_reasoning', assistant.reasoningContent);
      this.publishAssistantContent(assistant.id, assistant.content);
      this.publishAssistantReasoning(assistant.id, assistant.reasoningContent);
      await this.repository.saveMessage(assistant);
      await this.repository.updateConversation({
        id: conversationId,
        title: this.conversationTitle(user.content),
        providerId: provider.id,
        modelName: provider.modelName,
        status: assistant.status,
        createdAt: now,
        updatedAt: assistant.updatedAt
      });
      this.messages = this.messages.map((item: MessageRecord): MessageRecord => item.id === assistant.id ? {
        id: assistant.id,
        conversationId: assistant.conversationId,
        sequence: assistant.sequence,
        role: assistant.role,
        content: assistant.content,
        reasoningContent: assistant.reasoningContent,
        sourceData: assistant.sourceData,
        status: assistant.status,
        errorSummary: assistant.errorSummary,
        createdAt: assistant.createdAt,
        updatedAt: assistant.updatedAt
      } : item);
      this.isGenerating = false;
      AppStorage.setOrCreate('history_revision', Date.now());
      AppStorage.set('history_revision', Date.now());
      this.notifyStateChanged();
      AppStorage.setOrCreate('chat_live_assistant_status', assistant.status);
    }
  }
}
