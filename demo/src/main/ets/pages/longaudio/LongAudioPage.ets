import { LongAudioHomeViewModel } from '../../viewmodel/longaudio/LongAudioHomeViewModel'
import { LongAudioShelfContentView } from '../../view/longaudio/LongAudioShelfContentView'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { LongAudioRankPageParams, LongAudioCategoryPageParams } from '../../nav/RouteParams'

/**
 * 长音频首页
 */
@ComponentV2
export struct LongAudioPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: LongAudioHomeViewModel = new LongAudioHomeViewModel()
  private categoryTabScroller: ListScroller = new ListScroller()
  private subCategoryTabScroller: ListScroller = new ListScroller()

  aboutToAppear(): void {
    if (this.viewModel.categories.length === 0) {
      this.viewModel.fetchCategories()
    }
  }

  build() {
    Column() {
      if (this.viewModel.isLoadingCategories && this.viewModel.categories.length === 0) {
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
      } else if (this.viewModel.categories.length === 0) {
        // 空状态
        Column() {
          Image($r('app.media.icon_home_placeholder'))
            .width(64)
            .height(64)
            .opacity(0.3)
          Text('暂无长音频数据')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 12 })
          Button('重新加载')
            .margin({ top: 16 })
            .onClick(() => {
              this.viewModel.fetchCategories()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 一级品类 Tab
        this.buildCategoryTabBar()

        // 二级子分类 Tab
        if (this.viewModel.currentSubCategories.length > 0) {
          this.buildSubCategoryTabBar()
        }

        // 排行榜 + 分类 快捷按钮
        this.buildActionButtons()

        // 内容区域
        if (this.viewModel.isLoadingDetail) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color('#6200EE')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          LongAudioShelfContentView({
            shelves: this.viewModel.shelves
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildCategoryTabBar() {
    List({ scroller: this.categoryTabScroller }) {
      Repeat(this.viewModel.categories).each((repeatItem) => {
        ListItem() {
          Text(repeatItem.item.name)
            .fontSize(14)
            .fontColor(this.viewModel.currentCategoryIndex === repeatItem.index ? '#6200EE' : '#666666')
            .fontWeight(this.viewModel.currentCategoryIndex === repeatItem.index ? FontWeight.Bold : FontWeight.Normal)
            .padding({ top: 10, bottom: 6, left: 14, right: 14 })
            .onClick(() => {
              this.viewModel.selectCategory(repeatItem.index)
              this.categoryTabScroller.scrollToIndex(repeatItem.index, true, ScrollAlign.CENTER)
            })
        }
      })
    }
    .listDirection(Axis.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(40)
    .backgroundColor(Color.White)
  }

  @Builder
  buildSubCategoryTabBar() {
    List({ scroller: this.subCategoryTabScroller }) {
      Repeat(this.viewModel.currentSubCategories).each((repeatItem) => {
        ListItem() {
          Text(repeatItem.item.name)
            .fontSize(12)
            .fontColor(this.viewModel.currentSubCategoryIndex === repeatItem.index ? '#6200EE' : '#999999')
            .fontWeight(this.viewModel.currentSubCategoryIndex === repeatItem.index ? FontWeight.Medium : FontWeight.Normal)
            .padding({ top: 6, bottom: 6, left: 12, right: 12 })
            .onClick(() => {
              this.viewModel.selectSubCategory(repeatItem.index)
              this.subCategoryTabScroller.scrollToIndex(repeatItem.index, true, ScrollAlign.CENTER)
            })
        }
      })
    }
    .listDirection(Axis.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(32)
    .backgroundColor('#FAFAFA')
  }

  @Builder
  buildActionButtons() {
    Row({ space: 12 }) {
      Button('排行榜')
        .fontSize(12)
        .height(28)
        .onClick(() => {
          this.navController.push(RouteName.LONG_AUDIO_RANK_PAGE, this.rankPageParams)
        })

      Button('分类')
        .fontSize(12)
        .height(28)
        .onClick(() => {
          this.navController.push(RouteName.LONG_AUDIO_CATEGORY_PAGE, this.categoryPageParams)
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FAFAFA')
  }

  private get rankPageParams(): LongAudioRankPageParams {
    const tag = this.viewModel.categories[this.viewModel.currentCategoryIndex]?.name ?? ''
    return new LongAudioRankPageParams(tag)
  }

  private get categoryPageParams(): LongAudioCategoryPageParams {
    const tag = this.viewModel.categories[this.viewModel.currentCategoryIndex]?.name ?? ''
    return new LongAudioCategoryPageParams(
      tag,
      this.viewModel.currentCategoryId,
      this.viewModel.currentSubCategoryId
    )
  }
}
