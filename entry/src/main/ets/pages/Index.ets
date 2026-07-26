import { MainShellView } from '../views/MainShellView';
import { THEME_TOKENS, contentWidthFor, pagePaddingFor } from '../common/ThemeTokens';
import { AppStore } from '../common/AppStore';
import { CustomTheme } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ShellTab } from '../model/ShellModels';

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
  @StorageLink('shell_selected_tab') private selectedTab: number = ShellTab.Chat;
  @StorageLink('my_section') private mySection: string = 'home';
  @State private startupNoticeShown: boolean = false;

  aboutToAppear(): void {
    AppStorage.setOrCreate('appearance_color_mode', AppStore.readAppearance('color_mode', 'system'));
    AppStorage.setOrCreate('appearance_accent_color', AppStore.readAppearance('accent_color', '#3559D8'));
    AppStorage.setOrCreate('appearance_page_background', AppStore.readAppearance('page_background', ''));
    this.showStartupNotice();
  }

  onBackPress(): boolean {
    if (this.selectedTab !== ShellTab.My || this.mySection === 'home') return false;
    const revision: number = Date.now();
    AppStorage.setOrCreate('my_back_request_revision', revision);
    AppStorage.set('my_back_request_revision', revision);
    return true;
  }

  private onStartupNoticeChanged(): void {
    this.showStartupNotice();
  }

  private showStartupNotice(): void {
    if (this.startupNoticeShown || this.startupNoticeRevision <= 0) return;
    this.startupNoticeShown = true;
    const message: string = this.startupIsFirstInstall
      ? '已通过系统应用状态检测到首次安装。首次启动引导将在后续版本提供；现在可先前往“供应商”添加并测试 AI 服务。'
      : `已检测到 ${this.startupVersionName} 版本首次运行。首次启动引导将在后续版本提供；当前设置与本地会话会继续保留。`;
    void promptAction.showDialog({ title: '欢迎使用 AIBox', message, buttons: [{ text: '知道了', color: this.appearanceAccentColor }] });
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
    Column() {
      MainShellView({
        contentWidth: contentWidthFor(this.windowWidth),
        pagePadding: pagePaddingFor(this.windowWidth)
      })
      .layoutWeight(1)
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
