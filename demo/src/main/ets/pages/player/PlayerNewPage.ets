import { PlayerViewModel } from '../../viewmodel/PlayerViewModel'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { ToastUtil } from '../../utils/ToastUtil'
import { LyricView } from '@qqmusic/opisdk-lyricview'
import { LyricTextParam } from '@qqmusic/opisdk-lyricview'
import { SeekbarComponent } from '../player/SeekbarComponent'
import { MLog } from '@qqmusic/opisdk-base'
import { LyricManager } from '@qqmusic/opisdk-lyricview'
import { SPUtils } from '../../utils/SPUtils'
import { MagicColorUtil } from '../../utils/magiccolor/MagicColorUtil'
import { MagicColorAlgorithm } from '../../utils/magiccolor/MagicColorAlgorithm'
import { image } from '@kit.ImageKit'
import { http } from '@kit.NetworkKit'
import { CoverHelper } from '../../utils/CoverHelper'

const TAG = 'PlayerNewPage'

/**
 * 新版播放页面
 */
@ComponentV2
export struct PlayerNewPage {
  @Consumer('playerViewModel') model: PlayerViewModel = new PlayerViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local lyricManager: LyricManager = LyricManager.getInstance()
  /** 黑胶唱片旋转角度 */
  @Local vinylRotation: number = 0
  /** 是否正在旋转 */
  @Local isVinylRotating: boolean = false
  /** 魔法色字符串 */
  @Local magicColor: string = 'rgba(64, 64, 64, 1.00)'
  /** 魔法色 ARGB 数值 */
  @Local magicColorNumber: number = 0xFF404040
  /** 旋转动画定时器 ID */
  private rotationTimer: number = -1
  /** 封面提取请求 ID，防止异步竞态 */
  private magicColorRequestId: number = 0

  aboutToAppear(): void {
    this.model.init()
    this.model.onPageEnter()
    this.isVinylRotating = this.model.isPlaying
    if (this.isVinylRotating) {
      this.startVinylRotation()
    }
    this.extractMagicColor()
  }

  aboutToDisappear(): void {
    this.stopVinylRotation()
    // 取消未完成的魔法色提取请求
    this.magicColorRequestId++
  }

  /**
   * 从封面 URL 下载图片 → PixelMap → 提取魔法色
   * 利用 MagicColorUtil 获取偏亮光效魔法色对，取第一色作为主色
   */
  private async extractMagicColor(): Promise<void> {
    const url = CoverHelper.getCoverUrl(this.model.currentSong)
    if (!url || url.length === 0) {
      this.setMagicColor(0xFF404040)
      return
    }
    const requestId = ++this.magicColorRequestId
    try {
      const pixelMap = await this.downloadImageToPixelMap(url, 100, 100)
      if (requestId !== this.magicColorRequestId) {
        pixelMap?.release()
        return
      }
      if (pixelMap === null) {
        this.setMagicColor(0xFF404040)
        return
      }
      const pair = await MagicColorUtil.getLightMagicColorPair(pixelMap)
      if (requestId !== this.magicColorRequestId) {
        pixelMap.release()
        return
      }
      const adjusted = MagicColorUtil.getAdjustDefaultPlayerLightMagicColorPair(pair)
      this.setMagicColor(adjusted[0])
      pixelMap.release()
    } catch (e) {
      MLog.e(TAG, 'extractMagicColor error: ' + JSON.stringify(e))
      if (requestId === this.magicColorRequestId) {
        this.setMagicColor(0xFF404040)
      }
    }
  }

  /**
   * 设置魔法色（同时更新字符串和数值两种形式）
   */
  private setMagicColor(argb: number): void {
    this.magicColor = MagicColorAlgorithm.argbToRgba(argb)
    this.magicColorNumber = argb
  }

