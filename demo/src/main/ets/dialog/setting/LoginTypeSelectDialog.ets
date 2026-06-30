import { AuthType } from '@qqmusic/opisdk-entity';

/**
 * 登录方式选择对话框
 * 用于"测试小票过期"功能，让用户选择一种登录方式
 */
@CustomDialog
export struct LoginTypeSelectDialog {
  controller: CustomDialogController;
  onSelect?: (authType: AuthType) => void;
  private authTypes: AuthType[] = AuthType.values();

  build() {
    Column() {
      Text('选择登录方式').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 12 })

      ForEach(this.authTypes, (authType: AuthType) => {
        Column() {
          Row() {
            Text(authType.desc).fontSize(16).padding({ left: 16, top: 14, bottom: 14 })
          }
          .width('100%')
          .onClick(() => {
            this.controller.close();
            if (this.onSelect) this.onSelect(authType);
          })
          Divider().height(0.5).color('#EEEEEE')
        }
      })

      Button('取消')
        .margin({ top: 8 }).width('100%')
        .backgroundColor('#F0F0F0').fontColor('#333333')
        .onClick(() => this.controller.close())
    }
    .padding(20)
    .backgroundColor(Color.White)
  }
}
