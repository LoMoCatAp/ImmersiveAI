import { ChatComposer } from '../components/ChatComposer';
import { MessageRecord, MessageStatus } from '../model/ChatModels';
import { AppStore } from '../common/AppStore';
import { ProviderRecord, ProviderKind } from '../model/ProviderModels';
import { OpenAIStyleAdapter } from '../service/OpenAIStyleAdapter';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { ClaudeStyleAdapter } from '../service/ClaudeStyleAdapter';
import { GeminiStyleAdapter } from '../service/GeminiStyleAdapter';
import { DeepSeekStyleAdapter } from '../service/DeepSeekStyleAdapter';
import { EmptyState } from '../components/EmptyState';
import { NavigationIntent, NavigationSource, ShellTab } from '../model/ShellModels';
import { MarkdownBlock, MarkdownParser } from '../service/MarkdownParser';
import { MarkdownBlockView } from '../components/MarkdownBlockView';
import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { fileIo as fs, fileUri, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct ChatView {
  onNavigate: (intent: NavigationIntent) => void = (_intent: NavigationIntent): void => {};
  @State messages: MessageRecord[] = [];
  @State generating: boolean = false;
  @State statusText: string = '';
  @State errorMessage: string = '';
  @State conversationId: string = '';
  @State selectedProviderId: string = '';
  @State modelOverride: string = '';
  @State systemPrompt: string = '';
  @State contextCount: string = '16';
  @State showMore: boolean = false;
  @State providers: ProviderRecord[] = [];
  @State availableModels: string[] = [];
  @State modelDiscoveryMessage: string = '';
  @State liveReasoningExpanded: boolean = false;
  @State expandedReasoningMessageId: string = '';
  @State liveDisplayContent: string = '';
  @State liveDisplayReasoning: string = '';
  @State attachmentUri: string = '';
  @State attachmentName: string = '';
  @State attachmentContent: string = '';
  private readonly attachmentCharacterLimit: number = 50000;
  @StorageLink('appearance_chat_text_size') private chatTextSize: string = '16';
  @StorageLink('provider_revision') @Watch('onProviderRevisionChanged') private providerRevision: number = 0;
  @StorageLink('chat_stream_revision') @Watch('onStreamRevisionChanged') private streamRevision: number = 0;
  @StorageLink('chat_live_assistant_id') @Watch('onLiveAssistantChanged') private liveAssistantId: string = '';
  @StorageLink('chat_live_conversation_id') private liveConversationId: string = '';
  @StorageLink('chat_live_assistant_content') private liveAssistantContent: string = '';
  @StorageLink('chat_live_assistant_reasoning') private liveAssistantReasoning: string = '';
  @StorageLink('chat_live_assistant_status') @Watch('onLiveAssistantStatusChanged') private liveAssistantStatus: string = '';
  @StorageLink('chat_assistant_name') private assistantName: string = '助手';
  @StorageLink('chat_rendered_assistant_content') private renderedAssistantContent: string = '{}';
  @StorageLink('chat_rendered_assistant_reasoning') private renderedAssistantReasoning: string = '{}';
  private messageScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    AppStore.chatViewModel.setStateObserver((): void => {
      this.syncChatState();
    });
    this.restoreMoreSettings();
    this.syncChatState();
    AppStorage.setOrCreate('chat_assistant_name', AppStore.readAppearance('assistant_name', '助手'));
    void this.refreshProviders();
  }

  aboutToDisappear(): void {
    AppStore.chatViewModel.setStateObserver((): void => {});
  }

  private onProviderRevisionChanged(): void {
    void this.refreshProviders();
  }

  private onStreamRevisionChanged(): void {
    this.syncChatState();
  }

  private onLiveAssistantChanged(): void {
    this.liveReasoningExpanded = false;
  }

  private onLiveAssistantStatusChanged(): void {
    if (this.liveAssistantStatus === 'generating' || this.liveAssistantId.length === 0 || this.liveConversationId !== this.conversationId) return;
    const completedStatus: MessageStatus = this.liveAssistantStatus as MessageStatus;
    this.messages = this.messages.map((item: MessageRecord): MessageRecord => item.id === this.liveAssistantId ? {
      id: item.id,
      conversationId: item.conversationId,
      sequence: item.sequence,
      role: item.role,
      content: this.liveAssistantContent,
      reasoningContent: this.liveAssistantReasoning,
      status: completedStatus,
      errorSummary: item.errorSummary,
      createdAt: item.createdAt,
      updatedAt: Date.now()
    } : item);
  }

  private syncChatState(): void {
    this.conversationId = AppStore.chatViewModel.currentConversationId;
    this.messages = AppStore.chatViewModel.messages.map((item: MessageRecord): MessageRecord => ({
      id: item.id,
      conversationId: item.conversationId,
      sequence: item.sequence,
      role: item.role,
      content: item.content,
      reasoningContent: item.reasoningContent,
      status: item.status,
      errorSummary: item.errorSummary,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt
    }));
    this.generating = AppStore.chatViewModel.isGenerating;
    this.statusText = AppStore.chatViewModel.statusText;
    this.errorMessage = AppStore.chatViewModel.errorMessage;
    const live: MessageRecord | undefined = this.messages.find((message: MessageRecord): boolean => message.id === this.liveAssistantId);
    this.liveDisplayContent = live === undefined ? this.liveAssistantContent : live.content;
    this.liveDisplayReasoning = live === undefined ? this.liveAssistantReasoning : live.reasoningContent;
  }

  private hasLiveAssistant(): boolean {
    return this.liveAssistantId.length > 0 && this.liveConversationId === this.conversationId;
  }

  private displayedAssistantContent(message: MessageRecord): string {
    if (message.role !== 'assistant') return message.content;
    try {
      const records: Record<string, Object> = JSON.parse(this.renderedAssistantContent) as Record<string, Object>;
      const cached: Object | undefined = records[message.id];
      return typeof cached === 'string' && cached.length > message.content.length ? cached : message.content;
    } catch (_) {
      return message.content;
    }
  }

  private displayedAssistantReasoning(message: MessageRecord): string {
    if (message.role !== 'assistant') return message.reasoningContent;
    try {
      const records: Record<string, Object> = JSON.parse(this.renderedAssistantReasoning) as Record<string, Object>;
      const cached: Object | undefined = records[message.id];
      return typeof cached === 'string' && cached.length > message.reasoningContent.length ? cached : message.reasoningContent;
    } catch (_) {
      return message.reasoningContent;
    }
  }

  private liveMessage(): MessageRecord | undefined {
    return this.messages.find((message: MessageRecord): boolean => message.id === this.liveAssistantId);
  }

  private displayedLiveContent(): string {
    const message: MessageRecord | undefined = this.liveMessage();
    return message !== undefined && message.content.length > this.liveAssistantContent.length ? message.content : this.liveAssistantContent;
  }

  private displayedLiveReasoning(): string {
    const message: MessageRecord | undefined = this.liveMessage();
    return message !== undefined && message.reasoningContent.length > this.liveAssistantReasoning.length ? message.reasoningContent : this.liveAssistantReasoning;
  }

  private copyMessage(text: string): void {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    void pasteboard.getSystemPasteboard().setData(data);
    this.showToast('已复制整条消息');
  }

  private showToast(message: string): void {
    promptAction.showToast({ message });
  }

  @Builder
  private markdownContent(content: string): void {
    ForEach(MarkdownParser.parse(content), (block: MarkdownBlock) => {
      MarkdownBlockView({ block, textSize: this.messageTextSize() });
    }, (block: MarkdownBlock, index: number): string => `${index}-${block.kind}`);
  }

  private messageTextSize(): number {
    const size: number = Number(this.chatTextSize);
    return size >= 12 && size <= 24 ? size : 16;
  }

  private async refreshProviders(): Promise<void> {
    await AppStore.providerViewModel.load();
    this.providers = AppStore.providerViewModel.records.filter((item: ProviderRecord): boolean => item.enabled);
    const selected: ProviderRecord | undefined = this.providers.find((item: ProviderRecord): boolean => item.id === this.selectedProviderId) ?? this.providers[0];
    if (selected === undefined) return;
    this.selectedProviderId = selected.id;
    if (this.modelOverride.length === 0) this.modelOverride = selected.modelName;
  }

  private async refreshModels(): Promise<void> {
    const provider: ProviderRecord | undefined = this.providers.find((item: ProviderRecord): boolean => item.id === this.selectedProviderId);
    if (provider === undefined) return;
    await AppStore.providerViewModel.discoverModels(provider);
    this.availableModels = AppStore.providerViewModel.discoveredModels;
    this.modelDiscoveryMessage = AppStore.providerViewModel.modelDiscoveryMessage;
  }

  private async send(text: string): Promise<void> {
    await this.refreshProviders();
    const selected: ProviderRecord | undefined = this.providers.find((item: ProviderRecord): boolean => item.id === this.selectedProviderId);
    if (selected === undefined) {
      this.showToast('请先配置并启用供应商');
      return;
    }
    const provider: ProviderRecord = {
      id: selected.id, displayName: selected.displayName, providerKind: selected.providerKind, protocolStyle: selected.protocolStyle,
      endpoint: selected.endpoint, modelName: this.modelOverride.trim().length > 0 ? this.modelOverride.trim() : selected.modelName,
      credentialAlias: selected.credentialAlias, maskedCredential: selected.maskedCredential, enabled: selected.enabled,
      validationState: selected.validationState, createdAt: selected.createdAt, updatedAt: selected.updatedAt
    };
    const key: string | undefined = await AppStore.credentials.get(provider.credentialAlias);
    if (key === undefined) {
      this.showToast('密钥不可用，请检查供应商设置');
      return;
    }
    if (this.conversationId.length === 0) this.conversationId = await AppStore.chatViewModel.newConversation(provider);
    const adapter = provider.providerKind === ProviderKind.DeepSeek ? new DeepSeekStyleAdapter() : provider.protocolStyle === 'claudeStyle' ? new ClaudeStyleAdapter() : provider.protocolStyle === 'geminiStyle' ? new GeminiStyleAdapter() : new OpenAIStyleAdapter();
    const attachment: string = this.attachmentContent.length > 0 ? `\n\n---\n附件：${this.attachmentName}\n\n${this.attachmentContent}` : '';
    const messageCount: number = AppStore.chatViewModel.messages.length;
    const outgoingText: string = `${text}${attachment}`.trim();
    await AppStore.chatViewModel.send(provider, this.conversationId, key, adapter, outgoingText, this.systemPrompt, Number(this.contextCount));
    if (attachment.length > 0 && AppStore.chatViewModel.messages.length > messageCount) {
      this.attachmentUri = '';
      this.attachmentName = '';
      this.attachmentContent = '';
    }
  }

  private async createNewConversation(): Promise<void> {
    if (this.generating) {
      this.showToast('正在生成中，请先停止当前回复');
      return;
    }
    await this.refreshProviders();
    const provider: ProviderRecord | undefined = this.providers.find((item: ProviderRecord): boolean => item.id === this.selectedProviderId);
    if (provider === undefined) {
      this.showToast('请先配置并启用供应商');
      return;
    }
    this.conversationId = await AppStore.chatViewModel.newConversation(provider);
    this.messages = [];
    this.showToast('已创建新对话');
  }

  private async selectAttachment(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const uris: string[] = await documentPicker.select();
      if (uris.length === 0) return;
      const uri: string = uris[0];
      const selectedFile: fileUri.FileUri = new fileUri.FileUri(uri);
      const fileName: string = selectedFile.name;
      if (!this.isSupportedTextFile(fileName)) {
        this.showToast('仅支持导入文本文件');
        return;
      }
      const content: string = await this.readAttachmentText(context, uri, fileName);
      if (content.indexOf('\u0000') >= 0) {
        this.showToast('该文件不是可导入的文本文件');
        return;
      }
      this.attachmentUri = uri;
      this.attachmentName = fileName;
      this.attachmentContent = content;
      this.showToast(`已导入文件：${this.attachmentName}`);
      return;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      const code: string = businessError.code === undefined ? '' : `（${businessError.code}）`;
      this.showToast(`文件读取失败${code}，请重新选择`);
    }
  }

  private isSupportedTextFile(uri: string): boolean {
    const lower: string = uri.toLowerCase().split('?')[0].split('#')[0];
    const extensions: string[] = ['.txt', '.md', '.markdown', '.json', '.csv', '.xml', '.html', '.htm', '.yaml', '.yml', '.log', '.js', '.ts', '.ets', '.py', '.java', '.c', '.cpp', '.h', '.css', '.sql'];
    return extensions.some((extension: string): boolean => lower.endsWith(extension));
  }

  private async readAttachmentText(context: common.UIAbilityContext, uri: string, fileName: string): Promise<string> {
    const safeFileName: string = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const stagedPath: string = `${context.tempDir}/aibox-import-${Date.now()}-${safeFileName}`;
    try {
      // Picker URIs are granted external resources. Copying first makes the file readable through the app sandbox.
      await fs.copy(uri, fileUri.getUriFromPath(stagedPath));
      try {
        return await fs.readText(stagedPath, { length: this.attachmentCharacterLimit, encoding: 'utf-8' });
      } catch (_) {
        const file: fs.File = await fs.open(stagedPath, fs.OpenMode.READ_ONLY);
        try {
          const buffer: ArrayBuffer = new ArrayBuffer(this.attachmentCharacterLimit);
          const length: number = await fs.read(file.fd, buffer, { offset: 0, length: this.attachmentCharacterLimit });
          const bytes: Uint8Array = new Uint8Array(buffer).slice(0, length);
          return util.TextDecoder.create('utf-8').decodeToString(bytes);
        } finally {
          await fs.close(file);
        }
      }
    } finally {
      try {
        await fs.unlink(stagedPath);
      } catch (_) {
        // The temporary file is best-effort cleanup only.
      }
    }
  }

  private fileNameFromUri(uri: string): string {
    const path: string = uri.split('?')[0].split('#')[0];
    const index: number = path.lastIndexOf('/');
    return index >= 0 ? path.slice(index + 1) : path;
  }

  private providerOptions(): SelectOption[] {
    return this.providers.map((provider: ProviderRecord): SelectOption => ({ value: provider.displayName }));
  }

  private providerIndex(): number {
    const index: number = this.providers.findIndex((provider: ProviderRecord): boolean => provider.id === this.selectedProviderId);
    return index < 0 ? 0 : index;
  }

  private modelOptions(): SelectOption[] {
    return this.availableModels.map((model: string): SelectOption => ({ value: model }));
  }

  private modelIndex(): number {
    const index: number = this.availableModels.findIndex((model: string): boolean => model === this.modelOverride);
    return index < 0 ? 0 : index;
  }

  private saveMoreSettings(): void {
    const modelName: string = this.modelOverride.trim();
    const prompt: string = this.systemPrompt.trim();
    const context: number = Number(this.contextCount);
    const name: string = this.assistantName.trim().length > 0 ? this.assistantName.trim() : '助手';
    this.modelOverride = modelName;
    this.systemPrompt = prompt;
    this.contextCount = Number.isFinite(context) && context >= 0 ? `${Math.floor(context)}` : '16';
    this.assistantName = name;
    AppStore.saveAppearance('chat_model_override', modelName);
    AppStore.saveAppearance('chat_system_prompt', prompt);
    AppStore.saveAppearance('chat_context_count', this.contextCount);
    AppStore.saveAppearance('assistant_name', name);
    AppStorage.setOrCreate('chat_assistant_name', name);
    this.showMore = false;
  }

  private restoreMoreSettings(): void {
    this.modelOverride = AppStore.readAppearance('chat_model_override', '');
    this.systemPrompt = AppStore.readAppearance('chat_system_prompt', '');
    const context: number = Number(AppStore.readAppearance('chat_context_count', '16'));
    this.contextCount = Number.isFinite(context) && context >= 0 ? `${Math.floor(context)}` : '16';
    this.assistantName = AppStore.readAppearance('assistant_name', '助手');
  }

  @Builder
  private moreSheet(): void {
    Column({ space: 12 }) {
      Text('会话设置').fontSize(20).fontWeight(FontWeight.Bold).width('100%');
      Text('模型').fontSize(14).fontColor(THEME_TOKENS.secondaryText);
      Row({ space: 8 }) {
        Button('刷新可用模型').onClick((): void => { void this.refreshModels(); }).height(THEME_TOKENS.touchTarget).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
        if (this.modelDiscoveryMessage.length > 0) Text(this.modelDiscoveryMessage).layoutWeight(1).fontSize(13).fontColor(THEME_TOKENS.secondaryText);
      }.width('100%');
      if (this.availableModels.length > 0) {
        Select(this.modelOptions()).selected(this.modelIndex()).value(this.availableModels[this.modelIndex()]).onSelect((index: number): void => { this.modelOverride = this.availableModels[index]; }).height(48).menuAlign(MenuAlignType.START, { dx: 0, dy: 52 }).width('100%');
      }
      TextInput({ placeholder: '模型名称，也可直接输入自定义模型', text: this.modelOverride }).onChange((value: string): void => { this.modelOverride = value; });
      Text('系统提示词').fontSize(14).fontColor(THEME_TOKENS.secondaryText);
      TextInput({ placeholder: '本次会话的系统提示词', text: this.systemPrompt }).onChange((value: string): void => { this.systemPrompt = value; });
      Text('上下文消息数').fontSize(14).fontColor(THEME_TOKENS.secondaryText);
      TextInput({ placeholder: '0 为全部上下文', text: this.contextCount }).type(InputType.Number).onChange((value: string): void => { this.contextCount = value; });
      Text('助手名称').fontSize(14).fontColor(THEME_TOKENS.secondaryText);
      TextInput({ placeholder: '助手', text: this.assistantName }).onChange((value: string): void => { this.assistantName = value; });
      Button('保存').onClick((): void => { this.saveMoreSettings(); }).height(THEME_TOKENS.touchTarget).width('100%').clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
    }.padding(20).width('100%').backgroundColor(THEME_TOKENS.surface);
  }

  build() {
    Column({ space: 10 }) {
      if (this.providers.length === 0) {
        EmptyState({ title: '暂无启用的供应商', detail: '请先新增并启用供应商，再开始聊天。', actionLabel: '打开供应商设置', onAction: this.onNavigate });
      } else {
        Row({ space: 8 }) {
          Select(this.providerOptions()).selected(this.providerIndex()).value(this.providerOptions()[this.providerIndex()].value).onSelect((index: number): void => {
            this.selectedProviderId = this.providers[index].id;
            this.modelOverride = this.providers[index].modelName;
            this.conversationId = '';
            this.messages = [];
            this.availableModels = [];
            this.modelDiscoveryMessage = '';
          }).layoutWeight(1);
          Button('+').onClick((): void => { void this.createNewConversation(); }).height(THEME_TOKENS.touchTarget).width(THEME_TOKENS.touchTarget).fontSize(24).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.82 });
        }.width('100%');
        if (this.messages.length === 0) Text('输入消息即可开始新的会话。').margin({ top: 8 }).fontColor(THEME_TOKENS.secondaryText);
        List({ space: 8, scroller: this.messageScroller }) {
          ForEach(this.messages, (message: MessageRecord) => {
            if (!this.hasLiveAssistant() || message.id !== this.liveAssistantId) {
              ListItem() {
                Row() {
                  Column({ space: 4 }) {
                    if (message.role === 'assistant') Text(this.assistantName).fontSize(12).fontColor(THEME_TOKENS.secondaryText).margin({ left: 4 });
                    else Text('我').fontSize(12).fontColor(THEME_TOKENS.secondaryText);
                    if (message.role === 'assistant') {
                      if (this.displayedAssistantReasoning(message).length > 0) {
                        Button(this.expandedReasoningMessageId === message.id ? '收起思考' : '查看思考')
                          .onClick((): void => {
                            this.expandedReasoningMessageId = this.expandedReasoningMessageId === message.id ? '' : message.id;
                          })
                          .fontSize(11)
                          .height(28)
                          .padding({ left: 8, right: 8 })
                          .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
                        if (this.expandedReasoningMessageId === message.id) {
                          Text(this.displayedAssistantReasoning(message))
                            .fontSize(14)
                            .fontColor(THEME_TOKENS.secondaryText)
                            .wordBreak(WordBreak.BREAK_ALL)
                            .copyOption(CopyOptions.LocalDevice);
                        }
                      }
                      if (this.displayedAssistantContent(message).length > 0) {
                        this.markdownContent(this.displayedAssistantContent(message));
                      }
                      if (message.errorSummary.length > 0) Text(message.errorSummary).fontColor(THEME_TOKENS.danger).wordBreak(WordBreak.BREAK_ALL);
                    } else {
                      Text(message.content).fontSize(this.messageTextSize()).fontColor(THEME_TOKENS.primaryText).wordBreak(WordBreak.BREAK_ALL).copyOption(CopyOptions.LocalDevice);
                    }
                  }
                  .padding(16)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ bottom: 8 })
                  .borderRadius(THEME_TOKENS.cardRadius)
                  .backgroundColor(message.role === 'assistant' ? $r('app.color.chat_assistant_bubble') : $r('app.color.chat_user_bubble'))
                  .constraintSize({ maxWidth: '94%' })
                  .width(message.role === 'assistant' ? '94%' : undefined)
                  .gesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((): void => {
                    this.copyMessage(message.role === 'assistant' ? this.displayedAssistantContent(message) : message.content);
                  }));
                }
                .width('100%')
                .justifyContent(message.role === 'assistant' ? FlexAlign.Start : FlexAlign.End);
              }.transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.96, y: 0.96 })).animation({ duration: 220, curve: Curve.EaseOut }));
            }
          }, (message: MessageRecord): string => message.id);
          if (this.hasLiveAssistant()) {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(this.assistantName).fontSize(12).fontColor(THEME_TOKENS.secondaryText).margin({ left: 4 });
                  if (this.liveDisplayReasoning.length > 0) {
                    Button(this.liveReasoningExpanded ? '收起思考' : '查看思考')
                      .onClick((): void => { this.liveReasoningExpanded = !this.liveReasoningExpanded; })
                      .fontSize(11)
                      .height(28)
                      .padding({ left: 8, right: 8 })
                      .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
                    if (this.liveReasoningExpanded) {
                      Text(this.liveDisplayReasoning)
                        .fontSize(14)
                        .fontColor(THEME_TOKENS.secondaryText)
                        .wordBreak(WordBreak.BREAK_ALL)
                        .copyOption(CopyOptions.LocalDevice);
                    }
                  }
                  if (this.liveDisplayContent.length > 0) {
                    if (this.liveAssistantStatus === 'generating') {
                      Text(this.liveDisplayContent)
                        .fontSize(this.messageTextSize())
                        .fontColor(THEME_TOKENS.primaryText)
                        .wordBreak(WordBreak.BREAK_ALL)
                        .copyOption(CopyOptions.LocalDevice);
                    } else {
                      this.markdownContent(this.liveDisplayContent);
                    }
                  }
                  if (this.liveAssistantStatus === 'generating' && this.liveDisplayContent.length === 0) Text('正在思考…').fontColor(THEME_TOKENS.secondaryText);
                  if (this.liveAssistantStatus === 'generating' && this.liveDisplayContent.length > 0) Text('正在生成…').fontColor(THEME_TOKENS.secondaryText);
                }
                .padding(16)
                .alignItems(HorizontalAlign.Start)
                .margin({ bottom: 8 })
                .borderRadius(THEME_TOKENS.cardRadius)
                .backgroundColor($r('app.color.chat_assistant_bubble'))
                .constraintSize({ maxWidth: '94%' })
                .width('94%')
                .gesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((): void => { this.copyMessage(this.liveDisplayContent); }));
              }.width('100%').justifyContent(FlexAlign.Start);
            }
          }
        }.layoutWeight(1).width('100%');
        if (this.errorMessage.length > 0) Text(this.errorMessage).fontColor(THEME_TOKENS.danger);
        ChatComposer({ isGenerating: this.generating, hasAttachment: this.attachmentContent.length > 0, onSend: (text: string): void => { void this.send(text); }, onStop: (): void => { AppStore.chatViewModel.stop(); }, onMore: (): void => { this.showMore = true; void this.refreshModels(); }, onPickAttachment: (): void => { void this.selectAttachment(); } });
      }
    }
    .padding({ left: 20, right: 20, bottom: 72, top: 20 })
    .width('100%')
    .height('100%')
    .bindSheet($$this.showMore, this.moreSheet(), { detents: [SheetSize.FIT_CONTENT], preferType: SheetType.BOTTOM, showClose: true, onWillDismiss: (): void => { this.showMore = false; } });
  }
}
