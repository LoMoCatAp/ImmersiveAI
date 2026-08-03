import { AppStore } from '../common/AppStore';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { WebSearchConfiguration, WebSearchProvider, WebSearchResponse, WebSearchService } from '../service/WebSearchService';
import { KnowledgeSource } from '../model/CapabilityModels';
import { fileIo as fs, fileUri, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { uiMaterial } from '@kit.ArkUI';

interface SkillOption { name: string; prompt: string; }

const SKILLS: SkillOption[] = [
  { name: '未启用', prompt: '' },
  { name: '写作助手', prompt: '使用清晰、自然的中文完成写作任务。先理解目标读者和用途，再给出结构化、可直接使用的结果。' },
  { name: '编程助手', prompt: '以严谨的工程方式回答。说明假设、边界和可验证步骤；代码应可读、可维护，并优先使用用户现有技术栈。' },
  { name: '学习教练', prompt: '用循序渐进的方式解释概念。先给结论，再给必要的原理、例子与可执行练习。' }
];

const MCP_TRANSPORT_OPTIONS: string[] = ['Streamable HTTP', 'SSE'];
const SEARCH_PROVIDER_OPTIONS: string[] = ['服务商原生', '本地 SearXNG', 'Tavily API', 'Exa API', '博查 API'];
const KNOWLEDGE_LIMIT_OPTIONS: string[] = ['4,000 字符', '8,000 字符', '16,000 字符'];
const KNOWLEDGE_LIMIT_VALUES: number[] = [4000, 8000, 16000];
const IMAGE_SIZE_OPTIONS: string[] = ['1024 x 1024', '1024 x 1536', '1536 x 1024'];
const PROMPT_MEMORY_CONTENT_OFFSET: number = -39;
const SKILLS_CONTENT_OFFSET: number = -49;
const KNOWLEDGE_CONTENT_OFFSET: number = 33;
const TOOLS_CONTENT_OFFSET: number = -70;

@Component
export struct CapabilityCenterView {
  @Prop page: string = 'prompt';
  @State private systemPrompt: string = '';
  @State private globalMemory: string = '';
  @State private knowledge: string = '';
  @State private systemPromptEnabled: boolean = true;
  @State private memoryEnabled: boolean = true;
  @State private skillEnabled: boolean = true;
  @State private knowledgeEnabled: boolean = true;
  @State private knowledgeLimitIndex: number = 1;
  @State private skillIndex: number = 0;
  @State private customSkillName: string = '';
  @State private customSkillPrompt: string = '';
  @State private mcpEndpoint: string = '';
  @State private mcpEnabled: boolean = false;
  @State private mcpTransportIndex: number = 0;
  @State private mcpTimeout: string = '30';
  @State private webSearchEnabled: boolean = false;
  @State private webSearchProviderIndex: number = 0;
  @State private webSearchEndpoint: string = '';
  @State private webSearchApiKey: string = '';
  @State private imageEnabled: boolean = false;
  @State private imageEndpoint: string = '';
  @State private imageModel: string = '';
  @State private imageSizeIndex: number = 0;
  @State private savedMessage: string = '';
  @State private testingSearch: boolean = false;
  @State private showMcpSettings: boolean = false;
  @State private showSearchSettings: boolean = false;
  @State private showImageSettings: boolean = false;
  @State private knowledgeSources: KnowledgeSource[] = [];
  @State private knowledgeNoteTitle: string = '';
  @State private knowledgeNoteContent: string = '';
  @StorageLink('layout_page_padding') private pagePadding: number = THEME_TOKENS.pagePadding;
  @StorageLink('appearance_accent_color') private appearanceAccentColor: string = '#3559D8';
  private contentScroller: Scroller = new Scroller();
  private readonly webSearchService: WebSearchService = new WebSearchService();

  private immersiveMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.REGULAR,
      materialColor: Color.Transparent,
      applyShadow: true,
      interactive: true,
      lightEffect: { color: this.appearanceAccentColor }
    });
  }

  aboutToAppear(): void {
    this.systemPrompt = AppStore.readAppearance('capability_system_prompt', '');
    this.globalMemory = AppStore.readAppearance('capability_global_memory', '');
    this.knowledge = AppStore.readAppearance('capability_knowledge_context', '');
    this.knowledgeSources = AppStore.knowledgeSources();
    this.customSkillName = AppStore.readAppearance('capability_custom_skill_name', '');
    this.customSkillPrompt = AppStore.readAppearance('capability_custom_skill_prompt', '');
    this.mcpEndpoint = AppStore.readAppearance('capability_mcp_endpoint', '');
    this.imageEndpoint = AppStore.readAppearance('capability_image_endpoint', '');
    this.imageModel = AppStore.readAppearance('capability_image_model', '');
    this.systemPromptEnabled = this.readEnabled('capability_system_prompt_enabled', true);
    this.memoryEnabled = this.readEnabled('capability_memory_enabled', true);
    this.skillEnabled = this.readEnabled('capability_skill_enabled', true);
    this.knowledgeEnabled = this.readEnabled('capability_knowledge_enabled', true);
    this.mcpEnabled = this.readEnabled('capability_mcp_enabled', false);
    this.webSearchEnabled = this.readEnabled('capability_web_search_enabled', false);
    this.imageEnabled = this.readEnabled('capability_image_enabled', false);
    this.mcpTimeout = AppStore.readAppearance('capability_mcp_timeout', '30');
    this.webSearchEndpoint = AppStore.readAppearance('capability_web_search_endpoint', '');
    const transport: number = Number(AppStore.readAppearance('capability_mcp_transport', '0'));
    this.mcpTransportIndex = transport >= 0 && transport < MCP_TRANSPORT_OPTIONS.length ? transport : 0;
    const search: number = Number(AppStore.readAppearance('capability_web_search_provider', '0'));
    this.webSearchProviderIndex = search >= 0 && search < SEARCH_PROVIDER_OPTIONS.length ? search : 0;
    const limit: number = Number(AppStore.readAppearance('capability_knowledge_limit', '8000'));
    const limitIndex: number = KNOWLEDGE_LIMIT_VALUES.findIndex((value: number): boolean => value === limit);
    this.knowledgeLimitIndex = limitIndex < 0 ? 1 : limitIndex;
    const imageSize: number = Number(AppStore.readAppearance('capability_image_size', '0'));
    this.imageSizeIndex = imageSize >= 0 && imageSize < IMAGE_SIZE_OPTIONS.length ? imageSize : 0;
    void this.loadSearchApiKey();
    const selected: string = AppStore.readAppearance('capability_active_skill_name', '未启用');
    const index: number = SKILLS.findIndex((skill: SkillOption): boolean => skill.name === selected);
    this.skillIndex = index < 0 ? 0 : index;
  }

  private save(key: string, value: string): void {
    AppStore.saveAppearance(key, value.trim());
    this.savedMessage = '已保存，将在下一条消息中生效';
  }

  private readEnabled(key: string, fallback: boolean): boolean {
    return AppStore.readAppearance(key, fallback ? 'true' : 'false') === 'true';
  }

  private saveEnabled(key: string, enabled: boolean): void {
    AppStore.saveAppearance(key, enabled ? 'true' : 'false');
    this.savedMessage = enabled ? '已启用，将在下一条消息中生效' : '已关闭';
  }

  private saveEnabledSilently(key: string, enabled: boolean): void {
    AppStore.saveAppearance(key, enabled ? 'true' : 'false');
  }

  private async loadSearchApiKey(): Promise<void> {
    const stored: string | undefined = await AppStore.credentials.get('aibox.web_search_api_key');
    this.webSearchApiKey = stored ?? '';
  }

  private async saveSearchSettings(): Promise<void> {
    this.saveEnabled('capability_web_search_enabled', this.webSearchEnabled);
    this.save('capability_web_search_provider', `${this.webSearchProviderIndex}`);
    this.save('capability_web_search_endpoint', this.webSearchEndpoint);
    if (this.webSearchApiKey.trim().length > 0) await AppStore.credentials.update('aibox.web_search_api_key', this.webSearchApiKey.trim());
    this.savedMessage = '搜索配置已保存，API Key 使用系统安全存储';
  }

  private async testSearchSettings(): Promise<void> {
    const provider: WebSearchProvider = this.webSearchProviderIndex as WebSearchProvider;
    if (provider === WebSearchProvider.Native) {
      this.savedMessage = '服务商原生搜索会在聊天页由当前模型执行，无需单独测试。';
      return;
    }
    this.testingSearch = true;
    const configuration: WebSearchConfiguration = {
      provider,
      endpoint: this.webSearchEndpoint.trim(),
      apiKey: this.webSearchApiKey.trim()
    };
    const response: WebSearchResponse = await this.webSearchService.search('HarmonyOS ArkUI', configuration);
    this.testingSearch = false;
    this.savedMessage = response.error.length > 0 ? response.error : `搜索测试成功，获取到 ${response.results.length} 条可引用结果。`;
  }

  private selectSkill(index: number): void {
    const skill: SkillOption | undefined = SKILLS[index];
    if (skill === undefined) return;
    this.skillIndex = index;
    this.save('capability_active_skill_name', skill.name);
    this.save('capability_active_skill_prompt', skill.prompt);
  }

  private saveCustomSkill(): void {
    const name: string = this.customSkillName.trim();
    const prompt: string = this.customSkillPrompt.trim();
    this.save('capability_custom_skill_name', name);
    this.save('capability_custom_skill_prompt', prompt);
    this.save('capability_active_skill_name', name.length > 0 ? name : '未启用');
    this.save('capability_active_skill_prompt', prompt);
    this.skillIndex = 0;
  }

  private saveKnowledgeSource(source: KnowledgeSource): void {
    const sources: KnowledgeSource[] = this.knowledgeSources.filter((item: KnowledgeSource): boolean => item.id !== source.id);
    sources.unshift(source);
    AppStore.saveKnowledgeSources(sources);
    this.knowledgeSources = AppStore.knowledgeSources();
  }

  private addKnowledgeNote(): void {
    const content: string = this.knowledgeNoteContent.trim();
    if (content.length === 0) {
      this.savedMessage = '请先输入笔记内容。';
      return;
    }
    const title: string = this.knowledgeNoteTitle.trim().length > 0 ? this.knowledgeNoteTitle.trim() : '未命名笔记';
    const source: KnowledgeSource = { id: `note-${Date.now()}`, title, sourceType: '笔记', content: content.slice(0, 120000), updatedAt: Date.now() };
    this.saveKnowledgeSource(source);
    this.knowledgeNoteTitle = '';
    this.knowledgeNoteContent = '';
    this.savedMessage = '笔记已加入本地知识库。';
  }

  private removeKnowledgeSource(id: string): void {
    AppStore.saveKnowledgeSources(this.knowledgeSources.filter((source: KnowledgeSource): boolean => source.id !== id));
    this.knowledgeSources = AppStore.knowledgeSources();
    this.savedMessage = '已移除该知识库来源。';
  }

  private supportedKnowledgeFile(name: string): boolean {
    const lower: string = name.toLowerCase();
    const extensions: string[] = ['.txt', '.md', '.markdown', '.json', '.csv', '.xml', '.html', '.htm', '.yaml', '.yml', '.log', '.js', '.ts', '.ets', '.py', '.java', '.c', '.cpp', '.h', '.css', '.sql'];
    return extensions.some((extension: string): boolean => lower.endsWith(extension));
  }

  private async importKnowledgeFile(): Promise<void> {
    AppStorage.setOrCreate('knowledge_file_picker_active', true);
    AppStorage.set('knowledge_file_picker_active', true);
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const uris: string[] = await documentPicker.select();
      if (uris.length === 0) return;
      const uri: string = uris[0];
      const selected: fileUri.FileUri = new fileUri.FileUri(uri);
      if (!this.supportedKnowledgeFile(selected.name)) {
        this.savedMessage = '知识库仅支持导入文本类文件。';
        return;
      }
      const safeName: string = selected.name.replace(/[^a-zA-Z0-9._-]/g, '_');
      const stagedPath: string = `${context.tempDir}/aibox-knowledge-${Date.now()}-${safeName}`;
      try {
        await fs.copy(uri, fileUri.getUriFromPath(stagedPath));
        const content: string = await fs.readText(stagedPath, { length: 120000, encoding: 'utf-8' });
        if (content.trim().length === 0 || content.indexOf('\u0000') >= 0) {
          this.savedMessage = '该文件不是可导入的文本内容。';
          return;
        }
        const source: KnowledgeSource = { id: `file-${Date.now()}`, title: selected.name, sourceType: '文件', content: content.trim(), updatedAt: Date.now() };
        this.saveKnowledgeSource(source);
        this.savedMessage = `已导入知识库文件：${selected.name}`;
      } finally {
        try {
          await fs.unlink(stagedPath);
        } catch (_) {
          // The staged picker file is only needed while importing.
        }
      }
    } catch (_) {
      this.savedMessage = '文件导入失败，请重新选择。';
    } finally {
      AppStorage.setOrCreate('knowledge_file_picker_active', false);
      AppStorage.set('knowledge_file_picker_active', false);
    }
  }

  private skillOptions(): SelectOption[] {
    return SKILLS.map((skill: SkillOption): SelectOption => ({ value: skill.name }));
  }

  @Builder
  private sectionTitle(title: string, detail: string): void {
    Row({ space: 8 }) {
      if (this.page === 'prompt') Image($r('app.media.my_prompt')).width(20).height(20).fillColor(this.appearanceAccentColor);
      else if (this.page === 'skills') Image($r('app.media.my_skills')).width(20).height(20).fillColor(this.appearanceAccentColor);
      else if (this.page === 'knowledge') Image($r('app.media.my_knowledge')).width(20).height(20).fillColor(this.appearanceAccentColor);
      else Image($r('app.media.my_tools')).width(20).height(20).fillColor(this.appearanceAccentColor);
      Column({ space: 3 }) {
        Text(title).fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
        Text(detail).fontSize(12).fontColor(THEME_TOKENS.secondaryText).opacity(0.76).width('100%');
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
    }.alignItems(VerticalAlign.Top).width('100%');
  }

  @Builder
  private systemList(): void {
    List({ space: 0 }) {
      ListItem() {
        Column({ space: 8 }) {
          Row() { Text('默认系统提示词').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Toggle({ type: ToggleType.Switch, isOn: this.systemPromptEnabled }).onChange((enabled: boolean): void => { this.systemPromptEnabled = enabled; this.saveEnabled('capability_system_prompt_enabled', enabled); }); }.width('100%');
          TextInput({ placeholder: '为空时不额外注入系统提示词', text: this.systemPrompt })
            .onChange((value: string): void => { this.systemPrompt = value; })
            .width('100%');
          Button('保存系统提示词').onClick((): void => this.save('capability_system_prompt', this.systemPrompt)).width('100%').height(42).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16);
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Column({ space: 8 }) {
          Row() { Text('全局记忆').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Toggle({ type: ToggleType.Switch, isOn: this.memoryEnabled }).onChange((enabled: boolean): void => { this.memoryEnabled = enabled; this.saveEnabled('capability_memory_enabled', enabled); }); }.width('100%');
          Text('例如称呼、写作偏好与长期项目背景。仅存储在本机。').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
          TextInput({ placeholder: '输入希望 AI 长期记住的信息', text: this.globalMemory })
            .onChange((value: string): void => { this.globalMemory = value; })
            .width('100%');
          Button('保存全局记忆').onClick((): void => this.save('capability_global_memory', this.globalMemory)).width('100%').height(42).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16);
      }
    }.width('100%').backgroundColor(THEME_TOKENS.surface).borderRadius(THEME_TOKENS.cardRadius).scrollBar(BarState.Off);
  }

  @Builder
  private skillList(): void {
    List({ space: 0 }) {
      ListItem() { Row({ space: 12 }) { Text('启用技能').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Toggle({ type: ToggleType.Switch, isOn: this.skillEnabled }).onChange((enabled: boolean): void => { this.skillEnabled = enabled; this.saveEnabled('capability_skill_enabled', enabled); }); }.width('100%').padding(16); }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() { Row({ space: 12 }) { Text('内置技能').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Select(this.skillOptions()).selected(this.skillIndex).value(SKILLS[this.skillIndex].name).onSelect((index: number): void => this.selectSkill(index)); }.width('100%').padding(16); }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Column({ space: 8 }) {
          Text('自定义技能').fontSize(17).fontWeight(FontWeight.Medium).width('100%');
          TextInput({ placeholder: '技能名称', text: this.customSkillName }).onChange((value: string): void => { this.customSkillName = value; }).width('100%');
          TextInput({ placeholder: '技能指令', text: this.customSkillPrompt }).onChange((value: string): void => { this.customSkillPrompt = value; }).width('100%');
          Button('启用自定义技能').onClick((): void => this.saveCustomSkill()).width('100%').height(42).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16);
      }
    }.width('100%').backgroundColor(THEME_TOKENS.surface).borderRadius(THEME_TOKENS.cardRadius).scrollBar(BarState.Off);
  }

  @Builder
  private knowledgeList(): void {
    List({ space: 0 }) {
      ListItem() {
        Column({ space: 8 }) {
          Row() { Text('启用知识库').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1); Toggle({ type: ToggleType.Switch, isOn: this.knowledgeEnabled }).onChange((enabled: boolean): void => { this.knowledgeEnabled = enabled; this.saveEnabled('capability_knowledge_enabled', enabled); }); }.width('100%');
          Row({ space: 12 }) { Text('单次引用上限').fontSize(15).fontColor(THEME_TOKENS.secondaryText).layoutWeight(1); Select(KNOWLEDGE_LIMIT_OPTIONS.map((value: string): SelectOption => ({ value: value }))).selected(this.knowledgeLimitIndex).value(KNOWLEDGE_LIMIT_OPTIONS[this.knowledgeLimitIndex]).onSelect((index: number): void => { this.knowledgeLimitIndex = index; this.save('capability_knowledge_limit', `${KNOWLEDGE_LIMIT_VALUES[index]}`); }); }.width('100%');
          Text('本地知识库').fontSize(17).fontWeight(FontWeight.Medium).width('100%');
          Text('将常用资料摘要写入此处，保存后会作为当前对话的参考内容发送给已启用的服务商。').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
          TextInput({ placeholder: '粘贴知识库内容或资料摘要', text: this.knowledge }).onChange((value: string): void => { this.knowledge = value; }).width('100%');
          Button('保存知识库').onClick((): void => this.save('capability_knowledge_context', this.knowledge)).width('100%').height(42).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16);
      }
      ListItem() { Divider().margin({ left: 16, right: 16 }); }.height(1);
      ListItem() {
        Column({ space: 8 }) {
          Text('知识库来源').fontSize(17).fontWeight(FontWeight.Medium).width('100%');
          Text('笔记与文本文件仅保存于本机；每次对话只按当前问题选取相关片段。').fontSize(13).fontColor(THEME_TOKENS.secondaryText).width('100%');
          TextInput({ placeholder: '笔记名称', text: this.knowledgeNoteTitle }).onChange((value: string): void => { this.knowledgeNoteTitle = value; }).width('100%');
          TextArea({ placeholder: '输入需要长期参考的笔记内容', text: this.knowledgeNoteContent }).onChange((value: string): void => { this.knowledgeNoteContent = value; }).width('100%').height(100);
          Row({ space: 10 }) {
            Button('添加笔记').onClick((): void => this.addKnowledgeNote()).layoutWeight(1).height(42).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
            Button('导入文本文件').onClick((): void => { void this.importKnowledgeFile(); }).height(42).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
          }.width('100%');
          if (this.knowledgeSources.length > 0) {
            Column({ space: 1 }) {
              ForEach(this.knowledgeSources, (source: KnowledgeSource): void => {
                Row({ space: 10 }) {
                  Column({ space: 2 }) {
                    Text(source.title).fontSize(15).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%');
                    Text(`${source.sourceType} · ${source.content.length} 字符`).fontSize(12).fontColor(THEME_TOKENS.secondaryText).width('100%');
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1);
                  Button('移除').fontSize(13).onClick((): void => this.removeKnowledgeSource(source.id)).height(34).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 });
                }.width('100%').padding({ top: 8, bottom: 8 });
              }, (source: KnowledgeSource): string => source.id);
            }.width('100%').padding({ top: 4 });
          }
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16);
      }
    }.width('100%').backgroundColor(THEME_TOKENS.surface).borderRadius(THEME_TOKENS.cardRadius).scrollBar(BarState.Off);
  }

  @Builder
  private extensionList(): void {
    Column({ space: 18 }) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Column({ space: 3 }) { Text('MCP 工具服务').fontSize(17).fontWeight(FontWeight.Medium); Text('保存远程 Streamable HTTP 或 SSE 配置；工具发现与执行将在后续版本接入。').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Toggle({ type: ToggleType.Switch, isOn: this.mcpEnabled }).onChange((enabled: boolean): void => { this.mcpEnabled = enabled; this.saveEnabledSilently('capability_mcp_enabled', enabled); this.showMcpSettings = enabled; });
          Button({ type: ButtonType.Circle }) { Image($r('app.media.my_settings')).width(18).height(18).fillColor(this.appearanceAccentColor).opacity(this.mcpEnabled ? 1 : 0.32); }
            .width(36).height(36).backgroundColor(Color.Transparent).onClick((): void => { this.showMcpSettings = true; }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 })
            .bindSheet($$this.showMcpSettings, this.mcpSettingsSheet(), { detents: [SheetSize.FIT_CONTENT], preferType: SheetType.BOTTOM, showClose: true, dragBar: true, onWillDismiss: (): void => { this.showMcpSettings = false; } });
        }.width('100%');
      }.alignItems(HorizontalAlign.Start).width('100%').padding(16).backgroundColor(Color.Transparent).borderRadius(THEME_TOKENS.cardRadius).systemMaterial(this.immersiveMaterial());
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Column({ space: 3 }) { Text('联网搜索').fontSize(17).fontWeight(FontWeight.Medium); Text('可选择服务商原生、本地或 API 搜索服务。').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Toggle({ type: ToggleType.Switch, isOn: this.webSearchEnabled }).onChange((enabled: boolean): void => { this.webSearchEnabled = enabled; this.saveEnabledSilently('capability_web_search_enabled', enabled); this.showSearchSettings = enabled; });
          Button({ type: ButtonType.Circle }) { Image($r('app.media.my_settings')).width(18).height(18).fillColor(this.appearanceAccentColor).opacity(this.webSearchEnabled ? 1 : 0.32); }
            .width(36).height(36).backgroundColor(Color.Transparent).onClick((): void => { this.showSearchSettings = true; }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 })
            .bindSheet($$this.showSearchSettings, this.searchSettingsSheet(), { detents: [SheetSize.FIT_CONTENT], preferType: SheetType.BOTTOM, showClose: true, dragBar: true, onWillDismiss: (): void => { this.showSearchSettings = false; } });
        }.width('100%');
      }.alignItems(HorizontalAlign.Start).width('100%').padding(16).backgroundColor(Color.Transparent).borderRadius(THEME_TOKENS.cardRadius).systemMaterial(this.immersiveMaterial());
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Column({ space: 3 }) { Text('图像生成').fontSize(17).fontWeight(FontWeight.Medium); Text('保存兼容 OpenAI Images API 的服务配置；生成、保存与预览将在后续版本接入。').fontSize(13).fontColor(THEME_TOKENS.secondaryText); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Toggle({ type: ToggleType.Switch, isOn: this.imageEnabled }).onChange((enabled: boolean): void => { this.imageEnabled = enabled; this.saveEnabledSilently('capability_image_enabled', enabled); this.showImageSettings = enabled; });
          Button({ type: ButtonType.Circle }) { Image($r('app.media.my_settings')).width(18).height(18).fillColor(this.appearanceAccentColor).opacity(this.imageEnabled ? 1 : 0.32); }
            .width(36).height(36).backgroundColor(Color.Transparent).onClick((): void => { this.showImageSettings = true; }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.9 })
            .bindSheet($$this.showImageSettings, this.imageSettingsSheet(), { detents: [SheetSize.FIT_CONTENT], preferType: SheetType.BOTTOM, showClose: true, dragBar: true, onWillDismiss: (): void => { this.showImageSettings = false; } });
        }.width('100%');
      }.alignItems(HorizontalAlign.Start).width('100%').padding(16).backgroundColor(Color.Transparent).borderRadius(THEME_TOKENS.cardRadius).systemMaterial(this.immersiveMaterial());
    }.width('100%');
  }

  @Builder
  private mcpSettingsSheet(): void {
    Column({ space: 14 }) {
      Text('MCP 工具服务').fontSize(20).fontWeight(FontWeight.Bold).width('100%');
      Text('配置远程 Streamable HTTP 或 SSE 服务。').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
      Select(MCP_TRANSPORT_OPTIONS.map((value: string): SelectOption => ({ value: value }))).selected(this.mcpTransportIndex).value(MCP_TRANSPORT_OPTIONS[this.mcpTransportIndex]).onSelect((index: number): void => { this.mcpTransportIndex = index; this.save('capability_mcp_transport', `${index}`); }).width('100%');
      TextInput({ placeholder: 'https://example.com/mcp', text: this.mcpEndpoint }).onChange((value: string): void => { this.mcpEndpoint = value; }).width('100%');
      TextInput({ placeholder: '超时秒数', text: this.mcpTimeout }).type(InputType.Number).onChange((value: string): void => { this.mcpTimeout = value; }).width('100%');
      Button('保存 MCP 配置').onClick((): void => { this.save('capability_mcp_endpoint', this.mcpEndpoint); this.save('capability_mcp_timeout', this.mcpTimeout); this.showMcpSettings = false; }).width('100%').height(44).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
    }.alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 28, bottom: 24 }).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial());
  }

  @Builder
  private searchSettingsSheet(): void {
    Scroll() {
      Column({ space: 14 }) {
        Text('联网搜索').fontSize(20).fontWeight(FontWeight.Bold).width('100%');
        Text('选择服务商原生、本地或 API 搜索服务。').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
        Select(SEARCH_PROVIDER_OPTIONS.map((value: string): SelectOption => ({ value: value }))).selected(this.webSearchProviderIndex).value(SEARCH_PROVIDER_OPTIONS[this.webSearchProviderIndex]).onSelect((index: number): void => { this.webSearchProviderIndex = index; }).width('100%');
        if (this.webSearchProviderIndex > 0) TextInput({ placeholder: this.webSearchProviderIndex === 1 ? '本地 SearXNG 地址' : 'API 服务地址（可留空）', text: this.webSearchEndpoint }).onChange((value: string): void => { this.webSearchEndpoint = value; }).width('100%');
        if (this.webSearchProviderIndex > 1) TextInput({ placeholder: 'API Key', text: this.webSearchApiKey }).type(InputType.Password).onChange((value: string): void => { this.webSearchApiKey = value; }).width('100%');
        Row({ space: 10 }) {
          Button('保存搜索配置').onClick((): void => { void this.saveSearchSettings(); this.showSearchSettings = false; }).layoutWeight(1).height(44).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
          Button(this.testingSearch ? '正在测试' : '测试搜索').onClick((): void => { if (!this.testingSearch) void this.testSearchSettings(); }).enabled(!this.testingSearch).height(44).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
        }.width('100%');
      }.alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 28, bottom: 24 }).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial());
    }.width('100%').height(430).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
  }

  @Builder
  private imageSettingsSheet(): void {
    Column({ space: 14 }) {
      Text('图像生成').fontSize(20).fontWeight(FontWeight.Bold).width('100%');
      Text('配置兼容 OpenAI Images API 的文生图服务。').fontSize(14).fontColor(THEME_TOKENS.secondaryText).width('100%');
      TextInput({ placeholder: '服务地址', text: this.imageEndpoint }).onChange((value: string): void => { this.imageEndpoint = value; }).width('100%');
      TextInput({ placeholder: '图像模型名称', text: this.imageModel }).onChange((value: string): void => { this.imageModel = value; }).width('100%');
      Select(IMAGE_SIZE_OPTIONS.map((value: string): SelectOption => ({ value: value }))).selected(this.imageSizeIndex).value(IMAGE_SIZE_OPTIONS[this.imageSizeIndex]).onSelect((index: number): void => { this.imageSizeIndex = index; }).width('100%');
      Button('保存图像生成配置').onClick((): void => { this.save('capability_image_endpoint', this.imageEndpoint); this.save('capability_image_model', this.imageModel); this.save('capability_image_size', `${this.imageSizeIndex}`); this.showImageSettings = false; }).width('100%').height(44).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.92 });
    }.alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 28, bottom: 24 }).backgroundColor(Color.Transparent).systemMaterial(this.immersiveMaterial());
  }

  @Builder
  private promptMemoryContent(): void {
    Column({ space: 12 }) {
      this.sectionTitle('提示词与记忆', '默认提示词和全局记忆会在下一条消息中生效。');
      this.systemList();
      Text(this.savedMessage).fontSize(13).fontColor(this.appearanceAccentColor).width('100%').height(49).padding({ top: 4, bottom: 32 }).opacity(this.savedMessage.length > 0 ? 1 : 0);
    }.width('100%').translate({ y: PROMPT_MEMORY_CONTENT_OFFSET });
  }

  @Builder
  private skillsContent(): void {
    Column({ space: 12 }) {
      this.sectionTitle('技能', '为当前对话附加一组可复用的工作指令。');
      this.skillList();
      if (this.savedMessage.length > 0) Text(this.savedMessage).fontSize(13).fontColor(this.appearanceAccentColor).width('100%').padding({ top: 4, bottom: 32 });
    }.width('100%').translate({ y: SKILLS_CONTENT_OFFSET });
  }

  @Builder
  private knowledgeContent(): void {
    Column({ space: 12 }) {
      this.sectionTitle('知识库', '本地资料摘要会按需注入对话上下文。');
      this.knowledgeList();
      if (this.savedMessage.length > 0) Text(this.savedMessage).fontSize(13).fontColor(this.appearanceAccentColor).width('100%').padding({ top: 4, bottom: 32 });
    }.width('100%').translate({ y: KNOWLEDGE_CONTENT_OFFSET });
  }

  @Builder
  private toolsContent(): void {
    Column({ space: 12 }) {
      this.sectionTitle('工具与扩展', '联网搜索由聊天页按服务商能力启用。');
      this.extensionList();
    }.width('100%').translate({ y: TOOLS_CONTENT_OFFSET });
  }

  build() {
    Scroll(this.contentScroller) {
      Column() {
        if (this.page === 'prompt') this.promptMemoryContent();
        else if (this.page === 'skills') this.skillsContent();
        else if (this.page === 'knowledge') this.knowledgeContent();
        else this.toolsContent();
      }
      .width('100%')
      .padding({ left: this.pagePadding, right: this.pagePadding, top: THEME_TOKENS.subpageContentTop, bottom: 132 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start);
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
  }
}
