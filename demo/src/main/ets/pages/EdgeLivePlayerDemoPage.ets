import {
  ILiveInfoBean,
  IEdgeVideoPlayListener,
  LiveEvent,
  LiveEventInfoAuth,
  LiveEventWaitStart,
  VideoPlayState,
  VideoPlayError } from '@qqmusic/opisdk-entity'
import { EdgeLivePlayer, QQMusicVideoPlayerManager } from '@qqmusic/opisdk-mvplayer'
import { MLog } from '@qqmusic/opisdk-base'

/**
 * EdgeLivePlayerDemoPage 专用的播放事件监听器实现
 */
class LivePlayerCallback implements IEdgeVideoPlayListener {
  private page: EdgeLivePlayerDemoPage
  constructor(page: EdgeLivePlayerDemoPage) {
    this.page = page
  }

  onEvent(state: VideoPlayState, data?: Map<string, Object>): void {
    this.page.playerStateText = VideoPlayState[state]
    this.page.appendLog(`PlayerEvent: ${this.page.playerStateText}`)
  }

  onVideoSizeChanged(width?: number, height?: number): void {
    this.page.appendLog(`VideoRes: ${width}x${height}`)
  }

  onError(error: VideoPlayError, data?: object): void {
    this.page.appendLog(`PlayerError: ${error} - ${data}`)
    this.page.playerStateText = 'ERROR'
  }
}

@ComponentV2
export struct EdgeLivePlayerDemoPage {
  private TAG: string = 'EdgeLivePlayerDemoPage'

  // 核心业务播放器
  private edgeLivePlayer: EdgeLivePlayer | null = null

  // XComponent 控制器
  private xComponentController: XComponentController = new XComponentController()

  // --- UI 状态绑定 ---
  @Local surfaceId: string = ''
  @Local liveStatusText: string = '初始化...' // 无直播/直播中/直播结束
  @Local playerStateText: string = 'IDLE'     // 播放器缓冲/播放/暂停状态
  @Local liveTitle: string = ''
  @Local currentUrl: string = ''
  @Local logText: string = '' // 简易日志窗口

  // 倒计时显示
  @Local waitSeconds: number = 0
  @Local useAndroidMediaPlayer: boolean = true
  // 监听清理函数
  private unsubscribeLiveInfo: (() => void) | null = null
  private unsubscribeEvent: (() => void) | null = null
  private unsubscribeStream: (() => void) | null = null

  aboutToAppear() {
    this.appendLog("QQMusicVideoPlayerManager init...")
    QQMusicVideoPlayerManager.getInstance().init()
    this.appendLog("创建 EdgeLivePlayer实例...")
    this.edgeLivePlayer = new EdgeLivePlayer("demo_live_room")
    this.edgeLivePlayer.setUseSystemPlayer(this.useAndroidMediaPlayer)
    // 1. 设置底层播放器事件回调（监听缓冲/首帧等）
    this.edgeLivePlayer.setPlayEventListener(new LivePlayerCallback(this))

    // 2. 监听业务状态流 (StateFlow)
    // 监听直播间信息
    this.unsubscribeLiveInfo = this.edgeLivePlayer.liveInfoF.collect((liveInfo: ILiveInfoBean) => {
      // 检查 liveInfo 是否存在以及是否为空
      if (liveInfo && !liveInfo.isEmpty()) {
        this.liveTitle = liveInfo.getTitle()
        this.liveStatusText = liveInfo.getStatusDescription() // 待直播/直播中
        this.appendLog(`收到直播信息: ${this.liveTitle}, status=${liveInfo.getStatus()}`)
      }
    })
    // 监听当前播放的流
    this.unsubscribeStream = this.edgeLivePlayer.currentStreamF.collect((stream) => {
      if (stream && !stream.isEmpty()) {
        this.currentUrl = stream.getUrl()
        this.appendLog(`切流成功: ${stream.getResolutionDescription()} - ${this.currentUrl}`)
      }
    })
    // 监听业务事件 (鉴权失败、倒计时等)
    this.unsubscribeEvent = this.edgeLivePlayer.liveEventF.collect((event: LiveEvent) => {
      this.handleLiveEvent(event)
    })
  }

  aboutToDisappear() {
    this.UnsubscribeAll()
    if (this.edgeLivePlayer) {
      this.edgeLivePlayer.destroy()
      this.edgeLivePlayer = null
    }
  }

  private UnsubscribeAll() {
    this.unsubscribeLiveInfo?.()
    this.unsubscribeEvent?.()
    this.unsubscribeStream?.()
  }

  // 处理业务事件
  private handleLiveEvent(event: LiveEvent) {
    if (event instanceof LiveEventWaitStart) {
      this.liveStatusText = "等待开播"
      this.waitSeconds = Math.floor(event.delayTime / 1000)
      this.appendLog(`等待开播: 还有 ${this.waitSeconds} 秒`)
    } else if (event instanceof LiveEventInfoAuth) {
      this.liveStatusText = "无权观看"
      this.appendLog("鉴权失败: 用户无权限")
    } else {
      // IDLE, FINISH 等
    }
  }

