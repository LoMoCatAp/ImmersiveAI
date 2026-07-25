import { ChatMessage, ProtocolAdapter, StreamDelta, Usage } from '../model/ProtocolModels';
import { ProtocolStyle } from '../model/ProviderModels';
import { hilog } from '@kit.PerformanceAnalysisKit';
export class OpenAIStyleAdapter implements ProtocolAdapter {
  style: ProtocolStyle = ProtocolStyle.OpenAI;
  buildBody(messages: ChatMessage[], modelName: string): string {
    return JSON.stringify({ model: modelName, stream: true, messages });
  }
  parseEvent(event: string): StreamDelta {
    const empty: Usage | undefined = undefined;
    const dataLines: string[] = event.split('\n').filter((line: string): boolean => line.startsWith('data:'))
      .map((line: string): string => line.slice(5).trim());
    const payload: string = (dataLines.length > 0 ? dataLines.join('\n') : event).trim();
    if (payload === '[DONE]') return { content: '', reasoning: '', finishReason: 'stop', usage: empty, eventType: 'end', error: '' };
    try {
      const root: Record<string, Object> = JSON.parse(payload) as Record<string, Object>;
      const errorValue: Object | undefined = root['error'];
      if (errorValue !== undefined) {
        const error: Record<string, Object> = errorValue as Record<string, Object>;
        const message: Object | undefined = error['message'];
        hilog.error(0x0000, 'AIBoxStream', 'provider error message present=%{public}s', typeof message === 'string' ? 'yes' : 'no');
        return { content: '', reasoning: '', finishReason: '', usage: empty, eventType: 'error', error: typeof message === 'string' ? message : 'The provider returned an error.' };
      }
      const choices: Array<Object> = (root['choices'] as Array<Object> | undefined) ?? [];
      const choice: Record<string, Object> = choices.length > 0 ? choices[0] as Record<string, Object> : {};
      const delta: Record<string, Object> = (choice['delta'] as Record<string, Object> | undefined) ?? {};
      const message: Record<string, Object> = (choice['message'] as Record<string, Object> | undefined) ?? {};
      const contentValue: Object | undefined = delta['content'] ?? message['content'] ?? choice['text'] ?? root['output_text'] ?? root['content'];
      const reasoningValue: Object | undefined = delta['reasoning_content'] ?? delta['reasoning'] ?? message['reasoning_content'] ?? message['reasoning'];
      const usageObject: Record<string, Object> = (root['usage'] as Record<string, Object> | undefined) ?? {};
      const usage: Usage | undefined = usageObject['total_tokens'] !== undefined ? {
        inputTokens: Number(usageObject['prompt_tokens'] ?? 0), outputTokens: Number(usageObject['completion_tokens'] ?? 0), totalTokens: Number(usageObject['total_tokens'] ?? 0)
      } : undefined;
      return {
        content: typeof contentValue === 'string' ? contentValue : '',
        reasoning: typeof reasoningValue === 'string' ? reasoningValue : '',
        finishReason: String(choice['finish_reason'] ?? ''), usage, eventType: 'data', error: ''
      };
    } catch (_) {
      hilog.error(0x0000, 'AIBoxStream', 'protocol parse failed payloadLength=%{public}d', payload.length);
      return { content: '', reasoning: '', finishReason: '', usage: empty, eventType: 'protocolError', error: 'The provider response format is invalid.' };
    }
  }
}
