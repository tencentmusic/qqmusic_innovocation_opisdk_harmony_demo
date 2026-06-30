import { ClipboardUtils } from '../../utils/ClipboardUtils';

/**
 * 可复制信息项组件
 * 点击内容文本即可复制到剪贴板
 */
@ComponentV2
export struct CopyableItem {
  @Param title: string = '';
  @Param content: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .padding({ left: 16, top: 10 })

      Text(this.content)
        .fontSize(14)
        .fontColor('#666666')
        .padding({ left: 16, right: 16, top: 4 })
        .onClick(() => ClipboardUtils.copy(this.content, this.title))
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderWidth({ bottom: 0.5 })
    .borderColor('#EEEEEE')
    .padding({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }
}
