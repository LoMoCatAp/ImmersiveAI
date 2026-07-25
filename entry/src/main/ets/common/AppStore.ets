import { common } from '@kit.AbilityKit';
import { DatabaseManager } from '../data/DatabaseManager';
import { ProviderRepository } from '../data/ProviderRepository';
import { ChatRepository } from '../data/ChatRepository';
import { AssetCredentialStore } from '../data/AssetCredentialStore';
import { ProviderViewModel } from '../viewmodel/ProviderViewModel';
import { HistoryViewModel } from '../viewmodel/HistoryViewModel';
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { StreamingChatService } from '../service/StreamingChatService';
import { AppShellViewModel } from '../viewmodel/AppShellViewModel';
import { preferences } from '@kit.ArkData';
import { MaterialLevel } from '../model/ShellModels';

export class AppStore {
  static readonly shellViewModel: AppShellViewModel = new AppShellViewModel();
  static readonly database: DatabaseManager = new DatabaseManager();
  static readonly credentials: AssetCredentialStore = new AssetCredentialStore();
  static readonly providerViewModel: ProviderViewModel = new ProviderViewModel(new ProviderRepository(AppStore.database), AppStore.credentials);
  static readonly historyViewModel: HistoryViewModel = new HistoryViewModel(new ChatRepository(AppStore.database));
  static readonly chatViewModel: ChatViewModel = new ChatViewModel(new ChatRepository(AppStore.database), new StreamingChatService(), AppStore.credentials);
  static initialized: boolean = false;
  static initializing: boolean = false;
  private static materialPreferences: preferences.Preferences | undefined = undefined;
  static initializeMaterialPreferences(context: common.UIAbilityContext): void {
    if (AppStore.materialPreferences === undefined) AppStore.materialPreferences = preferences.getPreferencesSync(context, { name: 'immersive_material' });
  }
  static readMaterialLevel(): MaterialLevel {
    if (AppStore.materialPreferences === undefined) return MaterialLevel.Gentle;
    const value: string = AppStore.materialPreferences.getSync('level', MaterialLevel.Gentle) as string;
    if (value === MaterialLevel.Off || value === MaterialLevel.Exquisite || value === MaterialLevel.Smooth || value === MaterialLevel.Adaptive) return value as MaterialLevel;
    return MaterialLevel.Gentle;
  }
  static saveMaterialLevel(level: MaterialLevel): void { AppStore.materialPreferences?.putSync('level', level); AppStore.materialPreferences?.flushSync(); }
  static readAppearance(key: string, fallback: string): string {
    if (AppStore.materialPreferences === undefined) return fallback;
    return AppStore.materialPreferences.getSync(key, fallback) as string;
  }
  static saveAppearance(key: string, value: string): void {
    AppStore.materialPreferences?.putSync(key, value);
    AppStore.materialPreferences?.flushSync();
  }
  static async initialize(context: common.UIAbilityContext): Promise<void> {
    if (AppStore.initialized || AppStore.initializing) return;
    AppStore.initializing = true;
    AppStore.initializeMaterialPreferences(context);
    await AppStore.database.open(context);
    await AppStore.providerViewModel.load();
    await AppStore.historyViewModel.load();
    AppStore.shellViewModel.initialize(AppStore.providerViewModel.records, AppStore.readMaterialLevel());
    AppStore.initialized = true;
    AppStore.initializing = false;
  }
  static refreshShell(): void { const revision: number = Date.now(); AppStore.shellViewModel.syncProviders(AppStore.providerViewModel.records); AppStore.shellViewModel.notifyRefresh(); AppStorage.setOrCreate('provider_revision', revision); AppStorage.set('provider_revision', revision); }
  static async refreshAll(): Promise<void> { await AppStore.providerViewModel.load(); await AppStore.historyViewModel.load(); AppStore.refreshShell(); }
}
