import { ToastUtil } from './ToastUtil';
import { pasteboard } from '@kit.BasicServicesKit';
import { MLog } from '@qqmusic/opisdk-base';

const TAG = 'ClipboardUtils';

/**
 * 剪贴板工具类
 * 提供文本复制到系统剪贴板的能力，复制成功后弹出 Toast 提示
 */
export class ClipboardUtils {
  private static systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();

  /**
   * 复制文本到系统剪贴板并弹出提示
   * @param text 要复制的文本内容
   * @param label 复制内容的描述（用于 toast 提示和日志）
   */
  static copy(text: string, label: string): void {
    if (!text || text.length === 0) {
      MLog.w(TAG, `copy: empty text, label=${label}`);
      return;
    }
    const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    ClipboardUtils.systemPasteboard.setData(pasteData, (err: Error) => {
      if (err) {
        MLog.e(TAG, `copy failed, label=${label}, err=${err.message}`);
      } else {
        MLog.i(TAG, `copy success, label=${label}, text=${text.substring(0, 50)}`);
        ToastUtil.show(`已复制${label}到剪切板`);
      }
    });
  }
}
