import { THEME_TOKENS } from '../common/ThemeTokens';
import { uiMaterial } from '@kit.ArkUI';

@Component
export struct ChatComposer {
  @State inputText: string = '';
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  @Prop isGenerating: boolean = false;
  @Prop hasAttachment: boolean = false;
  @Prop webSearchSupported: boolean = false;
  @Prop webSearchEnabled: boolean = false;
  onSend: (text: string) => void = (_text: string): void => {};
  onStop: () => void = (): void => {};
  onMore: () => void = (): void => {};
  onOpenAttachmentMenu: () => void = (): void => {};
  onToggleWebSearch: () => void = (): void => {};

  private immersiveMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: Color.Transparent,
      applyShadow: false,
      interactive: true,
      lightEffect: { color: this.appearanceAccentColor }
    });
  }

  build() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Button('导入文件')
          .onClick(this.onOpenAttachmentMenu)
          .height(32)
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor(this.appearanceAccentColor)
          .systemMaterial(this.immersiveMaterial())
          .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.84 });
        Button('更多')
          .onClick(this.onMore)
          .height(32)
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor(this.appearanceAccentColor)
          .systemMaterial(this.immersiveMaterial())
          .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.84 });
        if (this.webSearchSupported) {
          Button('联网搜索')
            .onClick(this.onToggleWebSearch)
            .height(32)
            .fontSize(13)
            .fontColor(this.webSearchEnabled ? this.appearanceAccentColor : THEME_TOKENS.secondaryText)
            .backgroundColor(Color.Transparent)
            .systemMaterial(this.immersiveMaterial())
            .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.84 });
        }
      }.width('100%');
    Row({ space: 8 }) {
       TextInput({ placeholder: '输入消息', text: this.inputText }).layoutWeight(1).height(44).onChange((value: string): void => { this.inputText = value; });
      if (this.isGenerating) {
        Button() { Image($r('app.media.chat_close')).width(20).height(20).fillColor(this.appearanceAccentColor); }
          .onClick(this.onStop).width(44).height(44).backgroundColor(Color.Transparent).borderRadius(22).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.82 });
      } else {
        Button() { Image($r('app.media.chat_send')).width(21).height(21).fillColor(this.appearanceAccentColor); }
          .onClick((): void => { const value: string = this.inputText.trim(); if (value.length > 0 || this.hasAttachment) { this.onSend(value); this.inputText = ''; } })
          .width(44).height(44).backgroundColor(THEME_TOKENS.surface).borderRadius(22).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.82 });
      }
      }.width('100%');
    }.padding(12).width('100%');
  }
}
