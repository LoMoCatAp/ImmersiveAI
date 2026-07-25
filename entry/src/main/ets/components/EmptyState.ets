import { THEME_TOKENS } from '../common/ThemeTokens';
import { NavigationIntent, NavigationSource, ShellTab } from '../model/ShellModels';
@Component export struct EmptyState {
  @Prop title: string = '这里暂时没有内容';
  @Prop detail: string = '';
  @Prop actionLabel: string = '';
  onAction: (intent: NavigationIntent) => void = (_intent: NavigationIntent): void => {};
  build() { Column({ space: 10 }) { Text(this.title).fontSize(20).fontWeight(FontWeight.Bold); if (this.detail.length > 0) Text(this.detail).fontColor(THEME_TOKENS.secondaryText).textAlign(TextAlign.Center); if (this.actionLabel.length > 0) Button(this.actionLabel).onClick((): void => { this.onAction({ target: ShellTab.Providers, source: NavigationSource.EmptyState, requestId: Date.now() }); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); }.padding(24).width('100%').alignItems(HorizontalAlign.Center) }
}
