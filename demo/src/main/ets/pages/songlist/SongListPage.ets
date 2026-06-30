import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'
import { NavController } from '../../nav/NavController'
import { SongListPageParams } from '../../nav/RouteParams'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { ListInfoCard } from '../../view/songlist/ListInfoCard'
import { SongListToolbar } from '../../view/songlist/SongListToolbar'
import { SimpleSongListToolbar } from '../../view/songlist/SimpleSongListToolbar'
import { EditorBar } from '../../view/songlist/EditorBar'
import { AddSongDialog } from '../../view/songlist/AddSongDialog'
import { SongListItemView } from '../../view/songlist/SongListItemView'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'SongListPage'

@Builder
export function SongListPageBuilder(params: Object) {
  SongListPage({ args: params })
}

/**
 * 通用歌曲列表页
 * 支持：专辑/歌单/榜单 三种场景
 * 参考安卓 SongListActivity + SongListPage
 */
@ComponentV2
export struct SongListPage {
  @Param args: Object | undefined = undefined
  @Provider('viewModel') viewModel: SongListViewModel = new SongListViewModel()

  aboutToAppear(): void {
    const raw = this.args as SongListPageParams
    if (raw) {
      this.viewModel.playListType = raw.playListType as MusicListType
      if (raw.playListType === MusicListType.TYPE_ALBUM) {
        this.viewModel.albumId = raw.listId
      } else if (raw.playListType === MusicListType.TYPE_FOLDER) {
        this.viewModel.folderId = raw.listId
      } else if (raw.playListType === MusicListType.TYPE_ONLINE) {
        this.viewModel.rankId = raw.listId
      } else if (raw.playListType === MusicListType.TYPE_SINGER) {
        this.viewModel.singerId = raw.listId
        this.viewModel.singerMid = raw.listMid ?? ''
      }
      this.viewModel.listName = raw.listName
      this.viewModel.showSimpleToolbar = raw.showSimpleToolbar === true
      // 指定歌曲ID列表（对应安卓 KEY_SONG / pagingSongIds）
      if (raw.songIds && raw.songIds.length > 0) {
        this.viewModel.targetSongIds = raw.songIds
        this.viewModel.playListType = MusicListType.TYPE_SONG_LIST
      }
      // 场景分类ID列表（对应安卓 KEY_CATEGORY_IDS / pagingSongListScene）
      if (raw.categoryIds && raw.categoryIds.length >= 2) {
        this.viewModel.sceneGroupId = raw.categoryIds[0]
        this.viewModel.sceneSubGroupId = raw.categoryIds[1]
        this.viewModel.playListType = MusicListType.TYPE_SONG_LIST
      }
      // 按场景类型加载数据，避免重复请求和无效调用
      if (this.viewModel.playListType === MusicListType.TYPE_SONG_LIST) {
        // 指定歌曲ID / 场景分类：只需加载歌曲，无需拉取详情
        this.viewModel.loadSongs()
      } else if (this.viewModel.playListType === MusicListType.TYPE_ONLINE || raw.playListType === MusicListType.TYPE_SINGER) {
        // 榜单：fetchAlbumDetail 内部已通过 fetchRankDetail 加载首页歌曲，无需再调 loadSongs
        this.viewModel.fetchAlbumDetail()
      } else {
        // 专辑 / 歌单：先拉详情再拉歌曲，串行执行保证元数据先就绪
        this.viewModel.fetchAlbumDetail().then(() => {
          this.viewModel.loadSongs()
        })
      }
    }
    this.viewModel.registerPlayEventListener()
  }

  aboutToDisappear(): void {
    this.viewModel.unregisterPlayEventListener()
  }

  build() {
    NavDestination() {
      Column() {
        this.buildHeader()

        if ((this.viewModel.isLoading || this.viewModel.isLoadingSongs) && this.viewModel.songList.length === 0) {
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
        } else {
          Scroll() {
            Column({ space: 0 }) {
              // 列表信息卡片
              ListInfoCard()

              // 工具栏
              if (this.viewModel.songList.length > 0) {
                if (this.viewModel.showSimpleToolbar) {
                  SimpleSongListToolbar()
                } else {
                  SongListToolbar()
                }
              }

              // 多选操作栏
              if (this.viewModel.showEditorView) {
                EditorBar()
              }

              // 添加歌曲对话框
              if (this.viewModel.showAddSongDialog) {
                AddSongDialog()
              }

              // 歌曲列表
              if (this.viewModel.songList.length > 0) {
                List() {
                  Repeat(this.viewModel.songList).each((repeatItem) => {
                    ListItem() {
                      SongListItemView({
                        host: this.viewModel,
                        songList: this.viewModel.songList,
                        song: repeatItem.item,
                        index: repeatItem.index
                      })
                    }
                  })
                }
                .width('100%')
                .layoutWeight(1)
                .edgeEffect(EdgeEffect.Spring)
                .scrollBar(BarState.Off)
                .onReachEnd(() => {
                  // TYPE_FOLDER 使用 passBack 游标加载更多
                  if (this.viewModel.playListType === MusicListType.TYPE_FOLDER) {
                    this.viewModel.loadMoreSongs()
                  } else {
                    this.viewModel.loadSongs(true)
                  }
                })
              } else if (!this.viewModel.isLoadingSongs) {
                Column() {
                  Image($r('app.media.icon_home_placeholder'))
                    .width(64)
                    .height(64)
                    .opacity(0.3)
                  Text('暂无歌曲')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .margin({ top: 12 })
                }
                .width('100%')
                .padding({ top: 40 })
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }

              // 底部加载状态提示
              if (this.viewModel.isLoadingSongs && this.viewModel.songList.length > 0) {
                Text('正在加载更多...')
                  .fontSize(12)
                  .fontColor(Color.Gray)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 12, bottom: 12 })
              } else if (!this.viewModel.hasMore && this.viewModel.songList.length > 0) {
                Text('已加载全部')
                  .fontSize(12)
                  .fontColor(Color.Gray)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 12, bottom: 12 })
              }
            }
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .padding({ bottom: 70 - AppUtil.bottomSafeArea })
    }
    .hideTitleBar(true)
  }

  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_back_dark'))
        .width(24)
        .height(24)
        .onClick(() => {
          NavController.getInstance().pop();
        })

      Text(this.viewModel.listName ? this.viewModel.listName : '歌曲列表')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank().width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }
}
