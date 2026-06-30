import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import { IMediaEventListener, OnPlayerErrorListener, IPayAccessInfo } from '@qqmusic/opisdk-entity'
import { PlayErrorUtils } from '@qqmusic/opisdk-musicplayer'
import {
  IProgressChangeListener,
  ISongInfo,
  PlayStatus,
  PlayerEnums,
  PlayerEvent,
  ISoundEffectItem,
  PlayError
} from '@qqmusic/opisdk-qmutils'
import { InsightUtil } from '../utils/InsightUtil'
import { ToastUtil } from '../utils/ToastUtil'
import { SPUtils } from '../utils/SPUtils'
import { DemoGlobal } from '../utils/DemoGlobal'

const TAG = 'PlayerViewModel'

/**
 * 音质条目数据
 * 用于音质弹窗列表的每一行
 */
export class QualityItem {
  /** 音质枚举值 */
  quality: number
  /** 显示名称（含大小、权限标签、试听标签） */
  name: string
  /** 歌曲是否支持该音质 */
  hasQuality: boolean
  /** 是否为当前播放音质 */
  isCurrent: boolean

  constructor(quality: number, name: string, hasQuality: boolean, isCurrent: boolean) {
    this.quality = quality
    this.name = name
    this.hasQuality = hasQuality
    this.isCurrent = isCurrent
  }
}
/**
 * 播放器 ViewModel
 * 管理播放器状态，注册事件监听，暴露响应式状态给 UI 层
 *
 * 实现 IMediaEventListener 以直接注册到播放器事件系统
 * 实现 IProgressChangeListener 以接收播放进度变化
 */
@ObservedV2
export class PlayerViewModel implements IMediaEventListener, IProgressChangeListener, OnPlayerErrorListener {
  /** 当前播放列表 */
  @Trace songList: ISongInfo[] = [];
  // 是否选中
  @Trace selectedList: boolean[] = [];
  // 当前歌曲
  @Trace currentSong: ISongInfo | null = null
  // 播放状态（PlayStatus 枚举值）
  @Trace currentState: number = PlayStatus.IDLE
  // 播放模式（PlayerEnums.Mode 枚举值）
  @Trace currentMode: number = PlayerEnums.Mode.ORDER
  // 当前音质
  @Trace currentQuality: number | null = null
  // 当前播放位置（ms）
  @Trace playPosition: number = 0
  // 总时长（ms）
  @Trace duration: number = 0
  // 实际可播时长（ms），试听歌曲使用 tryEnd
  @Trace actualDuration: number = 0
  // 当前歌词句子
  @Trace curSentence: string = ''
  // 是否电台模式
  @Trace isRadio: boolean = false
  // 播放状态文本
  @Trace playStateText: string = '播放状态: Idle'
  // seek目标位置，-1表示未seek
  @Trace seekPosition: number = -1
  // 是否正在拖拽进度条
  @Trace isSeekBarTracking: boolean = false
  // 播放倍速
  @Trace playSpeed: number = 1.0
  // 是否已收藏
  @Trace isFavorite: boolean = false
  // 偏好音质
  @Trace preferSongQuality: PlayerEnums.Quality = PlayerEnums.Quality.HQ;


  private pendingStartPlay: boolean = false;

  private hasStartPlay: boolean = false;

  // 是否已完成初始化
  private isInitialized: boolean = false

  // 已提示过“试听片段”的会话级歌曲ID，格式为“pageSessionId|songId”，避免跨页重复弹
  private notifiedTryPlayKey: string = ''
  // 每次进入播放页递增的会话ID，歌曲切换时沿用
  private pageSessionId: number = 0

  // 已提示过“试听片段”的歌曲ID，避免同一首试听歌曲重复弹Toast
  private notifiedTryPlaySongId: string = ''

  // 播放模式顺序（用于循环切换）
  private readonly modeOrder: PlayerEnums.Mode[] = [
    PlayerEnums.Mode.ORDER,
    PlayerEnums.Mode.SINGLE_CYCLE,
    PlayerEnums.Mode.RANDOM,
    PlayerEnums.Mode.ONE_NOT_REPEAT
  ]

