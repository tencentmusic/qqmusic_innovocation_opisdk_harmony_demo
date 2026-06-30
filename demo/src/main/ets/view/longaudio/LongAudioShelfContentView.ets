import { IAreaShelf, IAreaShelfItem } from "@qqmusic/opisdk-entity"
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { LongAudioModuleContentPageParams, LongAudioCategoryPageParams, AlbumListPageParams } from '../../nav/RouteParams'
import { ToastUtil } from '../../utils/ToastUtil'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'

/**
 * 长音频 AreaShelf 内容列表
 */
@ComponentV2
export struct LongAudioShelfContentView {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Param shelves: IAreaShelf[] = []

  build() {
    if (this.shelves.length === 0) {
      Column() {
        Text('暂无内容')
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 40 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        Repeat(this.shelves).each((repeatItem) => {
          ListItem() {
            this.buildShelfSection(repeatItem.item)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
    }
  }

  @Builder
  buildShelfSection(shelf: IAreaShelf) {
    Column({ space: 8 }) {
      // 标题行 + 更多按钮
      Row() {
        Text(shelf.getShelfTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Text('更多')
          .fontSize(14)
          .fontColor('#6200EE')
          .onClick(() => {
            this.handleMoreClick(shelf)
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      // 横向专辑列表
      if (shelf.getShelfItems().length > 0) {
        Scroll() {
          Row({ space: 10 }) {
            Repeat(shelf.getShelfItems()).each((itemRepeat) => {
              this.buildAlbumItem(itemRepeat.item)
            })
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  buildAlbumItem(item: IAreaShelfItem) {
    Column({ space: 4 }) {
      Image(item.getAlbum()?.getPic() ?? '')
        .width(100)
        .height(100)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .backgroundColor('#E0E0E0')

      Text(item.getAlbum()?.getName() ?? '')
        .fontSize(12)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(100)

      Text(NumberFormatUtils.formatNumber(item.getAlbum()?.getListenNum() ?? 0))
        .fontSize(10)
        .fontColor(Color.Gray)
        .width(100)
    }
    .width(100)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      const album = item.getAlbum()
      if (album) {
        const albumId = album.getId()
        const albumName = album.getName()
        const params = new AlbumListPageParams(albumId, albumName)
        this.navController.push(RouteName.ALBUM_LIST_PAGE, params)
      }
    })
  }

  private handleMoreClick(shelf: IAreaShelf): void {
    const jumpInfo = shelf.getJumpInfo()
    if (!jumpInfo || !jumpInfo.getInterfaceName()) {
      ToastUtil.show('暂无更多内容')
      return
    }

    const interfaceName = jumpInfo.getInterfaceName()
    if (interfaceName === 'fetchCategoryPageModuleContentLongAudio') {
      const moduleId = jumpInfo.getArgs()?.[0]?.getIntVal() ?? 0
      const params = new LongAudioModuleContentPageParams(moduleId, shelf.getShelfTitle())
      this.navController.push(RouteName.LONG_AUDIO_MODULE_CONTENT_PAGE, params)
    } else if (interfaceName === 'fetchAlbumListOfLongAudioByCategory') {
      const intArrVal = jumpInfo.getArgs()?.[0]?.getIntArrVal()
      const firstId = intArrVal?.[0] ?? 0
      const secondId = intArrVal?.[1] ?? 0
      const params = new LongAudioCategoryPageParams(shelf.getShelfTitle(), firstId, secondId, intArrVal)
      this.navController.push(RouteName.LONG_AUDIO_CATEGORY_PAGE, params)
    } else {
      ToastUtil.show(`不支持的跳转: ${interfaceName}`)
    }
  }
}
