import { ProviderEditor } from '../components/ProviderEditor';
import { ProviderCard } from '../components/ProviderCard';
import { ImportPreview } from '../components/ImportPreview';
import { ProtocolStyle, ProviderRecord, ProviderDraft, ProviderKind, ConnectionTestStatus } from '../model/ProviderModels';
import { AppStore } from '../common/AppStore';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { ImportService } from '../service/ImportService';
import { ShellTab } from '../model/ShellModels';
import { promptAction } from '@kit.ArkUI';
import { OnboardingStepBanner } from '../components/OnboardingStepBanner';

@Component
export struct ProviderSettingsView {
  @State providers: ProviderRecord[] = [];
  @State editingId: string = '';
  @State editingDraft: ProviderDraft | undefined = undefined;
  @State importText: string = '';
  @StorageLink('shell_selected_tab') @Watch('onShellTabChanged') private shellSelectedTab: ShellTab = ShellTab.Chat;
  @StorageLink('onboarding_flow_stage') private onboardingFlowStage: string = '';
  @StorageLink('onboarding_provider_setup_revision') @Watch('onOnboardingProviderSetupRequested') private onboardingProviderSetupRevision: number = 0;
  @StorageLink('onboarding_provider_id') private onboardingProviderId: string = '';
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  onReturnChat: () => void = (): void => {};
  aboutToAppear(): void { this.providers = AppStore.providerViewModel.records; this.resetTransientState(); if (this.onboardingFlowStage === 'provider_setup') this.beginOnboardingProviderSetup(); void this.refresh(); }
  private onShellTabChanged(): void {
    this.resetTransientState();
    if (this.shellSelectedTab === ShellTab.Providers) { if (this.onboardingFlowStage === 'provider_setup') this.beginOnboardingProviderSetup(); void this.refresh(); }
  }
  private resetTransientState(): void {
    this.editingId = '';
    this.editingDraft = undefined;
    this.importText = '';
    AppStore.providerViewModel.resetTransientState();
  }
  private async refresh(): Promise<void> { await AppStore.providerViewModel.load(); this.providers = AppStore.providerViewModel.records; }
  private onOnboardingProviderSetupRequested(): void { if (this.onboardingProviderSetupRevision > 0) this.beginOnboardingProviderSetup(); }
  private beginOnboardingProviderSetup(): void {
    this.editingId = '';
    this.importText = '';
    this.editingDraft = { displayName: 'DeepSeek', providerKind: ProviderKind.DeepSeek, protocolStyle: ProtocolStyle.OpenAI, endpoint: 'https://api.deepseek.com', modelName: 'deepseek-v4-flash', credential: '' };
  }
  private setOnboardingStage(stage: string): void { AppStore.saveOnboardingStage(stage); }
  private onboardingProvider(): ProviderRecord | undefined { return this.providers.find((item: ProviderRecord): boolean => item.id === this.onboardingProviderId); }
  private async save(draft: ProviderDraft, id: string): Promise<void> {
    const value: ProviderDraft = id.length > 0 && draft.credential.length === 0 ? { displayName: draft.displayName, providerKind: draft.providerKind, protocolStyle: draft.protocolStyle, endpoint: draft.endpoint, modelName: draft.modelName, credential: 'unchanged' } : draft;
    const saved: boolean = await AppStore.providerViewModel.save(value, id);
    if (!saved) {
      const message: string = AppStore.providerViewModel.errorMessage.length > 0 ? AppStore.providerViewModel.errorMessage : '请检查服务商信息后重试';
      promptAction.showToast({ message });
      return;
    }
    AppStore.refreshShell();
    this.editingId = '';
    this.editingDraft = undefined;
    await this.refresh();
    if (this.onboardingFlowStage === 'provider_setup') {
      const savedProvider: ProviderRecord | undefined = this.providers.find((item: ProviderRecord): boolean => item.displayName === value.displayName.trim() && item.endpoint === value.endpoint.trim() && item.modelName === value.modelName.trim());
      if (savedProvider !== undefined) {
        AppStore.saveOnboardingProviderId(savedProvider.id);
        this.setOnboardingStage('provider_test');
      }
    }
  }
  private async toggle(provider: ProviderRecord): Promise<void> { await AppStore.providerViewModel.toggle(provider); AppStore.refreshShell(); await this.refresh(); }
  private remove(provider: ProviderRecord): void {
    AlertDialog.show({
      title: '删除供应商',
      message: `确定删除“${provider.displayName}”吗？该操作会同时移除本机保存的 API Key。`,
      autoCancel: true,
      primaryButton: { value: '取消', action: (): void => {} },
      secondaryButton: { value: '删除', fontColor: THEME_TOKENS.danger, action: (): void => { void this.confirmRemove(provider); } }
    });
  }
  private async confirmRemove(provider: ProviderRecord): Promise<void> { await AppStore.providerViewModel.remove(provider); AppStore.refreshShell(); await this.refresh(); }
  private async test(provider: ProviderRecord): Promise<void> {
    const startedAt: number = Date.now();
    promptAction.showToast({ message: '正在测试连接' });
    await AppStore.providerViewModel.testConnection(provider);
    const message: string = AppStore.providerViewModel.connectionTest.safeMessage;
    const elapsed: number = Date.now() - startedAt;
    const resultMessage: string = `${message.length > 0 ? message : '测试未启动，请稍后重试'}（${elapsed} ms）`;
    const delay: number = elapsed >= 800 ? 0 : 800 - elapsed;
    setTimeout((): void => { promptAction.showToast({ message: resultMessage }); }, delay);
    if (this.onboardingFlowStage === 'provider_test' && provider.id === this.onboardingProviderId && AppStore.providerViewModel.connectionTest.status === ConnectionTestStatus.Success) {
      AppStore.saveAppearance('chat_selected_provider_id', provider.id);
      AppStore.saveAppearance('chat_model_override', provider.modelName);
      const providerRevision: number = Date.now();
      AppStorage.setOrCreate('chat_provider_selection_revision', providerRevision);
      AppStorage.set('chat_provider_selection_revision', providerRevision);
      this.setOnboardingStage('chat');
      const chatRevision: number = Date.now();
      AppStorage.setOrCreate('onboarding_chat_request_revision', chatRevision);
      AppStorage.set('onboarding_chat_request_revision', chatRevision);
    }
  }
  private beginEdit(provider: ProviderRecord): void { this.editingId = provider.id; this.editingDraft = { displayName: provider.displayName, providerKind: provider.providerKind, protocolStyle: provider.protocolStyle, endpoint: provider.endpoint, modelName: provider.modelName, credential: '' }; AppStorage.setOrCreate('provider_edit_revision', Date.now()); }
  private previewImport(): void { AppStore.providerViewModel.beginImport(ImportService.preview(this.importText)); }
  build() {
      Column({ space: 12 }) {
       Text('密钥使用受保护存储，仅以遮罩形式显示。').fontColor(THEME_TOKENS.secondaryText);
       if (this.onboardingFlowStage === 'provider_setup') OnboardingStepBanner({ step: 1, title: '配置服务商', detail: '选择模板，确认地址、模型和 API Key 后保存。', accentColor: this.appearanceAccentColor });
       else if (this.onboardingFlowStage === 'provider_test') OnboardingStepBanner({ step: 2, title: '测试连接', detail: '供应商已启用。测试成功后将自动进入聊天。', accentColor: this.appearanceAccentColor });
       if (this.editingId.length > 0 || this.editingDraft !== undefined) ProviderEditor({ existingId: this.editingId, initialDraft: this.editingDraft, showOnboardingGuide: this.onboardingFlowStage === 'provider_setup', onSave: (draft: ProviderDraft, id: string): void => { void this.save(draft, id); }, onCancel: (): void => { this.editingId = ''; this.editingDraft = undefined; AppStore.providerViewModel.cancelEdit(); } });
       else Button('新增供应商').onClick((): void => { this.editingId = ''; this.editingDraft = { displayName: 'OpenAI compatible', providerKind: ProviderKind.OpenAICompatible, protocolStyle: ProtocolStyle.OpenAI, endpoint: '', modelName: '', credential: '' }; }).height(THEME_TOKENS.touchTarget).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
       TextInput({ placeholder: '粘贴供应商 JSON 进行预览', text: this.importText }).onChange((value: string): void => { this.importText = value; });
       Row({ space: 8 }) { Button('预览导入').onClick((): void => { this.previewImport(); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); Button('清空').onClick((): void => { this.importText = ''; AppStore.providerViewModel.cancelImport(); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); }
       if (AppStore.providerViewModel.preview !== undefined) ImportPreview({ preview: AppStore.providerViewModel.preview, onConfirm: (): void => { void AppStore.providerViewModel.confirmImport(); }, onCancel: (): void => { AppStore.providerViewModel.cancelImport(); }, onClear: (): void => { this.importText = ''; AppStore.providerViewModel.cancelImport(); } });
      if (this.onboardingFlowStage === 'provider_test' && this.onboardingProvider() !== undefined) Button('测试引导中的供应商').onClick((): void => { const provider: ProviderRecord | undefined = this.onboardingProvider(); if (provider !== undefined) void this.test(provider); }).height(THEME_TOKENS.touchTarget).width('100%').clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      if (AppStore.providerViewModel.errorMessage.length > 0) Text(AppStore.providerViewModel.errorMessage).fontColor(THEME_TOKENS.danger);
      ForEach(this.providers, (provider: ProviderRecord) => {
        Column() {
           ProviderCard({ provider, onToggle: (): void => { void this.toggle(provider); }, onDelete: (): void => { this.remove(provider); }, onEdit: (): void => { this.beginEdit(provider); }, onTest: (): void => { void this.test(provider); } });
        }.transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.96, y: 0.96 })).animation({ duration: 240, curve: Curve.EaseOut }));
      });
       if (AppStore.providerViewModel.feedbackMessage.length > 0) Text(AppStore.providerViewModel.feedbackMessage).fontColor(THEME_TOKENS.success);
    }.padding({ left: 20, right: 20, bottom: THEME_TOKENS.contentBottomInset, top: 20 }).width('100%');
  }
}
