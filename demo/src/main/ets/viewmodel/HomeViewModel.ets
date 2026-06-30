import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ICategory, IBanner, IFolder, IPlayParam, GetMVRecommendCmd, AreaID, CategoryType, OpenApiResponse, IArea,
  IMediaResDetail,
  IAlbum,
  IOtherPlatListeningList,
  AreaId,
  AreaShelfType,
  IShelf,
  IHomepageRecommendation,
  ICard} from '@qqmusic/opisdk-entity'
import { HomepageRecommendation } from '@qqmusic/opisdk-openapi'
import { ISongInfo, ISinger, MusicListType, PlayError } from '@qqmusic/opisdk-qmutils'

const TAG = 'HomeViewModel'

@ObservedV2
export class HomeViewModel {
  // 首页分类歌单
  @Trace public categories: ICategory[] = []
  // 场景歌单分类
  @Trace public sceneCategories: ICategory[] = []
  // 场景歌单是否已加载过
  private sceneCategoriesLoaded: boolean = false
  // Banner 配置
  @Trace public bannerList: IBanner[] = []
  // 个人歌单
  @Trace public mineFolders: IFolder[] = []
  // 首页推荐数据
  @Trace public recommendation: IHomepageRecommendation | null = null
  // 推荐 Shelf 列表（从 recommendation 提取，便于 UI 响应式追踪）
  @Trace public shelfList: IShelf[] = []
  // MV 推荐列表（详细信息，包含歌手等）
  @Trace public mvRecommendDetailList: IMediaResDetail[] = []
  // 是否正在加载
  @Trace public isLoadingCategory: boolean = false
  @Trace public isLoadingBanner: boolean = false
  @Trace public isLoadingRecommend: boolean = false
  @Trace public isLoadingMv: boolean = false
  // 是否已完成初始化
  private isInitialized: boolean = false
  // ========== 专区相关状态 ==========
  /** 当前专区数据 */
  @Trace public currentArea: IArea | null = null
  /** 专区加载中 */
  @Trace public isLoadingArea: boolean = false
  /** 专区加载错误信息 */
  @Trace public areaErrorMsg: string = ''
  /** 是否显示刷新按钮 */
  @Trace public showRefreshButton: boolean = false
  /** 是否显示 Wanos 弹窗 */
  @Trace public showWanosDialog: boolean = false

  constructor() {
  }

  init(): void {
    if (this.isInitialized) {
      return
    }
    this.isInitialized = true
    this.fetchCategory()
    this.fetchBannerConfig()
    this.fetchHomeRecommendation()
  }

