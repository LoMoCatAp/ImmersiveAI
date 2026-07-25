import { CapabilityDetector } from '../common/CapabilityDetector';
import { MaterialMode, ShellState, ShellTab, FirstUseState, GlobalFeedback, NavigationIntent, NavigationSource, MaterialLevel, MaterialState } from '../model/ShellModels';
import { ProviderRecord } from '../model/ProviderModels';
import { hdsMaterial } from '@kit.UIDesignKit';

export class AppShellViewModel {
  state: ShellState = { selectedTab: ShellTab.Chat, materialMode: MaterialMode.Fallback, materialReason: '正在检测沉浸光感能力', firstUseState: FirstUseState.Loading, globalFeedback: { message: '', category: '', isLoading: false, retryable: false }, refreshVersion: 0, lastNavigationIntent: undefined, material: { selected: MaterialLevel.Gentle, effective: MaterialLevel.Gentle, options: [], materialTypeAvailable: false, status: '正在检测沉浸光感能力', persisted: false }, myPage: { showMaterialSettings: false, entrySummary: '均衡（默认）', returnTarget: ShellTab.My } };
  initialize(providers: ProviderRecord[], preferred: MaterialLevel = MaterialLevel.Gentle): void {
    const capability = CapabilityDetector.detect();
    this.state.materialMode = capability.mode === 'official' ? MaterialMode.VerifiedOfficial : MaterialMode.Fallback;
    this.state.materialReason = capability.reason;
    this.state.material = { selected: preferred, effective: preferred, options: CapabilityDetector.options(hdsMaterial.getSystemMaterialTypes()), materialTypeAvailable: capability.runtimeAvailable, status: capability.reason, persisted: true };
    this.state.myPage.entrySummary = this.materialSummary(preferred);
    this.syncProviders(providers);
  }
  setMaterialLevel(level: MaterialLevel): void { const option = this.state.material.options.find((item) => item.level === level); if (option === undefined || !option.available) { this.showFeedback({ message: '当前设备不支持该材质档位。', category: 'material', isLoading: false, retryable: false }); return; } this.state.material.selected = level; this.state.material.effective = level; this.state.material.status = `已选择${option.label}材质，系统效果已更新。`; this.state.myPage.entrySummary = this.materialSummary(level); this.notifyRefresh(); }
  private materialSummary(level: MaterialLevel): string { if (level === MaterialLevel.Off) return '关闭'; if (level === MaterialLevel.Exquisite) return '强'; if (level === MaterialLevel.Smooth) return '弱'; if (level === MaterialLevel.Adaptive) return '系统自适应'; return '均衡（默认）'; }
  openMaterialSettings(): void { this.state.myPage.showMaterialSettings = true; }
  closeMaterialSettings(): void { this.state.myPage.showMaterialSettings = false; }
  syncProviders(providers: ProviderRecord[]): void { this.state.firstUseState = providers.some((item: ProviderRecord): boolean => item.enabled) ? FirstUseState.HasEnabledProvider : FirstUseState.NoProvider; }
  navigate(intent: NavigationIntent): void { this.state.selectedTab = intent.target; this.state.lastNavigationIntent = intent; }
  openProviders(): void { this.selectTab(ShellTab.Providers); }
  returnToChat(): void { this.selectTab(ShellTab.Chat); }
  selectTab(tab: ShellTab): void { this.navigate({ target: tab, source: NavigationSource.System, requestId: this.state.refreshVersion + 1 }); }
  notifyRefresh(): void { this.state.refreshVersion += 1; }
  showFeedback(feedback: GlobalFeedback): void { this.state.globalFeedback = feedback; }
  clearFeedback(): void { this.state.globalFeedback = { message: '', category: '', isLoading: false, retryable: false }; }
}
