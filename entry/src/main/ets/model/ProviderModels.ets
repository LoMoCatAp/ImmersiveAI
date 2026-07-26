export enum ProviderKind { OpenAI = 'openai', OpenAICompatible = 'openaiCompatible', DeepSeek = 'deepseek', GLM = 'glm', Anthropic = 'anthropic', Gemini = 'gemini', XAI = 'xai', Qwen = 'qwen', Kimi = 'kimi' }
export enum ProtocolStyle { OpenAI = 'openaiStyle', OpenAIResponses = 'openaiResponses', Claude = 'claudeStyle', Gemini = 'geminiStyle' }
export enum ValidationState { Unknown = 'unknown', Validating = 'validating', Valid = 'valid', Invalid = 'invalid' }
export interface ProviderRecord { id: string; displayName: string; providerKind: ProviderKind; protocolStyle: ProtocolStyle; endpoint: string; modelName: string; credentialAlias: string; maskedCredential: string; enabled: boolean; validationState: ValidationState; createdAt: number; updatedAt: number }
export interface ProviderDraft { displayName: string; providerKind: ProviderKind; protocolStyle: ProtocolStyle; endpoint: string; modelName: string; credential: string }
export interface ImportPreview { draft: ProviderDraft; protocolStyle: ProtocolStyle; maskedCredential: string; errors: string[] }
export enum ConnectionTestStatus { Idle = 'idle', Testing = 'testing', Success = 'success', ConfigurationError = 'configurationError', NetworkError = 'networkError', ProtocolError = 'protocolError', ServiceError = 'serviceError' }
export interface ConnectionTestResult { status: ConnectionTestStatus; safeMessage: string; checkedAt: number; responseSummary: string }
export enum ProviderOperation { Idle = 'idle', Saving = 'saving', Toggling = 'toggling', Deleting = 'deleting', Testing = 'testing', Importing = 'importing', Cancelling = 'cancelling' }
