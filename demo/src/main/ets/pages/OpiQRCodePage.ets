import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import { AuthType } from '@qqmusic/opisdk-entity'
import { NavController } from '../nav/NavController'
import { KeyValueParams } from '../nav/RouteParams'
import { ToastUtil } from '../utils/ToastUtil'

@ComponentV2
export struct OpiQRCodePage {
  navController: NavController = NavController.getInstance()
  @Local tips: string = '二维码加载中...'
  @Local showRefreshBtn: boolean = false
  @Local showQrCode: boolean = false
  @Local isLoading: boolean = true
  @Local QRCodeUrl: string = ''
  private devName: string = ''
  private timerId: number = -1
  private isDestroyed: boolean = false
  private readonly POLL_INTERVAL = 3000
  private readonly ERROR_EXPIRE = -10
  private readonly ERROR_NO_SCAN = -11
  private readonly ERROR_SCAN_SUC = -19
  private readonly ERROR_CANCEL = -14
  private readonly ERROR_BIND_ACCOUNT = -22
  private readonly TAG = 'TestLogin';

  aboutToAppear() {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as KeyValueParams
      if (raw) {
        this.devName = raw.KEY_DEV_NAME
      } else {
        this.devName = 'Unknown'
      }
    } else {
      this.devName = 'Unknown'
    }
    this.startGetQrCode()
  }

  aboutToDisappear() {
    this.isDestroyed = true
    if (this.timerId !== -1) {
      clearTimeout(this.timerId)
    }
  }

  startGetQrCode() {
    this.isLoading = true
    this.showQrCode = false
    this.showRefreshBtn = false
    this.tips = '二维码加载中...'

    MLog.i(this.TAG, "OpiQRCodePage: startGetQrCode 开始执行");

    if (!OpenApiSdk) {
      MLog.e(this.TAG, "OpiQRCodePage: OpenApiSdk 是 undefined!");
      this.showTips("SDK未加载", true);
      return;
    }
    if (!OpenApiSdk.loginApi) {
      MLog.e(this.TAG, "OpiQRCodePage: OpenApiSdk.loginApi 是 undefined!");
      this.showTips("Login模块未初始化", true);
      return;
    }

    const safetyTimer = setTimeout(() => {
      if(this.isLoading) {
        MLog.e(this.TAG, "OpiQRCodePage: UI 兜底超时触发");
        this.showTips("加载超时，请点击刷新", true);
        this.isLoading = false;
      }
    }, 8000);

    OpenApiSdk.loginApi.loginManager.getLoginQrCode(this.devName).then((data) => {
      clearTimeout(safetyTimer);
      MLog.i(this.TAG, `OpiQRCodePage: 收到回调 result=${data.isSuccess()}`);

      if (this.isDestroyed) return;
      this.isLoading = false

      if (data.isSuccess() && data.data) {
        this.QRCodeUrl = data.data.qrCode!
        MLog.i(this.TAG, `OpiQRCodePage: 设置二维码 URL=${this.QRCodeUrl}`);
        this.showQrCodeLogic()
        this.requestQrCodeAuthResult(data.data.authCode!)
      } else {
        MLog.w(this.TAG, `OpiQRCodePage: 获取失败 ${data.errorMsg}`);
        this.showTips(data.errorMsg || "二维码加载失败", true)
      }
    })
  }


  showQrCodeLogic() {
    this.showQrCode = true
    this.showRefreshBtn = false
    this.tips = '使用QQ或者微信扫描下方二维码'
  }

  requestQrCodeAuthResult(pollAuthCode: string) {
    if (this.isDestroyed) {
      return
    }

    MLog.i(this.TAG, `OpiQRCodePage: 开始轮询 authCode=${pollAuthCode}`)

    OpenApiSdk.loginApi?.loginManager.pollQrCodeLoginResult(pollAuthCode).then(async (res) => {
      if (this.isDestroyed) return;

      if (res.isSuccess()) {
        MLog.i(this.TAG, `OpiQRCodePage: 扫码绑定成功, authCode=${res.data}`)
        await OpenApiSdk.loginApi?.loginManager.onGetAuthCode(AuthType.QRCode, res.data ?? '')
        ToastUtil.show("登录成功");
        this.navController.pop()
      } else {
        if (res.ret === this.ERROR_EXPIRE) {
          this.showExpire()
        } else if (res.ret == this.ERROR_NO_SCAN || res.ret == this.ERROR_SCAN_SUC) {
          if (res.ret == this.ERROR_SCAN_SUC) {
            this.tips = "扫码成功，请在手机上确认";
          }

          this.timerId = setTimeout(() => {
            this.requestQrCodeAuthResult(pollAuthCode)
          }, this.POLL_INTERVAL)

        } else if (res.ret === this.ERROR_BIND_ACCOUNT) {
          this.showTips("绑定账户失败", true)
        } else {
          MLog.w(this.TAG, `OpiQRCodePage: 轮询中 error=${res.errorMsg}, ret=${res.ret}`)
          this.timerId = setTimeout(() => {
            this.requestQrCodeAuthResult(pollAuthCode)
          }, this.POLL_INTERVAL)
        }
      }
    })
  }

  showExpire() {
    this.showTips('二维码已过期，请刷新', true)
    this.showQrCode = false
  }

  showTips(msg: string, needBtn: boolean) {
    this.showQrCode = false
    this.tips = msg
    this.showRefreshBtn = needBtn
  }

  build() {
    NavDestination() {
    Column() {
      Row() {
        Image($r('app.media.icon_back_placeholder'))
          .width(26)
          .height(26)
          .margin({ left: 10, top: 10 })
          .onClick(() => this.navController.pop())

        Text('扫码登录')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16, top: 10 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Top)

      // 内容区
      Column() {
        Text(this.tips)
          .fontSize(16)
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 15 })

        Stack() {
          if (this.showQrCode && this.QRCodeUrl) {
            QRCode(this.QRCodeUrl)
              .width(300)
              .height(300)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
          } else {
            Column() {
              if (this.isLoading) {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color('#007DFF')
              }
              if (!this.isLoading && !this.showQrCode) {
                Image($r('app.media.startIcon'))
                  .width(48)
                  .height(48)
              }
            }
            .width(300)
            .height(300)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
          }
        }
        .width(300)
        .height(300)

        if (this.showRefreshBtn) {
          Button('刷新', { type: ButtonType.Normal })
            .width(120)
            .height(40)
            .fontSize(16)
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .margin({ top: 20 })
            .onClick(() => {
              this.startGetQrCode()
            })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .padding({ bottom: 40 })
    }
    .hideTitleBar(true)
  }
}

@Builder
export function OpiQRCodePageBuilder(params: Object) {
  OpiQRCodePage()
}