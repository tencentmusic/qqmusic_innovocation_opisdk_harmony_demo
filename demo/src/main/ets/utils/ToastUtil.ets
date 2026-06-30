import { AppUtil } from "./AppUtil";
import { deviceInfo } from "@kit.BasicServicesKit";
import { MLog } from "@qqmusic/opisdk-base";

/**
 * @Description: Toast辅助类
 *
 * @Author: jeffxliu
 * @Date: 2026/2/3
 */
export class ToastUtil {
  private static readonly TAG = "ToastUtil";

  static show(text: string|Resource, duration: number = 3000): void {
    const uiContext = AppUtil.uiContext;
    if (!uiContext) {
      MLog.w(ToastUtil.TAG, "uiContext is null");
      return;
    }

    if (deviceInfo.sdkApiVersion >= 20) {
      if (!uiContext.isAvailable()) {
        MLog.w(ToastUtil.TAG, "uiContext is not available");
        return;
      }
    }

    try {
      uiContext.getPromptAction().showToast({
        message: text,
        duration: duration
      });
    } catch (error) {
      MLog.e(ToastUtil.TAG, "showToast failed", error);
    }
  }
}