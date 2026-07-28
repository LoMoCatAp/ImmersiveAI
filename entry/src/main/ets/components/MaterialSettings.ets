import { MaterialLevel, MaterialOption } from '../model/ShellModels';
import { THEME_TOKENS } from '../common/ThemeTokens';

@Component
export struct MaterialSettings {
  @Prop options: Array<MaterialOption> = [];
  @Prop selected: MaterialLevel = MaterialLevel.Gentle;
  @Prop status: string = '';
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  onSelect: (level: MaterialLevel) => void = (_level: MaterialLevel): void => {};

  build() {
    Column({ space: 8 }) {
      Text('沉浸光感材质').fontSize(20).fontWeight(FontWeight.Bold);
      Text('使用系统 HDS 材质，选择后立即生效。').fontColor(THEME_TOKENS.secondaryText);
      ForEach(this.options, (option: MaterialOption) => {
        Button(`${option.label}：${option.description}`)
          .onClick((): void => { this.onSelect(option.level); })
          .height(THEME_TOKENS.touchTarget)
          .width('100%')
          .backgroundColor(option.level === this.selected ? this.appearanceAccentColor : THEME_TOKENS.surface)
          .fontColor(option.level === this.selected ? THEME_TOKENS.primaryText : THEME_TOKENS.secondaryText)
          .enabled(option.available)
          .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      }, (option: MaterialOption): string => option.level);
      Text(this.status).fontColor(THEME_TOKENS.secondaryText).maxLines(THEME_TOKENS.maxChineseLines);
    }.width('100%').padding({ top: 8, bottom: 8 });
  }
}
