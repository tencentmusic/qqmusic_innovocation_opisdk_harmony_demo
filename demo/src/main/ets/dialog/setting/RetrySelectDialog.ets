/**
 * 重试策略选择对话框
 * 对应 Android 中 MyMultiSelectDialog 在 OtherScreen 中的使用场景
 */
@CustomDialog
export struct RetrySelectDialog {
  controller: CustomDialogController;
  onSelect?: (option: string) => void;
  private options: string[] = ['列表重试', '不重试', '重试n次', '自定义'];

  build() {
    Column() {
      Text('选择重试策略')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      ForEach(this.options, (option: string) => {
        Column() {
          Row() {
            Text(option)
              .fontSize(16)
              .padding({ left: 16, top: 14, bottom: 14 })
          }
          .width('100%')
          .onClick(() => {
            this.controller.close();
            if (this.onSelect) {
              this.onSelect(option);
            }
          })

          Divider().height(0.5).color('#EEEEEE')
        }
      })

      Button('取消')
        .margin({ top: 8 })
        .width('100%')
        .backgroundColor('#F0F0F0')
        .fontColor('#333333')
        .onClick(() => {
          this.controller.close();
        })
    }
    .padding(20)
    .backgroundColor(Color.White)
  }
}
