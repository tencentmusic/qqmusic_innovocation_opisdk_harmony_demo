import { IMediaResDetail, IMediaSinger } from '@qqmusic/opisdk-entity'
import { NavController } from '../../../nav/NavController'
import { RouteName } from '../../../nav/RouteMap'
import { MVPlayerPageParams } from '../../../nav/RouteParams'

/**
 * 单个 MV 推荐项视图
 * 封面 + 标题 + 歌手，点击跳转 MV 播放页
 */
@ComponentV2
export struct MvRecommendItemView {
  @Param mvItem: IMediaResDetail | null = null
  @Consumer('navController') navController: NavController = NavController.getInstance()

  private get coverUrl(): string {
    return this.mvItem?.getCoverImage() ?? ''
  }

  private get mvTitle(): string {
    return this.mvItem?.getTitle() ?? '未知MV'
  }

  private get singerName(): string {
    const singers = this.mvItem?.getSingers()
    if (singers && singers.length > 0) {
      return singers.map((s: IMediaSinger) => s.getName() ?? '').join(', ')
    }
    const singerText = this.mvItem?.getSingerName()
    if (singerText && singerText.length > 0) {
      return singerText
    }
    return '未知歌手'
  }

  private get mvVid(): string {
    return this.mvItem?.getVid() ?? ''
  }

  private onItemClick(): void {
    if (this.mvVid.length > 0) {
      const params = new MVPlayerPageParams(this.mvVid)
      this.navController.push(RouteName.MV_PLAYER_PAGE, params)
    }
  }
  build() {
    Row({ space: 12 }) {
      // 封面
      Image(this.coverUrl)
        .width(110)
        .height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .backgroundColor('#E0E0E0')
      // 标题和歌手
      Column({ space: 4 }) {
        Text(this.mvTitle)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.singerName)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 8, bottom: 8, left: 16, right: 16 })
    .borderRadius(8)
    .backgroundColor(Color.White)
    .onClick(() => {
      this.onItemClick()
    })
  }
}