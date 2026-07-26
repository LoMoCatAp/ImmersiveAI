import { ChatMessage, ProtocolAdapter, StreamDelta, StreamRequestOptions, Usage } from '../model/ProtocolModels';
import { ProtocolStyle } from '../model/ProviderModels';
interface ClaudeMessage {
  role: string;
  content: string;
}
export class ClaudeStyleAdapter implements ProtocolAdapter {
  style: ProtocolStyle = ProtocolStyle.Claude;
  buildBody(messages: ChatMessage[], modelName: string, _options: StreamRequestOptions): string {
    const system: string = messages.filter((message: ChatMessage): boolean => message.role === 'system').map((message: ChatMessage): string => message.content).join('\n');
    const apiMessages: ClaudeMessage[] = messages.filter((message: ChatMessage): boolean => message.role !== 'system').map((message: ChatMessage): ClaudeMessage => ({ role: message.role, content: message.content }));
    return JSON.stringify({ model: modelName, stream: true, max_tokens: 4096, system, messages: apiMessages });
  }
  parseEvent(event: string): StreamDelta {
    const empty: Usage | undefined = undefined;
    const kind: string = event.startsWith('event:') ? event.slice(6).trim() : '';
    const payload: string = event.includes('\ndata:') ? event.slice(event.indexOf('\ndata:') + 6).trim() : event.trim();
    try {
      const root: Record<string, Object> = JSON.parse(payload) as Record<string, Object>;
      const delta: Record<string, Object> = (root['delta'] as Record<string, Object> | undefined) ?? {};
      const usageObject: Record<string, Object> = (root['usage'] as Record<string, Object> | undefined) ?? {};
      const usage: Usage | undefined = usageObject['output_tokens'] !== undefined ? { inputTokens: Number(usageObject['input_tokens'] ?? 0), outputTokens: Number(usageObject['output_tokens'] ?? 0), totalTokens: Number(usageObject['input_tokens'] ?? 0) + Number(usageObject['output_tokens'] ?? 0) } : undefined;
      return { content: String(delta['text'] ?? ''), reasoning: '', finishReason: String(delta['stop_reason'] ?? (kind === 'message_stop' ? 'stop' : '')), usage, eventType: kind.length > 0 ? kind : String(root['type'] ?? 'data'), error: root['error'] !== undefined ? 'The provider returned an error.' : '', toolCalls: [] };
    } catch (_) { return { content: '', reasoning: '', finishReason: kind === 'message_stop' ? 'stop' : '', usage: empty, eventType: kind, error: 'The provider response format is invalid.', toolCalls: [] }; }
  }
}
