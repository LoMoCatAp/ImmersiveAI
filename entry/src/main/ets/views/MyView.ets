import { AppStore } from '../common/AppStore';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { MaterialLevel, MaterialOption } from '../model/ShellModels';
import { ConversationRecord } from '../model/ChatModels';
import { SystemBarAppearance } from '../common/SystemBarAppearance';
import { common } from '@kit.AbilityKit';

interface AppearanceOption { value: string; label: string; }
interface HeatmapCell { day: number; level: number; }

enum MySection { Home = 'home', Settings = 'settings', About = 'about' }

const DAY_MS: number = 24 * 60 * 60 * 1000;
const HEATMAP_DAYS: number = 84;
const COLOR_MODE_OPTIONS: AppearanceOption[] = [
  { value: 'system', label: '跟随系统' }, { value: 'light', label: '浅色' }, { value: 'dark', label: '深色' }
];
const ACCENT_OPTIONS: AppearanceOption[] = [
  { value: '#3559D8', label: '星河蓝' }, { value: '#16805E', label: '森林绿' }, { value: '#A54619', label: '暖棕' },
  { value: '#007D8A', label: '湖青' }, { value: '#B23A6F', label: '莓红' }, { value: '#865200', label: '琥珀' },
  { value: '#5E6272', label: '石墨' }, { value: '#6D48A8', label: '鸢尾紫' }
];

@Component
export struct MyView {
  @State private section: MySection = MySection.Home;
  @State private summary: string = '均衡（默认）';
  @State private colorMode: string = 'system';
  @State private accentColor: string = '#3559D8';
  @State private chatTextSize: number = 16;
  @State private heatmap: HeatmapCell[] = [];
  @State private activeDays: number = 0;
  @State private heatEntered: boolean = false;
  onMaterialChanged: (level: MaterialLevel) => void = (_level: MaterialLevel): void => {};
  onAppearanceChanged: (mode: string, accent: string) => void = (_mode: string, _accent: string): void => {};

  aboutToAppear(): void {
    this.loadSettings();
    void this.loadHeatmap();
    this.heatEntered = false;
    setTimeout((): void => { this.heatEntered = true; }, 80);
  }

  private loadSettings(): void {
    this.summary = AppStore.shellViewModel.state.myPage.entrySummary;
    this.colorMode = AppStore.readAppearance('color_mode', 'system');
    this.accentColor = AppStore.readAppearance('accent_color', '#3559D8');
    const size: number = Number(AppStore.readAppearance('chat_text_size', '16'));
    this.chatTextSize = size >= 12 && size <= 24 ? size : 16;
  }

  private async loadHeatmap(): Promise<void> {
    await AppStore.historyViewModel.load();
    const counts: Map<number, number> = new Map<number, number>();
    AppStore.historyViewModel.conversations.forEach((item: ConversationRecord): void => {
      const key: number = Math.floor(item.updatedAt / DAY_MS);
      counts.set(key, (counts.get(key) ?? 0) + 1);
    });
    const today: number = Math.floor(Date.now() / DAY_MS);
    const cells: HeatmapCell[] = [];
    let active: number = 0;
    for (let offset: number = HEATMAP_DAYS - 1; offset >= 0; offset--) {
      const day: number = today - offset;
      const count: number = counts.get(day) ?? 0;
      const level: number = count === 0 ? 0 : count === 1 ? 1 : count < 4 ? 2 : count < 8 ? 3 : 4;
      if (level > 0) active++;
      cells.push({ day, level });
    }
    this.heatmap = cells;
    this.activeDays = active;
  }

  private heatWeeks(): Array<Array<HeatmapCell>> {
    const result: Array<Array<HeatmapCell>> = [];
    for (let start: number = 0; start < this.heatmap.length; start += 7) result.push(this.heatmap.slice(start, start + 7));
    return result;
  }

  private heatOpacity(level: number): number {
    if (level === 0) return 0.12;
    if (level === 1) return 0.32;
    if (level === 2) return 0.52;
    if (level === 3) return 0.74;
    return 1;
  }

  private labels(options: AppearanceOption[]): string[] { return options.map((option: AppearanceOption): string => option.label); }
  private selectOptions(options: AppearanceOption[]): SelectOption[] { return this.labels(options).map((label: string): SelectOption => ({ value: label })); }
  private optionIndex(options: AppearanceOption[], value: string): number { const index: number = options.findIndex((option: AppearanceOption): boolean => option.value === value); return index < 0 ? 0 : index; }
  private materialLabels(): string[] { return AppStore.shellViewModel.state.material.options.map((option: MaterialOption): string => option.label); }
  private materialIndex(): number { const index: number = AppStore.shellViewModel.state.material.options.findIndex((option: MaterialOption): boolean => option.level === AppStore.shellViewModel.state.material.selected); return index < 0 ? 0 : index; }

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
  private pageHeader(title: string): void {
    Row({ space: 10 }) {
      if (this.section !== MySection.Home) Button('返回').onClick((): void => { this.section = MySection.Home; }).height(36).fontSize(14).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      Text(title).fontSize(24).fontWeight(FontWeight.Bold).layoutWeight(1);
    }.width('100%');
  }

