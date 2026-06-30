import { ToastUtil } from '../../utils/ToastUtil';

/**
 * 重试次数输入对话框
 * 对应 Android OtherScreen 中输入 retryNumber 的 Dialog
 */
@CustomDialog
export struct RetryInputDialog {
  controller: CustomDialogController;
  @State inputValue: string = '';
  onConfirm?: (value: number) => void;

  build() {
    Column() {
      Text('请输入重试次数')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      TextInput({ text: this.inputValue, placeholder: '请输入数字' })
        .type(InputType.Number)
        .fontSize(16)
        .onChange((value: string) => {
          this.inputValue = value
        })
        .margin({ bottom: 16 })

      Row({ space: 12 }) {
        Button('取消')
          .fontColor('#333333')
          .backgroundColor('#F0F0F0')
          .onClick(() => {
            this.controller.close();
          })
        Button('确认')
          .onClick(() => {
            const num = parseInt(this.inputValue);
            if (isNaN(num)) {
              ToastUtil.show('请输入数字');
            } else {
              this.controller.close();
              if (this.onConfirm) {
                this.onConfirm(num);
              }
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .padding(20)
    .backgroundColor(Color.White)
  }
}
