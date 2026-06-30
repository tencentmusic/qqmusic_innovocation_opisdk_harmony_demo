import { FolderDialog } from '../../dialog/FolderDialog'
import { ToastUtil } from '../../utils/ToastUtil'

/**
 * 新建歌单区域：点击创建新个人歌单
 */
@ComponentV2
export struct NewFolderSectionView {
  private folderDialogController: CustomDialogController = new CustomDialogController({
    builder: FolderDialog({
      confirmAction: (name: string) => {
        ToastUtil.show(`创建歌单: ${name}`)
      }
    }),
    alignment: DialogAlignment.Center
  })

  build() {
    Row() {
      Image($r('app.media.startIcon'))
        .width(50)
        .height(50)
        .margin(5)
        .onClick(() => this.folderDialogController.open())

      Column() {
        Text("Click to Create New Folder")
        Text("点击创建新个人歌单")
          .fontColor(Color.Gray)
          .fontSize(12)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      .onClick(() => this.folderDialogController.open())
    }
    .width('100%')
    .padding(10)
    .backgroundColor(Color.White)
  }
}
