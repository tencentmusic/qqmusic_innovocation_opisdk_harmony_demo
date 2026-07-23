import { MLog } from '@qqmusic/opisdk-base'
import { IBanner } from '@qqmusic/opisdk-entity'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { RecommendItemView } from './RecommendItemView'
import { ToastUtil } from '../../utils/ToastUtil'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { CommonWebPageParams, RankDetailPageParams, SongListPageParams } from '../../nav/RouteParams'
import { MusicListType } from '@qqmusic/opisdk-qmutils'

const TAG = 'HomeRecommendView'

/**
 * 首页推荐页
 */
@ComponentV2
export struct HomeRecommendView {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()

  aboutToAppear() {
    if (this.homeViewModel.bannerList.length === 0 && !this.homeViewModel.isLoadingBanner) {
      this.homeViewModel.fetchBannerConfig()
    }
    if (this.homeViewModel.recommendation === null && !this.homeViewModel.isLoadingRecommend) {
      this.homeViewModel.fetchHomeRecommendation()
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // Banner 轮播区域
        if (this.homeViewModel.bannerList.length > 0) {
          this.buildBannerSection()
        } else if (this.homeViewModel.isLoadingBanner) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color('#6200EE')
          }
          .width('100%')
          .height(130)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
        }

        // 推荐内容区域
        if (this.homeViewModel.shelfList.length > 0) {
          Repeat(this.homeViewModel.shelfList).each((repeatItem) => {
            RecommendItemView({ shelf: repeatItem.item })
          })
        } else if (this.homeViewModel.isLoadingRecommend) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color('#6200EE')
            Text('推荐加载中...')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ top: 8 })
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.homeViewModel.recommendation === null && !this.homeViewModel.isLoadingRecommend) {
          Column() {
            Text('暂无推荐数据')
              .fontSize(16)
              .fontColor(Color.Gray)
              .margin({ top: 20 })
            Button('重新加载')
              .margin({ top: 12 })
              .onClick(() => {
                this.homeViewModel.fetchHomeRecommendation()
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
      }
      .padding({
        left: 16,
        right: 16,
        top: 16,
        bottom: 16
      })
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * Banner 轮播区域
   */
  @Builder
  buildBannerSection() {
    Swiper() {
      Repeat(this.homeViewModel.bannerList).each((repeatItem) => {
        Stack({ alignContent: Alignment.BottomStart }) {
          Image(repeatItem.item.getPic())
            .width('100%')
            .height(130)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .backgroundColor('#E0E0E0')

          Column({ space: 2 }) {
            if (repeatItem.item.getTag()) {
              Text(`tag: ${repeatItem.item.getTag()}`)
                .fontSize(11)
                .fontColor(Color.Yellow)
                .fontWeight(FontWeight.Bold)
            }
            Text(`标题: ${repeatItem.item.getTitle()}`)
              .fontSize(12)
              .fontColor(Color.Yellow)
              .fontWeight(FontWeight.Medium)
            if (repeatItem.item.getDesc()) {
              Text(`描述: ${repeatItem.item.getDesc()}`)
                .fontSize(11)
                .fontColor(Color.Yellow)
            }
            Text(`类型: ${this.getBannerTypeName(repeatItem.item.getType())}`)
              .fontSize(11)
              .fontColor(Color.Yellow)
            Text(`资源Id: ${repeatItem.item.getContentId()}`)
              .fontSize(11)
              .fontColor(Color.Yellow)
          }
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 10, bottom: 8 })
        }
        .width('100%')
        .height(130)
        .onClick(() => {
          this.handleBannerClick(repeatItem.item)
        })
      })
    }
    .autoPlay(true)
    .interval(3000)
    .loop(true)
    .indicator(
      new DotIndicator()
        .color(Color.Gray)
        .selectedColor(Color.Yellow)
    )
    .width('100%')
    .height(130)
    .borderRadius(8)
  }

  /**
   * 处理 Banner 点击事件
   * 类型: 1.歌曲  2.歌单  3.专辑  4.H5  5.排行榜  6.电台  7+.其他H5
   */
  handleBannerClick(banner: IBanner): void {
    const url = banner.getUrl()
    if (!url || url.length === 0) {
      ToastUtil.show('url为空')
      return
    }
    const bannerType = banner.getType()
    const contentId = banner.getContentId()
    const title = banner.getTitle()
    MLog.i(TAG, `Banner clicked: type=${bannerType}, contentId=${contentId}, url=${url}`)
    // 根据类型处理跳转：
    // 1.歌曲  2.歌单  3.专辑  4.H5  5.排行榜  6.电台  7+.其他H5
    switch (bannerType) {
      case 1:
        // 歌曲：获取歌曲信息并播放
        this.homeViewModel.playBannerSong(contentId, title)
        break
      case 2:
        // 歌单：跳转歌单详情
        NavController.getInstance().push(RouteName.SONG_LIST_PAGE,
          new SongListPageParams(MusicListType.TYPE_FOLDER, Number(contentId), title))
        break
      case 3:
        // 专辑：跳转专辑详情
        NavController.getInstance().push(RouteName.SONG_LIST_PAGE,
          new SongListPageParams(MusicListType.TYPE_ALBUM, Number(contentId), title))
        break
      case 4:
        // H5：打开 WebView
        NavController.getInstance().push(RouteName.COMMON_WEB_PAGE,
          new CommonWebPageParams(url, title))
        break
      case 5:
        // 排行榜：跳转排行榜详情
        NavController.getInstance().push(RouteName.RANK_DETAIL_PAGE,
          new RankDetailPageParams(Number(contentId), title))
        break
      case 6:
        // 电台：播放电台
        this.homeViewModel.playBannerRadio()
        break
      default:
      // 未知类型（如 type=7 车载VIP等），统一按 H5 打开 URL
        MLog.i(TAG, `Banner unknown type=${bannerType}, open as H5: ${url}`)
        NavController.getInstance().push(RouteName.COMMON_WEB_PAGE,
          new CommonWebPageParams(url, title))
        break
    }
  }

  /**
   * 获取 Banner 类型名称
   * 类型: 1.歌曲  2.歌单  3.专辑  4.H5  5.排行榜  6.电台  7+.其他
   */
  getBannerTypeName(type: number | null): string {
    switch (type) {
      case 1:
        return '歌曲'
      case 2:
        return '歌单'
      case 3:
        return '专辑'
      case 4:
        return 'H5'
      case 5:
        return '排行榜'
      case 6:
        return '电台'
      default:
        return `未知type(${type})`
    }
  }
}
