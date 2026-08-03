import { ProviderRecord, ProviderKind, ProtocolStyle, ValidationState } from '../model/ProviderModels';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { uiMaterial } from '@kit.ArkUI';

@Component
export struct ProviderCard {
  @Prop provider: ProviderRecord = { id: '', displayName: '', providerKind: ProviderKind.OpenAI, protocolStyle: ProtocolStyle.OpenAI, endpoint: '', modelName: '', credentialAlias: '', maskedCredential: '', enabled: false, validationState: ValidationState.Unknown, createdAt: 0, updatedAt: 0 };
  onToggle: () => void = (): void => {};
  onDelete: () => void = (): void => {};
  onEdit: () => void = (): void => {};
  onTest: () => void = (): void => {};
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';

  private immersiveMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: Color.Transparent,
      applyShadow: true,
      interactive: true,
      lightEffect: { color: this.appearanceAccentColor }
    });
  }

  build() {
    Column({ space: 8 }) {
      Text(this.provider.displayName).fontWeight(FontWeight.Bold);
      Text(`协议：${this.provider.protocolStyle}`).fontColor(THEME_TOKENS.secondaryText);
      Text(this.provider.enabled ? '状态：已启用' : '状态：已停用').fontColor(THEME_TOKENS.secondaryText);
      Text(`密钥：${this.provider.maskedCredential}`).fontColor(THEME_TOKENS.secondaryText);
      Row({ space: 8 }) {
        Button('编辑').onClick(this.onEdit).height(48).layoutWeight(1).fontColor(this.appearanceAccentColor).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
        Button(this.provider.enabled ? '停用' : '启用').onClick(this.onToggle).height(48).layoutWeight(1).fontColor(this.appearanceAccentColor).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
        Button('删除').onClick(this.onDelete).height(48).layoutWeight(1).fontColor(THEME_TOKENS.danger).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      }.width('100%');
      Button('测试连接').onClick(this.onTest).height(48).width('100%').fontColor(this.appearanceAccentColor).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
    }.padding(16).borderRadius(20).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).width('100%');
  }
}
