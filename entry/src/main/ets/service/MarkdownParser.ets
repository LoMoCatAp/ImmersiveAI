export enum MarkdownBlockKind { Heading = 'heading', Paragraph = 'paragraph', List = 'list', Task = 'task', Quote = 'quote', Code = 'code', Table = 'table', Math = 'math', Divider = 'divider', Footnote = 'footnote' }
export enum MarkdownInlineKind { Text = 'text', Bold = 'bold', Italic = 'italic', Strike = 'strike', Code = 'code', Link = 'link', Math = 'math', Badge = 'badge', Footnote = 'footnote' }

export interface MarkdownBlock {
  kind: MarkdownBlockKind;
  text: string;
  level: number;
  rows?: string[][];
  checked?: boolean;
}

export interface MarkdownInline {
  kind: MarkdownInlineKind;
  text: string;
  url?: string;
  rawLength?: number;
}

export class MarkdownParser {
  static parse(source: string): MarkdownBlock[] {
    const result: MarkdownBlock[] = [];
    const lines: string[] = source.replace(new RegExp('\\r\\n', 'g'), '\n').split('\n');
    let index: number = 0;
    let htmlListOrdered: boolean = false;
    let htmlListIndex: number = 1;
    while (index < lines.length) {
      const line: string = lines[index];
      const trimmed: string = line.trim();
      if (trimmed.length === 0) {
        index += 1;
        continue;
      }
      if (trimmed === '---' || trimmed === '***' || trimmed === '___' || trimmed.toLowerCase() === '<hr>' || trimmed.toLowerCase() === '<hr/>') {
        result.push({ kind: MarkdownBlockKind.Divider, text: '', level: 0 });
        index += 1;
        continue;
      }
      if (trimmed.toLowerCase() === '<ol>') {
        htmlListOrdered = true;
        htmlListIndex = 1;
        index += 1;
        continue;
      }
      if (trimmed.toLowerCase() === '<ul>') {
        htmlListOrdered = false;
        index += 1;
        continue;
      }
      if (trimmed.toLowerCase() === '</ol>' || trimmed.toLowerCase() === '</ul>') {
        index += 1;
        continue;
      }
      const htmlListItem: RegExpMatchArray | null = trimmed.match(new RegExp('^<li>(.*)</li>$', 'i'));
      if (htmlListItem !== null) {
        const marker: string = htmlListOrdered ? `${htmlListIndex}.` : '-';
        result.push({ kind: MarkdownBlockKind.List, text: `${marker} ${htmlListItem[1]}`, level: 0 });
        htmlListIndex += 1;
        index += 1;
        continue;
      }
      const footnote: RegExpMatchArray | null = trimmed.match(new RegExp('^\\[\\^([^\\]]+)\\]:\\s*(.*)$'));
      if (footnote !== null) {
        result.push({ kind: MarkdownBlockKind.Footnote, text: `${footnote[1]}: ${footnote[2]}`, level: 0 });
        index += 1;
        continue;
      }
      if (trimmed.startsWith('```')) {
        const codeLines: string[] = [];
        index += 1;
        while (index < lines.length && !lines[index].trim().startsWith('```')) {
          codeLines.push(lines[index]);
          index += 1;
        }
        if (index < lines.length) index += 1;
        result.push({ kind: MarkdownBlockKind.Code, text: codeLines.join('\n'), level: 0 });
        continue;
      }
      if (trimmed.startsWith('$$')) {
        const mathLines: string[] = [];
        if (trimmed.length > 2 && trimmed.endsWith('$$')) mathLines.push(trimmed.slice(2, trimmed.length - 2).trim());
        else {
          index += 1;
          while (index < lines.length && !lines[index].trim().startsWith('$$')) {
            mathLines.push(lines[index]);
            index += 1;
          }
        }
        if (index < lines.length && lines[index].trim().startsWith('$$')) index += 1;
        result.push({ kind: MarkdownBlockKind.Math, text: mathLines.join('\n').trim(), level: 0 });
        continue;
      }
      if (trimmed.startsWith('\\[')) {
        const mathLines: string[] = [];
        if (trimmed.length > 2 && trimmed.endsWith('\\]')) {
          mathLines.push(trimmed.slice(2, trimmed.length - 2).trim());
          index += 1;
        } else {
          index += 1;
          while (index < lines.length && !lines[index].trim().endsWith('\\]')) {
            mathLines.push(lines[index]);
            index += 1;
          }
          if (index < lines.length) {
            mathLines.push(lines[index].trim().slice(0, -2));
            index += 1;
          }
        }
        result.push({ kind: MarkdownBlockKind.Math, text: mathLines.join('\n').trim(), level: 0 });
        continue;
      }
      if (MarkdownParser.pushDelimitedMath(result, line)) {
        index += 1;
        continue;
      }
      if (index + 1 < lines.length && MarkdownParser.isTableRow(line) && MarkdownParser.isTableSeparator(lines[index + 1])) {
        const rows: string[][] = [MarkdownParser.tableCells(line)];
        index += 2;
        while (index < lines.length && MarkdownParser.isTableRow(lines[index])) {
          rows.push(MarkdownParser.tableCells(lines[index]));
          index += 1;
        }
        result.push({ kind: MarkdownBlockKind.Table, text: '', level: 0, rows });
        continue;
      }
      const heading: RegExpMatchArray | null = trimmed.match(new RegExp('^(#{1,6})\\s+(.*)$'));
      if (heading !== null) {
        result.push({ kind: MarkdownBlockKind.Heading, text: heading[2], level: heading[1].length });
        index += 1;
        continue;
      }
      if (trimmed.startsWith('>')) {
        result.push({ kind: MarkdownBlockKind.Quote, text: trimmed.slice(1).trim(), level: 0 });
        index += 1;
        continue;
      }
      const task: RegExpMatchArray | null = line.match(new RegExp('^(\\s*)[-+*]\\s+\\[([ xX])\\]\\s+(.*)$'));
      if (task !== null) {
        result.push({ kind: MarkdownBlockKind.Task, text: task[3], level: Math.floor(task[1].length / 2), checked: task[2].toLowerCase() === 'x' });
        index += 1;
        continue;
      }
      const list: RegExpMatchArray | null = line.match(new RegExp('^(\\s*)((?:[-+*])|(?:\\d+\\.))\\s+(.*)$'));
      if (list !== null) {
        result.push({ kind: MarkdownBlockKind.List, text: `${list[2]} ${list[3]}`, level: Math.floor(list[1].length / 2) });
        index += 1;
        continue;
      }
      result.push({ kind: MarkdownBlockKind.Paragraph, text: line, level: 0 });
      index += 1;
    }
    return result;
  }

