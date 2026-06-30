import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import {
  IEdgeMediaPlayer,
  IEdgeVideoPlayListener,
  VideoPlayError,
  VideoPlayState,
  MediaQuality,
  BlockReason,
  QualityBlockReason,
  OperateMediaCollectCmd,
  IMediaResDetail
} from '@qqmusic/opisdk-entity'
import { DemoGlobal } from '../utils/DemoGlobal'
import { ToastUtil } from '../utils/ToastUtil'

const TAG = 'MVPlayerViewModel'

/**
 * MV 播放器 ViewModel
 * 对应 Android 的 PlayerViewModel，管理 MV 播放相关的数据和状态
 */
@ObservedV2
export class MVPlayerViewModel {
  // 播放器实例
  player: IEdgeMediaPlayer | null = null
  // 当前播放的媒体资源详情
  @Trace currentData: IMediaResDetail | null = null

  // 播放状态
  @Trace isPlaying: boolean = false
  @Trace isMute: boolean = false
  @Trace isLoop: boolean = true
  @Trace currentQuality: MediaQuality = MediaQuality.SQ
  @Trace playDuration: number = 0
  @Trace duration: number = 0
  @Trace isLoading: boolean = false
  @Trace loadingText: string = '加载中'
  @Trace showBuyQR: boolean = false
  @Trace buyQRUrl: string = ''

  // 视频宽高
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;
  @Trace videoMarginHorizontal:number = 0;
  @Trace videoMarginVertical:number = 0;

  // 是否正在加载
  @Trace isLoadingRecommend: boolean = false
  @Trace isLoadingAreaDetail: boolean = false
  @Trace isLoadingContent: boolean = false
  /** 视频宽高 */
  @Trace videoSize: [number, number] = [0, 0];
  @Trace enablePersonalAssets: boolean = DemoGlobal.isPersonalAssets;

  // 播放事件回调
  private playEventListener: IEdgeVideoPlayListener = {
    onEvent: (state: VideoPlayState, data?: Map<string, Object>) => {
      this.handlePlayState(state, data)
    },
    onVideoSizeChanged: (width?: number, height?: number) => {
      MLog.d(TAG, `onVideoSizeChanged width=${width} height=${height}`)
      this.videoSize[0] = width ?? 0;
      this.videoSize[1] = height ?? 0;
      this.updateSurfaceSize();
    },
    onError: (error: VideoPlayError, data?: Object) => {
      this.handlePlayError(error, data)
    }
  }

  constructor() {
    this.player = OpenApiSdk.videoPlayerApi?.getMediaPlayer('MVPlayer') ?? null
    this.player?.setPlayEventListener(this.playEventListener)
    // 默认设置循环播放
    this.player?.setLoop(true)
  }

