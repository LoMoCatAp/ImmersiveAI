import { ChatMessage, ProtocolAdapter, StreamDelta, StreamRequestOptions, Usage } from '../model/ProtocolModels';
import { ProtocolStyle, ProviderKind } from '../model/ProviderModels';

export class OpenAIResponsesAdapter implements ProtocolAdapter {
  style: ProtocolStyle = ProtocolStyle.OpenAIResponses;
  private providerKind: ProviderKind;

  constructor(providerKind: ProviderKind) {
    this.providerKind = providerKind;
  }

  buildBody(messages: ChatMessage[], modelName: string, options: StreamRequestOptions): string {
    const instructions: string[] = messages.filter((item: ChatMessage): boolean => item.role === 'system' || item.role === 'developer').map((item: ChatMessage): string => item.content);
    const input: string[] = messages.filter((item: ChatMessage): boolean => item.role !== 'system' && item.role !== 'developer').map((item: ChatMessage): string => `{"role":${JSON.stringify(item.role)},"content":[{"type":"input_text","text":${JSON.stringify(item.content)}}]}`);
    let body: string = `{"model":${JSON.stringify(modelName)},"stream":true,"input":[${input.join(',')}]`;
    if (instructions.length > 0) body += `,"instructions":${JSON.stringify(instructions.join('\n\n'))}`;
    if (options.enableWebSearch) {
      if (this.providerKind === ProviderKind.Qwen) body += ',"tools":[{"type":"web_search"}]';
      else body += ',"tools":[{"type":"web_search_preview"}]';
    }
    return `${body}}`;
  }

  parseEvent(event: string): StreamDelta {
    const empty: Usage | undefined = undefined;
    const payload: string = event.split('\n').filter((line: string): boolean => line.startsWith('data:')).map((line: string): string => line.slice(5).trim()).join('\n').trim();
    if (payload === '[DONE]') return { content: '', reasoning: '', finishReason: 'stop', usage: empty, eventType: 'end', error: '', toolCalls: [] };
    try {
      const root: Record<string, Object> = JSON.parse(payload) as Record<string, Object>;
      const type: string = String(root['type'] ?? '');
      const response: Record<string, Object> = (root['response'] as Record<string, Object> | undefined) ?? {};
      const errorRoot: Record<string, Object> = (root['error'] as Record<string, Object> | undefined) ?? (response['error'] as Record<string, Object> | undefined) ?? {};
      if (Object.keys(errorRoot).length > 0 || type === 'response.failed' || type === 'response.incomplete') return { content: '', reasoning: '', finishReason: '', usage: empty, eventType: type, error: String(errorRoot['message'] ?? 'The provider response failed.'), toolCalls: [] };
      const usageRoot: Record<string, Object> = (response['usage'] as Record<string, Object> | undefined) ?? (root['usage'] as Record<string, Object> | undefined) ?? {};
      const usage: Usage | undefined = usageRoot['total_tokens'] === undefined ? empty : { inputTokens: Number(usageRoot['input_tokens'] ?? 0), outputTokens: Number(usageRoot['output_tokens'] ?? 0), totalTokens: Number(usageRoot['total_tokens'] ?? 0) };
      const content: string = type === 'response.output_text.delta' ? String(root['delta'] ?? '') : '';
      const reasoning: string = type.indexOf('reasoning') >= 0 && type.endsWith('.delta') ? String(root['delta'] ?? '') : '';
      const completed: boolean = type === 'response.completed';
      return { content, reasoning, finishReason: completed ? 'stop' : '', usage, eventType: type, error: '', toolCalls: [] };
    } catch (_) {
      return { content: '', reasoning: '', finishReason: '', usage: empty, eventType: 'protocolError', error: 'The provider response format is invalid.', toolCalls: [] };
    }
  }
}
