import { ChatMessage, ProtocolAdapter, StreamDelta, StreamRequestOptions, Usage } from '../model/ProtocolModels';
import { ProtocolStyle } from '../model/ProviderModels';
interface GeminiPart { text: string }
interface GeminiContent { role: string; parts: GeminiPart[] }
interface GeminiSystemInstruction { parts: GeminiPart[] }
interface GeminiRequest { contents: GeminiContent[]; systemInstruction?: GeminiSystemInstruction }
export class GeminiStyleAdapter implements ProtocolAdapter {
  style: ProtocolStyle = ProtocolStyle.Gemini;
  buildBody(messages: ChatMessage[], modelName: string, _options: StreamRequestOptions): string {
    const system: string = messages.filter((message: ChatMessage): boolean => message.role === 'system').map((message: ChatMessage): string => message.content).join('\n');
    const contents: GeminiContent[] = messages.filter((message: ChatMessage): boolean => message.role !== 'system').map((message: ChatMessage): GeminiContent => ({ role: message.role === 'assistant' ? 'model' : 'user', parts: [{ text: message.content }] }));
    const request: GeminiRequest = { contents };
    if (system.length > 0) { const part: GeminiPart = { text: system }; request.systemInstruction = { parts: [part] }; }
    return JSON.stringify(request);
  }
  parseEvent(event: string): StreamDelta {
    const empty: Usage | undefined = undefined;
    try {
      const root: Record<string, Object> = JSON.parse(event.startsWith('data:') ? event.slice(5).trim() : event.trim()) as Record<string, Object>;
      const candidates: Array<Object> = (root['candidates'] as Array<Object> | undefined) ?? [];
      const candidate: Record<string, Object> = candidates.length > 0 ? candidates[0] as Record<string, Object> : {};
      const content: Record<string, Object> = (candidate['content'] as Record<string, Object> | undefined) ?? {};
      const parts: Array<Object> = (content['parts'] as Array<Object> | undefined) ?? [];
      const part: Record<string, Object> = parts.length > 0 ? parts[0] as Record<string, Object> : {};
      const metadata: Record<string, Object> = (root['usageMetadata'] as Record<string, Object> | undefined) ?? {};
      const usage: Usage | undefined = metadata['totalTokenCount'] !== undefined ? { inputTokens: Number(metadata['promptTokenCount'] ?? 0), outputTokens: Number(metadata['candidatesTokenCount'] ?? 0), totalTokens: Number(metadata['totalTokenCount'] ?? 0) } : undefined;
      return { content: String(part['text'] ?? ''), reasoning: '', finishReason: String(candidate['finishReason'] ?? ''), usage, eventType: 'candidate', error: root['error'] !== undefined ? 'The provider returned an error.' : '', toolCalls: [] };
    } catch (_) { return { content: '', reasoning: '', finishReason: '', usage: empty, eventType: 'protocolError', error: 'The provider response format is invalid.', toolCalls: [] }; }
  }
}
