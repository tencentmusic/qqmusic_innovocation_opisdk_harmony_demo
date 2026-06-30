/**
 * 二维码短链弹窗
 * 对应 Android MvBuyQRDialog.showQRCodeDialog
 * 展示支付二维码，支持过期倒计时
 */
@CustomDialog
export struct QrCodeShortLinkDialog {
  controller: CustomDialogController;
  payUrl: string = '';
  expireSeconds: number | null = null;
  expireTs: number | null = null;
  @State showDetail: boolean = false;
  @State countdownText: string = '';
  private timerId: number = -1;
  private isDestroyed: boolean = false;

  aboutToAppear(): void {
    if (this.expireSeconds && this.expireSeconds > 0) {
      this.startCountdown(this.expireSeconds);
    }
  }

  aboutToDisappear(): void {
    this.isDestroyed = true;
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
    }
  }

  private startCountdown(seconds: number): void {
    let remaining = seconds;
    const tick = () => {
      if (this.isDestroyed) return;
      if (remaining <= 0) {
        this.countdownText = '收银台链接已过期';
        return;
      }
      const min = Math.floor(remaining / 60);
      const sec = remaining % 60;
      this.countdownText = `二维码有效期：${min}分${sec}秒`;
      remaining--;
      this.timerId = setTimeout(tick, 1000);
    };
    tick();
  }

  private formatExpireTime(ts: number): string {
    const date = new Date(ts * 1000);
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const d = date.getDate().toString().padStart(2, '0');
    const h = date.getHours().toString().padStart(2, '0');
    const min = date.getMinutes().toString().padStart(2, '0');
    const s = date.getSeconds().toString().padStart(2, '0');
    return `${y}-${m}-${d} ${h}:${min}:${s}`;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('扫码支付')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Image($r('sys.media.ohos_ic_public_close'))
          .fillColor(Color.Black)
          .width(28)
          .height(28)
          .onClick(() => this.controller.close())
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 16, bottom: 8 })

      // 二维码
      if (this.payUrl) {
        QRCode(this.payUrl)
          .width(200)
          .height(200)
          .margin({ top: 12, bottom: 12 })
          .onClick(() => {
            // 点击二维码切换详情展示
            this.showDetail = !this.showDetail;
          })
      }

      // 倒计时
      if (this.countdownText) {
        Text(this.countdownText)
          .fontSize(13)
          .fontColor(this.countdownText.includes('过期') ? Color.Red : '#666666')
          .margin({ bottom: 8 })
      }

      // 详情信息（点击二维码后展示）
      if (this.showDetail) {
        Column() {
          if (this.expireSeconds !== null) {
            Text(`收银台链接过期倒计时：${this.expireSeconds}s`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          if (this.expireTs !== null) {
            Text(`收银台链接准确的过期时间：${this.formatExpireTime(this.expireTs)}`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 12 })
      }

      Text('点击二维码查看详情')
        .fontSize(11)
        .fontColor('#BBBBBB')
        .margin({ bottom: 16 })
    }
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding({ bottom: 8 })
  }
}
