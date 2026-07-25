# Implementation Plan: ImmersiveAI 底部沉浸布局、“我的”入口与核心流程修复

**Input**: `C:\Users\LomoCat\DevEcoStudioProjects\ImmersiveAI\spec\rebuild-immersive-ai\spec.md`

## Summary

沿用现有 MVVM 架构，优先修复根窗口和 HDS Tabs 的尺寸/安全区边界：根页面铺满窗口，安全区背景与页面/HDS 连续，内容底部 inset 与导航视觉位置分离，避免重复 bottom padding 造成白框和内容整体上移。保留“聊天 / 历史 / 供应商”，新增“我的”页签，在“我的”页面提供独立的页内“沉浸光感材质”设置页。

材质设置继续使用已验证的系统 HDS 材质能力和四档官方等级，统一由 AppShellViewModel/AppStore 管理；业务修复继续覆盖 Provider、Chat、History，并参考 ClashBox 的全屏根布局和 More/Appearance 设置入口组织方式，不复制其业务实现。

## Technical Context

**Language/Version**: ArkTS 严格模式，当前 DevEco/SDK  
**Primary Dependencies**: ArkUI、`@kit.UIDesignKit` HDS、现有 Repository/Service 和凭据存储  
**Storage**: 现有应用存储及材质偏好持久化；不改数据库 schema  
**Testing**: `arkts_check`、`build_project`、签名 HAP 部署、HUAWEI Mate 70 Pro UI 验证  
**Target Platform**: API 24；目标设备 HUAWEI Mate 70 Pro  
**Project Type**: HarmonyOS 手机应用  
**Performance Goals**: 页面切换无明显跳动；材质选择 1 秒内刷新；核心操作 1 秒内出现反馈  
**Constraints**: 不重复应用系统安全区 inset；不以普通白色背景、渐变、透明、阴影、普通模糊或自制动画代替 HDS；不暴露 Key；保留现有业务边界；材质设置不使用底部半模态面板  
**Scale/Scope**: 四个底部页签、一个“我的”页内设置页、四档材质、三页业务流程及根布局修复  

## Project Structure

### Documentation (this feature)

```text
C:\Users\LomoCat\DevEcoStudioProjects\ImmersiveAI\spec\rebuild-immersive-ai\
├── spec.md
└── plan.md
```

### Source Code (repository root)

```text
C:\Users\LomoCat\DevEcoStudioProjects\ImmersiveAI\entry\src\main\ets\
├── pages\
│   └── Index.ets                         # 窗口根布局和系统安全区边界
├── views\
│   ├── MainShellView.ets                  # HDS 根壳、四页签和材质应用
│   ├── MyView.ets                         # “我的”页面及页内设置路由
│   ├── MaterialSettingsView.ets           # “我的”页内材质设置页
│   ├── ChatView.ets
│   ├── HistoryView.ets
│   └── ProviderSettingsView.ets
├── components\
│   ├── MainNavigation.ets                 # 四个导航项及选中态
│   ├── MySettingsEntry.ets                # “沉浸光感材质”入口行
│   ├── MaterialSettings.ets               # 四档材质选项
│   ├── ProviderEditor.ets
│   ├── ProviderCard.ets
│   ├── ConnectionTestResult.ets
│   ├── HistoryItem.ets
│   └── ChatMessageCard.ets
├── viewmodel\
│   ├── AppShellViewModel.ets              # ShellTab、材质、跨页导航状态
│   ├── ProviderViewModel.ets
│   ├── ChatViewModel.ets
│   └── HistoryViewModel.ets
├── model\
│   └── ShellModels.ets                    # 新增 My ShellTab 及相关状态模型
├── common\
│   ├── ThemeTokens.ets                    # 安全区/内容 inset/背景边界
│   ├── CapabilityDetector.ets
│   └── AppStore.ets
└── data\
    ├── ChatRepository.ets
    └── AssetCredentialStore.ets
```

资源继续放置于：

```text
C:\Users\LomoCat\DevEcoStudioProjects\ImmersiveAI\entry\src\main\resources\
├── base\element\string.json
└── dark\element\string.json
```

**Structure Decision**：这是已有 HarmonyOS/ArkTS MVVM 工程，继续遵循现有目录和职责边界，不进行架构迁移。新增 `MyView` 和 `MaterialSettingsView` 是因为用户明确要求“我的”入口及页内设置；不将材质设置继续塞入 Provider 页面，不使用底部半模态面板，也不把安全区计算散落到各业务页面。页面负责装配，ViewModel 负责状态和事件，组件负责可复用入口和选项展示，AppStore/现有持久化边界负责偏好保存。

## Complexity Tracking

本计划无架构迁移或数据库变更。新增“我的”页签、入口组件和页内设置装配层是用户明确要求；移除重复底部占用属于根布局修复，不新增复杂布局层。

