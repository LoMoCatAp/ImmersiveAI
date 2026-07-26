import { HdsTabs, HdsTabsController, hdsMaterial, DividerMode } from '@kit.UIDesignKit';
import { CustomTheme } from '@kit.ArkUI';
import { ChatView } from './ChatView';
import { HistoryView } from './HistoryView';
import { ProviderSettingsView } from './ProviderSettingsView';
import { MyView } from './MyView';
import { CapabilityDetector } from '../common/CapabilityDetector';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { AppStore } from '../common/AppStore';
import { MainNavigation } from '../components/MainNavigation';
import { AppHeader } from '../components/AppHeader';
import { NavigationIntent, ShellTab, MaterialMode as ShellMaterialMode, NavigationSource, MaterialLevel } from '../model/ShellModels';
import { SystemBarAppearance } from '../common/SystemBarAppearance';

@Component
export struct MainShellView {
  @State selectedTab: ShellTab = ShellTab.Chat;
  @Prop contentWidth: string = '100%';
  @Prop pagePadding: number = 20;
  private tabsController: HdsTabsController = new HdsTabsController();
  private chatScroller: Scroller = new Scroller();
  private historyScroller: Scroller = new Scroller();
  private providerScroller: Scroller = new Scroller();
  @StorageLink('provider_edit_revision') @Watch('onProviderEditRequested') private providerEditRevision: number = 0;
  private myScroller: Scroller = new Scroller();
  @State private materialLevel: MaterialLevel = MaterialLevel.Gentle;
  @StorageLink('appearance_color_mode') private appearanceColorMode: string = 'system';
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  @StorageLink('appearance_page_background') private appearancePageBackground: string = '';
  private material: ShellMaterialMode = ShellMaterialMode.Fallback;
  private materialReason: string = '正在检测沉浸光感能力';

  aboutToAppear(): void {
    this.selectedTab = AppStore.shellViewModel.state.selectedTab;
    AppStorage.setOrCreate('shell_selected_tab', this.selectedTab);
    const capability = CapabilityDetector.detect();
    this.material = capability.mode === 'official' ? ShellMaterialMode.VerifiedOfficial : ShellMaterialMode.Fallback;
    this.materialReason = AppStore.shellViewModel.state.material.status;
    this.materialLevel = AppStore.shellViewModel.state.material.effective;
    this.applyAppearance(AppStore.readAppearance('color_mode', 'system'), AppStore.readAppearance('accent_color', '#3559D8'));
    SystemBarAppearance.apply(AppStore.readAppearance('color_mode', 'system'));
    AppStorage.setOrCreate('appearance_page_background', AppStore.readAppearance('page_background', ''));
    AppStorage.setOrCreate('appearance_chat_text_size', AppStore.readAppearance('chat_text_size', '16'));
    this.tabsController.bindScroller(0, this.chatScroller);
    this.tabsController.bindScroller(1, this.historyScroller);
    this.tabsController.bindScroller(2, this.providerScroller);
    this.tabsController.bindScroller(3, this.myScroller);
  }

  private navigate(intent: NavigationIntent): void {
    AppStore.shellViewModel.navigate(intent);
    this.selectedTab = AppStore.shellViewModel.state.selectedTab;
    AppStorage.set('shell_selected_tab', this.selectedTab);
    if (this.material === ShellMaterialMode.VerifiedOfficial) this.tabsController.changeIndex(this.selectedTab);
  }

  private async openHistory(id: string): Promise<void> {
    if (id.length > 0) await AppStore.chatViewModel.load(id);
    this.navigate({ target: ShellTab.Chat, source: NavigationSource.System, requestId: Date.now() });
  }

  private applyMaterial(level: MaterialLevel): void {
    this.materialLevel = level;
    this.materialReason = AppStore.shellViewModel.state.material.status;
  }

  private applyAppearance(colorMode: string, accent: string): void {
    AppStorage.setOrCreate('appearance_color_mode', colorMode);
    AppStorage.setOrCreate('appearance_accent_color', accent);
  }

  private onProviderEditRequested(): void {
    this.providerScroller.scrollEdge(Edge.Top);
  }

  private activeColorMode(): ThemeColorMode {
    if (this.appearanceColorMode === 'dark') return ThemeColorMode.DARK;
    if (this.appearanceColorMode === 'light') return ThemeColorMode.LIGHT;
    return ThemeColorMode.SYSTEM;
  }

  private theme(): CustomTheme {
    return { colors: { brand: this.appearanceAccentColor, iconEmphasize: this.appearanceAccentColor, interactiveFocus: this.appearanceAccentColor, interactiveActive: this.appearanceAccentColor } };
  }

