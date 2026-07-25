# 实施计划：沉浸光感多模型 AI 应用

**输入**：`C:\Users\LomoCat\DevEcoStudioProjects\ImmersiveAI\spec\build-immersive-ai\spec.md`  
**参考工程**：`C:\Files\Codes\HarmonyApps\Spatialization-master`  
**协议参考项目**：`C:\Files\Codes\HarmonyApps\fork\HiveChat-main`

## Summary

本计划为新建 HarmonyOS ArkTS 移动应用选择 MVVM 分层结构，提供供应商配置、本地安全凭据、流式文本对话、本地会话历史、Markdown 安全展示、主题适配和官方 UI Design Kit 沉浸光感导航体验。

模型协议采用三个独立适配边界：OpenAI 风格、Anthropic Claude 风格和 Google Gemini 风格。OpenAI、DeepSeek、GLM 及 OpenAI 兼容接口归入 OpenAI 风格；服务地址完全由用户填写。协议解析参考 HiveChat 的职责划分和流式增量处理行为，但实现使用 HarmonyOS 官方网络能力独立完成，不复制 HiveChat 源码。

沉浸光感仅使用参考项目中可验证的 `@kit.UIDesignKit` 官方能力，重点覆盖 HDS 导航和底部页签；运行时检测能力，不可用时明确降级。

## Technical Context

**Language/Version**：ArkTS，版本由 DevEco 工程模板和已安装 SDK 自动确定，不在计划中臆测。  
**Primary Dependencies**：HarmonyOS Stage 模型；`@kit.ArkUI`；`@kit.UIDesignKit`；`@kit.NetworkKit`；`@kit.AssetStoreKit`；`@kit.CoreFileKit`；`@kit.ArkData` 或对应 SDK 提供的 `relationalStore`；`@kit.BasicServicesKit`。  
**Storage**：Asset Store Kit 保存 Key；关系型数据库保存供应商非敏感元数据、会话和消息；不在普通偏好数据中保存 Key。  
**Testing**：ArkTS 静态检查、工程构建、设备或模拟器部署、协议夹具测试、用户故事验证。  
**Target Platform**：HarmonyOS 手机和平板；基线以参考工程验证的 HarmonyOS 6.1 / API 23 能力为准，具体 SDK 版本由创建工具检测。  
**Project Type**：HarmonyOS mobile application。  
**Performance Goals**：有效服务开始返回数据后，目标是在 1 秒内呈现首段流式文本；停止操作目标在 1 秒内反馈；长回答滚动期间保持可用。  
**Constraints**：不得硬编码或猜测端点和 Key；不得把 Key 写入普通日志、消息数据库或错误提示；不得伪造模型响应、模型能力或推理内容；所有官方 API 必须以当前 SDK 可验证能力为准。  
**Scale/Scope**：首版单设备本地应用、六类供应商入口、三种协议风格、文本对话、五个核心用户故事、手机和平板两类布局。

## Project Structure

### Documentation

