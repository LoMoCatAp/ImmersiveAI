import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class DatabaseManager {
  private store: relationalStore.RdbStore | undefined;
  async open(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== undefined) return;
    const config: relationalStore.StoreConfig = { name: 'immersive_ai.db', securityLevel: relationalStore.SecurityLevel.S2 };
    this.store = await relationalStore.getRdbStore(context, config);
    await this.store.execute('CREATE TABLE IF NOT EXISTS providers (id TEXT PRIMARY KEY, display_name TEXT, provider_kind TEXT, protocol_style TEXT, endpoint TEXT, model_name TEXT, credential_alias TEXT, masked_credential TEXT, enabled INTEGER, validation_state TEXT, created_at INTEGER, updated_at INTEGER)');
    await this.store.execute('CREATE TABLE IF NOT EXISTS conversations (id TEXT PRIMARY KEY, title TEXT, provider_id TEXT, model_name TEXT, status TEXT, created_at INTEGER, updated_at INTEGER)');
    await this.store.execute('CREATE TABLE IF NOT EXISTS messages (id TEXT PRIMARY KEY, conversation_id TEXT, sequence INTEGER, role TEXT, content TEXT, reasoning_content TEXT, status TEXT, error_summary TEXT, created_at INTEGER, updated_at INTEGER)');
  }
  getRdbStore(): relationalStore.RdbStore | undefined { return this.store; }
  async close(): Promise<void> { if (this.store !== undefined) { this.store = undefined; } }
}
