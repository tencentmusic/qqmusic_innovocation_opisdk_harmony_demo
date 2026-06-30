import { util } from '@kit.ArkTS'
import { IMediaResDetail, MediaQuality } from '@qqmusic/opisdk-entity'
import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import { NavController } from '../../nav/NavController'
import { MVPlayerViewModel } from '../../viewmodel/MVPlayerViewModel'
import { PROGRESS_TIMER_INTERVAL_SEC } from '../../component/mvcommon/ComponentConstants'
import { RouteName } from '../../nav/RouteMap'
import { MVQualityDialog } from '../../component/mvcommon/MVQualityDialog'
import { MVBuyQRDialog } from '../../component/mvcommon/MVBuyQRDialog'
import { MVDetailPageParams, MVPlayerPageParams } from '../../nav/RouteParams'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'

const TAG = 'MVPlayerPage'


@Builder
export function MVPlayerPageBuilder(args?: Object) {
  MVPlayerPage({ args: args })
}

/**
 * MV 播放器页面
 * 对应 Android 的 MVPlayerFragment + MVPlayerActivity 播放功能
 */
@ComponentV2
export struct MVPlayerPage {
  @Param args: Object | undefined = undefined;
  @Param mvVid: string = ''
  @Param mvResDetail: IMediaResDetail | null = null
  @Local viewModel: MVPlayerViewModel = new MVPlayerViewModel()

  // XComponent 相关
  nativeXComponentID: string = 'MVPlayerView' + util.generateRandomUUID(true)
  private xComponentController: XComponentController = new XComponentController()
  @Local surfaceId: string = ''

  // 进度条相关
  @Local progressValue: number = 0
  @Local isDraggingProgress: boolean = false
  // 进度条更新定时器
  private onProgressTimer: number | null = null

  // 品质弹窗
  @Local showQualityDialog: boolean = false
  // 购买二维码弹窗
  @Local showBuyQRDialog: boolean = false
  // 是否暂停歌曲播放
  private isPauseSongPlaying: boolean = false

  aboutToAppear(): void {
    this.handleResume();
    // 设置 Surface
    this.viewModel.player?.setSurface(this.surfaceId)
    this.loadArgs();
    // 启动进度更新定时器
    this.startProgressTimer()
  }

  loadArgs(): void {
    if (this.args) {
      const argument = this.args as MVPlayerPageParams;
      MLog.i(TAG, `loadArgs: ${JSON.stringify(argument)}`);
      if (argument.mvResDetail) {
        this.viewModel.updateMedia(this.mvResDetail);
        return;
      }
      this.viewModel.updateMediaById(argument.mvVid);
    }
  }

  aboutToDisappear(): void {
    this.stopProgressTimer()
    // 暂停播放
    if (this.viewModel.player?.isPlaying()) {
      this.viewModel.player?.pause()
    }

    if (this.isPauseSongPlaying) {
      OpenApiSdk.playerApi?.resume()
    }
  }

