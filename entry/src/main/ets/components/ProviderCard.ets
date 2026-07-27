import { ProviderRecord, ProviderKind, ProtocolStyle, ValidationState } from '../model/ProviderModels';
import { THEME_TOKENS } from '../common/ThemeTokens';

@Component
export struct ProviderCard {
  @Prop provider: ProviderRecord = { id: '', displayName: '', providerKind: ProviderKind.OpenAI, protocolStyle: ProtocolStyle.OpenAI, endpoint: '', modelName: '', credentialAlias: '', maskedCredential: '', enabled: false, validationState: ValidationState.Unknown, createdAt: 0, updatedAt: 0 };
  onToggle: () => void = (): void => {};
  onDelete: () => void = (): void => {};
  onEdit: () => void = (): void => {};
  onTest: () => void = (): void => {};

  private protocolLabel(): string {
    return this.provider.protocolStyle === ProtocolStyle.OpenAIResponses ? 'Responses API' : 'Chat Completions';
  }

  build() {
    Row({ space: 10 }) {
      Image($r('app.media.nav_provider')).width(22).height(22).fillColor(THEME_TOKENS.primary);
      Column({ space: 4 }) {
        Text(this.provider.displayName).fontSize(16).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%');
        Text(this.provider.modelName.length > 0 ? this.provider.modelName : '未设置模型').fontSize(12).fontColor(THEME_TOKENS.secondaryText).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%');
        Text(this.protocolLabel()).fontSize(12).fontColor(THEME_TOKENS.secondaryText).opacity(0.8).maxLines(1).width('100%');
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
      Toggle({ type: ToggleType.Switch, isOn: this.provider.enabled })
        .accessibilityText(this.provider.enabled ? '停用供应商' : '启用供应商')
        .onChange((_enabled: boolean): void => { this.onToggle(); });
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.history_more')).width(20).height(20).fillColor(THEME_TOKENS.primary);
      }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .bindMenu([
          { value: '编辑供应商', action: (): void => { this.onEdit(); } },
          { value: '测试连接', action: (): void => { this.onTest(); } },
          { value: '删除供应商', action: (): void => { this.onDelete(); } }
        ])
        .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.86 });
    }.width('100%').padding({ left: 16, right: 8, top: 12, bottom: 12 });
  }
}
