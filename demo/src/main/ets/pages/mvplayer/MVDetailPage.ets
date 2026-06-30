import { MVPlayerViewModel } from '../../viewmodel/MVPlayerViewModel'
import { NavController } from '../../nav/NavController'
import { MVDetailPageParams } from '../../nav/RouteParams'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'
import { IMediaResDetail } from '@qqmusic/opisdk-entity'

@Builder
export function MVDetailPageBuilder(args?: Object) {
  MVDetailPage({ args: args })
}

/**
 * MV 详情信息页面
 * 对应 Android 的 MVDetailFragment，显示 MV 的 VID、上架时间、播放量等信息
 */
@ComponentV2
export struct MVDetailPage {
  @Param args: Object | undefined = undefined;
  @Local mvResDetail: IMediaResDetail | null = null;
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    const args = this.args as MVDetailPageParams;
    if (args) {
      this.mvResDetail = args.mvResDetail
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.icon_back_placeholder'))
            .width(24)
            .height(24)
            .margin({ left: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.navController.pop()
            })

          Text('MV 详情')
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

        // 详情内容
        Column({ space: 16 }) {
          // VID
          this.buildInfoRow('MV VID', this.mvResDetail?.getVid() ?? '未知')

          // 标题
          this.buildInfoRow('标题', this.mvResDetail?.getTitle() ?? '未知')

          // 歌手
          this.buildInfoRow('歌手', this.mvResDetail?.getSingerName() ?? '未知')

          // 上架时间
          this.buildInfoRow('上架时间', this.mvResDetail?.getPublicTime() ?? '未知')

          // 播放量
          this.buildInfoRow('播放量', NumberFormatUtils.formatNumber(this.mvResDetail?.getPlayCount() ?? null))

          // 时长
          this.buildInfoRow('时长', MVPlayerViewModel.formatTime(parseInt(this.mvResDetail?.getPlayTime() ?? '0')))

          // 收藏状态
          this.buildInfoRow('收藏状态', this.mvResDetail?.getIsCollect() === 1 ? '已收藏' : '未收藏')

          // 媒体类型
          this.buildInfoRow('媒体类型', (this.mvResDetail?.getMediaType() ?? 0) === 1 ? '短视频' : 'MV')

          // 下架状态
          this.buildInfoRow('下架状态', (this.mvResDetail?.getShelvesStatus() ?? 0) === 1 ? '已下架' : '正常')
        }
        .width('100%')
        .padding(16)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }

  @Builder
  buildInfoRow(label: string, value: string) {
    Row() {
      Text(label + ':  ')
        .fontSize(15)
        .fontColor('#666666')
        .fontWeight(FontWeight.Medium)

      Text(value)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
}
