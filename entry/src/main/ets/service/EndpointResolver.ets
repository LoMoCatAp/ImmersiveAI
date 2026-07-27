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
    if (provider.protocolStyle === 'openaiResponses') {
      if (endpoint.endsWith('/responses')) return endpoint;
      if (endpoint.endsWith('/chat/completions')) return `${endpoint.slice(0, -17)}/responses`;
      if (endpoint.endsWith('/models')) return `${endpoint.slice(0, -7)}/responses`;
      if (provider.providerKind === ProviderKind.Qwen && endpoint === 'https://dashscope.aliyuncs.com') return `${endpoint}/compatible-mode/v1/responses`;
      return endpoint.endsWith('/v1') ? `${endpoint}/responses` : `${endpoint}/v1/responses`;
    }
    if (endpoint.endsWith('/chat/completions') || endpoint.endsWith('/messages') || endpoint.indexOf(':streamGenerateContent') >= 0) return endpoint;
    if (endpoint.endsWith('/models')) return `${endpoint.slice(0, -7)}/chat/completions`;
    if (endpoint === 'https://api.deepseek.com' || endpoint === 'https://api.deepseek.com/v1') {
      return 'https://api.deepseek.com/chat/completions';
    }
    if (provider.providerKind === ProviderKind.Qwen && endpoint === 'https://dashscope.aliyuncs.com') return `${endpoint}/compatible-mode/v1/chat/completions`;
    return endpoint.endsWith('/v1') ? `${endpoint}/chat/completions` : `${endpoint}/v1/chat/completions`;
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
    if (provider.providerKind === ProviderKind.Qwen && endpoint === 'https://dashscope.aliyuncs.com') return `${endpoint}/compatible-mode/v1/models`;
    if (endpoint.endsWith('/v1')) return `${endpoint}/models`;
    if (endpoint.endsWith('/models')) return endpoint;
    return `${endpoint}/v1/models`;
  }
}