  // 音质展示顺序
  private readonly qualityOrder: number[] = [
    PlayerEnums.Quality.STANDARD,
    PlayerEnums.Quality.HQ,
    PlayerEnums.Quality.SQ,
    PlayerEnums.Quality.SQ_SR,
    PlayerEnums.Quality.DOLBY,
    PlayerEnums.Quality.HIRES,
    PlayerEnums.Quality.EXCELLENT,
    PlayerEnums.Quality.GALAXY,
    PlayerEnums.Quality.MASTER_TAPE,
    PlayerEnums.Quality.MASTER_SR,
    PlayerEnums.Quality.DTSC,
    PlayerEnums.Quality.DTSX
  ]

  constructor() {
    this.preferSongQuality = OpenApiSdk.playerApi!.getPreferSongQuality();
  }
  /**
   * 注册播放器事件监听和进度回调
   */
  init(): void {
    if (this.isInitialized) {
      return
    }
    this.isInitialized = true
    this.initFromPlayerApi()
    this.registerEvents()
  }
  /**
   * 从 SDK 初始化当前状态快照
   */
  private initFromPlayerApi(): void {
    this.currentSong = OpenApiSdk.playerApi?.getCurrentSongInfo() ?? null
    this.currentMode = OpenApiSdk.playerApi?.getPlayMode() ?? PlayerEnums.Mode.ORDER
    this.duration = this.currentSong?.durationMs() ?? 0
    this.actualDuration = OpenApiSdk.playerApi?.getDuration() ?? 0
    this.isRadio = OpenApiSdk.playerApi?.isRadio() ?? false
    this.playSpeed = 1.0
    this.refreshFavoriteState()
    this.refreshCurrentQuality()
    MLog.i(TAG, `init: song=${this.currentSong?.getSongName()}, mode=${this.currentMode}`)
  }
  /**
   * 注册播放器事件监听和进度回调
   */
  private registerEvents(): void {
    OpenApiSdk.playerApi?.registerEventListener(this)
    OpenApiSdk.playerApi?.registerProgressChangedListener(this)
    OpenApiSdk.playerApi?.addOnPlayerErrorListener(this)
  }
  /**
   * 注销所有事件监听
   * 在页面 aboutToDisappear 时调用，防止内存泄漏
   */
  unregisterEvents(): void {
    OpenApiSdk.playerApi?.unregisterEventListener(this)
    OpenApiSdk.playerApi?.unregisterProgressChangedListener(this)
    OpenApiSdk.playerApi?.removeOnPlayerErrorListener(this)
  }

