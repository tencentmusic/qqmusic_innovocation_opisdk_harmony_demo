import { MLog } from '@qqmusic/opisdk-base'
import { IRank, IRankGroup } from '@qqmusic/opisdk-entity'
import { RankListViewModel } from '../../viewmodel/musichall/RankListViewModel'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { RankDetailPageParams } from '../../nav/RouteParams'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'RankListPage'

@ComponentV2
export struct RankListPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: RankListViewModel = new RankListViewModel()

  aboutToAppear() {
    this.viewModel.loadData()
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        this.buildHeader()

        if (this.viewModel.isLoading && this.viewModel.rankGroups.length === 0) {
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
        } else if (this.viewModel.rankGroups.length === 0) {
          Column() {
            Image($r('app.media.icon_home_placeholder'))
              .width(64)
              .height(64)
              .opacity(0.3)
            Text('暂无排行榜数据')
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
          List() {
            Repeat(this.viewModel.rankGroups).each((groupItem) => {
              ListItem() {
                this.buildRankGroup(groupItem.item)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 12, right: 12, top: 12 })
          .edgeEffect(EdgeEffect.Spring)
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

      Text('排行榜')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank().width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  buildRankGroup(group: IRankGroup) {
    Column({ space: 0 }) {
      // 分组标题
      Text(group.getGroupName())
        .fontSize(16)
        .fontColor(Color.Gray)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 4, right: 16, top: 12, bottom: 8 })
        .width('100%')

      // 榜单列表：一行两个
      List({ space: 12 }) {
        Repeat(group.getRankList() ?? []).each((rankItem) => {
          ListItem() {
            this.buildRankItem(rankItem.item)
          }
        })
      }
      .width('100%')
      .lanes(2, 12)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
    .padding({ left: 8, right: 8, bottom: 8 })
    .margin({ bottom: 12 })
  }

  @Builder
  buildRankItem(rank: IRank) {
    Column({ space: 0 }) {
      // 封面区域
      Stack({ alignContent: Alignment.BottomEnd }) {
        // 底层封面
        Image(rank.getTopHeaderPic() ?? '')
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .backgroundColor('#E0E0E0')

        // 蒙层图
        if (rank.getTopBannerPic() != null && rank.getTopBannerPic()!.length > 0) {
          Image(rank.getTopBannerPic()!)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Fill)
            .borderRadius(8)
        }

        // 播放量
        if (rank.getListenNum() != null && rank.getListenNum()! > 0) {
          Row({ space: 2 }) {
            Image($r('app.media.icon_home_placeholder'))
              .width(10)
              .height(10)
              .fillColor(Color.White)
            Text(NumberFormatUtils.formatNumber(rank.getListenNum()!))
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
      .aspectRatio(1)

      // 标题放在封面下方
      Text(rank.getName())
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 8, bottom: 8 })
    }
    .width('100%')
    .onClick(() => {
      MLog.i(TAG, `click rank: ${rank.getName()}, id: ${rank.getId()}`)
      const params = new RankDetailPageParams(rank.getId(), rank.getName())
      this.navController.push(RouteName.RANK_DETAIL_PAGE, params)
    })
  }
}
@Builder
export function RankListPageBuilder(params: Object) {
  RankListPage()
}
