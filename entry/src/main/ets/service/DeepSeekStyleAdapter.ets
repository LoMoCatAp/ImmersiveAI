import { ChatMessage, ProtocolAdapter, StreamDelta, StreamRequestOptions } from '../model/ProtocolModels';
import { ProtocolStyle } from '../model/ProviderModels';
import { OpenAIStyleAdapter } from './OpenAIStyleAdapter';

interface DeepSeekMessage {
  role: string;
  content: string;
  reasoning_content?: string;
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
    return JSON.stringify({ model: resolvedModel, stream: true, messages: apiMessages });
  }

  parseEvent(event: string): StreamDelta {
    return this.parser.parseEvent(event);
  }
}
