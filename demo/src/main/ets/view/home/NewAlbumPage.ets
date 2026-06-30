import { IAlbum, IAreaInfo } from '@qqmusic/opisdk-entity'
import { NewAlbumViewModel } from '../../viewmodel/NewAlbumViewModel'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { SongListPageParams } from '../../nav/RouteParams'
import { MLog } from '@qqmusic/opisdk-base'
import { MusicListType, ISinger } from '@qqmusic/opisdk-qmutils'

const TAG = 'NewAlbumPage'

/**
 * 专辑类型筛选选项
 */
const FILTER_TYPE_LIST: FilterTypeItem[] = [
  { label: '全部', value: null },
  { label: '单曲', value: 10 },
  { label: 'EP', value: 11 },
  { label: '录音室专辑', value: 0 },
  { label: '现场专辑', value: 1 },
]

interface FilterTypeItem {
  label: string
  value: number | null
}

/**
 * 新碟专区页面
 * 对应 Android 端 NewAlbumPage.kt
 *
 * 功能：
 * - 顶部 Tab 栏切换不同地区
 * - 水平滑动切换地区页面
 * - 每个地区页面包含：类型筛选下拉 + 专辑列表
 * - 支持加载更多
 */
@ComponentV2
export struct NewAlbumPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: NewAlbumViewModel = new NewAlbumViewModel()

  /** 当前选中的 Tab 索引 */
  @Local currentTabIndex: number = 0
  /** Tab 控制器 */
  private tabController: TabsController = new TabsController()

  aboutToAppear(): void {
    MLog.i(TAG, 'NewAlbumPage aboutToAppear')
    this.viewModel.fetchNewAlbumAreaList()
  }

  aboutToDisappear(): void {
    MLog.i(TAG, 'NewAlbumPage aboutToDisappear')
    this.viewModel.clear()
  }

  /**
   * 监听 Tab 切换，自动加载对应地区的专辑数据
   */
  @Monitor('currentTabIndex')
  onTabIndexChanged(monitor: IMonitor) {
    const index = monitor.value<number>()?.now
    if (index !== undefined && this.viewModel.areaList.length > 0) {
      const areaId = this.viewModel.areaList[index]?.id
      if (areaId !== undefined && this.viewModel.getAlbumList(areaId).length === 0 && !this.viewModel.isLoading(areaId)) {
        MLog.i(TAG, `Tab switched to index=${index}, loading album for areaId=${areaId}`)
        this.viewModel.fetchNewAlbum(areaId, null)
      }
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      // this.buildTopBar()

      // 内容区域
      if (this.viewModel.isLoadingArea) {
        this.buildLoadingState()
      } else if (this.viewModel.areaList.length === 0 && this.viewModel.areaErrorMsg.length > 0) {
        this.buildErrorState()
      } else if (this.viewModel.areaList.length === 0) {
        this.buildEmptyState()
      } else {
        this.buildContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildTopBar() {
    Row() {
      Image($r('app.media.icon_back_placeholder'))
        .width(24)
        .height(24)
        .margin({ left: 16, top: 12, bottom: 12 })
        .onClick(() => {
          this.navController.pop()
        })

      Text('新碟专区')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ top: 12, bottom: 12 })

      Blank()
        .width(40)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  buildLoadingState() {
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
  }

  @Builder
  buildErrorState() {
    Column() {
      Image($r('app.media.icon_home_placeholder'))
        .width(64)
        .height(64)
        .opacity(0.3)
      Text(this.viewModel.areaErrorMsg)
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 12 })
      Button('重新加载')
        .margin({ top: 16 })
        .onClick(() => {
          this.viewModel.fetchNewAlbumAreaList()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState() {
    Column() {
      Image($r('app.media.icon_home_placeholder'))
        .width(64)
        .height(64)
        .opacity(0.3)
      Text('暂无地区数据')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildContent() {
    Tabs({
      index: this.currentTabIndex,
      controller: this.tabController
    }) {
      ForEach(this.viewModel.areaList, (area: IAreaInfo, index: number) => {
        TabContent() {
          this.buildAreaAlbumContent(area.id)
        }
        .tabBar(this.buildTabLabel(area, index))
        .onAppear(() => {
          // Tab 内容首次出现时加载数据
          if (this.viewModel.getAlbumList(area.id).length === 0 && !this.viewModel.isLoading(area.id)) {
            MLog.i(TAG, `Tab content appear, loading album for areaId=${area.id}`)
            this.viewModel.fetchNewAlbum(area.id, null)
          }
        })
      })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(true)
    .barMode(BarMode.Scrollable)
    .barHeight(44)
    .backgroundColor(Color.White)
    .onChange((index: number) => {
      this.currentTabIndex = index
      MLog.i(TAG, `Tab changed to index: ${index}, areaId: ${this.viewModel.areaList[index]?.id}`)
    })
  }
  /**
   * 构建 Tab 标签
   */
  @Builder
  buildTabLabel(area: IAreaInfo, index: number) {
    Column() {
      Text(area.name ?? `地区${area.id}`)
        .fontSize(15)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? '#333333' : '#888888')
        .padding({ left: 16, right: 16 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
  }

  /**
   * 构建某个地区的专辑内容（类型筛选 + 专辑列表）
   */
  @Builder
  buildAreaAlbumContent(areaId: number) {
    Column() {
      // 类型筛选下拉按钮
      this.buildFilterDropdown(areaId)

      // 专辑列表
      this.buildAlbumList(areaId)
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建类型筛选下拉按钮
   */
  @Builder
  buildFilterDropdown(areaId: number) {
    Row() {
      Blank()

      Button() {
        Row({ space: 4 }) {
          Text(this.getFilterLabel(areaId))
            .fontSize(14)
            .fontColor('#333333')

          Image($r('sys.media.ohos_ic_public_arrow_down'))
            .width(16)
            .height(16)
        }
        .alignItems(VerticalAlign.Center)
      }
      .type(ButtonType.Normal)
      .backgroundColor(Color.White)
      .border({ width: 1, color: '#DDDDDD', radius: 16 })
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .margin({ right: 16, top: 8, bottom: 4 })
      .bindMenu(this.buildFilterMenu(areaId))
    }
    .width('100%')
  }

  /**
   * 构建筛选菜单
   */
  @Builder
  buildFilterMenu(areaId: number) {
    Menu() {
      ForEach(FILTER_TYPE_LIST, (item: FilterTypeItem) => {
        MenuItem({
          content: item.label,
        })
          .onClick(() => {
            MLog.i(TAG, `Filter selected: ${item.label}, type=${item.value}, areaId=${areaId}`)
            this.viewModel.fetchNewAlbum(areaId, item.value)
          })
      })
    }
  }

  /**
   * 获取当前筛选标签文本
   */
  private getFilterLabel(areaId: number): string {
    const currentType = this.viewModel.getType(areaId)
    const found = FILTER_TYPE_LIST.find((item: FilterTypeItem) => item.value === currentType)
    return found ? found.label : '筛选'
  }

  /**
   * 构建专辑列表
   */
  @Builder
  buildAlbumList(areaId: number) {
    List() {
      // 专辑列表项
      ForEach(this.viewModel.getAlbumList(areaId), (album: IAlbum, index: number) => {
        ListItem() {
          this.buildAlbumItem(album)
        }
      })

      // 加载更多 / 底部提示
      ListItem() {
        this.buildLoadMoreItem(areaId)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .onReachEnd(() => {
      // 滚动到底部时加载更多
      if (this.viewModel.hasMore(areaId) && !this.viewModel.isLoading(areaId)) {
        MLog.i(TAG, `Reach end, loading more for areaId=${areaId}`)
        this.viewModel.fetchMoreNewAlbum(areaId)
      }
    })
  }

  /**
   * 构建单个专辑项
   */
  @Builder
  buildAlbumItem(album: IAlbum) {
    Row({ space: 12 }) {
      // 专辑封面
      Image(album.getAlbumPic() ?? '')
        .width(56)
        .height(56)
        .objectFit(ImageFit.Cover)
        .borderRadius(4)
        .backgroundColor('#E0E0E0')

      // 专辑信息
      Column({ space: 4 }) {
        Text(album.getName())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.getAlbumSingerName(album))
          .fontSize(13)
          .fontColor('#888888')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(album.getPublicTime() ?? '')
          .fontSize(12)
          .fontColor('#AAAAAA')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor(Color.White)
    .margin({ top: 1 })
    .onClick(() => {
      this.onAlbumClick(album)
    })
  }

  /**
   * 构建加载更多区域
   */
  @Builder
  buildLoadMoreItem(areaId: number) {
    Row() {
      if (this.viewModel.isLoading(areaId)) {
        LoadingProgress()
          .width(20)
          .height(20)
          .color('#31C27C')

        Text('正在加载更多...')
          .fontSize(13)
          .fontColor('#888888')
          .margin({ left: 8 })
      } else if (this.viewModel.hasMore(areaId)) {
        Text('上拉加载更多')
          .fontSize(13)
          .fontColor('#888888')
      } else if (this.viewModel.getAlbumList(areaId).length > 0) {
        Text('已全部加载完毕')
          .fontSize(13)
          .fontColor('#CCCCCC')
      } else {
        Text('暂无数据')
          .fontSize(13)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ top: 8, bottom: 16 })
  }

  /**
   * 获取专辑歌手名
   */
  private getAlbumSingerName(album: IAlbum): string {
    const singers: ISinger[] = album.getSingers()
    if (singers.length > 0) {
      return singers[0].getSingerName() ?? ''
    }
    return album.getSingerName() ?? ''
  }

  /**
   * 专辑点击事件 — 跳转到歌曲列表页
   */
  private onAlbumClick(album: IAlbum): void {
    MLog.i(TAG, `Album clicked: id=${album.getId()}, name=${album.getName()}`)
    const params = new SongListPageParams(
      MusicListType.TYPE_ALBUM,
      album.getId(),
      album.getName()
    )
    this.navController.push(RouteName.SONG_LIST_PAGE, params)
  }
}

/**
 * 页面 Builder 导出（用于路由注册）
 */
@Builder
export function NewAlbumPageBuilder(params: Object) {
  NewAlbumPage()
}
