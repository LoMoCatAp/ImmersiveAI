import bundleManager from '@ohos.bundle.bundleManager';

export interface FirstLaunchInfo {
  firstInstallTime: number;
  versionCode: number;
  versionName: string;
}

export class FirstLaunchDetector {
  static async detect(): Promise<FirstLaunchInfo> {
    const info = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    return {
      firstInstallTime: info.firstInstallTime ?? 0,
      versionCode: info.versionCode,
      versionName: info.versionName
    };
  }
}
