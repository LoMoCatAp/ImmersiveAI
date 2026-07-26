import { MarkdownBlock, MarkdownBlockKind, MarkdownInline, MarkdownInlineKind, MarkdownParser } from '../service/MarkdownParser';
import { THEME_TOKENS } from '../common/ThemeTokens';
import { common } from '@kit.AbilityKit';
import { LatexFormatter } from '../service/LatexFormatter';
import { LatexFormulaView } from './LatexFormulaView';

@Component
export struct MarkdownBlockView {
  @Prop block: MarkdownBlock = { kind: MarkdownBlockKind.Paragraph, text: '', level: 0 };
  @Prop textSize: number = 16;

  private openLink(url: string | undefined): void {
    if (url === undefined || !url.startsWith('http')) return;
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    void context.startAbility({ action: 'ohos.want.action.viewData', uri: url });
  }

  @Builder
  private inlineContent(source: string): void {
    Text() {
      ForEach(MarkdownParser.parseInline(source), (token: MarkdownInline) => {
        Span(token.kind === MarkdownInlineKind.Math ? LatexFormatter.format(token.text) : token.text)
          .fontWeight(token.kind === MarkdownInlineKind.Bold || this.block.kind === MarkdownBlockKind.Heading ? FontWeight.Bold : FontWeight.Normal)
          .fontStyle(token.kind === MarkdownInlineKind.Italic || this.block.kind === MarkdownBlockKind.Quote ? FontStyle.Italic : FontStyle.Normal)
          .fontFamily(token.kind === MarkdownInlineKind.Code || token.kind === MarkdownInlineKind.Math ? 'monospace' : undefined)
          .fontSize(token.kind === MarkdownInlineKind.Badge || token.kind === MarkdownInlineKind.Footnote ? this.textSize - 3 : this.textSize)
          .fontColor(token.kind === MarkdownInlineKind.Link ? '#2F75D6' : token.kind === MarkdownInlineKind.Badge || token.kind === MarkdownInlineKind.Footnote ? '#2F75D6' : $r('app.color.text_primary'))
          .decoration({ type: token.kind === MarkdownInlineKind.Strike ? TextDecorationType.LineThrough : token.kind === MarkdownInlineKind.Link ? TextDecorationType.Underline : TextDecorationType.None })
          .onClick((): void => { if (token.kind === MarkdownInlineKind.Link) this.openLink(token.url); });
      }, (token: MarkdownInline, index: number): string => `${index}-${token.kind}`);
    }
    .fontSize(this.block.kind === MarkdownBlockKind.Heading ? this.textSize + (7 - this.block.level) * 2 : this.textSize)
    .wordBreak(WordBreak.BREAK_ALL)
    .copyOption(CopyOptions.LocalDevice)
    .width('100%')
    .constraintSize({ maxWidth: '100%' });
  }

  @Builder
  private inlineListContent(source: string): void {
    Text() {
      ForEach(MarkdownParser.parseInline(source), (token: MarkdownInline) => {
        Span(token.kind === MarkdownInlineKind.Math ? LatexFormatter.format(token.text) : token.text)
          .fontWeight(token.kind === MarkdownInlineKind.Bold ? FontWeight.Bold : FontWeight.Normal)
          .fontStyle(token.kind === MarkdownInlineKind.Italic ? FontStyle.Italic : FontStyle.Normal)
          .fontFamily(token.kind === MarkdownInlineKind.Code || token.kind === MarkdownInlineKind.Math ? 'monospace' : undefined)
          .fontSize(token.kind === MarkdownInlineKind.Badge || token.kind === MarkdownInlineKind.Footnote ? this.textSize - 3 : this.textSize)
          .fontColor(token.kind === MarkdownInlineKind.Link ? '#2F75D6' : token.kind === MarkdownInlineKind.Badge || token.kind === MarkdownInlineKind.Footnote ? '#2F75D6' : $r('app.color.text_primary'))
          .decoration({ type: token.kind === MarkdownInlineKind.Strike ? TextDecorationType.LineThrough : token.kind === MarkdownInlineKind.Link ? TextDecorationType.Underline : TextDecorationType.None })
          .onClick((): void => { if (token.kind === MarkdownInlineKind.Link) this.openLink(token.url); });
      }, (token: MarkdownInline, index: number): string => `${index}-${token.kind}`);
    }
    .fontSize(this.textSize)
    .wordBreak(WordBreak.BREAK_ALL)
    .copyOption(CopyOptions.LocalDevice)
    .layoutWeight(1)
    .constraintSize({ maxWidth: '100%' });
  }