  onEvent(event: PlayerEvent.Event, arg: Map<PlayerEvent.Key, Object>): void {
    switch (event) {
      case PlayerEvent.Event.API_EVENT_PLAY_SONG_CHANGED: {
        const curr = arg.get(PlayerEvent.Key.API_EVENT_KEY_PLAY_SONG) as ISongInfo | undefined
        if (curr !== undefined) {
          this.currentSong = curr
          this.curSentence = ''
          this.seekPosition = -1
          this.refreshFavoriteState()
          this.refreshCurrentQuality()
          this.notifyIfTryPlay(curr)
          MLog.d(TAG, `song changed: ${curr.getSongName()}`)
        }
        break
      }

      case PlayerEvent.Event.API_EVENT_PLAY_STATE_CHANGED: {
        const state = arg.get(PlayerEvent.Key.API_EVENT_KEY_PLAY_STATE) as number | undefined
        if (state !== undefined) {
          this.currentState = state
          this.updatePlayStateText(state)
          MLog.d(TAG, `state changed: ${state}`)
        }
        break
      }

      case PlayerEvent.Event.API_EVENT_PLAY_LIST_CHANGED: {
        const playList = OpenApiSdk.playerApi!.getPlayList() ?? [];
        this.songList = playList;
        this.selectedList = new Array<boolean>(playList.length).fill(false);
        this.currentSong = OpenApiSdk.playerApi!.getCurrentSongInfo();
        this.checkLaunchAutoPlay();
        break;
      }

      case PlayerEvent.Event.API_EVENT_PLAY_MODE_CHANGED: {
        const mode = arg.get(PlayerEvent.Key.API_EVENT_KEY_PLAY_MODE) as number | undefined
        if (mode !== undefined) {
          this.currentMode = mode
          MLog.d(TAG, `mode changed: ${mode}`)
        }
        break
      }

      case PlayerEvent.Event.API_EVENT_CURRENT_PLAY_SONG_QUALITY_CHANGE: {
        const q = arg.get(PlayerEvent.Key.API_EVENT_KEY_QUALITY) as number | undefined
        if (q !== undefined) {
          this.currentQuality = q
          MLog.d(TAG, `quality changed: ${q}`)
        }
        break
      }

      case PlayerEvent.Event.API_EVENT_PLAY_LIST_CHANGED: {
        this.isRadio = OpenApiSdk.playerApi?.isRadio() ?? false
        break
      }

      case PlayerEvent.Event.API_EVENT_PLAY_SPEED_CHANGED: {
        const speed = arg.get(PlayerEvent.Key.API_EVENT_KEY_PLAY_SPEED) as number | undefined
        if (speed !== undefined) {
          this.playSpeed = speed
        }
        break
      }

      case PlayerEvent.Event.API_EVENT_PLAY_START: {
        this.hasStartPlay = true;
        break
      }

      case PlayerEvent.Event.API_EVENT_RESTORE_PLAY_LIST_END: {
        const size = arg.get(PlayerEvent.Key.API_EVENT_KEY_PLAY_LIST_SIZE) as number | undefined
        if (size && size > 0) {
          this.pendingStartPlay = SPUtils.getBool("launch_auto_play", true);
        } else {
          this.pendingStartPlay = false;
        }
        break
      }

      case PlayerEvent.Event.API_EVENT_PREFER_SONG_QUALITY_CHANGE: {
        const quality = arg.get(PlayerEvent.Key.API_EVENT_KEY_QUALITY) as PlayerEnums.Quality;
        MLog.i(TAG, `[handlePlayEvent->PREFER_SONG_QUALITY_CHANGE] ${quality}`);
        this.preferSongQuality = quality;
        break;
      }

      default:
        break
    }
  }

  progressChanged(curPlayTime: number, totalTime: number): void {
    if (this.isSeekBarTracking) {
      return
    }
    const song = this.currentSong
    if (song !== null) {
      this.playPosition = curPlayTime
      this.actualDuration = totalTime
      this.duration = song.durationMs()
      if (this.seekPosition >= 0 && this.seekPosition <= this.playPosition) {
        this.seekPosition = -1
      }
    } else {
      this.playPosition = 0
      this.duration = 0
      this.actualDuration = 0
    }
  }

  onPlayerError(code: number, subCode: number): void {
    MLog.i(TAG, `onEvent: current error ${code}`);
    if (!this.currentSong?.canPlay()) {
      if (code === PlayError.PLAY_ERR_CANNOT_PLAY) {
        ToastUtil.show(`${code},${this.currentSong?.getUnplayableMsg()}`);
      } else {
        ToastUtil.show(`${code},${InsightUtil.convertErrorCode(code)}`);
      }
    } else {
      const playError = PlayErrorUtils.convertToPlayErrorData(code, subCode);
      ToastUtil.show(`code=${playError.code},msg=${playError.errorMsg},${playError.suggestion}`);
    }
    this.playStateText = `播放状态: 错误(code=${code},msg=${this.currentSong?.getUnplayableMsg()})`
    this.resetPlayProgress();
  }

  // === 状态 getter ===

  /** 是否正在播放 */
  get isPlaying(): boolean {
    return this.currentState === PlayStatus.PLAYING
  }

  /** 是否暂停 */
  get isPaused(): boolean {
    return this.currentState === PlayStatus.PAUSE
  }

  /** 当前进度比例（0~1） */
  get progressRatio(): number {
    if (this.duration <= 0) {
      return 0
    }
    return this.playPosition / this.duration
  }

