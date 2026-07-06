import { globalEventHandler, MLog, OpenApiSdk } from '@qqmusic/opisdk-base';
import { MMKVHelper } from '@qqmusic/opisdk-qmutils';
import {
  OpenIdInfo, OpenApiResponse, AuthType, IUserInfo, IVipInfo, BaseBusinessEvent, PreferencesConstants, ICheckNeedRenewalInfo, LoginEvent, IOperationsInfo
} from '@qqmusic/opisdk-entity'


@ObservedV2
export class MineViewModel {
  private TAG = "MineViewModel"
  @Trace public userInfo: IUserInfo | null = null
  @Trace public userVipInfo: IVipInfo | null = null
  @Trace public loginInfo: OpenIdInfo | null = null
  @Trace public partnerAccountInfo: string | null = null
  @Trace public limitFree: OpenApiResponse<IOperationsInfo> | null = null
  @Trace public remindRenewalInfo: ICheckNeedRenewalInfo | null = null
  private lastUserUpdateTime: number = 0
  // 是否已完成初始化
  private isInitialized: boolean = false

  constructor() {
  }

  init(): void {
    if (this.isInitialized) {
      return
    }
    this.isInitialized = true
    this.initListener()
  }

  // 注册全局事件监听
  private initListener() {
    globalEventHandler.registerHandler(this)
  }

  // 在页面的 aboutToDisappear 中手动调用此方法以避免内存泄漏
  public onDestroy() {
    globalEventHandler.removeHandler(this)
  }

  /**
   * 实现 BusinessEventHandler 接口的 handle 方法
   * 处理登录、登出、VIP信息变更等事件
   */
  public async handle(event: BaseBusinessEvent): Promise<void> {
    if (event.tag === LoginEvent.EventTag) {
      switch (event.code) {
        case LoginEvent.MusicUserLogIn:
          MLog.d(this.TAG, "Handle Event: MusicUserLogIn")
          await this.updateData()
          break;
        case LoginEvent.MusicAccountAutoLoginIn:
          MLog.d(this.TAG, "Handle Event: MusicAccountAutoLoginIn")
          await this.updateData()
          break;
        case LoginEvent.UserVipInfoUpdate:
          MLog.d(this.TAG, "Handle Event: UserVipInfoUpdate")
          await this.updateData()
          break;
        case LoginEvent.MusicUserLogOut:
          MLog.d(this.TAG, "Handle Event: MusicUserLogOut")
          this.clearData()
          break;
        case LoginEvent.UserDeauthorization:
          MLog.d(this.TAG, "Handle Event: UserDeauthorization")
          this.clearData()
          break;
        case LoginEvent.AcountDeregisterPending:
          MLog.d(this.TAG, "Handle Event: AcountDeregisterPending")
          this.clearData()
          break;
        case LoginEvent.AcountDeregisterDone:
          MLog.d(this.TAG, "Handle Event: AcountDeregisterDone")
          this.clearData()
          break;
        case LoginEvent.UserAccountLoginExpired:
          MLog.d(this.TAG, "Handle Event: UserAccountLoginExpired")
          this.clearData()
          break;
        default:
          break;
      }
    }
  }

  /**
   * 退出登录时清空数据
   */
  public clearData(): void {
    this.userInfo = null
    this.loginInfo = null
    this.userVipInfo = null
    this.partnerAccountInfo = null
    this.remindRenewalInfo = null
    this.limitFree = null
  }

