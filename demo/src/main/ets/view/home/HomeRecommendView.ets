import { MLog } from '@qqmusic/opisdk-base'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { RecommendItemView } from './RecommendItemView'
import { ToastUtil } from '../../utils/ToastUtil'

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
          ToastUtil.show(`Banner: ${repeatItem.item.getTitle()}`)
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
   * 获取 Banner 类型名称
   */
  getBannerTypeName(type: number | null): string {
    if (type === 1) {
      return '歌曲'
    } else if (type === 2) {
      return '歌单'
    } else if (type === 3) {
      return '专辑'
    } else if (type === 4) {
      return 'H5'
    } else if (type === 5) {
      return '排行榜'
    } else if (type === 6) {
      return '电台'
    } else {
      return `未知type(${type})`
    }
  }
}
