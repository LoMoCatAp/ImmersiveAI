import { ChatMessage, ChatToolCall, ProtocolAdapter, StreamDelta, StreamRequestOptions } from '../model/ProtocolModels';
import { ProviderKind, ProviderRecord } from '../model/ProviderModels';
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SseStreamParser } from './SseStreamParser';
import { EndpointResolver } from './EndpointResolver';

interface StreamAttempt {
  finishReason: string;
  toolCalls: ChatToolCall[];
}

export class StreamingChatService {
  private request: http.HttpRequest | undefined;
  private completeActiveStream: () => void = (): void => {};

  private headersFor(provider: ProviderRecord, credential: string): Record<string, string> {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', 'Accept': 'text/event-stream' };
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

  async stream(provider: ProviderRecord, messages: ChatMessage[], credential: string, adapter: ProtocolAdapter, options: StreamRequestOptions, onDelta: (delta: StreamDelta) => void): Promise<void> {
    let requestMessages: ChatMessage[] = messages;
    for (let round: number = 0; round < 4; round++) {
      const result: StreamAttempt = await this.streamOnce(provider, requestMessages, credential, adapter, options, onDelta);
      if (provider.providerKind !== ProviderKind.Kimi || !options.enableWebSearch || result.finishReason !== 'tool_calls' || result.toolCalls.length === 0) return;
      const assistant: ChatMessage = { role: 'assistant', content: '', reasoningContent: '', toolCalls: result.toolCalls };
      const toolMessages: ChatMessage[] = result.toolCalls.map((call: ChatToolCall): ChatMessage => ({ role: 'tool', content: call.arguments, reasoningContent: '', toolCallId: call.id, name: call.name }));
      requestMessages = requestMessages.concat([assistant]).concat(toolMessages);
    }
    onDelta({ content: '', reasoning: '', finishReason: '', usage: undefined, eventType: 'toolLimit', error: 'The web search tool did not complete.' , toolCalls: [] });
  }

  private async streamOnce(provider: ProviderRecord, messages: ChatMessage[], credential: string, adapter: ProtocolAdapter, options: StreamRequestOptions, onDelta: (delta: StreamDelta) => void): Promise<StreamAttempt> {
    if (provider.endpoint.trim().length === 0 || credential.length === 0) {
      const emptyAttempt: StreamAttempt = { finishReason: '', toolCalls: [] };
      return emptyAttempt;
    }
    const body: string = adapter.buildBody(messages, provider.modelName, options);
    const request: http.HttpRequest = http.createHttp();
    this.request = request;
    const parser: SseStreamParser = new SseStreamParser();
    const collectedToolCalls: Map<number, ChatToolCall> = new Map<number, ChatToolCall>();
    let finishReason: string = '';
    let finishStream: () => void = (): void => {};
    let finished: boolean = false;
    const completion: Promise<void> = new Promise<void>((resolve: () => void): void => { finishStream = resolve; });
    const complete = (): void => {
      if (finished) return;
      finished = true;
      finishStream();
    };
    this.completeActiveStream = complete;
    const emit = (frame: string): void => {
      const delta: StreamDelta = adapter.parseEvent(frame);
      if (delta.finishReason.length > 0) finishReason = delta.finishReason;
      delta.toolCalls.forEach((partial: ChatToolCall): void => {
        const current: ChatToolCall | undefined = collectedToolCalls.get(partial.index);
        const merged: ChatToolCall = {
          index: partial.index,
          id: partial.id.length > 0 ? partial.id : (current?.id ?? ''),
          name: partial.name.length > 0 ? partial.name : (current?.name ?? ''),
          arguments: `${current?.arguments ?? ''}${partial.arguments}`
        };
        collectedToolCalls.set(partial.index, merged);
      });
      hilog.info(0x0000, 'AIBoxStream', 'frame content=%{public}d reasoning=%{public}d finish=%{public}s error=%{public}s', delta.content.length, delta.reasoning.length, delta.finishReason, delta.error.length > 0 ? 'yes' : 'no');
      onDelta(delta);
      if (delta.finishReason.length > 0 || delta.error.length > 0) complete();
    };
    const receive: (data: ArrayBuffer) => void = (data: ArrayBuffer): void => {
      const decoded: string = util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(new Uint8Array(data), { stream: true });
      const frames: string[] = parser.feed(decoded);
      hilog.info(0x0000, 'AIBoxStream', 'received bytes=%{public}d frames=%{public}d', data.byteLength, frames.length);
      frames.forEach(emit);
    };
    const end = (): void => {
      const frames: string[] = parser.finish();
      hilog.info(0x0000, 'AIBoxStream', 'data end remainingFrames=%{public}d', frames.length);
      frames.forEach(emit);
      if (finishReason.length === 0) {
        finishReason = 'stop';
        onDelta({ content: '', reasoning: '', finishReason: 'stop', usage: undefined, eventType: 'end', error: '', toolCalls: [] });
      }
      complete();
    };
    request.on('dataReceive', receive);
    request.on('dataEnd', end);
    try {
      const responseCode: number = await request.requestInStream(EndpointResolver.chatCompletions(provider), {
        method: http.RequestMethod.POST,
        header: this.headersFor(provider, credential),
        extraData: body,
        connectTimeout: 30000,
        readTimeout: 120000
      });
      hilog.info(0x0000, 'AIBoxStream', 'response code=%{public}d', responseCode);
      if (responseCode < 200 || responseCode >= 300) throw new Error(`Chat request failed with HTTP ${responseCode}.`);
      await completion;
      const result: StreamAttempt = { finishReason, toolCalls: Array.from(collectedToolCalls.values()) };
      return result;
    } finally {
      request.off('dataReceive', receive);
      request.off('dataEnd');
      request.destroy();
      if (this.request === request) this.request = undefined;
      this.completeActiveStream = (): void => {};
    }
  }

  stop(): void {
    if (this.request !== undefined) {
      this.completeActiveStream();
      this.request.destroy();
      this.request = undefined;
    }
  }
}
