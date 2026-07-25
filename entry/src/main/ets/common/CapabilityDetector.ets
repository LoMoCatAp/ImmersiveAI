import { hdsMaterial } from '@kit.UIDesignKit';
import { MaterialLevel, MaterialOption } from '../model/ShellModels';

export enum MaterialMode { Official = 'official', Fallback = 'fallback' }
export interface MaterialCapability { mode: MaterialMode; reason: string; verifiedSymbols: Array<string>; sdkAvailable: boolean; runtimeAvailable: boolean; presentationVerified: boolean }

export class CapabilityDetector {
  static options(supported: Array<hdsMaterial.MaterialType>): Array<MaterialOption> {
    const available: boolean = supported.length > 0;
    return [
      { level: MaterialLevel.Off, label: '关闭', description: '关闭导航栏沉浸光感材质效果。', isDefault: false, available: true, reason: '始终可用。' },
      { level: MaterialLevel.Exquisite, label: '强', description: '完整沉浸光感，适合高性能设备。', isDefault: false, available, reason: available ? '设备已报告系统材质能力。' : '设备未报告沉浸光感能力。' },
      { level: MaterialLevel.Gentle, label: '均衡（默认）', description: '适度沉浸光感，平衡效果与性能。', isDefault: true, available, reason: available ? '设备已报告系统材质能力。' : '设备未报告沉浸光感能力。' },
      { level: MaterialLevel.Smooth, label: '弱', description: '轻量沉浸光感，仅保留核心视觉特性。', isDefault: false, available, reason: available ? '设备已报告系统材质能力。' : '设备未报告沉浸光感能力。' },
      { level: MaterialLevel.Adaptive, label: '系统自适应', description: '由系统根据设备性能自动选择档位。', isDefault: false, available, reason: available ? '由系统自动选择合适档位。' : '设备未报告系统材质能力。' }
    ];
  }
  static detect(): MaterialCapability {
    const symbols: Array<string> = ['HdsNavigation', 'HdsTabs', 'TabContent', 'HdsTabsController', 'bindToScrollable', 'titleBar', 'barFloatingStyle', 'hdsMaterial'];
    const supportedMaterials: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
    if (supportedMaterials.length === 0) {
      return { mode: MaterialMode.Fallback, reason: '系统未报告可用的沉浸光感材质，已使用中文导航。', verifiedSymbols: symbols, sdkAvailable: true, runtimeAvailable: false, presentationVerified: false };
    }
    return { mode: MaterialMode.Official, reason: '已检测到 SDK 与运行时材质，设备视觉效果待验证。', verifiedSymbols: symbols, sdkAvailable: true, runtimeAvailable: true, presentationVerified: false };
  }
}
