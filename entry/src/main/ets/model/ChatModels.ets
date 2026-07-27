export enum MessageStatus { Generating = 'generating', Completed = 'completed', Stopped = 'stopped', Failed = 'failed' }
export interface ConversationRecord { id: string; title: string; providerId: string; modelName: string; status: MessageStatus; createdAt: number; updatedAt: number }
export interface MessageRecord { id: string; conversationId: string; sequence: number; role: string; content: string; reasoningContent: string; sourceData?: string; status: MessageStatus; errorSummary: string; createdAt: number; updatedAt: number; inputTokens?: number; outputTokens?: number; totalTokens?: number }
export interface ChatSelection { providerId: string; modelName: string; enabled: boolean }
export interface ChatViewState { selection: ChatSelection; hasEnabledProvider: boolean; generationLabel: string; safeError: string }
