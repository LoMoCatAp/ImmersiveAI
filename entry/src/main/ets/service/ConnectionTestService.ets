import { http } from '@kit.NetworkKit';
import { ProviderRecord, ConnectionTestResult, ConnectionTestStatus } from '../model/ProviderModels';
import { EndpointResolver } from './EndpointResolver';

export class ConnectionTestService {
  private headersFor(provider: ProviderRecord, credential: string): Record<string, string> {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', 'Accept': 'application/json' };
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

  private testBody(provider: ProviderRecord): string {
    if (provider.protocolStyle === 'openaiResponses') return `{"model":${JSON.stringify(provider.modelName)},"input":"ping","max_output_tokens":1}`;
    if (provider.protocolStyle === 'claudeStyle') {
      return `{"model":${JSON.stringify(provider.modelName)},"max_tokens":1,"messages":[{"role":"user","content":"ping"}]}`;
    }
    if (provider.protocolStyle === 'geminiStyle') {
      return '{"contents":[{"role":"user","parts":[{"text":"ping"}]}]}';
    }
    return `{"model":${JSON.stringify(provider.modelName)},"max_tokens":1,"messages":[{"role":"user","content":"ping"}]}`;
  }

  private async testModelAccess(provider: ProviderRecord, credential: string): Promise<ConnectionTestResult | undefined> {
    if (provider.protocolStyle === 'claudeStyle') return undefined;
    const request: http.HttpRequest = http.createHttp();
    const now: number = Date.now();
    try {
      const response: http.HttpResponse = await request.request(EndpointResolver.models(provider), {
        method: http.RequestMethod.GET,
        header: this.headersFor(provider, credential),
        connectTimeout: 15000,
        readTimeout: 15000
      });
      if (response.responseCode >= 200 && response.responseCode < 400) return { status: ConnectionTestStatus.Success, safeMessage: '服务地址和密钥验证成功。', checkedAt: now, responseSummary: `HTTP ${response.responseCode}` };
      if (response.responseCode === 401 || response.responseCode === 403) return { status: ConnectionTestStatus.ServiceError, safeMessage: '服务拒绝了受保护密钥，请检查供应商配置。', checkedAt: now, responseSummary: `HTTP ${response.responseCode}` };
      return undefined;
    } catch (_) {
      return undefined;
    } finally {
      request.destroy();
    }
  }

  async test(provider: ProviderRecord, credential: string): Promise<ConnectionTestResult> {
    const now: number = Date.now();
     if (provider.endpoint.trim().length === 0 || credential.length === 0) return { status: ConnectionTestStatus.ConfigurationError, safeMessage: '测试前请填写服务地址和受保护密钥。', checkedAt: now, responseSummary: '' };
    const modelAccess: ConnectionTestResult | undefined = await this.testModelAccess(provider, credential);
    if (modelAccess !== undefined) return modelAccess;
    if (provider.modelName.trim().length === 0) return { status: ConnectionTestStatus.ConfigurationError, safeMessage: '当前服务未提供模型列表，请手动填写模型后重试。', checkedAt: now, responseSummary: '' };
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(EndpointResolver.chatCompletions(provider), {
        method: http.RequestMethod.POST,
        header: this.headersFor(provider, credential),
        extraData: this.testBody(provider),
        connectTimeout: 15000,
        readTimeout: 15000
      });
       if (response.responseCode >= 200 && response.responseCode < 400) return { status: ConnectionTestStatus.Success, safeMessage: '连接测试成功。', checkedAt: now, responseSummary: `HTTP ${response.responseCode}` };
       if (response.responseCode === 401 || response.responseCode === 403) return { status: ConnectionTestStatus.ServiceError, safeMessage: '服务拒绝了受保护密钥，请检查供应商配置。', checkedAt: now, responseSummary: `HTTP ${response.responseCode}` };
       return { status: ConnectionTestStatus.ProtocolError, safeMessage: '服务返回了异常响应，请检查协议和地址。', checkedAt: now, responseSummary: `HTTP ${response.responseCode}` };
     } catch (_) { return { status: ConnectionTestStatus.NetworkError, safeMessage: '无法连接服务，请检查网络和用户填写的地址。', checkedAt: now, responseSummary: '' }; } finally { request.destroy(); }
  }
}