  private static pushDelimitedMath(result: MarkdownBlock[], line: string): boolean {
    let cursor: number = 0;
    let parsed: boolean = false;
    while (cursor < line.length) {
      const dollarStart: number = line.indexOf('$$', cursor);
      const slashStart: number = line.indexOf('\\(', cursor);
      const start: number = dollarStart < 0 ? slashStart : slashStart < 0 ? dollarStart : Math.min(dollarStart, slashStart);
      if (start < 0) break;
      const isDollar: boolean = start === dollarStart;
      const closer: string = isDollar ? '$$' : '\\)';
      const end: number = line.indexOf(closer, start + 2);
      if (end < 0) break;
      const leading: string = line.slice(cursor, start).replace(new RegExp('\\s+$'), '');
      if (leading.length > 0) MarkdownParser.pushTextBlock(result, leading);
      const formula: string = line.slice(start + 2, end).trim();
      if (formula.length > 0) result.push({ kind: MarkdownBlockKind.Math, text: formula, level: 0 });
      cursor = end + closer.length;
      parsed = true;
    }
    if (parsed) {
      const trailing: string = line.slice(cursor).replace(new RegExp('^\\s+'), '');
      if (trailing.length > 0) MarkdownParser.pushTextBlock(result, trailing);
    }
    return parsed;
  }

  private static pushTextBlock(result: MarkdownBlock[], text: string): void {
    const list: RegExpMatchArray | null = text.match(new RegExp('^(\\s*)((?:[-+*])|(?:\\d+\\.))\\s+(.*)$'));
    if (list !== null) {
      result.push({ kind: MarkdownBlockKind.List, text: `${list[2]} ${list[3]}`, level: Math.floor(list[1].length / 2) });
      return;
    }
    result.push({ kind: MarkdownBlockKind.Paragraph, text, level: 0 });
  }

