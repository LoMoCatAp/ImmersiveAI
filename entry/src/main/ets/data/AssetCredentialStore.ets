import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';

function bytes(value: string): Uint8Array { return new util.TextEncoder().encodeInto(value); }
function text(value: Uint8Array): string { return util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(value, { stream: false }); }

export class AssetCredentialStore {
  async add(alias: string, credential: string): Promise<void> {
    const attributes: asset.AssetMap = new Map();
    attributes.set(asset.Tag.ALIAS, bytes(alias));
    attributes.set(asset.Tag.SECRET, bytes(credential));
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    attributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
    await asset.add(attributes);
  }
  async get(alias: string): Promise<string | undefined> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, bytes(alias));
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    const results: asset.AssetMap[] = await asset.query(query);
    if (results.length === 0) return undefined;
    const secret: Object | undefined = results[0].get(asset.Tag.SECRET);
    return secret instanceof Uint8Array ? text(secret) : undefined;
  }
  async update(alias: string, credential: string): Promise<void> {
    await this.add(alias, credential);
  }
  async remove(alias: string): Promise<void> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, bytes(alias));
    await asset.remove(query);
  }
}
