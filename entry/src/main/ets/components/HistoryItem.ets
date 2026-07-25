import { ConversationRecord, MessageStatus } from '../model/ChatModels';
import { THEME_TOKENS } from '../common/ThemeTokens';
@Component export struct HistoryItem {
  @Prop item: ConversationRecord = { id: '', title: '', providerId: '', modelName: '', status: MessageStatus.Completed, createdAt: 0, updatedAt: 0 };
  @Prop selected: boolean = false;
  onOpen: () => void = (): void => {};
  onDelete: () => void = (): void => {};
  onRename: (title: string) => void = (_title: string): void => {};
  build() { Row({ space: 8 }) { Column() { Text(this.item.title).fontWeight(FontWeight.Bold); Text(`模型：${this.item.modelName}`).fontSize(12).fontColor(THEME_TOKENS.secondaryText); }.layoutWeight(1); Button(this.selected ? '已选中' : '打开').onClick(this.onOpen).height(48).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); Button('删除').onClick(this.onDelete).height(48).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); }.padding(12).backgroundColor(this.selected ? $r('app.color.selection_surface') : THEME_TOKENS.surface).borderRadius(12).width('100%'); }
}
