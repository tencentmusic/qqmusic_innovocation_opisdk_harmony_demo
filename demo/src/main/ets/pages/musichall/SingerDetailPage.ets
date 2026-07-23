import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'
import { NavController } from '../../nav/NavController'
import { SingerDetailPageParams } from '../../nav/RouteParams'
import { IAlbum, ISingerWiki } from '@qqmusic/opisdk-entity'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { RouteName } from '../../nav/RouteMap'
import { SongListItemView } from '../../view/songlist/SongListItemView'
import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { SongListPageParams } from '../../nav/RouteParams'
import { AppUtil } from '../../utils/AppUtil'
import { SongListToolbar } from '../../view/songlist/SongListToolbar'
import { CopyableInfoField } from '../../view/common/CopyableInfoField'

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
  @Local isWikiExpanded: boolean = false
  private readonly albumPageSize: number = 20
  private singerId: number = 0
  private singerMid: string = ''
  private singerName: string = ''
  private scroller: ListScroller = new ListScroller()

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

        List({ space: 0, scroller: this.scroller }) {
          // 歌手信息卡片
          ListItem() {
            this.buildSingerInfoCard()
          }

          ListItemGroup({ space: 0, header: this.buildStickyHeader }) {
            // Tab 内容区
            if (this.currentTabIndex === 0) {
              this.buildSongTabItems()
            } else {
              this.buildAlbumTabItems()
            }
          }
        }
        .sticky(StickyStyle.Header)
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(() => {
          if (this.currentTabIndex === 0) {
            if (this.viewModel.isLoading || this.viewModel.songList.length === 0) {
              return
            }
            this.viewModel.loadSongs(true)
          } else {
            if (this.isLoadingAlbums || this.albumList.length === 0) {
              return
            }
            this.loadAlbums(true)
          }
        })
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
  buildStickyHeader() {
    Column() {
      // Tab 切换栏
      this.buildTabBar()
      // 歌曲列表工具栏
      if (this.currentTabIndex === 0 && this.viewModel.songList.length > 0) {
        SongListToolbar()
      }
    }
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
        if (this.currentTabIndex !== 0) {
          this.currentTabIndex = 0
          this.scrollToSticky()
        }
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
        if (this.currentTabIndex !== 1) {
          this.currentTabIndex = 1
          if (this.albumList.length === 0 && !this.isLoadingAlbums) {
            this.loadAlbums()
          }
          this.scrollToSticky()
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

  private scrollToSticky(): void {
    // 延迟执行，等待 Tab 内容切换渲染完成
    setTimeout(() => {
      this.scroller.scrollToIndex(1)
    }, 100)
  }

  /** 歌曲 Tab 列表项 */
  @Builder
  buildSongTabItems() {
    if (this.viewModel.isLoading && this.viewModel.songList.length === 0) {
      ListItem() {
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
      }
    } else if (this.viewModel.songList.length === 0 && !this.viewModel.isLoadingSongs) {
      ListItem() {
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
    } else {
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

      // 底部加载状态
      if (this.viewModel.isLoadingSongs && this.viewModel.songList.length > 0) {
        ListItem() {
          Text('正在加载更多...')
            .fontSize(12)
            .fontColor(Color.Gray)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
        }
      } else if (!this.viewModel.hasMore && this.viewModel.songList.length > 0) {
        ListItem() {
          Text('已加载全部')
            .fontSize(12)
            .fontColor(Color.Gray)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
        }
      }
    }
  }

  @Builder
  buildSingerInfoCard() {
    if (this.viewModel.singerDetail) {
      Column() {
        // 歌手大图
        Image(this.viewModel.singerDetail.getSingerPic() ?? '')
          .width('100%')
          .objectFit(ImageFit.Contain)

        // 歌手基本信息
        Column({ space: 6 }) {
          CopyableInfoField({
            label: '歌手id',
            value: `${this.viewModel.singerDetail.getSingerId()}`,
            fontSize: 13,
            fontColor: '#666666'
          })
          CopyableInfoField({
            label: '歌手mid',
            value: this.viewModel.singerMid,
            fontSize: 13,
            fontColor: '#666666'
          })
          CopyableInfoField({
            label: '歌手名称',
            value: this.viewModel.singerDetail.getSingerName(),
            fontSize: 13,
            fontColor: '#666666'
          })

          // Wiki 基本信息
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
      // Wiki 基本信息
      ForEach(
        this.getWikiBasicInfoArray(this.viewModel.singerDetail.getWikiInfo()),
        (item: WikiEntry) => {
          CopyableInfoField({
            label: item.key,
            value: item.value,
            fontSize: 13,
            fontColor: '#666666',
            maxLines: 9
          })
        },
        (item: WikiEntry) => item.key
      )

      // 歌手简介 — 默认折叠，点击展开
      this.buildWikiDesc()
    }
  }

  @Builder
  buildWikiDesc() {
    if (this.viewModel.singerDetail?.getWikiInfo()?.getDesc() &&
      this.viewModel.singerDetail!.getWikiInfo()!.getDesc()!.length > 0) {
      Row() {
        Text('歌手简介:')
          .fontSize(13)
          .fontColor('#666666')
          .layoutWeight(1)

        Text(this.isWikiExpanded ? '收起 ▲' : '展开 ▼')
          .fontSize(12)
          .fontColor('#1890FF')
          .onClick(() => {
            this.isWikiExpanded = !this.isWikiExpanded
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.isWikiExpanded) {
        Text(this.viewModel.singerDetail!.getWikiInfo()!.getDesc()!)
          .fontSize(13)
          .fontColor('#666666')
          .width('100%')
          .maxLines(99)
      }
    }
  }

  @Builder
  buildAlbumTabItems() {
    if (this.isLoadingAlbums && this.albumList.length === 0) {
      ListItem() {
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
      }
    } else if (this.albumList.length === 0) {
      ListItem() {
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
      }
    } else {
      Repeat(this.albumList).each((repeatItem) => {
        ListItem() {
          this.buildAlbumItem(repeatItem.item)
        }
      })

      // 底部加载状态
      if (this.isLoadingAlbums && this.albumList.length > 0) {
        ListItem() {
          Text('正在加载更多...')
            .fontSize(12)
            .fontColor(Color.Gray)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
        }
      } else if (!this.albumHasMore && this.albumList.length > 0) {
        ListItem() {
          Text('已加载全部')
            .fontSize(12)
            .fontColor(Color.Gray)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
        }
      }
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
