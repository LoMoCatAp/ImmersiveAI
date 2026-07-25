export enum ErrorCategory { Configuration = 'configuration', Authentication = 'authentication', RateLimit = 'rateLimit', Network = 'network', Timeout = 'timeout', Service = 'service', Protocol = 'protocol', Storage = 'storage', ConnectionTest = 'connectionTest', ProviderOperation = 'providerOperation', Shell = 'shell', History = 'history', Chat = 'chat' }
export interface SafeError { category: ErrorCategory; message: string; retryable: boolean }
export function safeError(category: ErrorCategory, message: string, retryable: boolean): SafeError { return { category, message, retryable }; }
export function redact(value: string): string { return value.length < 5 ? '••••' : `${value.slice(0, 2)}••••${value.slice(-2)}`; }
