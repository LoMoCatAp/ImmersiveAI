# AIBox Privacy Policy

Effective date: July 26, 2026

AIBox is maintained by Li Li. This policy explains how the HarmonyOS application processes information when you configure and use third-party AI services.

## Information Stored on Your Device

AIBox stores the following information in its private application sandbox:

- Provider configuration, including provider name, endpoint, selected model, and enabled state.
- Conversation history, generated content, reasoning content returned by a provider, and local token usage statistics.
- Appearance and chat preferences.

API keys are stored through HarmonyOS system asset storage and are not sent to an AIBox developer-operated server.

## Information Sent to Third Parties

AIBox does not operate an AI model service. When you choose to send a message, test a connection, discover models, or enable a supported web-search capability, AIBox sends the necessary request directly to the provider endpoint that you configured.

Depending on the request, this can include your message, system prompt, selected context messages, imported text file content, model name, and API key. The configured provider processes this information under its own privacy policy, service terms, account settings, and regional rules. You should only configure providers and submit information that you are authorized to use.

## Imported Files

AIBox uses HarmonyOS document picker and file APIs only after you select a file. The file is copied into the app temporary directory for reading, and its text can be included in a message only when you send that message. Temporary file copies are removed after reading. AIBox does not upload files to a developer server.

## Permissions

AIBox requests `ohos.permission.INTERNET` only to communicate with provider endpoints chosen by you. The application does not request access to contacts, location, call records, or device identifiers.

## Retention and Deletion

You can delete individual conversations and providers inside the application. Clearing AIBox application data in system settings or uninstalling AIBox removes local records and credentials stored by the app.

## Policy Changes and Contact

This policy may be updated when application functions or applicable rules change. The current source version is maintained at [LoMoCatAp/ImmersiveAI](https://github.com/LoMoCatAp/ImmersiveAI). For questions or feedback, use the repository Issues page.