| Decision | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| 新增 MyView 与页内 MaterialSettingsView | 入口必须位于“我的”，设置需要明确进入和返回 | 继续复用 ProviderSettingsView 会违反入口需求并混淆业务职责；底部半模态有额外高度压缩风险 |
| 分离导航视觉位置与内容底部 inset | 解决底部白框和内容挤压的根因 | 继续增加 bottom padding 会造成重复安全区占用 |

## Research & Decisions

### Decision 1: 根窗口只负责铺满和安全区背景连续

- **Decision**: `Index` 和主壳保持完整窗口尺寸；不使用根级固定 bottom padding 作为导航避让手段；系统安全区背景必须与页面背景/HDS 视觉连续。
- **Rationale**: 当前 `Index` 的根级底部 padding 与 HDS Tabs 自带底部安全区避让及内容 inset 叠加，符合白框和内容整体上移的现象；ClashBox 参考工程将根内容保持 `100%` 高度，并在 Tabs/内容层分别处理尺寸。
- **Alternatives considered**: 继续扩大 `bottomSafeInset` 或 `barBottomMargin`；拒绝，因为只会扩大空白并继续挤压内容。

### Decision 2: HDS 底部导航与内容 inset 分离

- **Decision**: HDS Tabs 负责底部导航和系统安全区；Chat、History、Provider Settings、My 的可滚动内容单独保留内容末端空间。不得在 `Index`、主壳和 Tabs 同时叠加同一安全区间距。
- **Rationale**: 官方 Tabs 从 API 11 起具备底部安全区避让能力；内容可见性需要独立末端空间，不能用导航位置 padding 代替。
- **Alternatives considered**: 用导航栏 bottom margin 代替内容 inset；拒绝，因为导航位置和内容遮挡是两个不同问题。

### Decision 3: “我的”作为第四个 ShellTab

- **Decision**: ShellTab 增加 My；MainShellView 增加对应 TabContent；MainNavigation 显示“聊天 / 历史 / 供应商 / 我的”。MyView 只提供入口和页内设置路由。
- **Rationale**: 用户明确要求材质设置位于导航栏“我的”中，同时保留供应商入口。
- **Alternatives considered**: 将供应商改名为我的；拒绝，因为会隐藏或破坏供应商核心流程。

### Decision 4: 设置入口采用页内设置页

- **Decision**: MyView 使用类似 ClashBox More/Appearance 的设置列表行；点击“沉浸光感材质”后，在“我的”页内切换到 MaterialSettingsView，提供明确返回入口；不使用底部半模态面板。
- **Rationale**: 页内设置不会额外改变窗口底部 detent 或制造新的底部安全区叠加，最适合当前白框和内容挤压问题；列表入口也与参考工程一致。
- **Alternatives considered**: 底部半模态设置面板；拒绝，因为面板高度、键盘和系统安全区容易再次产生底部空白或压缩。直接展开卡片；拒绝，因为长文案和四档选项会使“我的”页面拥挤，返回状态也不清晰。

### Decision 5: HDS 仅使用真实系统材质能力

- **Decision**: 保留 `hdsMaterial.MaterialLevel` 四档、`getSystemMaterialTypes()` 能力检测、HDS 顶部/底部系统材质、滚动绑定和安全布局；不可用时显示真实中文原因。
- **Rationale**: 知识检索确认 API 24 HDS/Tabs 具备系统材质和底部安全区行为；普通视觉效果不能作为 HDS 成功。
- **Alternatives considered**: 自制白色/透明/渐变层填补底部；拒绝，因为会制造白框并违反系统材质要求。

### Decision 6: 参考工程仅作为布局参考

- **Decision**: 参考 `C:\Files\Codes\HarmonyApps\fork\ClashBox-master` 的全屏根容器、Tabs 内容与底部栏分离、More/Appearance 设置列表模式；不复制其业务逻辑、资源、第三方组件或状态模型。
- **Rationale**: 只复用已确认的交互组织经验，避免引入无关依赖和业务边界变化。
- **Alternatives considered**: 复制 ClashBox 的 Index 或设置实现；拒绝，因为两个应用的业务和依赖不同。

## Data Model

### ShellTab

- Values: Chat、History、Providers、My。
- Invariant: 四个页签拥有稳定顺序；跨页导航和 HDS `onChange` 使用同一选中状态。

### MyPageState

- `showMaterialSettings`: 是否显示“我的”页内材质设置页。
- `entrySummary`: 当前材质档位或真实不可用原因。
- `returnTarget`: 返回“我的”列表页。
- Invariant: 打开/返回设置不改变底部选中项，离开“我的”后再次进入恢复列表页状态。

### SafeAreaLayout

