import { LongAudioCategoryViewModel } from '../../viewmodel/longaudio/LongAudioCategoryViewModel'
import { NavController } from '../../nav/NavController'
import { LongAudioCategoryPageParams, SongListPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { IAlbum } from '@qqmusic/opisdk-entity'
import { LongAudioAlbumItemView } from '../../view/longaudio/LongAudioAlbumItemView'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { AppUtil } from '../../utils/AppUtil'

/**
 * 长音频分类筛选二级页
 */
@ComponentV2
export struct LongAudioCategoryPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: LongAudioCategoryViewModel = new LongAudioCategoryViewModel()
  private topTabScroller: ListScroller = new ListScroller()
  private subTabScroller: ListScroller = new ListScroller()
  private albumListScroller: ListScroller = new ListScroller()

  aboutToAppear(): void {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as LongAudioCategoryPageParams
      if (raw) {
        this.viewModel.tag = raw.tag
        this.viewModel.categoryId = raw.categoryId
        this.viewModel.subCategoryId = raw.subCategoryId
        this.viewModel.intArrVal = raw.intArrVal
        this.viewModel.fetchCategories()
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.buildHeader()

        if (this.viewModel.isLoadingCategories && this.viewModel.categories.length === 0) {
          Column() {
            LoadingProgress().width(48).height(48).color('#6200EE')
            Text('加载中...').fontSize(14).fontColor(Color.Gray).margin({ top: 8 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else if (this.viewModel.categories.length === 0 && !this.viewModel.isLoadingCategories) {
          Column() {
            Image($r('app.media.icon_home_placeholder')).width(64).height(64).opacity(0.3)
            Text('暂无分类数据').fontSize(14).fontColor(Color.Gray).margin({ top: 12 })
            Button('重新加载').margin({ top: 16 }).onClick(() => { this.viewModel.fetchCategories() })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {
          // 一级分类 Tab
          if (this.viewModel.categories.length > 0) {
            List({ scroller: this.topTabScroller }) {
              Repeat(this.viewModel.categories).each((repeatItem) => {
                ListItem() {
                  Text(repeatItem.item.name)
                    .fontSize(14)
                    .fontColor(this.viewModel.currentCategoryIndex === repeatItem.index ? '#6200EE' : '#666666')
                    .fontWeight(this.viewModel.currentCategoryIndex === repeatItem.index ? FontWeight.Bold : FontWeight.Normal)
                    .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                    .onClick(() => {
                      this.viewModel.selectCategory(repeatItem.index)
                      this.topTabScroller.scrollToIndex(repeatItem.index, true, ScrollAlign.CENTER)
                      this.albumListScroller.scrollToIndex(0, true, ScrollAlign.START)
                    })
                }
              })
            }
            .listDirection(Axis.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%').height(36).backgroundColor(Color.White)
            .onAppear(() => {
              if (this.viewModel.currentCategoryIndex > 0) {
                this.topTabScroller.scrollToIndex(this.viewModel.currentCategoryIndex, true, ScrollAlign.CENTER)
              }
            })
          }

          // 二级分类 Tab
          if (this.viewModel.currentSubCategories.length > 0) {
            List({ scroller: this.subTabScroller }) {
              Repeat(this.viewModel.currentSubCategories).each((repeatItem) => {
                ListItem() {
                  Text(repeatItem.item.name)
                    .fontSize(12)
                    .fontColor(this.viewModel.currentSubCategoryIndex === repeatItem.index ? '#6200EE' : '#999999')
                    .fontWeight(this.viewModel.currentSubCategoryIndex === repeatItem.index ? FontWeight.Medium : FontWeight.Normal)
                    .padding({ top: 6, bottom: 6, left: 10, right: 10 })
                    .onClick(() => {
                      this.viewModel.selectSubCategory(repeatItem.index)
                      this.subTabScroller.scrollToIndex(repeatItem.index, true, ScrollAlign.CENTER)
                      this.albumListScroller.scrollToIndex(0, true, ScrollAlign.START)
                    })
                }
              })
            }
            .listDirection(Axis.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%').height(28).backgroundColor('#FAFAFA')
            .onAppear(() => {
              if (this.viewModel.currentSubCategoryIndex > 0) {
                this.subTabScroller.scrollToIndex(this.viewModel.currentSubCategoryIndex, true, ScrollAlign.CENTER)
              }
            })
          }

          // 筛选标签行 + 排序切换
          Row({ space: 8 }) {
            Scroll() {
              Row({ space: 6 }) {
                Repeat(this.viewModel.filters).each((repeatItem) => {
                  Text(repeatItem.item.name)
                    .fontSize(12)
                    .fontColor(this.viewModel.currentFilterIndex === repeatItem.index ? Color.White : '#666666')
                    .backgroundColor(this.viewModel.currentFilterIndex === repeatItem.index ? '#6200EE' : '#F0F0F0')
                    .borderRadius(14)
                    .padding({ top: 4, bottom: 4, left: 10, right: 10 })
                    .onClick(() => {
                      this.viewModel.selectFilter(repeatItem.index)
                      this.albumListScroller.scrollToIndex(0, true, ScrollAlign.START)
                    })
                })
              }
            }
            .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
            .layoutWeight(1)

            Text(this.viewModel.sortType === 0 ? '最新' : '最热')
              .fontSize(12)
              .fontColor('#6200EE')
              .padding({ left: 8, right: 8 })
              .onClick(() => {
                this.viewModel.toggleSortType()
                this.albumListScroller.scrollToIndex(0, true, ScrollAlign.START)
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(Color.White)

          if (this.viewModel.isLoading && this.viewModel.albumList.length === 0) {
            Column() {
              LoadingProgress().width(36).height(36).color('#6200EE')
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.viewModel.albumList.length === 0) {
            Column() {
              Image($r('app.media.icon_home_placeholder')).width(64).height(64).opacity(0.3)
              Text('暂无专辑数据').fontSize(14).fontColor(Color.Gray).margin({ top: 12 })
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          } else {
            List({ scroller: this.albumListScroller }) {
              Repeat(this.viewModel.albumList).each((repeatItem) => {
                ListItem() {
                  LongAudioAlbumItemView({
                    album: repeatItem.item,
                    onCollect: (album: IAlbum): void => {
                      this.viewModel.toggleAlbumCollect(album, repeatItem.index)
                    },
                    onItemClick: (album: IAlbum): void => {
                      const params = new SongListPageParams(
                        MusicListType.TYPE_ALBUM,
                        album.getId(),
                        album.getName()
                      )
                      this.navController.push(RouteName.SONG_LIST_PAGE, params)
                    }
                  })
                }
              })
            }
            .width('100%').layoutWeight(1)
            .edgeEffect(EdgeEffect.Spring)
            .scrollBar(BarState.Off)
            .onReachEnd(() => {
              this.viewModel.loadData(true)
            })
            .padding({ left: 12, right: 12 })
          }
        }
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5').padding({ bottom: 70 - AppUtil.bottomSafeArea })
    }
    .hideTitleBar(true)
  }

  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_back_dark')).width(24).height(24)
        .onClick(() => { this.navController.pop() })
      Text(this.viewModel.tag ? `长音频分类 - ${this.viewModel.tag}` : '长音频分类')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        .layoutWeight(1).textAlign(TextAlign.Center).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Blank().width(24)
    }
    .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
  }
}

@Builder
export function LongAudioCategoryPageBuilder(params: Object) {
  LongAudioCategoryPage()
}
