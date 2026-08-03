import { ConversationRecord, MessageRecord } from '../model/ChatModels';
import { AppStore } from '../common/AppStore';
import { HistoryItem } from '../components/HistoryItem';
import { EmptyState } from '../components/EmptyState';
import { ProviderRecord } from '../model/ProviderModels';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { WebSearchResult, WebSearchService } from '../service/WebSearchService';

@Component
export struct HistoryView {
  @State conversations: ConversationRecord[] = [];
  @State errorMessage: string = '';
  @StorageLink('history_revision') @Watch('onHistoryChanged') private historyRevision: number = 0;
  @StorageLink('layout_page_padding') private pagePadding: number = THEME_TOKENS.pagePadding;
  private readonly webSearchService: WebSearchService = new WebSearchService();
  onOpen: (id: string) => void = (_id: string): void => {};

  aboutToAppear(): void {
    void this.refresh();
  }

  private onHistoryChanged(): void { void this.refresh(); }

  private async refresh(): Promise<void> {
    await AppStore.historyViewModel.load();
    this.conversations = AppStore.historyViewModel.conversations;
    this.errorMessage = AppStore.historyViewModel.errorMessage;
  }

  private async create(): Promise<void> {
    const selectedProviderId: string = AppStore.readAppearance('chat_selected_provider_id', '');
    const provider: ProviderRecord | undefined = AppStore.providerViewModel.records.find((item: ProviderRecord): boolean => item.enabled && item.id === selectedProviderId)
      ?? AppStore.providerViewModel.records.find((item: ProviderRecord): boolean => item.enabled);
    const providerId: string = provider === undefined ? '' : provider.id;
    const modelName: string = provider === undefined ? '' : provider.modelName;
    const id: string = await AppStore.historyViewModel.create(providerId, modelName);
    if (id.length > 0) {
      this.onOpen(id);
    }
    this.conversations = AppStore.historyViewModel.conversations;
  }

  private remove(item: ConversationRecord): void {
    AlertDialog.show({
      title: '删除会话',
      message: `确定删除“${item.title}”吗？此会话中的本地消息将一并删除。`,
      autoCancel: true,
      primaryButton: { value: '取消', action: (): void => {} },
      secondaryButton: { value: '删除', fontColor: THEME_TOKENS.danger, action: (): void => { void this.confirmRemove(item); } }
    });
  }

  private async confirmRemove(item: ConversationRecord): Promise<void> {
    await AppStore.historyViewModel.remove(item);
    await this.refresh();
  }

  private fileNameFor(item: ConversationRecord): string {
    const title: string = item.title.trim().replace(/[\\/:*?"<>|]/g, '_').slice(0, 48);
    return `AIBox-${title.length > 0 ? title : '会话'}-${item.id}.md`;
  }

  private markdownFor(item: ConversationRecord, messages: MessageRecord[]): string {
    const rows: string[] = [`# ${item.title || 'AIBox 会话'}`, '', `模型：${item.modelName}`, `导出时间：${new Date().toLocaleString()}`, ''];
    messages.forEach((message: MessageRecord): void => {
      rows.push(`## ${message.role === 'user' ? '用户' : '助手'}`, '');
      if (message.reasoningContent.length > 0) rows.push('### 思考过程', '', message.reasoningContent, '');
      rows.push(message.content.length > 0 ? message.content : '（无文本内容）', '');
      const sources: WebSearchResult[] = this.webSearchService.resultsFromSerialized(message.sourceData ?? '');
      if (sources.length > 0) {
        rows.push('### 联网来源', '');
        sources.forEach((source: WebSearchResult, index: number): void => {
          rows.push(`- [${index + 1}. ${source.title.length > 0 ? source.title : '未命名来源'}](${source.url})`);
          if (source.snippet.length > 0) rows.push(`  - ${source.snippet}`);
        });
        rows.push('');
      }
    });
    return rows.join('\n');
  }

  private async exportConversation(item: ConversationRecord): Promise<void> {
    try {
      const messages: MessageRecord[] = await AppStore.chatViewModel.messagesFor(item.id);
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      options.newFileNames = [this.fileNameFor(item)];
      options.fileSuffixChoices = ['Markdown 文档|.md'];
      const uris: string[] = await documentPicker.save(options);
      if (uris.length === 0) return;
      const file: fs.File = await fs.open(uris[0], fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try {
        await fs.write(file.fd, this.markdownFor(item, messages));
      } finally {
        await fs.close(file);
      }
      promptAction.showToast({ message: '会话已导出为 Markdown 文件' });
    } catch (_) {
      promptAction.showToast({ message: '会话导出未完成' });
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('历史会话').fontSize(24).fontWeight(FontWeight.Bold);
          Text(`本地保存 ${this.conversations.length} 个会话`).fontSize(13).fontColor(THEME_TOKENS.secondaryText);
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
      }.width('100%').padding({ bottom: 4 });
      if (AppStore.historyViewModel.feedbackMessage.length > 0) {
        Text(AppStore.historyViewModel.feedbackMessage).fontSize(13).fontColor(THEME_TOKENS.success).width('100%');
      }
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontSize(13).fontColor(THEME_TOKENS.danger).width('100%');
      }
      if (this.conversations.length === 0 && this.errorMessage.length === 0) {
        EmptyState({ title: '暂无会话', detail: '本地会话会显示在这里。' });
      } else {
        Text('会话').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').padding({ top: 4, bottom: 2 });
        List({ space: 6 }) {
          ForEach(this.conversations, (item: ConversationRecord, index: number) => {
            ListItem() {
              HistoryItem({
                item,
                selected: AppStore.historyViewModel.selectedId === item.id,
                onOpen: (): void => { AppStore.historyViewModel.select(item.id); this.onOpen(item.id); },
                onExport: (): void => { void this.exportConversation(item); },
                onDelete: (): void => { this.remove(item); }
              });
            }
          }, (item: ConversationRecord): string => item.id);
        }
        .layoutWeight(1)
        .width('100%')
        .padding(6)
        .backgroundColor(THEME_TOKENS.surface)
        .borderRadius(24)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
      }
    }.padding({ left: this.pagePadding, right: this.pagePadding, bottom: THEME_TOKENS.contentBottomInset, top: 20 }).width('100%').height('100%');
  }
}
