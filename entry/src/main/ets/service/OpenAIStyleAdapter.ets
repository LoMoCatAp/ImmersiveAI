import { ChatMessage, ChatToolCall, ProtocolAdapter, StreamDelta, StreamRequestOptions, Usage } from '../model/ProtocolModels';
import { ProtocolStyle } from '../model/ProviderModels';
import { hilog } from '@kit.PerformanceAnalysisKit';
export class OpenAIStyleAdapter implements ProtocolAdapter {
  style: ProtocolStyle = ProtocolStyle.OpenAI;
  buildBody(messages: ChatMessage[], modelName: string, options: StreamRequestOptions): string {
    const serializedMessages: string[] = messages.map((message: ChatMessage): string => {
      let item: string = `{"role":${JSON.stringify(message.role)},"content":${JSON.stringify(message.content)}`;
      if (message.toolCalls !== undefined && message.toolCalls.length > 0) {
        const calls: string = message.toolCalls.map((call: ChatToolCall): string => `{"id":${JSON.stringify(call.id)},"type":"function","function":{"name":${JSON.stringify(call.name)},"arguments":${JSON.stringify(call.arguments)}}}`).join(',');
        item += `,"tool_calls":[${calls}]`;
      }
      if (message.toolCallId !== undefined) item += `,"tool_call_id":${JSON.stringify(message.toolCallId)}`;
      if (message.name !== undefined) item += `,"name":${JSON.stringify(message.name)}`;
      return `${item}}`;
    });
    let body: string = `{"model":${JSON.stringify(modelName)},"stream":true,"stream_options":{"include_usage":true},"messages":[${serializedMessages.join(',')}]`;
    if (options.enableWebSearch) body += ',"enable_search":true,"search_options":{"search_strategy":"turbo"}';
    return `${body}}`;
  }
  parseEvent(event: string): StreamDelta {
    const empty: Usage | undefined = undefined;
    const dataLines: string[] = event.split('\n').filter((line: string): boolean => line.startsWith('data:'))
      .map((line: string): string => line.slice(5).trim());
    const payload: string = (dataLines.length > 0 ? dataLines.join('\n') : event).trim();
    if (payload === '[DONE]') return { content: '', reasoning: '', finishReason: 'stop', usage: empty, eventType: 'end', error: '', toolCalls: [] };
    try {
      const root: Record<string, Object> = JSON.parse(payload) as Record<string, Object>;
      const errorValue: Object | undefined = root['error'];
      if (errorValue !== undefined) {
        const error: Record<string, Object> = errorValue as Record<string, Object>;
        const message: Object | undefined = error['message'];
        hilog.error(0x0000, 'AIBoxStream', 'provider error message present=%{public}s', typeof message === 'string' ? 'yes' : 'no');
        return { content: '', reasoning: '', finishReason: '', usage: empty, eventType: 'error', error: typeof message === 'string' ? message : 'The provider returned an error.', toolCalls: [] };
      }
      const choices: Array<Object> = (root['choices'] as Array<Object> | undefined) ?? [];
      const choice: Record<string, Object> = choices.length > 0 ? choices[0] as Record<string, Object> : {};
      const delta: Record<string, Object> = (choice['delta'] as Record<string, Object> | undefined) ?? {};
      const message: Record<string, Object> = (choice['message'] as Record<string, Object> | undefined) ?? {};
      const contentValue: Object | undefined = delta['content'] ?? message['content'] ?? choice['text'] ?? root['output_text'] ?? root['content'];
      const reasoningValue: Object | undefined = delta['reasoning_content'] ?? delta['reasoning'] ?? message['reasoning_content'] ?? message['reasoning'];
      const rawToolCalls: Array<Object> = (delta['tool_calls'] as Array<Object> | undefined) ?? (message['tool_calls'] as Array<Object> | undefined) ?? [];
      const toolCalls: ChatToolCall[] = rawToolCalls.map((entry: Object, index: number): ChatToolCall => {
        const call: Record<string, Object> = entry as Record<string, Object>;
        const fn: Record<string, Object> = (call['function'] as Record<string, Object> | undefined) ?? {};
        return { index: Number(call['index'] ?? index), id: String(call['id'] ?? ''), name: String(fn['name'] ?? ''), arguments: String(fn['arguments'] ?? '') };
      });
      const usageObject: Record<string, Object> = (root['usage'] as Record<string, Object> | undefined) ?? {};
      const usage: Usage | undefined = usageObject['total_tokens'] !== undefined ? {
        inputTokens: Number(usageObject['prompt_tokens'] ?? 0), outputTokens: Number(usageObject['completion_tokens'] ?? 0), totalTokens: Number(usageObject['total_tokens'] ?? 0)
      } : undefined;
      return {
        content: typeof contentValue === 'string' ? contentValue : '',
        reasoning: typeof reasoningValue === 'string' ? reasoningValue : '',
        finishReason: String(choice['finish_reason'] ?? ''), usage, eventType: 'data', error: '', toolCalls
      };
    } catch (_) {
      hilog.error(0x0000, 'AIBoxStream', 'protocol parse failed payloadLength=%{public}d', payload.length);
      return { content: '', reasoning: '', finishReason: '', usage: empty, eventType: 'protocolError', error: 'The provider response format is invalid.', toolCalls: [] };
    }
  }
}
