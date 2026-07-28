import { ProviderRecord, ProviderKind, ProtocolStyle, ValidationState } from '../model/ProviderModels';
import { THEME_TOKENS } from '../common/ThemeTokens';

@Component
export struct ProviderCard {
  @Prop provider: ProviderRecord = { id: '', displayName: '', providerKind: ProviderKind.OpenAI, protocolStyle: ProtocolStyle.OpenAI, endpoint: '', modelName: '', credentialAlias: '', maskedCredential: '', enabled: false, validationState: ValidationState.Unknown, createdAt: 0, updatedAt: 0 };
  onToggle: () => void = (): void => {};
  onDelete: () => void = (): void => {};
  onEdit: () => void = (): void => {};
  onTest: () => void = (): void => {};
  @StorageLink('immersive_list_enabled') private listImmersiveEnabled: boolean = false;

  build() {
    Column({ space: 8 }) {
      Text(this.provider.displayName).fontWeight(FontWeight.Bold);
      Text(`协议：${this.provider.protocolStyle}`).fontColor(THEME_TOKENS.secondaryText);
      Text(this.provider.enabled ? '状态：已启用' : '状态：已停用').fontColor(THEME_TOKENS.secondaryText);
      Text(`密钥：${this.provider.maskedCredential}`).fontColor(THEME_TOKENS.secondaryText);
      Row({ space: 8 }) {
        Button('编辑').onClick(this.onEdit).height(48).layoutWeight(1).clickEffect({ level: ClickEffectLevel.LIGHT, scale: this.listImmersiveEnabled ? 0.84 : 1 });
        Button(this.provider.enabled ? '停用' : '启用').onClick(this.onToggle).height(48).layoutWeight(1).clickEffect({ level: ClickEffectLevel.LIGHT, scale: this.listImmersiveEnabled ? 0.84 : 1 });
        Button('删除').onClick(this.onDelete).height(48).layoutWeight(1).clickEffect({ level: ClickEffectLevel.LIGHT, scale: this.listImmersiveEnabled ? 0.84 : 1 });
      }.width('100%');
      Button('测试连接').onClick(this.onTest).height(48).width('100%').clickEffect({ level: ClickEffectLevel.LIGHT, scale: this.listImmersiveEnabled ? 0.84 : 1 });
    }.padding(16).borderRadius(16).backgroundColor(this.listImmersiveEnabled ? Color.Transparent : THEME_TOKENS.surface).backgroundBlurStyle(this.listImmersiveEnabled ? BlurStyle.COMPONENT_ULTRA_THICK : BlurStyle.NONE).animation({ duration: this.listImmersiveEnabled ? 220 : 0, curve: Curve.Friction }).width('100%');
  }
}