  /**
   * 根据 vid 更新媒体信息
   */
  async updateMediaById(vid: string): Promise<void> {
    if (!vid || vid.length === 0) {
      return
    }
    try {
      const resp = await OpenApiSdk.openApi?.edgeMediaApi?.getMediaInfo([vid])
      if (resp && resp.isSuccess() && resp.data && resp.data.length > 0) {
        this.updateMedia(resp.data[0])
      } else {
        MLog.w(TAG, `updateMediaById failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `updateMediaById error: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 设置媒体资源
   */
  updateMedia(mediaResDetail: IMediaResDetail | null): void {
    this.currentData = mediaResDetail
    MLog.i(TAG, `updateMedia success, mediaResDetail: ${JSON.stringify(mediaResDetail)}`);
    if (mediaResDetail) {
      this.player?.setMediaRes(mediaResDetail)
      const playTime = mediaResDetail.getPlayTime()
      this.duration = playTime ? parseInt(playTime) * 1000 : 0
    }
  }

  // === 播放控制方法 ===

  /** 切换播放/暂停 */
  playPause(): void {
    if (this.player?.isPlaying()) {
      this.player?.pause()
    } else {
      this.player?.play()
    }
  }

  /** 设置静音 */
  toggleMute(): void {
    const isMute = this.player?.isMute() ?? false
    this.player?.setMute(!isMute)
    this.isMute = !isMute
  }

  /** 设置循环 */
  toggleLoop(): void {
    const isLoop = this.player?.getLoopStatus() ?? true
    this.player?.setLoop(!isLoop)
    this.isLoop = !isLoop
  }

  /** Seek */
  seekTo(timeMs: number): void {
    this.player?.seekTo(timeMs)
  }

  /** 设置品质 */
  setQuality(quality: MediaQuality): void {
    if (this.player) {
      this.player.setExceptMvQuality(quality)
      this.currentQuality = this.player.getCurrentQuality()
    }
  }

  /** 收藏/取消收藏 */
  async toggleCollect(): Promise<void> {
    const mediaRes = this.player?.getCurrentMediaRes()
    if (!mediaRes) {
      return
    }
    const cmd = mediaRes.getIsCollect() === 1 ? OperateMediaCollectCmd.UN_COLLECT : OperateMediaCollectCmd.COLLECT

    if (this.enablePersonalAssets) {
      const resp = await OpenApiSdk.personalAssetsApi?.videoFavApi.setCollectOrCancel(cmd === 1 ? false : true, mediaRes);
      if (resp) {
        // 刷新媒体信息
        const vid = mediaRes.getVid()
        if (vid) {
          const infoResp = await OpenApiSdk.openApi?.edgeMediaApi?.getMediaInfo([vid])
          if (infoResp && infoResp.isSuccess() && infoResp.data && infoResp.data.length > 0) {
            const newMediaRes = infoResp.data[0]
            this.currentData = newMediaRes
            // 同步更新播放器内部的媒体资源，确保下次 getCurrentMediaRes 返回最新数据
            this.player?.setMediaRes(newMediaRes)
          }
        }
      }
    } else {
      try {
        const resp = await OpenApiSdk.openApi?.edgeMediaApi?.operateMediaCollectStatus(
          [mediaRes], cmd
        )
        if (resp && resp.isSuccess()) {
          // 刷新媒体信息
          const vid = mediaRes.getVid()
          if (vid) {
            const infoResp = await OpenApiSdk.openApi?.edgeMediaApi?.getMediaInfo([vid])
            if (infoResp && infoResp.isSuccess() && infoResp.data && infoResp.data.length > 0) {
              const newMediaRes = infoResp.data[0]
              this.currentData = newMediaRes
              // 同步更新播放器内部的媒体资源，确保下次 getCurrentMediaRes 返回最新数据
              this.player?.setMediaRes(newMediaRes)
            }
          }
        }
      } catch (e) {
        MLog.e(TAG, `toggleCollect error: ${JSON.stringify(e)}`)
      }
    }

  }

  /** 获取当前播放时间 */
  getPlayDuration(): number {
    return this.player?.getPlayDuration() ?? 0
  }

  // === 内部方法 ===

  /**
   * 处理播放状态变化
   */
  private handlePlayState(state: VideoPlayState, data?: Map<string, Object>): void {
    MLog.d(TAG, `handlePlayState: ${state}`)
    switch (state) {
      case VideoPlayState.PREPARED:
        this.isLoading = false
        this.loadingText = ''
        this.player?.play()
        this.isPlaying = true
        // 更新时长
        const d = this.player?.getDuration()
        if (d && d > 0) {
          this.duration = d
        }
        break

      case VideoPlayState.STARTED:
        this.isPlaying = true
        this.isLoading = false
        break

      case VideoPlayState.ACTIVE_PAUSED:
      case VideoPlayState.PASSIVE_PAUSED:
      case VideoPlayState.STOPPED:
        this.isPlaying = false
        break

      case VideoPlayState.BUFFERING_START:
        this.isLoading = true
        this.loadingText = '加载中'
        break

      case VideoPlayState.BUFFERING_END:
        this.isLoading = false
        break

      case VideoPlayState.PLAYBACK_COMPLETED:
        this.isPlaying = false
        break

      case VideoPlayState.ERROR:
        this.isLoading = false
        break

      case VideoPlayState.SEEK_COMPLETED:
        MLog.d(TAG, `seek completed, current time: ${this.getPlayDuration()}`)
        break

      default:
        break
    }
  }

  /**
   * 处理播放错误
   */
  private handlePlayError(error: VideoPlayError, data?: Object): void {
    MLog.e(TAG, `handlePlayError: ${error}, data: ${JSON.stringify(data)}`)
    this.showBuyQR = false
    this.buyQRUrl = ''

    switch (error) {
      case VideoPlayError.NO_QUALITY_REQUIRED:
        ToastUtil.show('该媒体没有要求的品质');
        break
      case VideoPlayError.DEVICE_NOT_SUPPORT_THIS_QUALITY:
        ToastUtil.show('设备不支持该品质播放');
        break
      case VideoPlayError.MEDIA_HAVE_NOT_QUALITY_TO_PLAY_FOR_USER:
        ToastUtil.show('当前用户身份下无可播放的品质');
        break
      case VideoPlayError.CAN_NOT_PLAY:
        const reason = data as BlockReason
        switch (reason) {
          case BlockReason.VIDEO_PURCHASE_BLOCK:
            this.showBuyQR = true
            this.buyQRUrl = this.currentData?.getBuyQRUrl() ?? ''
            ToastUtil.show('需要购买');
            break
          case BlockReason.HUGE_VIP_MEMBER_BLOCK:
            ToastUtil.show('需要超会');
            break
          case BlockReason.SUPER_GREEN_VIP_MEMBER_BLOCK:
            ToastUtil.show('需要豪华绿钻');
            break
          case BlockReason.NO_COPYRIGHT:
            ToastUtil.show('无版权');
            break
          default:
            ToastUtil.show(`${reason}`);
            break
        }
        break
      case VideoPlayError.MEDIA_DOWNGRADE_PLAY:
        this.currentQuality = this.player?.getCurrentQuality() ?? MediaQuality.LQ
        ToastUtil.show('降级播放');
        break
      case VideoPlayError.MEDIA_RES_HAS_EXPIRED:
        ToastUtil.show('资源已经过期，需要刷新，请刷新界面');
        break
      case VideoPlayError.NO_PERMISSION_TO_PLAY_QUALITY:
        ToastUtil.show(this.buildPermissionErrorMsg(data));
        break
      default:
        ToastUtil.show('');
        break
    }
  }

  /**
   * 构建权限错误提示
   */
  private buildPermissionErrorMsg(data?: Object): string {
    const reasons = data as QualityBlockReason[]
    if (!reasons || reasons.length === 0) {
      return '无权限播放'
    }
    let msg = '需要 '
    const parts: string[] = []
    for (const reason of reasons) {
      switch (reason) {
        case QualityBlockReason.NEED_SUPER_VIP:
          parts.push('超会')
          break
        case QualityBlockReason.NEED_PAY_FOR_MEDIA:
          this.showBuyQR = true
          this.buyQRUrl = this.currentData?.getBuyQRUrl() ?? ''
          parts.push('手机端购买')
          break
        case QualityBlockReason.NEED_IOT_VIP:
          parts.push('IOT独立会员')
          break
        case QualityBlockReason.NO_PERMISSION_FOR_UER_OR_DEVICE:
          return '当前用户无权限播放'
        case QualityBlockReason.NEED_GREEN_VIP:
          parts.push('绿钻')
          break
        case QualityBlockReason.NEED_SUPER_GREEN_VIP:
          parts.push('豪华绿钻')
          break
      }
    }
    msg += parts.join(' 或 ')
    msg += ' 才能播放'
    return msg
  }

  /**
   * 获取品质显示名称
   */
  static getQualityName(quality: MediaQuality): string {
    switch (quality) {
      case MediaQuality.LQ: return '标清 360P'
      case MediaQuality.HQ: return '高清 480P'
      case MediaQuality.SQ: return '超清 720P'
      case MediaQuality.BR_1080: return '蓝光 1080P'
      case MediaQuality.HIGH_1080: return '1080_高刷'
      case MediaQuality.NORMAL_4K: return '4K 超清'
      case MediaQuality.EXCELLENT: return '臻品视听'
      case MediaQuality.DOLBY_4K: return '杜比视界'
      default: return '未知'
    }
  }

  /**
   * 格式化时间（秒 -> mm:ss）
   */
  static formatTime(seconds: number): string {
    if (seconds <= 0 || !Number.isFinite(seconds)) {
      return '00:00'
    }
    const min = Math.floor(seconds / 60)
    const sec = Math.floor(seconds % 60)
    const minStr = min < 10 ? `0${min}` : `${min}`
    const secStr = sec < 10 ? `0${sec}` : `${sec}`
    return `${minStr}:${secStr}`
  }

  /**
   * 格式化毫秒时间（ms -> mm:ss）
   */
  static formatTimeMs(ms: number): string {
    return MVPlayerViewModel.formatTime(Math.floor(ms / 1000))
  }

  /**
   * 销毁资源
   */
  destroy(): void {
    this.player?.destroy()
    this.player = null
    this.currentData = null
  }

  setSurfaceSize(width:number, height:number) {
    this.surfaceWidth = width
    this.surfaceHeight = height;
    this.updateSurfaceSize();
  }

  private updateSurfaceSize() {
    try {
      if (this.videoSize[0] === 0 || this.videoSize[1] === 0 || this.surfaceWidth === 0 || this.surfaceHeight === 0) {
        MLog.e(TAG, `updateSurfaceSize 不存在`);
        return;
      }
      const scaleX = this.surfaceWidth / this.videoSize[0];
      const scaleY = this.surfaceHeight / this.videoSize[1];

      const scale = Math.min(scaleX, scaleY);
      const w = this.videoSize[0] * scale;
      const h = this.videoSize[1] * scale;

      this.videoMarginHorizontal = Math.floor((this.surfaceWidth - w) / 2);
      this.videoMarginVertical = Math.floor((this.surfaceHeight - h) / 2);
    } catch (e) {
      MLog.e(TAG, `updateSurfaceSize error, err=${e}`);
    }
  }
}
