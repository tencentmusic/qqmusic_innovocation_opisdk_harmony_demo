import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'
import { NavController } from '../../nav/NavController'
import { SingerDetailPageParams } from '../../nav/RouteParams'
import { IAlbum, ISingerWiki } from '@qqmusic/opisdk-entity'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { RouteName } from '../../nav/RouteMap'
import { SongListItemView } from '../../view/songlist/SongListItemView'
import { SimpleSongListToolbar } from '../../view/songlist/SimpleSongListToolbar'
import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { SongListPageParams } from '../../nav/RouteParams'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'SingerDetailPage'

/** Wiki 基本信息条目 */
class WikiEntry {
  key: string
  value: string

  constructor(key: string, value: string) {
    this.key = key
    this.value = value
  }
}

/**
 * 歌手详情页
 * 包含：歌手信息头部、歌曲/专辑 Tab 切换
 * 歌曲 Tab：复用 SongListViewModel + SongListItemView
 * 专辑 Tab：独立加载歌手专辑列表
 */
@ComponentV2
export struct SingerDetailPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Provider('viewModel') viewModel: SongListViewModel = new SongListViewModel()
  @Local currentTabIndex: number = 0
  @Local albumList: IAlbum[] = []
  @Local isLoadingAlbums: boolean = false
  @Local albumHasMore: boolean = true
  @Local albumPage: number = 0
  @Local albumTotalCount: number = 0
  private readonly albumPageSize: number = 20
  private singerId: number = 0
  private singerMid: string = ''
  private singerName: string = ''

  aboutToAppear(): void {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as SingerDetailPageParams
      if (raw) {
        this.singerId = raw.singerId
        this.singerMid = raw.singerMid
        this.singerName = raw.singerName
        this.viewModel.playListType = MusicListType.TYPE_SINGER
        this.viewModel.singerId = raw.singerId
        this.viewModel.singerMid = raw.singerMid
        this.viewModel.listName = raw.singerName
        this.viewModel.showSimpleToolbar = true
        this.viewModel.fetchAlbumDetail()
        this.viewModel.loadSongs()
        // 预加载专辑列表第一页，获取专辑总数用于 Tab 展示
        this.loadAlbums()
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
        // 顶部标题栏
        this.buildHeader()

        // 可滚动内容区（歌手信息 + Tab + 列表）
        Scroll() {
          Column({ space: 0 }) {
            // 歌手信息卡片
            this.buildSingerInfoCard()

            // Tab 切换栏
            this.buildTabBar()

            // Tab 内容区
            if (this.currentTabIndex === 0) {
              this.buildSongTab()
            } else {
              this.buildAlbumTab()
            }
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
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
          this.navController.pop()
        })

      Text(this.singerName ? this.singerName : '歌手详情')
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
  @Builder
  buildTabBar() {
    Row() {
      // 歌曲 Tab
      Column() {
        Text(`歌曲 (${this.viewModel.listSongCount} 首)`)
          .fontSize(14)
          .fontColor(this.currentTabIndex === 0 ? '#6200EE' : '#999999')
          .fontWeight(this.currentTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)

        if (this.currentTabIndex === 0) {
          Divider()
            .strokeWidth(2)
            .color('#6200EE')
            .width(40)
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.currentTabIndex = 0
      })

      // 专辑 Tab
      Column() {
        Text(`专辑 (${this.albumTotalCount} 张)`)
          .fontSize(14)
          .fontColor(this.currentTabIndex === 1 ? '#6200EE' : '#999999')
          .fontWeight(this.currentTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)

        if (this.currentTabIndex === 1) {
          Divider()
            .strokeWidth(2)
            .color('#6200EE')
            .width(40)
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.currentTabIndex = 1
        if (this.albumList.length === 0 && !this.isLoadingAlbums) {
          this.loadAlbums()
        }
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .border({
      width: { bottom: 0.5 },
      color: '#E0E0E0'
    })
  }

  @Builder
  buildSongTab() {
    if (this.viewModel.isLoading && this.viewModel.songList.length === 0) {
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
      .height(200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      Column({ space: 0 }) {
        // 工具栏
        if (this.viewModel.songList.length > 0) {
          SimpleSongListToolbar()
            .margin({ top: 8, bottom: 4 })
        }

        // 歌曲列表 — 用固定高度让 List 可独立滚动
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
          .height(400)
          .edgeEffect(EdgeEffect.Spring)
          .onReachEnd(() => {
            this.viewModel.loadSongs(true)
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
          .height(200)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        // 底部加载状态
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
      .width('100%')
    }
  }
  @Builder
  buildSingerInfoCard() {
    if (this.viewModel.singerDetail) {
      Column({ space: 8 }) {
        // 歌手大图
        Image(this.viewModel.singerDetail.getSingerPic() ?? '')
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#E0E0E0')

        // 歌手基本信息
        Column({ space: 6 }) {
          this.buildInfoRow('歌手id', `${this.viewModel.singerDetail.getSingerId()}`)
          this.buildInfoRow('歌手mid', this.viewModel.singerMid)
          this.buildInfoRow('歌手名称', this.viewModel.singerDetail.getSingerName())

          // Wiki 基本信息 — 使用独立的 @Builder 避免 @Builder 中写 const
          this.buildWikiSection()
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
      }
      .width('100%')
      .margin({ bottom: 8 })
    }
  }

  /**
   * 普通方法：将 Wiki 基本信息 Map 转为数组，供 ForEach 使用
   * @Builder 中不能声明 const / 写普通 TS 逻辑
   */
  private getWikiBasicInfoArray(wiki: ISingerWiki | null): WikiEntry[] {
    const result: WikiEntry[] = []
    const basicInfo = wiki?.getBasicInfo()
    if (basicInfo) {
      basicInfo.forEach((value, key) => {
        result.push(new WikiEntry(key, value))
      })
    }
    return result
  }
  @Builder
  buildWikiSection() {
    if (this.viewModel.singerDetail?.getWikiInfo()) {
      // Wiki 基本信息 — ForEach 是 UI 组件语法
      ForEach(
        this.getWikiBasicInfoArray(this.viewModel.singerDetail.getWikiInfo()),
        (item: WikiEntry) => {
          this.buildInfoRow(item.key, item.value)
        },
        (item: WikiEntry) => item.key
      )

      // 歌手简介
      if (this.viewModel.singerDetail.getWikiInfo()?.getDesc()) {
        this.buildInfoRow('歌手简介', this.viewModel.singerDetail.getWikiInfo()!.getDesc()!)
      }
    }
  }
  @Builder
  buildInfoRow(label: string, value: string) {
    if (value && value.length > 0) {
      Row() {
        Text(`${label}:`)
          .fontSize(13)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .width(80)

        Text(value)
          .fontSize(13)
          .fontColor('#666666')
          .layoutWeight(1)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
  }

  @Builder
  buildAlbumTab() {
    if (this.isLoadingAlbums && this.albumList.length === 0) {
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
      .height(200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.albumList.length === 0) {
      Column() {
        Image($r('app.media.icon_home_placeholder'))
          .width(64)
          .height(64)
          .opacity(0.3)
        Text('暂无专辑')
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 12 })
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List() {
        Repeat(this.albumList).each((repeatItem) => {
          ListItem() {
            this.buildAlbumItem(repeatItem.item)
          }
        })
      }
      .width('100%')
      .height(400)
      .padding({ left: 12, right: 12, top: 8 })
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd(() => {
        this.loadAlbums(true)
      })
    }
  }
  @Builder
  buildAlbumItem(album: IAlbum) {
    Row({ space: 12 }) {
      Image(this.getAlbumCoverUrl(album))
        .width(60)
        .height(60)
        .objectFit(ImageFit.Cover)
        .borderRadius(4)
        .backgroundColor('#E0E0E0')

      Column({ space: 4 }) {
        Text(album.getName() ?? '')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (album.getSubName()) {
          Text(album.getSubName()!)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Text(album.getPublicTime() ?? '')
          .fontSize(11)
          .fontColor(Color.Gray)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .margin({ top: 4, bottom: 4 })
    .borderRadius(8)
    .onClick(() => {
      const params = new SongListPageParams(
        MusicListType.TYPE_ALBUM,
        album.getId(),
        album.getName(),
        true
      )
      this.navController.push(RouteName.SONG_LIST_PAGE, params)
    })
  }

  /**
   * 获取专辑封面 URL，参考 TV 端 AlbumInfo.fromIAlbum 的优先级：
   * albumMediumUrl > pic300x300 > pic > ''
   */
  private getAlbumCoverUrl(album: IAlbum): string {
    return album.getAlbumMediumUrl()
      ?? album.getPic300x300()
      ?? album.getPic()
      ?? ''
  }

  async loadAlbums(isLoadMore: boolean = false): Promise<void> {
    if (this.isLoadingAlbums) {
      return
    }
    if (!isLoadMore) {
      this.albumPage = 0
      this.albumList = []
      this.albumHasMore = true
    } else if (!this.albumHasMore) {
      return
    }

    this.isLoadingAlbums = true
    try {
      const resp = await OpenApiSdk.openApi?.albumApi.fetchAlbumOfSinger(
        this.singerId,
        this.singerMid,
        this.albumPage,
        this.albumPageSize,
        0
      )
      if (resp && resp.isSuccess() && resp.data) {
        const list: IAlbum[] = resp.data as IAlbum[]
        if (isLoadMore) {
          this.albumList = this.albumList.concat(list)
        } else {
          this.albumList = list
        }
        this.albumHasMore = resp.hasMore ?? false
        this.albumTotalCount = resp.totalCount ?? 0
        this.albumPage++
        MLog.i(TAG, `loadAlbums success, page: ${this.albumPage - 1}, count: ${list.length}`)
      } else {
        MLog.w(TAG, `loadAlbums failed: ${resp?.errorMsg}`)
        this.albumHasMore = false
      }
    } catch (e) {
      MLog.e(TAG, `loadAlbums error: ${JSON.stringify(e)}`)
      this.albumHasMore = false
    } finally {
      this.isLoadingAlbums = false
    }
  }
}

@Builder
export function SingerDetailPageBuilder(params: Object) {
  SingerDetailPage()
}
