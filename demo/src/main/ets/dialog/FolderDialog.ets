@CustomDialog
export struct FolderDialog {
  controller: CustomDialogController;
  @State folderName: string = "";
  confirmAction: (name: string) => void = () => {
  };

  build() {
    Column() {
      TextInput({ placeholder: '输入歌单名字', text: this.folderName })
        .onChange((value) => this.folderName = value)
        .width('100%')
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .onClick(() => this.controller.close())
          .backgroundColor(Color.White)
          .fontColor(Color.Black)
          .layoutWeight(1)

        Button('确定')
          .onClick(() => {
            if (this.folderName.length > 0) {
              this.confirmAction(this.folderName);
              this.controller.close();
            }
          })
          .layoutWeight(1)
          .margin({ left: 10 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(10)
  }
}