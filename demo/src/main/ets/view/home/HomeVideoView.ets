import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { MvAreaPageParams } from './mv/MvAreaPage'
import { SpecialArea } from '@qqmusic/opisdk-entity'
import { MLog } from '@qqmusic/opisdk-base'

const TAG = 'HomeVideoView'

/**
 * 视频 Tab 入口卡片数据
 */
class VideoEntryItem {
  title: string
  subtitle: string
  icon: ResourceStr

  constructor(title: string, subtitle: string, icon: ResourceStr) {
    this.title = title
    this.subtitle = subtitle
    this.icon = icon
  }
}

/**
 * 首页视频 Tab 主视图
 */
@ComponentV2
export struct HomeVideoView {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()

  private get entryList(): VideoEntryItem[] {
    return [
      new VideoEntryItem('最新最热的MV', '热门MV推荐', $r('app.media.icon_home_placeholder')),
      new VideoEntryItem('Dolby视界专区', '杜比全景声体验', $r('app.media.icon_home_placeholder')),
      new VideoEntryItem('4K臻品世界', '超高清视听盛宴', $r('app.media.icon_home_placeholder'))
    ]
  }

  aboutToAppear() {
    MLog.i(TAG, 'HomeVideoView aboutToAppear')
  }

  build() {
    Column() {
      // 标题
      Text('视频专区')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .padding({ left: 16, top: 16, bottom: 12 })
        .width('100%')

      // 2列网格入口
      Grid() {
        Repeat(this.entryList).each((repeatItem) => {
          GridItem() {
            this.buildEntryCard(repeatItem.item, repeatItem.index)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .padding({ left: 16, right: 16 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildEntryCard(item: VideoEntryItem, index: number) {
    Column({ space: 8 }) {
      Image(item.icon)
        .width(60)
        .height(60)
        .objectFit(ImageFit.Contain)
        .opacity(0.6)

      Text(item.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)

      Text(item.subtitle)
        .fontSize(12)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(140)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .onClick(() => {
      this.onEntryClick(index)
    })
  }

  /**
   * 处理入口卡片点击
   */
  private onEntryClick(index: number): void {
    if (index === 0) {
      this.navController.push(RouteName.MV_RECOMMEND_PAGE)
    } else if (index === 1) {
      const params = new MvAreaPageParams(SpecialArea.Dolby)
      this.navController.push(RouteName.MV_AREA_PAGE, params)
    } else if (index === 2) {
      const params = new MvAreaPageParams(SpecialArea.Excellent)
      this.navController.push(RouteName.MV_AREA_PAGE, params)
    }
  }
}
