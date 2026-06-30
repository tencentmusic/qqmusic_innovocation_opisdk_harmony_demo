import { ToastUtil } from '../../utils/ToastUtil';

/**
 * 超时配置对话框
 * 对应 Android 中 NetworkTimeoutDialog Composable
 */
@CustomDialog
export struct TimeoutConfigDialog {
  controller: CustomDialogController;
  @State readTimeout: string = '';
  @State writeTimeout: string = '';
  @State connectTimeout: string = '';
  @State callTimeout: string = '';

  build() {
    Column() {
      Text('设置接口超时时间')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      TextInput({ text: this.readTimeout, placeholder: '请输入readTimeout(秒)' })
        .type(InputType.Number)
        .fontSize(14)
        .onChange((v: string) => {
          this.readTimeout = v
        })
        .margin({ bottom: 8 })

      TextInput({ text: this.writeTimeout, placeholder: '请输入writeTimeout(秒)' })
        .type(InputType.Number)
        .fontSize(14)
        .onChange((v: string) => {
          this.writeTimeout = v
        })
        .margin({ bottom: 8 })

      TextInput({ text: this.connectTimeout, placeholder: '请输入connectTimeout(秒)' })
        .type(InputType.Number)
        .fontSize(14)
        .onChange((v: string) => {
          this.connectTimeout = v
        })
        .margin({ bottom: 8 })

      TextInput({ text: this.callTimeout, placeholder: '请输入callTimeout(秒)' })
        .type(InputType.Number)
        .fontSize(14)
        .onChange((v: string) => {
          this.callTimeout = v
        })
        .margin({ bottom: 16 })

      Row({ space: 12 }) {
        Button('取消')
          .fontColor('#333333')
          .backgroundColor('#F0F0F0')
          .onClick(() => {
            this.controller.close();
          })
        Button('设置')
          .onClick(() => {
            // TODO: 调用 SDK 接口设置超时  NetworkTimeoutConfig
            ToastUtil.show('暂不支持设置接口超时时间');
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .padding(20)
    .backgroundColor(Color.White)
  }
}
