import { webview } from '@kit.ArkWeb';

@Component
export struct LatexFormulaView {
  @Prop @Watch('onFormulaChanged') source: string = '';
  @Prop textSize: number = 16;
  @Prop isDark: boolean = false;
  private controller: webview.WebviewController = new webview.WebviewController();
  @State private isPageReady: boolean = false;

  private onFormulaChanged(): void {
    this.renderFormula();
  }

  private renderFormula(): void {
    if (!this.isPageReady) return;
    const formula: string = JSON.stringify(this.source);
    const dark: string = this.isDark ? 'true' : 'false';
    void this.controller.runJavaScript(`window.renderFormula(${formula}, true, ${dark}, ${this.textSize});`);
  }

  build() {
    Web({ src: 'https://aibox.local/katex/formula.html', controller: this.controller })
      .width('100%')
      .height(76)
      .javaScriptAccess(true)
      .domStorageAccess(false)
      .backgroundColor(Color.Transparent)
      .onInterceptRequest((event) => {
        if (event === undefined) return null;
        const url: string = event.request.getRequestUrl();
        const response: WebResourceResponse = new WebResourceResponse();
        if (url === 'https://aibox.local/katex/formula.html') {
          response.setResponseData($rawfile('katex/formula.html'));
          response.setResponseMimeType('text/html');
        } else if (url === 'https://aibox.local/katex/katex.min.css') {
          response.setResponseData($rawfile('katex/katex.min.css'));
          response.setResponseMimeType('text/css');
        } else if (url === 'https://aibox.local/katex/katex.min.js') {
          response.setResponseData($rawfile('katex/katex.min.js'));
          response.setResponseMimeType('text/javascript');
        } else if (url.startsWith('https://aibox.local/katex/fonts/')) {
          const fontName: string = url.substring('https://aibox.local/katex/fonts/'.length);
          response.setResponseData($rawfile(`katex/fonts/${fontName}`));
          response.setResponseMimeType(fontName.endsWith('.woff2') ? 'font/woff2' : 'font/woff');
        } else {
          return null;
        }
        response.setResponseEncoding('utf-8');
        response.setResponseCode(200);
        response.setReasonMessage('OK');
        response.setResponseIsReady(true);
        return response;
      })
      .onPageEnd(() => {
        this.isPageReady = true;
        this.renderFormula();
      });
  }
}
