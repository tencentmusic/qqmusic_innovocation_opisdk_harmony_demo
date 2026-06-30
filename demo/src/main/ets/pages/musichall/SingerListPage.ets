import { MLog } from '@qqmusic/opisdk-base'
import { ISinger } from '@qqmusic/opisdk-qmutils'
import {
  SingerListViewModel,
  FILTER_AREAS,
  FILTER_SEX,
  FILTER_GENRE,
  FILTER_INDEX,
  FilterCategory,
  FilterOption,
  FilterIndexOption
} from '../../viewmodel/musichall/SingerListViewModel'
import { NavController } from '../../nav/NavController'
import { SingerDetailPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'SingerListPage'

/**
 * 悬浮播放器栏高度（与 FloatingPlayerPage 保持一致）
 */
const FLOATING_PLAYER_HEIGHT = 70

/**
 * 歌手列表页面
 *
 * 筛选设计：
 * - 顶部：4 个分类标签按钮（地区/性别/流派/索引），点击展开下拉面板
 * - 下拉面板：网格布局展示具体筛选项，选中后自动关闭面板并刷新列表
 * - 列表：使用 Repeat 懒加载 + key 优化性能
 * - 底部预留播放器栏高度，避免筛选面板被遮挡
 */
@ComponentV2
export struct SingerListPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: SingerListViewModel = new SingerListViewModel()

  /**
   * 底部播放器栏占用的可视高度
   * 非首页时 FloatingPlayerPage margin bottom = -bottomSafeArea，
   * 实际可视高度 = FLOATING_PLAYER_HEIGHT - bottomSafeArea
   */
  private get playerBarVisibleHeight(): number {
    return Math.max(0, FLOATING_PLAYER_HEIGHT - AppUtil.bottomSafeArea)
  }

  aboutToAppear(): void {
    this.viewModel.loadData()
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          // 顶部标题栏
          this.buildHeader()

          // 筛选栏（分类标签按钮行）
          this.buildFilterTabBar()

          // 主内容区
          this.buildContentArea()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')

        // 下拉筛选面板（覆盖在内容区上方，底部避开播放器栏）
        if (this.viewModel.activeFilterCategory !== null) {
          Column() {
            // 半透明遮罩
            Blank()
              .width('100%')
              .layoutWeight(1)
              .onClick(() => {
                this.viewModel.closeFilterPanel()
              })

            // 筛选面板
            this.buildFilterDropdownPanel()
          }
          .width('100%')
          .height('100%')
          .padding({ bottom: this.playerBarVisibleHeight })
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  // ========= 标题栏 =========
  @Builder
  buildHeader(): void {
    Row() {
      Image($r('app.media.ic_back_dark'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.navController.pop()
        })

      Text('歌手')
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

  // ========= 筛选分类标签栏 =========

  @Builder
  buildFilterTabBar(): void {
    Row({ space: 0 }) {
      this.buildAreaTab()
      this.buildSexTab()
      this.buildGenreTab()
      this.buildIndexTab()
    }
    .width('100%')
    .height(44)
    .backgroundColor(Color.White)
    .border({
      width: { bottom: 0.5 },
      color: '#E0E0E0'
    })
  }

  @Builder
  buildAreaTab(): void {
    Row({ space: 4 }) {
      Text(this.viewModel.selectedAreaLabel)
        .fontSize(14)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.AREA ? '#6200EE' : '#333333')
        .fontWeight(this.viewModel.activeFilterCategory === FilterCategory.AREA ? FontWeight.Medium : FontWeight.Normal)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.viewModel.activeFilterCategory === FilterCategory.AREA ? '▲' : '▼')
        .fontSize(10)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.AREA ? '#6200EE' : '#999999')
    }
    .height(44)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .onClick(() => {
      this.viewModel.toggleFilterPanel(FilterCategory.AREA)
    })
  }

  @Builder
  buildSexTab(): void {
    Row({ space: 4 }) {
      Text(this.viewModel.selectedSexLabel)
        .fontSize(14)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.SEX ? '#6200EE' : '#333333')
        .fontWeight(this.viewModel.activeFilterCategory === FilterCategory.SEX ? FontWeight.Medium : FontWeight.Normal)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.viewModel.activeFilterCategory === FilterCategory.SEX ? '▲' : '▼')
        .fontSize(10)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.SEX ? '#6200EE' : '#999999')
    }
    .height(44)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .onClick(() => {
      this.viewModel.toggleFilterPanel(FilterCategory.SEX)
    })
  }
  @Builder
  buildGenreTab(): void {
    Row({ space: 4 }) {
      Text(this.viewModel.selectedGenreLabel)
        .fontSize(14)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.GENRE ? '#6200EE' : '#333333')
        .fontWeight(this.viewModel.activeFilterCategory === FilterCategory.GENRE ? FontWeight.Medium : FontWeight.Normal)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.viewModel.activeFilterCategory === FilterCategory.GENRE ? '▲' : '▼')
        .fontSize(10)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.GENRE ? '#6200EE' : '#999999')
    }
    .height(44)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .onClick(() => {
      this.viewModel.toggleFilterPanel(FilterCategory.GENRE)
    })
  }

  @Builder
  buildIndexTab(): void {
    Row({ space: 4 }) {
      Text(this.viewModel.selectedIndexLabel)
        .fontSize(14)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.INDEX ? '#6200EE' : '#333333')
        .fontWeight(this.viewModel.activeFilterCategory === FilterCategory.INDEX ? FontWeight.Medium : FontWeight.Normal)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.viewModel.activeFilterCategory === FilterCategory.INDEX ? '▲' : '▼')
        .fontSize(10)
        .fontColor(this.viewModel.activeFilterCategory === FilterCategory.INDEX ? '#6200EE' : '#999999')
    }
    .height(44)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .onClick(() => {
      this.viewModel.toggleFilterPanel(FilterCategory.INDEX)
    })
  }

  // ========= 下拉筛选面板 =========

  @Builder
  buildFilterDropdownPanel(): void {
    Column() {
      if (this.viewModel.activeFilterCategory === FilterCategory.AREA) {
        this.buildAreaFilterGrid()
      } else if (this.viewModel.activeFilterCategory === FilterCategory.SEX) {
        this.buildSexFilterGrid()
      } else if (this.viewModel.activeFilterCategory === FilterCategory.GENRE) {
        this.buildGenreFilterGrid()
      } else if (this.viewModel.activeFilterCategory === FilterCategory.INDEX) {
        this.buildIndexFilterGrid()
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ bottomLeft: 12, bottomRight: 12 })
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
    .padding({ left: 12, right: 12, top: 8, bottom: 12 })
  }

  @Builder
  buildAreaFilterGrid(): void {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
      Repeat<FilterOption>(FILTER_AREAS)
        .each((item: RepeatItem<FilterOption>): void => {
          Text(item.item.label)
            .fontSize(13)
            .fontColor(this.viewModel.selectedArea === item.item.value ? Color.White : '#333333')
            .backgroundColor(this.viewModel.selectedArea === item.item.value ? '#6200EE' : '#F0F0F0')
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: 8, bottom: 8 })
            .onClick((): void => {
              this.viewModel.selectArea(item.item.value)
            })
        })
    }
    .width('100%')
  }

  @Builder
  buildSexFilterGrid(): void {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
      Repeat<FilterOption>(FILTER_SEX)
        .each((item: RepeatItem<FilterOption>): void => {
          Text(item.item.label)
            .fontSize(13)
            .fontColor(this.viewModel.selectedSex === item.item.value ? Color.White : '#333333')
            .backgroundColor(this.viewModel.selectedSex === item.item.value ? '#6200EE' : '#F0F0F0')
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: 8, bottom: 8 })
            .onClick((): void => {
              this.viewModel.selectSex(item.item.value)
            })
        })
    }
    .width('100%')
  }

  @Builder
  buildGenreFilterGrid(): void {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
      Repeat<FilterOption>(FILTER_GENRE)
        .each((item: RepeatItem<FilterOption>): void => {
          Text(item.item.label)
            .fontSize(13)
            .fontColor(this.viewModel.selectedGenre === item.item.value ? Color.White : '#333333')
            .backgroundColor(this.viewModel.selectedGenre === item.item.value ? '#6200EE' : '#F0F0F0')
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: 8, bottom: 8 })
            .onClick((): void => {
              this.viewModel.selectGenre(item.item.value)
            })
        })
    }
    .width('100%')
  }
  @Builder
  buildIndexFilterGrid(): void {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
      Repeat<FilterIndexOption>(FILTER_INDEX)
        .each((item: RepeatItem<FilterIndexOption>): void => {
          Text(item.item.label)
            .fontSize(13)
            .fontColor(this.viewModel.selectedIndex === item.item.value ? Color.White : '#333333')
            .backgroundColor(this.viewModel.selectedIndex === item.item.value ? '#6200EE' : '#F0F0F0')
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: 8, bottom: 8 })
            .onClick((): void => {
              this.viewModel.selectIndex(item.item.value)
            })
        })
    }
    .width('100%')
  }

  // ========= 主内容区 =========

  @Builder
  buildContentArea(): void {
    if (this.viewModel.isLoading && this.viewModel.singerList.length === 0) {
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
    } else if (!this.viewModel.isLoading && this.viewModel.hasError && this.viewModel.singerList.length === 0) {
      // 加载失败
      Column() {
        Image($r('app.media.icon_home_placeholder'))
          .width(64)
          .height(64)
          .opacity(0.3)
        Text('加载失败，请重试')
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
    } else if (!this.viewModel.isLoading && !this.viewModel.hasError && this.viewModel.singerList.length === 0) {
      // 空数据
      Column() {
        Image($r('app.media.icon_home_placeholder'))
          .width(64)
          .height(64)
          .opacity(0.3)
        Text('暂无歌手数据')
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      // 歌手网格列表
      Grid() {
        Repeat<ISinger>(this.viewModel.singerList)
          .each((repeatItem: RepeatItem<ISinger>): void => {
            GridItem() {
              this.buildSingerItem(repeatItem.item)
            }
          })
          .key((item: ISinger, index: number): string => {
            return `${item.getSingerId()}_${index}`
          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 12 })
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(16)
      .scrollBar(BarState.Auto)
      .onClick(() => {
        // 点击列表空白区域关闭筛选面板
        this.viewModel.closeFilterPanel()
      })
    }
  }

  // ========= 歌手列表项 =========

  @Builder
  buildSingerItem(singer: ISinger): void {
    Column({ space: 8 }) {
      // 歌手头像
      Image(singer.getSingerPic() ?? '')
        .width('100%')
        .aspectRatio(1)
        .objectFit(ImageFit.Cover)
        .borderRadius('50%')
        .backgroundColor('#E0E0E0')

      // 歌手名字
      Text(singer.getSingerName())
        .fontSize(14)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      MLog.i(TAG, `click singer: ${singer.getSingerName()}, id: ${singer.getSingerId()}`)
      const params = new SingerDetailPageParams(
        singer.getSingerId(),
        singer.getSingerMid() ?? '',
        singer.getSingerName()
      )
      this.navController.push(RouteName.SINGER_DETAIL_PAGE, params)
    })
  }
}

@Builder
export function SingerListPageBuilder(params: Object): void {
  SingerListPage()
}
