import { ToastUtil } from "../utils/ToastUtil";

@CustomDialog
export struct OpenIdLoginDialog {
  controller: CustomDialogController;
  @State openId: string = "";
  @State accessToken: string = "";

  build() {
    Column() {
      TextInput({ placeholder: '请输入OpenId', text: this.openId })
        .onChange((val) => this.openId = val)
        .margin({ bottom: 10 })

      TextInput({ placeholder: '请输入AccessToken', text: this.accessToken })
        .onChange((val) => this.accessToken = val)
        .margin({ bottom: 20 })

      Button('登录')
        .onClick(() => {
          ToastUtil.show(`OpenID登录: ${this.openId}`);
          this.controller.close();
        })
        .width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(10)
  }
}