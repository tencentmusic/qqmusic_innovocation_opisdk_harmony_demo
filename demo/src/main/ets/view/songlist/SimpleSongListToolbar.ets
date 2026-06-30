import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { ToastUtil } from '../../utils/ToastUtil'

/**
 * 简化工具栏：播放全部 + 收藏列表 + 收藏全部歌曲
 * 用于首页推荐歌单/专辑列表入口
 * - 收藏列表：收藏/取消收藏专辑、歌单、歌手本身
 * - 收藏全部歌曲：将当前列表所有歌曲添加到"我喜欢"/从"我喜欢"中移除
 *
 * 各场景按钮：
 * - 歌手：播放全部 + 收藏歌手
 * - 榜单：播放全部 + 收藏全部歌曲
 * - 专辑/歌单：播放全部 + 收藏列表 + 收藏全部歌曲
 */
@ComponentV2
export struct SimpleSongListToolbar {
  @Consumer('viewModel') viewModel: SongListViewModel = new SongListViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()

  build() {
    Row() {
      // 播放全部
      Button(`播放全部(${this.viewModel.songList.length})`)
        .fontSize(12)
        .height(32)
        .backgroundColor('#1890FF')
        .fontColor(Color.White)
        .borderRadius(4)
        .onClick(() => {
          if (this.viewModel.playAllSongs()) {
            this.navController.push(RouteName.PLAYER_PAGE)
          } else {
            ToastUtil.show('暂无版权，无法播放')
          }
        })

      if (this.viewModel.playListType === MusicListType.TYPE_SINGER) {
        // 歌手场景：播放全部 + 收藏歌手
        Button(this.viewModel.isListCollected ? '取消收藏' : '收藏')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.viewModel.isListCollected ? '#D9D9D9' : '#1890FF')
          .fontColor(this.viewModel.isListCollected ? '#333333' : Color.White)
          .borderRadius(4)
          .onClick(() => {
            this.viewModel.toggleListCollect()
          })
      } else if (this.viewModel.playListType === MusicListType.TYPE_ONLINE) {
        // 榜单场景：播放全部 + 收藏全部歌曲（榜单本身不支持收藏）
        Button(this.viewModel.isAllSongsCollected ? `取消收藏(${this.viewModel.songList.length})首` : `收藏(${this.viewModel.songList.length})首`)
          .fontSize(12)
          .height(32)
          .backgroundColor(this.viewModel.isAllSongsCollected ? '#D9D9D9' : '#1890FF')
          .fontColor(this.viewModel.isAllSongsCollected ? '#333333' : Color.White)
          .borderRadius(4)
          .onClick(() => {
            this.viewModel.toggleCollectAllSongs()
          })
      } else {
        // 专辑/歌单场景：播放全部 + 收藏列表 + 收藏全部歌曲
        Button(this.viewModel.isListCollected ? '取消收藏' : '收藏')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.viewModel.isListCollected ? '#D9D9D9' : '#1890FF')
          .fontColor(this.viewModel.isListCollected ? '#333333' : Color.White)
          .borderRadius(4)
          .onClick(() => {
            this.viewModel.toggleListCollect()
          })

        Button(this.viewModel.isAllSongsCollected ? `取消收藏(${this.viewModel.songList.length})首` : `收藏(${this.viewModel.songList.length})首`)
          .fontSize(12)
          .height(32)
          .backgroundColor(this.viewModel.isAllSongsCollected ? '#D9D9D9' : '#1890FF')
          .fontColor(this.viewModel.isAllSongsCollected ? '#333333' : Color.White)
          .borderRadius(4)
          .onClick(() => {
            this.viewModel.toggleCollectAllSongs()
          })
      }
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
    .backgroundColor(Color.White)
    .margin({ bottom: 4 })
  }
}