  private handleResume(): void {
    if (OpenApiSdk.playerApi?.isPlaying()) {
      OpenApiSdk.playerApi.pause();
      this.isPauseSongPlaying = true;
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 顶部控制栏
          this.buildTopBar()

          // 视频播放区域
          Stack() {
            // XComponent 视频渲染
            XComponent({
              id: this.nativeXComponentID,
              type: XComponentType.SURFACE,
              controller: this.xComponentController
            })
              .onLoad(() => {
                this.surfaceId = this.xComponentController.getXComponentSurfaceId()
                this.viewModel.player?.setSurface(this.surfaceId)
              })
              .width('100%')
              .height('100%')
              .margin({
                top: this.viewModel.videoMarginVertical,
                bottom: this.viewModel.videoMarginVertical,
                left: this.viewModel.videoMarginHorizontal,
                right: this.viewModel.videoMarginHorizontal
              })
              .onAreaChange((oldValue, newValue) => {
                this.viewModel.setSurfaceSize(Number(newValue.width), Number(newValue.height))
              })

            // 加载中遮罩
            if (this.viewModel.isLoading) {
              Column() {
                LoadingProgress()
                  .width(48)
                  .height(48)
                  .color('#FFFFFF')
                Text(this.viewModel.loadingText)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .margin({ top: 8 })
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor('rgba(0, 0, 0, 0.5)')
            }
          }
          .width('100%')
          .aspectRatio(16 / 9)
          .backgroundColor('#000000')

          // MV 信息区域
          this.buildMVInfo()

          // 播放控制区域
          Column() {
            // 进度条（纯进度条，点击可跳转）
            this.buildProgressBar()
            // 控制按钮行
            this.buildControlButtons()
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')

        // 品质选择弹窗（覆盖层）
        if (this.showQualityDialog) {
          MVQualityDialog({
            mediaResDetail: this.viewModel.currentData,
            supportQualityList: this.getSupportQualityList(),
            currentQuality: this.viewModel.currentQuality,
            onQualitySelected: (quality: MediaQuality) => {
              this.viewModel.setQuality(quality)
              this.showQualityDialog = false
            },
            onDismiss: () => {
              this.showQualityDialog = false
            }
          })
        }

        // 购买二维码弹窗（覆盖层，由 ViewModel 的 showBuyQR 触发）
        if (this.viewModel.showBuyQR && this.viewModel.buyQRUrl.length > 0) {
          MVBuyQRDialog({
            qrCodeContent: this.viewModel.buyQRUrl,
            onDismiss: () => {
              this.viewModel.showBuyQR = false
            }
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.viewModel.destroy()
      return false
    })
  }

  @Builder
  buildTopBar() {
    Row() {
      Image($r('app.media.icon_back_placeholder'))
        .width(24)
        .height(24)
        .margin({ left: 16, top: 12, bottom: 12 })
        .onClick(() => {
          this.viewModel.destroy();
          NavController.getInstance().pop();
        })

      Text('MV 播放')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .margin({ top: 12, bottom: 12, left: 8, right: 8 })

      // 品质按钮
      Text(MVPlayerViewModel.getQualityName(this.viewModel.currentQuality))
        .fontSize(12)
        .fontColor('#007AFF')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .border({ width: 1, color: '#007AFF', radius: 4 })
        .margin({ right: 8 })
        .onClick(() => {
          this.showQualityDialog = true
        })
    }
    .width('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  buildMVInfo() {
    Column() {
      if (this.viewModel.currentData) {
        Row({ space: 8 }) {
          // 封面
          Image(this.viewModel.currentData.getCoverImage() ?? '')
            .width(60)
            .height(60)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .backgroundColor('#E0E0E0')

          Column({ space: 4 }) {
            Text(this.viewModel.currentData.getTitle() ?? '未知MV')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.MARQUEE })

            Text('歌手：' + (this.viewModel.currentData.getSingerName() ?? '未知'))
              .fontSize(13)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.MARQUEE })

            Row({ space: 12 }) {
              Text('播放量：' + NumberFormatUtils.formatNumber(this.viewModel.currentData.getPlayCount()))
                .fontSize(11)
                .fontColor('#BBBBBB')

              Text('时长：' + MVPlayerViewModel.formatTime(parseInt(this.viewModel.currentData.getPlayTime() ?? '0')))
                .fontSize(11)
                .fontColor('#BBBBBB')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
  }

  /**
   * 纯进度条组件：使用 Slider 组件，支持点击/拖拽跳转
   */
  @Builder
  buildProgressBar() {
    Row() {
      // 当前时间
      Text(this.formatTimeMs(this.viewModel.playDuration))
        .fontSize(11)
        .fontColor('#999999')
        .width(40)
        .textAlign(TextAlign.Start)

      // Slider 进度条
      Slider({
        value: this.isDraggingProgress ? this.progressValue : this.viewModel.playDuration,
        min: 0,
        max: this.viewModel.duration > 0 ? this.viewModel.duration : 100,
        step: 100
      })
        .blockColor('#FF5500')
        .trackColor('rgba(200, 200, 200, 0.5)')
        .selectedColor('#FF5500')
        .trackThickness(3)
        .layoutWeight(1)
        .onChange((value: number, mode: SliderChangeMode) => {
          if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
            this.isDraggingProgress = true
            this.progressValue = value
          } else if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
            this.isDraggingProgress = false
            this.viewModel.seekTo(value)
          }
        })

      // 总时长
      Text(this.formatTimeMs(this.viewModel.duration))
        .fontSize(11)
        .fontColor('#999999')
        .width(40)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(40)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildControlButtons() {
    Row() {
      // 播放/暂停按钮
      Button(this.viewModel.isPlaying ? '暂停' : '播放')
        .fontSize(12)
        .height(32)
        .type(ButtonType.Normal)
        .borderRadius(16)
        .onClick(() => {
          this.viewModel.playPause()
        })

      Blank()

      // 收藏按钮
      Button(this.viewModel.currentData?.getIsCollect() === 1 ? '已收藏' : '收藏')
        .fontSize(12)
        .height(32)
        .type(ButtonType.Normal)
        .borderRadius(16)
        .onClick(() => {
          this.viewModel.toggleCollect()
        })

      Blank()

      // 循环按钮
      Button(this.viewModel.isLoop ? '循环播放' : '单次播放')
        .fontSize(12)
        .height(32)
        .type(ButtonType.Normal)
        .borderRadius(16)
        .onClick(() => {
          this.viewModel.toggleLoop()
        })

      Blank()

      // 静音按钮
      Button(this.viewModel.isMute ? '解除静音' : '静音')
        .fontSize(12)
        .height(32)
        .type(ButtonType.Normal)
        .borderRadius(16)
        .onClick(() => {
          this.viewModel.toggleMute()
        })

      Blank()

      // 详情按钮
      Button('详情')
        .fontSize(12)
        .height(32)
        .type(ButtonType.Normal)
        .borderRadius(16)
        .onClick(() => {
          // 跳转详情页
          const params = new MVDetailPageParams(this.viewModel.currentData);
          NavController.getInstance().push(RouteName.MV_DETAIL_PAGE, params);
        })
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
  }

  // === 定时器 ===

  startProgressTimer(): void {
    this.onProgressTimer = setInterval(() => {
      this.updatePlayPosition()
    }, PROGRESS_TIMER_INTERVAL_SEC * 1000)
  }

  stopProgressTimer(): void {
    if (this.onProgressTimer !== null) {
      clearInterval(this.onProgressTimer)
      this.onProgressTimer = null
    }
  }

  private updatePlayPosition(): void {
    const currentPositionMs = this.viewModel.getPlayDuration()
    const durationMs = this.viewModel.duration
    if (currentPositionMs !== undefined && durationMs > 0) {
      // 同步更新 ViewModel（Slider 非拖拽时直接绑定 playDuration，无需手动更新 progressValue）
      this.viewModel.playDuration = currentPositionMs
    }
  }

  /**
   * 格式化毫秒为 mm:ss
   */
  private formatTimeMs(ms: number): string {
    return MVPlayerViewModel.formatTimeMs(ms)
  }

  /**
   * 获取设备支持的品质列表
   */
  private getSupportQualityList(): MediaQuality[] {
    // 从 SDK 获取设备支持的品质列表
    const apiList = OpenApiSdk.videoPlayerApi?.getDeviceSupportQualityList()
    if (apiList && apiList.length > 0) {
      return apiList
    }
    // 降级：返回所有品质
    return [
      MediaQuality.DOLBY_4K,
      MediaQuality.EXCELLENT,
      MediaQuality.NORMAL_4K,
      MediaQuality.HIGH_1080,
      MediaQuality.BR_1080,
      MediaQuality.SQ,
      MediaQuality.HQ,
      MediaQuality.LQ
    ]
  }
}