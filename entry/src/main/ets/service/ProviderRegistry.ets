import { ProviderKind, ProtocolStyle, ProviderRecord } from '../model/ProviderModels';

export class ProviderRegistry {
  static style(kind: ProviderKind): ProtocolStyle {
    if (kind === ProviderKind.Anthropic) return ProtocolStyle.Claude;
    if (kind === ProviderKind.Gemini) return ProtocolStyle.Gemini;
    return ProtocolStyle.OpenAI;
  }

  static supportsWebSearch(provider: ProviderRecord): boolean {
    // Responses-compatible gateways expose the same native web-search tool
    // contract as OpenAI. Do not hide the capability solely because the
    // provider was imported as an OpenAI-compatible gateway.
    if ((provider.providerKind === ProviderKind.OpenAI || provider.providerKind === ProviderKind.OpenAICompatible) && provider.protocolStyle === ProtocolStyle.OpenAIResponses) return true;
    if (provider.providerKind === ProviderKind.Qwen) return provider.modelName.toLowerCase().startsWith('qwen') || provider.modelName.toLowerCase().startsWith('qwq') || provider.modelName.toLowerCase().startsWith('deepseek');
    if (provider.providerKind === ProviderKind.Kimi) return provider.modelName === 'kimi-k3' || provider.modelName === 'kimi-k2.6';
    return false;
  }
}
