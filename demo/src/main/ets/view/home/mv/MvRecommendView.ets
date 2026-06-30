import { HomeViewModel } from '../../../viewmodel/HomeViewModel'
import { GetMVRecommendCmd, AreaID, CategoryType } from '@qqmusic/opisdk-entity'
import { MvRecommendItemView } from './MvRecommendItemView'

const TAG = 'MvRecommendView'

/**
 * MV 推荐筛选状态
 */
class MvRecommendFilterState {
  type: GetMVRecommendCmd
  areaID: AreaID
  category: CategoryType

  constructor(type: GetMVRecommendCmd, areaID: AreaID, category: CategoryType) {
    this.type = type
    this.areaID = areaID
    this.category = category
  }
}

/**
 * MV 推荐列表视图（含类型/地区/分类筛选）
 */
@ComponentV2
export struct MvRecommendView {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()
  @Local filterState: MvRecommendFilterState = new MvRecommendFilterState(
    GetMVRecommendCmd.LATEST, AreaID.Mainland, CategoryType.ALL
  )

  aboutToAppear() {
    this.loadRecommend()
  }

  private loadRecommend(): void {
    this.homeViewModel.fetchMvRecommendWithFilter(
      this.filterState.type, this.filterState.areaID, this.filterState.category
    )
  }

  private get typeLabel(): string {
    switch (this.filterState.type) {
      case GetMVRecommendCmd.LATEST:
        return '最新'
      case GetMVRecommendCmd.HOTTEST:
        return '最热'
      default:
        return '最新'
    }
  }

  private get areaLabel(): string {
    switch (this.filterState.areaID) {
      case AreaID.Recommend:
        return '推荐'
      case AreaID.Mainland:
        return '内地'
      case AreaID.Korea:
        return '韩国'
      case AreaID.HKorTW:
        return '港台'
      case AreaID.Occident:
        return '欧美'
      case AreaID.Japan:
        return '日本'
      default:
        return '内地'
    }
  }

  private get categoryLabel(): string {
    switch (this.filterState.category) {
      case CategoryType.ALL:
        return '全部'
      case CategoryType.MV:
        return 'MV'
      case CategoryType.LIVE:
        return '现场'
      case CategoryType.COVER:
        return '翻唱'
      case CategoryType.DANCE:
        return '舞蹈'
      case CategoryType.MOVIE:
        return '影视'
      case CategoryType.VARIETY:
        return '综艺'
      case CategoryType.KIDS:
        return '儿歌'
      default:
        return '全部'
    }
  }

  build() {
    Column() {
      // 筛选栏
      this.buildFilterBar()

      // 加载中
      if (this.homeViewModel.isLoadingMv) {
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
      } else if (this.homeViewModel.mvRecommendDetailList.length === 0) {
        // 空状态
        Column() {
          Image($r('app.media.icon_home_placeholder'))
            .width(64)
            .height(64)
            .opacity(0.3)
          Text('暂无MV推荐')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 12 })
          Button('重新加载')
            .margin({ top: 16 })
            .onClick(() => {
              this.loadRecommend()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // MV 列表
        List() {
          Repeat(this.homeViewModel.mvRecommendDetailList).each((repeatItem) => {
            ListItem() {
              MvRecommendItemView({ mvItem: repeatItem.item })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .divider({
          strokeWidth: 0.5,
          color: '#F0F0F0',
          startMargin: 16,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildFilterBar() {
    Row({ space: 8 }) {
      // 类型筛选
      this.buildTypeFilterChip()

      // 地区筛选
      this.buildAreaFilterChip()

      // 分类筛选
      this.buildCategoryFilterChip()
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  buildTypeFilterChip() {
    Row({ space: 4 }) {
      Text('类型')
        .fontSize(12)
        .fontColor('#999999')
      Text(this.typeLabel)
        .fontSize(13)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
      Text('▼')
        .fontSize(10)
        .fontColor('#999999')
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .border({ width: 1, color: '#E0E0E0', radius: 16 })
    .bindMenu([
      { value: '最新', action: () => {
        this.filterState = new MvRecommendFilterState(GetMVRecommendCmd.LATEST, this.filterState.areaID, this.filterState.category)
        this.loadRecommend()
      }},
      { value: '最热', action: () => {
        this.filterState = new MvRecommendFilterState(GetMVRecommendCmd.HOTTEST, this.filterState.areaID, this.filterState.category)
        this.loadRecommend()
      }}
    ])
  }

  @Builder
  buildAreaFilterChip() {
    Row({ space: 4 }) {
      Text('地区')
        .fontSize(12)
        .fontColor('#999999')
      Text(this.areaLabel)
        .fontSize(13)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
      Text('▼')
        .fontSize(10)
        .fontColor('#999999')
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .border({ width: 1, color: '#E0E0E0', radius: 16 })
    .bindMenu([
      { value: '推荐', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, AreaID.Recommend, this.filterState.category)
        this.loadRecommend()
      }},
      { value: '内地', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, AreaID.Mainland, this.filterState.category)
        this.loadRecommend()
      }},
      { value: '港台', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, AreaID.HKorTW, this.filterState.category)
        this.loadRecommend()
      }},
      { value: '欧美', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, AreaID.Occident, this.filterState.category)
        this.loadRecommend()
      }},
      { value: '韩国', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, AreaID.Korea, this.filterState.category)
        this.loadRecommend()
      }},
      { value: '日本', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, AreaID.Japan, this.filterState.category)
        this.loadRecommend()
      }}
    ])
  }

  @Builder
  buildCategoryFilterChip() {
    Row({ space: 4 }) {
      Text('分类')
        .fontSize(12)
        .fontColor('#999999')
      Text(this.categoryLabel)
        .fontSize(13)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
      Text('▼')
        .fontSize(10)
        .fontColor('#999999')
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .border({ width: 1, color: '#E0E0E0', radius: 16 })
    .bindMenu([
      { value: '全部', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.ALL)
        this.loadRecommend()
      }},
      { value: 'MV', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.MV)
        this.loadRecommend()
      }},
      { value: '现场', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.LIVE)
        this.loadRecommend()
      }},
      { value: '翻唱', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.COVER)
        this.loadRecommend()
      }},
      { value: '舞蹈', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.DANCE)
        this.loadRecommend()
      }},
      { value: '影视', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.MOVIE)
        this.loadRecommend()
      }},
      { value: '综艺', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.VARIETY)
        this.loadRecommend()
      }},
      { value: '儿歌', action: () => {
        this.filterState = new MvRecommendFilterState(this.filterState.type, this.filterState.areaID, CategoryType.KIDS)
        this.loadRecommend()
      }}
    ])
  }
}
