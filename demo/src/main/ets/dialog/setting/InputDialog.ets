import { MMKVHelper } from '@qqmusic/opisdk-qmutils';

/**
 * 通用输入对话框
 * 对应 Android 中 logFileDir / sessionActivity 输入 Dialog
 */
@CustomDialog
export struct InputDialog {
  controller: CustomDialogController;
  @State inputValue: string = '';
  title: string = '';
  hint: string = '';
  prefKey: string = '';
  onConfirm?: (value: string) => void;

  aboutToAppear(): void {
    try {
      this.inputValue = MMKVHelper.getMMKV('OpenApiSDKEnv').decodeString(this.prefKey) ?? '';
    } catch (_e) {
      this.inputValue = '';
    }
  }

  build() {
    Column() {
      Text(this.title).fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 12 })

      TextInput({ text: this.inputValue, placeholder: this.hint })
        .fontSize(14)
        .onChange((v: string) => { this.inputValue = v })
        .margin({ bottom: 16 })

      Row({ space: 12 }) {
        Button('取消')
          .onClick(() => this.controller.close())
        Button('确定')
          .onClick(() => {
            MMKVHelper.getMMKV('OpenApiSDKEnv').encodeString(this.prefKey, this.inputValue);
            this.controller.close();
            if (this.onConfirm) this.onConfirm(this.inputValue);
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .padding(20)
    .backgroundColor(Color.White)
  }
}
