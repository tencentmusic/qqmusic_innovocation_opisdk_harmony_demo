import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'

/**
 * 添加歌曲对话框
 * 通过输入歌曲ID（逗号分隔）批量添加歌曲到当前歌单
 */
@ComponentV2
export struct AddSongDialog {
  @Consumer('viewModel') viewModel: SongListViewModel = new SongListViewModel()

  build() {
    Column({ space: 8 }) {
      Text('添加歌曲到当前歌单')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Text(`folderId=${this.viewModel.currentListId}`)
        .fontSize(11)
        .fontColor(Color.Gray)

      TextInput({ placeholder: '请输入songId,多个以英文逗号分隔', text: this.viewModel.addSongInputText })
        .width('100%')
        .height(40)
        .fontSize(13)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        .onChange((value: string) => {
          this.viewModel.addSongInputText = value
        })

      Row({ space: 8 }) {
        Button('取消')
          .fontSize(12)
          .height(28)
          .backgroundColor('#D9D9D9')
          .fontColor('#333333')
          .borderRadius(14)
          .onClick(() => {
            this.viewModel.toggleAddSongDialog()
          })

        Button('确认添加')
          .fontSize(12)
          .height(28)
          .backgroundColor('#1890FF')
          .fontColor(Color.White)
          .borderRadius(14)
          .onClick(() => {
            this.viewModel.addSongsByIds()
          })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .margin({ left: 16, right: 16, bottom: 8 })
    .borderRadius(8)
  }
}
