import { ChatMessage, ProtocolAdapter, StreamDelta } from '../model/ProtocolModels';
import { ProviderRecord } from '../model/ProviderModels';
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SseStreamParser } from './SseStreamParser';
import { EndpointResolver } from './EndpointResolver';

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

  async stream(provider: ProviderRecord, messages: ChatMessage[], credential: string, adapter: ProtocolAdapter, onDelta: (delta: StreamDelta) => void): Promise<void> {
    if (provider.endpoint.trim().length === 0 || credential.length === 0) return;
    const body: string = adapter.buildBody(messages, provider.modelName);
    this.request = http.createHttp();
    const parser: SseStreamParser = new SseStreamParser();
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
      onDelta({ content: '', reasoning: '', finishReason: 'stop', usage: undefined, eventType: 'end', error: '' });
      complete();
    };
    this.request.on('dataReceive', receive);
    this.request.on('dataEnd', end);
    try {
      const responseCode: number = await this.request.requestInStream(EndpointResolver.chatCompletions(provider), {
        method: http.RequestMethod.POST,
        header: this.headersFor(provider, credential),
        extraData: body,
        connectTimeout: 30000,
        readTimeout: 120000
      });
      hilog.info(0x0000, 'AIBoxStream', 'response code=%{public}d', responseCode);
      if (responseCode < 200 || responseCode >= 300) throw new Error(`Chat request failed with HTTP ${responseCode}.`);
      await completion;
    } finally {
      this.request.off('dataReceive', receive);
      this.request.off('dataEnd');
      this.request.destroy();
      this.request = undefined;
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
