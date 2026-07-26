import { THEME_TOKENS } from '../common/ThemeTokens';
import { AppStore } from '../common/AppStore';

@Component
export struct FirstLaunchGuide {
  @Prop accentColor: string = '#3559D8';
  @State private step: number = 0;
  @State private contentOffsetX: number = 0;
  @State private isTransitioning: boolean = false;
  private transitionRevision: number = 0;
  onBeginProviderSetup: () => void = (): void => {};
  onDefer: () => void = (): void => {};

  aboutToAppear(): void {
    this.transitionRevision += 1;
    this.isTransitioning = false;
    this.step = AppStore.readOnboardingIntroStep();
    this.contentOffsetX = 0;
  }

  private titleForStep(step: number): string {
    if (step === 0) return 'AIBox';
    if (step === 1) return '数据与隐私';
    return '开始对话';
  }

  private detailForStep(step: number): string {
    if (step === 0) return '在设备本地管理会话与服务商配置，直接连接您选择的 AI 服务。';
    if (step === 1) return 'API Key 通过系统资产存储保存。发送消息、测试连接、查询模型或使用联网搜索时，必要内容会直接发送至您自行配置的服务商。';
    return '先在“供应商”中添加服务地址、模型和 API Key。测试连接成功后，即可在聊天页创建会话并发送消息。';
  }

  private hintForStep(step: number): string {
    if (step === 1) return '请仅添加可信服务商，并在发送前确认输入内容。';
    if (step === 2) return '服务商、会话和外观设置均可随时在应用内调整。';
    return '';
  }

  private animateContentTo(offsetX: number): void {
    animateTo({ duration: 180, curve: Curve.EaseOut }, (): void => {
      this.contentOffsetX = offsetX;
    });
  }

  private dismissGuide(): void {
    // The root page also observes this request while the overlay is leaving the tree.
    const revision: number = Date.now();
    AppStorage.setOrCreate('onboarding_dismiss_request_revision', revision);
    AppStorage.set('onboarding_dismiss_request_revision', revision);
    this.onDefer();
  }

  private changeStep(delta: number): void {
    const target: number = this.step + delta;
    if (this.isTransitioning || target < 0 || target > 2) return;
    this.isTransitioning = true;
    this.transitionRevision += 1;
    const revision: number = this.transitionRevision;
    const forward: boolean = delta > 0;
    AppStore.saveOnboardingIntroStep(target);
    this.animateContentTo(forward ? -320 : 320);
    setTimeout((): void => {
      if (revision !== this.transitionRevision) return;
      this.step = target;
      this.contentOffsetX = forward ? 320 : -320;
      setTimeout((): void => {
        if (revision !== this.transitionRevision) return;
        this.animateContentTo(0);
      }, 16);
    }, 180);
    setTimeout((): void => {
      if (revision !== this.transitionRevision) return;
      this.isTransitioning = false;
    }, 376);
  }

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
  private guideContent(): void {
      Column({ space: 12 }) {
        Text(this.titleForStep(this.step)).fontSize(this.step === 0 ? 30 : 24).fontWeight(FontWeight.Bold).fontColor(THEME_TOKENS.primaryText).width('100%');
        Text(this.detailForStep(this.step)).fontSize(16).lineHeight(24).fontColor(THEME_TOKENS.secondaryText).width('100%');
        if (this.hintForStep(this.step).length > 0) Text(this.hintForStep(this.step)).fontSize(14).lineHeight(21).fontColor(THEME_TOKENS.secondaryText).width('100%');
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%');
  }

  @Builder
  private guideBody(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        this.guideContent();
      }
      .width('100%')
      .height(220)
      .translate({ x: this.contentOffsetX });
    }
    .width('100%')
    .height(220)
    .clip(true);
  }

  @Builder
  private actionContent(): void {
      if (this.step === 2) {
        Column({ space: 8 }) {
          Button('去配置服务商')
            .width('100%')
            .height(THEME_TOKENS.touchTarget)
            .fontColor(Color.White)
            .backgroundColor(this.accentColor)
            .onClick((): void => { this.onBeginProviderSetup(); })
            .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
          Row({ space: 12 }) {
            Button('上一步')
              .layoutWeight(1)
              .height(40)
              .fontColor(this.accentColor)
              .backgroundColor(Color.Transparent)
              .onClick((): void => { this.changeStep(-1); })
              .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
            Button('稍后设置')
              .layoutWeight(1)
              .height(40)
              .fontColor(this.accentColor)
              .backgroundColor(Color.Transparent)
              .onClick((): void => { this.dismissGuide(); })
              .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
          }.width('100%');
        }.width('100%');
      } else {
        Row({ space: 12 }) {
          if (this.step > 0) {
            Button('上一步')
              .layoutWeight(1)
              .height(THEME_TOKENS.touchTarget)
              .fontColor(this.accentColor)
              .backgroundColor(Color.Transparent)
              .onClick((): void => { this.changeStep(-1); })
              .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
          }
          Button('下一步')
            .layoutWeight(1)
            .height(THEME_TOKENS.touchTarget)
            .fontColor(Color.White)
            .backgroundColor(this.accentColor)
            .onClick((): void => { this.changeStep(1); })
            .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
        }.width('100%');
      }
  }

  @Builder
  private actionArea(): void {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        this.actionContent();
      }
      .width('100%')
      .height(96)
      .translate({ x: this.contentOffsetX });
    }
    .width('100%')
    .height(96)
    .clip(true);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor('#99000000');
      Column({ space: 20 }) {
        this.progress();
        this.guideBody();
        this.actionArea();
      }
      .width('88%')
      .constraintSize({ maxWidth: 480 })
      .height(448)
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
