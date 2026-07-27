import { common } from '@kit.AbilityKit';
import { DatabaseManager } from '../data/DatabaseManager';
import { ProviderRepository } from '../data/ProviderRepository';
import { ChatRepository } from '../data/ChatRepository';
import { AssetCredentialStore } from '../data/AssetCredentialStore';
import { ProviderViewModel } from '../viewmodel/ProviderViewModel';
import { HistoryViewModel } from '../viewmodel/HistoryViewModel';
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { StreamingChatService } from '../service/StreamingChatService';
import { AppShellViewModel } from '../viewmodel/AppShellViewModel';
import { preferences } from '@kit.ArkData';
import { MaterialLevel } from '../model/ShellModels';
import { FirstLaunchDetector } from './FirstLaunchDetector';
import { KnowledgeSource } from '../model/CapabilityModels';

export class AppStore {
  static readonly shellViewModel: AppShellViewModel = new AppShellViewModel();
  static readonly database: DatabaseManager = new DatabaseManager();
  static readonly credentials: AssetCredentialStore = new AssetCredentialStore();
  static readonly providerViewModel: ProviderViewModel = new ProviderViewModel(new ProviderRepository(AppStore.database), AppStore.credentials);
  static readonly historyViewModel: HistoryViewModel = new HistoryViewModel(new ChatRepository(AppStore.database));
  static readonly chatViewModel: ChatViewModel = new ChatViewModel(new ChatRepository(AppStore.database), new StreamingChatService(), AppStore.credentials);
  static initialized: boolean = false;
  static initializing: boolean = false;
  private static materialPreferences: preferences.Preferences | undefined = undefined;
  static initializeMaterialPreferences(context: common.UIAbilityContext): void {
    if (AppStore.materialPreferences === undefined) AppStore.materialPreferences = preferences.getPreferencesSync(context, { name: 'immersive_material' });
  }
  static readMaterialLevel(): MaterialLevel {
    if (AppStore.materialPreferences === undefined) return MaterialLevel.Gentle;
    const value: string = AppStore.materialPreferences.getSync('level', MaterialLevel.Gentle) as string;
    if (value === MaterialLevel.Off || value === MaterialLevel.Exquisite || value === MaterialLevel.Smooth || value === MaterialLevel.Adaptive) return value as MaterialLevel;
    return MaterialLevel.Gentle;
  }
  static saveMaterialLevel(level: MaterialLevel): void { AppStore.materialPreferences?.putSync('level', level); AppStore.materialPreferences?.flushSync(); }
  static readAppearance(key: string, fallback: string): string {
    if (AppStore.materialPreferences === undefined) return fallback;
    return AppStore.materialPreferences.getSync(key, fallback) as string;
  }
  static saveAppearance(key: string, value: string): void {
    AppStore.materialPreferences?.putSync(key, value);
    AppStore.materialPreferences?.flushSync();
  }
  static composeCapabilityPrompt(userQuery: string = ''): string {
    const sections: string[] = [];
    const defaultPrompt: string = AppStore.readAppearance('capability_system_prompt', '').trim();
    const memory: string = AppStore.readAppearance('capability_global_memory', '').trim();
    const skill: string = AppStore.readAppearance('capability_active_skill_prompt', '').trim();
    const knowledge: string = AppStore.readAppearance('capability_knowledge_context', '').trim();
    const knowledgeLimit: number = Number(AppStore.readAppearance('capability_knowledge_limit', '8000'));
    if (AppStore.readAppearance('capability_system_prompt_enabled', 'true') === 'true' && defaultPrompt.length > 0) sections.push(defaultPrompt);
    if (AppStore.readAppearance('capability_skill_enabled', 'true') === 'true' && skill.length > 0) sections.push(`当前技能要求：\n${skill}`);
    if (AppStore.readAppearance('capability_memory_enabled', 'true') === 'true' && memory.length > 0) sections.push(`用户的长期记忆：\n${memory}`);
    if (AppStore.readAppearance('capability_knowledge_enabled', 'true') === 'true' && knowledge.length > 0) {
      const safeLimit: number = Number.isFinite(knowledgeLimit) && knowledgeLimit >= 1000 ? Math.min(Math.floor(knowledgeLimit), 20000) : 8000;
      const sourceContext: string = AppStore.knowledgeContextFor(userQuery, safeLimit);
      const combined: string = sourceContext.length > 0 ? `${knowledge}\n\n${sourceContext}` : knowledge;
      sections.push(`本次对话可参考的知识库内容：\n${combined.slice(0, safeLimit)}`);
    } else if (AppStore.readAppearance('capability_knowledge_enabled', 'true') === 'true') {
      const safeLimit: number = Number.isFinite(knowledgeLimit) && knowledgeLimit >= 1000 ? Math.min(Math.floor(knowledgeLimit), 20000) : 8000;
      const sourceContext: string = AppStore.knowledgeContextFor(userQuery, safeLimit);
      if (sourceContext.length > 0) sections.push(`本次对话可参考的知识库内容：\n${sourceContext}`);
    }
    return sections.join('\n\n');
  }
  static knowledgeSources(): KnowledgeSource[] {
    const serialized: string = AppStore.readAppearance('capability_knowledge_sources', '[]');
    try {
      const items: Object[] = JSON.parse(serialized) as Object[];
      const sources: KnowledgeSource[] = [];
      items.forEach((entry: Object): void => {
        const value: Record<string, Object> = entry as Record<string, Object>;
        const id: string = String(value['id'] ?? '');
        const title: string = String(value['title'] ?? '');
        const content: string = String(value['content'] ?? '');
        if (id.length === 0 || title.length === 0 || content.length === 0) return;
        sources.push({ id, title: title.slice(0, 80), sourceType: String(value['sourceType'] ?? '笔记'), content: content.slice(0, 120000), updatedAt: Number(value['updatedAt'] ?? 0) });
      });
      return sources.slice(0, 12);
    } catch (_) {
      return [];
    }
  }
  static saveKnowledgeSources(sources: KnowledgeSource[]): void {
    AppStore.saveAppearance('capability_knowledge_sources', JSON.stringify(sources.slice(0, 12)));
  }
  private static knowledgeContextFor(query: string, characterLimit: number): string {
    const terms: string[] = AppStore.knowledgeTerms(query);
    const ranked: KnowledgeSource[] = AppStore.knowledgeSources().slice().sort((left: KnowledgeSource, right: KnowledgeSource): number => {
      return AppStore.knowledgeScore(right.content, terms) - AppStore.knowledgeScore(left.content, terms);
    });
    let remaining: number = characterLimit;
    const selected: string[] = [];
    ranked.forEach((source: KnowledgeSource): void => {
      if (remaining < 300) return;
      const excerpt: string = AppStore.knowledgeExcerpt(source.content, terms, Math.min(2200, remaining));
      if (excerpt.length === 0) return;
      const entry: string = `来源：${source.title}\n${excerpt}`;
      selected.push(entry.slice(0, remaining));
      remaining -= entry.length;
    });
    return selected.join('\n\n');
  }
  private static knowledgeTerms(query: string): string[] {
    const terms: string[] = query.toLowerCase().match(/[a-z0-9]{2,}|[\u4e00-\u9fa5]/g) ?? [];
    const unique: string[] = [];
    terms.forEach((term: string): void => { if (unique.indexOf(term) < 0) unique.push(term); });
    return unique.slice(0, 24);
  }
  private static knowledgeScore(content: string, terms: string[]): number {
    if (terms.length === 0) return 1;
    const lower: string = content.toLowerCase();
    let score: number = 0;
    terms.forEach((term: string): void => { if (lower.indexOf(term) >= 0) score += 1; });
    return score;
  }
  private static knowledgeExcerpt(content: string, terms: string[], limit: number): string {
    const compact: string = content.replace(/\r\n/g, '\n').trim();
    if (compact.length === 0) return '';
    if (terms.length === 0) return compact.slice(0, limit);
    const lower: string = compact.toLowerCase();
    let position: number = -1;
    for (let index: number = 0; index < terms.length; index += 1) {
      position = lower.indexOf(terms[index]);
      if (position >= 0) break;
    }
    if (position < 0) return compact.slice(0, Math.min(600, limit));
    const start: number = Math.max(0, position - Math.floor(limit / 4));
    const end: number = Math.min(compact.length, start + limit);
    return `${start > 0 ? '…' : ''}${compact.slice(start, end)}${end < compact.length ? '…' : ''}`;
  }
  static readOnboardingStage(): string {
    return AppStore.readAppearance('onboarding_flow_stage', '');
  }
  static saveOnboardingStage(stage: string): void {
    AppStore.saveAppearance('onboarding_flow_stage', stage);
    AppStorage.setOrCreate('onboarding_flow_stage', stage);
    AppStorage.set('onboarding_flow_stage', stage);
  }
  static readOnboardingProviderId(): string {
    return AppStore.readAppearance('onboarding_provider_id', '');
  }
  static saveOnboardingProviderId(providerId: string): void {
    AppStore.saveAppearance('onboarding_provider_id', providerId);
    AppStorage.setOrCreate('onboarding_provider_id', providerId);
    AppStorage.set('onboarding_provider_id', providerId);
  }
  static readOnboardingIntroStep(): number {
    const stored: number = Number(AppStore.readAppearance('onboarding_intro_step', '0'));
    return stored === 1 || stored === 2 ? stored : 0;
  }
  static saveOnboardingIntroStep(step: number): void {
    const value: number = step === 1 || step === 2 ? step : 0;
    AppStore.saveAppearance('onboarding_intro_step', `${value}`);
  }
  static async publishStartupNotice(): Promise<void> {
    const info = await FirstLaunchDetector.detect();
    const installIdentity: string = `${info.firstInstallTime}`;
    const versionIdentity: string = `${info.versionCode}`;
    const previousInstall: string = AppStore.readAppearance('startup_install_identity', '');
    const previousVersion: string = AppStore.readAppearance('startup_version_identity', '');
    const completedOnboardingInstall: string = AppStore.readAppearance('onboarding_completed_install_identity', '');
    const onboardingStage: string = AppStore.readOnboardingStage();
    const isFirstInstall: boolean = previousInstall.length === 0 || (installIdentity !== '0' && previousInstall !== installIdentity);
    const isFirstRunOfVersion: boolean = previousVersion !== versionIdentity;
    const shouldShowOnboarding: boolean = completedOnboardingInstall !== installIdentity;
    const hasResumableOnboarding: boolean = onboardingStage === 'provider_setup' || onboardingStage === 'provider_test' || onboardingStage === 'chat';
    AppStore.saveAppearance('startup_install_identity', installIdentity);
    AppStore.saveAppearance('startup_version_identity', versionIdentity);
    if (isFirstInstall) AppStore.saveOnboardingIntroStep(0);
    AppStorage.setOrCreate('onboarding_flow_stage', onboardingStage);
    AppStorage.set('onboarding_flow_stage', onboardingStage);
    AppStorage.setOrCreate('onboarding_provider_id', AppStore.readOnboardingProviderId());
    AppStorage.set('onboarding_provider_id', AppStore.readOnboardingProviderId());
    if (!isFirstInstall && !isFirstRunOfVersion && (!shouldShowOnboarding || hasResumableOnboarding)) return;
    AppStorage.setOrCreate('startup_is_first_install', isFirstInstall);
    AppStorage.set('startup_is_first_install', isFirstInstall);
    AppStorage.setOrCreate('startup_version_name', info.versionName);
    AppStorage.set('startup_version_name', info.versionName);
    AppStorage.setOrCreate('startup_should_show_onboarding', shouldShowOnboarding);
    AppStorage.set('startup_should_show_onboarding', shouldShowOnboarding);
    const revision: number = Date.now();
    AppStorage.setOrCreate('startup_notice_revision', revision);
    AppStorage.set('startup_notice_revision', revision);
  }
  static completeOnboarding(): void {
    const installIdentity: string = AppStore.readAppearance('startup_install_identity', '');
    if (installIdentity.length > 0) AppStore.saveAppearance('onboarding_completed_install_identity', installIdentity);
    AppStorage.setOrCreate('startup_should_show_onboarding', false);
    AppStorage.set('startup_should_show_onboarding', false);
    AppStore.saveOnboardingStage('completed');
    AppStore.saveOnboardingIntroStep(0);
  }
  static async initialize(context: common.UIAbilityContext): Promise<void> {
    if (AppStore.initialized || AppStore.initializing) return;
    AppStore.initializing = true;
    AppStore.initializeMaterialPreferences(context);
    await AppStore.database.open(context);
    await AppStore.providerViewModel.load();
    await AppStore.historyViewModel.load();
    AppStore.shellViewModel.initialize(AppStore.providerViewModel.records, AppStore.readMaterialLevel());
    AppStore.initialized = true;
    AppStore.initializing = false;
  }
  static refreshShell(): void { const revision: number = Date.now(); AppStore.shellViewModel.syncProviders(AppStore.providerViewModel.records); AppStore.shellViewModel.notifyRefresh(); AppStorage.setOrCreate('provider_revision', revision); AppStorage.set('provider_revision', revision); }
  static async refreshAll(): Promise<void> { await AppStore.providerViewModel.load(); await AppStore.historyViewModel.load(); AppStore.refreshShell(); }
}
