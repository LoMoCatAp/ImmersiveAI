export interface ThemeTokenSet {
  pagePadding: number;
  cardRadius: number;
  compactWidth: number;
  tabletWidth: number;
  contentMaxWidth: number;
  pageBackground: ResourceColor;
  surface: ResourceColor;
  primary: ResourceColor;
  primaryText: ResourceColor;
  secondaryText: ResourceColor;
  danger: ResourceColor;
  success: ResourceColor;
  warning: ResourceColor;
  touchTarget: number;
  fieldGap: number;
  safeAreaPadding: number;
  floatingBarInset: number;
  barBottomDistance: number;
  contentBottomInset: number;
  keyboardPadding: number;
  chineseTextSpacing: number;
  minimumContrast: number;
  minButtonWidth: number;
  maxChineseLines: number;
  bottomSafeInset: number;
  feedbackDuration: number;
}

export const THEME_TOKENS: ThemeTokenSet = {
  pagePadding: 20,
  cardRadius: 18,
  compactWidth: 600,
  tabletWidth: 900,
  contentMaxWidth: 920,
  pageBackground: $r('app.color.app_background'),
  surface: $r('app.color.surface'),
  primary: $r('app.color.primary'),
  primaryText: $r('app.color.text_primary'),
  secondaryText: $r('app.color.text_secondary'),
  danger: $r('app.color.danger'),
  success: '#18794E',
  warning: '#946200',
  touchTarget: 48,
  fieldGap: 10,
  safeAreaPadding: 16,
  floatingBarInset: 64,
  barBottomDistance: 0,
  contentBottomInset: 84,
  keyboardPadding: 24,
  chineseTextSpacing: 4,
  minimumContrast: 4.5,
  minButtonWidth: 88,
  maxChineseLines: 3,
  bottomSafeInset: 0,
  feedbackDuration: 1800
};

export function pagePaddingFor(width: number): number {
  return width >= THEME_TOKENS.tabletWidth ? 32 : THEME_TOKENS.pagePadding;
}

export function contentWidthFor(width: number): string {
  return width >= THEME_TOKENS.tabletWidth ? `${THEME_TOKENS.contentMaxWidth}vp` : '100%';
}
