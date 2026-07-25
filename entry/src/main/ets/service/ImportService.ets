import { ImportPreview, ProviderDraft, ProviderKind } from '../model/ProviderModels';
import { ProviderRegistry } from './ProviderRegistry';
export class ImportService {
  static preview(text: string): ImportPreview {
    const draft: ProviderDraft = { displayName: '', providerKind: ProviderKind.OpenAICompatible, endpoint: '', modelName: '', credential: '' };
    try {
      const value: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
      draft.displayName = String(value['displayName'] ?? value['name'] ?? '');
      draft.endpoint = String(value['endpoint'] ?? '');
      draft.modelName = String(value['modelName'] ?? value['model'] ?? '');
      draft.credential = String(value['key'] ?? value['apiKey'] ?? '');
      const kind: string = String(value['providerKind'] ?? value['provider'] ?? 'openaiCompatible');
       if (kind === ProviderKind.OpenAI) draft.providerKind = ProviderKind.OpenAI;
      else if (kind === ProviderKind.DeepSeek) draft.providerKind = ProviderKind.DeepSeek;
      else if (kind === ProviderKind.GLM) draft.providerKind = ProviderKind.GLM;
      else if (kind === ProviderKind.Anthropic) draft.providerKind = ProviderKind.Anthropic;
      else if (kind === ProviderKind.Gemini) draft.providerKind = ProviderKind.Gemini;
       else if (kind !== ProviderKind.OpenAICompatible) return { draft, protocolStyle: ProviderRegistry.style(draft.providerKind), maskedCredential: '', errors: ['暂不支持该供应商类型。'] };
     } catch (_) { return { draft, protocolStyle: ProviderRegistry.style(draft.providerKind), maskedCredential: '', errors: ['粘贴内容不是有效 JSON。'] }; }
    const errors: string[] = [];
     if (draft.displayName.length === 0) errors.push('请输入供应商名称。');
     if (draft.endpoint.length === 0 || !draft.endpoint.startsWith('http')) errors.push('请输入用户提供的有效服务地址。');
     if (draft.modelName.length === 0) errors.push('请输入模型名称。');
     if (draft.credential.length === 0) errors.push('请输入密钥。');
    return { draft, protocolStyle: ProviderRegistry.style(draft.providerKind), maskedCredential: draft.credential.length > 0 ? '••••••' : '', errors };
  }
  static unsupportedPickerMessage(): string { return '系统文件选择能力尚未验证，请直接粘贴 JSON 内容进行预览。'; }
}
