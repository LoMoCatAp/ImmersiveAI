import { MaterialMode } from '../model/ShellModels';
@Component export struct AppHeader {
  @Prop title: string = '沉浸智能';
  @Prop materialMode: MaterialMode = MaterialMode.Fallback;
  build() { Row() { Text(this.title).fontSize(24).fontWeight(FontWeight.Bold).layoutWeight(1); if (this.materialMode === MaterialMode.VerifiedOfficial) Text('系统沉浸光感（待设备验证）').fontSize(12); else Text('系统能力不可用，使用基础导航').fontSize(12); }.width('100%').padding({ top: 12, bottom: 12 }); }
}
