import { ChatMessage, ProtocolAdapter, StreamDelta, StreamRequestOptions } from '../model/ProtocolModels';
import { ProtocolStyle } from '../model/ProviderModels';
import { OpenAIStyleAdapter } from './OpenAIStyleAdapter';

interface DeepSeekMessage {
  role: string;
  content: string;
  reasoning_content?: string;
}

interface DeepSeekStreamOptions {
  include_usage: boolean;
}

interface DeepSeekRequest {
  model: string;
  stream: boolean;
  stream_options: DeepSeekStreamOptions;
  messages: DeepSeekMessage[];
}

export class DeepSeekStyleAdapter implements ProtocolAdapter {
  style: ProtocolStyle = ProtocolStyle.OpenAI;
  private readonly parser: OpenAIStyleAdapter = new OpenAIStyleAdapter();

  buildBody(messages: ChatMessage[], modelName: string, _options: StreamRequestOptions): string {
    const apiMessages: DeepSeekMessage[] = messages.map((message: ChatMessage): DeepSeekMessage => {
      const result: DeepSeekMessage = { role: message.role, content: message.content };
      if (message.role === 'assistant' && message.reasoningContent.trim().length > 0) {
        result.reasoning_content = message.reasoningContent;
      }
      return result;
    });
    const resolvedModel: string = modelName === 'deepseek-chat' || modelName === 'deepseek-reasoner' ? 'deepseek-v4-flash' : modelName;
    const streamOptions: DeepSeekStreamOptions = { include_usage: true };
    const request: DeepSeekRequest = { model: resolvedModel, stream: true, stream_options: streamOptions, messages: apiMessages };
    return JSON.stringify(request);
  }

  parseEvent(event: string): StreamDelta {
    return this.parser.parseEvent(event);
  }
}
