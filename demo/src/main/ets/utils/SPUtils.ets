import { MLog } from '@qqmusic/opisdk-base';
import { MMKVHelper } from '@qqmusic/opisdk-qmutils';

/**
 * SharedPreferences / MMKV 工具类
 * 封装布尔、整数、字符串的读写操作
 * 使用静态方法，prefName 固定为 'OpenApiSDKEnv'
 */
export class SPUtils {
  private static readonly TAG = "SPUtils";
  private static readonly PREF_NAME: string = 'OpenApiSDKEnv';

  /** 获取布尔值 */
  static getBool(key: string, def: boolean = true): boolean {
    try {
      const val = MMKVHelper.getMMKV(SPUtils.PREF_NAME).decodeBool(key);
      return val ?? def;
    } catch (_e) {
      return def;
    }
  }

  /** 设置布尔值 */
  static setBool(key: string, value: boolean): void {
    try {
      MMKVHelper.getMMKV(SPUtils.PREF_NAME).encodeBool(key, value);
    } catch (_e) {
      MLog.e(SPUtils.TAG, `【setBool】 message = ${_e.message}; code = ${_e.code}`);
    }
  }

  /** 获取整数 */
  static getInt(key: string, def: number = 0): number {
    try {
      const val = MMKVHelper.getMMKV(SPUtils.PREF_NAME).decodeInt64(key);
      return val !== null && val !== undefined ? Number(val) : def;
    } catch (_e) {
      return def;
    }
  }

  /** 设置整数 */
  static setInt(key: string, value: number): void {
    try {
      MMKVHelper.getMMKV(SPUtils.PREF_NAME).encodeInt64(key, BigInt(value));
    } catch (_e) {
      MLog.e(SPUtils.TAG, `【setInt】 message = ${_e.message}; code = ${_e.code}`);
    }
  }

  /** 获取字符串 */
  static getString(key: string, def: string = ''): string {
    try {
      const val = MMKVHelper.getMMKV(SPUtils.PREF_NAME).decodeString(key);
      return val ?? def;
    } catch (_e) {
      return def;
    }
  }

  /** 设置字符串 */
  static setString(key: string, value: string): void {
    try {
      MMKVHelper.getMMKV(SPUtils.PREF_NAME).encodeString(key, value);
    } catch (_e) {
      MLog.e(SPUtils.TAG, `【setString】 message = ${_e.message}; code = ${_e.code}`);
    }
  }
}
