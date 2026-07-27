import { ImportPreview, ProtocolStyle, ProviderDraft, ProviderKind } from '../model/ProviderModels';
import { ProviderRegistry } from './ProviderRegistry';
export class ImportService {
  static preview(text: string): ImportPreview {
    const draft: ProviderDraft = { displayName: '', providerKind: ProviderKind.OpenAICompatible, protocolStyle: ProtocolStyle.OpenAI, endpoint: '', modelName: '', credential: '' };
    try {
      const value: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
      const connectionType: string = String(value['_type'] ?? '');
      const isNewApiConnection: boolean = connectionType === 'newapi_channel_conn';
      draft.displayName = String(value['displayName'] ?? value['name'] ?? (isNewApiConnection ? 'New API' : ''));
      draft.endpoint = String(value['endpoint'] ?? value['url'] ?? '');
      draft.modelName = String(value['modelName'] ?? value['model'] ?? '');
      draft.credential = String(value['key'] ?? value['apiKey'] ?? '');
      const kind: string = String(value['providerKind'] ?? value['provider'] ?? 'openaiCompatible');
      if (isNewApiConnection) draft.providerKind = ProviderKind.OpenAICompatible;
      else if (kind === ProviderKind.OpenAI) draft.providerKind = ProviderKind.OpenAI;
      else if (kind === ProviderKind.DeepSeek) draft.providerKind = ProviderKind.DeepSeek;
      else if (kind === ProviderKind.GLM) draft.providerKind = ProviderKind.GLM;
      else if (kind === ProviderKind.Anthropic) draft.providerKind = ProviderKind.Anthropic;
      else if (kind === ProviderKind.Gemini) draft.providerKind = ProviderKind.Gemini;
      else if (kind === ProviderKind.Kimi) draft.providerKind = ProviderKind.Kimi;
       else if (kind !== ProviderKind.OpenAICompatible) return { draft, protocolStyle: ProviderRegistry.style(draft.providerKind), maskedCredential: '', errors: ['暂不支持该供应商类型。'] };
      const protocol: string = String(value['protocolStyle'] ?? value['protocol'] ?? '');
      if (protocol === ProtocolStyle.OpenAIResponses || protocol === 'responses') draft.protocolStyle = ProtocolStyle.OpenAIResponses;
      else if (isNewApiConnection) draft.protocolStyle = ProtocolStyle.OpenAI;
      else draft.protocolStyle = ProviderRegistry.style(draft.providerKind);
     } catch (_) { return { draft, protocolStyle: ProviderRegistry.style(draft.providerKind), maskedCredential: '', errors: ['粘贴内容不是有效 JSON。'] }; }
    const errors: string[] = [];
     if (draft.displayName.length === 0) errors.push('请输入供应商名称。');
     if (draft.endpoint.length === 0 || !draft.endpoint.startsWith('http')) errors.push('请输入用户提供的有效服务地址。');
     if (draft.credential.length === 0) errors.push('请输入密钥。');
    return { draft, protocolStyle: draft.protocolStyle, maskedCredential: draft.credential.length > 0 ? '••••••' : '', errors };
  }
  static unsupportedPickerMessage(): string { return '系统文件选择能力尚未验证，请直接粘贴 JSON 内容进行预览。'; }
}
