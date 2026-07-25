import { THEME_TOKENS } from '../common/ThemeTokens';
@Component export struct StatusBanner {
  @Prop message: string = '';
  @Prop loading: boolean = false;
  @Prop failure: boolean = false;
  onRetry: () => void = (): void => {};
  build() { if (this.message.length > 0) Row({ space: 8 }) { if (this.loading) LoadingProgress().width(20).height(20); Text(this.message).fontColor(this.failure ? THEME_TOKENS.danger : THEME_TOKENS.primaryText).layoutWeight(1); if (this.failure) Button('Retry').onClick(this.onRetry).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); }.padding(12).borderRadius(10).backgroundColor(THEME_TOKENS.surface).width('100%'); }
}
