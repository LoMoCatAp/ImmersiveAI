import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppStore } from '../common/AppStore';
import { SystemBarAppearance } from '../common/SystemBarAppearance';
export default class EntryAbility extends UIAbility {
  onWindowStageCreate(stage: window.WindowStage): void {
    void this.loadMainPage(stage);
  }

  private async loadMainPage(stage: window.WindowStage): Promise<void> {
    // Views read provider data in aboutToAppear, so initialize persistent state first.
    await AppStore.initialize(this.context);
    try {
      await AppStore.publishStartupNotice();
    } catch (_) {
      // Startup remains available when bundle status cannot be read.
    }
    const mainWindow: window.Window = await stage.getMainWindow();
    SystemBarAppearance.bind(mainWindow, AppStore.readAppearance('color_mode', 'system'));
    stage.loadContent('pages/Index', (error: Error): void => { if (error) return; });
  }

  onWindowStageDestroy(): void { void AppStore.database.close(); }
}