  static parseInline(source: string): MarkdownInline[] {
    const result: MarkdownInline[] = [];
    let index: number = 0;
    while (index < source.length) {
      const token: MarkdownInline | undefined = MarkdownParser.inlineToken(source, index);
      if (token !== undefined) {
        result.push(token);
        index += MarkdownParser.tokenLength(source, index, token);
        continue;
      }
      const start: number = index;
      index += 1;
      while (index < source.length && !MarkdownParser.isMarker(source, index)) index += 1;
      result.push({ kind: MarkdownInlineKind.Text, text: source.slice(start, index) });
    }
    return result;
  }

  private static inlineToken(source: string, index: number): MarkdownInline | undefined {
    const pairs: Array<[string, MarkdownInlineKind]> = [['**', MarkdownInlineKind.Bold], ['__', MarkdownInlineKind.Bold], ['~~', MarkdownInlineKind.Strike], ['`', MarkdownInlineKind.Code], ['*', MarkdownInlineKind.Italic], ['_', MarkdownInlineKind.Italic], ['$', MarkdownInlineKind.Math]];
    if (source.startsWith('[^', index)) {
      const end: number = source.indexOf(']', index + 2);
      if (end > index + 2) return { kind: MarkdownInlineKind.Footnote, text: source.slice(index + 2, end), rawLength: end - index + 1 };
    }
    const badgeTags: string[] = ['sup', 'badge', 'mark'];
    for (let tagIndex: number = 0; tagIndex < badgeTags.length; tagIndex += 1) {
      const tag: string = badgeTags[tagIndex];
      const open: string = `<${tag}>`;
      const close: string = `</${tag}>`;
      if (!source.startsWith(open, index)) continue;
      const end: number = source.indexOf(close, index + open.length);
      if (end > index + open.length) return { kind: MarkdownInlineKind.Badge, text: source.slice(index + open.length, end), rawLength: end - index + close.length };
    }
    if (source.startsWith('[', index)) {
      const closeLabel: number = source.indexOf('](', index + 1);
      const closeUrl: number = closeLabel < 0 ? -1 : source.indexOf(')', closeLabel + 2);
      if (closeLabel > index && closeUrl > closeLabel + 2) return { kind: MarkdownInlineKind.Link, text: source.slice(index + 1, closeLabel), url: source.slice(closeLabel + 2, closeUrl), rawLength: closeUrl - index + 1 };
    }
    for (let pairIndex: number = 0; pairIndex < pairs.length; pairIndex += 1) {
      const marker: string = pairs[pairIndex][0];
      if (!source.startsWith(marker, index)) continue;
      const end: number = source.indexOf(marker, index + marker.length);
      if (end > index + marker.length) return { kind: pairs[pairIndex][1], text: source.slice(index + marker.length, end) };
    }
    return undefined;
  }

  private static tokenLength(source: string, index: number, token: MarkdownInline): number {
    if (token.rawLength !== undefined) return token.rawLength;
    if (token.kind === MarkdownInlineKind.Link) {
      const closeLabel: number = source.indexOf('](', index + 1);
      const closeUrl: number = closeLabel < 0 ? -1 : source.indexOf(')', closeLabel + 2);
      return closeUrl >= 0 ? closeUrl - index + 1 : 1;
    }
    if (token.kind === MarkdownInlineKind.Bold || token.kind === MarkdownInlineKind.Strike) return token.text.length + 4;
    return token.text.length + 2;
  }

  private static isMarker(source: string, index: number): boolean {
    const character: string = source[index];
    return character === '*' || character === '_' || character === '~' || character === '`' || character === '[' || character === '$' || character === '<';
  }

  private static isTableRow(line: string): boolean {
    return line.includes('|') && line.trim().replace(new RegExp('\\|', 'g'), '').length > 0;
  }

  private static isTableSeparator(line: string): boolean {
    return new RegExp('^\\s*\\|?\\s*:?-{3,}:?\\s*(\\|\\s*:?-{3,}:?\\s*)+\\|?\\s*$').test(line);
  }

  private static tableCells(line: string): string[] {
    return line.trim().replace(new RegExp('^\\|'), '').replace(new RegExp('\\|$'), '').split('|').map((cell: string): string => cell.trim());
  }
}
