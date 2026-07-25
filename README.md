# AIBox

AIBox is a HarmonyOS AI chat client built with ArkTS and ArkUI. It keeps provider credentials on-device, supports configurable AI services, streamed chat responses, Markdown and KaTeX rendering, file attachments, conversation history, and immersive visual settings.

## Highlights

- Configure multiple providers and switch the active provider in chat.
- Supports OpenAI-compatible, DeepSeek, Claude-style, and Gemini-style protocols.
- Test connections and discover available models when the provider supports it.
- Stream responses with visible reasoning, persistent conversation history, and selectable context length.
- Render Markdown, code blocks, tables, links, and LaTeX formulas.
- Import supported text files into a message.
- Persist chat settings from the More sheet: model override, system prompt, context count, and assistant name.
- ArkUI interface with light/dark mode, theme colors, adjustable message text size, and HarmonyOS immersive material settings.

## Requirements

- DevEco Studio with a compatible HarmonyOS SDK.
- A HarmonyOS device or emulator that supports this project's target API level.
- API credentials for the AI provider you configure.

## Build

Open the project directory in DevEco Studio, select the `entry` module, then build and run the default product.

From PowerShell, with the SDK installed at the configured DevEco Studio location:

```powershell
$env:DEVECO_SDK_HOME = 'D:\DevEco Studio\sdk'
node 'D:\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p product=default -p buildMode=debug assembleHap
```

The signed debug HAP is generated under `entry/build/default/outputs/default/` and is intentionally excluded from Git.

## Provider Setup

1. Open Provider settings and add a provider.
2. Enter the service endpoint, model, and API key.
3. Enable the provider, then run Test connection.
4. In chat, open More to select or enter a model and configure session options. Tap Save to persist those options across app launches.

API keys are stored locally through the HarmonyOS asset storage service. Do not commit private keys, signing certificates, or generated packages; the repository `.gitignore` excludes these files.

## Project Structure

```text
entry/src/main/ets/
  views/        Page-level ArkUI views
  components/   Reusable chat and settings components
  viewmodel/    UI state and interaction logic
  service/      Provider protocols, streaming, Markdown, and import support
  data/         Local persistence and credential storage
```

## License

See [LICENSE](LICENSE).
