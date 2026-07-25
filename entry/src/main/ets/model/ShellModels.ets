export enum ShellTab { Chat = 0, History = 1, Providers = 2, My = 3 }
export enum MaterialMode { VerifiedOfficial = 'verifiedOfficial', Fallback = 'fallback', Unavailable = 'unavailable' }
export enum MaterialLevel { Off = 'OFF', Exquisite = 'EXQUISITE', Gentle = 'GENTLE', Smooth = 'SMOOTH', Adaptive = 'ADAPTIVE' }
export interface MaterialOption { level: MaterialLevel; label: string; description: string; isDefault: boolean; available: boolean; reason: string }
export interface MaterialState { selected: MaterialLevel; effective: MaterialLevel; options: Array<MaterialOption>; materialTypeAvailable: boolean; status: string; persisted: boolean }
export enum FirstUseState { Loading = 'loading', NoProvider = 'noProvider', HasEnabledProvider = 'hasEnabledProvider', Error = 'error' }
export interface GlobalFeedback { message: string; category: string; isLoading: boolean; retryable: boolean }
export enum OperationPhase { Idle = 'idle', Loading = 'loading', Success = 'success', Failure = 'failure', Cancelled = 'cancelled' }
export interface CoreOperationState { operation: string; phase: OperationPhase; message: string; retryable: boolean; requestId: number }
export enum NavigationSource { EmptyState = 'emptyState', HdsTabs = 'hdsTabs', FallbackNavigation = 'fallbackNavigation', System = 'system' }
export interface NavigationIntent { target: ShellTab; source: NavigationSource; requestId: number }
export interface MyPageState { showMaterialSettings: boolean; entrySummary: string; returnTarget: ShellTab }
export interface ShellState { selectedTab: ShellTab; materialMode: MaterialMode; materialReason: string; firstUseState: FirstUseState; globalFeedback: GlobalFeedback; refreshVersion: number; lastNavigationIntent: NavigationIntent | undefined; material: MaterialState; myPage: MyPageState }
export interface HdsCapabilityState { sdkAvailable: boolean; runtimeAvailable: boolean; presentationVerified: boolean; reason: string; verifiedSymbols: Array<string> }
