import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { IAlbum, IPlayParam, IMediaEventListener, IFolder, IRank, ISingerDetail, ISingerWiki, OpenApiResponse } from '@qqmusic/opisdk-entity'
import { ISongInfo, ISinger, MusicListType, PlayerEnums, PlayerEvent, PlayError, PlayStatus } from '@qqmusic/opisdk-qmutils'
import { ToastUtil } from '../../utils/ToastUtil'
import { ISongListItemHost } from '../../view/songlist/ISongListItemHost'
import { DemoGlobal } from '../../utils/DemoGlobal'

const TAG = 'SongListViewModel'

/**
 * 通用歌曲列表 ViewModel
 * 支持：播放全部、收藏/取消收藏、添加歌曲到播放列表、多选模式、歌曲播控
 *
 * 实现 IMediaEventListener 以监听播放状态变化，驱动 UI 实时刷新
 */
@ObservedV2
export class SongListViewModel implements IMediaEventListener, ISongListItemHost {
  /** 专辑详情（TYPE_ALBUM 场景） */
  @Trace public album: IAlbum | null = null
  /** 歌单详情（TYPE_FOLDER 场景） */
  @Trace public folder: IFolder | null = null
  /** 榜单详情（TYPE_ONLINE 场景） */
  @Trace public rankDetail: IRank | null = null
  /** 歌手详情（TYPE_SINGER 场景） */
  @Trace public singerDetail: ISingerDetail | null = null
  @Trace public songList: ISongInfo[] = []
  @Trace public isLoading: boolean = false
  @Trace public isLoadingSongs: boolean = false
  @Trace public hasMore: boolean = true
  /** 列表名称（专辑名或歌单名） */
  @Trace public listName: string = ''
  /** 是否已滚动到底部并显示"已加载全部"提示 */
  @Trace public showAllLoadedTip: boolean = false
  /** 列表是否已收藏 */
  @Trace public isListCollected: boolean = false
  @Trace public isTogglingCollect: boolean = false
  @Trace public showEditorView: boolean = false
  @Trace public showAddSongDialog: boolean = false
  @Trace public addSongInputText: string = ''
  @Trace public selectedSongIds: Set<number> = new Set()
  @Trace public isAllSelected: boolean = false
  /** 已收藏歌曲ID集合，用于驱动收藏爱心 UI 实时刷新 */
  @Trace public collectedSongIds: Set<number> = new Set()
  /** 专辑ID（TYPE_ALBUM 场景使用） */
  public albumId: number = 0
  public page: number = 0
  public readonly pageSize: number = 200
  /** passBack 游标（TYPE_FOLDER 场景使用），用于基于游标的分页，保证大歌单遍历完整性 */
  private folderPassBack: string = ''
  /** 播放列表类型，用于区分专辑/歌单等场景 */
  public playListType: MusicListType = MusicListType.TYPE_NULL
  /** 歌单ID（TYPE_FOLDER 场景使用） */
  public folderId: number = 0
  /** 榜单ID（TYPE_ONLINE 场景使用） */
  public rankId: number = 0
  /** 歌手ID（TYPE_SINGER 场景使用） */
  public singerId: number = 0
  /** 歌手Mid（TYPE_SINGER 场景使用） */
  public singerMid: string = ''
  /**
   * 是否使用简化工具栏（播放全部 + 收藏 + 收藏全部）
   */
  @Trace public showSimpleToolbar: boolean = false
  /**
   * 指定歌曲ID列表（TYPE_SONG_LIST 场景使用）
   * 对应安卓 pagingSongIds
   */
  public targetSongIds: number[] = []
  /**
   * 场景分类 groupId（歌单场景分类使用）
   * 对应安卓 pagingSongListScene
   */
  public sceneGroupId: number = 0
  /**
   * 场景分类 subGroupId（歌单场景分类使用）
   */
  public sceneSubGroupId: number = 0
  /**
   * 来源标识（歌单场景使用）
   * 对应安卓 KEY_SOURCE
   * 注意：当前鸿蒙 fetchSongOfFolder API 不支持 source 参数，
   * 保留此字段供未来埋点/上报使用，暂不参与数据请求
   */
  public source: number = 0
  /** 当前播放歌曲ID，用于驱动 UI 刷新 */
  @Trace public currentPlayingSongId: number = -1
  /** 当前播放状态，用于驱动 toolbar 刷新 */
  @Trace public currentPlayStatus: PlayStatus = PlayStatus.IDLE
  private isEventListenerRegistered: boolean = false
  /** 防止 Toggle.onChange 级联触发导致死循环 */
  private isTogglingAll: boolean = false

  /** 当前列表所有歌曲是否都已收藏到"我喜欢" */
  get isAllSongsCollected(): boolean {
    if (this.songList.length === 0) {
      return false
    }
    for (let i = 0; i < this.songList.length; i++) {
      if (!this.collectedSongIds.has(this.songList[i].getSongId())) {
        return false
      }
    }
    return true
  }

