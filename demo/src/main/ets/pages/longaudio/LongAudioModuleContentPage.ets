import { LongAudioModuleContentViewModel } from '../../viewmodel/longaudio/LongAudioModuleContentViewModel'
import { NavController } from '../../nav/NavController'
import { LongAudioModuleContentPageParams, AlbumListPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { IAreaShelfItem } from "@qqmusic/opisdk-entity"
import { AppUtil } from '../../utils/AppUtil'

/**
 * 长音频模块更多内容二级页
 */
@ComponentV2
export struct LongAudioModuleContentPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: LongAudioModuleContentViewModel = new LongAudioModuleContentViewModel()

  aboutToAppear(): void {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as LongAudioModuleContentPageParams
      if (raw) {
        this.viewModel.moduleId = raw.moduleId
        this.viewModel.shelfTitle = raw.shelfTitle
        this.viewModel.loadData()
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.buildHeader()

        if (this.viewModel.isLoading && this.viewModel.shelfItems.length === 0) {
          Column() {
            LoadingProgress().width(48).height(48).color('#6200EE')
            Text('加载中...').fontSize(14).fontColor(Color.Gray).margin({ top: 8 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else if (this.viewModel.shelfItems.length === 0) {
          Column() {
            Image($r('app.media.icon_home_placeholder')).width(64).height(64).opacity(0.3)
            Text('暂无内容').fontSize(14).fontColor(Color.Gray).margin({ top: 12 })
            Button('重新加载').margin({ top: 16 }).onClick(() => { this.viewModel.loadData() })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {
          List() {
            Repeat(this.viewModel.shelfItems).each((repeatItem) => {
              ListItem() {
                this.buildContentItem(repeatItem.item)
              }
              .margin({ left: 6, right: 6, bottom: 12 })
            })
          }
          .lanes(2).width('100%').layoutWeight(1)
          .padding({ left: 6, right: 6, top: 12 })
          .edgeEffect(EdgeEffect.Spring)
          .onReachEnd(() => {
            this.viewModel.loadData(true)
          })
        }
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5').padding({ bottom: 70 - AppUtil.bottomSafeArea })
    }
    .hideTitleBar(true)
  }

  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_back_dark')).width(24).height(24)
        .onClick(() => { this.navController.pop() })
      Text(this.viewModel.shelfTitle)
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        .layoutWeight(1).textAlign(TextAlign.Center).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Blank().width(24)
    }
    .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
  }

  @Builder
  buildContentItem(item: IAreaShelfItem) {
    Column({ space: 4 }) {
      Image(item.getAlbum()?.getPic() ?? '')
        .width('100%').aspectRatio(1).objectFit(ImageFit.Cover)
        .borderRadius(8).backgroundColor('#E0E0E0')
      Text(item.getAlbum()?.getName() ?? '')
        .fontSize(12).fontColor('#333333').maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
    }
    .width('100%')
    .onClick(() => {
      const album = item.getAlbum()
      if (album) {
        const params = new AlbumListPageParams(album.getId(), album.getName())
        this.navController.push(RouteName.ALBUM_LIST_PAGE, params)
      }
    })
  }
}

@Builder
export function LongAudioModuleContentPageBuilder(params: Object) {
  LongAudioModuleContentPage()
}