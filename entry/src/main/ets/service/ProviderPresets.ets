import { ProviderKind } from '../model/ProviderModels';

export interface ProviderPreset {
  displayName: string;
  endpoint: string;
  models: string[];
}

export class ProviderPresets {
  static endpointFor(kind: ProviderKind, modelName: string): string {
    const endpoint: string = ProviderPresets.get(kind).endpoint;
    if (kind !== ProviderKind.Gemini) return endpoint;
    const marker: string = '/models/';
    const start: number = endpoint.indexOf(marker);
    const actionStart: number = endpoint.indexOf(':', start + marker.length);
    return start >= 0 && actionStart >= 0 ? `${endpoint.slice(0, start + marker.length)}${modelName}${endpoint.slice(actionStart)}` : endpoint;
  }

  static get(kind: ProviderKind): ProviderPreset {
    if (kind === ProviderKind.OpenAI) return { displayName: 'OpenAI', endpoint: 'https://api.openai.com', models: ['gpt-5.6', 'gpt-5.6-terra', 'gpt-5.6-luna', 'gpt-4.1-mini'] };
    if (kind === ProviderKind.DeepSeek) return { displayName: 'DeepSeek', endpoint: 'https://api.deepseek.com', models: ['deepseek-v4-flash', 'deepseek-v4-pro'] };
    if (kind === ProviderKind.GLM) return { displayName: 'ZHIPU AI', endpoint: 'https://open.bigmodel.cn/api/paas/v4/chat/completions', models: ['glm-4.5-air', 'glm-4.5', 'glm-4-flash'] };
    if (kind === ProviderKind.Anthropic) return { displayName: 'Anthropic', endpoint: 'https://api.anthropic.com/v1/messages', models: ['claude-sonnet-4-5', 'claude-opus-4-1', 'claude-haiku-4-5'] };
    if (kind === ProviderKind.Gemini) return { displayName: 'Google Gemini', endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse', models: ['gemini-2.5-flash', 'gemini-2.5-pro'] };
    if (kind === ProviderKind.XAI) return { displayName: 'xAI Grok', endpoint: 'https://api.x.ai/v1/chat/completions', models: ['grok-4-1-fast-reasoning', 'grok-4-1-fast-non-reasoning'] };
    if (kind === ProviderKind.Qwen) return { displayName: 'Alibaba Qwen', endpoint: 'https://dashscope.aliyuncs.com', models: ['qwen3.7-plus', 'qwen3.7-flash', 'qwen3.8-max-preview'] };
    if (kind === ProviderKind.Kimi) return { displayName: 'Kimi', endpoint: 'https://api.moonshot.cn', models: ['kimi-k3', 'kimi-k2.7-code-highspeed', 'kimi-k2.6'] };
    return { displayName: 'OpenAI Compatible', endpoint: '', models: [] };
  }
}