  private pageBackground(): ResourceColor {
    if (new RegExp('^#[0-9A-Fa-f]{6}$').test(this.appearancePageBackground)) return this.appearancePageBackground;
    if (this.appearanceColorMode === 'dark') return '#10131A';
    if (this.appearanceColorMode === 'light') return '#F7F8FC';
    return THEME_TOKENS.pageBackground;
  }

  private titleFor(tab: ShellTab): string {
    if (tab === ShellTab.History) return '历史';
    if (tab === ShellTab.Providers) return '供应商';
    if (tab === ShellTab.My) return '我的';
    return '聊天';
  }

  @Builder
  private tabLabel(label: string, tab: ShellTab): void {
    Text(label)
      .width('100%')
      .height(48)
      .textAlign(TextAlign.Center)
      .fontSize(14)
      .fontColor(this.selectedTab === tab ? this.appearanceAccentColor : $r('app.color.text_secondary'))
      .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 })
      .backgroundColor('#00000000');
  }

  @Builder
  private hdsPageContent(): void {
    HdsTabs({ controller: this.tabsController }) {
      TabContent() { ChatView({ onNavigate: (intent: NavigationIntent): void => { this.navigate(intent); } }) }.tabBar(this.tabLabel('聊天', ShellTab.Chat))
      TabContent() { HistoryView({ onOpen: (id: string): void => { void this.openHistory(id); } }) }.tabBar(this.tabLabel('历史', ShellTab.History))
       TabContent() { Scroll(this.providerScroller) { ProviderSettingsView({ onReturnChat: (): void => { this.navigate({ target: ShellTab.Chat, source: NavigationSource.System, requestId: Date.now() }); } }) }.scrollBar(BarState.Off).width('100%').height('100%') }.tabBar(this.tabLabel('供应商', ShellTab.Providers))
      TabContent() { Scroll(this.myScroller) { MyView({ onMaterialChanged: (level: MaterialLevel): void => { this.applyMaterial(level); }, onAppearanceChanged: (mode: string, accent: string): void => { this.applyAppearance(mode, accent); } }) }.scrollBar(BarState.Off).width('100%').height('100%') }.tabBar(this.tabLabel('我的', ShellTab.My))
    }
    .barOverlap(true)
    .vertical(false)
    .barPosition(BarPosition.End)
    .divider({ mode: DividerMode.NONE })
    .barFloatingStyle({ barBottomMargin: 4, adaptToHandedness: true, lightColor: this.appearanceAccentColor, systemMaterialEffect: this.materialLevel === MaterialLevel.Off ? undefined : { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: this.toHdsLevel(this.materialLevel) } })
    .onChange((index: number): void => { this.navigate({ target: index as ShellTab, source: NavigationSource.HdsTabs, requestId: Date.now() }); })
    .width('100%').height('100%');
  }

  private toHdsLevel(level: MaterialLevel): hdsMaterial.MaterialLevel {
    if (level === MaterialLevel.Exquisite) return hdsMaterial.MaterialLevel.EXQUISITE;
    if (level === MaterialLevel.Smooth) return hdsMaterial.MaterialLevel.SMOOTH;
    if (level === MaterialLevel.Adaptive) return hdsMaterial.MaterialLevel.ADAPTIVE;
    return hdsMaterial.MaterialLevel.GENTLE;
  }

  build() {
    WithTheme({ colorMode: this.activeColorMode(), theme: this.theme() }) {
    Column() {
      if (this.material === ShellMaterialMode.VerifiedOfficial) {
        this.hdsPageContent();
      } else {
        AppHeader({ title: this.titleFor(this.selectedTab), materialMode: this.material });
        Column() {
          if (this.selectedTab === ShellTab.Chat) ChatView({ onNavigate: (intent: NavigationIntent): void => { this.navigate(intent); } });
          else if (this.selectedTab === ShellTab.History) HistoryView({ onOpen: (id: string): void => { void this.openHistory(id); } });
          else if (this.selectedTab === ShellTab.Providers) ProviderSettingsView({ onReturnChat: (): void => { this.navigate({ target: ShellTab.Chat, source: NavigationSource.System, requestId: Date.now() }); } });
          else MyView({ onMaterialChanged: (level: MaterialLevel): void => { this.applyMaterial(level); }, onAppearanceChanged: (mode: string, accent: string): void => { this.applyAppearance(mode, accent); } });
        }
        .layoutWeight(1)
        .width('100%');
        MainNavigation({ selectedTab: this.selectedTab, onSelect: (intent: NavigationIntent): void => { this.navigate(intent); } });
      }
    }.width('100%').height('100%').backgroundColor(this.pageBackground());
    }
  }
}