  /** 列表类型标签（歌单/专辑/榜单），供 UI 使用 */
  get listTypeLabel(): string {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      return '歌单'
    } else if (this.playListType === MusicListType.TYPE_ONLINE) {
      return '榜单'
    } else if (this.playListType === MusicListType.TYPE_SINGER) {
      return '歌手'
    }
    return '专辑'
  }

  /** 当前列表ID（根据 playListType 返回 albumId、folderId、rankId 或 singerId） */
  get currentListId(): number {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      return this.folderId
    } else if (this.playListType === MusicListType.TYPE_ONLINE) {
      return this.rankId
    } else if (this.playListType === MusicListType.TYPE_SINGER) {
      return this.singerId
    }
    return this.albumId
  }

  /** 列表封面 URL（专辑封面、歌单封面、榜单封面或歌手封面） */
  get listCoverUrl(): string {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      return this.folder?.getPicUrl() ?? ''
    } else if (this.playListType === MusicListType.TYPE_ONLINE) {
      return this.rankDetail?.getTopHeaderPic() ?? this.rankDetail?.getTopBannerPic() ?? ''
    } else if (this.playListType === MusicListType.TYPE_SINGER) {
      return this.singerDetail?.getSingerPic() ?? ''
    }
    return this.album?.getPic() ?? ''
  }

  /** 列表歌曲总数 */
  get listSongCount(): number {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      return this.folder?.getSongNum() ?? 0
    } else if (this.playListType === MusicListType.TYPE_ONLINE) {
      return this.rankDetail?.getTotalNum() ?? 0
    } else if (this.playListType === MusicListType.TYPE_SINGER) {
      return this.singerDetail?.getSongSum() ?? 0
    }
    return this.album?.getSongNum() ?? 0
  }

  /** 列表播放量 */
  get listListenCount(): number {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      return this.folder?.getListenNum() ?? 0
    } else if (this.playListType === MusicListType.TYPE_ONLINE) {
      return this.rankDetail?.getListenNum() ?? 0
    } else if (this.playListType === MusicListType.TYPE_SINGER) {
      return this.singerDetail?.getConcernNum() ?? 0
    }
    return this.album?.getListenNum() ?? 0
  }

  /** 列表收藏量 */
  get listFavCount(): number {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      return this.folder?.getFavNum() ?? 0
    } else if (this.playListType === MusicListType.TYPE_SINGER) {
      return 0
    }
    return this.album?.getFavCount() ?? 0
  }

  /** 列表创建者名称（仅歌单有） */
  get listCreatorName(): string {
    return this.folder?.getCreator()?.getName() ?? ''
  }

  /** 列表发布时间（仅专辑有） */
  get listPublicTime(): string {
    return this.album?.getPublicTime() ?? ''
  }

  /** 列表歌手名（仅专辑有） */
  get listSingerName(): string {
    return this.album?.getSingerName() ?? ''
  }

  /** 榜单描述（仅榜单有） */
  get rankDesc(): string {
    return this.rankDetail?.getTopDesc() ?? ''
  }

  /** 榜单更新时间（仅榜单有） */
  get rankUpdateTime(): string {
    return this.rankDetail?.getUpdateTime() ?? ''
  }

  /** 歌手名称（仅歌手有） */
  get singerName(): string {
    return this.singerDetail?.getSingerName() ?? ''
  }

  /** 歌手外文名（仅歌手有） */
  get singerTranslatorName(): string {
    return this.singerDetail?.getSingerTranslatorName() ?? ''
  }

  /** 歌手区域（仅歌手有） */
  get singerArea(): string {
    return this.singerDetail?.getArea() ?? ''
  }

  /** 歌单描述（仅歌单有） */
  get folderIntroduction(): string {
    return this.folder?.getIntroduction() ?? ''
  }

  /** 歌单创建时间（仅歌单有），返回格式化字符串 */
  get folderCreateTime(): string {
    const t = this.folder?.getCreateTime()
    if (t !== null && t !== undefined && t > 0) {
      return new Date(t).toLocaleDateString()
    }
    return ''
  }

  /** 歌单更新时间（仅歌单有），返回格式化字符串 */
  get folderUpdateTime(): string {
    const t = this.folder?.getUpdateTime()
    if (t !== null && t !== undefined && t > 0) {
      return new Date(t).toLocaleDateString()
    }
    return ''
  }

  /** 歌手 Wiki 信息（仅歌手有） */
  get singerWiki(): ISingerWiki | null {
    return this.singerDetail?.getWikiInfo() ?? null
  }

  /** 歌手 Wiki basicInfo 转为数组（供 UI ForEach 遍历） */
  get singerWikiBasicInfoEntries(): [string, string][] {
    const wiki = this.singerDetail?.getWikiInfo()
    if (wiki) {
      const basicInfo = wiki.getBasicInfo()
      if (basicInfo && basicInfo.size > 0) {
        const result: [string, string][] = []
        basicInfo.forEach((value: string, key: string) => {
          result.push([key, value])
        })
        return result
      }
    }
    return []
  }

  /** 歌手 Wiki groupListInfo 转为二维数组（供 UI ForEach 遍历） */
  get singerWikiGroupListEntries(): [string, string][][] {
    const wiki = this.singerDetail?.getWikiInfo()
    if (wiki) {
      const groupList = wiki.getGroupListInfo()
      if (groupList && groupList.length > 0) {
        const result: [string, string][][] = []
        for (let i = 0; i < groupList.length; i++) {
          const groupMap = groupList[i]
          const entries: [string, string][] = []
          groupMap.forEach((value: string, key: string) => {
            entries.push([key, value])
          })
          result.push(entries)
        }
        return result
      }
    }
    return []
  }

  /** 歌手 Wiki otherInfo 转为数组（供 UI ForEach 遍历） */
  get singerWikiOtherInfoEntries(): [string, string][] {
    const wiki = this.singerDetail?.getWikiInfo()
    if (wiki) {
      const otherInfo = wiki.getOtherInfo()
      if (otherInfo && otherInfo.size > 0) {
        const result: [string, string][] = []
        otherInfo.forEach((value: string, key: string) => {
          result.push([key, value])
        })
        return result
      }
    }
    return []
  }

  /** 歌手 Wiki desc 文本（仅歌手有） */
  get singerWikiDesc(): string {
    return this.singerDetail?.getWikiInfo()?.getDesc() ?? ''
  }

  async fetchAlbumDetail(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      if (this.playListType === MusicListType.TYPE_FOLDER) {
        // 歌单场景：拉取歌单详情
        const resp = await OpenApiSdk.openApi?.folderApi.fetchFolderDetail(this.folderId)
        if (resp && resp.isSuccess() && resp.data) {
          this.folder = resp.data
          this.listName = resp.data.getName()
          // 同步查询歌单是否已收藏，确保首屏渲染前数据就绪
          await this.fetchFolderCollectStatus()
          MLog.i(TAG, `fetchFolderDetail success: ${this.listName}`)
        } else {
          MLog.w(TAG, `fetchFolderDetail failed: ${resp?.errorMsg}`)
        }
      } else if (this.playListType === MusicListType.TYPE_ONLINE) {
        // 榜单场景：拉取榜单详情（含第一页歌曲），然后循环加载全部剩余页面
        const resp = await OpenApiSdk.openApi?.rankApi.fetchRankDetail(this.rankId, 0, this.pageSize)
        if (resp && resp.isSuccess() && resp.data) {
          this.rankDetail = resp.data
          this.listName = resp.data.getName()
          this.isListCollected = false // 榜单不支持收藏
          // 榜单详情接口已附带第一页歌曲，直接填充
          const firstPageSongs = resp.data.getSongList()
          if (firstPageSongs && firstPageSongs.length > 0) {
            this.songList = firstPageSongs
            this.hasMore = firstPageSongs.length >= this.pageSize
            this.page = 1
            // 继续加载剩余页面，确保"播放全部"时 songList 已完整
            await this.loadRemainingPages()
          }
          MLog.i(TAG, `fetchRankDetail success: ${this.listName}, songs: ${this.songList.length}`)
        } else {
          MLog.w(TAG, `fetchRankDetail failed: ${resp?.errorMsg}`)
          this.rankDetail = null
        }
      } else if (this.playListType === MusicListType.TYPE_SINGER) {
        // 歌手场景：拉取歌手详情（含第一页歌曲），然后循环加载全部剩余页面
        const resp = await OpenApiSdk.openApi?.singerApi.fetchSingerDetail(
          this.singerId,
          this.singerMid,
          0,
          this.pageSize,
          0,
          true,
          true
        )
        if (resp && resp.isSuccess() && resp.data) {
          this.singerDetail = resp.data
          this.listName = resp.data.getSingerName()
          this.isListCollected = resp.data.getFavState() === 1
          const firstPageSongs = resp.data.getSonglist()
          if (firstPageSongs && firstPageSongs.length > 0) {
            this.songList = firstPageSongs
            this.hasMore = firstPageSongs.length >= this.pageSize
            this.page = 1
          }
          MLog.i(TAG, `fetchSingerDetail success: ${this.listName}, songs: ${this.songList.length}`)
        } else {
          MLog.w(TAG, `fetchSingerDetail failed: ${resp?.errorMsg}`)
          this.singerDetail = null
        }
      } else {
        // 专辑场景
        const resp = await OpenApiSdk.openApi?.albumApi.fetchAlbumDetail(this.albumId)
        if (resp && resp.isSuccess() && resp.data) {
          this.album = resp.data
          this.listName = resp.data.getName()
          this.isListCollected = resp.data.getFavState() === 1
          MLog.i(TAG, `fetchAlbumDetail success: ${this.listName}, favState: ${resp.data.getFavState()}`)
        } else {
          MLog.w(TAG, `fetchAlbumDetail failed: ${resp?.errorMsg}`)
          this.album = null
        }
      }
    } catch (e) {
      MLog.e(TAG, `fetchAlbumDetail error: ${JSON.stringify(e)}`)
      this.album = null
    } finally {
      this.isLoading = false
      // 榜单/歌手场景：fetchAlbumDetail 内部已加载全部歌曲，补充刷新收藏状态
      if (this.playListType === MusicListType.TYPE_ONLINE || this.playListType === MusicListType.TYPE_SINGER) {
        if (this.songList.length > 0) {
          this.refreshCollectedState()
        }
      }
    }
  }

  /**
   * 异步查询歌单是否已收藏（TYPE_FOLDER 场景）
   */
  private async fetchFolderCollectStatus(): Promise<void> {
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.fetchCollectedFolder()
      if (resp && resp.isSuccess() && resp.data) {
        const found = resp.data.find((f: IFolder) => f.getId() === this.folderId)
        this.isListCollected = found !== undefined
        MLog.i(TAG, `fetchFolderCollectStatus: ${this.isListCollected}`)
      }
    } catch (e) {
      MLog.e(TAG, `fetchFolderCollectStatus error: ${JSON.stringify(e)}`)
    }
  }

  async loadSongs(isLoadMore: boolean = false): Promise<void> {
    if (this.isLoadingSongs) {
      return
    }
    if (!isLoadMore) {
      // 榜单场景：fetchAlbumDetail 已通过 fetchRankDetail 加载了第一页歌曲，首屏不重复拉取
      if (this.playListType === MusicListType.TYPE_ONLINE && this.songList.length > 0) {
        return
      }
      // 歌手场景：fetchAlbumDetail 已通过 fetchSingerDetail 加载了第一页歌曲，首屏不重复拉取
      if (this.playListType === MusicListType.TYPE_SINGER && this.songList.length > 0) {
        return
      }
      // 指定歌曲ID场景：一次性加载，不支持分页
      if (this.playListType === MusicListType.TYPE_SONG_LIST && this.targetSongIds.length > 0) {
        await this.loadSongsByIds(this.targetSongIds)
        return
      }
      // 场景分类场景：一次性加载，不支持分页
      if (this.sceneGroupId > 0) {
        await this.loadSongsByScene(this.sceneGroupId, this.sceneSubGroupId)
        return
      }
      this.page = 0
      this.songList = []
      this.hasMore = true
      this.showAllLoadedTip = false
      // TYPE_FOLDER 场景：重置 passBack 游标
      if (this.playListType === MusicListType.TYPE_FOLDER) {
        this.folderPassBack = ''
      }
    } else if (!this.hasMore) {
      return
    }

    this.isLoadingSongs = true
    try {
      // 首屏加载时循环拉取全部页面，确保"播放全部"时 songList 已完整
      if (!isLoadMore) {
        await this.loadAllPages()
      } else {
        // 加载更多（onReachEnd 触发，作为兜底；正常情况下首屏已全部加载完）
        await this.loadSinglePage(true)
      }
    } catch (e) {
      MLog.e(TAG, `loadSongs error: ${JSON.stringify(e)}`)
      this.hasMore = false
    } finally {
      this.isLoadingSongs = false
      // 首次加载完成后同步初始收藏状态
      if (!isLoadMore) {
        this.refreshCollectedState()
      }
    }
  }

  /**
   * 循环拉取所有页面，直到 hasMore 为 false
   * 首屏加载时调用，确保 songList 一次性包含全部歌曲
   * TYPE_FOLDER 场景使用基于 passBack 的游标分页，保证大歌单遍历完整性
   */
  private async loadAllPages(): Promise<void> {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      // 歌单场景：使用 passBack 游标分页，首屏只拉第一页
      await this.loadAllPagesByPassBack()
      return
    }
    let currentPage = this.page
    while (this.hasMore) {
      const list = await this.loadSinglePageRaw(currentPage)
      if (list && list.length > 0) {
        if (currentPage === 0) {
          this.songList = list
        } else {
          this.songList = this.songList.concat(list)
        }
        this.hasMore = list.length >= this.pageSize
        currentPage++
        this.page = currentPage
        MLog.d(TAG, `loadAllPages: page ${currentPage - 1}, count: ${list.length}, total: ${this.songList.length}`)
      } else {
        this.hasMore = false
        break
      }
    }
    MLog.i(TAG, `loadAllPages done, total songs: ${this.songList.length}`)
  }

  /**
   * 加载歌单第一页歌曲（使用 passBack 游标分页，每页 200 首）
   * 首屏只拉第一页，后续通过 loadMoreSongs 按需加载
   */
  private async loadAllPagesByPassBack(): Promise<void> {
    const FOLDER_PAGE_SIZE = 200
    const resp = await OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(
      this.folderId,
      this.folderPassBack,
      FOLDER_PAGE_SIZE
    )
    if (resp && resp.isSuccess() && resp.data) {
      this.songList = resp.data
      this.hasMore = resp.hasMore === true && resp.passBack !== '' && resp.passBack !== '-1'
      this.folderPassBack = resp.passBack ?? ''
      MLog.i(TAG, `loadAllPagesByPassBack: first page count: ${this.songList.length}, hasMore: ${this.hasMore}`)
    } else {
      this.hasMore = false
      MLog.w(TAG, `loadAllPagesByPassBack failed: ${resp?.errorMsg}`)
    }
  }

  /**
   * 加载歌单下一页歌曲（上拉触底时调用）
   * 使用当前 folderPassBack 游标继续加载
   */
  async loadMoreSongs(): Promise<void> {
    if (!this.hasMore || this.isLoadingSongs) {
      return
    }
    this.isLoadingSongs = true
    try {
      const FOLDER_PAGE_SIZE = 200
      const resp = await OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(
        this.folderId,
        this.folderPassBack,
        FOLDER_PAGE_SIZE
      )
      if (resp && resp.isSuccess() && resp.data) {
        // 一次性 concat 赋值，触发一次 UI 刷新
        this.songList = this.songList.concat(resp.data)
        this.hasMore = resp.hasMore === true && resp.passBack !== '' && resp.passBack !== '-1'
        this.folderPassBack = resp.passBack ?? ''
        MLog.d(TAG, `loadMoreSongs: page count: ${resp.data.length}, total: ${this.songList.length}, hasMore: ${this.hasMore}`)
      } else {
        this.hasMore = false
        MLog.w(TAG, `loadMoreSongs failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `loadMoreSongs error: ${JSON.stringify(e)}`)
      this.hasMore = false
    } finally {
      this.isLoadingSongs = false
    }
  }

  /**
   * 列表滚动到底部时调用，显示"已加载全部"提示
   * 仅在数据已全部加载（无更多）且有歌曲数据时显示
   */
  onReachListEnd(): void {
    if (!this.hasMore && this.songList.length > 0 && !this.isLoadingSongs) {
      this.showAllLoadedTip = true
    }
  }

  /**
   * 加载剩余页面（从当前 page 开始，不清空已有数据）
   * 供 fetchAlbumDetail 中榜单/歌手场景使用，在首屏数据已填充后继续拉取后续页
   */
  private async loadRemainingPages(): Promise<void> {
    while (this.hasMore) {
      const list = await this.loadSinglePageRaw(this.page)
      if (list && list.length > 0) {
        this.songList = this.songList.concat(list)
        this.hasMore = list.length >= this.pageSize
        this.page++
        MLog.d(TAG, `loadRemainingPages: page ${this.page - 1}, count: ${list.length}, total: ${this.songList.length}`)
      } else {
        this.hasMore = false
        break
      }
    }
    MLog.i(TAG, `loadRemainingPages done, total songs: ${this.songList.length}`)
  }

  /**
   * 加载单页歌曲（供 onReachEnd 兜底使用）
   * TYPE_FOLDER 场景使用 passBack 游标，忽略 pageIndex 参数
   */
  private async loadSinglePage(isLoadMore: boolean): Promise<void> {
    // TYPE_FOLDER 使用 passBack 游标加载下一页
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      await this.loadMoreSongs()
      return
    }
    const currentPage = isLoadMore ? this.page : 0
    const list = await this.loadSinglePageRaw(currentPage)
    if (list && list.length > 0) {
      if (isLoadMore) {
        this.songList = this.songList.concat(list)
      } else {
        this.songList = list
      }
      this.hasMore = list.length >= this.pageSize
      this.page = currentPage + 1
    } else {
      this.hasMore = false
    }
  }

  /**
   * 原始单页请求逻辑，根据 playListType 调用对应 API
   * TYPE_FOLDER 场景使用 passBack 游标分页，每页 200 首
   * @returns 该页歌曲列表，失败返回空数组
   */
  private async loadSinglePageRaw(pageIndex: number): Promise<ISongInfo[]> {
    if (this.playListType === MusicListType.TYPE_FOLDER) {
      // 歌单场景：使用 passBack 游标分页，每页 200 首
      const resp = await OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(
        this.folderId,
        this.folderPassBack,
        200
      )
      if (resp && resp.isSuccess() && resp.data) {
        this.hasMore = resp.hasMore === true && resp.passBack !== '' && resp.passBack !== '-1'
        this.folderPassBack = resp.passBack ?? ''
        return resp.data
      } else {
        MLog.w(TAG, `loadSinglePageRaw(folder) failed, passBack: ${this.folderPassBack}: ${resp?.errorMsg}`)
        this.hasMore = false
        return []
      }
    } else if (this.playListType === MusicListType.TYPE_ONLINE) {
      const resp = await OpenApiSdk.openApi?.rankApi.fetchSongOfRank(
        this.rankId,
        pageIndex,
        this.pageSize
      )
      if (resp && resp.isSuccess() && resp.data) {
        return resp.data
      } else {
        MLog.w(TAG, `loadSinglePageRaw(rank) failed at page ${pageIndex}: ${resp?.errorMsg}`)
        return []
      }
    } else if (this.playListType === MusicListType.TYPE_SINGER) {
      const resp = await OpenApiSdk.openApi?.singerApi.fetchSongOfSinger(
        this.singerId,
        this.singerMid,
        pageIndex,
        this.pageSize,
        0
      )
      if (resp && resp.isSuccess() && resp.data) {
        return resp.data
      } else {
        MLog.w(TAG, `loadSinglePageRaw(singer) failed at page ${pageIndex}: ${resp?.errorMsg}`)
        return []
      }
    } else {
      // 专辑场景
      const resp = await OpenApiSdk.openApi?.albumApi.fetchSongOfAlbum(
        this.albumId,
        undefined,
        pageIndex,
        this.pageSize,
        0,
        0
      )
      if (resp && resp.isSuccess() && resp.data) {
        return resp.data.songList ?? []
      } else {
        MLog.w(TAG, `loadSinglePageRaw(album) failed at page ${pageIndex}: ${resp?.errorMsg}`)
        return []
      }
    }
  }

  /**
   * 通过指定歌曲ID列表加载歌曲（一次性加载，不分页）
   * 对应安卓 pagingSongIds
   */
  async loadSongsByIds(songIds: number[]): Promise<void> {
    if (songIds.length === 0) {
      MLog.w(TAG, 'loadSongsByIds: songIds is empty')
      this.hasMore = false
      return
    }
    this.isLoadingSongs = true
    try {
      const resp = await OpenApiSdk.openApi?.songApi.fetchSongInfoBatch(songIds, undefined)
      if (resp && resp.isSuccess() && resp.data) {
        this.songList = resp.data
        this.hasMore = false // 指定ID一次性加载，无更多
        MLog.i(TAG, `loadSongsByIds success, count: ${this.songList.length}`)
      } else {
        MLog.w(TAG, `loadSongsByIds failed: ${resp?.errorMsg}`)
        this.hasMore = false
      }
    } catch (e) {
      MLog.e(TAG, `loadSongsByIds error: ${JSON.stringify(e)}`)
      this.hasMore = false
    } finally {
      this.isLoadingSongs = false
      this.refreshCollectedState()
    }
  }

  /**
   * 通过场景分类加载歌单歌曲（一次性加载，不分页）
   * 对应安卓 pagingSongListScene
   */
  async loadSongsByScene(groupId: number, subGroupId: number): Promise<void> {
    if (groupId <= 0) {
      MLog.w(TAG, 'loadSongsByScene: invalid groupId')
      this.hasMore = false
      return
    }
    this.isLoadingSongs = true
    try {
      const resp = await OpenApiSdk.openApi?.songApi.fetchSongOfSongListScene(groupId, subGroupId)
      if (resp && resp.isSuccess() && resp.data) {
        this.songList = resp.data
        this.hasMore = false // 场景歌单一次性加载
        MLog.i(TAG, `loadSongsByScene success, groupId: ${groupId}, subGroupId: ${subGroupId}, count: ${this.songList.length}`)
      } else {
        MLog.w(TAG, `loadSongsByScene failed: ${resp?.errorMsg}`)
        this.hasMore = false
      }
    } catch (e) {
      MLog.e(TAG, `loadSongsByScene error: ${JSON.stringify(e)}`)
      this.hasMore = false
    } finally {
      this.isLoadingSongs = false
      this.refreshCollectedState()
    }
  }

  /**
   * 上报最近播放
   * 对应安卓 reportRecentPlay
   * 在播放全部或点击歌曲播放成功后调用
   */
  reportRecentPlay(): void {
    if (this.songList.length === 0) {
      return
    }
    const song = this.songList[0]
    if (!song) {
      return
    }
    try {
      OpenApiSdk.personalAssetsApi?.reportRecentPlay(song, this.playListType, this.currentListId)
      MLog.d(TAG, `reportRecentPlay: type=${this.playListType}, id=${this.currentListId}`)
    } catch (e) {
      MLog.e(TAG, `reportRecentPlay error: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 注册播放事件监听，页面出现时调用
   */
  registerPlayEventListener(): void {
    if (this.isEventListenerRegistered) {
      return
    }
    OpenApiSdk.playerApi?.registerEventListener(this)
    this.isEventListenerRegistered = true
    // 初始化当前播放状态
    this.refreshPlayState()
    MLog.i(TAG, 'registerPlayEventListener done')
  }

  /**
   * 解注册播放事件监听，页面销毁时调用
   */
  unregisterPlayEventListener(): void {
    if (!this.isEventListenerRegistered) {
      return
    }
    OpenApiSdk.playerApi?.unregisterEventListener(this)
    this.isEventListenerRegistered = false
    MLog.i(TAG, 'unregisterPlayEventListener done')
  }

  /**
   * 实现 IMediaEventListener
   */
  onEvent(event: PlayerEvent.Event, arg: Map<PlayerEvent.Key, Object>): void {
    switch (event) {
      case PlayerEvent.Event.API_EVENT_PLAY_STATE_CHANGED: {
        const state = arg.get(PlayerEvent.Key.API_EVENT_KEY_PLAY_STATE) as number
        if (state !== null && state !== undefined) {
          this.currentPlayStatus = state
          MLog.d(TAG, `onEvent PLAY_STATE_CHANGED: ${state}`)
        }
        break
      }
      case PlayerEvent.Event.API_EVENT_PLAY_SONG_CHANGED: {
        const song = arg.get(PlayerEvent.Key.API_EVENT_KEY_PLAY_SONG) as ISongInfo | null
        this.currentPlayingSongId = song?.getSongId() ?? -1
        MLog.d(TAG, `onEvent PLAY_SONG_CHANGED: ${song?.getSongName()}, id: ${this.currentPlayingSongId}`)
        break
      }
    }
  }

  /**
   * 手动刷新播放状态（首次注册时同步当前状态）
   */
  private refreshPlayState(): void {
    this.currentPlayStatus = OpenApiSdk.playerApi?.getPlayState() ?? PlayStatus.IDLE
    this.currentPlayingSongId = OpenApiSdk.playerApi?.getCurrentSongInfo()?.getSongId() ?? -1
  }

  /**
   * 刷新已收藏歌曲ID集合（首次加载歌曲后调用，同步初始收藏状态）
   */
  async refreshCollectedState(): Promise<void> {
    try {
      // 从服务端拉取"我喜欢"歌单的简单歌曲列表（最多10000首，一次请求）
      const resp = await OpenApiSdk.openApi?.folderApi.fetchSimpleSongListOfFolder(0, 0, 10000)
      if (resp && resp.isSuccess() && resp.data) {
        const serverCollectedIds = new Set<number>()
        for (let i = 0; i < resp.data.length; i++) {
          serverCollectedIds.add(resp.data[i].getSongId())
        }
        // 仅保留当前列表中已在服务端收藏的歌曲ID
        const newSet = new Set<number>()
        for (let i = 0; i < this.songList.length; i++) {
          const song = this.songList[i]
          const songId = song.getSongId()
          if (serverCollectedIds.has(songId)) {
            newSet.add(songId)
          } else if (song.isListenBook() || song.isLongAudioSong()) {
            // 长音频歌曲（听书/播客）的收藏数据不在"我喜欢"歌单中，
            // 需要通过 personalAssetsApi 查询本地 LongAudioSongCollectManager 的缓存
            if (OpenApiSdk.personalAssetsApi?.isSongCollected(song)) {
              newSet.add(songId)
            }
          }
        }
        this.collectedSongIds = newSet
        MLog.d(TAG, `refreshCollectedState: ${newSet.size} collected songs (from server + local longAudio)`)
      } else {
        // 服务端请求失败时回退到本地缓存查询
        MLog.w(TAG, `refreshCollectedState: server request failed, fallback to local`)
        const newSet = new Set<number>()
        for (let i = 0; i < this.songList.length; i++) {
          const song = this.songList[i]
          if (OpenApiSdk.personalAssetsApi?.isSongCollected(song)) {
            newSet.add(song.getSongId())
          }
        }
        this.collectedSongIds = newSet
      }
    } catch (e) {
      MLog.e(TAG, `refreshCollectedState error: ${JSON.stringify(e)}`)
      // 出错时回退到本地缓存查询
      const newSet = new Set<number>()
      for (let i = 0; i < this.songList.length; i++) {
        const song = this.songList[i]
        if (OpenApiSdk.personalAssetsApi?.isSongCollected(song)) {
          newSet.add(song.getSongId())
        }
      }
      this.collectedSongIds = newSet
    }
  }

  /**
   * 播放全部
   * 自动跳过不可播放（置灰）的歌曲，从第一首可播放歌曲开始
   * @returns 播放是否成功
   */
  playAllSongs(): boolean {
    if (this.songList.length === 0) {
      MLog.w(TAG, 'playAllSongs: songList is empty')
      return false
    }
    // 找到第一首可播放歌曲的位置，跳过置灰歌曲
    const startPos = this.findFirstCanPlayIndex(0)
    if (startPos < 0) {
      MLog.w(TAG, 'playAllSongs: no playable song found')
      return false
    }
    const playParam: IPlayParam = {
      playListType: this.playListType,
      playListTypeId: this.currentListId,
      songList: this.songList,
      startPos: startPos,
      startPlay: true
    }
    const result = OpenApiSdk.playerApi?.playSongs(playParam) ?? -1
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `playAllSongs failed, startPos: ${startPos}, error: ${result}`)
      return false
    }
    MLog.i(TAG, `playAllSongs success, startPos: ${startPos}, count: ${this.songList.length}`)
    this.refreshPlayState()
    // 上报最近播放（对应安卓 reportRecentPlay）
    this.reportRecentPlay()
    return true
  }

  // 判断当前播放列表是否为本列表
  isCurrentAlbumPlaying(): boolean {
    return this.currentPlayStatus === PlayStatus.PLAYING
      && this.isCurrentAlbumList()
  }

  isCurrentAlbumPaused(): boolean {
    return this.currentPlayStatus === PlayStatus.PAUSE
      && this.isCurrentAlbumList()
  }

  private isCurrentAlbumList(): boolean {
    const currentListType = OpenApiSdk.playerApi?.getPlayListType()
    const currentListId = OpenApiSdk.playerApi?.getPlayListTypeId()
    return currentListType === this.playListType
      && currentListId === this.currentListId
  }

  /**
   * 暂停播放
   */
  pause(): void {
    const result = OpenApiSdk.playerApi?.pause() ?? -1
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `pause failed, error: ${result}`)
    } else {
      MLog.i(TAG, 'pause success')
      this.refreshPlayState()
    }
  }

  /**
   * 恢复播放
   */
  resume(): void {
    const result = OpenApiSdk.playerApi?.resume() ?? -1
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `resume failed, error: ${result}`)
    } else {
      MLog.i(TAG, 'resume success')
      this.refreshPlayState()
    }
  }

  /**
   * 随机打乱并添加到播放列表
   */
  shuffleAppendToPlaylist(): void {
    if (this.songList.length === 0) {
      MLog.w(TAG, 'shuffleAppendToPlaylist: songList is empty')
      return
    }
    // 浅拷贝并打乱
    const shuffled = this.songList.slice()
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const temp = shuffled[i]
      shuffled[i] = shuffled[j]
      shuffled[j] = temp
    }
    const result = OpenApiSdk.playerApi?.appendSongToPlaylist(shuffled)
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `shuffleAppendToPlaylist failed, error: ${result}`)
    } else {
      MLog.i(TAG, `shuffleAppendToPlaylist success, count: ${shuffled.length}`)
    }
  }

  /**
   * 点击歌曲 → 播放该歌曲
   * 若点击的歌曲不可播放（置灰），返回 false，由调用方弹出无版权提示
   * @param index 歌曲在列表中的索引
   * @param songList 可选，外部传入的歌曲列表；不传则使用内部 this.songList
   * @returns 播放是否成功；置灰歌曲返回 false
   */
  playSongAt(index: number, songList?: ISongInfo[]): boolean {
    const list = songList ?? this.songList
    if (index < 0 || index >= list.length) {
      MLog.w(TAG, `playSongAt: invalid index ${index}`)
      return false
    }
    const song = list[index]
    // 不可播放（置灰）歌曲：不跳转播放，由调用方展示提示
    if (!song.canPlay()) {
      MLog.w(TAG, `playSongAt: song can't play, name=${song.getSongName()}, msg=${song.getUnplayableMsg()}`)
      return false
    }
    const playParam: IPlayParam = {
      playListType: this.playListType,
      playListTypeId: this.currentListId,
      songList: list,
      startPos: index,
      startPlay: true
    }
    const result = OpenApiSdk.playerApi?.playSongs(playParam) ?? -1
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `playSongAt failed, index: ${index}, error: ${result}`)
      return false
    }
    MLog.i(TAG, `playSongAt success, index: ${index}, song: ${song.getSongName()}`)
    // 上报最近播放（对应安卓 reportRecentPlay）
    this.reportRecentPlay()
    return true
  }

  /**
   * 整行点击回调（ISongListItemHost 接口）
   * 置灰歌曲弹出提示，可播放歌曲则播放并跳转播放页
   * @returns 是否成功播放（供组件判断是否需要跳转）
   */
  onSongClick(song: ISongInfo, index: number, songList: ISongInfo[]): void {
    if (!song.canPlay()) {
      const msg = song.getUnplayableMsg()
      ToastUtil.show(msg ?? '暂无版权，无法播放')
      return
    }
    this.playSongAt(index, songList)
  }

  /**
   * 是否处于多选编辑模式（ISongListItemHost 接口）
   */
  isEditorMode(): boolean {
    return this.showEditorView
  }

  /**
   * 获取指定位置的序号颜色（ISongListItemHost 接口）
   * 前三名红色，其余灰色
   */
  getIndexColor(index: number): string {
    return index < 3 ? '#FF4D4F' : '#666666'
  }

  /**
   * 从指定位置开始，找到第一首可播放歌曲的索引
   * 优先从 startIndex 往后找；若后面没有可播放歌曲，再从头找到 startIndex 之前
   * @param startIndex 起始搜索位置
   * @returns 可播放歌曲的索引，若没有则返回 -1
   */
  private findFirstCanPlayIndex(startIndex: number): number {
    if (this.songList.length === 0) {
      return -1
    }
    // 先从 startIndex 往后找
    for (let i = startIndex; i < this.songList.length; i++) {
      if (this.songList[i].canPlay()) {
        return i
      }
    }
    // 再从头找到 startIndex 之前
    for (let i = 0; i < startIndex; i++) {
      if (this.songList[i].canPlay()) {
        return i
      }
    }
    return -1
  }

  /**
   * 添加歌曲到下一曲
   */
  addToNext(song: ISongInfo): void {
    const result = OpenApiSdk.playerApi?.addToNext(true, song) ?? -1
    if (result === PlayError.PLAY_ERR_NONE) {
      MLog.i(TAG, `addToNext success: ${song.getSongName()}`)
    } else {
      MLog.w(TAG, `addToNext failed: ${song.getSongName()}, error: ${result}`)
    }
  }

  /**
   * 添加歌曲到播放列表末尾
   */
  appendToPlaylist(song: ISongInfo): void {
    const result = OpenApiSdk.playerApi?.appendSongToPlaylist([song]) ?? -1
    if (result === PlayError.PLAY_ERR_NONE) {
      MLog.i(TAG, `appendToPlaylist success: ${song.getSongName()}`)
    } else {
      MLog.w(TAG, `appendToPlaylist failed: ${song.getSongName()}, error: ${result}`)
    }
  }

  /**
   * 切换单首歌曲收藏状态
   * 根据 DemoGlobal.isPersonalAssets 判断走资产模块还是直接 API
   */
  async toggleSongCollect(song: ISongInfo): Promise<void> {
    try {
      const songId = song.getSongId()
      const isCurrentlyCollected = this.collectedSongIds.has(songId)
      const targetState = !isCurrentlyCollected
      const enablePersonalAssets = DemoGlobal.isPersonalAssets;

      let result = false
      if (enablePersonalAssets) {
        // 资产模块路径
        result = await OpenApiSdk.personalAssetsApi?.setSongCollected(song, targetState) ?? false
      } else {
        // 非资产模块路径：直接操作"我喜欢"歌单
        result = await this.toggleSongCollectViaApi(song, targetState)
      }

      if (result) {
        const newSet = new Set(this.collectedSongIds)
        if (isCurrentlyCollected) {
          newSet.delete(songId)
        } else {
          newSet.add(songId)
        }
        this.collectedSongIds = newSet
      }
      MLog.i(TAG, `toggleSongCollect: ${song.getSongName()}, collected: ${targetState}, result: ${result}`)
    } catch (e) {
      MLog.e(TAG, `toggleSongCollect error: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 非资产模块路径：通过 OpenApi 直接操作"我喜欢"歌单
   */
  private async toggleSongCollectViaApi(song: ISongInfo, targetState: boolean): Promise<boolean> {
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.fetchPersonalFolder()
      const folder = resp?.data?.find((f: IFolder) => f.getName() === '我喜欢')
      if (!folder) {
        MLog.w(TAG, 'toggleSongCollectViaApi: 我喜欢 folder not found')
        return false
      }
      const folderId = folder.getId()
      if (targetState) {
        // 收藏：添加到"我喜欢"
        const addResp = await OpenApiSdk.openApi?.folderApi.addSongToFolder(folderId, [song])
        return addResp?.isSuccess() ?? false
      } else {
        // 取消收藏：从"我喜欢"删除
        const idList = [song.getSongId()]
        const midList: string[] = []
        const mid = song.getSongMid()
        if (mid) {
          midList.push(mid)
        }
        const typeList: string[] = []
        const st = song.getSongType()
        if (st !== null && st !== undefined) {
          typeList.push(st.toString())
        }
        const delResp = await OpenApiSdk.openApi?.folderApi.deleteSongFromFolder(
          folderId, idList, midList.length > 0 ? midList : undefined, typeList.length > 0 ? typeList : undefined
        )
        return delResp?.isSuccess() ?? false
      }
    } catch (e) {
      MLog.e(TAG, `toggleSongCollectViaApi error: ${JSON.stringify(e)}`)
      return false
    }
  }

  /**
   * 判断歌曲是否已收藏
   */
  isSongCollected(song: ISongInfo): boolean {
    return this.collectedSongIds.has(song.getSongId())
  }

  /**
   * 判断歌曲是否为当前正在播放的歌曲
   */
  isCurrentPlayingSong(song: ISongInfo): boolean {
    return this.currentPlayingSongId === song.getSongId()
  }

  /**
   * 切换多选模式
   */
  toggleEditorView(): void {
    this.showEditorView = !this.showEditorView
    if (!this.showEditorView) {
      this.clearSelection()
    }
  }

  /**
   * 全选/取消全选
   */
  toggleSelectAll(): void {
    if (this.isTogglingAll) {
      return
    }
    this.isTogglingAll = true
    try {
      if (this.isAllSelected) {
        this.clearSelection()
      } else {
        this.selectAllSongs()
      }
    } finally {
      this.isTogglingAll = false
    }
  }

  /**
   * 全选所有歌曲
   * 先构建完整 Set 再一次性赋值，避免中间状态触发 UI 刷新
   */
  selectAllSongs(): void {
    const newSet = new Set<number>()
    for (let i = 0; i < this.songList.length; i++) {
      newSet.add(this.songList[i].getSongId())
    }
    this.selectedSongIds = newSet
    this.isAllSelected = true
  }

  /**
   * 清除选择
   */
  clearSelection(): void {
    this.selectedSongIds = new Set()
    this.isAllSelected = false
  }

  /**
   * 切换单首歌曲选中状态
   * 当 isTogglingAll 为 true 时忽略，防止全选操作级联触发 onChange
   */
  toggleSongSelection(song: ISongInfo): void {
    if (this.isTogglingAll) {
      return
    }
    const id = song.getSongId()
    const newSet = new Set(this.selectedSongIds)
    if (newSet.has(id)) {
      newSet.delete(id)
    } else {
      newSet.add(id)
    }
    this.selectedSongIds = newSet
    this.isAllSelected = newSet.size === this.songList.length
  }

  /**
   * 判断歌曲是否被选中
   */
  isSongSelected(song: ISongInfo): boolean {
    return this.selectedSongIds.has(song.getSongId())
  }

  /**
   * 获取选中的歌曲列表
   */
  getSelectedSongs(): ISongInfo[] {
    return this.songList.filter((song) => this.selectedSongIds.has(song.getSongId()))
  }

  /**
   * 将选中的歌曲添加到播放列表
   */
  appendSelectedToPlaylist(): void {
    const selected = this.getSelectedSongs()
    if (selected.length === 0) {
      MLog.w(TAG, 'appendSelectedToPlaylist: no selected songs')
      return
    }
    const result = OpenApiSdk.playerApi?.appendSongToPlaylist(selected) ?? -1
    if (result === PlayError.PLAY_ERR_NONE) {
      MLog.i(TAG, `appendSelectedToPlaylist success, count: ${selected.length}`)
      this.clearSelection()
      this.showEditorView = false
    } else {
      MLog.w(TAG, `appendSelectedToPlaylist failed, error: ${result}`)
    }
  }

  /**
   * 是否允许删除选中歌曲（仅歌单场景支持）
   */
  canDeleteSelected(): boolean {
    return this.playListType === MusicListType.TYPE_NULL && this.folderId > 0
  }

  /**
   * 删除选中的歌曲
   * - 歌单场景：调用 deleteSongFromFolder API，成功后重新加载
   * - 专辑场景：不支持删除
   */
  async deleteSelectedSongs(): Promise<void> {
    const selected = this.getSelectedSongs()
    if (selected.length === 0) {
      MLog.w(TAG, 'deleteSelectedSongs: no selected songs')
      return
    }
    if (this.playListType !== MusicListType.TYPE_NULL || this.folderId <= 0) {
      ToastUtil.show('不能操作非自己的歌单')
      MLog.w(TAG, `deleteSelectedSongs: not supported for playListType=${this.playListType}`)
      return
    }
    try {
      const songIdList = selected.map((song) => song.getSongId())
      const midList: string[] = []
      selected.forEach((song) => {
        const mid = song.getSongMid()
        if (mid) {
          midList.push(mid)
        }
      })
      const songTypes: string[] = []
      selected.forEach((song) => {
        const st = song.getSongType()
        if (st !== null && st !== undefined) {
          songTypes.push(st.toString())
        }
      })
      const resp = await OpenApiSdk.openApi?.folderApi.deleteSongFromFolder(
        this.folderId,
        songIdList,
        midList.length > 0 ? midList : undefined,
        songTypes.length > 0 ? songTypes : undefined
      )
      if (resp && resp.isSuccess()) {
        MLog.i(TAG, `deleteSelectedSongs success, deleted: ${selected.length}`)
        this.clearSelection()
        this.showEditorView = false
        // 重新加载歌曲列表
        this.loadSongs()
      } else {
        ToastUtil.show(`${resp?.errorMsg || "删除失败"}`)
        MLog.w(TAG, `deleteSelectedSongs failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `deleteSelectedSongs error: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 切换添加歌曲对话框
   */
  toggleAddSongDialog(): void {
    this.showAddSongDialog = !this.showAddSongDialog
    if (!this.showAddSongDialog) {
      this.addSongInputText = ''
    }
  }

  /**
   * 通过输入歌曲ID添加歌曲到歌单
   */
  async addSongsByIds(): Promise<void> {
    if (!this.addSongInputText || this.addSongInputText.trim().length === 0) {
      return
    }
    const regex = /^[0-9,]+$/
    if (!regex.test(this.addSongInputText.trim())) {
      MLog.w(TAG, 'addSongsByIds: invalid input format')
      return
    }
    const idList = this.addSongInputText.trim()
      .split(',')
      .map((s) => parseInt(s.trim()))
      .filter((n) => !isNaN(n))
    if (idList.length === 0) {
      return
    }
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.addSongToFolderByIds(
        this.currentListId,
        idList,
        undefined
      )
      if (resp && resp.isSuccess()) {
        MLog.i(TAG, `addSongsByIds success, count: ${idList.length}`)
        this.showAddSongDialog = false
        this.addSongInputText = ''
        this.loadSongs()
      } else {
        MLog.w(TAG, `addSongsByIds failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `addSongsByIds error: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 收藏/取消收藏当前歌单、专辑或歌手
   */
  async toggleListCollect(): Promise<void> {
    if (this.isTogglingCollect) {
      return
    }
    // 榜单不支持收藏
    if (this.playListType === MusicListType.TYPE_ONLINE) {
      MLog.w(TAG, 'toggleListCollect: rank does not support collect')
      return
    }
    this.isTogglingCollect = true
    try {
      if (this.playListType === MusicListType.TYPE_ALBUM) {
        if (this.album) {
          let resp = await OpenApiSdk.openApi?.albumApi.collectAlbum(!this.isListCollected, [this.album.getId()])
          if (resp && resp.isSuccess()) {
            this.isListCollected = !this.isListCollected
            MLog.i(TAG, `toggleListCollect(album) success: ${this.isListCollected}`)
          } else {
            MLog.w(TAG, `toggleListCollect(album) failed`)
          }
        }
      } else if (this.playListType === MusicListType.TYPE_FOLDER) {
        if (this.folder) {
          let resp: OpenApiResponse<boolean> | undefined
          if (!this.isListCollected) {
            resp = await OpenApiSdk.openApi?.folderApi.collectFolder(this.folder.getId());
          } else {
            resp = await OpenApiSdk.openApi?.folderApi.unCollectFolder(this.folder.getId());
          }
          if (resp && resp.isSuccess()) {
            this.isListCollected = !this.isListCollected
            MLog.i(TAG, `toggleListCollect(folder) success: ${this.isListCollected}`)
          } else {
            MLog.w(TAG, `toggleListCollect(folder) failed`)
          }
        }
      } else if (this.playListType === MusicListType.TYPE_SINGER) {
        let resp = await OpenApiSdk.openApi?.singerApi.collectSinger(!this.isListCollected, [this.singerId])
        if (resp && resp.isSuccess()) {
          this.isListCollected = !this.isListCollected
          MLog.i(TAG, `toggleListCollect(singer) success: ${this.isListCollected}`)
        } else {
          MLog.w(TAG, `toggleListCollect(singer) failed`)
        }
      }
    } catch (e) {
      MLog.e(TAG, `toggleListCollect error: ${JSON.stringify(e)}`)
    } finally {
      this.isTogglingCollect = false
    }
  }

  /**
   * 批量收藏/取消收藏当前列表所有歌曲到"我喜欢"歌单
   * 独立于 isListCollected（收藏专辑/歌单本身），仅操作歌曲
   */
  async toggleCollectAllSongs(): Promise<void> {
    if (this.songList.length === 0) {
      MLog.w(TAG, 'toggleCollectAllSongs: songList is empty')
      return
    }
    const isAllCollected = this.isAllSongsCollected
    const targetState = !isAllCollected

    try {
      // 收集歌曲 ID 和 Mid
      const songIds: number[] = []
      const songMids: string[] = []
      const songTypes: string[] = []
      for (let i = 0; i < this.songList.length; i++) {
        const s = this.songList[i]
        songIds.push(s.getSongId())
        const mid = s.getSongMid()
        if (mid) {
          songMids.push(mid)
        }
        const st = s.getSongType()
        if (st !== null && st !== undefined) {
          songTypes.push(st.toString())
        }
      }

      // 使用 operSongOfMyLikeSongList 批量操作服务端"我喜欢"歌单
      const resp = await OpenApiSdk.openApi?.folderApi.operSongOfMyLikeSongList(
        targetState,
        songIds,
        songMids.length > 0 ? songMids : undefined,
        songTypes.length > 0 ? songTypes : undefined
      )

      if (resp && resp.isSuccess()) {
        // 同步更新 collectedSongIds（页面内 UI 实时刷新）
        if (targetState) {
          const newSet = new Set<number>()
          for (let i = 0; i < this.songList.length; i++) {
            newSet.add(this.songList[i].getSongId())
          }
          this.collectedSongIds = newSet
        } else {
          this.collectedSongIds = new Set()
        }
        MLog.i(TAG, `toggleCollectAllSongs success, targetState: ${targetState}, count: ${this.songList.length}`)
      } else {
        MLog.w(TAG, `toggleCollectAllSongs failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `toggleCollectAllSongs error: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 获取歌曲支持的音质列表（按优先级分组展示用）
   * @returns 按优先级排序的音质列表
   */
  getSongQualityPriorityList(song: ISongInfo): PlayerEnums.Quality[] {
    const result: PlayerEnums.Quality[] = []
    // 杜比
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.DOLBY) === true) {
      result.push(PlayerEnums.Quality.DOLBY)
    }
    // 全景声
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.GALAXY) === true) {
      result.push(PlayerEnums.Quality.GALAXY)
    }
    // Hi-Res
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.HIRES) === true) {
      result.push(PlayerEnums.Quality.HIRES)
    }
    // 臻品
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.EXCELLENT) === true) {
      result.push(PlayerEnums.Quality.EXCELLENT)
    }
    // SQ
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.SQ) === true) {
      result.push(PlayerEnums.Quality.SQ)
    }
    // HQ
    if (song.hasQualityHQ()) {
      result.push(PlayerEnums.Quality.HQ)
    }
    // 标准
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.STANDARD) === true) {
      result.push(PlayerEnums.Quality.STANDARD)
    }
    // WANOS
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.WANOS) === true) {
      result.push(PlayerEnums.Quality.WANOS)
    }
    // 黑胶
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.VINYL) === true) {
      result.push(PlayerEnums.Quality.VINYL)
    }
    // 母带
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.MASTER_TAPE) === true) {
      result.push(PlayerEnums.Quality.MASTER_TAPE)
    }
    // 伴奏
    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.VOCAL_ACCOMPANY) === true) {
      result.push(PlayerEnums.Quality.VOCAL_ACCOMPANY)
    }
    return result
  }
}