  @Builder
  private heatmapCard(): void {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('使用热力图').fontSize(17).fontWeight(FontWeight.Medium);
          Text(`最近 12 周 · ${this.activeDays} 天活跃`).fontSize(13).fontColor(THEME_TOKENS.secondaryText);
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
        Text('本地').fontSize(12).fontColor(THEME_TOKENS.secondaryText).padding({ left: 8, right: 8, top: 4, bottom: 4 }).backgroundColor(THEME_TOKENS.pageBackground).borderRadius(10);
      }.width('100%');
      Row({ space: 4 }) {
        ForEach(this.heatWeeks(), (week: HeatmapCell[], weekIndex: number) => {
          Column({ space: 4 }) {
            ForEach(week, (cell: HeatmapCell, dayIndex: number) => {
              Text('')
                .width(12)
                .height(12)
                .borderRadius(3)
                .backgroundColor(THEME_TOKENS.primary)
                .opacity(this.heatOpacity(cell.level))
                .scale({ x: this.heatEntered ? 1 : 0.55, y: this.heatEntered ? 1 : 0.55 })
                .animation({ duration: 260, delay: (weekIndex * 7 + dayIndex) * 10, curve: Curve.EaseOut });
            }, (cell: HeatmapCell): string => `${cell.day}`);
          };
        }, (_week: HeatmapCell[], index: number): string => `${index}`);
      }.width('100%').justifyContent(FlexAlign.SpaceBetween);
      Row() {
        Text('少').fontSize(11).fontColor(THEME_TOKENS.secondaryText);
        Row({ space: 3 }) {
          ForEach([0, 1, 2, 3, 4], (level: number) => { Text('').width(10).height(10).borderRadius(2).backgroundColor(THEME_TOKENS.primary).opacity(this.heatOpacity(level)); });
        };
        Text('多').fontSize(11).fontColor(THEME_TOKENS.secondaryText);
      }.width('100%').justifyContent(FlexAlign.End);
    }.padding(16).width('100%').backgroundColor(THEME_TOKENS.surface).borderRadius(18);
  }

  @Builder
  private entryList(): void {
    List({ space: 0 }) {
      ListItem() {
        Row({ space: 12 }) {
          Column({ space: 3 }) { Text('设置').fontSize(17).fontWeight(FontWeight.Medium); Text('外观、聊天与沉浸光感').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.section = MySection.Settings; });
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Row({ space: 12 }) {
          Column({ space: 3 }) { Text('关于').fontSize(17).fontWeight(FontWeight.Medium); Text('AIBox、版本与项目地址').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.section = MySection.About; });
      }
    }.width('100%').height(132).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private appearanceList(): void {
    List({ space: 0 }) {
      ListItem() { Row({ space: 12 }) { Text('主题色').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.selectOptions(ACCENT_OPTIONS)).selected(this.optionIndex(ACCENT_OPTIONS, this.accentColor)).value(this.labels(ACCENT_OPTIONS)[this.optionIndex(ACCENT_OPTIONS, this.accentColor)]).onSelect((index: number): void => this.selectAccent(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() { Row({ space: 12 }) { Text('显示模式').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.selectOptions(COLOR_MODE_OPTIONS)).selected(this.optionIndex(COLOR_MODE_OPTIONS, this.colorMode)).value(this.labels(COLOR_MODE_OPTIONS)[this.optionIndex(COLOR_MODE_OPTIONS, this.colorMode)]).onSelect((index: number): void => this.selectColorMode(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); }
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
  private homeContent(): void {
    Column({ space: 16 }) {
      this.pageHeader('我的');
      this.heatmapCard();
      Text('应用').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 4 });
      this.entryList();
    }.width('100%');
  }

  @Builder
  private settingsContent(): void {
    Column({ space: 12 }) {
      this.pageHeader('设置');
      Text('外观').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 8 });
      this.appearanceList();
      Text('聊天外观').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.chatAppearanceList();
      Text('沉浸光感').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.materialList();
    }.width('100%');
  }

  @Builder
  private aboutContent(): void {
    Column({ space: 16 }) {
      this.pageHeader('关于');
      List({ space: 0 }) {
        ListItem() { Column({ space: 5 }) { Text('AIBox').fontSize(20).fontWeight(FontWeight.Bold).width('100%'); Text('作者：LomoCat').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%'); Text('版本：1.0.0').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%'); }.width('100%').padding(16); }
        ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
        ListItem() { Row() { Text('GitHub').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Text('github.com/LoMoCatAp/ImmersiveAI').fontSize(13).fontColor(THEME_TOKENS.primary); }.width('100%').padding(16).onClick((): void => this.openGitHub()); }
      }.width('100%').height(156).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
    }.width('100%');
  }

  build() {
    Column() {
      if (this.section === MySection.Home) this.homeContent();
      else if (this.section === MySection.Settings) this.settingsContent();
      else this.aboutContent();
    }.width('100%').height('100%').padding({ left: 20, right: 20, top: 28, bottom: 132 });
  }
}
