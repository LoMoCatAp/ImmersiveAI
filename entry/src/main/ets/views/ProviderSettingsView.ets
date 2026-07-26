import { ProviderEditor } from '../components/ProviderEditor';
import { ProviderCard } from '../components/ProviderCard';
import { ImportPreview } from '../components/ImportPreview';
import { ProviderRecord, ProviderDraft, ProviderKind } from '../model/ProviderModels';
import { AppStore } from '../common/AppStore';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { ImportService } from '../service/ImportService';
import { ShellTab } from '../model/ShellModels';
import { promptAction } from '@kit.ArkUI';

@Component
export struct ProviderSettingsView {
  @State providers: ProviderRecord[] = [];
  @State editingId: string = '';
  @State editingDraft: ProviderDraft | undefined = undefined;
  @State importText: string = '';
  @StorageLink('shell_selected_tab') @Watch('onShellTabChanged') private shellSelectedTab: ShellTab = ShellTab.Chat;
  onReturnChat: () => void = (): void => {};
  aboutToAppear(): void { this.providers = AppStore.providerViewModel.records; this.resetTransientState(); void this.refresh(); }
  private onShellTabChanged(): void {
    this.resetTransientState();
    if (this.shellSelectedTab === ShellTab.Providers) void this.refresh();
  }
  private resetTransientState(): void {
    this.editingId = '';
    this.editingDraft = undefined;
    this.importText = '';
    AppStore.providerViewModel.resetTransientState();
  }
  private async refresh(): Promise<void> { await AppStore.providerViewModel.load(); this.providers = AppStore.providerViewModel.records; }
  private async save(draft: ProviderDraft, id: string): Promise<void> { const value: ProviderDraft = id.length > 0 && draft.credential.length === 0 ? { displayName: draft.displayName, providerKind: draft.providerKind, endpoint: draft.endpoint, modelName: draft.modelName, credential: 'unchanged' } : draft; await AppStore.providerViewModel.save(value, id); AppStore.refreshShell(); this.editingId = ''; this.editingDraft = undefined; await this.refresh(); }
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
  }
  private beginEdit(provider: ProviderRecord): void { this.editingId = provider.id; this.editingDraft = { displayName: provider.displayName, providerKind: provider.providerKind, endpoint: provider.endpoint, modelName: provider.modelName, credential: '' }; }
  private previewImport(): void { AppStore.providerViewModel.beginImport(ImportService.preview(this.importText)); }
  build() {
      Column({ space: 12 }) {
       Text('密钥使用受保护存储，仅以遮罩形式显示。').fontColor(THEME_TOKENS.secondaryText);
       if (this.editingId.length > 0 || this.editingDraft !== undefined) ProviderEditor({ existingId: this.editingId, initialDraft: this.editingDraft, onSave: (draft: ProviderDraft, id: string): void => { void this.save(draft, id); }, onCancel: (): void => { this.editingId = ''; this.editingDraft = undefined; AppStore.providerViewModel.cancelEdit(); } });
       else Button('新增供应商').onClick((): void => { this.editingId = ''; this.editingDraft = { displayName: 'OpenAI', providerKind: ProviderKind.OpenAI, endpoint: 'https://api.openai.com/v1/chat/completions', modelName: 'gpt-5.6', credential: '' }; }).height(THEME_TOKENS.touchTarget).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
       TextInput({ placeholder: '粘贴供应商 JSON 进行预览', text: this.importText }).onChange((value: string): void => { this.importText = value; });
       Row({ space: 8 }) { Button('预览导入').onClick((): void => { this.previewImport(); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); Button('清空').onClick((): void => { this.importText = ''; AppStore.providerViewModel.cancelImport(); }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); }
       if (AppStore.providerViewModel.preview !== undefined) ImportPreview({ preview: AppStore.providerViewModel.preview, onConfirm: (): void => { void AppStore.providerViewModel.confirmImport(); }, onCancel: (): void => { AppStore.providerViewModel.cancelImport(); }, onClear: (): void => { this.importText = ''; AppStore.providerViewModel.cancelImport(); } });
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
