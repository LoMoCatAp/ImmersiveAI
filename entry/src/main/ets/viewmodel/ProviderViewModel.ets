import { ProviderRecord, ProviderDraft, ImportPreview, ValidationState } from '../model/ProviderModels';
import { ProviderRepository } from '../data/ProviderRepository';
import { AssetCredentialStore } from '../data/AssetCredentialStore';
import { ProviderRegistry } from '../service/ProviderRegistry';
import { ConnectionTestService } from '../service/ConnectionTestService';
import { ModelDiscoveryResult, ModelDiscoveryService } from '../service/ModelDiscoveryService';
import { ConnectionTestResult, ConnectionTestStatus, ProviderOperation } from '../model/ProviderModels';
import { PROVIDER_MESSAGES } from '../common/AppConstants';
export class ProviderViewModel {
  records: ProviderRecord[] = [];
  errorMessage: string = '';
  operation: ProviderOperation = ProviderOperation.Idle;
  connectionTest: ConnectionTestResult = { status: ConnectionTestStatus.Idle, safeMessage: '', checkedAt: 0, responseSummary: '' };
  discoveredProviderId: string = '';
  discoveredModels: string[] = [];
  modelDiscoveryMessage: string = '';
  testedProviderId: string = '';
  preview: ImportPreview | undefined = undefined;
  private repository: ProviderRepository;
  private credentials: AssetCredentialStore;
  private testService: ConnectionTestService = new ConnectionTestService();
  private modelDiscoveryService: ModelDiscoveryService = new ModelDiscoveryService();
  private lastTestedProvider: ProviderRecord | undefined = undefined;
  constructor(repository: ProviderRepository, credentials: AssetCredentialStore) { this.repository = repository; this.credentials = credentials; }
  feedbackMessage: string = '';
  async load(): Promise<void> { this.records = await this.repository.list(); }
  resetTransientState(): void {
    this.operation = ProviderOperation.Idle;
    this.errorMessage = '';
    this.feedbackMessage = '';
    this.preview = undefined;
    this.connectionTest = { status: ConnectionTestStatus.Idle, safeMessage: '', checkedAt: 0, responseSummary: '' };
    this.discoveredProviderId = '';
    this.discoveredModels = [];
    this.modelDiscoveryMessage = '';
    this.testedProviderId = '';
    this.lastTestedProvider = undefined;
  }
  cancelEdit(): void { this.errorMessage = ''; this.feedbackMessage = '已取消编辑'; }
  beginImport(preview: ImportPreview): void { this.preview = preview; this.errorMessage = preview.errors.join(' '); this.feedbackMessage = preview.errors.length === 0 ? PROVIDER_MESSAGES.importReady : '导入预览存在问题，请修改后重试'; }
  cancelImport(): void { this.operation = ProviderOperation.Cancelling; this.preview = undefined; this.errorMessage = ''; this.feedbackMessage = PROVIDER_MESSAGES.importCancelled; this.operation = ProviderOperation.Idle; }
  async confirmImport(): Promise<void> { if (this.operation !== ProviderOperation.Idle) return; const pending: ImportPreview | undefined = this.preview; if (pending === undefined || pending.errors.length > 0) { this.errorMessage = '导入内容未通过校验'; return; } const saved: boolean = await this.save(pending.draft); if (saved) this.cancelImport(); }
  async save(draft: ProviderDraft, existingId: string = ''): Promise<boolean> {
      if (this.operation !== ProviderOperation.Idle) { this.errorMessage = '上一个操作仍在进行，请稍候'; return false; }
      if (draft.displayName.trim().length === 0 || draft.endpoint.trim().length === 0 || draft.modelName.trim().length === 0 || (draft.credential.length === 0 && existingId.length === 0)) { this.errorMessage = '请填写名称、地址、模型和密钥'; this.feedbackMessage = PROVIDER_MESSAGES.saveFailed; return false; }
     this.operation = ProviderOperation.Saving;
     try {
       const now: number = Date.now();
       const id: string = existingId.length > 0 ? existingId : `provider-${now}-${Math.floor(Math.random() * 1000000)}`;
       const alias: string = `provider_${id}`;
    const old: ProviderRecord | undefined = this.records.find((item: ProviderRecord): boolean => item.id === id);
     const record: ProviderRecord = { id, displayName: draft.displayName.trim(), providerKind: draft.providerKind, protocolStyle: draft.protocolStyle, endpoint: draft.endpoint.trim(), modelName: draft.modelName.trim(), credentialAlias: old !== undefined ? old.credentialAlias : alias, maskedCredential: old !== undefined ? old.maskedCredential : '••••••', enabled: old !== undefined ? old.enabled : true, validationState: ValidationState.Unknown, createdAt: old !== undefined ? old.createdAt : now, updatedAt: now };
    if (old === undefined) await this.credentials.add(record.credentialAlias, draft.credential); else if (draft.credential !== 'unchanged') await this.credentials.update(record.credentialAlias, draft.credential);
      await this.repository.save(record);
      await this.load();
      this.errorMessage = '';
      this.feedbackMessage = PROVIDER_MESSAGES.saved;
      return true;
     } catch (_) {
       this.errorMessage = PROVIDER_MESSAGES.saveFailed;
       this.feedbackMessage = PROVIDER_MESSAGES.saveFailed;
       return false;
     } finally {
       this.operation = ProviderOperation.Idle;
     }
  }
  async toggle(record: ProviderRecord): Promise<void> {
    if (this.operation !== ProviderOperation.Idle) { this.feedbackMessage = '上一个操作仍在进行，请稍候'; return; }
    this.operation = ProviderOperation.Toggling;
    try {
      await this.repository.setEnabled(record.id, !record.enabled);
      await this.load();
      this.feedbackMessage = PROVIDER_MESSAGES.toggled;
    } catch (_) {
      this.errorMessage = PROVIDER_MESSAGES.saveFailed;
    } finally {
      this.operation = ProviderOperation.Idle;
    }
  }
  async remove(record: ProviderRecord): Promise<void> {
    if (this.operation !== ProviderOperation.Idle) return;
    this.operation = ProviderOperation.Deleting;
    try {
      await this.credentials.remove(record.credentialAlias);
      await this.repository.remove(record.id);
      await this.load();
      this.feedbackMessage = PROVIDER_MESSAGES.deleted;
    } catch (_) {
      this.errorMessage = PROVIDER_MESSAGES.deleteFailed;
    } finally {
      this.operation = ProviderOperation.Idle;
    }
  }
  async testConnection(record: ProviderRecord): Promise<void> {
    if (this.operation !== ProviderOperation.Idle) return;
    this.lastTestedProvider = record;
    this.testedProviderId = record.id;
    this.discoveredProviderId = record.id;
    this.discoveredModels = [];
    this.modelDiscoveryMessage = '';
    this.operation = ProviderOperation.Testing;
    this.connectionTest = { status: ConnectionTestStatus.Testing, safeMessage: PROVIDER_MESSAGES.testing, checkedAt: 0, responseSummary: '' };
    try {
      const credential: string | undefined = await this.credentials.get(record.credentialAlias);
      this.connectionTest = await this.testService.test(record, credential ?? '');
      if (this.connectionTest.status === ConnectionTestStatus.Success) {
        const discovery = await this.modelDiscoveryService.list(record, credential ?? '');
        this.discoveredModels = discovery.models;
        this.modelDiscoveryMessage = discovery.message;
      }
    } catch (_) {
      this.connectionTest = { status: ConnectionTestStatus.NetworkError, safeMessage: '测试连接失败，请稍后重试', checkedAt: Date.now(), responseSummary: '' };
    } finally {
      this.operation = ProviderOperation.Idle;
    }
  }
  async discoverModels(record: ProviderRecord): Promise<void> {
    if (this.operation !== ProviderOperation.Idle) return;
    this.discoveredProviderId = record.id;
    this.discoveredModels = [];
    this.modelDiscoveryMessage = '';
    this.operation = ProviderOperation.Testing;
    try {
      const credential: string | undefined = await this.credentials.get(record.credentialAlias);
      const discovery = await this.modelDiscoveryService.list(record, credential ?? '');
      this.discoveredModels = discovery.models;
      this.modelDiscoveryMessage = discovery.message;
    } catch (_) {
      this.modelDiscoveryMessage = '获取模型失败，请稍后重试';
    } finally {
      this.operation = ProviderOperation.Idle;
    }
  }
  async discoverModelsForDraft(draft: ProviderDraft, fallbackCredential: string = ''): Promise<ModelDiscoveryResult> {
    const credential: string = draft.credential.trim().length > 0 ? draft.credential : fallbackCredential;
    if (draft.endpoint.trim().length === 0) return { models: [], message: '请先填写服务地址后再获取模型。' };
    if (credential.trim().length === 0) return { models: [], message: '请先填写或保存密钥后再获取模型。' };
    const now: number = Date.now();
    const record: ProviderRecord = {
      id: 'draft', displayName: draft.displayName, providerKind: draft.providerKind, protocolStyle: draft.protocolStyle,
      endpoint: draft.endpoint, modelName: draft.modelName, credentialAlias: '', maskedCredential: '', enabled: true,
      validationState: ValidationState.Unknown, createdAt: now, updatedAt: now
    };
    try {
      return await this.modelDiscoveryService.list(record, credential);
    } catch (_) {
      return { models: [], message: '获取模型失败，请检查网络、服务地址和密钥。' };
    }
  }
  async useDiscoveredModel(record: ProviderRecord, modelName: string): Promise<void> {
    if (this.operation !== ProviderOperation.Idle || modelName.trim().length === 0) return;
    this.operation = ProviderOperation.Saving;
    try {
      const updated: ProviderRecord = { id: record.id, displayName: record.displayName, providerKind: record.providerKind, protocolStyle: record.protocolStyle, endpoint: record.endpoint, modelName, credentialAlias: record.credentialAlias, maskedCredential: record.maskedCredential, enabled: record.enabled, validationState: record.validationState, createdAt: record.createdAt, updatedAt: Date.now() };
      await this.repository.update(updated);
      await this.load();
      this.feedbackMessage = `已将 ${record.displayName} 的模型切换为 ${modelName}。`;
    } catch (_) {
      this.errorMessage = PROVIDER_MESSAGES.saveFailed;
    } finally {
      this.operation = ProviderOperation.Idle;
    }
  }
  async retryLastTest(): Promise<void> { const provider: ProviderRecord | undefined = this.lastTestedProvider; if (provider === undefined) { this.feedbackMessage = '暂无可重试的供应商测试'; return; } await this.testConnection(provider); }
}
