import { MLog } from '@qqmusic/opisdk-base'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { CategorySectionView } from '../../view/home/CategorySectionView'
import { HomeRecommendView } from '../../view/home/HomeRecommendView'
import { HomeVideoView } from '../../view/home/HomeVideoView'
import { MusicHallPage } from '../musichall/MusicHallPage'
import { LongAudioPage } from '../longaudio/LongAudioPage'
import { CustomSongListView } from '../../view/home/CustomSongListView'
import { AreaSectionView } from '../../view/home/AreaSectionView'

const TAG = 'HomePage'

/**
 * 首页主页面，包含多 Tab 页签
 */
@ComponentV2
export struct HomePage {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()
  // 当前选中的 Tab 索引
  @Local currentTabIndex: number = 0
  // Tab 页签列表
  private readonly tabTitles: string[] = [
    '分类歌单', '首页推荐', '视频', 'AI功能', '音乐馆', '专区', '长音频', '多人点歌', '运营歌单'
  ]
  private tabController: TabsController = new TabsController()
  // Tab 栏横向滚动控制器
  private tabBarScroller: Scroller = new Scroller()

  build() {
    Column() {
      // 可横向滚动的 Tab 栏
      this.buildTabBar()

      // Tab 内容区域
      Tabs({ barPosition: BarPosition.Start, controller: this.tabController, index: this.currentTabIndex }) {
        Repeat(this.tabTitles).each((repeatItem) => {
          TabContent() {
            this.buildTabContent(repeatItem.index)
          }
          .tabBar(this.buildInvisibleTabBar())
        })
      }
      .barHeight(0)
      .scrollable(false)
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTabIndex = index
        MLog.i(TAG, `HomePage: current index ${index}`)
      })
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 70 })
  }

  /**
   * 构建不可见的 TabBar（用于配合自定义 Tab 栏）
   */
  @Builder
  buildInvisibleTabBar() {
    Column()
      .width(0)
      .height(0)
  }

  /**
   * 构建可横向滚动的自定义 Tab 栏
   */
  @Builder
  buildTabBar() {
    List({ scroller: this.tabBarScroller }) {
      Repeat(this.tabTitles).each((repeatItem) => {
        ListItem() {
          Column() {
            Text(repeatItem.item)
              .fontSize(15)
              .fontColor(this.currentTabIndex === repeatItem.index ? '#6200EE' : '#666666')
              .fontWeight(this.currentTabIndex === repeatItem.index ? FontWeight.Bold : FontWeight.Normal)
              .padding({
                top: 12,
                bottom: 8,
                left: 16,
                right: 16
              })

            // 选中指示器
            if (this.currentTabIndex === repeatItem.index) {
              Divider()
                .color('#6200EE')
                .height(3)
                .width(24)
                .margin({ top: 0 })
            } else {
              Blank().height(3)
            }
          }
          .onClick(() => {
            this.currentTabIndex = repeatItem.index
            this.tabController.changeIndex(repeatItem.index)
            this.tabBarScroller.scrollToIndex(repeatItem.index, true, ScrollAlign.CENTER)
          })
        }
      })
    }
    .listDirection(Axis.Horizontal)
    .scrollBar(BarState.Off)
    .backgroundColor(Color.White)
    .height(48)
    .width('100%')
    .alignListItem(ListItemAlign.Center)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  /**
   * 根据 Tab 索引构建对应内容
   */
  @Builder
  buildTabContent(index: number) {
    if (index === 0) {
      // 分类歌单
      CategoryFolderPage()
    } else if (index === 1) {
      // 首页推荐
      HomeRecommendView()
    } else if (index === 2) {
      // 视频（MV）
      HomeVideoView()
    } else if (index === 3) {
      // AI 功能
      PlaceholderPage({ title: 'AI功能' })
    } else if (index === 4) {
      // 音乐馆
      MusicHallPage()
    } else if (index === 5) {
      // 专区
      AreaSectionView()
    } else if (index === 6) {
      // 长音频
      LongAudioPage()
    } else if (index === 7) {
      // 多人点歌
      PlaceholderPage({ title: '多人点歌' })
    } else if (index === 8) {
      // 运营歌单
      CustomSongListView()
    }
  }
}

// 分类歌单页
@ComponentV2
struct CategoryFolderPage {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()

  aboutToAppear() {
    if (this.homeViewModel.categories.length === 0) {
      this.homeViewModel.fetchCategory()
    }
  }

  build() {
    Column() {
      if (this.homeViewModel.isLoadingCategory) {
        // 加载中
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
      } else if (this.homeViewModel.categories.length === 0) {
        // 空状态
        Column() {
          Image($r('app.media.icon_home_placeholder'))
            .width(64)
            .height(64)
            .opacity(0.3)
          Text('暂无分类数据')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 12 })
          Button('重新加载')
            .margin({ top: 16 })
            .onClick(() => {
              this.homeViewModel.fetchCategory()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 分类列表
        List() {
          Repeat(this.homeViewModel.categories).each((repeatItem) => {
            ListItem() {
              CategorySectionView({ topCategory: repeatItem.item })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// 占位页（用于尚未实现的 Tab 内容）
@ComponentV2
struct PlaceholderPage {
  @Param title: string = ''

  build() {
    Column() {
      Image($r('app.media.icon_home_placeholder'))
        .width(64)
        .height(64)
        .opacity(0.3)
      Text(this.title)
        .fontSize(18)
        .fontColor(Color.Gray)
        .margin({ top: 16 })
      Text('功能开发中...')
        .fontSize(14)
        .fontColor('#AAAAAA')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}
