import { THEME_TOKENS } from '../common/ThemeTokens';

@Component
export struct FirstLaunchGuide {
  @Prop accentColor: string = '#3559D8';
  @State private step: number = 0;
  onBeginProviderSetup: () => void = (): void => {};
  onDefer: () => void = (): void => {};

  @Builder
  private progress(): void {
    Row({ space: 6 }) {
      ForEach([0, 1, 2], (index: number): void => {
        Text('')
          .width(index === this.step ? 22 : 8)
          .height(6)
          .borderRadius(3)
          .backgroundColor(index <= this.step ? this.accentColor : '#AEB6C8')
          .opacity(index <= this.step ? 1 : 0.42)
          .animation({ duration: 180, curve: Curve.EaseOut });
      }, (index: number): string => `${index}`);
    }.justifyContent(FlexAlign.Center).width('100%');
  }

  @Builder
  private guideBody(): void {
    if (this.step === 0) {
      Column({ space: 12 }) {
        Text('AIBox').fontSize(30).fontWeight(FontWeight.Bold).fontColor(THEME_TOKENS.primaryText).width('100%');
        Text('在设备本地管理会话与服务商配置，直接连接您选择的 AI 服务。').fontSize(16).lineHeight(24).fontColor(THEME_TOKENS.secondaryText).width('100%');
      }.alignItems(HorizontalAlign.Start).width('100%');
    } else if (this.step === 1) {
      Column({ space: 12 }) {
        Text('数据与隐私').fontSize(24).fontWeight(FontWeight.Bold).fontColor(THEME_TOKENS.primaryText).width('100%');
        Text('API Key 通过系统资产存储保存。发送消息、测试连接、查询模型或使用联网搜索时，必要内容会直接发送至您自行配置的服务商。').fontSize(16).lineHeight(24).fontColor(THEME_TOKENS.secondaryText).width('100%');
        Text('请仅添加可信服务商，并在发送前确认输入内容。').fontSize(14).lineHeight(21).fontColor(THEME_TOKENS.secondaryText).width('100%');
      }.alignItems(HorizontalAlign.Start).width('100%');
    } else {
      Column({ space: 12 }) {
        Text('开始对话').fontSize(24).fontWeight(FontWeight.Bold).fontColor(THEME_TOKENS.primaryText).width('100%');
        Text('先在“供应商”中添加服务地址、模型和 API Key。测试连接成功后，即可在聊天页创建会话并发送消息。').fontSize(16).lineHeight(24).fontColor(THEME_TOKENS.secondaryText).width('100%');
        Text('服务商、会话和外观设置均可随时在应用内调整。').fontSize(14).lineHeight(21).fontColor(THEME_TOKENS.secondaryText).width('100%');
      }.alignItems(HorizontalAlign.Start).width('100%');
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor('#99000000');
      Column({ space: 28 }) {
        this.progress();
        this.guideBody();
        Row({ space: 12 }) {
          if (this.step > 0) {
            Button('上一步')
              .layoutWeight(1)
              .height(THEME_TOKENS.touchTarget)
              .fontColor(this.accentColor)
              .backgroundColor(Color.Transparent)
              .onClick((): void => { this.step -= 1; })
              .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
          }
          if (this.step === 2) {
            Button('稍后设置')
              .layoutWeight(1)
              .height(THEME_TOKENS.touchTarget)
              .fontColor(this.accentColor)
              .backgroundColor(Color.Transparent)
              .onClick((): void => { this.onDefer(); })
              .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
          }
          Button(this.step === 2 ? '去配置服务商' : '下一步')
            .layoutWeight(1)
            .height(THEME_TOKENS.touchTarget)
            .fontColor(Color.White)
            .backgroundColor(this.accentColor)
            .onClick((): void => {
              if (this.step < 2) this.step += 1;
              else this.onBeginProviderSetup();
            })
            .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
        }.width('100%');
      }
      .width('88%')
      .constraintSize({ maxWidth: 480 })
      .padding(28)
      .backgroundColor(THEME_TOKENS.surface)
      .borderRadius(24)
      .alignItems(HorizontalAlign.Start)
      .shadow({ radius: 24, color: '#33000000', offsetX: 0, offsetY: 10 });
    }
    .width('100%')
    .height('100%')
    .zIndex(10);
  }
}
