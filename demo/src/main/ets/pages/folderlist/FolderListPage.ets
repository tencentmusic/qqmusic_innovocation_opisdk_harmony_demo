import { MLog } from '@qqmusic/opisdk-base'
import { IFolder } from '@qqmusic/opisdk-entity'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { FolderListViewModel } from '../../viewmodel/folderlist/FolderListViewModel'
import { NavController } from '../../nav/NavController'
import { FolderListPageParams, SongListPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'FolderListPage'

@ComponentV2
export struct FolderListPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: FolderListViewModel = new FolderListViewModel()
  @Local categoryName: string = ''

  aboutToAppear() {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as FolderListPageParams
      if (raw) {
        this.viewModel.groupId = raw.groupId
        this.viewModel.labelId = raw.labelId
        this.categoryName = raw.categoryName
        this.viewModel.categoryName = this.categoryName
        this.viewModel.loadData()
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        this.buildHeader()

        if (this.viewModel.isLoading && this.viewModel.folderList.length === 0) {
          // 首次加载中
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
        } else if (this.viewModel.folderList.length === 0) {
          // 空状态
          Column() {
            Image($r('app.media.icon_home_placeholder'))
              .width(64)
              .height(64)
              .opacity(0.3)
            Text('暂无歌单数据')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 12 })
            Button('重新加载')
              .margin({ top: 16 })
              .onClick(() => {
                this.viewModel.loadData()
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          // 歌单列表 - 两列网格
          List() {
            Repeat(this.viewModel.folderList).each((repeatItem) => {
              ListItem() {
                this.buildFolderItem(repeatItem.item)
              }
              .margin({ left: 6, right: 6, bottom: 12 })
            })
          }
          .lanes(2)
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 6, right: 6, top: 12 })
          .edgeEffect(EdgeEffect.Spring)
          .onReachEnd(() => {
            this.viewModel.loadData(true)
          })
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

      Text(this.categoryName)
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

  @Builder
  buildFolderItem(folder: IFolder) {
    Column({ space: 8 }) {
      // 歌单封面
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(folder.getPicUrl() ?? '')
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .backgroundColor('#E0E0E0')

        // 播放量角标
        if (folder.getListenNum() != null && folder.getListenNum()! > 0) {
          Row({ space: 2 }) {
            Image($r('app.media.icon_home_placeholder'))
              .width(10)
              .height(10)
              .fillColor(Color.White)
            Text(NumberFormatUtils.formatNumber(folder.getListenNum()!))
              .fontSize(10)
              .fontColor(Color.White)
          }
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('rgba(0,0,0,0.5)')
          .borderRadius({ topLeft: 8, bottomRight: 8 })
          .margin({ right: 4, bottom: 4 })
        }
      }
      .width('100%')

      // 歌单名称
      Text(folder.getName())
        .fontSize(14)
        .fontColor('#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .height(40)

      // 歌曲数量 songNum=null
      // Text(`${folder.getSongNum() ?? 0}首`)
      //   .fontSize(12)
      //   .fontColor(Color.Gray)
      //   .width('100%')
    }
    .width('100%')
    .onClick(() => {
      MLog.i(TAG, `click folder: ${folder.getName()}, id: ${folder.getId()}`)
      const params = new SongListPageParams(
        MusicListType.TYPE_FOLDER,
        folder.getId(),
        folder.getName()
      )
      this.navController.push(RouteName.SONG_LIST_PAGE, params)
    })
  }
}
@Builder
export function FolderListPageBuilder(params: Object) {
  FolderListPage()
}
