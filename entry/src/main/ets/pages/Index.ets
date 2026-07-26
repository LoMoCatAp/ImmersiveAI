import { MainShellView } from '../views/MainShellView';
import { THEME_TOKENS, contentWidthFor, pagePaddingFor } from '../common/ThemeTokens';
import { AppStore } from '../common/AppStore';
import { CustomTheme } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ShellTab } from '../model/ShellModels';
import { FirstLaunchGuide } from '../components/FirstLaunchGuide';

@Entry
@Component
struct Index {
  @State private windowWidth: number = THEME_TOKENS.compactWidth;
  @StorageLink('appearance_color_mode') private appearanceColorMode: string = 'system';
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  @StorageLink('appearance_page_background') private appearancePageBackground: string = '';
  @StorageLink('startup_notice_revision') @Watch('onStartupNoticeChanged') private startupNoticeRevision: number = 0;
  @StorageLink('startup_is_first_install') private startupIsFirstInstall: boolean = false;
  @StorageLink('startup_version_name') private startupVersionName: string = '';
  @StorageLink('startup_should_show_onboarding') private startupShouldShowOnboarding: boolean = false;
  @StorageLink('onboarding_request_revision') @Watch('onOnboardingRequested') private onboardingRequestRevision: number = 0;
  @StorageLink('onboarding_flow_stage') private onboardingFlowStage: string = '';
  @StorageLink('shell_selected_tab') private selectedTab: number = ShellTab.Chat;
  @StorageLink('my_section') private mySection: string = 'home';
  @State private startupNoticeShown: boolean = false;
  @State private showOnboarding: boolean = false;

  aboutToAppear(): void {
    AppStorage.setOrCreate('appearance_color_mode', AppStore.readAppearance('color_mode', 'system'));
    AppStorage.setOrCreate('appearance_accent_color', AppStore.readAppearance('accent_color', '#3559D8'));
    AppStorage.setOrCreate('appearance_page_background', AppStore.readAppearance('page_background', ''));
    this.showStartupNotice();
  }

  onBackPress(): boolean {
    if (this.showOnboarding) {
      this.deferOnboarding();
      return true;
    }
    if (this.selectedTab !== ShellTab.My || this.mySection === 'home') return false;
    const revision: number = Date.now();
    AppStorage.setOrCreate('my_back_request_revision', revision);
    AppStorage.set('my_back_request_revision', revision);
    return true;
  }

  private onStartupNoticeChanged(): void {
    this.showStartupNotice();
  }

  private onOnboardingRequested(): void {
    if (this.onboardingRequestRevision > 0) this.showOnboarding = true;
  }

  private showStartupNotice(): void {
    if (this.startupNoticeShown || this.startupNoticeRevision <= 0) return;
    this.startupNoticeShown = true;
    if (this.startupShouldShowOnboarding && this.onboardingFlowStage.length === 0) {
      this.showOnboarding = true;
      return;
    }
    const version: string = this.startupVersionName.length > 0 ? this.startupVersionName : '最新版本';
    const message: string = `更新版本：${version}\n\n更新内容：\n- 优化首次引导的步骤提示与动效\n- 修正 DeepSeek 引导默认模型\n- 改进服务商配置与首次对话流程\n\n欢迎继续使用 AIBox`;
    void promptAction.showDialog({ title: '更新说明', message, buttons: [{ text: '知道了', color: this.appearanceAccentColor }] });
  }

  private beginProviderSetup(): void {
    this.showOnboarding = false;
    AppStore.saveOnboardingIntroStep(0);
    AppStore.saveOnboardingStage('provider_setup');
    const revision: number = Date.now();
    AppStorage.setOrCreate('onboarding_provider_setup_revision', revision);
    AppStorage.set('onboarding_provider_setup_revision', revision);
  }

  private deferOnboarding(): void {
    this.showOnboarding = false;
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

  build() {
    WithTheme({ colorMode: this.activeColorMode(), theme: this.theme() }) {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        MainShellView({
          contentWidth: contentWidthFor(this.windowWidth),
          pagePadding: pagePaddingFor(this.windowWidth)
        })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%');
      if (this.showOnboarding) FirstLaunchGuide({ accentColor: this.appearanceAccentColor, onBeginProviderSetup: (): void => { this.beginProviderSetup(); }, onDefer: (): void => { this.deferOnboarding(); } })
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.96, y: 0.96 })).animation({ duration: 220, curve: Curve.EaseOut }));
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBackground())
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onAreaChange((_oldArea: Area, newArea: Area): void => {
      const nextWidth: number = Number(newArea.width);
      if (nextWidth > 0) this.windowWidth = nextWidth;
    });
    }
  }
}
