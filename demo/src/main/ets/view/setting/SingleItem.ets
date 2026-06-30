/**
 * 设置页面通用单项组件 (V2装饰器版本)
 * 对应 AppSettingScreen.kt 中的 SingleItem Composable
 *
 * 布局结构: [title] ---- [item文本] [>箭头]
 * - title: 左侧标题文字
 * - item: 右侧描述文字（可选，为空则不显示）
 * - 右侧固定显示箭头图标
 */
@ComponentV2
export struct SingleItem {
  @Param title: string = ''
  @Param item: string = ''
  @Event onItemClick?: () => void

  build() {
    Row() {
      // 左侧标题
      Text(this.title)
        .fontSize(16)
        .fontColor('#333333')

      Blank()

      // 右侧描述文字
      if (this.item.length > 0) {
        Text(this.item)
          .fontSize(14)
          .fontColor('#E6000000')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ right: 5 })
      }

      // 右侧箭头图标
      Image($r('app.media.icon_right_arrow_placeholder'))
        .width(16)
        .height(16)
        .margin({ right: 10 })
    }
    .width('100%')
    .height(60)
    .padding({ left: 20 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick()
      }
    })
  }
}
