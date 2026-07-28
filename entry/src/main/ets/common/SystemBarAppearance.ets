import { window } from '@kit.ArkUI';

export class SystemBarAppearance {
  private static mainWindow: window.Window | undefined = undefined;
  private static selectedMode: string = 'system';
  private static systemMode: string = 'light';

  static bind(mainWindow: window.Window, mode: string, systemMode: string): void {
    SystemBarAppearance.mainWindow = mainWindow;
    SystemBarAppearance.systemMode = systemMode;
    SystemBarAppearance.apply(mode);
  }

  static updateSystemMode(systemMode: string): void {
    SystemBarAppearance.systemMode = systemMode;
    if (SystemBarAppearance.selectedMode === 'system') SystemBarAppearance.apply('system');
  }

  static apply(mode: string): void {
    const target: window.Window | undefined = SystemBarAppearance.mainWindow;
    SystemBarAppearance.selectedMode = mode;
    if (target === undefined) return;
    const isDark: boolean = (mode === 'system' ? SystemBarAppearance.systemMode : mode) === 'dark';
    void target.setWindowSystemBarProperties({
      statusBarColor: isDark ? '#10131A' : '#F7F8FC',
      navigationBarColor: isDark ? '#10131A' : '#F7F8FC',
      isStatusBarLightIcon: isDark,
      isNavigationBarLightIcon: isDark
    }).catch((): void => {});
  }
}
