import { NavigationIntent, NavigationSource, ShellTab } from '../model/ShellModels';
import { THEME_TOKENS } from '../common/ThemeTokens';
@Component export struct MainNavigation {
  @Prop selectedTab: ShellTab = ShellTab.Chat;
  onSelect: (intent: NavigationIntent) => void = (_intent: NavigationIntent): void => {};
  @Builder
  private tabButton(label: string, tab: ShellTab): void {
    Text(label)
      .accessibilityText(label)
      .onClick((): void => { this.onSelect({ target: tab, source: NavigationSource.FallbackNavigation, requestId: Date.now() }); })
      .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 })
      .height(THEME_TOKENS.touchTarget)
      .width('100%')
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .fontColor(this.selectedTab === tab ? THEME_TOKENS.primary : THEME_TOKENS.secondaryText)
      .backgroundColor('#00000000');
  }
  build() {
    Row({ space: 4 }) {
      this.tabButton('聊天', ShellTab.Chat);
      this.tabButton('历史', ShellTab.History);
      this.tabButton('供应商', ShellTab.Providers);
      this.tabButton('我的', ShellTab.My);
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#00000000')
    .height(THEME_TOKENS.touchTarget + 16);
  }
}
