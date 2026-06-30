import { GalleryImageUtil, PickImageAddr } from "../utils/GalleryImageUtil";

@CustomDialog
export struct CreatFolderDialog {
  controller: CustomDialogController;
  @State folderName: string = "";
  @State imagePath: string = "";

  confirmAction: (name: string,imagePath:string) => void = () => {
  };

  build() {
    Column() {
      TextInput({ placeholder: '输入歌单名字', text: this.folderName })
        .onChange((value) => this.folderName = value)
        .width('100%')
        .margin({ bottom: 20 })

      Text( this.imagePath === "" ? '选择图片' : this.imagePath)
        .width('100%')
        .margin({ bottom: 20 })
        .onClick(async () => {
          try {
            let  addr: PickImageAddr = await GalleryImageUtil.pickOneImage()
            addr = await GalleryImageUtil.exportPhotoUriToCache(addr.photoUri)
            this.imagePath = addr.cachePath ?? ''
          } catch (e) {
          }
        })

      Row() {
        Button('取消')
          .onClick(() => this.controller.close())
          .backgroundColor(Color.White)
          .fontColor(Color.Black)
          .layoutWeight(1)

        Button('确定')
          .onClick(() => {
            if (this.folderName.length > 0) {
              this.confirmAction(this.folderName,this.imagePath);
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