  public async updateData() {
    const currentTime = Date.now()
    if (currentTime - this.lastUserUpdateTime < 100) {
      MLog.d(this.TAG, "updateData too frequent")
      return
    }
    this.lastUserUpdateTime = currentTime

    try {
      // 获取登录态信息
      const currentLoginInfo = OpenApiSdk.loginApi?.getOpenIdInfo() ??
        MMKVHelper.getObject(MMKVHelper.getCommonMMKV(), PreferencesConstants.KEY_OPEN_INFO, null)

      // 如果当前没有登录态，说明在异步过程中已经登出，不再更新 UI
      if (!currentLoginInfo || !currentLoginInfo.openId) {
        MLog.d(this.TAG, "updateData: no valid login state, skip UI update")
        this.clearData()
        return
      }

      this.loginInfo = currentLoginInfo
      // 获取用户信息
      const userResp = await OpenApiSdk.openApi?.userApi.fetchUserInfo()
      // 异步返回后再次检查登录态，防止请求期间已登出
      if (!this.isStillLoggedIn()) {
        MLog.d(this.TAG, "updateData: logged out during fetchUserInfo, skip")
        return
      }
      if (userResp && userResp.isSuccess()) {
        this.userInfo = userResp.data ?? null
      }

      // 获取第三方账号ID
      try {
        const partnerId = OpenApiSdk.openApi?.partnerLogin?.queryThirdPartyAccountID()
        if (!this.isStillLoggedIn()) {
          MLog.d(this.TAG, "updateData: logged out during queryThirdPartyAccountID, skip")
          return
        }
        this.partnerAccountInfo = partnerId ?? null
      } catch (e) {
        MLog.w(this.TAG, "queryThirdPartyAccountID failed or not supported")
      }

      // 获取 VIP 信息
      // 判断是否是第三方独立账号模式
      let isPartnerAccountIndependent =
        MMKVHelper.getObject<boolean>(MMKVHelper.getCommonMMKV(), "accountModePartner", false) ?? false

      if (isPartnerAccountIndependent) {
        const partnerVipResp = await OpenApiSdk.openApi?.userApi.fetchPartnerMemberInformation()
        if (!this.isStillLoggedIn()) {
          MLog.d(this.TAG, "updateData: logged out during fetchPartnerMemberInformation, skip")
          return
        }
        if (partnerVipResp?.isSuccess()) {
          this.userVipInfo = partnerVipResp.data ?? null
        }
      } else {
        const greenVipResp = await OpenApiSdk.openApi?.userApi.fetchGreenMemberInformation()
        if (!this.isStillLoggedIn()) {
          MLog.d(this.TAG, "updateData: logged out during fetchGreenMemberInformation, skip")
          return
        }
        if (greenVipResp?.isSuccess()) {
          this.userVipInfo = greenVipResp.data ?? null
        }
      }

      // 获取限免运营信息
      // try {
      //   const opsResp = await OpenApiSdk.openApi?.operAreaApi?.getOperationsInfo()
      //   if (opsResp) {
      //     this.limitFree = opsResp
      //   }
      // } catch (e) {
      //   MLog.e(this.TAG, "getOperationsInfo failed: " + e)
      // }

    } catch (e) {
      MLog.e(this.TAG, "updateData failed: " + JSON.stringify(e))
    }
  }

  /**
   * 检查当前是否仍然处于登录状态
   * 用于异步操作返回后的登录态校验，防止登出后异步数据覆盖 UI
   */
  private isStillLoggedIn(): boolean {
    const currentLoginInfo = OpenApiSdk.loginApi?.getOpenIdInfo()
    return currentLoginInfo !== null && currentLoginInfo !== undefined && currentLoginInfo.openId.length > 0
  }


  /**
   * 刷新 VIP 续费提醒信息
   */
  public async refreshVipRenewalInfo() {
    try {
      const resp = await OpenApiSdk.openApi?.vipApi?.getVipRenewalInfo()
      if (resp && resp?.isSuccess()) {
        this.remindRenewalInfo = resp.data ?? null
      }
    } catch (e) {
      MLog.e(this.TAG, `refreshVipRenewalInfo failed: ${e}`)
    }
  }

  public getLoginType(openIdInfo: OpenIdInfo | null): string {
    if (!openIdInfo) {
      return "未知"
    }

    switch (openIdInfo.type) {
      case AuthType.QQ:
        return "QQ"
      case AuthType.QQMusic:
        return "QQMusic"
      case AuthType.QRCode:
        return "扫码登录"
      case AuthType.WX:
        return "微信"
      case AuthType.PHONE:
        return "手机"
      case AuthType.PARTNER:
        return "三方帐号登录"
      case AuthType.OPEN_ID:
        return "OpenID登录"
      case AuthType.MUSIC_ID:
        return "MusicID登录"
      case AuthType.LOGIN_TOKEN:
        return "Token登录"
      default:
        return "未知"
    }
  }

  public getVipText(vipInfo: IVipInfo | null): string[] {
    let ret: string[] = []

    let audioVip = ""
    if (vipInfo?.isVip() === false && !vipInfo.isLongAudioVip()) {
      audioVip = "非vip用户"
    } else if (vipInfo?.isSuperVip() === true) {
      audioVip = "超级会员"
    } else if (vipInfo?.getSuperGreenVipFlag() === 1) {
      audioVip = "豪华绿钻"
    } else if (vipInfo?.getGreenVipFlag() === 1) {
      audioVip = "绿钻"
    } else if (vipInfo?.getYearGreenVipFlag() === 1) {
      audioVip = "年费绿钻"
    } else if (vipInfo?.getPartnerVipFlag() === 1) {
      audioVip = "三方独立会员"
    }
    if (audioVip) {
      ret.push(audioVip)
    }

    let payVip = ""
    if (vipInfo?.getTwelveFlag() === 1) {
      payVip = "12元付费包用户"
    } else if (vipInfo?.getEightFlag() === 1) {
      payVip = "8元付费包用户"
    }
    if (payVip) {
      ret.push(payVip)
    }

    if (vipInfo?.getLongAudioVip() === 1) {
      ret.push("听书会员用户")
    }

    if (vipInfo?.getUnionVipFlag() === 1) {
      ret.push("联合会员")
    }

    if (OpenApiSdk.loginApi?.isQQMusicLoginUserSame()) {
      ret.push('Q音手机端登录相同账号')
    }

    if (ret.length === 0) {
      return ["信息获取不明"]
    }
    return ret
  }


