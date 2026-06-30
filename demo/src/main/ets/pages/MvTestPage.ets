import { PROGRESS_TIMER_INTERVAL_SEC } from '../component/mvcommon/ComponentConstants'
import { PlayerController, PlayerControlView, PlayerControlDelegate } from '../component/mvcommon/PlayerControlView'
import { util } from '@kit.ArkTS'
import { IEdgeMediaPlayer, IEdgeVideoPlayListener, VideoPlayError, VideoPlayState } from '@qqmusic/opisdk-entity'
import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'

const TAG = 'MvTestPage'

/**
 * MvTestPage 专用的播放事件监听器实现
 */
class MvPlayListener implements IEdgeVideoPlayListener {
  private page: MvTestPage

  constructor(page: MvTestPage) {
    this.page = page
  }

  onEvent(state: VideoPlayState, data?: Map<string, Object>): void {
    MLog.d(TAG, 'playListener' + '   ' + state + '   ' + JSON.stringify(data))
    if (state === VideoPlayState.PREPARED) {
      this.page.player?.play()
    }

    const durationMs = this.page.player?.getDuration()
    if (durationMs) {
      this.page.playerController.setDurationMs(durationMs)
    }
    // 进度条
    this.page.playerController.changePlayButtonToState(true)
    this.page.startProgressTimer()
  }
  onVideoSizeChanged(width?: number, height?: number): void {
    MLog.d(TAG, 'onVideoSizeChanged' + ' width= ' + width + ' height= ' + height)
  }

  onError(error: VideoPlayError, data?: Object): void {
    MLog.d(TAG, 'onError' + '  error=' + error + '   ' + JSON.stringify(data))
  }
}

/**
 * MvTestPage 专用的播放控制回调实现
 */
class MvControlDelegate implements PlayerControlDelegate {
  private page: MvTestPage

  constructor(page: MvTestPage) {
    this.page = page
  }

  onPlayButtonStatusChanged(state: boolean): void {
    if (state) {
      this.page.player?.pause()
    } else {
      this.page.player?.play()
    }
  }
  onProgressBarSeekStart(_positionMs: number): void {
    // 无操作
  }

  onProgressBarPositionChanged(_positionMs: number): void {
    // 无操作
  }

  onProgressBarSeekEnd(positionMs: number): void {
    this.page.player?.seekAccurateTo(positionMs)
  }
}

@ComponentV2
export struct MvTestPage {
  nativeXComponentID: string = 'VideoView' + util.generateRandomUUID(true)
  // xComponent控制器
  private xComponentController: XComponentController = new XComponentController()
  private xComponentContext: Record<string, () => void> = {}
  private surfaceSize: Size = {
    width: 1280,
    height: 720
  }
  // xComponent的surface id，用来获取native window
  @Local surfaceId: string = ''
  // 播放控件控制器
  playerController: PlayerController = new PlayerController()
  player?: IEdgeMediaPlayer
  // 进度条更新定时器
  private onProgressTimer: number | null = null

  aboutToAppear(): void {
    this.player = OpenApiSdk.videoPlayerApi?.getMediaPlayer('MvTest')
    this.player?.setPlayEventListener(new MvPlayListener(this))

    OpenApiSdk.openApi?.edgeMediaApi?.getMediaInfo(['w0026q7f01a']).then((result) => {
      MLog.d(TAG, 'getMediaInfo' + '   ' + JSON.stringify(result))
      if (result.isSuccess() && result.data && result.data.length > 0) {
        this.player?.setMediaRes(result.data[0])
      }
    }).catch((error: Error) => {
      MLog.d(TAG, 'getMediaInfo' + '   ' + JSON.stringify(error))
    })
  }

  build() {
    NavDestination() {
      Column() {
        // 视频显示组件
        XComponent({
          id: this.nativeXComponentID,
          type: XComponentType.SURFACE,
          controller: this.xComponentController,
          libraryname: 'ThumbPlayer'
        })
          .onLoad(async (xComponentContext?: object | Record<string, () => void>) => {
            if (xComponentContext) {
              this.xComponentContext = xComponentContext as Record<string, () => void>
            }
            this.xComponentController.setXComponentSurfaceSize({
              surfaceWidth: this.surfaceSize.width,
              surfaceHeight: this.surfaceSize.height
            })
            this.surfaceId = this.xComponentController.getXComponentSurfaceId()
            this.player?.setSurface(this.surfaceId)
          })
          .width(`${this.surfaceSize.width}px`)
          .height(`${this.surfaceSize.height}px`)

        // 播放控制组件
        PlayerControlView({
          controller: this.playerController,
          delegate: new MvControlDelegate(this)
        })
          .width('100%')
          .height('5%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .hideTitleBar(true)
  }

  // 开始更新定时器
  startProgressTimer() {
    this.onProgressTimer = setInterval(() => {
      this.updatePlayPosition()
    }, PROGRESS_TIMER_INTERVAL_SEC * 1000)
  }

  // 更新进度条
  private updatePlayPosition() {
    if (this.player === null) {
      return
    }
    const currentPositionMs = this.player?.getPlayDuration()
    const availablePositionMs = this.player?.getPlayDuration()
    if (currentPositionMs && availablePositionMs) {
      this.playerController.updatePlayPosition(currentPositionMs, availablePositionMs)
    }
  }
}

@Builder
export function MvTestPageBuilder(params: Object) {
  MvTestPage()
}