  /**
   * 获取分类歌单数据
   */
  async fetchCategory() {
    if (this.isLoadingCategory) {
      return
    }
    this.isLoadingCategory = true
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.fetchCategoryOfFolder()
      if (resp && resp.isSuccess() && resp.data) {
        this.categories = resp.data
        MLog.i(TAG, `fetchCategory success, count: ${this.categories.length}`)
      } else {
        MLog.w(TAG, `fetchCategory failed: ${resp?.errorMsg}`)
        this.categories = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchCategory error: ${JSON.stringify(e)}`)
      this.categories = []
    } finally {
      this.isLoadingCategory = false
    }
  }

  /**
   * 获取场景歌单分类数据
   * 对应 Android 端 HomeViewModel.fetchSceneCategory()
   */
  async fetchSceneCategory() {
    if (this.sceneCategoriesLoaded) {
      return
    }
    if (this.sceneCategories.length > 0) {
      return
    }
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.fetchCategoryOfSongListScene()
      if (resp && resp.isSuccess() && resp.data) {
        this.sceneCategories = resp.data
        this.sceneCategoriesLoaded = true
        MLog.i(TAG, `fetchSceneCategory success, count: ${this.sceneCategories.length}`)
      } else {
        MLog.w(TAG, `fetchSceneCategory failed: ${resp?.errorMsg}`)
        this.sceneCategories = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchSceneCategory error: ${JSON.stringify(e)}`)
      this.sceneCategories = []
    }
  }

  /**
   * 获取 Banner 配置
   */
  async fetchBannerConfig() {
    if (this.isLoadingBanner) {
      return
    }
    this.isLoadingBanner = true
    try {
      const resp = await OpenApiSdk.openApi?.recommendApi.fetchBannerConfig()
      if (resp && resp.isSuccess() && resp.data) {
        this.bannerList = resp.data
        MLog.i(TAG, `fetchBannerConfig success, count: ${this.bannerList.length}`)
      } else {
        MLog.w(TAG, `fetchBannerConfig failed: ${resp?.errorMsg}`)
        this.bannerList = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchBannerConfig error: ${JSON.stringify(e)}`)
      this.bannerList = []
    } finally {
      this.isLoadingBanner = false
    }
  }

  /**
   * 获取首页推荐数据（单曲 type=200，歌单 type=500）
   */
  async fetchHomeRecommendation() {
    if (this.isLoadingRecommend) {
      return
    }
    this.isLoadingRecommend = true
    try {
      const types: number[] = [200, 500]
      const resp = await OpenApiSdk.openApi?.recommendApi.fetchHomepageRecommendationWithSongInfo(types)
      if (resp && resp.isSuccess() && resp.data) {
        this.recommendation = resp.data
        this.shelfList = this.recommendation.getShelfList() ?? []
        MLog.i(TAG, `fetchHomeRecommendation success, shelfCount: ${this.shelfList.length}`)
      } else {
        MLog.w(TAG, `fetchHomeRecommendation failed: ${resp?.errorMsg}`)
        this.recommendation = null
        this.shelfList = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchHomeRecommendation error: ${JSON.stringify(e)}`)
      this.recommendation = null
      this.shelfList = []
    } finally {
      this.isLoadingRecommend = false
    }
  }

  /**
   * 播放推荐歌曲列表中指定歌曲
   */
  playRecommendSongs(card: ICard): void {
    if (card.getSongInfo() === null) {
      MLog.w(TAG, 'playRecommendSongs: songInfo is null')
      return
    }
    const songList: ISongInfo[] = []
    this.shelfList.forEach((shelf: IShelf) => {
      if (shelf.getCardList().length > 0 && shelf.getCardList()[0].getType() === 200) {
        shelf.getCardList().forEach((c: ICard) => {
          if (c.getSongInfo() !== null) {
            songList.push(c.getSongInfo()!)
          }
        })
      }
    })
    const targetSong = card.getSongInfo()!
    const pos = songList.findIndex((s: ISongInfo) => s.getSongId() === targetSong.getSongId())
    const playParam: IPlayParam = {
      playListType: MusicListType.TYPE_ONLINE,
      playListTypeId: 0,
      songList: songList,
      startPos: pos >= 0 ? pos : 0,
      startPlay: true
    }
    const result = OpenApiSdk.playerApi?.playSongs(playParam) ?? -1
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `playRecommendSongs failed, error: ${result}`)
    }
  }

  /**
   * 获取个人歌单列表
   */
  async fetchMineFolder() {
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.fetchPersonalFolder()
      if (resp && resp.isSuccess() && resp.data) {
        this.mineFolders = resp.data
        MLog.i(TAG, `fetchMineFolder success, count: ${this.mineFolders.length}`)
      } else {
        this.mineFolders = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchMineFolder error: ${JSON.stringify(e)}`)
      this.mineFolders = []
    }
  }

  /**
   * 获取 MV 推荐列表（含详细信息）
   * 先获取简单列表，再通过 getMediaInfo 获取包含歌手信息的详情
   */
  async fetchMvRecommend() {
    await this.fetchMvRecommendWithFilter(GetMVRecommendCmd.LATEST, AreaID.Mainland, CategoryType.ALL)
  }

  /**
   * 获取 MV 推荐列表（含详细信息，支持筛选条件）
   */
  async fetchMvRecommendWithFilter(type: GetMVRecommendCmd, areaID: AreaID, category: CategoryType) {
    if (this.isLoadingMv) {
      return
    }
    this.isLoadingMv = true
    try {
      const resp = await OpenApiSdk.openApi?.edgeMediaApi?.getRecommendMVList(type, areaID, category)
      if (resp && resp.isSuccess() && resp.data) {
        const simpleList = resp.data
        MLog.i(TAG, `fetchMvRecommend simpleList success, count: ${simpleList.length}`)
        // 取前50个 vid 获取详细信息（含歌手信息）
        const ids = simpleList.map(item => item.getVid() ?? '').filter(v => v.length > 0).slice(0, 50)
        if (ids.length > 0) {
          const detailResp = await OpenApiSdk.openApi?.edgeMediaApi?.getMediaInfo(ids)
          if (detailResp && detailResp.isSuccess() && detailResp.data) {
            this.mvRecommendDetailList = detailResp.data
            MLog.i(TAG, `fetchMvRecommend detailList success, count: ${this.mvRecommendDetailList.length}`)
          } else {
            this.mvRecommendDetailList = []
          }
        } else {
          this.mvRecommendDetailList = []
        }
      } else {
        MLog.w(TAG, `fetchMvRecommend failed: ${resp?.errorMsg}`)
        this.mvRecommendDetailList = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchMvRecommend error: ${JSON.stringify(e)}`)
      this.mvRecommendDetailList = []
    } finally {
      this.isLoadingMv = false
    }
  }

  /**
   * 获取 Hires 专区数据
   */
  async fetchHiresSection(): Promise<void> {
    await this.fetchAreaDataInternal(
      () => OpenApiSdk.openApi?.operAreaApi.fetchHiresSectionByShelfTypes(null),
      'fetchHiresSection'
    )
  }

  /**
   * 获取 Dolby 专区数据
   */
  async fetchDolbySection(): Promise<void> {
    await this.fetchAreaDataInternal(
      () => OpenApiSdk.openApi?.operAreaApi.fetchDolbySectionByShelfTypes([]),
      'fetchDolbySection'
    )
  }

  /**
   * 获取臻品全景声专区数据
   */
  async fetchGalaxySection(): Promise<void> {
    await this.fetchAreaDataInternal(
      () => OpenApiSdk.openApi?.operAreaApi.fetchGalaxySectionByShelfTypes([]),
      'fetchGalaxySection'
    )
  }

  /**
   * 获取指定专区数据（通用方法）
   */
  async fetchAreaSection(areaId: number): Promise<void> {
    await this.fetchAreaDataInternal(
      () => OpenApiSdk.openApi?.operAreaApi.fetchAreaSectionByShelfTypes(areaId, this.getShelfTypes(areaId)),
      `fetchAreaSection_${areaId}`
    )
  }

  /**
   * 获取指定专区数据的类型
   */
  private getShelfTypes(areaId: number): Array<number> {
    switch (areaId) {
      case AreaId.Wanos:
        return [AreaShelfType.AreaShelfType_Song];
      case AreaId.Vinly:
        return [AreaShelfType.AreaShelfType_Album, AreaShelfType.AreaShelfType_Folder];
      case AreaId.XiaoYuZhou:
        return [AreaShelfType.AreaShelfType_Song];
      default:
        return [];
    }
  }

  /**
   * 内部通用专区数据获取方法
   */
  private async fetchAreaDataInternal(
    apiCall: () => Promise<OpenApiResponse<IArea>> | undefined,
    logTag: string
  ): Promise<void> {
    if (this.isLoadingArea) {
      return
    }
    this.isLoadingArea = true
    this.areaErrorMsg = ''
    this.showRefreshButton = false
    try {
      const resp = await (apiCall() ?? Promise.resolve(undefined))
      if (resp && resp.isSuccess() && resp.data) {
        this.currentArea = resp.data
        this.showRefreshButton = false
        MLog.i(TAG, `${logTag} success, shelves: ${this.currentArea.getShelves()?.length ?? 0}`)
      } else {
        const errMsg = resp?.errorMsg ?? '请求失败'
        this.areaErrorMsg = errMsg
        this.currentArea = null
        this.showRefreshButton = true
        MLog.w(TAG, `${logTag} failed: ${errMsg}`)
      }
    } catch (e) {
      this.areaErrorMsg = '网络请求异常'
      this.currentArea = null
      this.showRefreshButton = true
      MLog.e(TAG, `${logTag} error: ${JSON.stringify(e)}`)
    } finally {
      this.isLoadingArea = false
    }
  }

  /**
   * 根据 areaId 获取对应专区数据
   */
  async fetchAreaDataById(areaId: number): Promise<void> {
    switch (areaId) {
      case AreaId.AreaDolby:
        await this.fetchDolbySection()
        break
      case AreaId.AreaHires:
        await this.fetchHiresSection()
        break
      case AreaId.AreaGalaxy:
        await this.fetchGalaxySection()
        break
      default:
        await this.fetchAreaSection(areaId)
        break
    }
  }

  /**
   * 获取 Wanos 限免权益信息
   */
  async getFreeLimitedTimeWanosProfitInfo(): Promise<void> {
    // 鸿蒙端暂不实现 Wanos 弹窗逻辑，后续可补充
    MLog.i(TAG, 'getFreeLimitedTimeWanosProfitInfo: not implemented on HarmonyOS')
  }

  /**
   * 清理专区数据
   */
  cleanAreaData(): void {
    this.currentArea = null
    this.areaErrorMsg = ''
    this.showRefreshButton = false
    this.showWanosDialog = false
    this.isLoadingArea = false
  }

  /**
   * 清除请求状态
   * 在登录/登出操作后调用，重置加载状态以便重新拉取数据
   */
  clearRequestState(): void {
    this.sceneCategoriesLoaded = false
    this.cleanAreaData()
  }

  /**
   * 登录/登出后刷新首页数据
   */
  async refreshAfterLogin() {
    this.clearRequestState()
  }

  smartSearchKey(key: string, callback: (list: string[]) => void) {
    callback(["周杰伦", "陈奕迅", "林俊杰", "SearchKey:" + key])
  }

  search(type: number, key: string) {
    MLog.i(TAG, `Search type: ${type}, key: ${key}`)
  }

  /**
   * 获取我的收藏歌曲列表
   */
  @Trace public collectedSongList: ISongInfo[] = []
  @Trace public collectedSongListHasMore: boolean = true;
  private collectedSongPassBack = '';

  fetchCollectedSong(): void {
    if (this.collectedSongListHasMore) {
      OpenApiSdk.openApi?.folderApi.fetchSongOfMyLikeFolder(this.collectedSongPassBack).then((result) => {
        if (result.isSuccess()) {
          const songList = result.data;
          if (songList && songList.length > 0) {
            this.collectedSongList.push(...songList);
          }
          this.collectedSongPassBack = result.passBack;
          this.collectedSongListHasMore = result.hasMore;
          MLog.i(TAG, `fetchCollectedSongList success, count: ${this.collectedSongList.length}`);
        }
      }).catch((e: Error) => {
        MLog.e(TAG, `fetchCollectedSongList error: ${JSON.stringify(e)}`);
      });
    }
  }

  /**
   * 获取收藏歌单列表
   */
  @Trace public collectedFolderList: IFolder[] = []

  fetchCollectedFolder() {
    OpenApiSdk.openApi?.folderApi.fetchCollectedFolder().then((result) => {
      if (result.isSuccess() && result.data) {
        this.collectedFolderList = result.data;
        MLog.i(TAG, `fetchCollectedFolder success, count: ${this.collectedFolderList.length}`);
      } else {
        this.collectedFolderList = []
      }
    }).catch((e: Error) => {
      this.collectedFolderList = [];
      MLog.e(TAG, `fetchCollectedFolder error: ${JSON.stringify(e)}`);
    });
  }

  /**
   * 获取收藏MV列表
   */
  @Trace public collectedMvList: IMediaResDetail[] = [];
  private collectedMvPage = 0;
  private collectedMvPageSize = 50;

  fetchCollectedMv() {
    OpenApiSdk.openApi?.edgeMediaApi.getCollectList(this.collectedMvPage, this.collectedMvPageSize).then((result) => {
      if (result.isSuccess()) {
        const mediaList = result.data;
        if (mediaList && mediaList.length > 0) {
          this.collectedMvList.push(...mediaList);
        }
        this.collectedMvPage++;
        MLog.i(TAG, `fetchCollectedMvList success, count: ${this.collectedMvList.length}`);
      }
    }).catch((e: Error) => {
      this.collectedMvList = [];
      this.collectedMvPage = 0;
      MLog.e(TAG, `fetchCollectedMvList error: ${JSON.stringify(e)}`);
    })
  }

  /**
   * 获取收藏专辑列表
   */
  @Trace public collectedAlbumList: IAlbum[] = [];
  private collectedAlbumPage = 0;
  private collectedAlbumPageSize = 50;

  fetchCollectedAlbum() {
    OpenApiSdk.openApi?.albumApi.fetchCollectedAlbum(this.collectedAlbumPage, this.collectedAlbumPageSize, 0)
      .then((result) => {
        if (result.isSuccess()) {
          const albumList = result.data;
          if (albumList && albumList.length > 0) {
            this.collectedAlbumList.push(...albumList);
          }
          this.collectedMvPage++;
          MLog.i(TAG, `fetchCollectedAlbumList success, count: ${this.collectedAlbumList.length}`);
        }
      })
      .catch((e: Error) => {
        this.collectedAlbumList = [];
        this.collectedAlbumPage = 0;
        MLog.e(TAG, `fetchCollectedAlbumList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 获取最近播放单曲
   */
  @Trace public recentSongList: ISongInfo[] = [];
  private recentSongUpdateTime: number = 0;

  fetchRecentSong() {
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlaySong(this.recentSongUpdateTime)
      .then((result) => {
        if (result.isSuccess()) {
          const songList = result.data;
          if (songList && songList.length > 0) {
            this.recentSongList = songList;
          }
          this.recentAlbumUpdateTime = new Date().getTime();
          MLog.i(TAG, `fetchRecentSongList success, count: ${this.recentSongList.length}`);
        }
      })
      .catch((e: Error) => {
        this.recentSongList = [];
        this.recentSongUpdateTime = 0;
        MLog.e(TAG, `fetchRecentSongList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 获取最近播放专辑
   */
  @Trace public recentAlbumList: IAlbum[] = [];
  private recentAlbumUpdateTime: number = 0;

  fetchRecentAlbum() {
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayAlbum(this.recentAlbumUpdateTime)
      .then((result) => {
        if (result.isSuccess()) {
          const albumList = result.data;
          if (albumList && albumList.length > 0) {
            this.recentAlbumList = albumList;
          }
          this.recentAlbumUpdateTime = new Date().getTime();
          MLog.i(TAG, `fetchRecentAlbumList success, count: ${this.recentAlbumList.length}`);
        }
      })
      .catch((e: Error) => {
        this.recentAlbumList = [];
        this.recentAlbumUpdateTime = 0;
        MLog.e(TAG, `fetchRecentAlbumList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 自建歌单
   */
  @Trace public personalFolderList: IFolder[] = []

  fetchPersonalFolder() {
    OpenApiSdk.openApi?.folderApi.fetchPersonalFolder()
      .then((result) => {
        if (result.data) {
          this.personalFolderList = result.data
        }
      })
  }

  /**
   * 获取最近播放歌单
   */
  @Trace public recentFolderList: IFolder[] = [];
  private recentFolderUpdateTime: number = 0;

  fetchRecentFolder() {
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayFolder(this.recentFolderUpdateTime)
      .then((result) => {
        if (result.isSuccess()) {
          const folderList = result.data;
          if (folderList && folderList.length > 0) {
            this.recentFolderList = folderList;
          }
          this.recentFolderUpdateTime = new Date().getTime();
          MLog.i(TAG, `fetchRecentFolderList success, count: ${this.recentFolderList.length}`);
        }
      })
      .catch((e: Error) => {
        this.recentFolderList = [];
        this.recentFolderUpdateTime = 0;
        MLog.e(TAG, `fetchRecentFolderList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 获取最近播放长音频
   */
  @Trace public recentLongAudioList: ISongInfo[] = [];
  private recentLongAudioUpdateTime: number = 0;

  fetchRecentLongAudio() {
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayLongAudio(this.recentLongAudioUpdateTime)
      .then((result) => {
        if (result.isSuccess()) {
          const longAudioList = result.data;
          if (longAudioList && longAudioList.length > 0) {
            this.recentLongAudioList = longAudioList;
          }
          this.recentLongAudioUpdateTime = new Date().getTime();
          MLog.i(TAG, `fetchRecentLongAudioList success, count: ${this.recentLongAudioList.length}`);
        }
      })
      .catch((e: Error) => {
        this.recentLongAudioList = [];
        this.recentLongAudioUpdateTime = 0;
        MLog.e(TAG, `fetchRecentLongAudioList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 获取最近播放MV
   */
  @Trace public recentMvList: IMediaResDetail[] = [];
  private recentMvUpdateTime: number = 0;

  fetchRecentMVList() {
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayMv(this.recentMvUpdateTime)
      .then((result) => {
        if (result.isSuccess()) {
          const MvList = result.data;
          if (MvList && MvList.length > 0) {
            this.recentMvList = MvList;
          }
          this.recentMvUpdateTime = new Date().getTime();
          MLog.i(TAG, `fetchRecentMvList success, count: ${this.recentMvList.length}`);
        }
      })
      .catch((e: Error) => {
        this.recentMvList = [];
        this.recentMvUpdateTime = 0;
        MLog.e(TAG, `fetchRecentMvList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 已购专辑纪录
   */
  @Trace public albumBuyRecordList: IAlbum[] = [];
  private albumBuyRecordPage = 0;

  fetchBuyRecordOfAlbum() {
    OpenApiSdk.openApi?.albumApi.fetchBuyRecord(1, this.albumBuyRecordPage)
      .then((result) => {
        if (result.isSuccess()) {
          const albumList = result.data?.albums;
          if (albumList && albumList.length > 0) {
            this.albumBuyRecordList = albumList;
          }
          this.albumBuyRecordPage++;
          MLog.i(TAG, `fetchBuyRecordOfAlbum success, count: ${this.albumBuyRecordList.length}`);
        }
      })
      .catch((e: Error) => {
        this.albumBuyRecordList = [];
        this.albumBuyRecordPage = 0;
        MLog.e(TAG, `fetchBuyRecordOfAlbum error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 已购单曲
   */
  @Trace public songBuyRecordList: ISongInfo[] = [];
  private songBuyRecordPage = 0;

  fetchBuyRecordOfSong() {
    OpenApiSdk.openApi?.albumApi.fetchBuyRecord(2, this.songBuyRecordPage)
      .then((result) => {
        if (result.isSuccess()) {
          const songList = result.data?.songList;
          if (songList && songList.length > 0) {
            this.songBuyRecordList = songList;
          }
          this.songBuyRecordPage++;
          MLog.i(TAG, `fetchBuyRecordOfSong success, count: ${this.songBuyRecordList.length}`);
        }
      })
      .catch((e: Error) => {
        this.songBuyRecordList = [];
        this.songBuyRecordPage = 0;
        MLog.e(TAG, `fetchBuyRecordOfSong error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 已购长音频
   */
  @Trace public longAudioBuyRecordList: IAlbum[] = [];
  private longAudioBuyRecordPage = 0;

  fetchBuyRecordOfLongAudio() {
    OpenApiSdk.openApi?.albumApi.fetchBuyRecord(3, this.longAudioBuyRecordPage)
      .then((result) => {
        if (result.isSuccess()) {
          const longAudioList = result.data?.albums;
          if (longAudioList && longAudioList.length > 0) {
            this.longAudioBuyRecordList = longAudioList;
          }
          this.longAudioBuyRecordPage++;
          MLog.i(TAG, `fetchBuyRecordOfLongAudio success, count: ${this.longAudioBuyRecordList.length}`);
        }
      })
      .catch((e: Error) => {
        this.longAudioBuyRecordList = [];
        this.longAudioBuyRecordPage = 0;
        MLog.e(TAG, `fetchBuyRecordOfLongAudio error: ${JSON.stringify(e)}`);
      });
  }


  @Trace public otherPlatListeningList ?: IOtherPlatListeningList;

  /**
   * 其他端播放列表
   */
  fetchOtherPlatListeningList(){
    OpenApiSdk.openApi?.recentPlayApi.fetchOtherPlatListeningList().then((result)=>{
      this.otherPlatListeningList = result.data;
    })
  }


  /**
   * 收藏有声单曲
   */
  @Trace public collectedVoicedSongList: ISongInfo[] = [];
  private collectedVoicedSongPage = 0;

  fetchCollectedVoicedSong() {
    OpenApiSdk.openApi?.longAudioApi.fetchCollectedLongAudioSongList(1, this.collectedVoicedSongPage)
      .then((result) => {
        if (result.isSuccess()) {
          const songList = result.data;
          if (songList && songList.length > 0) {
            this.collectedVoicedSongList = songList;
          }
          this.collectedVoicedSongPage++;
          MLog.i(TAG, `fetchCollectedVoicedSongList success, count: ${this.collectedVoicedSongList.length}`);
        }
      })
      .catch((e: Error) => {
        this.collectedVoicedSongList = [];
        this.collectedVoicedSongPage = 0;
        MLog.e(TAG, `fetchBuyRecordOfSong error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 收藏播客
   */
  @Trace public longAudioFavList: ISongInfo[] = [];
  private favLongAudioPage = 0;

  fetchCollectedLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCollectedLongAudioSongList(2, this.favLongAudioPage)
      .then((result) => {
        if (result.isSuccess()) {
          const songList = result.data;
          if (songList && songList.length > 0) {
            this.longAudioFavList = songList;
          }
          this.favLongAudioPage++;
          MLog.i(TAG, `fetchCollectedLongAudioList success, count: ${this.longAudioFavList.length}`);
        }
      })
      .catch((e: Error) => {
        this.longAudioFavList = [];
        this.favLongAudioPage = 0;
        MLog.e(TAG, `fetchCollectedLongAudioList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 收藏有声专辑
   */
  @Trace public collectedVoicedAlbumList: IAlbum[] = [];
  private collectedVoicedAlbumPage = 0;
  private collectedVoicedAlbumPageSize = 50;

  fetchCollectedVoicedAlbum() {
    OpenApiSdk.openApi?.albumApi.fetchCollectedAlbum(this.collectedVoicedAlbumPage, this.collectedVoicedAlbumPageSize,
      1)
      .then((result) => {
        if (result.isSuccess()) {
          const albumList = result.data;
          if (albumList && albumList.length > 0) {
            this.collectedVoicedAlbumList = albumList;
          }
          this.collectedVoicedAlbumPage++;
          MLog.i(TAG, `fetchCollectedVoicedAlbumList success, count: ${this.collectedVoicedAlbumList.length}`);
        }
      })
      .catch((e: Error) => {
        this.collectedVoicedAlbumList = [];
        this.collectedVoicedAlbumPage = 0;
        MLog.e(TAG, `fetchCollectedVoicedAlbumList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 收藏有声播客
   */
  @Trace public voicedLongAlbumFavList: IAlbum[] = [];
  private voicedLongAlbumPage = 0;
  private voicedLongAlbumPageSize = 50;

  fetchCollectedVoicedLongAlbum() {
    OpenApiSdk.openApi?.albumApi.fetchCollectedAlbum(this.voicedLongAlbumPage, this.voicedLongAlbumPageSize)
      .then((result) => {
        if (result.isSuccess()) {
          const albumList = result.data;
          if (albumList && albumList.length > 0) {
            this.voicedLongAlbumFavList = albumList;
          }
          this.voicedLongAlbumPage++;
          MLog.i(TAG, `fetchCollectedVoicedLongAlbumList success, count: ${this.voicedLongAlbumFavList.length}`);
        }
      })
      .catch((e: Error) => {
        this.voicedLongAlbumFavList = [];
        this.voicedLongAlbumPage = 0;
        MLog.e(TAG, `fetchCollectedVoicedLongAlbumList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 订阅歌手
   */
  @Trace public collectedSingerList: ISinger[] = [];
  private collectedSingerPage = 0;
  private collectedSingerSize = 50;

  fetchCollectedSingerList() {
    OpenApiSdk.openApi?.singerApi.fetchCollectedSinger(this.collectedSingerPage, this.collectedSingerSize)
      .then((result) => {
        if (result.isSuccess()) {
          const singerList = result.data;
          if (singerList && singerList.length > 0) {
            this.collectedSingerList = singerList;
          }
          this.collectedSingerPage++;
          MLog.i(TAG, `fetchCollectedSingerList success, count: ${this.collectedSingerList.length}`);
        }
      })
      .catch((e: Error) => {
        this.collectedSingerList = [];
        this.collectedSingerPage = 0;
        MLog.e(TAG, `fetchCollectedSingerList error: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 刷新所有 API 面板数据（重置分页并重新拉取）
   * 在页面 onPageShow 时调用，确保数据实时更新
   */
  refreshAllApiData(): void {
    this.refreshCollectedSong();
    this.refreshCollectedFolder();
    this.refreshCollectedMv();
    this.refreshCollectedAlbum();
    this.refreshCollectedVoicedSong();
    this.refreshCollectedVoicedAlbum();
    this.refreshRecentSong();
    this.refreshRecentAlbum();
    this.refreshRecentFolder();
    this.refreshRecentLongAudio();
    this.refreshRecentMv();
    this.refreshBuyRecordOfAlbum();
    this.refreshBuyRecordOfSong();
    this.refreshBuyRecordOfLongAudio();
    this.refreshCollectedSinger();
    this.refreshPersonalFolder();
    this.refreshOtherPlatListening();
  }

  /**
   * 刷新收藏歌曲
   */
  refreshCollectedSong(): void {
    this.collectedSongList = [];
    this.collectedSongPassBack = '';
    this.collectedSongListHasMore = true;
    this.fetchCollectedSong();
  }

  /**
   * 刷新收藏歌单
   */
  refreshCollectedFolder(): void {
    this.collectedFolderList = [];
    this.fetchCollectedFolder();
  }

  /**
   * 刷新收藏MV
   */
  refreshCollectedMv(): void {
    this.collectedMvList = [];
    this.collectedMvPage = 0;
    this.fetchCollectedMv();
  }

  /**
   * 刷新收藏专辑
   */
  refreshCollectedAlbum(): void {
    this.collectedAlbumList = [];
    this.collectedAlbumPage = 0;
    this.fetchCollectedAlbum();
  }

  /**
   * 刷新收藏有声单曲
   */
  refreshCollectedVoicedSong(): void {
    this.collectedVoicedSongList = [];
    this.collectedVoicedSongPage = 0;
    this.fetchCollectedVoicedSong();
  }

  /**
   * 刷新收藏有声专辑
   */
  refreshCollectedVoicedAlbum(): void {
    this.collectedVoicedAlbumList = [];
    this.collectedVoicedAlbumPage = 0;
    this.fetchCollectedVoicedAlbum();
  }

  /**
   * 刷新最近播放单曲
   */
  refreshRecentSong(): void {
    this.recentSongList = [];
    this.recentSongUpdateTime = 0;
    this.fetchRecentSong();
  }

  /**
   * 刷新最近播放专辑
   */
  refreshRecentAlbum(): void {
    this.recentAlbumList = [];
    this.recentAlbumUpdateTime = 0;
    this.fetchRecentAlbum();
  }

  /**
   * 刷新最近播放歌单
   */
  refreshRecentFolder(): void {
    this.recentFolderList = [];
    this.recentFolderUpdateTime = 0;
    this.fetchRecentFolder();
  }

  /**
   * 刷新最近播放长音频
   */
  refreshRecentLongAudio(): void {
    this.recentLongAudioList = [];
    this.recentLongAudioUpdateTime = 0;
    this.fetchRecentLongAudio();
  }

  /**
   * 刷新最近播放MV
   */
  refreshRecentMv(): void {
    this.recentMvList = [];
    this.recentMvUpdateTime = 0;
    this.fetchRecentMVList();
  }

  /**
   * 刷新已购专辑
   */
  refreshBuyRecordOfAlbum(): void {
    this.albumBuyRecordList = [];
    this.albumBuyRecordPage = 0;
    this.fetchBuyRecordOfAlbum();
  }

  /**
   * 刷新已购单曲
   */
  refreshBuyRecordOfSong(): void {
    this.songBuyRecordList = [];
    this.songBuyRecordPage = 0;
    this.fetchBuyRecordOfSong();
  }

  /**
   * 刷新已购长音频
   */
  refreshBuyRecordOfLongAudio(): void {
    this.longAudioBuyRecordList = [];
    this.longAudioBuyRecordPage = 0;
    this.fetchBuyRecordOfLongAudio();
  }

  /**
   * 刷新订阅歌手
   */
  refreshCollectedSinger(): void {
    this.collectedSingerList = [];
    this.collectedSingerPage = 0;
    this.fetchCollectedSingerList();
  }

  /**
   * 刷新自建歌单
   */
  refreshPersonalFolder(): void {
    this.personalFolderList = [];
    this.fetchPersonalFolder();
  }

  /**
   * 刷新其他端播放列表
   */
  refreshOtherPlatListening(): void {
    this.otherPlatListeningList = undefined;
    this.fetchOtherPlatListeningList();
  }
}
