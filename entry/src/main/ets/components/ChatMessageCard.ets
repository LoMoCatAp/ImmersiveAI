import { MessageStatus } from '../model/ChatModels';
import { MarkdownBlock, MarkdownParser } from '../service/MarkdownParser';
import { MarkdownBlockView } from './MarkdownBlockView';
import { ReasoningSection } from './ReasoningSection';
import { THEME_TOKENS } from '../common/ThemeTokens';

@Component
export struct ChatMessageCard {
  @Prop role: string = 'assistant';
  @Prop @Watch('onContentChanged') content: string = '';
  @Prop @Watch('onReasoningChanged') reasoningContent: string = '';
  @Prop status: MessageStatus = MessageStatus.Completed;
  @Prop errorSummary: string = '';
  @StorageLink('appearance_chat_text_size') private chatTextSize: string = '16';
  @State private renderedContent: string = '';
  @State private renderedReasoning: string = '';

  aboutToAppear(): void {
    this.renderedContent = this.content;
    this.renderedReasoning = this.reasoningContent;
  }

  private onContentChanged(): void {
    this.renderedContent = this.content;
  }

  private onReasoningChanged(): void {
    this.renderedReasoning = this.reasoningContent;
  }

  private messageTextSize(): number {
    const size: number = Number(this.chatTextSize);
    return size >= 12 && size <= 24 ? size : 16;
  }

  build() {
    Column({ space: 4 }) {
      Text(this.role === 'assistant' ? '助手' : '我').fontSize(12).fontColor(THEME_TOKENS.secondaryText);
      if (this.role === 'assistant') {
        ForEach(MarkdownParser.parse(this.renderedContent), (block: MarkdownBlock) => { MarkdownBlockView({ block, textSize: this.messageTextSize() }) });
        if (this.renderedReasoning.trim().length > 0) ReasoningSection({ content: this.renderedReasoning });
        if (this.status === MessageStatus.Generating) Text('正在生成…').fontColor(THEME_TOKENS.secondaryText);
        if (this.errorSummary.length > 0) Text(this.errorSummary).fontColor(THEME_TOKENS.danger).wordBreak(WordBreak.BREAK_ALL);
      } else {
        Text(this.content).fontSize(this.messageTextSize()).fontColor(THEME_TOKENS.primaryText).wordBreak(WordBreak.BREAK_ALL).copyOption(CopyOptions.LocalDevice);
      }
    }
    .padding(16)
    .margin({ bottom: 8 })
    .borderRadius(THEME_TOKENS.cardRadius)
    .backgroundColor(this.role === 'assistant' ? $r('app.color.chat_assistant_bubble') : $r('app.color.chat_user_bubble'))
    .constraintSize({ maxWidth: '94%' });
  }
}
