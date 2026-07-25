export class SseStreamParser {
  private buffer: string = '';

  feed(chunk: string): string[] {
    this.buffer += chunk.replace(new RegExp('\\r\\n', 'g'), '\n');
    const frames: string[] = this.buffer.split('\n\n');
    this.buffer = frames.pop() ?? '';
    return frames.filter((frame: string) => frame.trim().length > 0);
  }

  finish(): string[] {
    const result: string[] = this.buffer.trim().length > 0 ? [this.buffer] : [];
    this.buffer = '';
    return result;
  }

  static data(frame: string): string {
    const lines: string[] = frame.split('\n');
    const dataLines: string[] = lines.filter((line: string) => line.startsWith('data:'))
      .map((line: string) => line.slice(5).trimStart());
    return dataLines.join('\n');
  }
}
