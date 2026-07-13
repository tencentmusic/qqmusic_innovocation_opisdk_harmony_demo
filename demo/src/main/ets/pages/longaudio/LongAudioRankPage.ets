import { LongAudioRankViewModel } from '../../viewmodel/longaudio/LongAudioRankViewModel'
import { NavController } from '../../nav/NavController'
import { LongAudioRankPageParams, SongListPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { IAlbum } from '@qqmusic/opisdk-entity'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { LongAudioAlbumItemView } from '../../view/longaudio/LongAudioAlbumItemView'
import { AppUtil } from '../../utils/AppUtil'

/**
 * 长音频排行榜二级页
 */
@ComponentV2
export struct LongAudioRankPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local viewModel: LongAudioRankViewModel = new LongAudioRankViewModel()
  private topTabScroller: ListScroller = new ListScroller()
  private subTabScroller: ListScroller = new ListScroller()
  private albumListScroller: ListScroller = new ListScroller()

  aboutToAppear(): void {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as LongAudioRankPageParams
      if (raw) {
        this.viewModel.tag = raw.tag
        this.viewModel.fetchRankCategories()
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.buildHeader()

        if (this.viewModel.isLoading && this.viewModel.albumList.length === 0) {
          Column() {
            LoadingProgress().width(48).height(48).color('#6200EE')
            Text('加载中...').fontSize(14).fontColor(Color.Gray).margin({ top: 8 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else if (this.viewModel.albumList.length === 0 && !this.viewModel.isLoading) {
          Column() {
            Image($r('app.media.icon_home_placeholder')).width(64).height(64).opacity(0.3)
            Text('暂无排行榜数据').fontSize(14).fontColor(Color.Gray).margin({ top: 12 })
            Button('重新加载').margin({ top: 16 }).onClick(() => { this.viewModel.fetchRankCategories() })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {
          // 一级分类 Tab
          if (this.viewModel.topCategories.length > 0) {
            List({ scroller: this.topTabScroller }) {
              Repeat(this.viewModel.topCategories).each((repeatItem) => {
                ListItem() {
                  Text(repeatItem.item.name)
                    .fontSize(14)
                    .fontColor(this.viewModel.currentTopIndex === repeatItem.index ? '#6200EE' : '#666666')
                    .fontWeight(this.viewModel.currentTopIndex === repeatItem.index ? FontWeight.Bold : FontWeight.Normal)
                    .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                    .onClick(() => {
                      this.viewModel.selectTopCategory(repeatItem.index)
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
              if (this.viewModel.currentTopIndex > 0) {
                this.topTabScroller.scrollToIndex(this.viewModel.currentTopIndex, true, ScrollAlign.CENTER)
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
                    .fontColor(this.viewModel.currentSubIndex === repeatItem.index ? '#6200EE' : '#999999')
                    .fontWeight(this.viewModel.currentSubIndex === repeatItem.index ? FontWeight.Medium : FontWeight.Normal)
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
              if (this.viewModel.currentSubIndex > 0) {
                this.subTabScroller.scrollToIndex(this.viewModel.currentSubIndex, true, ScrollAlign.CENTER)
              }
            })
          }

          // 专辑列表 — 横向卡片布局
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

            if (this.viewModel.showAllLoadedTip) {
              ListItem() {
                Text('已全部加载')
                  .fontSize(12)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 12, bottom: 12 })
              }
            }
          }
          .width('100%').layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Off)
          .padding({ left: 12, right: 12 })
          .onReachEnd(() => {
            this.viewModel.onReachListEnd()
          })
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
      Text(`长音频排行榜 - ${this.viewModel.tag}`)
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        .layoutWeight(1).textAlign(TextAlign.Center).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Blank().width(24)
    }
    .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
  }
}

@Builder
export function LongAudioRankPageBuilder(params: Object) {
  LongAudioRankPage()
}