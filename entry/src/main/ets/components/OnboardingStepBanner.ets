import { THEME_TOKENS } from '../common/ThemeTokens';

@Component
export struct OnboardingStepBanner {
  @Prop step: number = 1;
  @Prop title: string = '';
  @Prop detail: string = '';
  @Prop accentColor: string = '#3559D8';
  @State private entered: boolean = false;

  aboutToAppear(): void {
    this.entered = false;
    setTimeout((): void => { this.entered = true; }, 16);
  }

  build() {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(`${this.step}`)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center);
      }
      .width(42)
      .height(42)
      .borderRadius(21)
      .backgroundColor(this.accentColor)
      .shadow({ radius: this.entered ? 14 : 4, color: this.accentColor, offsetX: 0, offsetY: 3 })
      .scale({ x: this.entered ? 1 : 0.72, y: this.entered ? 1 : 0.72 })
      .animation({ duration: 360, curve: Curve.Friction });
      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text(`步骤 ${this.step} / 3`).fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.accentColor);
          LoadingProgress().color(this.accentColor).width(16).height(16);
        }.width('100%');
        Text(this.title).fontSize(17).fontWeight(FontWeight.Bold).fontColor(THEME_TOKENS.primaryText).width('100%');
        Text(this.detail).fontSize(14).lineHeight(21).fontColor(THEME_TOKENS.secondaryText).width('100%');
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
    }
    .width('100%')
    .padding(14)
    .backgroundColor(THEME_TOKENS.surface)
    .border({ width: 1, color: this.accentColor, radius: 16 })
    .opacity(this.entered ? 1 : 0)
    .translate({ y: this.entered ? 0 : 12 })
    .animation({ duration: 320, curve: Curve.EaseOut });
  }
}
