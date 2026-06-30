import { ClipboardUtils } from '../../utils/ClipboardUtils'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { CommonWebPageParams } from '../../nav/RouteParams'

/**
 * 购买二维码弹窗组件
 * 对应 Android 的 MvBuyQRDialog
 */
@ComponentV2
export struct MVBuyQRDialog {
  @Param qrCodeContent: string = ''
  @Event onDismiss: () => void = () => {}
  @Consumer('navController') navController: NavController = NavController.getInstance()

  build() {
    // 半透明遮罩
    Column() {
      Column({ space: 12 }) {
        // 标题
        Text('二维码展示')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .padding({ top: 16, left: 16, right: 16 })
          .width('100%')
          .textAlign(TextAlign.Center)

        // 提示
        Text('p.s. 点击二维码查看链接')
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .textAlign(TextAlign.Center)

        // 二维码占位区域
        Column() {
          // 使用 QRCode 组件生成二维码
          QRCode(this.qrCodeContent)
            .width(200)
            .height(200)
            .color('#000000')
            .backgroundColor('#FFFFFF')
        }
        .width(220)
        .height(220)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .border({ width: 1, color: '#E0E0E0', radius: 8 })
        .onClick(() => {
          // 点击显示链接详情
          this.showLinkDialog()
        })

        // 链接文本
        Text(this.qrCodeContent)
          .fontSize(11)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .padding({ left: 16, right: 16 })
          .textAlign(TextAlign.Center)

        Divider()
          .width('100%')
          .height(0.5)
          .color('#E0E0E0')

        // 按钮行
        Row({ space: 0 }) {
          // 复制链接
          Button('复制链接')
            .fontSize(14)
            .layoutWeight(1)
            .height(44)
            .type(ButtonType.Normal)
            .backgroundColor(Color.White)
            .fontColor('#007AFF')
            .onClick(() => {
              ClipboardUtils.copy(this.qrCodeContent, '链接')
              this.onDismiss()
            })

          Divider()
            .width(0.5)
            .height(44)
            .color('#E0E0E0')

          // 打开网页
          Button('打开网页')
            .fontSize(14)
            .layoutWeight(1)
            .height(44)
            .type(ButtonType.Normal)
            .backgroundColor(Color.White)
            .fontColor('#007AFF')
            .onClick(() => {
              const params = new CommonWebPageParams(this.qrCodeContent, '购买链接')
              this.navController.push(RouteName.COMMON_WEB_PAGE, params)
              this.onDismiss()
            })
        }
        .width('100%')

        // 取消按钮
        Button('关闭')
          .fontSize(14)
          .width('100%')
          .height(44)
          .type(ButtonType.Normal)
          .backgroundColor(Color.White)
          .fontColor('#FF3B30')
          .onClick(() => {
            this.onDismiss()
          })
      }
      .width('80%')
      .borderRadius(12)
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .onClick(() => {
      this.onDismiss()
    })
  }

  /**
   * 显示链接详情对话框
   */
  private showLinkDialog(): void {
    AlertDialog.show({
      title: '链接',
      message: this.qrCodeContent,
      confirm: {
        value: '确定',
        fontColor: '#007AFF',
        action: () => {}
      }
    })
  }
}
