import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'

/**
 * 多选编辑操作栏
 * 包含：全选 checkbox + 删除选中 + 添加到播放列表
 */
@ComponentV2
export struct EditorBar {
  @Consumer('viewModel') viewModel: SongListViewModel = new SongListViewModel()

  build() {
    Row({ space: 8 }) {
      Toggle({ type: ToggleType.Checkbox, isOn: this.viewModel.isAllSelected })
        .onChange((value: boolean) => {
          if (value !== this.viewModel.isAllSelected) {
            this.viewModel.toggleSelectAll()
          }
        })
      Text('全选')
        .fontSize(12)
        .fontColor('#333333')

      Blank()

      if (this.viewModel.canDeleteSelected()) {
        Image($r('app.media.icon_delete'))
          .width(20)
          .height(20)
          .fillColor(Color.Black)
          .onClick(() => {
            this.viewModel.deleteSelectedSongs()
          })
      }

      Image($r('app.media.action_icon_play_next'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.viewModel.appendSelectedToPlaylist()
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor('#FFF7E6')
    .margin({ bottom: 4 })
  }
}
