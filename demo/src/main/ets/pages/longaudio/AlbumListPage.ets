import { AlbumListViewModel } from '../../viewmodel/longaudio/AlbumListViewModel'
import { NavController } from '../../nav/NavController'
import { AlbumListPageParams, SongListPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'AlbumListPage'

/**
 * 专辑列表页
 * 展示专辑封面、名称、副标题、歌手、播放量、收藏按钮
 * 点击专辑 item 跳转 SongListPage
 */
@ComponentV2
export struct AlbumListPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: AlbumListViewModel = new AlbumListViewModel()

  aboutToAppear(): void {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as AlbumListPageParams
      if (raw) {
        this.viewModel.albumId = raw.albumId
        this.viewModel.albumName = raw.albumName
        this.viewModel.fetchAlbumDetail()
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.buildHeader()

        if (this.viewModel.isLoading) {
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
        } else if (this.viewModel.album !== null) {
          Column() {
            this.buildAlbumItem()

            // 已加载全部提示
            Text('已加载全部')
              .fontSize(12)
              .fontColor(Color.Gray)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          Column() {
            Image($r('app.media.icon_home_placeholder'))
              .width(64)
              .height(64)
              .opacity(0.3)
            Text('暂无专辑信息')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
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

      Text('专辑列表')
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

  /**
   * 专辑 item
   * 封面 + 名称 + 副标题 + 歌手 + 播放量 + 收藏按钮
   * 点击跳转 SongListPage
   */
  @Builder
  buildAlbumItem() {
    Row({ space: 12 }) {
      // 封面（带播放量叠加）
      Stack() {
        Image(this.viewModel.album?.getPic() ?? '')
          .width(60)
          .height(60)
          .objectFit(ImageFit.Cover)
          .borderRadius(4)
          .backgroundColor('#E0E0E0')

        // 播放量标签（叠加在封面底部）
        Text(`播放量:${NumberFormatUtils.formatNumber(this.viewModel.album?.getListenNum() ?? 0)}`)
          .fontSize(8)
          .fontColor(Color.White)
          .backgroundColor('#99000000')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .width(60)
          .textAlign(TextAlign.Center)
      }
      .width(60)
      .height(60)
      .alignContent(Alignment.Bottom)

      // 专辑信息
      Column({ space: 4 }) {
        Text(this.viewModel.album?.getName() ?? '')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.viewModel.album?.getSubName()) {
          Text(this.viewModel.album?.getSubName() ?? '')
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Text(this.viewModel.album?.getSingerName() ?? '')
          .fontSize(12)
          .fontColor(Color.Gray)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)

      // 收藏按钮
      Image(this.viewModel.isAlbumCollected ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
        .width(32)
        .height(32)
        .padding(6)
        .onClick(() => {
          this.viewModel.toggleAlbumCollect()
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .margin({ left: 12, right: 12, top: 8 })
    .borderRadius(8)
    .onClick(() => {
      if (this.viewModel.album) {
        const params = new SongListPageParams(
          MusicListType.TYPE_ALBUM,
          this.viewModel.album.getId(),
          this.viewModel.album.getName()
        )
        this.navController.push(RouteName.SONG_LIST_PAGE, params)
      }
    })
  }
}
@Builder
export function AlbumListPageBuilder(params: Object) {
  AlbumListPage()
}
