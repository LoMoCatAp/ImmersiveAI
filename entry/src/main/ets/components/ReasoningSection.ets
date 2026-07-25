import { THEME_TOKENS } from '../common/ThemeTokens';
@Component
export struct ReasoningSection {
  @Prop content: string = '';
  @State expanded: boolean = false;
  build() {
    if (this.content.length > 0) {
      Column({ space: 6 }) {
        Row() { Text('Reasoning').fontWeight(FontWeight.Bold).fontColor(THEME_TOKENS.primaryText).layoutWeight(1); Button(this.expanded ? 'Hide' : 'Show').onClick(() => { this.expanded = !this.expanded }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }) }
        if (this.expanded) Text(this.content).fontColor(THEME_TOKENS.secondaryText)
      }.padding(12).borderRadius(THEME_TOKENS.cardRadius).backgroundColor(THEME_TOKENS.surface);
    }
  }
}
