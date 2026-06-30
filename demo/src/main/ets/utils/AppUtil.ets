import BuildProfile from "BuildProfile";
import { common } from "@kit.AbilityKit";
import window from "@ohos.window";
import { MLog } from '@qqmusic/opisdk-base';
/**
 * @Description: APP辅助类
 *
 * @Author: jeffxliu
 * @Date: 2026/2/3
 */
export class AppUtil {
  private static readonly TAG = "AppUtil";
  private static _appContext: common.ApplicationContext;
  private static _abilityContext: common.UIAbilityContext;
  private static _uiContext: UIContext|undefined = undefined;
  static bottomSafeArea: number = 0;

  // 是否是Release版本
  static isRelease(): boolean {
    return !BuildProfile.DEBUG;
  }

  // 是否是Debug版本
  static isDebug(): boolean {
    return BuildProfile.DEBUG;
  }

  static versionName(){
    return BuildProfile.VERSION_NAME
  }

  static setContext(context: common.UIAbilityContext) {
    AppUtil._abilityContext = context;
    AppUtil._appContext = context.getApplicationContext();
  }

  static async setUIContext(windowStage: window.WindowStage) {
    try {
      const windowClass = await windowStage.getMainWindow();
      AppUtil._uiContext = windowClass.getUIContext();
      // 计算底部安全区高度
      const avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      AppUtil.bottomSafeArea = AppUtil._uiContext.px2vp(avoidArea.bottomRect.height);
    } catch (e) {
      MLog.e(AppUtil.TAG, "getMainWindow failed", e);
    }
  }

  static get uiContext(): UIContext|undefined {
    return AppUtil._uiContext;
  }

  static get appContext(): common.ApplicationContext {
    return AppUtil._appContext;
  }

  static get abilityContext(): common.UIAbilityContext {
    return AppUtil._abilityContext;
  }

  static getString(resName: string): string {
    try {
      return AppUtil.appContext.resourceManager.getStringByNameSync(resName);
    } catch (e) {
      return "";
    }
  }
}