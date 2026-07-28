import { AppStore } from '../common/AppStore';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { MaterialLevel, MaterialOption } from '../model/ShellModels';
import { ConversationRecord } from '../model/ChatModels';
import { SystemBarAppearance } from '../common/SystemBarAppearance';
import { FirstLaunchDetector } from '../common/FirstLaunchDetector';
import { CapabilityCenterView } from './CapabilityCenterView';
import { common } from '@kit.AbilityKit';
import { hdsMaterial, DynamicHideParams, HdsNavigation, HdsNavigationTitleBarOptions, HdsNavDestination, HideMode, ScrollEffectType } from '@kit.UIDesignKit';

interface AppearanceOption { value: string; label: string; }
interface HeatmapCell { day: number; level: number; count: number; tokens: number; }
interface ChangelogEntry { version: string; date: string; items: string[]; }
interface PrivacyEntry { title: string; content: string; }

enum MySection { Home = 'home', Settings = 'settings', Prompt = 'prompt', Skills = 'skills', Knowledge = 'knowledge', Tools = 'tools', About = 'about' }

const DAY_MS: number = 24 * 60 * 60 * 1000;
const HEATMAP_DAYS: number = 84;
const ABOUT_CONTENT_OFFSET: number = -45;
const PRIVACY_ENTRIES: PrivacyEntry[] = [
  { title: '本地存储', content: 'AIBox 仅在设备本地保存供应商配置、会话记录、外观设置与 Token 统计。API Key 使用系统资产存储能力保存，不会发送至开发者服务器。' },
  { title: '第三方服务', content: '当您发起对话、测试连接、查询模型或启用联网搜索时，输入内容、系统提示词、上下文及导入文件文本会直接发送到您自行配置的第三方 AI 服务商。相关数据的处理规则由该服务商的隐私政策和服务条款决定。' },
  { title: '导入文件', content: '导入文件仅会在应用临时目录中读取；其文本会在您发送消息时作为附件内容加入请求，临时文件会在读取后清理。应用不读取通讯录、位置、通话记录或设备标识符。' },
  { title: '权限与删除', content: '应用申请网络权限仅用于连接您配置的 AI 服务。您可以删除会话或供应商；卸载应用或在系统设置中清除应用数据将删除本地保存的数据和凭据。' },
  { title: '政策更新', content: '本政策可能随功能和适用法律变化更新。继续使用应用即表示您理解第三方服务商可能处理您主动发送的数据。' }
];
const CHANGELOG_ENTRIES: ChangelogEntry[] = [
  { version: '1.1.3', date: '2026-07-27', items: ['优化 UI：调整能力页面布局与入口图标显示。'] },
  { version: '1.1.2', date: '2026-07-27', items: ['优化 UI'] },
  { version: '1.1.1', date: '2026-07-27', items: ['以设置页为统一基准重构子页面顶部布局，设置、关于、提示词、技能、知识库和工具与扩展不再依赖位移补偿。', '工具与扩展的开关状态变化仅在对应卡片内重排，外层滚动内容固定从统一位置开始。'] },
  { version: '1.1.0', date: '2026-07-27', items: ['统一设置、提示词、技能、知识库、工具与扩展及关于页的内容基线，修复工具开关触发的页面位置变化。', '联网搜索来源现以可点击卡片显示在回复内，并与摘要一同保存至本地会话和 Markdown 导出。'] },
  { version: '1.0.38', date: '2026-07-27', items: ['将设置、技能、知识库、工具与扩展入口分别改为齿轮、铅笔、书本和扳手 SVG 图标。', '重新校准设置、提示词、技能、工具与扩展及关于页的内容起始位置。'] },
  { version: '1.0.37', date: '2026-07-27', items: ['按页面校准能力中心与关于页的内容起始位置：技能、工具与扩展上移，知识库下移。', '“我的”入口和能力页标题补充主题色 SVG 图标；布局不再因开关展开而改变基线。'] },
  { version: '1.0.36', date: '2026-07-27', items: ['统一“我的”、设置、能力中心与关于页面的内容起始位置，移除不一致的手动位移。', '设置项补充主题色 SVG 图标，并修复知识库选择文件后底部导航栏错误出现的问题。'] },
  { version: '1.0.35', date: '2026-07-27', items: ['知识库支持添加本地笔记与导入文本文件；资料保存在设备本地。', '对话会根据当前问题筛选相关知识库片段，减少无关上下文占用。'] },
  { version: '1.0.34', date: '2026-07-27', items: ['新增可实际用于对话的外部联网搜索：支持 SearXNG、Tavily、Exa 与博查，并在请求中附带带编号的参考资料。', '工具与扩展增加搜索连通性测试；明确标注尚处于配置阶段的 MCP 与图像生成能力。'] },
  { version: '1.0.33', date: '2026-07-27', items: ['修复沉浸标题栏初始状态，并优化“我的”与关于页内容位置。', '子页面与底部导航栏改为直接联动，确保点击进入和返回时播放收缩、恢复动画。'] },
  { version: '1.0.32', date: '2026-07-27', items: ['修正子页面标题栏的滚动显隐方向，并调整“我的”与关于页内容位置。', '进入设置或关于时，底部 HDS 导航栏会以点击场景动画收缩隐藏。'] },
  { version: '1.0.31', date: '2026-07-27', items: ['设置与关于接入沉浸光感标题栏，支持材质渐变模糊与滚动动态隐藏。', '上移关于页内容，优化子页面的信息起始位置。'] },
  { version: '1.0.30', date: '2026-07-27', items: ['“我的”页设置与关于改用 ArkUI 原生 Navigation 返回栏与侧滑返回。'] },
  { version: '1.0.29', date: '2026-07-27', items: ['隐私政策改为独立信息卡片布局。'] },
  { version: '1.0.28', date: '2026-07-27', items: ['重构更新日志的独立卡片布局与回弹进场动效。', '调整日志头部位置，避开系统关闭按钮。'] },
  { version: '1.0.27', date: '2026-07-27', items: ['修复 New API 连接 JSON 的导入预览显示。', '同步首页更新说明内容。'] },
  { version: '1.0.26', date: '2026-07-27', items: ['优化更新日志视觉样式、图标显示与展开动效。'] },
  { version: '1.0.25', date: '2026-07-27', items: ['支持导入 New API 中转站连接 JSON。', '修复 OpenAI 兼容服务商自动补全 /v1/models 的模型获取与连接测试。'] },
  { version: '1.0.24', date: '2026-07-27', items: ['新增关于页更新日志，可查看各版本功能变化。', '更新日志使用原生 ArkUI 底部弹窗呈现。'] },
  { version: '1.0.23', date: '2026-07-27', items: ['支持将对话记录导出为 Markdown 文件。', '服务商模型支持自动选择与手动刷新可用列表。', '优化兼容服务商的连接测试。'] },
  { version: '1.0.22', date: '2026-07-26', items: ['统一页面边距，并优化平板与大屏显示。', '调整对话、服务商和我的页面的响应式布局。'] },
  { version: '1.0.21', date: '2026-07-26', items: ['优化首次使用引导的恢复流程与页面同步。', '改善我的页面、设置和关于页面的导航动画。'] },
  { version: '1.0.20', date: '2026-07-25', items: ['完善服务商配置引导与本地隐私说明。', '持续优化对话流式输出、模型切换与历史记录体验。'] }
];
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
  @State private showAboutSheet: boolean = false;
  @State private aboutSheetKind: number = 0;
  @State private expandedChangelogVersion: string = '1.1.3';
  @State private changelogContentEntered: boolean = false;
  @StorageLink('history_revision') @Watch('onHistoryRevisionChanged') private historyRevision: number = 0;
  @StorageLink('my_back_request_revision') @Watch('onBackRequested') private backRequestRevision: number = 0;
  @StorageLink('knowledge_file_picker_active') private knowledgeFilePickerActive: boolean = false;
  @StorageLink('layout_page_padding') private pagePadding: number = THEME_TOKENS.pagePadding;
  @StorageLink('appearance_color_mode') private appearanceColorMode: string = 'system';
  @StorageLink('appearance_page_background') private appearancePageBackground: string = '';
  private pageStack: NavPathStack = new NavPathStack();
  private homeScroller: Scroller = new Scroller();
  private settingsScroller: Scroller = new Scroller();
  private aboutScroller: Scroller = new Scroller();
  onMaterialChanged: (level: MaterialLevel) => void = (_level: MaterialLevel): void => {};
  onAppearanceChanged: (mode: string, accent: string) => void = (_mode: string, _accent: string): void => {};
  onSubPageChanged: (active: boolean) => void = (_active: boolean): void => {};

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
    if (this.backRequestRevision > 0 && this.section !== MySection.Home) this.returnToHome();
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
    if (next === MySection.Home) {
      this.returnToHome();
      return;
    }
    if (next === this.section) return;
    this.section = next;
    AppStorage.setOrCreate('my_section', next);
    AppStorage.set('my_section', next);
    this.pageStack.pushPathByName(next as string, false);
    this.onSubPageChanged(true);
  }

  private returnToHome(): void {
    if (this.section === MySection.Home) return;
    this.section = MySection.Home;
    AppStorage.setOrCreate('my_section', MySection.Home);
    AppStorage.set('my_section', MySection.Home);
    this.pageStack.pop();
    this.onSubPageChanged(false);
  }

  private onDestinationDisappear(section: MySection): void {
    // The document picker temporarily backgrounds the destination. That is
    // not a navigation pop, so the HDS tab bar must remain hidden.
    if (section === MySection.Knowledge && this.knowledgeFilePickerActive) return;
    if (this.section !== section) return;
    this.section = MySection.Home;
    AppStorage.setOrCreate('my_section', MySection.Home);
    AppStorage.set('my_section', MySection.Home);
    this.onSubPageChanged(false);
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

  private openOnboarding(): void {
    AppStore.saveOnboardingIntroStep(0);
    const revision: number = Date.now();
    AppStorage.setOrCreate('onboarding_request_revision', revision);
    AppStorage.set('onboarding_request_revision', revision);
  }

  private openGitHub(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    void context.startAbility({ action: 'ohos.want.action.viewData', uri: 'https://github.com/LoMoCatAp/ImmersiveAI' });
  }

  private openAfdian(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    void context.startAbility({ action: 'ohos.want.action.viewData', uri: 'https://ifdian.net/a/lomocat' });
  }

  private openChangelog(): void {
    this.expandedChangelogVersion = CHANGELOG_ENTRIES[0].version;
    this.changelogContentEntered = false;
    this.aboutSheetKind = 1;
    this.showAboutSheet = true;
    setTimeout((): void => { this.changelogContentEntered = true; }, 80);
  }

  private openPrivacyPolicy(): void {
    this.aboutSheetKind = 2;
    this.showAboutSheet = true;
  }

  @Builder
  private changelogSheet(): void {
    Column({ space: 14 }) {
      Text('').width(36).height(4).borderRadius(2).backgroundColor(THEME_TOKENS.secondaryText).opacity(0.32);
      Row({ space: 12 }) {
        Stack() {
          Image($r('app.media.background')).width(52).height(52).objectFit(ImageFit.Cover);
          Image($r('app.media.foreground')).width(52).height(52).objectFit(ImageFit.Cover);
        }.width(52).height(52).borderRadius(16).clip(true).backgroundColor(this.accentColor);
        Column({ space: 4 }) {
          Text('AIBox').fontSize(20).fontWeight(FontWeight.Bold);
          Text(`当前版本 v${this.appVersion.length > 0 ? this.appVersion : CHANGELOG_ENTRIES[0].version}`)
            .fontSize(13)
            .fontColor(THEME_TOKENS.secondaryText);
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
      }.width('100%').margin({ top: 48 }).padding(14).backgroundColor(THEME_TOKENS.surface).borderRadius(20);
      Column({ space: 12 }) {
        Text('更新日志').fontSize(16).fontWeight(FontWeight.Medium).width('100%');
        Scroll() {
          Column({ space: 10 }) {
            ForEach(CHANGELOG_ENTRIES, (entry: ChangelogEntry): void => {
              Column({ space: 0 }) {
              Row({ space: 10 }) {
                Column({ space: 3 }) {
                  Text(`v${entry.version}`).fontSize(17).fontWeight(FontWeight.Medium);
                  Text(entry.date).fontSize(12).fontColor(THEME_TOKENS.secondaryText);
                }.alignItems(HorizontalAlign.Start).layoutWeight(1);
                Image($r('app.media.changelog_arrow'))
                  .width(20)
                  .height(20)
                  .rotate({ angle: this.expandedChangelogVersion === entry.version ? 180 : 0 })
                  .animation({ duration: 180, curve: Curve.EaseOut });
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .onClick((): void => {
                this.expandedChangelogVersion = this.expandedChangelogVersion === entry.version ? '' : entry.version;
              })
              .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.97 });
              if (this.expandedChangelogVersion === entry.version) {
                Column({ space: 8 }) {
                  Divider().margin({ bottom: 12 });
                  ForEach(entry.items, (item: string): void => {
                    Text(`• ${item}`).fontSize(14).lineHeight(21).fontColor(THEME_TOKENS.secondaryText).width('100%');
                  }, (item: string): string => item);
                }.alignItems(HorizontalAlign.Start).width('100%').padding({ left: 16, right: 16, bottom: 16 }).transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: -8 })).animation({ duration: 180, curve: Curve.EaseOut }));
              }
              }.width('100%').backgroundColor(THEME_TOKENS.surface).borderRadius(18);
            }, (entry: ChangelogEntry): string => entry.version);
          }.width('100%');
        }
        .width('100%')
        .height(350)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
      }
      .width('100%')
      .opacity(this.changelogContentEntered ? 1 : 0)
      .translate({ y: this.changelogContentEntered ? 0 : 24 })
      .scale({ x: this.changelogContentEntered ? 1 : 0.97, y: this.changelogContentEntered ? 1 : 0.97 })
      .animation({ duration: 420, curve: Curve.Friction });
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 20 });
  }

  @Builder
  private pageHeader(title: string): void {
    Text(title).fontSize(24).fontWeight(FontWeight.Bold).width('100%');
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
                .backgroundColor(this.accentColor)
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
          ForEach([0, 1, 2, 3, 4], (level: number) => { Text('').width(10).height(10).borderRadius(2).backgroundColor(this.accentColor).opacity(this.heatOpacity(level)); });
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
          Image($r('app.media.my_settings')).width(22).height(22).fillColor(this.accentColor);
          Column({ space: 3 }) { Text('设置').fontSize(17).fontWeight(FontWeight.Medium); Text('外观、聊天与沉浸光感').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.Settings); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Row({ space: 12 }) {
          Image($r('app.media.my_prompt')).width(22).height(22).fillColor(this.accentColor);
          Column({ space: 3 }) { Text('提示词与记忆').fontSize(17).fontWeight(FontWeight.Medium); Text('默认指令、长期偏好与本地记忆').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.Prompt); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Row({ space: 12 }) {
          Image($r('app.media.my_skills')).width(22).height(22).fillColor(this.accentColor);
          Column({ space: 3 }) { Text('技能').fontSize(17).fontWeight(FontWeight.Medium); Text('写作、编程、学习与自定义工作流').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.Skills); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Row({ space: 12 }) {
          Image($r('app.media.my_knowledge')).width(22).height(22).fillColor(this.accentColor);
          Column({ space: 3 }) { Text('知识库').fontSize(17).fontWeight(FontWeight.Medium); Text('本地资料摘要与对话参考内容').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.Knowledge); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Row({ space: 12 }) {
          Image($r('app.media.my_tools')).width(22).height(22).fillColor(this.accentColor);
          Column({ space: 3 }) { Text('工具与扩展').fontSize(17).fontWeight(FontWeight.Medium); Text('MCP 服务、联网搜索与图像生成配置').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.Tools); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Row({ space: 12 }) {
          Image($r('app.media.my_about')).width(22).height(22).fillColor(this.accentColor);
          Column({ space: 3 }) { Text('关于').fontSize(17).fontWeight(FontWeight.Medium); Text('AIBox、版本与项目地址').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.navigateTo(MySection.About); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
    }.width('100%').height(408).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private appearanceList(): void {
    List({ space: 0 }) {
      ListItem() { Row({ space: 12 }) { Image($r('app.media.setting_theme')).width(20).height(20).fillColor(this.accentColor); Text('主题色').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.selectOptions(ACCENT_OPTIONS)).selected(this.optionIndex(ACCENT_OPTIONS, this.accentColor)).value(this.labels(ACCENT_OPTIONS)[this.optionIndex(ACCENT_OPTIONS, this.accentColor)]).onSelect((index: number): void => this.selectAccent(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() { Row({ space: 12 }) { Image($r('app.media.setting_display')).width(20).height(20).fillColor(this.accentColor); Text('显示模式').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.selectOptions(COLOR_MODE_OPTIONS)).selected(this.optionIndex(COLOR_MODE_OPTIONS, this.colorMode)).value(this.labels(COLOR_MODE_OPTIONS)[this.optionIndex(COLOR_MODE_OPTIONS, this.colorMode)]).onSelect((index: number): void => this.selectColorMode(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); }
    }.width('100%').height(112).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private chatAppearanceList(): void {
    List({ space: 0 }) {
      ListItem() { Column({ space: 6 }) { Row({ space: 12 }) { Image($r('app.media.setting_chat')).width(20).height(20).fillColor(this.accentColor); Text('聊天字号').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Text(`${this.chatTextSize} vp`).fontColor(THEME_TOKENS.secondaryText); }.width('100%'); Slider({ value: this.chatTextSize, min: 12, max: 22, step: 1, style: SliderStyle.OutSet }).onChange((value: number): void => this.saveTextSize(value)).width('100%'); }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }); }
    }.width('100%').height(88).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private materialList(): void {
    List({ space: 0 }) { ListItem() { Row({ space: 12 }) { Image($r('app.media.setting_material')).width(20).height(20).fillColor(this.accentColor); Text('档位').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.materialLabels().map((label: string): SelectOption => ({ value: label }))).selected(this.materialIndex()).value(this.summary).onSelect((index: number): void => this.selectMaterial(index)); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }); } }.width('100%').height(56).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
  }

  @Builder
  private guideList(): void {
    List({ space: 0 }) {
      ListItem() {
        Row({ space: 12 }) {
          Image($r('app.media.setting_guide')).width(20).height(20).fillColor(this.accentColor);
          Column({ space: 3 }) { Text('使用引导').fontSize(17).fontWeight(FontWeight.Medium); Text('重新查看服务商配置与隐私说明').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 }).onClick((): void => { this.openOnboarding(); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
      }
    }.width('100%').height(72).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
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
      Text('外观').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
      this.appearanceList();
      Text('聊天外观').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.chatAppearanceList();
      Text('沉浸光感').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.materialList();
      Text('使用').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%').margin({ top: 12 });
      this.guideList();
    }.width('100%');
  }

  @Builder
  private aboutContent(): void {
    Column({ space: 16 }) {
      Text('应用信息').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
      List({ space: 0 }) {
        ListItem() { Column({ space: 5 }) { Text('AIBox').fontSize(20).fontWeight(FontWeight.Bold).width('100%'); Text('作者：LomoCat').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%'); Text(`版本：${this.appVersion.length > 0 ? this.appVersion : '读取中'}`).fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%'); }.width('100%').padding(16); }
        ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
        ListItem() { Row() { Text('GitHub').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Text('github.com/LoMoCatAp/ImmersiveAI').fontSize(13).fontColor(this.accentColor); }.width('100%').padding(16).onClick((): void => this.openGitHub()); }
        ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
        ListItem() { Row() { Text('爱发电').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Text('ifdian.net/a/lomocat').fontSize(13).fontColor(this.accentColor); }.width('100%').padding(16).onClick((): void => this.openAfdian()); }
        ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
        ListItem() {
          Row() {
            Column({ space: 3 }) {
              Text('更新日志').fontSize(17).fontWeight(FontWeight.Medium);
              Text('查看各版本功能变化').fontSize(13).fontColor(THEME_TOKENS.secondaryText);
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText);
          }.width('100%').padding(16).onClick((): void => this.openChangelog()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 });
        }
        ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
        ListItem() { Row() { Column({ space: 3 }) { Text('隐私政策').fontSize(17).fontWeight(FontWeight.Medium); Text('本地数据、第三方服务与权限说明').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1); Text('›').fontSize(24).fontColor(THEME_TOKENS.secondaryText); }.width('100%').padding(16).onClick((): void => { this.openPrivacyPolicy(); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.96 }); }
      }.width('100%').height(358).backgroundColor(THEME_TOKENS.surface).borderRadius(18).scrollBar(BarState.Off);
    }.width('100%');
  }

  @Builder
  private privacySheet(): void {
    Column({ space: 14 }) {
      Text('').width(36).height(4).borderRadius(2).backgroundColor(THEME_TOKENS.secondaryText).opacity(0.32);
      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 6 }) {
            Text('隐私政策').fontSize(20).fontWeight(FontWeight.Bold).width('100%');
            Text('生效日期：2026 年 7 月 26 日').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
          }.alignItems(HorizontalAlign.Start).width('100%');
          Divider();
          ForEach(PRIVACY_ENTRIES, (entry: PrivacyEntry): void => {
            Column({ space: 8 }) {
              Text(entry.title).fontSize(16).fontWeight(FontWeight.Medium).width('100%');
              Text(entry.content).fontSize(15).lineHeight(22).fontColor(THEME_TOKENS.primaryText).width('100%');
            }.alignItems(HorizontalAlign.Start).width('100%');
          }, (entry: PrivacyEntry): string => entry.title);
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(18)
        .backgroundColor(THEME_TOKENS.surface)
        .borderRadius(22);
      }
      .width('100%')
      .height(400)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 44, bottom: 20 });
  }

  @Builder
  private aboutSheet(): void {
    if (this.aboutSheetKind === 1) this.changelogSheet();
    else this.privacySheet();
  }

  private immersiveTitleBar(title: string): HdsNavigationTitleBarOptions {
    return {
      content: { title: { mainTitle: title } },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        // HDS defaults to a light foreground in the fully transparent
        // immersive state. Explicit token colors keep the native title and
        // back button readable before the content has been scrolled.
        originalStyle: {
          contentStyle: {
            titleStyle: { mainTitleColor: THEME_TOKENS.primaryText },
            backIconStyle: { iconColor: THEME_TOKENS.primaryText }
          }
        },
        scrollEffectStyle: {
          contentStyle: {
            titleStyle: { mainTitleColor: THEME_TOKENS.primaryText },
            backIconStyle: { iconColor: THEME_TOKENS.primaryText }
          }
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      }
    };
  }

  private destinationBackground(): ResourceColor {
    if (new RegExp('^#[0-9A-Fa-f]{6}$').test(this.appearancePageBackground)) return this.appearancePageBackground;
    if (this.appearanceColorMode === 'dark') return '#10131A';
    if (this.appearanceColorMode === 'light') return '#F7F8FC';
    return THEME_TOKENS.pageBackground;
  }

  private dynamicTitleBar(): DynamicHideParams {
    return {
      hideTitleArea: true,
      hideStatusBar: true,
      // Keep the destination title visible at rest. It starts to hide only
      // after the content has a meaningful upward scroll distance.
      mode: HideMode.SCROLL_UP_TO,
      hideOffset: 48,
      hideRatio: 2
    };
  }

  @Builder
  private settingsDestination(): void {
    HdsNavDestination() {
      Scroll(this.settingsScroller) {
        this.settingsContent();
      }
      .width('100%')
      .height('100%')
      .padding({ left: this.pagePadding, right: this.pagePadding, top: THEME_TOKENS.subpageContentTop, bottom: 132 })
      .backgroundColor(this.destinationBackground())
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
    }
    .titleBar(this.immersiveTitleBar('设置'))
    .hideTitleBar(false)
    .dynamicHideTitleBar(this.dynamicTitleBar())
    .bindToScrollable([this.settingsScroller])
    .hideBackButton(false)
    .onBackPressed((): boolean => {
      // Keep the native back button and side-swipe in one Navigation path.
      // onHidden synchronizes the page state after the destination pops.
      return false;
    })
    .onHidden((): void => this.onDestinationDisappear(MySection.Settings));
  }

  @Builder
  private aboutDestination(): void {
    HdsNavDestination() {
      Scroll(this.aboutScroller) {
        this.aboutContent();
      }
      .width('100%')
      .height('100%')
      .padding({ left: this.pagePadding, right: this.pagePadding, top: THEME_TOKENS.subpageContentTop, bottom: 132 })
      .translate({ y: ABOUT_CONTENT_OFFSET })
      .backgroundColor(this.destinationBackground())
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
    }
    .titleBar(this.immersiveTitleBar('关于'))
    .hideTitleBar(false)
    .dynamicHideTitleBar(this.dynamicTitleBar())
    .bindToScrollable([this.aboutScroller])
    .hideBackButton(false)
    .onBackPressed((): boolean => {
      return false;
    })
    .onHidden((): void => this.onDestinationDisappear(MySection.About));
  }

  @Builder
  private capabilityDestination(section: MySection, title: string, page: string): void {
    HdsNavDestination() {
      Stack() {
        Column().width('100%').height('100%').backgroundColor(this.destinationBackground());
        CapabilityCenterView({ page: page });
      }.width('100%').height('100%');
    }
    .titleBar(this.immersiveTitleBar(title))
    .hideTitleBar(false)
    .hideBackButton(false)
    .onBackPressed((): boolean => false)
    .onHidden((): void => this.onDestinationDisappear(section));
  }

  @Builder
  private myDestinations(name: string): void {
    if (name === 'settings') this.settingsDestination();
    else if (name === 'prompt') this.capabilityDestination(MySection.Prompt, '提示词与记忆', 'prompt');
    else if (name === 'skills') this.capabilityDestination(MySection.Skills, '技能', 'skills');
    else if (name === 'knowledge') this.capabilityDestination(MySection.Knowledge, '知识库', 'knowledge');
    else if (name === 'tools') this.capabilityDestination(MySection.Tools, '工具与扩展', 'tools');
    else if (name === 'about') this.aboutDestination();
  }

  build() {
    HdsNavigation(this.pageStack) {
      Scroll(this.homeScroller) {
        this.homeContent();
      }
      .width('100%')
      .height('100%')
      .padding({ left: this.pagePadding, right: this.pagePadding, top: 0, bottom: 132 })
      .translate({ y: 15 })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
    }
    .mode(NavigationMode.Stack)
    // The root destination has no title. Hide only its title bar so the
    // nested HdsTabs content remains laid out normally.
    .hideTitleBar(true)
    .hideToolBar(true)
    .navDestination(this.myDestinations)
    .width('100%')
    .height('100%')
    .bindSheet($$this.showAboutSheet, this.aboutSheet(), {
      detents: [SheetSize.FIT_CONTENT],
      preferType: SheetType.BOTTOM,
      showClose: true,
      dragBar: false,
      scrollSizeMode: ScrollSizeMode.CONTINUOUS,
      onWillDismiss: (): void => {
        this.changelogContentEntered = false;
        this.showAboutSheet = false;
        this.aboutSheetKind = 0;
      }
    });
  }
}
