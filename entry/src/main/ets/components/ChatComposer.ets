
@Component
export struct ChatComposer {
  @State inputText: string = '';
  @Prop isGenerating: boolean = false;
  @Prop hasAttachment: boolean = false;
  onSend: (text: string) => void = (_text: string): void => {};
  onStop: () => void = (): void => {};
  onMore: () => void = (): void => {};
  onPickAttachment: () => void = (): void => {};
  build() {
    Column({ space: 8 }) {
      Row() {
        Button('导入文件').onClick(this.onPickAttachment).height(32).fontSize(13).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.84 });
      }.width('100%');
    Row({ space: 8 }) {
       TextInput({ placeholder: '输入消息', text: this.inputText }).layoutWeight(1).onChange((value: string): void => { this.inputText = value; });
      if (this.isGenerating) {
         Button('停止生成').onClick(this.onStop).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      } else {
          Button('发送').onClick((): void => { const value: string = this.inputText.trim(); if (value.length > 0 || this.hasAttachment) { this.onSend(value); this.inputText = ''; } }).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
         Button('更多').onClick(this.onMore).clickEffect({ level: ClickEffectLevel.MIDDLE, scale: 0.88 });
      }
      }.width('100%');
    }.padding(12).width('100%');
  }
}