```text
C:\Users\LomoCat\DevEcoStudioProjects\ImmersiveAI\spec\build-immersive-ai\
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code

```text
C:\Users\LomoCat\DevEcoStudioProjects\ImmersiveAI\
├── AppScope/
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets
│       │   ├── pages/
│       │   │   └── Index.ets
│       │   ├── views/
│       │   │   ├── MainShellView.ets
│       │   │   ├── ChatView.ets
│       │   │   ├── HistoryView.ets
│       │   │   └── ProviderSettingsView.ets
│       │   ├── components/
│       │   │   ├── ChatMessageCard.ets
│       │   │   ├── ChatComposer.ets
│       │   │   ├── ProviderCard.ets
│       │   │   ├── ProviderEditor.ets
│       │   │   ├── ImportPreview.ets
│       │   │   ├── ReasoningSection.ets
│       │   │   └── MarkdownBlockView.ets
│       │   ├── viewmodel/
│       │   │   ├── ChatViewModel.ets
│       │   │   ├── ProviderViewModel.ets
│       │   │   └── HistoryViewModel.ets
│       │   ├── model/
│       │   │   ├── ProviderModels.ets
│       │   │   ├── ChatModels.ets
│       │   │   └── ProtocolModels.ets
│       │   ├── service/
│       │   │   ├── ProviderRegistry.ets
│       │   │   ├── StreamingChatService.ets
│       │   │   ├── OpenAIStyleAdapter.ets
│       │   │   ├── ClaudeStyleAdapter.ets
│       │   │   ├── GeminiStyleAdapter.ets
│       │   │   ├── SseStreamParser.ets
│       │   │   ├── EndpointNormalizer.ets
│       │   │   ├── ImportService.ets
│       │   │   └── MarkdownParser.ets
│       │   ├── data/
│       │   │   ├── AssetCredentialStore.ets
│       │   │   ├── ChatRepository.ets
│       │   │   ├── ProviderRepository.ets
│       │   │   └── DatabaseManager.ets
│       │   └── common/
│       │       ├── AppConstants.ets
│       │       ├── ErrorCatalog.ets
│       │       ├── ThemeTokens.ets
│       │       └── CapabilityDetector.ets
│       ├── module.json5
│       └── resources/
│           ├── base/
│           │   ├── element/
│           │   │   ├── color.json
│           │   │   └── string.json
│           │   │   └── profile/
│           │       └── main_pages.json
│           └── dark/
│               └── element/
│                   ├── color.json
│                   └── string.json
└── build-profile.json5
```

**Structure Decision**：这是新建 HarmonyOS 项目，选择 MVVM 层级。多页面、跨页面状态、本地数据库、安全凭据、网络流式处理和三种协议适配均触发 MVVM 需求。目录数量用于划分职责，不要求每个数据概念单独成文件；实现阶段应优先保持上述最小文件集合。页面只负责组装视图和导航，网络、协议解析和持久化不得直接写入页面。

**责任边界与追踪**：`pages/` 只负责启动页、导航装配；`views/` 负责业务区域；`components/` 负责消息、配置、导入预览、推理折叠和 Markdown 块；`viewmodel/` 负责用户操作和跨视图状态；`model/` 只保存业务实体与协议无关事件；`service/` 负责 HTTP、协议适配、SSE、端点规范化、JSON 导入和 Markdown；`data/` 负责 Asset Store、关系型数据库和仓储；`common/` 负责常量、主题语义、能力检测；资源必须放在 `entry/src/main/resources/`。

FR-001 至 FR-009C 由 ProviderModels、ProviderRegistry、三种适配器、EndpointNormalizer、ProviderRepository 覆盖；FR-010 至 FR-012 由 StreamingChatService、SseStreamParser、ErrorCatalog、ChatViewModel 覆盖；FR-013 至 FR-014 由 DatabaseManager、ChatRepository、HistoryViewModel 覆盖；FR-015 由 MarkdownParser、MarkdownBlockView、ChatMessageCard 覆盖；FR-016 和 FR-019 由 ThemeTokens、base/dark 资源和响应式 MainShellView 覆盖；FR-017 至 FR-018 由 CapabilityDetector、MainShellView、HDS 导航和底部页签覆盖；FR-020 至 FR-023 由首次使用提示、AssetCredentialStore、日志约束、推理分区和独立实现边界覆盖。

实现约束：不得写入真实 Key、真实用户端点、伪造模型名或假响应；不得逐行复制 HiveChat；不得把普通模糊、渐变、阴影或透明层称为官方沉浸光感；不得使用当前 SDK 未验证的模块、装饰器、属性或参数；页面不得直接发 HTTP、解析 SSE、访问数据库或 Asset Store；资源不得放入 `ets/`；启动页配置和 EntryAbility 必须一致。

## Complexity Tracking

本计划没有违反既定结构约束。MVVM 的额外分层由以下已批准需求直接导致：多页面、持久化、敏感数据存储、网络流式生命周期、三种外部协议和跨页面状态。

| 设计复杂度 | 必要性 | 被拒绝的更简单方案 |
|---|---|---|
| 三个协议适配器 | 外部协议的消息格式、鉴权、流事件和 usage 不同 | 单一请求类会把供应商分支扩散到 UI 和持久化层 |
| 独立 SSE 分帧服务 | HarmonyOS 流式回调可能按任意边界返回数据 | 在各适配器内重复分帧会导致残缺事件处理不一致 |
| Asset Store 与数据库分离 | Key 与普通元数据需要不同安全级别 | 将 Key 放入数据库违反安全需求 |
| Markdown 解析服务 | 需要流式过程中的稳定降级和安全展示 | 直接把原始文本交给复杂 UI 会产生格式和安全风险 |

## Research & Decisions

### Decision 1：采用官方 UI Design Kit 沉浸光感

- **Decision**：使用参考工程中已出现的 `@kit.UIDesignKit` HDS 导航、底部页签和 `systemMaterialEffect` 能力；用官方能力检测判断是否启用。
- **Rationale**：用户明确要求不捏造沉浸光感；本地参考工程提供了可核验的官方调用方向。
- **Alternatives considered**：自定义渐变、模糊、阴影或自造材质 API；因不能称为官方沉浸光感而拒绝。

### Decision 2：协议分层参考 HiveChat，但独立实现

- **Decision**：保留统一聊天服务契约，下面挂 OpenAI 风格、Claude 风格和 Gemini 风格适配器；不直接移植 HiveChat 的 Next.js/TypeScript 源码。
- **Rationale**：HiveChat 的 `LLMApi`、供应商 `apiStyle`、消息映射和流解析提供了清晰的协议职责边界；独立实现可适配 ArkTS 官方网络 API，并遵守参考项目许可证约束。
- **Alternatives considered**：直接复制 Provider 文件；会引入运行时、语言、许可证和 ArkTS 兼容问题，拒绝。

### Decision 3：服务地址全部用户提供

- **Decision**：配置模型必须包含用户输入的服务地址；应用只做协议匹配、必填字段检查和不改变语义的路径规范化，并在保存前展示规范化结果。
- **Rationale**：用户明确要求不捏造任何内容；不同供应商和代理服务地址不能由应用猜测。
- **Alternatives considered**：内置默认端点或照搬 HiveChat 端点；无法保证当前官方有效性，拒绝。

### Decision 4：使用 Asset Store 保存 Key

- **Decision**：供应商元数据保存于关系型数据库，Key 以独立别名保存于 Asset Store；数据库只保存凭据别名和遮罩摘要。
- **Rationale**：官方 Asset Store Kit 用于短敏感数据，适合 Token/Key；可避免会话数据库和普通日志泄露 Key。
- **Alternatives considered**：Preferences、普通文件或数据库明文；安全性不满足 FR-006，拒绝。

### Decision 5：使用 requestInStream 处理流式响应

- **Decision**：网络服务使用 HarmonyOS Network Kit HTTP 流式请求；将字节流解码、SSE 分帧和协议事件解析拆成独立边界；停止时销毁当前请求对象。
- **Rationale**：官方知识结果确认 `requestInStream` 与 `dataReceive`、`dataEnd` 适合流式响应，并要求使用后销毁请求对象。
- **Alternatives considered**：等待完整响应后使用普通请求；无法满足流式显示和停止生成。

### Decision 6：三种协议的事件解析

- **Decision**：OpenAI 风格读取正文增量、推理增量、结束原因和多种 usage 位置；Claude 风格读取消息开始、内容块增量、消息结束和 usage；Gemini 风格读取候选内容分片、结束原因和 usage metadata。未知字段安全忽略，关键结构缺失标记为协议错误。
- **Rationale**：对应 HiveChat 中三个 Provider 的职责，同时尊重不同官方协议的实际结构。
- **Alternatives considered**：把所有响应强制转成一种 JSON 结构后交给 UI；会丢失供应商语义并掩盖协议错误。

### Decision 7：推理内容保守分离

- **Decision**：只处理服务实际返回的独立推理字段或可识别的 `<think>`/结束标签；使用增量缓冲跨越数据块边界；推理视图折叠显示，最终回答单独显示。
- **Rationale**：参考 HiveChat 对 reasoning 字段和标签的处理，但避免应用生成任何推理内容。
- **Alternatives considered**：默认显示“思考中”或推测推理文本；会制造虚假内容，拒绝。

### Decision 8：本地关系型数据模型

- **Decision**：使用关系型数据库保存 Provider、Conversation、Message 三类核心数据，并以会话 ID 和消息顺序查询；更新和删除在事务边界内完成。
- **Rationale**：会话与消息是结构化、具有关联关系的数据，适合关系型存储。
- **Alternatives considered**：单个 JSON 文件或 Preferences 数组；长文本、增量保存、排序和删除风险较高。

### Decision 9：系统文件选择器导入 JSON

- **Decision**：通过官方 DocumentViewPicker 让用户选择文件，读取临时授权 URI，解析并校验后展示遮罩预览；确认后只写入应用数据和 Asset Store，不保留原文件副本。
- **Rationale**：符合用户主动选择文件的权限边界，并满足不保留源文件副本的要求。
- **Alternatives considered**：直接扫描公共存储；权限和隐私边界不符合要求。

### Decision 10：Markdown 安全降级

- **Decision**：只支持标题、段落、列表、引用和代码块；解析结果为受控块模型；未知标记转为纯文本，不执行其中内容。
- **Rationale**：流式增量文本可能处于不完整状态，受控块模型便于稳定渲染和安全降级。
- **Alternatives considered**：未经限制地嵌入 Web HTML；引入内容执行和主题适配风险，拒绝。

### Decision 11：主题与响应式资源

- **Decision**：使用 base/dark 同名语义资源，组件使用资源引用；手机和平板通过官方窗口尺寸或断点能力调整导航、历史侧栏和内容宽度。
- **Rationale**：官方知识结果建议使用资源限定词适配深浅色，避免组件中散落主题分支。
- **Alternatives considered**：在每个组件中手动判断颜色模式；容易造成半适配和对比度缺陷。

## Data Model

### ProviderRecord

- `id`：本地唯一标识。
- `displayName`：用户可识别名称。
- `providerKind`：`openai`、`anthropic`、`gemini`、`deepseek`、`glm` 或 `openaiCompatible`。
- `protocolStyle`：`openaiStyle`、`claudeStyle` 或 `geminiStyle`。
- `endpoint`：用户输入并确认过的服务地址；不得使用隐含默认值。
- `modelName`：用户输入的模型标识。
- `credentialAlias`：Asset Store 中 Key 的别名，不保存 Key 明文。
- `maskedCredential`：用于 UI 摘要的遮罩文本。
- `enabled`：是否允许被选择。
- `validationState`：未验证、成功、失败或未知。
- `createdAt`、`updatedAt`：时间信息。

### ConversationRecord

- `id`：会话 ID。
- `title`：用户标题或由首条用户消息生成的标题。
- `providerId`、`modelName`：创建时选择的供应商和模型快照。
- `status`：空闲、生成中、已停止、完成或失败。
- `createdAt`、`updatedAt`：时间信息。

### MessageRecord

- `id`：消息 ID。
- `conversationId`：所属会话。
- `sequence`：严格递增的展示顺序。
- `role`：用户、助手或系统。
- `content`：最终回答或用户文本。
- `reasoningContent`：服务实际返回并解析出的推理内容，可为空。
- `status`：生成中、完成、已停止或失败。
- `errorCategory`、`errorSummary`：不含 Key 的错误摘要。
- `inputTokens`、`outputTokens`、`totalTokens`：可选 usage。
- `createdAt`、`updatedAt`：时间信息。

### Protocol-neutral streaming model

- `StreamDelta`：正文增量、推理增量、协议事件类型、结束原因、usage 更新和错误信息。
- `StreamingState`：准备、连接中、生成中、已停止、完成、失败。
- `ProtocolError`：响应结构未知、SSE 分帧无效、服务状态错误或鉴权失败。
- `ImportPreview`：解析后的供应商摘要、校验错误和遮罩 Key，不可直接持久化。

### State transitions

- Provider：未验证 → 验证中 → 可用 / 不可用；可用 → 停用 / 删除。
- Conversation：新建 → 空闲 → 生成中 → 完成 / 已停止 / 失败。
- Message：占位 → 增量更新 → 完成 / 已停止 / 失败。
- Import：选择文件 → 读取 → 解析 → 校验失败或预览 → 用户确认 → 持久化。

## Contracts & Interfaces

### Provider registry contract

- 输入：ProviderRecord 的非敏感配置和协议风格。
- 输出：对应的协议适配器以及能力声明。
- 约束：不存在注册项时返回明确配置错误，不根据名称猜测协议。

### Streaming chat contract

- 输入：会话消息列表、ProviderRecord 非敏感配置、从 Asset Store 取得的短时 Key、取消信号。
- 输出：有序的 StreamDelta 序列，以及最终 StreamingState。
- 约束：Key 只能存在请求头或请求构造的短生命周期内；不得进入日志、UI 错误、数据库消息或诊断摘要。
- 操作：开始、增量更新、停止、完成、失败；停止必须释放网络请求对象。

### OpenAI-style adapter contract

- 请求语义：用户消息列表、模型标识、流式标志和必要的用户明确配置参数。
- 鉴权：按照用户提供的 Key 和该服务协议要求构造，不在应用中硬编码未验证的供应商特例。
- 响应语义：识别 SSE data 事件、正文 delta、推理字段、finish reason、usage 和显式错误对象。
- 不支持：未知工具调用、多模态或未在规格中批准的扩展不得被猜测处理。

### Claude-style adapter contract

- 请求语义：Anthropic Messages 风格角色与内容块、模型标识、必要输出字段。
- 鉴权：根据用户确认的 Claude 风格服务协议构造 API Key 和版本类请求头；具体版本值不得脱离官方资料臆测。
- 响应语义：识别 message start、content block text delta、message delta/end、usage 和显式错误。

### Gemini-style adapter contract

- 请求语义：Gemini contents/parts 风格消息和模型标识。
- 鉴权：按照用户确认的 Gemini 风格服务配置构造；不得把 Key 明文放入普通日志或 UI。
- 响应语义：识别候选内容 parts、文本增量、finish reason、usage metadata 和显式错误。

### Endpoint normalization contract

- 输入：用户填写的地址、协议风格。
- 输出：规范化地址和可解释的变更摘要。
- 规则：只执行明确的斜杠、已存在协议路径和重复后缀校验；不替换域名，不注入默认域名，不猜测缺失地址。

### JSON import contract

- 输入：用户通过 DocumentViewPicker 选择的 JSON 文件。
- 允许字段：配置名称、供应商类型、协议风格、服务地址、模型名、Key 以及明确批准的非敏感元数据。
- 输出：ImportPreview。
- 校验：JSON 结构、类型、必填字段、服务地址格式、供应商与协议一致性、Key 非空和重复配置策略。
- 安全：完整 Key 只进入预览的受保护状态和 Asset Store 写入流程；确认后释放源文件内容，不保留源文件副本。

### Markdown block contract

- 输入：流式或完成的纯文本回答。
- 输出：受控 MarkdownBlock 列表。
- 支持：标题、段落、无序/有序列表、引用和代码块。
- 降级：不支持、残缺或疑似执行内容作为纯文本显示；不加载外部内容。

### UI contracts

- MainShellView：提供官方 HDS 导航和底部页签；页签切换不丢失当前会话状态。
- ChatView：展示消息、推理折叠区、生成状态和输入操作。
- ProviderSettingsView：提供配置编辑、导入预览、遮罩凭据和删除确认。
- HistoryView：提供空状态、会话选择、重命名和删除。
- CapabilityDetector：返回官方沉浸材质是否可用；UI 只能据此选择官方效果或明确降级样式。
