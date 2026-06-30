import { ToastUtil } from "../utils/ToastUtil";

@CustomDialog
export struct PhoneLoginDialog {
  controller: CustomDialogController;
  @State phoneNum: string = "";
  @State verifyCode: string = "";

  build() {
    Column() {
      TextInput({ placeholder: '输入11位手机号', text: this.phoneNum })
        .type(InputType.PhoneNumber)
        .onChange((value) => this.phoneNum = value)
        .margin({ bottom: 10 })

      Button('获取验证码')
        .onClick(() => {
          ToastUtil.show(`获取验证码: ${this.phoneNum}`);
        })
        .width('100%')
        .margin({ bottom: 10 })

      TextInput({ placeholder: '输入验证码', text: this.verifyCode })
        .type(InputType.Number)
        .onChange((value) => this.verifyCode = value)
        .margin({ bottom: 20 })

      Button('验证码登录')
        .onClick(() => {
          ToastUtil.show('尝试登录...');
          this.controller.close();
        })
        .width('100%')
        .margin({ bottom: 10 })

      Button('取消')
        .onClick(() => this.controller.close())
        .backgroundColor(Color.Gray)
        .width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(10)
  }
}