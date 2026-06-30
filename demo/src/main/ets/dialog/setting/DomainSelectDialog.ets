/**
 * 域名选择对话框
 */
@CustomDialog
export struct DomainSelectDialog {
  controller: CustomDialogController;
  onSelect?: (domain: string) => void;
  private domains: string[] = ['正式域名', '深圳域名', '上海域名'];

  build() {
    Column() {
      Text('切换域名').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 12 })

      ForEach(this.domains, (domain: string) => {
        Column() {
          Row() {
            Text(domain).fontSize(16).padding({ left: 16, top: 14, bottom: 14 })
          }
          .width('100%')
          .onClick(() => {
            this.controller.close();
            if (this.onSelect) this.onSelect(domain);
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
