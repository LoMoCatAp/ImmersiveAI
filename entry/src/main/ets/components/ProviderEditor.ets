import { ProtocolStyle, ProviderDraft, ProviderKind } from '../model/ProviderModels';
import { ProviderPresets } from '../service/ProviderPresets';
import { ProviderRegistry } from '../service/ProviderRegistry';
import { THEME_TOKENS } from '../common/ThemeTokens';

const PROVIDER_KINDS: ProviderKind[] = [ProviderKind.OpenAICompatible, ProviderKind.OpenAI, ProviderKind.Kimi, ProviderKind.Qwen, ProviderKind.DeepSeek, ProviderKind.GLM, ProviderKind.Anthropic, ProviderKind.Gemini, ProviderKind.XAI];
const PROVIDER_OPTIONS: SelectOption[] = [{ value: 'OpenAI compatible' }, { value: 'OpenAI' }, { value: 'Kimi' }, { value: 'Qwen' }, { value: 'DeepSeek' }, { value: 'ZHIPU AI' }, { value: 'Anthropic Claude' }, { value: 'Google Gemini' }, { value: 'xAI Grok' }];
const PROTOCOLS: ProtocolStyle[] = [ProtocolStyle.OpenAI, ProtocolStyle.OpenAIResponses];
const PROTOCOL_OPTIONS: SelectOption[] = [{ value: 'Chat Completions' }, { value: 'Responses API' }];

@Component
export struct ProviderEditor {
  @State private name: string = '';
  @State private endpoint: string = '';
  @State private model: string = '';
  @State private credentialInput: string = '';
  @State private kind: ProviderKind = ProviderKind.OpenAICompatible;
  @State private protocol: ProtocolStyle = ProtocolStyle.OpenAI;
  @Prop existingId: string = '';
  @Prop initialDraft: ProviderDraft | undefined = undefined;
  onSave: (draft: ProviderDraft, id: string) => void = (_draft: ProviderDraft, _id: string): void => {};
  onCancel: () => void = (): void => {};

  aboutToAppear(): void {
    const draft: ProviderDraft | undefined = this.initialDraft;
    if (draft === undefined) return;
    this.name = draft.displayName;
    this.endpoint = draft.endpoint;
    this.model = draft.modelName;
    this.kind = draft.providerKind;
    this.protocol = draft.protocolStyle;
  }

  private kindIndex(): number { const index: number = PROVIDER_KINDS.findIndex((value: ProviderKind): boolean => value === this.kind); return index < 0 ? 0 : index; }
  private modelOptions(): SelectOption[] { return ProviderPresets.get(this.kind).models.map((value: string): SelectOption => ({ value })); }
  private modelIndex(): number { const index: number = ProviderPresets.get(this.kind).models.findIndex((value: string): boolean => value === this.model); return index < 0 ? 0 : index; }
  private protocolIndex(): number { return this.protocol === ProtocolStyle.OpenAIResponses ? 1 : 0; }
  private canSelectProtocol(): boolean { return this.kind === ProviderKind.OpenAICompatible || this.kind === ProviderKind.OpenAI || this.kind === ProviderKind.Qwen || this.kind === ProviderKind.XAI; }
  private applyPreset(kind: ProviderKind): void { const preset = ProviderPresets.get(kind); this.kind = kind; this.protocol = ProviderRegistry.style(kind); this.name = preset.displayName; this.model = preset.models.length > 0 ? preset.models[0] : ''; this.endpoint = ProviderPresets.endpointFor(kind, this.model); }
  private save(): void { this.onSave({ displayName: this.name, providerKind: this.kind, protocolStyle: this.protocol, endpoint: this.endpoint, modelName: this.model, credential: this.credentialInput }, this.existingId); }

  build() {
    Column({ space: 10 }) {
        Text(this.existingId.length > 0 ? '编辑供应商' : '新增供应商').fontSize(22).fontWeight(FontWeight.Bold);
        Text('服务商模板').fontSize(14);
        Select(PROVIDER_OPTIONS).selected(this.kindIndex()).value(PROVIDER_OPTIONS[this.kindIndex()].value).onSelect((index: number, _value: string): void => this.applyPreset(PROVIDER_KINDS[index])).width('100%');
        if (this.canSelectProtocol()) {
          Text('接口协议').fontSize(14);
          Select(PROTOCOL_OPTIONS).selected(this.protocolIndex()).value(PROTOCOL_OPTIONS[this.protocolIndex()].value).onSelect((index: number): void => { this.protocol = PROTOCOLS[index]; }).width('100%');
        }
        TextInput({ placeholder: '供应商名称', text: this.name }).onChange((value: string): void => { this.name = value; });
        TextInput({ placeholder: '服务地址，例如 https://api.example.com（可省略 /v1 和接口路径）', text: this.endpoint }).onChange((value: string): void => { this.endpoint = value; });
        TextInput({ placeholder: '模型名称，例如 gpt-4o-mini 或自定义模型 ID', text: this.model }).onChange((value: string): void => { this.model = value; });
        Text('模型将在聊天页的“更多”中获取和选择。').fontSize(13).fontColor(THEME_TOKENS.secondaryText);
        TextInput({ placeholder: '密钥（更新时可留空）', text: this.credentialInput }).type(InputType.Password).onChange((value: string): void => { this.credentialInput = value; });
        Row({ space: 8 }) { Button('保存供应商').onClick((): void => this.save()).height(48).layoutWeight(1).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); Button('取消编辑').onClick((): void => this.onCancel()).height(48).layoutWeight(1).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); }.width('100%');
    }.padding({ left: 20, right: 20, bottom: 24, top: 20 }).width('100%').transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.97, y: 0.97 })).animation({ duration: 220, curve: Curve.EaseOut }));
  }
}
