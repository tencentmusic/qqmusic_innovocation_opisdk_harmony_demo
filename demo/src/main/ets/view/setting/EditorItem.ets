import { ClipboardUtils } from '../../utils/ClipboardUtils';

/**
 * 可编辑信息项组件
 * 点击 ✎ 图标触发编辑，点击内容文本可复制
 */
@ComponentV2
export struct EditorItem {
  @Param title: string = '';
  @Param content: string = '';
  @Event onEdit?: () => void;

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text('✎')
          .fontSize(18)
          .fontColor('#999999')
          .margin({ left: 8 })
          .onClick(() => {
            if (this.onEdit) {
              this.onEdit();
            }
          })
      }
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
