export const APP_NAME: string = '沉浸智能';
export const APP_TITLE: string = '沉浸智能';
export const CONTENT_MAX_WIDTH: number = 920;
export const TOUCH_TARGET: number = 48;
export const FLOATING_BAR_INSET: number = 72;
export const CONTENT_BOTTOM_INSET: number = 112;
export const KEYBOARD_INSET: number = 24;
export const STATUS_LABELS: Record<string, string> = { 'generating': '正在生成', 'completed': '已完成', 'stopped': '已停止', 'failed': '生成失败' };
export const NAVIGATION_LABELS: Record<string, string> = { 'chat': '聊天', 'history': '历史', 'providers': '供应商' };
export const OPERATION_LABELS: Record<string, string> = { 'idle': '就绪', 'loading': '处理中', 'success': '操作成功', 'failure': '操作失败', 'cancelled': '已取消' };
export const SAFE_MESSAGES: Record<string, string> = { 'emptyInput': '请输入消息后再发送', 'providerRequired': '请先配置并启用供应商', 'confirmDelete': '再次点击删除以确认', 'importEmpty': '请粘贴供应商 JSON', 'copyUnavailable': '当前系统未验证剪贴板能力，内容未复制' };
export const PROVIDER_MESSAGES: Record<string, string> = {
  'saved': '供应商已保存', 'saveFailed': '供应商保存失败，请检查填写内容', 'toggled': '供应商状态已更新',
  'deleted': '供应商已删除', 'deleteFailed': '供应商删除失败，请稍后重试', 'testing': '正在测试连接',
  'importReady': '导入内容已通过预览，请确认', 'importCancelled': '已取消导入', 'importCleared': '已清空导入内容'
};
export const CHAT_MESSAGES: Record<string, string> = {
  'ready': '可以开始聊天', 'sending': '正在发送', 'stopped': '已停止生成', 'completed': '回答已完成',
  'failed': '回答生成失败，请重试', 'copied': '复制能力尚未验证，内容未复制'
};
export const HISTORY_MESSAGES: Record<string, string> = {
  'created': '已新建会话', 'opened': '已打开会话', 'renamed': '会话名称已更新',
  'deleted': '会话已删除', 'confirmDelete': '再次点击删除以确认', 'renameRequired': '请输入会话名称'
};
export const COMMON_MESSAGES: Record<string, string> = { 'cancelled': '已取消操作', 'returnChat': '已返回聊天', 'loading': '正在处理，请稍候', 'busy': '上一个操作仍在进行，请稍候' };
