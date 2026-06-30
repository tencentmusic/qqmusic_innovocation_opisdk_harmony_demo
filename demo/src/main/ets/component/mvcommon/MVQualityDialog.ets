import { IMediaResDetail, MediaQuality, UserIdentity } from '@qqmusic/opisdk-entity'
import { MVPlayerViewModel } from '../../viewmodel/MVPlayerViewModel'

/**
 * 品质选择弹窗组件
 * 对应 Android 的 MediaQualityDialog
 */
@ComponentV2
export struct MVQualityDialog {
  @Param mediaResDetail: IMediaResDetail | null = null
  @Param supportQualityList: MediaQuality[] = []
  @Param currentQuality: MediaQuality = MediaQuality.SQ
  @Event onQualitySelected: (quality: MediaQuality) => void = () => {}
  @Event onDismiss: () => void = () => {}

  // 品质显示顺序（从高到低）
  private qualityOrder: MediaQuality[] = [
    MediaQuality.DOLBY_4K,
    MediaQuality.EXCELLENT,
    MediaQuality.NORMAL_4K,
    MediaQuality.HIGH_1080,
    MediaQuality.BR_1080,
    MediaQuality.SQ,
    MediaQuality.HQ,
    MediaQuality.LQ
  ]

  build() {
    // 半透明遮罩
    Column() {
      Column() {
        // 标题
        Text('选择需要的清晰度')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .padding({ top: 16, bottom: 12, left: 16, right: 16 })
          .width('100%')
          .textAlign(TextAlign.Center)

        Divider()
          .width('100%')
          .height(0.5)
          .color('#E0E0E0')

        // 品质列表
        List() {
          ForEach(this.qualityOrder, (quality: MediaQuality) => {
            ListItem() {
              this.buildQualityItem(quality)
            }
          }, (quality: MediaQuality) => quality.toString())
        }
        .width('100%')
        .constraintSize({ maxHeight: 400 })

        Divider()
          .width('100%')
          .height(0.5)
          .color('#E0E0E0')

        // 取消按钮
        Button('取消')
          .fontSize(15)
          .width('100%')
          .height(44)
          .type(ButtonType.Normal)
          .backgroundColor(Color.White)
          .fontColor('#007AFF')
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

  @Builder
  buildQualityItem(quality: MediaQuality) {
    Row() {
      Column({ space: 2 }) {
        Text(MVPlayerViewModel.getQualityName(quality))
          .fontSize(14)
          .fontColor('#333333')

        // 文件大小
        if (this.mediaResDetail) {
          if (this.getFileSize(quality) !== null) {
            Text(this.formatFileSize(this.getFileSize(quality)!))
              .fontSize(11)
              .fontColor('#999999')
          }
        }

        // 用户身份提示
        if (this.getIdentity(quality).length > 0) {
          Text(`[${this.getIdentity(quality)}]`)
            .fontSize(11)
            .fontColor('#FF6B35')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 当前品质标记
      if (quality === this.currentQuality) {
        Text('✓')
          .fontSize(16)
          .fontColor('#007AFF')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => {
      this.onQualitySelected(quality)
    })
  }

  getFileSize(quality: MediaQuality): number | null {
    const size = this.mediaResDetail?.getQualitySize(quality)
    return size ?? null;
  }

  getIdentity(quality: MediaQuality): string {
    const identity = this.getUserIdentityTip(quality)
    return identity;
  }

  /**
   * 获取用户身份提示
   */
  private getUserIdentityTip(quality: MediaQuality): string {
    if (!this.mediaResDetail) {
      return ''
    }
    const identity = this.mediaResDetail.getQualityIdentity(quality)
    switch (identity) {
      case UserIdentity.NORMAL: return '普通'
      case UserIdentity.VIP: return '豪华绿钻'
      case UserIdentity.IOT_VIP: return 'IOT会员'
      case UserIdentity.SUPER_VIP: return '超会'
      case UserIdentity.PAY_FOR_MEDIA: return '购买'
      default: return ''
    }
  }

  /**
   * 格式化文件大小
   */
  private formatFileSize(sizeBytes: number): string {
    if (sizeBytes <= 0) {
      return ''
    }
    const mb = sizeBytes / (1024 * 1024)
    if (mb >= 1) {
      return mb.toFixed(1) + ' MB'
    }
    const kb = sizeBytes / 1024
    return kb.toFixed(0) + ' KB'
  }
}
