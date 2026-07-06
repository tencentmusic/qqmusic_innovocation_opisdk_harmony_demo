import workScheduler from '@ohos.resourceschedule.workScheduler';
import { WorkSchedulerExtensionAbility } from '@kit.BackgroundTasksKit';
import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base';

const TAG = "LoginRefreshWorkExtensionAbility";

export default class LoginRefreshWorkExtensionAbility extends WorkSchedulerExtensionAbility {
  onWorkStart(workInfo: workScheduler.WorkInfo) {
    MLog.i(TAG, `onWorkStart, workId: ${workInfo.workId}`);
    this.ensureLoginModuleInit();

    this.performRefreshToken(workInfo);
  }

  onWorkStop(workInfo: workScheduler.WorkInfo) {
    MLog.i(TAG, `onWorkStop, workId: ${workInfo.workId}`);
  }

  private ensureLoginModuleInit() {
    // loginApi 由 ServiceLoader 通过 @AutoService('ILoginApi') 自动注册并由 OpenApiSdk getter 惰性获取，
    // 这里仅做一次可用性检查；若 ServiceLoader 未发现实现则记录警告，避免下游 NPE。
    if (!OpenApiSdk.loginApi) {
      MLog.w(TAG, "loginApi not registered by ServiceLoader; check dependency on 'login' HAR and AutoService setup");
    }
  }

  private async performRefreshToken(workInfo: workScheduler.WorkInfo) {
    try {
      const randomMs = Math.floor(Math.random() * 5000);
      await new Promise<void>(resolve => setTimeout(resolve, randomMs));

      MLog.i(TAG, "Starting refresh access token logic...");

      // 执行自动登录(强登录刷新小票)
      OpenApiSdk.loginApi?.autoLoginToStrong((sus, msg) => {
        if (sus) {
          MLog.i(TAG, "后台任务刷新小票成功")
        } else {
          MLog.i(TAG, `后台任务刷新小票成失败${msg}`)
        }
      });

    } catch (e) {
      MLog.e(TAG, `performRefreshToken error: ${e.message}`);
    }
  }
}