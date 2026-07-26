import { AppStore } from '../common/AppStore';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { MaterialLevel, MaterialOption } from '../model/ShellModels';
import { ConversationRecord } from '../model/ChatModels';
import { SystemBarAppearance } from '../common/SystemBarAppearance';
import { FirstLaunchDetector } from '../common/FirstLaunchDetector';
import { common } from '@kit.AbilityKit';

interface AppearanceOption { value: string; label: string; }
interface HeatmapCell { day: number; level: number; count: number; tokens: number; }

enum MySection { Home = 'home', Settings = 'settings', About = 'about', Privacy = 'privacy' }

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
  @State private appVersion: string = '';
  @State private heatmap: HeatmapCell[] = [];
  @State private activeDays: number = 0;
  @State private heatEntered: boolean = false;
  @State private showHeatDetail: boolean = false;
  @State private selectedDayLabel: string = '';
  @State private selectedDay: number = -1;
  @State private selectedDayCount: number = 0;
  @State private selectedDayTokens: number = 0;
  @State private selectedConversationTitles: string[] = [];
  @State private totalTokens: number = 0;
  @State private heatDetailOpacity: number = 1;
  @State private heatDetailOffset: number = 0;
  @State private heatDetailScale: number = 1;
  @State private contentOffset: number = 0;
  @State private contentAnimationDuration: number = 0;
  @State private isNavigating: boolean = false;
  @StorageLink('history_revision') @Watch('onHistoryRevisionChanged') private historyRevision: number = 0;
  @StorageLink('my_back_request_revision') @Watch('onBackRequested') private backRequestRevision: number = 0;
  onMaterialChanged: (level: MaterialLevel) => void = (_level: MaterialLevel): void => {};
  onAppearanceChanged: (mode: string, accent: string) => void = (_mode: string, _accent: string): void => {};

  aboutToAppear(): void {
    if (this.section === MySection.Home) {
      AppStorage.setOrCreate('my_section', MySection.Home);
      AppStorage.set('my_section', MySection.Home);
    }
    this.loadSettings();
    void this.loadAppVersion();
    void this.loadHeatmap();
    this.heatEntered = false;
    setTimeout((): void => { this.heatEntered = true; }, 80);
  }

  private onHistoryRevisionChanged(): void {
    void this.loadHeatmap();
  }

  private async loadAppVersion(): Promise<void> {
    try {
      this.appVersion = (await FirstLaunchDetector.detect()).versionName;
    } catch (_) {
      this.appVersion = '';
    }
  }

  private onBackRequested(): void {
    if (this.backRequestRevision > 0 && this.section !== MySection.Home) this.navigateTo(MySection.Home);
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
    const usageByDay: Map<number, number> = await AppStore.historyViewModel.tokenUsageByDay(today - HEATMAP_DAYS + 1);
    const cells: HeatmapCell[] = [];
    let active: number = 0;
    let tokenTotal: number = 0;
    for (let offset: number = HEATMAP_DAYS - 1; offset >= 0; offset--) {
      const day: number = today - offset;
      const count: number = counts.get(day) ?? 0;
      const tokens: number = usageByDay.get(day) ?? 0;
      const level: number = count === 0 ? 0 : count === 1 ? 1 : count < 4 ? 2 : count < 8 ? 3 : 4;
      if (level > 0) active++;
      tokenTotal += tokens;
      cells.push({ day, level, count, tokens });
    }
    this.heatmap = cells;
    this.activeDays = active;
    this.totalTokens = tokenTotal;
    this.refreshSelectedHeatDetail(cells);
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

  private dayLabel(day: number): string {
    const date: Date = new Date(day * DAY_MS);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private tokenLabel(tokens: number): string {
    if (tokens >= 1000000) return `${(tokens / 1000000).toFixed(1)}M`;
    if (tokens >= 1000) return `${(tokens / 1000).toFixed(1)}K`;
    return `${tokens}`;
  }

  private refreshSelectedHeatDetail(cells: HeatmapCell[]): void {
    if (!this.showHeatDetail || this.selectedDay < 0) return;
    const selected: HeatmapCell | undefined = cells.find((cell: HeatmapCell): boolean => cell.day === this.selectedDay);
    if (selected === undefined) return;
    const records: ConversationRecord[] = AppStore.historyViewModel.conversations
      .filter((item: ConversationRecord): boolean => Math.floor(item.updatedAt / DAY_MS) === selected.day)
      .sort((left: ConversationRecord, right: ConversationRecord): number => right.updatedAt - left.updatedAt);
    this.selectedDayCount = selected.count;
    this.selectedDayTokens = selected.tokens;
    this.selectedConversationTitles = records.slice(0, 3).map((item: ConversationRecord): string => item.title || '未命名会话');
  }

  private openHeatDetail(cell: HeatmapCell): void {
    const records: ConversationRecord[] = AppStore.historyViewModel.conversations
      .filter((item: ConversationRecord): boolean => Math.floor(item.updatedAt / DAY_MS) === cell.day)
      .sort((left: ConversationRecord, right: ConversationRecord): number => right.updatedAt - left.updatedAt);
    this.selectedDayLabel = this.dayLabel(cell.day);
    this.selectedDay = cell.day;
    this.selectedDayCount = cell.count;
    this.selectedDayTokens = cell.tokens;
    this.selectedConversationTitles = records.slice(0, 3).map((item: ConversationRecord): string => item.title || '未命名会话');
    if (!this.showHeatDetail) {
      this.showHeatDetail = true;
      this.heatDetailOpacity = 0;
      this.heatDetailOffset = -10;
      this.heatDetailScale = 0.96;
    } else {
      this.heatDetailOpacity = 0.72;
      this.heatDetailOffset = -3;
      this.heatDetailScale = 0.98;
    }
    setTimeout((): void => {
      this.heatDetailOpacity = 1;
      this.heatDetailOffset = 0;
      this.heatDetailScale = 1;
    }, 16);
  }

  private closeHeatDetail(): void {
    this.heatDetailOpacity = 0;
    this.heatDetailOffset = -8;
    this.heatDetailScale = 0.96;
    setTimeout((): void => { this.showHeatDetail = false; }, 180);
  }

  private navigateTo(next: MySection): void {
    if (this.isNavigating || next === this.section) return;
    this.isNavigating = true;
    this.contentAnimationDuration = 0;
    this.contentOffset = next === MySection.Home ? -28 : 28;
    this.section = next;
    AppStorage.setOrCreate('my_section', next);
    AppStorage.set('my_section', next);
    setTimeout((): void => {
      this.contentAnimationDuration = 240;
      this.contentOffset = 0;
      setTimeout((): void => { this.isNavigating = false; }, 250);
    }, 16);
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
      if (this.section !== MySection.Home) Button('返回').onClick((): void => { this.navigateTo(MySection.Home); }).height(36).fontSize(14).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      Text(title).fontSize(24).fontWeight(FontWeight.Bold).layoutWeight(1);
    }.width('100%');
  }

  @Builder
  private heatmapCard(): void {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('使用热力图').fontSize(17).fontWeight(FontWeight.Medium);
          Text(`最近 12 周 · ${this.activeDays} 天活跃 · ${this.tokenLabel(this.totalTokens)} Token`).fontSize(13).fontColor(THEME_TOKENS.secondaryText);
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
                .animation({ duration: 260, delay: (weekIndex * 7 + dayIndex) * 10, curve: Curve.EaseOut })
                .onClick((): void => this.openHeatDetail(cell))
                .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.82 });
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
  private heatDetailPanel(): void {
    Column({ space: 8 }) {
      Row() {
        Text(this.selectedDayLabel).fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1);
        Button({ type: ButtonType.Circle }) {
          Text('×').fontSize(20).fontColor(THEME_TOKENS.secondaryText);
        }.width(28).height(28).backgroundColor(Color.Transparent).onClick((): void => { this.closeHeatDetail(); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.82 });
      }.width('100%');
      Text(this.selectedDayCount > 0 ? `当天更新了 ${this.selectedDayCount} 个会话` : '当天没有本地会话活动')
        .fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
      Text(`累计消耗 ${this.tokenLabel(this.selectedDayTokens)} Token`).fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
      if (this.selectedConversationTitles.length > 0) {
        Column({ space: 4 }) {
          Text('最近会话').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
          ForEach(this.selectedConversationTitles, (title: string): void => {
            Text(title).fontSize(14).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%');
          }, (title: string, index: number): string => `${index}-${title}`);
        }.alignItems(HorizontalAlign.Start).width('100%');
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(THEME_TOKENS.surface)
    .borderRadius(18)
    .opacity(this.heatDetailOpacity)
    .translate({ y: this.heatDetailOffset })
    .scale({ x: this.heatDetailScale, y: this.heatDetailScale })
    .animation({ duration: 220, curve: Curve.EaseOut });
  }

  @Builder
  private entryList(): void {
    List({ space: 0 }) {
      ListItem() {
        Row({ space: 12 }) {
          Column({ space: 3 }) { Text('设置').fontSize(17).fontWeight(FontWeight.Medium); Text('外观、聊天与沉浸光感').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.Settings); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Row({ space: 12 }) {
          Column({ space: 3 }) { Text('关于').fontSize(17).fontWeight(FontWeight.Medium); Text('AIBox、版本与项目地址').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.About); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
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
      if (this.showHeatDetail) this.heatDetailPanel();
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
        ListItem() { Column({ space: 5 }) { Text('AIBox').fontSize(20).fontWeight(FontWeight.Bold).width('100%'); Text('作者：LomoCat').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%'); Text(`版本：${this.appVersion.length > 0 ? this.appVersion : '读取中'}`).fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%'); }.width('100%').padding(16); }
        ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
        ListItem() { Row() { Text('GitHub').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Text('github.com/LoMoCatAp/ImmersiveAI').fontSize(13).fontColor(THEME_TOKENS.primary); }.width('100%').padding(16).onClick((): void => this.openGitHub()); }
        ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
        ListItem() { Row() { Column({ space: 3 }) { Text('隐私政策').fontSize(17).fontWeight(FontWeight.Medium); Text('本地数据、第三方服务与权限说明').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1); Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText); }.width('100%').padding(16).onClick((): void => { this.navigateTo(MySection.Privacy); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 }); }
      }.width('100%').height(230).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
    }.width('100%');
  }

  @Builder
  private privacyContent(): void {
    Column({ space: 16 }) {
      this.pageHeader('隐私政策');
      Column({ space: 14 }) {
        Text('生效日期：2026 年 7 月 26 日').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
        Text('AIBox 仅在设备本地保存供应商配置、会话记录、外观设置与 Token 统计。API Key 使用系统资产存储能力保存，不会发送至开发者服务器。').fontSize(15).lineHeight(22).width('100%');
        Text('当您发起对话、测试连接、查询模型或启用联网搜索时，输入内容、系统提示词、上下文及导入文件文本会直接发送到您自行配置的第三方 AI 服务商。相关数据的处理规则由该服务商的隐私政策和服务条款决定。').fontSize(15).lineHeight(22).width('100%');
        Text('导入文件仅会在应用临时目录中读取；其文本会在您发送消息时作为附件内容加入请求，临时文件会在读取后清理。应用不读取通讯录、位置、通话记录或设备标识符。').fontSize(15).lineHeight(22).width('100%');
        Text('应用申请网络权限仅用于连接您配置的 AI 服务。您可以删除会话或供应商；卸载应用或在系统设置中清除应用数据将删除本地保存的数据和凭据。').fontSize(15).lineHeight(22).width('100%');
        Text('本政策可能随功能和适用法律变化更新。继续使用应用即表示您理解第三方服务商可能处理您主动发送的数据。').fontSize(15).lineHeight(22).width('100%');
      }.padding(18).width('100%').backgroundColor(THEME_TOKENS.surface).borderRadius(18).alignItems(HorizontalAlign.Start);
    }.width('100%');
  }

  build() {
    Column() {
      if (this.section === MySection.Home) this.homeContent();
      else if (this.section === MySection.Settings) this.settingsContent();
      else if (this.section === MySection.About) this.aboutContent();
      else this.privacyContent();
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 28, bottom: 132 })
    .translate({ x: this.contentOffset })
    .animation({ duration: this.contentAnimationDuration, curve: Curve.EaseOut });
  }
}
