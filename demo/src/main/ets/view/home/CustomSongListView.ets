import { CustomSongListViewModel } from '../../viewmodel/CustomSongListViewModel'
import { ISongListItem } from '@qqmusic/opisdk-entity'
import { NavController } from '../../nav/NavController'
import { SongListPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { CopyableInfoField } from '../common/CopyableInfoField'
/**
 * 合作方运营歌单页面
 */
@ComponentV2
export struct CustomSongListView {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: CustomSongListViewModel = new CustomSongListViewModel()

  aboutToAppear(): void {
    this.viewModel.fetchSongListSquare()
  }

  build() {
    Column() {
      if (this.viewModel.isLoading && this.viewModel.squares.length === 0) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#6200EE')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.viewModel.squares.length === 0) {
        Column() {
          Image($r('app.media.icon_home_placeholder'))
            .width(64)
            .height(64)
            .opacity(0.3)
          Text('暂无运营歌单数据')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 12 })
          Button('重新加载')
            .margin({ top: 16 })
            .onClick(() => {
              this.viewModel.fetchSongListSquare()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Grid() {
            Repeat(this.viewModel.squares).each((repeatItem) => {
              GridItem() {
                this.buildSongListItemCard(repeatItem.item)
              }
            })
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .padding(8)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildSongListItemCard(item: ISongListItem) {
    Column({ space: 4 }) {
      // 封面图：点击跳转
      Image(item.pic ?? '')
        .width('100%')
        .aspectRatio(1)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .backgroundColor('#E0E0E0')
        .onClick(() => {
          this.handleItemClick(item)
        })

      // 信息区域（半透明背景）：使用 CopyableInfoField 渲染每个字段
      Column({ space: 2 }) {
        CopyableInfoField({
          label: 'title',
          value: item.title ?? 'null',
          fontSize: 12,
          fontColor: '#333333'
        })

        CopyableInfoField({
          label: 'subtitle',
          value: item.subtitle ?? '',
          fontSize: 11,
          fontColor: '#666666'
        })

        CopyableInfoField({
          label: 'itemId',
          value: item.itemId ?? '',
          fontSize: 11,
          fontColor: '#666666'
        })

        CopyableInfoField({
          label: 'type',
          value: this.viewModel.getTypeLabel(item.type),
          fontSize: 11,
          fontColor: '#666666'
        })

        CopyableInfoField({
          label: 'scene',
          value: item.scene ?? '',
          fontSize: 11,
          fontColor: '#666666'
        })
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#B3FFFFFF')
      .borderRadius({ bottomLeft: 8, bottomRight: 8 })
    }
    .width('100%')
    .padding(4)
    .borderRadius(8)
  }

  /**
   * 处理 item 点击事件
   */
  private handleItemClick(item: ISongListItem): void {
    const itemId = item.itemId
    if (!itemId || itemId.length === 0) {
      return
    }

    if (item.type === 2) {
      // 歌单：跳转 SongListPage，playListType = TYPE_FOLDER
      const params = new SongListPageParams(
        MusicListType.TYPE_FOLDER,
        parseInt(itemId),
        item.title ?? '歌单',
        false
      )
      this.navController.push(RouteName.SONG_LIST_PAGE, params)
    } else {
      // 榜单：跳转 SongListPage，playListType = TYPE_ONLINE（榜单场景）
      const params = new SongListPageParams(
        MusicListType.TYPE_ONLINE,
        parseInt(itemId),
        item.title ?? '榜单',
        true
      )
      this.navController.push(RouteName.SONG_LIST_PAGE, params)
    }
  }
}
