import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { ToastUtil } from '../../utils/ToastUtil'

/**
 * 歌曲列表工具栏
 * 包含：播放全部/暂停/继续 + 随机添加 + 添加歌曲 + 多选开关
 */
@ComponentV2
export struct SongListToolbar {
  @Consumer('viewModel') viewModel: SongListViewModel = new SongListViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()

  build() {
    Row({ space: 8 }) {
      if (this.viewModel.isCurrentAlbumPlaying()) {
        Row() {
          Image($r('app.media.ic_music_pause'))
            .fillColor(Color.Black)
            .height(32)
          Text('暂停').fontSize(12).fontColor('#333333')
        }.onClick(() => {
          this.viewModel.pause()
        })
      } else if (this.viewModel.isCurrentAlbumPaused()) {
        Row() {
          Image($r('app.media.ic_music_play'))
            .fillColor(Color.Black)
            .height(32)
          Text('继续').fontSize(12).fontColor('#333333')
        }.onClick(() => {
          this.viewModel.resume()
        })
      } else {
        Row({ space: 4 }) {
          Image($r('app.media.ic_play_all'))
            .height(32)
          Text(`(${this.viewModel.songList.length})`)
            .fontSize(10)
            .fontColor('#333333')
        }
        .onClick(() => {
          if (this.viewModel.playAllSongs()) {
            this.navController.push(RouteName.PLAYER_PAGE)
          } else {
            ToastUtil.show('暂无版权，无法播放')
          }
        })
      }

      Blank()

      // 随机添加到播放列表
      Image($r('app.media.action_icon_play_next'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.viewModel.shuffleAppendToPlaylist()
        })

      // 添加歌曲
      Image($r('app.media.folder_action_icon_add_song'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.viewModel.toggleAddSongDialog()
        })

      // 多选开关
      Image($r('app.media.action_icon_folder_multi_opt'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.viewModel.toggleEditorView()
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
    .backgroundColor(Color.White)
    .margin({ bottom: 4 })
  }
}
