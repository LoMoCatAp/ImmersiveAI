import { ConversationRecord } from '../model/ChatModels';
import { AppStore } from '../common/AppStore';
import { HistoryItem } from '../components/HistoryItem';
import { EmptyState } from '../components/EmptyState';
import { ProviderRecord } from '../model/ProviderModels';
import { THEME_TOKENS } from '../common/ThemeTokens';

@Component
export struct HistoryView {
  @State conversations: ConversationRecord[] = [];
  @State errorMessage: string = '';
  @State pendingDeleteId: string = '';
  @StorageLink('history_revision') @Watch('onHistoryChanged') private historyRevision: number = 0;
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
    const provider: ProviderRecord | undefined = AppStore.providerViewModel.records.find((item: ProviderRecord): boolean => item.enabled);
    const providerId: string = provider === undefined ? '' : provider.id;
    const modelName: string = provider === undefined ? '' : provider.modelName;
    const id: string = await AppStore.historyViewModel.create(providerId, modelName);
    if (id.length > 0) {
      this.onOpen(id);
    }
    this.conversations = AppStore.historyViewModel.conversations;
  }

  private async remove(item: ConversationRecord): Promise<void> {
    if (this.pendingDeleteId !== item.id) {
      this.pendingDeleteId = item.id;
      AppStore.historyViewModel.feedbackMessage = '再次点击删除以确认';
      return;
    }
    await AppStore.historyViewModel.remove(item);
    this.pendingDeleteId = '';
    await this.refresh();
  }

  build() {
    Column({ space: 12 }) {
      Button('新建会话').onClick((): void => { void this.create(); }).height(THEME_TOKENS.touchTarget).width('100%').clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      if (AppStore.historyViewModel.feedbackMessage.length > 0) {
        Text(AppStore.historyViewModel.feedbackMessage).fontColor(THEME_TOKENS.success);
      }
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontColor(THEME_TOKENS.danger);
      }
      if (this.conversations.length === 0 && this.errorMessage.length === 0) {
        EmptyState({ title: '暂无会话', detail: '本地会话会显示在这里。' });
      }
      List({ space: 8 }) {
        ForEach(this.conversations, (item: ConversationRecord) => {
          ListItem() {
            Column() {
              HistoryItem({
                item,
                selected: AppStore.historyViewModel.selectedId === item.id,
                onOpen: (): void => { AppStore.historyViewModel.select(item.id); this.onOpen(item.id); },
                onDelete: (): void => { void this.remove(item); }
              });
              if (this.pendingDeleteId === item.id) {
                Text('再次点击删除以确认').fontColor(THEME_TOKENS.danger);
              }
            }
          }
        }, (item: ConversationRecord): string => item.id);
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
    }.padding({ left: 20, right: 20, bottom: THEME_TOKENS.contentBottomInset, top: 20 }).width('100%').height('100%');
  }
}
