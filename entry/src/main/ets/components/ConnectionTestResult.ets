import { ConnectionTestResult as ResultModel, ConnectionTestStatus } from '../model/ProviderModels';
import { THEME_TOKENS } from '../common/ThemeTokens';
@Component export struct ConnectionTestResultView {
  @Prop result: ResultModel = { status: ConnectionTestStatus.Idle, safeMessage: '', checkedAt: 0, responseSummary: '' };
  @Prop version: number = 0;
  onRetry: () => void = (): void => {};
  onCheckConfiguration: () => void = (): void => {};
  build() { if (this.result.status !== ConnectionTestStatus.Idle) Column({ space: 4 }) { Text(this.result.safeMessage).fontColor(this.result.status === ConnectionTestStatus.Success ? THEME_TOKENS.success : THEME_TOKENS.danger); if (this.result.responseSummary.length > 0) Text(`响应摘要：${this.result.responseSummary}`).fontColor(THEME_TOKENS.secondaryText); Row({ space: 8 }) { Button('检查配置').onClick(this.onCheckConfiguration).height(THEME_TOKENS.touchTarget).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); Button('重试测试').onClick(this.onRetry).height(THEME_TOKENS.touchTarget).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); } }.padding(10).width('100%'); }
}
