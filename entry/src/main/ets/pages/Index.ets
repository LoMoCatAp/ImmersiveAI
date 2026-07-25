import { MainShellView } from '../views/MainShellView';
import { THEME_TOKENS, contentWidthFor, pagePaddingFor } from '../common/ThemeTokens';
import { AppStore } from '../common/AppStore';
import { CustomTheme } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State private windowWidth: number = THEME_TOKENS.compactWidth;
  @StorageLink('appearance_color_mode') private appearanceColorMode: string = 'system';
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  @StorageLink('appearance_page_background') private appearancePageBackground: string = '';

  aboutToAppear(): void {
    AppStorage.setOrCreate('appearance_color_mode', AppStore.readAppearance('color_mode', 'system'));
    AppStorage.setOrCreate('appearance_accent_color', AppStore.readAppearance('accent_color', '#3559D8'));
    AppStorage.setOrCreate('appearance_page_background', AppStore.readAppearance('page_background', ''));
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