  public getVipTimeStartText(vipInfo: IVipInfo | null): string {
    if (vipInfo?.isVip() === false && !vipInfo.isLongAudioVip()) {
      return ""
    } else if (vipInfo?.getUnionVipFlag() === 1) {
      return vipInfo.getUnionVipStartTime() ?? ""
    } else if (vipInfo?.getGreenVipFlag() === 1) {
      return vipInfo.getGreenVipStartTime()
    } else if (vipInfo?.getSuperGreenVipFlag() === 1) {
      return vipInfo.getSuperGreenVipStartTime()
    } else if (vipInfo?.getHugeVipFlag() === 1) {
      return vipInfo.getHugeVipStartTime()
    } else if (vipInfo?.getYearGreenVipFlag() === 1) {
      return vipInfo.getGreenVipStartTime()
    } else if (vipInfo?.getTwelveFlag() === 1) {
      return vipInfo.getTwelveStartTime()
    } else if (vipInfo?.getEightFlag() === 1) {
      return vipInfo.getEightStartTime()
    } else if (vipInfo?.getLongAudioVip() === 1) {
      return vipInfo.getLongAudioVipStartTime()
    } else if (vipInfo?.getPartnerVipFlag() === 1) {
      return vipInfo.getPartnerVipStartTime()
    } else {
      return "信息获取不明"
    }
  }

  public getVipEndTimeText(vipInfo: IVipInfo | null): string {
    if (vipInfo?.isVip() === false && !vipInfo.isLongAudioVip()) {
      return ""
    } else if (vipInfo?.getUnionVipFlag() === 1) {
      return vipInfo.getUnionVipEndTime() ?? ""
    } else if (vipInfo?.getGreenVipFlag() === 1) {
      return vipInfo.getGreenVipEndTime()
    } else if (vipInfo?.getSuperGreenVipFlag() === 1) {
      return vipInfo.getSuperGreenVipEndTime()
    } else if (vipInfo?.getHugeVipFlag() === 1) {
      return vipInfo.getHugeVipEndTime()
    } else if (vipInfo?.getYearGreenVipFlag() === 1) {
      return vipInfo.getGreenVipEndTime()
    } else if (vipInfo?.getTwelveFlag() === 1) {
      return vipInfo.getTwelveEndTime()
    } else if (vipInfo?.getEightFlag() === 1) {
      return vipInfo.getEightEndTime()
    } else if (vipInfo?.getLongAudioVip() === 1) {
      return vipInfo.getLongAudioVipEndTime()
    } else if (vipInfo?.getPartnerVipFlag() === 1) {
      return vipInfo.getPartnerVipEndTime()
    } else {
      return "信息获取不明"
    }
  }


  public getLimitFreeInfo(operationsInfoResp: OpenApiResponse<IOperationsInfo> | null): string {
    if (!operationsInfoResp || !operationsInfoResp.data) {
      return `接口异常, ${operationsInfoResp?.errorMsg ?? ''}`;
    }
    const info = operationsInfoResp.data;
    switch (info.getNewLoginFreeListenState()) {
      case 0:
        return "未登录";
      case 1:
        return "未领取";
      case 2:
        return `生效中,${this.convertSecondsToTimeFormat(info.getNewLoginFreeListenRemainSec())}`;
      case 3:
        return "已过期";
      default:
        return `${info.getNewLoginFreeListenState()}-未知状态`;
    }
  }

  private convertSecondsToTimeFormat(sec: number): string {
    const days = Math.floor(sec / 86400);
    const hours = Math.floor((sec % 86400) / 3600);
    const minutes = Math.floor((sec % 3600) / 60);
    const seconds = Math.floor(sec % 60);

    let timeFormat = "";
    if (days > 0) {
      timeFormat += `${days}天`;
    }
    if (hours > 0) {
      timeFormat += `${hours.toString().padStart(2, '0')}h`;
    }
    if (minutes > 0) {
      timeFormat += `${minutes.toString().padStart(2, '0')}m`;
    }
    if (seconds > 0) {
      timeFormat += `${seconds.toString().padStart(2, '0')}s`;
    }

    return timeFormat;
  }

  public logout() {
    MLog.i(this.TAG, "logout")
    OpenApiSdk.loginApi?.logout()
  }
}