  appendLog(msg: string) {
    MLog.i(this.TAG, msg)
    // 简单的UI日志滚动，保留最近10条
    const time = new Date().toLocaleTimeString()
    this.logText = `[${time}] ${msg}\n` + this.logText
    if (this.logText.length > 500) this.logText = this.logText.substring(0, 500)
  }

  build() {
    NavDestination() {
    Column() {
      // 标题
      Text("EdgeLivePlayer 综合业务调试")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .padding(10)
        .backgroundColor('#f0f0f0')
        .width('100%')

      // --- 视频区 ---
      Stack() {
        XComponent({
          id: 'xcomponent_edge_live',
          type: XComponentType.SURFACE,
          controller: this.xComponentController
        })
          .onLoad(() => {
            this.surfaceId = this.xComponentController.getXComponentSurfaceId()
            this.appendLog(`SurfaceCreated: ${this.surfaceId}`)
            // 关键：Surface 准备好后传给 Player
            if (this.edgeLivePlayer) {
              this.edgeLivePlayer.setSurface(this.surfaceId)
            }
          })
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)

        // 倒计时覆盖层
        if (this.waitSeconds > 0) {
          Column() {
            Text("距离开播还有").fontColor(Color.White)
            Text(`${this.waitSeconds}`).fontSize(40).fontColor(Color.White).fontWeight(FontWeight.Bold)
            Text("秒").fontColor(Color.White)
          }
          .backgroundColor('#88000000')
          .padding(20)
          .borderRadius(10)
        }
      }
      .width('100%')
      .height(220)

      // --- 信息区 ---
      Column({ space: 5 }) {
        Text(`直播间: ${this.liveTitle}`).fontWeight(FontWeight.Bold)
        Text(`业务状态: ${this.liveStatusText}`).fontColor(Color.Blue)
        Text(`播放器状态: ${this.playerStateText}`).fontColor(this.playerStateText === 'STARTED' ? Color.Green : Color.Red)
        Text(`当前流Res: ${this.currentUrl}`).fontSize(10).fontColor(Color.Gray).maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
        Text(`是否使用系统播放器: ${this.useAndroidMediaPlayer}`).fontSize(10).fontColor(Color.Gray).maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(10)
      .backgroundColor(Color.White)

      // --- 控制区 ---
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
        Button("loadWithLiveId")
          .onClick(() => {
            if (!this.surfaceId) {
              this.appendLog("错误: Surface未就绪")
              return
            }
            this.edgeLivePlayer?.loadWithLiveId(10000398)
          })

        Button("pause")
          .onClick(() => {
            if (!this.surfaceId) {
              this.appendLog("错误: Surface未就绪")
              return
            }
            this.edgeLivePlayer?.pause()
          })

        Button("play")
          .onClick(() => {
            if (!this.surfaceId) {
              this.appendLog("错误: Surface未就绪")
              return
            }
            this.edgeLivePlayer?.play()
          })

        Button("reload")
          .onClick(() => {
            if (!this.surfaceId) {
              this.appendLog("错误: Surface未就绪")
              return
            }
            this.edgeLivePlayer?.reload()
          })

        Button("switchStream")
          .onClick(() => {
            if (!this.surfaceId) {
              this.appendLog("错误: Surface未就绪")
              return
            }
            this.edgeLivePlayer?.switchStream(2688)
          })

        Button("switchCamera")
          .onClick(() => {
            this.edgeLivePlayer?.switchCamera(486, 2688)
          })

        Button("useAndroidMediaPlayer")
          .onClick(() => {
            this.useAndroidMediaPlayer = !this.useAndroidMediaPlayer
            this.edgeLivePlayer?.setUseSystemPlayer(this.useAndroidMediaPlayer)
          })

        Button("refreshCameraOrStream")
          .onClick(() => {
            this.edgeLivePlayer?.refreshCameraOrStream(486, 2687)
          })

        Button("销毁/重置")
          .onClick(() => {
            this.edgeLivePlayer?.destroy()
            this.appendLog("已销毁，请退出页面或重新进入")
          })
      }
      .padding(10)

      // --- 日志区 ---
      Text("运行日志:")
        .width('100%')
        .padding({ left: 10, top: 10 })
        .fontSize(12)

      Scroll() {
        Text(this.logText)
          .fontSize(10)
          .fontColor('#333333')
          .padding(10)
      }
      .layoutWeight(1) // 占满剩余空间
      .width('100%')
      .backgroundColor('#eeeeee')
      .align(Alignment.TopStart)
    }
    .height('100%')
    .backgroundColor('#ffffff')
    }
    .hideTitleBar(true)
  }
}

@Builder
export function EdgeLivePlayerDemoPageBuilder(params: Object) {
  EdgeLivePlayerDemoPage()
}
