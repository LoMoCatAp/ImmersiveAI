import { ProviderRecord, ProviderKind, ProtocolStyle, ValidationState } from '../model/ProviderModels';
import { DatabaseManager } from './DatabaseManager';
import { relationalStore } from '@kit.ArkData';

export class ProviderRepository {
  private database: DatabaseManager;
  constructor(database: DatabaseManager) { this.database = database; }
  async list(): Promise<ProviderRecord[]> {
    const store = this.database.getRdbStore();
    if (store === undefined) return [];
    const result = await store.querySql('SELECT * FROM providers ORDER BY updated_at DESC, display_name ASC');
    const output: ProviderRecord[] = [];
    while (result.goToNextRow()) output.push(this.read(result));
    result.close();
    return output;
  }
  async save(record: ProviderRecord): Promise<void> {
    const store = this.database.getRdbStore();
    if (store === undefined) return;
    await store.execute('INSERT OR REPLACE INTO providers (id,display_name,provider_kind,protocol_style,endpoint,model_name,credential_alias,masked_credential,enabled,validation_state,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)', [record.id, record.displayName, record.providerKind, record.protocolStyle, record.endpoint, record.modelName, record.credentialAlias, record.maskedCredential, record.enabled ? 1 : 0, record.validationState, record.createdAt, record.updatedAt]);
  }
  async update(record: ProviderRecord): Promise<void> { await this.save(record); }
  async setEnabled(id: string, enabled: boolean): Promise<void> {
    const store = this.database.getRdbStore();
    if (store !== undefined) await store.execute('UPDATE providers SET enabled = ?, updated_at = ? WHERE id = ?', [enabled ? 1 : 0, Date.now(), id]);
  }
  async remove(id: string): Promise<void> {
    const store = this.database.getRdbStore();
    if (store !== undefined) await store.execute('DELETE FROM providers WHERE id = ?', [id]);
  }
  private read(result: relationalStore.ResultSet): ProviderRecord {
    return { id: result.getString(result.getColumnIndex('id')), displayName: result.getString(result.getColumnIndex('display_name')), providerKind: result.getString(result.getColumnIndex('provider_kind')) as ProviderKind, protocolStyle: result.getString(result.getColumnIndex('protocol_style')) as ProtocolStyle, endpoint: result.getString(result.getColumnIndex('endpoint')), modelName: result.getString(result.getColumnIndex('model_name')), credentialAlias: result.getString(result.getColumnIndex('credential_alias')), maskedCredential: result.getString(result.getColumnIndex('masked_credential')), enabled: result.getLong(result.getColumnIndex('enabled')) === 1, validationState: result.getString(result.getColumnIndex('validation_state')) as ValidationState, createdAt: result.getLong(result.getColumnIndex('created_at')), updatedAt: result.getLong(result.getColumnIndex('updated_at')) };
  }
}
