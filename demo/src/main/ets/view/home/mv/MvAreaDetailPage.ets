import { MvAreaViewModel } from '../../../viewmodel/MvAreaViewModel'
import { NavController } from '../../../nav/NavController'
import { RouteName } from '../../../nav/RouteMap'
import { SpecialArea, IMediaSimpleRes, IMediaGroupRes } from '@qqmusic/opisdk-entity'
import { MVPlayerPageParams, MvAreaDetailPageParams } from '../../../nav/RouteParams'
import { NumberFormatUtils } from '../../../utils/NumberFormatUtils'
import { AppUtil } from '../../../utils/AppUtil'

const TAG = 'MvAreaDetailPage'

/**
 * 格式化时长（秒 -> mm:ss）
 */
function formatPlayTime(seconds: number | null): string {
  if (seconds === null || seconds === undefined || seconds <= 0) {
    return ''
  }
  const min = Math.floor(seconds / 60)
  const sec = Math.floor(seconds % 60)
  const minStr = min < 10 ? `0${min}` : `${min}`
  const secStr = sec < 10 ? `0${sec}` : `${sec}`
  return `${minStr}:${secStr}`
}

/**
 * 专区详情页（分组内容翻页）
 */
@ComponentV2
export struct MvAreaDetailPage {
  @Param specialArea: number = SpecialArea.Dolby
  @Param groupRes: IMediaGroupRes | null = null
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: MvAreaViewModel = new MvAreaViewModel()

  aboutToAppear(): void {
    this.viewModel.setSpecialArea(this.specialArea as SpecialArea)
    if (this.groupRes) {
      this.viewModel.setGroupAndLoadDetail(this.groupRes)
    }
  }

  aboutToDisappear(): void {
    this.viewModel.clear()
  }

  private get allMvItems(): IMediaSimpleRes[] {
    const items: IMediaSimpleRes[] = []
    for (const group of this.viewModel.areaDetailList) {
      const groupItems = group.getItems()
      if (groupItems) {
        for (const item of groupItems) {
          const mediaItem = item.getMediaItem()
          if (mediaItem && mediaItem.getVid() && mediaItem.getVid()!.length > 0) {
            items.push(mediaItem)
          }
        }
      }
    }
    return items
  }

  private get groupTitle(): string {
    return this.groupRes?.getTitle() ?? 'MV列表'
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        this.buildTopBar()

        // 内容区域
        if (this.viewModel.isLoadingDetail && this.viewModel.areaDetailList.length === 0) {
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
        } else if (this.viewModel.areaDetailList.length === 0) {
          Column() {
            Image($r('app.media.icon_home_placeholder'))
              .width(64)
              .height(64)
              .opacity(0.3)
            Text('暂无数据')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 12 })
            Button('重新加载')
              .margin({ top: 16 })
              .onClick(() => {
                if (this.groupRes) {
                  this.viewModel.setGroupAndLoadDetail(this.groupRes)
                }
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Column() {
            // MV 网格
            Grid() {
              Repeat(this.allMvItems).each((repeatItem) => {
                GridItem() {
                  this.buildMvGridItem(repeatItem.item)
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(8)
            .rowsGap(8)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .width('100%')
            .layoutWeight(1)

            // 加载更多按钮
            Button('新增下一页')
              .width('60%')
              .margin({ top: 12, bottom: 16 })
              .onClick(() => {
                this.viewModel.loadMoreDetail()
              })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 70 - AppUtil.bottomSafeArea })
    }
    .hideTitleBar(true)
  }

  @Builder
  buildTopBar() {
    Row() {
      Image($r('app.media.icon_back_placeholder'))
        .width(24)
        .height(24)
        .margin({ left: 16, top: 12, bottom: 12 })
        .onClick(() => {
          this.navController.pop()
        })

      Text(this.groupTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ top: 12, bottom: 12 })

      Blank()
        .width(40)
    }
    .width('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  buildMvGridItem(mvItem: IMediaSimpleRes | null) {
    Column({ space: 4 }) {
      // 封面（含播放量和时长叠加）
      Stack({ alignContent: Alignment.Bottom }) {
        Image(mvItem?.getCoverImage() ?? '')
          .width('100%')
          .height(100)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 8, topRight: 8 })
          .backgroundColor('#E0E0E0')

        // 底部叠加：播放量 + 时长
        Row({ space: 4 }) {
          Text(NumberFormatUtils.formatNumber(mvItem?.getPlayCount() ?? null))
            .fontSize(10)
            .fontColor(Color.White)

          Blank()

          Text(formatPlayTime(mvItem?.getPlayTime() ?? null))
            .fontSize(10)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        .backgroundColor('#66000000')
        .borderRadius({ bottomLeft: 8, bottomRight: 8 })
      }

      Text(mvItem?.getName() ?? '未知MV')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 2, right: 2 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .onClick(() => {
      this.onMvItemClick(mvItem)
    })
  }

  /**
   * 处理 MV 项点击
   */
  private onMvItemClick(mvItem: IMediaSimpleRes | null): void {
    const vid = mvItem?.getVid()
    if (vid && vid.length > 0) {
      const params = new MVPlayerPageParams(vid)
      this.navController.push(RouteName.MV_PLAYER_PAGE, params)
    }
  }
}

@Builder
export function MvAreaDetailPageBuilder(params: Object) {
  if (params instanceof MvAreaDetailPageParams) {
    MvAreaDetailPage({
      specialArea: params.specialArea,
      groupRes: params.groupRes
    })
  } else {
    MvAreaDetailPage()
  }
}
