import { AppStore } from '../common/AppStore';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { MaterialLevel, MaterialOption } from '../model/ShellModels';
import { SystemBarAppearance } from '../common/SystemBarAppearance';
import { common } from '@kit.AbilityKit';

interface AppearanceOption { value: string; label: string; }

const COLOR_MODE_OPTIONS: AppearanceOption[] = [
  { value: 'system', label: '跟随系统' }, { value: 'light', label: '浅色' }, { value: 'dark', label: '深色' }
];
const ACCENT_OPTIONS: AppearanceOption[] = [
  { value: '#3559D8', label: '星河蓝' }, { value: '#16805E', label: '森林绿' }, { value: '#A54619', label: '暖橙' },
  { value: '#007D8A', label: '湖青' }, { value: '#B23A6F', label: '莓红' }, { value: '#865200', label: '琥珀' },
  { value: '#5E6272', label: '石墨' }, { value: '#6D48A8', label: '鸢尾紫' }
];

@Component
export struct MyView {
  @State private summary: string = '均衡（默认）';
  @State private colorMode: string = 'system';
  @State private accentColor: string = '#3559D8';
  @State private chatTextSize: number = 16;
  onMaterialChanged: (level: MaterialLevel) => void = (_level: MaterialLevel): void => {};
  onAppearanceChanged: (mode: string, accent: string) => void = (_mode: string, _accent: string): void => {};

  aboutToAppear(): void {
    this.summary = AppStore.shellViewModel.state.myPage.entrySummary;
    this.colorMode = AppStore.readAppearance('color_mode', 'system');
    this.accentColor = AppStore.readAppearance('accent_color', '#3559D8');
    const size: number = Number(AppStore.readAppearance('chat_text_size', '16'));
    this.chatTextSize = size >= 12 && size <= 24 ? size : 16;
  }

  private labels(options: AppearanceOption[]): string[] { return options.map((option: AppearanceOption): string => option.label); }
  private selectOptions(options: AppearanceOption[]): SelectOption[] { return this.labels(options).map((label: string): SelectOption => ({ value: label })); }
  private optionIndex(options: AppearanceOption[], value: string): number { const index: number = options.findIndex((option: AppearanceOption): boolean => option.value === value); return index < 0 ? 0 : index; }
  private materialLabels(): string[] { return AppStore.shellViewModel.state.material.options.map((option: MaterialOption): string => option.label); }
  private materialIndex(): number { const index: number = AppStore.shellViewModel.state.material.options.findIndex((option: MaterialOption): boolean => option.level === AppStore.shellViewModel.state.material.selected); return index < 0 ? 0 : index; }
  private isColor(value: string): boolean { return new RegExp('^#[0-9A-Fa-f]{6}$').test(value); }
  private safeColor(value: string, fallback: string): string { return this.isColor(value) ? value : fallback; }

  private selectMaterial(index: number): void {
    const option: MaterialOption | undefined = AppStore.shellViewModel.state.material.options[index];
    if (option === undefined || !option.available) return;
    AppStore.shellViewModel.setMaterialLevel(option.level);
    AppStore.saveMaterialLevel(option.level);
    this.summary = AppStore.shellViewModel.state.myPage.entrySummary;
    this.onMaterialChanged(option.level);
  }

  private selectColorMode(index: number): void {
    const option: AppearanceOption | undefined = COLOR_MODE_OPTIONS[index];
    if (option === undefined) return;
    this.colorMode = option.value;
    AppStore.saveAppearance('color_mode', option.value);
    AppStorage.setOrCreate('appearance_color_mode', option.value);
    AppStorage.set('appearance_color_mode', option.value);
    SystemBarAppearance.apply(option.value);
    this.onAppearanceChanged(this.colorMode, this.accentColor);
  }

  private selectAccent(index: number): void {
    const option: AppearanceOption | undefined = ACCENT_OPTIONS[index];
    if (option === undefined) return;
    this.accentColor = option.value;
    AppStore.saveAppearance('accent_color', option.value);
    AppStorage.setOrCreate('appearance_accent_color', option.value);
    AppStorage.set('appearance_accent_color', option.value);
    this.onAppearanceChanged(this.colorMode, this.accentColor);
  }

  private saveTextSize(value: number): void {
    const size: number = Math.round(value);
    this.chatTextSize = size;
    AppStore.saveAppearance('chat_text_size', `${size}`);
    AppStorage.setOrCreate('appearance_chat_text_size', `${size}`);
    AppStorage.set('appearance_chat_text_size', `${size}`);
  }

  private openGitHub(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    void context.startAbility({ action: 'ohos.want.action.viewData', uri: 'https://github.com/LoMoCatAp/ImmersiveAI' });
  }

  @Builder
  private swatch(color: string): void { Text(' ').width(28).height(28).borderRadius(14).backgroundColor(color); }

  @Builder
  private appearanceList(): void {
    List({ space: 0 }) {
      ListItem() { Row({ space: 12 }) { Text('主题色').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.selectOptions(ACCENT_OPTIONS)).selected(this.optionIndex(ACCENT_OPTIONS, this.accentColor)).value(this.labels(ACCENT_OPTIONS)[this.optionIndex(ACCENT_OPTIONS, this.accentColor)]).onSelect((index: number): void => this.selectAccent(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() { Row({ space: 12 }) { Text('显示模式').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.selectOptions(COLOR_MODE_OPTIONS)).selected(this.optionIndex(COLOR_MODE_OPTIONS, this.colorMode)).value(this.labels(COLOR_MODE_OPTIONS)[this.optionIndex(COLOR_MODE_OPTIONS, this.colorMode)]).onSelect((index: number): void => this.selectColorMode(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
    }.width('100%').height(112).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private chatAppearanceList(): void {
    List({ space: 0 }) {
      ListItem() { Column({ space: 6 }) { Row() { Text('聊天字号').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Text(`${this.chatTextSize} vp`).fontColor(THEME_TOKENS.secondaryText); }.width('100%'); Slider({ value: this.chatTextSize, min: 12, max: 22, step: 1, style: SliderStyle.OutSet }).onChange((value: number): void => this.saveTextSize(value)).width('100%'); }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }); }
    }.width('100%').height(88).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private materialList(): void {
    List({ space: 0 }) { ListItem() { Row({ space: 12 }) { Text('档位').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.materialLabels().map((label: string): SelectOption => ({ value: label }))).selected(this.materialIndex()).value(this.summary).onSelect((index: number): void => this.selectMaterial(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); } }.width('100%').height(56).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private aboutList(): void {
    List({ space: 0 }) {
      ListItem() {
        Column({ space: 4 }) {
          Text('AIBox').fontSize(17).fontWeight(FontWeight.Medium).width('100%');
          Text('作者：LomoCat').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
          Text('版本：1.0.0').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
          Text('GitHub：github.com/LoMoCatAp/ImmersiveAI').fontSize(13).fontColor('#2F75D6').decoration({ type: TextDecorationType.Underline }).width('100%').onClick((): void => this.openGitHub());
        }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 });
      }
    }.width('100%').height(108).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  build() {
    Column({ space: 12 }) {
      Text('外观').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
      this.appearanceList();
      Text('聊天外观').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.chatAppearanceList();
      Text('沉浸光感').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.materialList();
      Text('关于').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.aboutList();
    }.width('100%').height('100%').padding({ left: 20, right: 20, top: 28, bottom: 132 });
  }
}