  /** 歌曲名 */
  get songName(): string {
    return this.currentSong?.getSongName() ?? '未知'
  }

  /** 歌手名 */
  get singerName(): string {
    return this.currentSong?.getSingerName() ?? '未知'
  }

  /** 封面 URL（大图优先） */
  get coverUrl(): string {
    const url = this.currentSong?.getAlbumPicUrlBySize?.('1500') ?? ''
    return url.length > 0 ? url : (this.currentSong?.bigCoverUrl() ?? '')
  }

  /** 是否有 MV */
  get hasMvVid(): boolean {
    const mvVid = this.currentSong?.getMvVid()
    return mvVid !== null && mvVid !== undefined && (mvVid as string).length > 0
  }

  /** 播放模式图标文本 */
  get modeText(): string {
    switch (this.currentMode) {
      case PlayerEnums.Mode.ORDER:
        return '列表循环'
      case PlayerEnums.Mode.SINGLE_CYCLE:
        return '单曲循环'
      case PlayerEnums.Mode.RANDOM:
        return '随机播放'
      case PlayerEnums.Mode.ONE_NOT_REPEAT:
        return '单曲一次'
      default:
        return `模式${this.currentMode}`
    }
  }

  /** 播放模式图标资源 */
  get modeIcon(): Resource {
    switch (this.currentMode) {
      case PlayerEnums.Mode.ORDER:
        return $r('app.media.ic_play_mode_normal')
      case PlayerEnums.Mode.SINGLE_CYCLE:
        return $r('app.media.ic_play_mode_single')
      case PlayerEnums.Mode.RANDOM:
        return $r('app.media.ic_play_mode_random')
      case PlayerEnums.Mode.ONE_NOT_REPEAT:
        return $r('app.media.ic_play_mode_single_not_repeat')
      default:
        return $r('app.media.ic_play_mode_normal')
    }
  }

  /** 品质文本 */
  getQualityText(quality: number | null): string {
    switch (quality) {
      case PlayerEnums.Quality.STANDARD:
        return '标准'
      case PlayerEnums.Quality.HQ:
        return 'HQ'
      case PlayerEnums.Quality.SQ:
        return 'SQ'
      case PlayerEnums.Quality.SQ_SR:
        return 'SQ省流版'
      case PlayerEnums.Quality.HIRES:
        return 'HiRes'
      case PlayerEnums.Quality.DOLBY:
        return '杜比'
      case PlayerEnums.Quality.GALAXY:
        return '臻品'
      case PlayerEnums.Quality.EXCELLENT:
        return '臻品2.0'
      case PlayerEnums.Quality.MASTER_SR:
        return '臻品母带省流版'
      case PlayerEnums.Quality.MASTER_TAPE:
        return '母带'
      case PlayerEnums.Quality.WANOS:
        return 'Wanos'
      case PlayerEnums.Quality.VINYL:
        return '黑胶'
      case PlayerEnums.Quality.DTSC:
        return 'DTSC'
      case PlayerEnums.Quality.DTSX:
        return 'DTSX'
      default:
        return '品质'
    }
  }

