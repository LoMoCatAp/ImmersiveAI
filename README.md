<p align="center">
  <img src="AppScope/resources/base/media/foreground.png" width="128" alt="AIBox Logo">
</p>

# AIBox

<p align="center">
  <img src="https://img.shields.io/badge/HarmonyOS-API%2024-0D8BFF?logo=harmonyos&logoColor=white" alt="HarmonyOS API 24">
  <img src="https://img.shields.io/badge/ArkTS-5.0-0D8BFF" alt="ArkTS">
  <img src="https://img.shields.io/badge/ArkUI-Native-0D8BFF" alt="ArkUI">
  <img src="https://img.shields.io/badge/Protocol-OpenAI%20Compatible-412991" alt="OpenAI Compatible">
  <img src="https://img.shields.io/badge/Markdown-KaTeX-000000?logo=markdown&logoColor=white" alt="Markdown and KaTeX">
  <img src="https://img.shields.io/badge/platform-HarmonyOS-0D8BFF?logo=harmonyos&logoColor=white" alt="HarmonyOS">
</p>

AIBox 是一款面向 HarmonyOS 的本地 AI 聚合聊天应用，使用 ArkTS 与 ArkUI 构建。它允许用户在设备上配置多个 AI 服务商，直接与服务商 API 通信，并提供流式对话、历史会话、模型发现、文件导入、Markdown/LaTeX 渲染和沉浸式界面设置。

应用不会要求用户把 API Key 发送给开发者服务器。服务商凭据、会话记录与界面设置均保存在应用私有数据中；对话请求会直接发送至用户自行配置的服务地址。

## 致谢与授权

**维护边界**：本项目由 [LoMoCatAp](https://github.com/LoMoCatAp) 独立维护。功能适配、版本发布、问题反馈和 AI 服务商配置均由本仓库维护者负责。

**致谢**：感谢 HarmonyOS 官方提供 ArkUI、ArkData、Core File Kit、Ability Kit 等系统能力；数学公式渲染使用 KaTeX 资源。

## 使用

1. 前往 [Releases](https://github.com/LoMoCatAp/ImmersiveAI/releases) 下载最新 HAP。
2. 在 HarmonyOS 设备上安装应用。
3. 打开「供应商」，添加服务地址、模型名称和 API Key，并启用该供应商。
4. 点击「测试连接」确认服务可用。
5. 返回聊天页开始对话；点击「更多」可设置模型、系统提示词、上下文条数和助手名称，点击「保存」后会在下次启动时保留。

## 使用说明与免责声明

本项目仅供个人学习、交流和非商业用途。

本项目不是任何 AI 服务商的官方客户端，与 OpenAI、Anthropic、Google、DeepSeek、阿里云、智谱 AI、xAI 或其他服务商不存在隶属、授权、合作或担保关系。本项目不代表任何服务商的官方立场。

AI 服务的可用性、模型名称、计费、内容政策和接口兼容性由相应服务商决定。使用者应自行确认 API Key、服务地址与模型配置，并遵守目标服务商规则及适用法律法规。

用户应仅处理本人有权访问的数据，并自行承担使用、误用或无法使用本软件产生的风险和后果。

## 当前模块

- **聊天**：多会话对话、流式回复、思考内容展开、长按复制、模型切换与附件导入。
- **更多**：模型名称、系统提示词、上下文消息数、助手名称设置，以及可用模型刷新。
- **供应商**：新增、编辑、启用多个服务商，测试连接并按服务商协议查询模型。
- **历史**：创建、查看和切换本地会话历史。
- **设置**：主题色、深色模式、聊天字号、沉浸光感档位和关于信息。
- **内容渲染**：Markdown、表格、代码块、列表、链接与 KaTeX 数学公式。

## 支持的协议

AIBox 提供以下协议适配。实际可用模型取决于服务商账户、区域和服务端配置。

- OpenAI Compatible：OpenAI 及兼容 `/v1/chat/completions` 的服务。
- DeepSeek：DeepSeek Chat Completions 接口。
- Claude Style：Anthropic Messages 风格接口。
- Gemini Style：Google Gemini 风格接口。

## 源码运行

1. 安装 DevEco Studio，并通过 SDK Manager 安装项目需要的 HarmonyOS SDK（API 24）。
2. 克隆本仓库后，将 `build-profile.example.json5` 复制为本地 `build-profile.json5`，或在 DevEco Studio 的签名配置中生成本地配置。
3. 在 DevEco Studio 打开项目根目录，选择 `entry` 模块与已连接设备或模拟器，点击 Run。

项目依赖定义位于 `oh-package.json5` 和各模块的 `oh-package.json5`；本地签名配置 `build-profile.json5` 不提交到仓库。

## 构建

在 PowerShell 中运行：

```powershell
$env:DEVECO_SDK_HOME = 'D:\DevEco Studio\sdk'
node 'D:\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p product=default -p buildMode=debug assembleHap
```

构建产物位于 `entry/build/default/outputs/default/`。HAP、release、build 输出及本地签名材料均由 `.gitignore` 排除，不会提交到仓库。

## 本地数据位置

- 服务商配置和会话记录：应用私有沙箱数据库。
- API Key：HarmonyOS 本地资产存储服务。
- 外观和「更多」设置：HarmonyOS Preferences。
- 导入文件：仅在读取期间暂存于应用临时目录，发送成功后清除。

卸载应用或清除应用数据可能会删除上述本地数据。请妥善保管 API Key，并在重置设备前自行备份必要信息。

## 当前限制

- 需要设备能访问用户配置的服务商 API。
- 模型发现并非所有服务商均支持；不支持时可手动输入模型名称。
- 流式输出与思考内容依赖服务商是否按协议返回相应字段。
- 文件导入仅支持常见文本与代码格式，单次内容会受到应用的字符长度限制。
- Markdown 与 LaTeX 渲染以移动端显示稳定性为优先，复杂 HTML 或服务商自定义语法可能无法完整呈现。

## 项目结构

```text
AppScope/                           应用级配置与图标资源
entry/src/main/ets/
  views/                            聊天、历史、供应商和设置页面
  components/                       可复用 ArkUI 组件
  viewmodel/                        页面状态和交互逻辑
  service/                          协议适配、流式解析、模型发现和内容处理
  data/                             本地数据库与凭据存储
  model/                            领域模型和导航定义
entry/src/main/resources/           主题、字符串、原始渲染资源
```

## 开发验证

```powershell
$env:DEVECO_SDK_HOME = 'D:\DevEco Studio\sdk'
node 'D:\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p product=default -p buildMode=debug assembleHap
```

构建成功后，使用 DevEco Studio 或 HDC 安装生成的 HAP 至设备进行验证。

## 作者与反馈

- 维护者：[LoMoCatAp](https://github.com/LoMoCatAp)
- 项目仓库：[LoMoCatAp/ImmersiveAI](https://github.com/LoMoCatAp/ImmersiveAI)
- Bug 与功能建议：[GitHub Issues](https://github.com/LoMoCatAp/ImmersiveAI/issues)

## License

See [LICENSE](LICENSE).
