import { Global } from '@qqmusic/opisdk-base';
import { SPUtils } from './SPUtils';

/**
 * AppCheckMode 枚举
 *
 * 0: 严格模式 (STRICT) - 使用固定的默认 appId/appKey
 * 1: 无检查模式 (UNCHECK) - 使用无检查的 appId/appKey
 * 2: 自定义模式 (CUSTOM) - 使用用户自定义的 appId/appKey
 */
export enum AppCheckMode {
  STRICT = 0,
  UNCHECK = 1,
  CUSTOM = 2
}

/**
 * Account 数据类
 */
export class Account {
  appId: string;
  appKey: string;

  constructor(appId: string, appKey: string) {
    this.appId = appId;
    this.appKey = appKey;
  }
}

/**
 * BaseFuncProxy
 * 对应 Android 中 BaseFuncProxy (BaseFunctionManager.proxy)
 *
 * 提供帐号检查模式管理、调试环境初始化等功能。
 * 所有方法均为静态方法，不实现 IBaseFunction 接口。
 */
export class BaseFuncProxy {
  // 严格模式默认帐号
  private static readonly STRICT_ACCOUNT = new Account('12345779', 'GmRZHxHAMyfzgbYW');
  // 无检查模式默认帐号
  private static readonly UNCHECK_ACCOUNT = new Account('12345668', 'qoJvLUGMKmSExFJdXD');

  /**
   * 获取当前帐号信息
   * 根据 appCheckMode 返回对应的 Account
   */
  static getAccount(): Account {
    const mode = BaseFuncProxy.getAppCheckMode();
    if (mode === AppCheckMode.UNCHECK) {
      return BaseFuncProxy.UNCHECK_ACCOUNT;
    } else if (mode === AppCheckMode.CUSTOM) {
      const customAppId = SPUtils.getString('customize_appId', '');
      const customAppKey = SPUtils.getString('customize_appKey', '');
      if (customAppId.length > 0 && customAppKey.length > 0) {
        return new Account(customAppId, customAppKey);
      }
    }
    return BaseFuncProxy.STRICT_ACCOUNT;
  }

  /**
   * 获取当前帐号检查模式
   */
  static getAppCheckMode(): number {
    return SPUtils.getInt('appCheckMode', 0);
  }

  /**
   * 设置帐号检查模式
   */
  static setAppCheckMode(appCheckMode: number): void {
    SPUtils.setInt('appCheckMode', appCheckMode);
  }

  /**
   * 获取自定义 AppId
   */
  static getCustomAppId(): string {
    return SPUtils.getString('customize_appId', '');
  }

  /**
   * 获取自定义 AppKey
   */
  static getCustomAppKey(): string {
    return SPUtils.getString('customize_appKey', '');
  }

  /**
   * 设置自定义 AppId 和 AppKey
   */
  static setAppIdAndAppKey(appId: string, appKey: string): void {
    SPUtils.setString('customize_appId', appId);
    SPUtils.setString('customize_appKey', appKey);
  }

  /**
   * 应用自定义 AppId/AppKey 到 Global
   * 仅在自定义模式下有效
   */
  static applyCustomAccount(): void {
    const appId = BaseFuncProxy.getCustomAppId();
    const appKey = BaseFuncProxy.getCustomAppKey();
    if (appId.length > 0) {
      Global.opiAppId = appId;
    }
    if (appKey.length > 0) {
      Global.opiAppKey = appKey;
    }
  }

  /**
   * 获取微信 AppID
   */
  static getWxAPPID(): string {
    return 'wx85d9b008252f26b5';
  }

  /**
   * 获取 MatchID
   */
  static getMatchID(): string {
    return '95B26A42074C906A';
  }
  /**
   * 获取 QQ AppID
   */
  static getQQAPPID(): string {
    return '101834739';
  }

  /**
   * 获取渠道 ID
   */
  static getChannelId(): string {
    return Global.channelId;
  }

  /**
   * 初始化调试环境配置
   * 从 SPUtils 读取持久化的调试设置并应用到 Global
   *
   * 对应 Android 中 BaseFuncProxy.initDebug()
   */
  static initDebug(isDebug: boolean): void {
    Global.isTestEnv = SPUtils.getBool('isTestEnv', false);
    Global.isPreReleaseEnv = SPUtils.getBool('isPreReleaseEnv', false);
    // TODO(chezijian): 鸿蒙侧 Global.isWnsTestEnv 不存在
    // Global.isWnsTestEnv = SPUtils.getBool('isWnsTestEnv', false);
    Global.curDomain = SPUtils.getString('curDomain', '');
    Global.meshDevops = SPUtils.getString('devopsName', '');
    Global.enableHttpDns = SPUtils.getBool('enableHttpDns', true) ? null : false;
    Global.isDebug = isDebug;
    Global.channelId = SPUtils.getString('DemoChannelId', '');
  }
}