- `windowFilled`: 根页面是否占满窗口。
- `systemBottomSafeArea`: 系统底部避让区域状态。
- `navigationVisualInset`: HDS 底部导航的视觉位置约束。
- `contentBottomInset`: 业务滚动内容末端空间。
- Invariant: `contentBottomInset` 不改变 `navigationVisualInset`；不得重复计算同一系统安全区。

### MaterialPreference

- `selected`: 用户选择的四档之一。
- `effective`: 设备能力约束后的当前有效档位。
- `options`: 四个固定中文选项。
- `materialTypeAvailable`: HDS 系统材质能力。
- `status`: 可用、降级、不可用及真实中文原因。
- `persisted`: 是否完成恢复或保存。

### MySettingsEntry

- `title`: 固定为“沉浸光感材质”。
- `summary`: 当前档位或真实不可用原因。
- `enabled`: 是否可以进入设置。
- `target`: MyPageState.showMaterialSettings。

### NavigationState

- `selectedTab`: ShellTab 当前选中项。
- `lastNavigationIntent`: 来源、目标和请求标识。
- `refreshVersion`: 跨页状态刷新版本。

## Contracts & Interfaces

### Root Layout Contract

- `Index` 提供唯一的全屏根容器和页面背景。
- 根容器不得通过固定底部 padding 压缩 MainShellView。
- 系统底部安全区的视觉背景与页面/HDS 背景连续。
- 内容底部 inset 只在内容滚动区域或页面内容容器中生效。

### Navigation Contract

- MainNavigation 提供四个入口：聊天、历史、供应商、我的。
- 每个入口点击后产生统一 NavigationIntent；AppShellViewModel 更新 selectedTab。
- HDS 与 fallback 必须共享同一 ShellTab 顺序和选中状态。
- “我的”返回其他页签后不得丢失材质设置状态。

### My Settings Contract

- MyView 展示“沉浸光感材质”入口和当前摘要。
- 入口点击只切换“我的”页内的 `showMaterialSettings`，不创建底部半模态层。
- MaterialSettingsView 提供页内返回“我的”列表的操作。
- MaterialSettings emits a selected MaterialLevel；共享 ViewModel 执行能力校验、持久化和发布刷新。
- 设置页不得直接承担 Provider、Chat 或 History 的业务操作。

### HDS Material Contract

- 顶部和底部使用同一有效材质等级，但保持各自合法的 HDS 配置。
- 能力检测使用 SDK 可用的系统材质类型查询。
- 不可用或降级时显示真实中文状态，不报告为已验证的 HDS 视觉成功。
- 不新增伪造沉浸光感动画或白色占位背景。

### Existing Business Contracts

- Provider：显式取消编辑、目标供应商连接重试、Key 遮罩和中文操作反馈。
- Chat：配置引导、返回聊天、页签同步、发送/停止/重试/复制。
- History：新建、打开、重命名保存/取消、目标删除和持久化反馈。
- 以上业务不改变数据库 schema、协议适配、流式聊天、Asset Store Kit 或端点来源。

### Reference Boundary Contract

- 允许参考 `C:\Files\Codes\HarmonyApps\fork\ClashBox-master` 的布局组织和设置行模式。
- 禁止复制 ClashBox 的业务代码、资源、第三方模块或依赖配置。

### Implementation Order and Verification Contract

1. 审计当前 `Index`、`MainShellView`、`MainNavigation` 的重复底部占用和 HDS Tabs 尺寸边界。
2. 增加 My ShellTab、MyView、页内 MaterialSettingsView 和设置入口。
3. 重新定义唯一根安全区边界，拆分导航视觉位置与内容底部 inset，消除白框和内容挤压。
4. 将材质设置从 ProviderSettingsView 移出，接入 MyView 页内设置，并保持共享持久化和 HDS 即时刷新。
5. 继续修复 Provider、Chat、History 核心回调和反馈闭环。
6. 完成中文、Key 安全、资源、HDS 系统 API 和布局边界审计。
7. 运行 ArkTS 检查、构建、部署，并在目标设备上验证四页导航、底部布局、“我的”入口和材质设置。

Verification must include `arkts_check`, `build_project`, signed HAP installation/startup, and UI verification on HUAWEI Mate 70 Pro. UI verification must cover no bottom white block, no content compression, four navigation tabs, My entry path, four material choices, persistence, HDS top/bottom update, and Provider/Chat/History core flows. Any ordinary fallback or static white/transparent presentation is not HDS success.

## Changelog

- 2026-07-25: Reworked Summary, Technical Context, Project Structure, Research & Decisions, Data Model, Contracts, implementation order and verification contract. Added root-layout diagnosis, fourth “我的” tab, My settings entry, safe-area separation and ClashBox reference boundary to match the confirmed Phase 1 requirements.
- 2026-07-25: Architecture discussion resolved the settings container as a page-in-page flow within “我的”; removed bottom-sheet/modal design from the plan to avoid additional bottom height and safe-area compression.