  /**
   * 获取当前歌曲的可用音质列表
   * 根据 ISongInfo 的 hasQuality* 方法判断歌曲是否支持各音质
   */
  get qualityList(): QualityItem[] {
    const song = this.currentSong
    if (song === null) {
      return []
    }
    const curQ = this.currentQuality

    // WANOS / VINYL 特殊音质覆盖逻辑
    let realQuality: number | null = null
    let qualityOrderString: string[] = []

    if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.WANOS)) {
      qualityOrderString = ['WANOS']
      realQuality = PlayerEnums.Quality.WANOS
    } else if (OpenApiSdk.playerApi?.getSongHasQuality(song, PlayerEnums.Quality.VINYL)) {
      qualityOrderString = ['黑胶']
      realQuality = PlayerEnums.Quality.VINYL
    }

    const items: QualityItem[] = []

    if (realQuality !== null) {
      // WANOS / VINYL 单项列表
      const name = this.buildQualityItemName(song, realQuality, qualityOrderString[0])
      items.push(new QualityItem(realQuality, name, true, curQ === realQuality))
    } else {
      // 正常音质列表
      for (const q of this.qualityOrder) {
        const hasQ = this.songHasQuality(song, q)
        const isCurrent = curQ !== null && curQ === q
        const name = this.buildQualityItemName(song, q, this.qualityName(q))
        items.push(new QualityItem(q, name, hasQ, isCurrent))
      }
    }
    return items
  }

  items: ISoundEffectItem[] = [];
  getSoundEffect(): void {
    OpenApiSdk.openApi?.commonConfigApi.fetchSoundEffectConfig().then((res) => {
      if (res.isSuccess() && res.data && res.data.length > 0) {
        this.items = res.data;
        MLog.d(TAG, `getSoundEffect success: ${JSON.stringify(res.data)}`)
      }
    });
  }

  // === 播放控制方法 ===

  /** 切换播放/暂停 */
  playPause(): void {
    if (this.isPlaying) {
      OpenApiSdk.playerApi?.pause()
    } else {
      OpenApiSdk.playerApi?.play()
    }
  }

  /** 下一曲 */
  next(): void {
    OpenApiSdk.playerApi?.next()
  }

  /** 上一曲 */
  prev(): void {
    OpenApiSdk.playerApi?.prev()
  }
  /** Seek到指定位置并发起播放 */
  seekTo(positionMs: number): void {
    this.seekPosition = positionMs
    OpenApiSdk.playerApi?.seekToPlay(positionMs)
  }

  /** 循环切换播放模式 */
  cyclePlayMode(): void {
    const curIdx = this.modeOrder.indexOf(this.currentMode)
    let nextMode: PlayerEnums.Mode
    // 电台模式：只在「列表循环」和「单曲一次」之间切换
    if (this.isRadio) {
      nextMode = curIdx === 0 ? PlayerEnums.Mode.ONE_NOT_REPEAT : PlayerEnums.Mode.ORDER
    } else {
      // 普通模式：按 modeOrder 顺序循环切换
      const nextIdx = curIdx >= 0 ? (curIdx + 1) % this.modeOrder.length : 0
      nextMode = this.modeOrder[nextIdx]
    }
    OpenApiSdk.playerApi?.setPlayMode(nextMode)
  }

  /**
   * 切换音质
   * @param quality 目标音质
   * @returns true 表示已发起切换请求（UI 可关闭弹窗），false 表示参数不合法无需操作
   */
  changeQuality(quality: number): boolean {
    if (quality === this.currentQuality) {
      return false
    }
    const song = this.currentSong
    if (song === null) {
      ToastUtil.show('当前无歌曲')
      return false
    }
    if (!this.songHasQuality(song, quality)) {
      ToastUtil.show('该歌曲不支持此音质')
      return false
    }
    OpenApiSdk.playerApi?.setCurrentPlaySongQuality(quality).then((ret: number) => {
      if (ret === 0) {
        MLog.i(TAG, `changeQuality success: quality=${quality}`)
        ToastUtil.show('切换音质成功')
      } else {
        MLog.w(TAG, `changeQuality failed: ret=${ret}`)
        ToastUtil.show(this.convertErrorCode(ret))
      }
    }).catch((err: Error) => {
      MLog.e(TAG, `changeQuality error: ${err.message}`)
      ToastUtil.show('切换异常')
    })
    return true
  }

  /**
   * 切换收藏状态
   * 根据 DemoGlobal.isPersonalAssets 判断走资产模块还是直接 API
   */
  toggleFavorite(): void {
    if (this.currentSong === null) {
      return
    }
    const song = this.currentSong
    const isAdd = !this.isFavorite
    const enablePersonalAssets = DemoGlobal.isPersonalAssets;

    if (enablePersonalAssets) {
      // 资产模块路径
      OpenApiSdk.personalAssetsApi?.setSongCollected(song, isAdd).then((result) => {
        if (result) {
          this.isFavorite = isAdd
          MLog.i(TAG, `toggleFavorite(assets) success: isAdd=${isAdd}`)
        } else {
          MLog.w(TAG, `toggleFavorite(assets) failed`)
        }
      }).catch((err: Error) => {
        MLog.e(TAG, `toggleFavorite(assets) error: ${err.message}`)
      })
    } else {
      // 非资产模块路径：通过 folderApi.operSongOfMyLikeSongList 操作「我喜欢」歌单
      OpenApiSdk.openApi?.folderApi.operSongOfMyLikeSongList(
        isAdd,
        [song.getSongId()],
        [song.getSongMid()]
      ).then((resp) => {
        if (resp.isSuccess()) {
          this.isFavorite = isAdd
          MLog.i(TAG, `toggleFavorite(api) success: isAdd=${isAdd}`)
        } else {
          MLog.w(TAG, `toggleFavorite(api) failed: ret=${resp.ret}, msg=${resp.errorMsg}`)
        }
      }).catch((err: Error) => {
        MLog.e(TAG, `toggleFavorite(api) error: ${err.message}`)
      })
    }
  }

  /** 格式化时间（ms -> mm:ss） */
  formatTime(ms: number): string {
    if (ms <= 0 || !Number.isFinite(ms)) {
      return '00:00'
    }
    const totalSec = Math.floor(ms / 1000)
    const min = Math.floor(totalSec / 60)
    const sec = totalSec % 60
    const minStr = min < 10 ? `0${min}` : `${min}`
    const secStr = sec < 10 ? `0${sec}` : `${sec}`
    return `${minStr}:${secStr}`
  }

  /** 刷新收藏状态 */
  private refreshFavoriteState(): void {
    if (this.currentSong === null) {
      this.isFavorite = false
      return
    }
    const enablePersonalAssets = DemoGlobal.isPersonalAssets;
    if (enablePersonalAssets) {
      // 资产模块路径：通过 personalAssetsApi 判断
      this.isFavorite = OpenApiSdk.personalAssetsApi?.isSongCollected(this.currentSong) ?? false
    } else {
      // 非资产模块路径：通过 getHot() 判断
      const hot = this.currentSong.getHot()
      this.isFavorite = hot !== null && hot !== undefined && hot === 1
    }
  }
  /**
   * 如果是试听歌曲且未提示过，则弹“正在播放试听片段”Toast
   * 以“pageSessionId|songId”作为去重 key，同一会话内同一首试听歌曲只弹一次
   */
  private notifyIfTryPlay(song: ISongInfo): void {
    if (!song.canOnlyPlayTry()) {
      return
    }
    const songId = song.getSongId()
    if (!songId) {
      return
    }
    const key = `${this.pageSessionId}|${songId}`
    if (key === this.notifiedTryPlayKey) {
      return
    }
    this.notifiedTryPlayKey = key
    ToastUtil.show('正在播放试听片段')
  }
  /**
   * 进入播放页时调用，重置会话内试听提示去重记录
   * 使本页内切到的第一首试听歌曲一定会提示一次
   */
  onPageEnter(): void {
    this.pageSessionId++
    this.notifiedTryPlayKey = ''
    if (this.currentSong !== null) {
      this.notifyIfTryPlay(this.currentSong)
    }
    // 每次进入播放页时强制刷新收藏状态，
    // 因为收藏状态可能在外部（如 SongListPage）被改变，
    // 而 init() 由于 isInitialized 守卫不会重复执行 refreshFavoriteState()
    this.refreshFavoriteState()
  }

  /** 刷新当前音质（异步获取） */
  private refreshCurrentQuality(): void {
    OpenApiSdk.playerApi?.getCurrentPlaySongQuality().then((q: number | null) => {
      if (q !== null && q !== undefined) {
        this.currentQuality = q
        MLog.i(TAG, `refreshCurrentQuality: ${q}`)
      }
    }).catch((err: Error) => {
      MLog.e(TAG, `refreshCurrentQuality error: ${err.message}`)
    })
  }
  /**
   * 判断歌曲是否支持指定音质
   * 优先使用 SDK 的 getSongHasQuality，若不可用则降级为 ISongInfo 的 hasQuality* 方法
   */
  private songHasQuality(song: ISongInfo, quality: number): boolean {
    // 优先使用 SDK 接口
    const sdkResult = OpenApiSdk.playerApi?.getSongHasQuality(song, quality)
    if (sdkResult !== null && sdkResult !== undefined) {
      return sdkResult
    }
    // 降级：使用 ISongInfo 本地方法
    switch (quality) {
      case PlayerEnums.Quality.STANDARD:
        return song.hasQualityStandard()
      case PlayerEnums.Quality.HQ:
        return song.hasQualityHQ()
      case PlayerEnums.Quality.SQ:
        return song.hasQualitySQ()
      case PlayerEnums.Quality.HIRES:
        return song.hasQualityHiRes()
      case PlayerEnums.Quality.DOLBY:
        return song.hasQualityDolby()
      case PlayerEnums.Quality.GALAXY:
        return song.hasQualityGalaxy()
      case PlayerEnums.Quality.EXCELLENT:
        return song.hasQualityExcellent()
      case PlayerEnums.Quality.MASTER_SR:
        return song.hasQualityMasterSR()
      case PlayerEnums.Quality.MASTER_TAPE:
        return song.hasQualityMasterTape()
      case PlayerEnums.Quality.SQ_SR:
      case PlayerEnums.Quality.WANOS:
      case PlayerEnums.Quality.VINYL:
      case PlayerEnums.Quality.DTSC:
      case PlayerEnums.Quality.DTSX:
        return (song.getSongSize(quality) ?? 0) > 0
      default:
        return false
    }
  }

  /** 音质枚举值 -> 显示名称 */
  private qualityName(quality: number): string {
    switch (quality) {
      case PlayerEnums.Quality.STANDARD:
        return '标准'
      case PlayerEnums.Quality.HQ:
        return '高品质'
      case PlayerEnums.Quality.SQ:
        return 'SQ'
      case PlayerEnums.Quality.SQ_SR:
        return 'SQ省流版'
      case PlayerEnums.Quality.HIRES:
        return 'Hires'
      case PlayerEnums.Quality.DOLBY:
        return 'DOLBY'
      case PlayerEnums.Quality.EXCELLENT:
        return '臻品2.0'
      case PlayerEnums.Quality.GALAXY:
        return '臻品全景声'
      case PlayerEnums.Quality.MASTER_TAPE:
        return '臻品母带'
      case PlayerEnums.Quality.MASTER_SR:
        return '臻品母带省流版'
      case PlayerEnums.Quality.WANOS:
        return 'Wanos'
      case PlayerEnums.Quality.VINYL:
        return '黑胶'
      case PlayerEnums.Quality.DTSC:
        return 'DTSC音质'
      case PlayerEnums.Quality.DTSX:
        return 'DTSX音质'
      default:
        return `音质${quality}`
    }
  }
  /**
   * 根据播放状态更新状态文本
   */
  private updatePlayStateText(state: number): void {
    const radioSuffix = this.isRadio ? '(个性电台)' : ''
    switch (state) {
      case PlayStatus.BUFFERING:
        this.playStateText = `缓冲中${radioSuffix}`
        break
      case PlayStatus.IDLE:
        this.playStateText = `Idle${radioSuffix}`
        break
      case PlayStatus.PAUSE:
        this.playStateText = `已暂停${radioSuffix}`
        break
      case PlayStatus.PLAYING:
        this.playStateText = `播放中${radioSuffix}`
        break
      case PlayStatus.STOP:
        this.playStateText = `停止${radioSuffix}`
        break
      case PlayStatus.PREPARED:
        this.playStateText = `已准备${radioSuffix}`
        break
      default:
        this.playStateText = `播放状态: ${state}${radioSuffix}`
    }
  }

  /** 清理资源 */
  onDestroy(): void {
    this.unregisterEvents()
  }

  private checkLaunchAutoPlay() {
    if (this.pendingStartPlay && !this.hasStartPlay) {
      this.pendingStartPlay = false;
      MLog.d(TAG, "checkLaunchAutoPlay: launch auto play");
      OpenApiSdk.playerApi?.play(0);
    }
  }

  private resetPlayProgress() {
    this.seekPosition = -1
    this.playPosition= 0
  }

  private convertErrorCode(code: number): string {
    switch (code) {
      case PlayError.PLAY_ERR_NONE:
        return '切换歌曲品质成功';
      case PlayError.PLAY_ERR_DEVICE_NO_SUPPORT:
        return '设备不支持';
      case PlayError.PLAY_ERR_NO_QUALITY:
        return '没有对应音质';
      case PlayError.PLAY_ERR_PLAYER_ERROR:
        return '播放器异常';
      case PlayError.PLAY_ERR_NEED_VIP:
        return '需要VIP';
      case PlayError.PLAY_ERR_CANNOT_PLAY:
        return '歌曲不能播放';
      case PlayError.PLAY_ERR_NONETWORK:
        return '无网络';
      case PlayError.PLAY_ERR_UNSUPPORT:
      case PlayError.PLAY_ERR_CAN_NOT_SET_CURRENT_QUALITY:
        return '不支持切换此音质';
      case PlayError.PLAY_ERR_NEED_SUPER_VIP:
        return '需要超级会员';
      case PlayError.PLAY_ERR_NEED_PAY_ALBUM:
        return '需要专辑付费';
      case PlayError.PLAY_ERR_NEED_PAY_TRACK:
        return '需要单曲付费';
      case PlayError.PLAY_ERR_NEED_VIP_LONG_AUDIO:
        return '需要听书会员';
      default:
        return `ret=$code,${InsightUtil.convertErrorCode(code)}`;
    }
  }
  /**
   * 构建音质条目显示名称
   * 格式：音质名 + 文件大小 + 权限标签 + 试听标签
   */
  private buildQualityItemName(song: ISongInfo, quality: number, baseName: string): string {
    const qualitySize = OpenApiSdk.playerApi?.getSongQualitySize(song, quality) ?? 0
    const accessStr = this.getFormatAccessLabel(song, quality)
    const tryPlayLabel = OpenApiSdk.playerApi?.canTryOpenQuality(song, quality) ? '-可试听' : ''

    // 特殊处理：EXCELLENT / WANOS 不支持下载时的提示
    if (quality === PlayerEnums.Quality.EXCELLENT) {
      return `臻品音质2.0${this.formatSize(qualitySize)}${accessStr}${tryPlayLabel}`
    }
    if (quality === PlayerEnums.Quality.WANOS) {
      return `WANOS ${accessStr}`
    }

    return `${baseName}${this.formatSize(qualitySize)}${accessStr}${tryPlayLabel}`
  }

  /**
   * 格式化文件大小
   */
  private formatSize(sizeByte: number): string {
    if (sizeByte <= 0) {
      return '(0MB)'
    }
    const size = sizeByte / (1024 * 1024)
    const rounded = Math.round(size * 100) / 100
    return `(${rounded.toFixed(2)}MB)`
  }

  /**
   * 获取权限标签
   */
  private getFormatAccessLabel(song: ISongInfo, quality: number): string {
    const access = OpenApiSdk.playerApi?.getAccessByQuality(song, quality)
    if (access === null || access === undefined) {
      return ''
    }
    const sb: string[] = []
    if (access.vip) {
      sb.push('vip')
    }
    if (access.iotVip) {
      sb.push('iotVip')
    }
    if (!access.vip && access.hugeVip) {
      sb.push('SuperVip')
    }
    if (access.vipLongAudio) {
      sb.push('vipAudio')
    }
    if (access.payTrack) {
      sb.push('payTrack')
    }
    if (access.payAlbum) {
      sb.push('payAlbum')
    }
    if (access.unionVip) {
      sb.push('unionVip')
    }
    if (sb.length > 0) {
      return `[${sb.join('•')}]`
    }
    return ''
  }
}
