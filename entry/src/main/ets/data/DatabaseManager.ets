import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class DatabaseManager {
  private store: relationalStore.RdbStore | undefined;
  private async ensureMessageTokenColumn(column: string): Promise<void> {
    if (this.store === undefined) return;
    const result = await this.store.querySql('PRAGMA table_info(messages)');
    const nameIndex: number = result.getColumnIndex('name');
    let exists: boolean = false;
    while (result.goToNextRow()) {
      if (result.getString(nameIndex) === column) { exists = true; break; }
    }
    result.close();
    if (!exists) await this.store.execute(`ALTER TABLE messages ADD COLUMN ${column} INTEGER DEFAULT 0`);
  }
  private async ensureMessageTextColumn(column: string): Promise<void> {
    if (this.store === undefined) return;
    const result = await this.store.querySql('PRAGMA table_info(messages)');
    const nameIndex: number = result.getColumnIndex('name');
    let exists: boolean = false;
    while (result.goToNextRow()) {
      if (result.getString(nameIndex) === column) { exists = true; break; }
    }
    result.close();
    if (!exists) await this.store.execute(`ALTER TABLE messages ADD COLUMN ${column} TEXT DEFAULT ''`);
  }
  async open(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== undefined) return;
    const config: relationalStore.StoreConfig = { name: 'immersive_ai.db', securityLevel: relationalStore.SecurityLevel.S2 };
    this.store = await relationalStore.getRdbStore(context, config);
    await this.store.execute('CREATE TABLE IF NOT EXISTS providers (id TEXT PRIMARY KEY, display_name TEXT, provider_kind TEXT, protocol_style TEXT, endpoint TEXT, model_name TEXT, credential_alias TEXT, masked_credential TEXT, enabled INTEGER, validation_state TEXT, created_at INTEGER, updated_at INTEGER)');
    await this.store.execute('CREATE TABLE IF NOT EXISTS conversations (id TEXT PRIMARY KEY, title TEXT, provider_id TEXT, model_name TEXT, status TEXT, created_at INTEGER, updated_at INTEGER)');
    await this.store.execute('CREATE TABLE IF NOT EXISTS messages (id TEXT PRIMARY KEY, conversation_id TEXT, sequence INTEGER, role TEXT, content TEXT, reasoning_content TEXT, source_data TEXT DEFAULT \'\', status TEXT, error_summary TEXT, created_at INTEGER, updated_at INTEGER, input_tokens INTEGER DEFAULT 0, output_tokens INTEGER DEFAULT 0, total_tokens INTEGER DEFAULT 0)');
    await this.ensureMessageTokenColumn('input_tokens');
    await this.ensureMessageTokenColumn('output_tokens');
    await this.ensureMessageTokenColumn('total_tokens');
    await this.ensureMessageTextColumn('source_data');
  }
  getRdbStore(): relationalStore.RdbStore | undefined { return this.store; }
  async close(): Promise<void> { if (this.store !== undefined) { this.store = undefined; } }
}
