import { ProviderKind, ProviderRecord } from '../model/ProviderModels';

export class EndpointResolver {
  static chatCompletions(provider: ProviderRecord): string {
    const endpoint: string = provider.endpoint.trim().replace(/\/$/, '');
    if (provider.providerKind === ProviderKind.Gemini) {
      const marker: string = '/models/';
      const start: number = endpoint.indexOf(marker);
      const actionStart: number = endpoint.indexOf(':', start + marker.length);
      if (start >= 0 && actionStart >= 0) return `${endpoint.slice(0, start + marker.length)}${provider.modelName}${endpoint.slice(actionStart)}`;
    }
    if (provider.providerKind !== ProviderKind.DeepSeek || endpoint.endsWith('/chat/completions')) return endpoint;
    if (endpoint === 'https://api.deepseek.com' || endpoint === 'https://api.deepseek.com/v1') {
      return 'https://api.deepseek.com/chat/completions';
    }
    return endpoint;
  }

  static models(provider: ProviderRecord): string {
    const endpoint: string = provider.endpoint.trim().replace(/\/$/, '');
    if (provider.providerKind === ProviderKind.Gemini) {
      const modelMarker: string = '/models/';
      const markerIndex: number = endpoint.indexOf(modelMarker);
      if (markerIndex >= 0) return `${endpoint.slice(0, markerIndex)}/models`;
      return 'https://generativelanguage.googleapis.com/v1beta/models';
    }
    if (provider.providerKind === ProviderKind.Anthropic) return endpoint.endsWith('/messages') ? `${endpoint.slice(0, -8)}models` : `${endpoint}/models`;
    if (endpoint.endsWith('/chat/completions')) return `${endpoint.slice(0, -17)}/models`;
    if (endpoint.endsWith('/responses')) return `${endpoint.slice(0, -10)}/models`;
    if (endpoint.endsWith('/messages')) return `${endpoint.slice(0, -9)}/models`;
    if (provider.providerKind === ProviderKind.DeepSeek && (endpoint === 'https://api.deepseek.com' || endpoint === 'https://api.deepseek.com/v1')) return 'https://api.deepseek.com/models';
    return endpoint.endsWith('/models') ? endpoint : `${endpoint}/models`;
  }
}
