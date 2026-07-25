import { window } from '@kit.ArkUI';

export class SystemBarAppearance {
  private static mainWindow: window.Window | undefined = undefined;

  static bind(mainWindow: window.Window, mode: string): void {
    SystemBarAppearance.mainWindow = mainWindow;
    SystemBarAppearance.apply(mode);
  }

  static apply(mode: string): void {
    const target: window.Window | undefined = SystemBarAppearance.mainWindow;
    if (target === undefined || mode === 'system') return;
    const isDark: boolean = mode === 'dark';
    void target.setWindowSystemBarProperties({
      statusBarColor: isDark ? '#10131A' : '#F7F8FC',
      navigationBarColor: isDark ? '#10131A' : '#F7F8FC',
      isStatusBarLightIcon: isDark,
      isNavigationBarLightIcon: isDark
    }).catch((): void => {});
  }
}