  /**
   * 从 URL 下载图片并解码为 PixelMap
   * @param url 图片 URL
   * @param width 目标宽度
   * @param height 目标高度
   */
  private async downloadImageToPixelMap(url: string, width: number, height: number): Promise<image.PixelMap | null> {
    const httpRequest = http.createHttp()
    try {
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      })
      const buffer = resp.result as ArrayBuffer
      const imageSource = image.createImageSource(buffer)
      try {
        const pixelMap = await imageSource.createPixelMap({
          desiredSize: { width, height },
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888
        })
        return pixelMap
      } finally {
        imageSource.release()
      }
    } catch (e) {
      MLog.e(TAG, 'downloadImageToPixelMap error: ' + JSON.stringify(e))
      return null
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 监听封面 URL 变化，重新提取魔法色
   */
  @Monitor('model.coverUrl')
  onCoverUrlChanged(): void {
    this.extractMagicColor()
  }

  /**
   * 监听播放状态变化，控制黑胶旋转
   */
  @Monitor('model.isPlaying')
  onPlayingStateChanged(): void {
    if (this.model.isPlaying) {
      if (!this.isVinylRotating) {
        this.isVinylRotating = true
        this.startVinylRotation()
      }
    } else {
      this.isVinylRotating = false
      this.stopVinylRotation()
    }
  }

  /**
   * 启动黑胶旋转动画
   */
  private startVinylRotation(): void {
    if (this.rotationTimer >= 0) {
      return
    }
    const frameInterval = 16
    const rotationPerFrame = 360 / (20000 / frameInterval)
    this.rotationTimer = setInterval(() => {
      this.vinylRotation = (this.vinylRotation + rotationPerFrame) % 360
    }, frameInterval)
  }

  /**
   * 停止黑胶旋转动画
   */
  private stopVinylRotation(): void {
    if (this.rotationTimer >= 0) {
      clearInterval(this.rotationTimer)
      this.rotationTimer = -1
    }
  }

  @Builder
  lyricEmptyView() {
    Column() {
      Text('暂无歌词')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .opacity(0.4)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Column(){
        // 返回按钮
        this.buildBackButton()
        Column() {
          // 歌名
          this.buildSongName()

          // 封面区 + 右侧三个入口
          Stack() {
            this.buildVinylCoverArea()
            this.buildRightEntries()
          }
          .width('100%')
          .margin({ top: 60 })

          // 歌词
          this.buildLyricArea()

          // 进度条
          this.buildProgressBar()

          // 播放控制
          this.buildPlayControlRow()
        }
        .justifyContent(FlexAlign.SpaceAround)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor('#FAFAFA')
  }

  /**
   * 歌名
   */
  @Builder
  buildSongName() {
    Text(this.model.songName)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.magicColor)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .textAlign(TextAlign.Center)
      .width('80%')
      .margin({ top: 10, bottom: 8 })
  }

  /**
   * 黑胶封面区域
   */
  @Builder
  buildVinylCoverArea() {
    Stack({ alignContent: Alignment.Center }) {
      // 黑胶底盘
      Circle()
        .width('100%')
        .height('100%')
        .fill('#1a1a1a')
      // 黑胶纹路
      Circle()
        .width('92%')
        .height('92%')
        .fill(Color.Transparent)
        .stroke('#333333')
        .strokeWidth(1)

      Circle()
        .width('76%')
        .height('76%')
        .fill(Color.Transparent)
        .stroke('#333333')
        .strokeWidth(0.5)

      Circle()
        .width('54%')
        .height('54%')
        .fill(Color.Transparent)
        .stroke('#333333')
        .strokeWidth(0.5)

      Circle()
        .width('30%')
        .height('30%')
        .fill(Color.Transparent)
        .stroke('#444444')
        .strokeWidth(0.5)

      // 中心标签
      Circle()
        .width('22%')
        .height('22%')
        .fill(this.magicColor)

      // 封面图（圆形裁剪）
      Image(CoverHelper.getCoverUrl(this.model.currentSong))
        .width('68%')
        .height('68%')
        .objectFit(ImageFit.Cover)
        .borderRadius('50%')
        .border({ width: 3, color: '#333333' })
    }
    .width('60%')
    .height(0)
    .aspectRatio(1)
    .rotate({
      angle: this.vinylRotation,
      centerX: '50%',
      centerY: '50%'
    })
  }

  /**
   * 沉浸式歌词区域
   * 只显示高亮行，非高亮行透明
   */
  @Builder
  buildLyricArea() {
    Column() {
      LyricView({
        lineTextParam: new LyricTextParam(14, 18, false, Color.Transparent),
        highlightTextParam: new LyricTextParam(18, 26, true, 0xFFFFFFFF, this.magicColorNumber),
        paddingTop: 0,
        lineSpace: 16,
        enableInteraction: false,
        enableWordByWord: false,
        scrollAlign: ScrollAlign.CENTER,
        emptyView: this.lyricEmptyView,
        lyricTextAlign: TextAlign.Center
      })
    }
    .width('100%')
    .height(200)
    .margin({ left: 16, right: 16 })
    .clip(true)
  }

  /**
   * seek_bar：进度条
   */
  @Builder
  buildProgressBar() {
    SeekbarComponent({
      progress: this.model.playPosition,
      progressMax: this.model.duration,
      playColor: this.magicColor,
      bgColor: '#FFFFFF20',
      tryListenStart: this.model.currentSong?.canOnlyPlayTry() ? (this.model.currentSong?.getTryBegin() ?? 0) : 0,
      tryListenEnd: this.model.currentSong?.canOnlyPlayTry() ? (this.model.currentSong?.getTryEnd() ?? 0) : 0,
      isShowTime: false,
      enableInteraction: true,
      progressHeight: 3,
      onSeek: (position: number) => {
        this.model.seekTo(position)
      }
    })
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 20 })
  }

  /**
   * 播放控制行
   */
  @Builder
  buildPlayControlRow() {
    Row() {
      Image($r('app.media.ic_previous'))
        .width(40)
        .height(40)
        .fillColor(this.magicColor)
        .margin({ right: 32 })
        .onClick(() => {
          this.model.prev()
        })

      Image(this.model.isPlaying ? $r('app.media.ic_state_playing') : $r('app.media.ic_state_paused'))
        .width(70)
        .height(70)
        .fillColor(this.magicColor)
        .margin({ right: 32 })
        .onClick(() => {
          this.model.playPause()
        })

      Image($r('app.media.ic_next'))
        .width(40)
        .height(40)
        .fillColor(this.magicColor)
        .onClick(() => {
          this.model.next()
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .margin({ bottom: 25 })
  }

  /**
   * 返回按钮
   */
  @Builder
  buildBackButton() {
    Row() {
      Image($r('app.media.icon_back_placeholder'))
        .width(24)
        .height(24)
        .margin({ left: 16, top: 12, bottom: 12 })
        .onClick(() => {
          this.navController.pop()
        })
    }
    .width('100%')
    .height(50)
    .alignItems(VerticalAlign.Bottom)
  }

  /**
   * 右侧三个入口
   */
  @Builder
  buildRightEntries() {
    Column() {
      // 播放器样式
      Image($r('app.media.exo_ic_settings'))
        .width(50)
        .height(50)
        .backgroundColor(this.magicColor)
        .margin({ bottom: 5 })
        .onClick(() => {
          ToastUtil.show('播放器皮肤功能开发中')
        })

      // 旧版播放页
      Image($r('app.media.exo_ic_audiotrack'))
        .width(50)
        .height(50)
        .backgroundColor(this.magicColor)
        .margin({ bottom: 5 })
        .onClick(() => {
          SPUtils.setBool('newPlayerPage', false)
          this.navController.pop()
          this.navController.push(RouteName.PLAYER_PAGE)
        })

      // 沉浸式歌词
      Text('沉浸式歌词')
        .fontSize(10)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(50)
        .height(50)
        .backgroundColor(this.magicColor)
        .padding(4)
        .borderRadius(4)
        .onClick(() => {
          this.navController.push(RouteName.LYRIC_TEST_PAGE)
        })
    }
    .alignItems(HorizontalAlign.Center)
    .position({ right: 10, top: 40 })
  }
}

@Builder
export function PlayerNewPageBuilder(params: Object) {
  PlayerNewPage()
}
