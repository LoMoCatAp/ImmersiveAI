import { ProviderKind, ProtocolStyle } from '../model/ProviderModels';
export class ProviderRegistry { static style(kind: ProviderKind): ProtocolStyle { if (kind === ProviderKind.Anthropic) return ProtocolStyle.Claude; if (kind === ProviderKind.Gemini) return ProtocolStyle.Gemini; return ProtocolStyle.OpenAI; } }
