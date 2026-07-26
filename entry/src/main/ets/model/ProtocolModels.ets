import { ProtocolStyle } from './ProviderModels';
export interface ChatMessage { role: string; content: string; reasoningContent: string; toolCalls?: ChatToolCall[]; toolCallId?: string; name?: string }
export interface ChatToolCall { index: number; id: string; name: string; arguments: string }
export interface StreamRequestOptions { enableWebSearch: boolean }
export interface Usage { inputTokens: number; outputTokens: number; totalTokens: number }
export interface StreamDelta { content: string; reasoning: string; finishReason: string; usage: Usage | undefined; eventType: string; error: string; toolCalls: ChatToolCall[] }
export enum StreamingState { Ready = 'ready', Connecting = 'connecting', Generating = 'generating', Stopped = 'stopped', Completed = 'completed', Failed = 'failed' }
export interface ProtocolAdapter { style: ProtocolStyle; buildBody(messages: ChatMessage[], modelName: string, options: StreamRequestOptions): string; parseEvent(event: string): StreamDelta }
