import { MvAreaViewModel } from '../../../viewmodel/MvAreaViewModel'
import { NavController } from '../../../nav/NavController'
import { RouteName } from '../../../nav/RouteMap'
import { SpecialArea, IMediaSimpleRes, IMediaGroupRes } from '@qqmusic/opisdk-entity'
import { MVPlayerPageParams, MvAreaDetailPageParams } from '../../../nav/RouteParams'
import { MLog } from '@qqmusic/opisdk-base'
import { NumberFormatUtils } from '../../../utils/NumberFormatUtils'

const TAG = 'MvAreaPage'

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
 * 专区内容页面（Dolby视界 / 4K臻品）
 */
@ComponentV2
export struct MvAreaPage {
  @Param specialArea: number = SpecialArea.Dolby
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: MvAreaViewModel = new MvAreaViewModel()

  aboutToAppear(): void {
    this.viewModel.setSpecialArea(this.specialArea as SpecialArea)
    this.viewModel.fetchContentArea()
  }

  aboutToDisappear(): void {
    this.viewModel.clear()
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        this.buildTopBar()

        // 内容区域
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
        } else if (this.viewModel.areaData === null) {
          Column() {
            Image($r('app.media.icon_home_placeholder'))
              .width(64)
              .height(64)
              .opacity(0.3)
            Text('暂无专区数据')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 12 })
            Button('重新加载')
              .margin({ top: 16 })
              .onClick(() => {
                this.viewModel.fetchContentArea()
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Scroll() {
            Column({ space: 0 }) {
              // 专区封面
              Image(this.viewModel.areaData.getCover() ?? '')
                .width('100%')
                .height(160)
                .objectFit(ImageFit.Cover)
                .backgroundColor('#E0E0E0')

              // 专区标题
              Text(this.viewModel.areaData.getTitle() ?? '')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .padding({ left: 16, right: 16, top: 12, bottom: 4 })
                .width('100%')

              // 专区描述
              Text(this.viewModel.areaData.getDesc() ?? '')
                .fontSize(13)
                .fontColor('#666666')
                .padding({ left: 16, right: 16, top: 4, bottom: 8 })
                .width('100%')

              // 货架分组列表
              this.buildShelves()
            }
            .width('100%')
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
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

      Text(this.viewModel.getAreaTitle())
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
  buildShelves() {
    Column() {
      Repeat(this.viewModel.areaData!.getItems()!).each((repeatItem) => {
        this.buildShelfGroup(repeatItem.item)
      })
    }
    .width('100%')
  }

  @Builder
  buildShelfGroup(groupRes: IMediaGroupRes) {
    Column({ space: 8 }) {
      // 分组标题（可点击跳转详情页）
      Row() {
        Text(groupRes.getTitle() ?? '无主题')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Image($r('sys.media.ohos_ic_public_arrow_right'))
         .width(24)
          .height(24)
         .margin({ left: 4, right: 4 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })
      .onClick(() => {
        MLog.i(TAG, `Shelf group clicked: ${groupRes.getTitle()}, navigating to detail`)
        const params = new MvAreaDetailPageParams(
          this.viewModel.getSpecialArea(), groupRes
        )
        this.navController.push(RouteName.MV_AREA_DETAIL_PAGE, params)
      })

      // 分组下的 MV 网格
      Grid() {
        Repeat(groupRes.getItems()).each((repeatItem) => {
          GridItem() {
            this.buildMvGridItem(repeatItem.item.getMediaItem())
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .padding({ left: 16, right: 16 })
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 16 })
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
export function MvAreaPageBuilder(params: Object) {
  if (params instanceof MvAreaPageParams) {
    MvAreaPage({ specialArea: params.specialArea })
  } else {
    MvAreaPage()
  }
}

/**
 * 专区页面路由参数
 */
export class MvAreaPageParams {
  specialArea: number

  constructor(specialArea: number) {
    this.specialArea = specialArea
  }
}
