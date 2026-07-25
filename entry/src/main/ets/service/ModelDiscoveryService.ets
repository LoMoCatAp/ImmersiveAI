import { http } from '@kit.NetworkKit';
import { ProviderRecord } from '../model/ProviderModels';
import { EndpointResolver } from './EndpointResolver';

export interface ModelDiscoveryResult {
  models: string[];
  message: string;
}

export class ModelDiscoveryService {
  private headersFor(provider: ProviderRecord, credential: string): Record<string, string> {
    const headers: Record<string, string> = { 'Accept': 'application/json' };
    if (provider.protocolStyle === 'claudeStyle') {
      headers['x-api-key'] = credential;
      headers['anthropic-version'] = '2023-06-01';
    } else if (provider.protocolStyle === 'geminiStyle') {
      headers['x-goog-api-key'] = credential;
    } else {
      headers['Authorization'] = `Bearer ${credential}`;
    }
    return headers;
  }

  private payload(response: http.HttpResponse): Record<string, Object> {
    const raw: Object | string | undefined = response.result;
    if (typeof raw === 'string') return JSON.parse(raw) as Record<string, Object>;
    if (raw !== undefined && typeof raw === 'object') return raw as Record<string, Object>;
    return {};
  }

  private names(provider: ProviderRecord, root: Record<string, Object>): string[] {
    const data: Array<Object> = (root['data'] as Array<Object> | undefined) ?? (root['models'] as Array<Object> | undefined) ?? [];
    const values: string[] = [];
    data.forEach((entry: Object): void => {
      const item: Record<string, Object> = entry as Record<string, Object>;
      const id: string = String(item['id'] ?? item['name'] ?? '');
      if (id.length === 0) return;
      if (provider.protocolStyle === 'geminiStyle') {
        const methods: Array<Object> = (item['supportedGenerationMethods'] as Array<Object> | undefined) ?? [];
        const supportsChat: boolean = methods.some((value: Object): boolean => String(value) === 'generateContent' || String(value) === 'streamGenerateContent');
        if (!supportsChat) return;
        values.push(id.startsWith('models/') ? id.slice(7) : id);
        return;
      }
      values.push(id);
    });
    return values.sort();
  }

  async list(provider: ProviderRecord, credential: string): Promise<ModelDiscoveryResult> {
    if (credential.trim().length === 0) return { models: [], message: '未找到该供应商的受保护密钥。' };
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(EndpointResolver.models(provider), {
        method: http.RequestMethod.GET,
        header: this.headersFor(provider, credential),
        connectTimeout: 15000,
        readTimeout: 15000
      });
      if (response.responseCode === 401 || response.responseCode === 403) return { models: [], message: '模型列表请求被密钥拒绝，请检查供应商配置。' };
      if (response.responseCode < 200 || response.responseCode >= 300) return { models: [], message: `模型列表请求失败（HTTP ${response.responseCode}）。` };
      const models: string[] = this.names(provider, this.payload(response));
      return models.length > 0 ? { models, message: `已获取 ${models.length} 个可用模型。` } : { models: [], message: '供应商已连接，但未返回可用于聊天的模型。' };
    } catch (_) {
      return { models: [], message: '无法获取模型列表，请检查网络、服务地址和密钥。' };
    } finally {
      request.destroy();
    }
  }
}
