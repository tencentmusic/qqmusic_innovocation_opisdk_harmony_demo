import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { InitConfig, OpenApiSdk, MLog, Global } from '@qqmusic/opisdk-base';

import { AbsMonitorConfig } from '@qqmusic/opisdk-entity';

import BuildProfile from 'demo/BuildProfile';
import { AppUtil } from '../utils/AppUtil';
import { SPUtils } from '../utils/SPUtils';
import { ResumePlayback } from '../utils/ResumePlayback';
import { BaseFuncProxy } from '../utils/BaseFuncProxy';
import { DemoGlobal } from '../utils/DemoGlobal';
import { OpiSdkInit } from '../../../generated/ets/OpiSdkInit';

export const TAG = "DemoAbility";

export default class DemoAbility extends UIAbility {
  private launchParam: AbilityConstant.LaunchParam | null = null;

  async onCreate(_want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    MLog.i(TAG, 'Ability onCreate');
    AppUtil.setContext(this.context);

    this.launchParam = launchParam;

    const abilityName = this.context.abilityInfo.name
    const bundleName = this.context.abilityInfo.bundleName
    MLog.i(TAG, `abilityName = ${abilityName}, bundleName = ${bundleName}`);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }

  onDestroy(): void {
    MLog.i(TAG, 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    MLog.i(TAG, 'Ability onWindowStageCreate');
    const opiAppId: string = BaseFuncProxy.getAccount().appId;
    const opiAppKey: string = BaseFuncProxy.getAccount().appKey;
    MLog.i(TAG, `opiAppId = ${opiAppId}, opiAppKey = ${opiAppKey}`);
    const initConfig = new InitConfig(this.context.getApplicationContext(), this.context, opiAppId, opiAppKey);
    initConfig.monitorConfig = new MonitorConfig(this.launchParam);
    initConfig.useMediaPlayerWhenPlayDolby = SPUtils.getBool("useMediaPlayerWhenPlayDolby", false);
    initConfig.deviceConfigInfo.lowMemoryMode = SPUtils.getBool("lowMemoryMode", false);
    initConfig.isUseForegroundService = SPUtils.getBool("isUseForegroundService", true);
    Global.channelId = SPUtils.getString("DemoChannelId", "123456789");
    await OpiSdkInit.init(initConfig);
    ResumePlayback.start();
    DemoGlobal.isPersonalAssets = SPUtils.getBool("enablePersonalAssets", true);

    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        MLog.e(TAG, `Failed to load the content. Cause: ${JSON.stringify(err)}`);
        return;
      }
      AppUtil.setUIContext(windowStage);
      MLog.i(TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    MLog.i(TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    MLog.i(TAG, 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    MLog.i(TAG, 'Ability onBackground');
  }
}

/**
 * 火眼相关配置
 */
class MonitorConfig extends AbsMonitorConfig {
  private launchParam: AbilityConstant.LaunchParam|null = null;
  constructor(launchParam: AbilityConstant.LaunchParam|null) {
    super();
    this.launchParam = launchParam;
  }

  versionName(): string {
    return BuildProfile.VERSION_NAME
  }

  isDebug(): boolean {
    return true
  }

  getLaunchParam(): AbilityConstant.LaunchParam|null {
    return this.launchParam;
  }

}
