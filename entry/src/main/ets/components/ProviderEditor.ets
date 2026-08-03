import { ProtocolStyle, ProviderDraft, ProviderKind } from '../model/ProviderModels';
import { ProviderPresets } from '../service/ProviderPresets';
import { ProviderRegistry } from '../service/ProviderRegistry';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { ModelDiscoveryResult } from '../service/ModelDiscoveryService';
import { uiMaterial } from '@kit.ArkUI';

const PROVIDER_KINDS: ProviderKind[] = [ProviderKind.OpenAICompatible, ProviderKind.OpenAI, ProviderKind.DeepSeek, ProviderKind.Kimi, ProviderKind.Qwen, ProviderKind.GLM, ProviderKind.Anthropic, ProviderKind.Gemini];
const PROVIDER_OPTIONS: SelectOption[] = [{ value: 'OpenAI compatible' }, { value: 'OpenAI' }, { value: 'DeepSeek' }, { value: 'Kimi' }, { value: 'Qwen' }, { value: 'ZHIPU AI' }, { value: 'Anthropic Claude' }, { value: 'Google Gemini' }];
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
  @State private availableModels: string[] = [];
  @State private modelDiscoveryMessage: string = '';
  @State private isDiscoveringModels: boolean = false;
  @Prop existingId: string = '';
  @Prop initialDraft: ProviderDraft | undefined = undefined;
  @Prop showOnboardingGuide: boolean = false;
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  onSave: (draft: ProviderDraft, id: string) => void = (_draft: ProviderDraft, _id: string): void => {};
  onCancel: () => void = (): void => {};
  onDiscoverModels: (draft: ProviderDraft, id: string) => Promise<ModelDiscoveryResult> = async (_draft: ProviderDraft, _id: string): Promise<ModelDiscoveryResult> => ({ models: [], message: '' });

  private immersiveMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: Color.Transparent,
      applyShadow: false,
      interactive: true,
      lightEffect: { color: this.appearanceAccentColor }
    });
  }

  aboutToAppear(): void {
    const draft: ProviderDraft | undefined = this.initialDraft;
    if (draft === undefined) return;
    this.name = draft.displayName;
    this.endpoint = draft.endpoint;
    this.model = draft.modelName;
    this.kind = draft.providerKind;
    this.protocol = draft.protocolStyle;
    if (this.existingId.length > 0 || (this.endpoint.trim().length > 0 && this.credentialInput.trim().length > 0)) void this.refreshModels();
  }

  private kindIndex(): number { const index: number = PROVIDER_KINDS.findIndex((value: ProviderKind): boolean => value === this.kind); return index < 0 ? 0 : index; }
  private modelOptions(): SelectOption[] { return this.availableModels.map((value: string): SelectOption => ({ value })); }
  private modelIndex(): number { const index: number = this.availableModels.findIndex((value: string): boolean => value === this.model); return index < 0 ? 0 : index; }
  private protocolIndex(): number { return this.protocol === ProtocolStyle.OpenAIResponses ? 1 : 0; }
  private canSelectProtocol(): boolean { return this.kind === ProviderKind.OpenAICompatible || this.kind === ProviderKind.OpenAI || this.kind === ProviderKind.Qwen || this.kind === ProviderKind.XAI; }
  private applyPreset(kind: ProviderKind): void { const preset = ProviderPresets.get(kind); this.kind = kind; this.protocol = ProviderRegistry.style(kind); this.name = preset.displayName; this.model = preset.models.length > 0 ? preset.models[0] : ''; this.endpoint = ProviderPresets.endpointFor(kind, this.model); }
  private save(): void { this.onSave({ displayName: this.name, providerKind: this.kind, protocolStyle: this.protocol, endpoint: this.endpoint, modelName: this.model, credential: this.credentialInput }, this.existingId); }
  private currentDraft(): ProviderDraft { return { displayName: this.name, providerKind: this.kind, protocolStyle: this.protocol, endpoint: this.endpoint, modelName: this.model, credential: this.credentialInput }; }
  private async refreshModels(): Promise<void> {
    if (this.isDiscoveringModels) return;
    this.isDiscoveringModels = true;
    this.modelDiscoveryMessage = '';
    try {
      const result: ModelDiscoveryResult = await this.onDiscoverModels(this.currentDraft(), this.existingId);
      this.availableModels = result.models;
      this.modelDiscoveryMessage = result.message;
      if (result.models.length > 0 && !result.models.some((model: string): boolean => model === this.model)) this.model = result.models[0];
    } finally {
      this.isDiscoveringModels = false;
    }
  }
  private endpointGuide(): string {
    if (this.kind === ProviderKind.OpenAICompatible) return '中转站填写服务商提供的根地址，例如 https://api.example.com；可省略 /v1、/chat/completions 等接口路径。';
    if (this.kind === ProviderKind.DeepSeek) return 'DeepSeek 官方地址：https://api.deepseek.com。无需手动补全 /v1/chat/completions。';
    if (this.kind === ProviderKind.OpenAI) return 'OpenAI 官方地址：https://api.openai.com。无需手动补全 /v1/chat/completions。';
    if (this.kind === ProviderKind.Kimi) return 'Kimi 官方地址：https://api.moonshot.cn。无需手动补全接口路径。';
    if (this.kind === ProviderKind.Qwen) return '通义千问官方地址：https://dashscope.aliyuncs.com。无需手动补全接口路径。';
    return '选择官方模板会自动填入推荐地址；如使用中转站，请改用 OpenAI compatible 并填写服务商提供的根地址。';
  }

  build() {
    Column({ space: 10 }) {
        Text(this.existingId.length > 0 ? '编辑供应商' : '新增供应商').fontSize(22).fontWeight(FontWeight.Bold);
        Text('服务商模板').fontSize(14);
        Select(PROVIDER_OPTIONS).selected(this.kindIndex()).value(PROVIDER_OPTIONS[this.kindIndex()].value).onSelect((index: number, _value: string): void => this.applyPreset(PROVIDER_KINDS[index])).width('100%').backgroundColor(Color.Transparent).fontColor(this.appearanceAccentColor).systemMaterial(this.immersiveMaterial());
        if (this.canSelectProtocol()) {
          Text('接口协议').fontSize(14);
          Select(PROTOCOL_OPTIONS).selected(this.protocolIndex()).value(PROTOCOL_OPTIONS[this.protocolIndex()].value).onSelect((index: number): void => { this.protocol = PROTOCOLS[index]; }).width('100%').backgroundColor(Color.Transparent).fontColor(this.appearanceAccentColor).systemMaterial(this.immersiveMaterial());
        }
        TextInput({ placeholder: '供应商名称', text: this.name }).onChange((value: string): void => { this.name = value; });
        TextInput({ placeholder: '服务地址，例如 https://api.example.com（可省略 /v1 和接口路径）', text: this.endpoint })
          .defaultFocus(this.existingId.length === 0)
          .onChange((value: string): void => { this.endpoint = value; });
        if (this.showOnboardingGuide) {
          Column({ space: 4 }) {
            Text('地址填写提示').fontSize(14).fontWeight(FontWeight.Medium);
            Text(this.endpointGuide()).fontSize(13).lineHeight(20).fontColor(THEME_TOKENS.secondaryText).width('100%');
          }.width('100%').padding(12).backgroundColor(Color.Transparent).borderRadius(16).systemMaterial(this.immersiveMaterial()).alignItems(HorizontalAlign.Start);
        }
        TextInput({ placeholder: '密钥（更新时可留空）', text: this.credentialInput }).type(InputType.Password).onChange((value: string): void => { this.credentialInput = value; });
        Row({ space: 8 }) {
          Text('模型').fontSize(14).fontWeight(FontWeight.Medium).layoutWeight(1);
          Button(this.isDiscoveringModels ? '正在获取' : '刷新可用模型').onClick((): void => { void this.refreshModels(); }).enabled(!this.isDiscoveringModels).fontColor(this.appearanceAccentColor).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
        }.width('100%');
        TextInput({ placeholder: '模型名称，可刷新获取或手动填写', text: this.model }).onChange((value: string): void => { this.model = value; });
        if (this.availableModels.length > 0) Select(this.modelOptions()).selected(this.modelIndex()).value(this.model).onSelect((index: number): void => { const selected: string | undefined = this.availableModels[index]; if (selected !== undefined) this.model = selected; }).width('100%').backgroundColor(Color.Transparent).fontColor(this.appearanceAccentColor).systemMaterial(this.immersiveMaterial());
        if (this.modelDiscoveryMessage.length > 0) Text(this.modelDiscoveryMessage).fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
        Row({ space: 8 }) { Button('保存供应商').onClick((): void => this.save()).height(48).layoutWeight(1).fontColor(this.appearanceAccentColor).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); Button('取消编辑').onClick((): void => this.onCancel()).height(48).layoutWeight(1).fontColor(this.appearanceAccentColor).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial()).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 }); }.width('100%');
    }.padding({ bottom: 24, top: 20 }).width('100%').transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.97, y: 0.97 })).animation({ duration: 220, curve: Curve.EaseOut }));
  }
}
