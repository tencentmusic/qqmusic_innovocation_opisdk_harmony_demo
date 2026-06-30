import { BaseFuncProxy } from '../../utils/BaseFuncProxy';

const APP_CHECK_MODE_LIST: string[] = ['严格模式', '无检查模式', '自定义模式'];
/**
 * 切换帐号检查模式对话框
 * 对应 Android 中 MyMultiSelectDialogN (appCheckModeList)
 *
 * 严格模式: 使用 SDK 初始化时配置的 appId/appKey
 * 无检查模式: 清空自定义 appId/appKey
 * 自定义模式: 用户输入自定义 appId/appKey
 */
@CustomDialog
export struct AppCheckModeSelectDialog {
  controller: CustomDialogController;
  @State selectedOption: string = APP_CHECK_MODE_LIST[BaseFuncProxy.getAppCheckMode()];
  @State customAppId: string = BaseFuncProxy.getCustomAppId();
  @State customAppKey: string = BaseFuncProxy.getCustomAppKey();

  build() {
    Column() {
      Text('选择应用ID模式')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      ForEach(APP_CHECK_MODE_LIST, (option: string) => {
        Column() {
          Row() {
            Radio({ value: option, group: 'appCheckMode' })
              .checked(this.selectedOption === option)
            Text(option)
              .fontSize(16)
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ left: 16, top: 10, bottom: 10 })
          .onClick(() => {
            this.selectedOption = option;
          })
          Divider().height(0.5).color('#EEEEEE')
        }
      })

      if (this.selectedOption === '自定义模式') {
        Column() {
          TextInput({ text: this.customAppId, placeholder: '请输入AppId' })
            .fontSize(14)
            .margin({ top: 8, bottom: 8 })
            .onChange((v: string) => { this.customAppId = v })

          TextInput({ text: this.customAppKey, placeholder: '请输入AppKey' })
            .fontSize(14)
            .margin({ bottom: 12 })
            .onChange((v: string) => { this.customAppKey = v })
        }
        .width('100%')
      }

      Row({ space: 12 }) {
        Button('取消')
          .onClick(() => this.controller.close())
        Button('确认')
          .onClick(() => {
            const modeIndex = APP_CHECK_MODE_LIST.indexOf(this.selectedOption);
            BaseFuncProxy.setAppCheckMode(modeIndex);
            if (this.selectedOption === '自定义模式') {
              BaseFuncProxy.setAppIdAndAppKey(this.customAppId, this.customAppKey);
              BaseFuncProxy.applyCustomAccount();
            } else {
              // 严格模式/无检查模式：清空自定义配置
              BaseFuncProxy.setAppIdAndAppKey('', '');
            }

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
