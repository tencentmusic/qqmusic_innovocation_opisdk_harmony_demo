import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'
import { NavController } from '../../nav/NavController'
import { RankDetailPageParams } from '../../nav/RouteParams'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { SongListItemView } from '../../view/songlist/SongListItemView'
import { SimpleSongListToolbar } from '../../view/songlist/SimpleSongListToolbar'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'RankDetailPage'

/**
 * 榜单详情页
 * 复用 SongListViewModel + SongListItemView + SimpleSongListToolbar
 * 工具栏仅显示：播放全部 + 收藏全部歌曲
 */
@ComponentV2
export struct RankDetailPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Provider('viewModel') viewModel: SongListViewModel = new SongListViewModel()
  @Local rankName: string = ''

  aboutToAppear(): void {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as RankDetailPageParams
      if (raw) {
        this.rankName = raw.rankName
        this.viewModel.playListType = MusicListType.TYPE_ONLINE
        this.viewModel.rankId = raw.rankId
        this.viewModel.listName = raw.rankName
        this.viewModel.showSimpleToolbar = true
        this.viewModel.fetchAlbumDetail()
      }
    }
    this.viewModel.registerPlayEventListener()
  }

  aboutToDisappear(): void {
    this.viewModel.unregisterPlayEventListener()
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        this.buildHeader()

        if (this.viewModel.isLoading && this.viewModel.songList.length === 0) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color('#6200EE')
            Text('加载中...')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.viewModel.songList.length === 0 && !this.viewModel.isLoadingSongs) {
          Column() {
            Image($r('app.media.icon_home_placeholder'))
              .width(64)
              .height(64)
              .opacity(0.3)
            Text('暂无歌曲数据')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 12 })
            Button('重新加载')
              .margin({ top: 16 })
              .onClick(() => {
                this.viewModel.fetchAlbumDetail()
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          // 工具栏：播放全部 + 收藏全部歌曲
          if (this.viewModel.songList.length > 0) {
            SimpleSongListToolbar()
              .margin({ top: 8, bottom: 4 })
          }
          // 歌曲列表
          List() {
            Repeat(this.viewModel.songList).each((repeatItem) => {
              ListItem() {
                SongListItemView({
                  host: this.viewModel,
                  songList: this.viewModel.songList,
                  song: repeatItem.item,
                  index: repeatItem.index
                })
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 12, right: 12 })
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Off)
          .onReachEnd(() => {
            this.viewModel.loadSongs(true)
          })

          // 底部加载状态
          if (this.viewModel.isLoadingSongs && this.viewModel.songList.length > 0) {
            Text('正在加载更多...')
              .fontSize(12)
              .fontColor(Color.Gray)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
          } else if (!this.viewModel.hasMore && this.viewModel.songList.length > 0) {
            Text('已加载全部')
              .fontSize(12)
              .fontColor(Color.Gray)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .padding({ bottom: 70 - AppUtil.bottomSafeArea })
    }
    .hideTitleBar(true)
  }

  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_back_dark'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.navController.pop()
        })

      Text(this.rankName ? this.rankName : '榜单详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank().width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }
}

@Builder
export function RankDetailPageBuilder(params: Object) {
  RankDetailPage()
}