  private listParts(text: string): string[] {
    const match: RegExpMatchArray | null = text.match(new RegExp('^((?:[-+*])|(?:\\d+\\.))\\s+(.*)$'));
    return match === null ? ['-', text] : [match[1], match[2]];
  }

  private listMarker(): string {
    return this.listParts(this.block.text)[0];
  }

  private listText(): string {
    return this.listParts(this.block.text)[1];
  }

  @Builder
  private listContent(): void {
    Row({ space: 6 }) {
      Text(this.listMarker()).fontSize(this.textSize).fontColor($r('app.color.text_primary'));
      this.inlineListContent(this.listText());
    }
    .width('100%')
    .padding({ left: this.block.level * 12 });
  }

  @Builder
  private tableContent(): void {
    Column({ space: 1 }) {
      ForEach(this.block.rows ?? [], (row: string[], rowIndex: number) => {
        Row({ space: 1 }) {
          ForEach(row, (cell: string, cellIndex: number) => {
            Text(cell)
              .fontSize(this.textSize - 1)
              .fontWeight(rowIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor($r('app.color.text_primary'))
              .wordBreak(WordBreak.BREAK_ALL)
              .padding(8)
              .layoutWeight(1)
              .backgroundColor(rowIndex === 0 ? THEME_TOKENS.surface : $r('app.color.chat_assistant_bubble'));
          }, (_cell: string, cellIndex: number): string => `${rowIndex}-${cellIndex}`);
        }.width('100%');
      }, (_row: string[], rowIndex: number): string => `${rowIndex}`);
    }
    .width('100%')
    .borderRadius(8)
    .clip(true);
  }

  build() {
    Column({ space: 4 }) {
      if (this.block.kind === MarkdownBlockKind.Table) {
        this.tableContent();
      } else if (this.block.kind === MarkdownBlockKind.Divider) {
        Divider().color(THEME_TOKENS.secondaryText).strokeWidth(1).width('100%').margin({ top: 6, bottom: 10 });
      } else if (this.block.kind === MarkdownBlockKind.Footnote) {
        Text(`[${this.block.text}]`).fontSize(this.textSize - 3).fontColor(THEME_TOKENS.secondaryText).wordBreak(WordBreak.BREAK_ALL).copyOption(CopyOptions.LocalDevice);
      } else if (this.block.kind === MarkdownBlockKind.Task) {
        Row({ space: 8 }) {
          Text(this.block.checked ? '[x]' : '[ ]').fontSize(this.textSize).fontColor(this.block.checked ? '#2F75D6' : THEME_TOKENS.secondaryText);
          this.inlineListContent(this.block.text);
        }.width('100%');
      } else if (this.block.kind === MarkdownBlockKind.Code) {
        Text(this.block.text)
          .fontSize(this.textSize - 1)
          .fontFamily('monospace')
          .fontColor($r('app.color.text_primary'))
          .wordBreak(WordBreak.BREAK_ALL)
          .copyOption(CopyOptions.LocalDevice)
          .padding(12)
          .width('100%')
          .borderRadius(8)
          .backgroundColor(THEME_TOKENS.surface);
      } else if (this.block.kind === MarkdownBlockKind.Math) {
        LatexFormulaView({ source: this.block.text, textSize: this.textSize })
          .width('100%')
          .borderRadius(8)
          .clip(true)
          .backgroundColor(THEME_TOKENS.surface);
      } else {
        if (this.block.kind === MarkdownBlockKind.List) {
          this.listContent();
        } else {
          this.inlineContent(this.block.text);
        }
      }
    }
    .padding({ bottom: 8 })
    .width('100%');
  }
}
