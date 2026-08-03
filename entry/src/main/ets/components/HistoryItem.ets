import { ConversationRecord, MessageStatus } from '../model/ChatModels';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { uiMaterial } from '@kit.ArkUI';

@Component
export struct HistoryItem {
  @Prop item: ConversationRecord = { id: '', title: '', providerId: '', modelName: '', status: MessageStatus.Completed, createdAt: 0, updatedAt: 0 };
  @Prop selected: boolean = false;
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  onOpen: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onDelete: () => void = (): void => {};

  private immersiveMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: Color.Transparent,
      applyShadow: false,
      interactive: true,
      lightEffect: { color: this.appearanceAccentColor }
    });
  }

  private timeLabel(): string {
    const date: Date = new Date(this.item.updatedAt);
    const today: Date = new Date();
    const minute: string = date.getMinutes() < 10 ? `0${date.getMinutes()}` : `${date.getMinutes()}`;
    if (date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate()) return `今天 ${date.getHours()}:${minute}`;
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  build() {
    Row({ space: 12 }) {
      Text('')
        .width(3)
        .height(40)
        .borderRadius(2)
        .backgroundColor(this.appearanceAccentColor)
        .opacity(this.selected ? 1 : 0);
      Column({ space: 5 }) {
        Text(this.item.title.length > 0 ? this.item.title : '未命名会话')
          .fontSize(16)
          .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');
        Row({ space: 8 }) {
          Text(this.item.modelName.length > 0 ? this.item.modelName : '未设置模型')
            .fontSize(12)
            .fontColor(THEME_TOKENS.secondaryText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1);
          Text(this.timeLabel()).fontSize(12).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%');
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.history_more')).width(20).height(20).fillColor(this.appearanceAccentColor);
      }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .systemMaterial(this.immersiveMaterial())
        .bindMenu([
          { value: '导出 Markdown', action: (): void => { this.onExport(); } },
          { value: '删除会话', action: (): void => { this.onDelete(); } }
        ])
        .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.86 });
    }
      .width('100%')
      .padding({ left: 16, right: 10, top: 13, bottom: 13 })
      .backgroundColor(this.selected ? $r('app.color.selection_surface') : Color.Transparent)
      .borderRadius(18)
      .systemMaterial(this.immersiveMaterial())
      .onClick(this.onOpen)
      .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.98 });
  }
}
