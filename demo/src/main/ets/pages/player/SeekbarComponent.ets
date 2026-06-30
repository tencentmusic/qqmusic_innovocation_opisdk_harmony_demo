import { MLog } from '@qqmusic/opisdk-base';
import { TimeUtils } from '@qqmusic/opisdk-qmutils';
const TAG = 'SeekbarComponent';

/**
 * 通用播放seekbar组件
 * 支持音乐播放和MV播放场景，提供点击和拖动快进快退能力
 */
@Preview
@ComponentV2
export struct SeekbarComponent {
  /** 当前播放进度（单位：毫秒） */
  @Param progress: number = 0;
  /** 最大进度，即歌曲/视频总时长（单位：毫秒） */
  @Param progressMax: number = 0;
  /** 试听开始位置（单位：毫秒） */
  @Param tryListenStart: number = 0;
  /** 试听结束位置（单位：毫秒），为0表示无试听区间 */
  @Param tryListenEnd: number = 0;
  /** 播放进度条颜色 */
  @Param playColor: ResourceColor = $r('app.color.color_70FBAC');
  /** 进度条背景颜色 */
  @Param bgColor: ResourceColor = $r('app.color.color_FFFFFF_10');
  /** 是否展示时间 */
  @Param isShowTime: boolean = true;
  /** 是否启用交互（包括hover态效果和点击/拖动手势） */
  @Param enableInteraction: boolean = true;
  /** 进度条高度（单位vp） */
  @Param progressHeight: number = 6;
  /** hover状态变化回调 */
  @Param seekBarHoverChange: (hover: boolean) => void = () => {};
  /** 快进快退回调，参数为目标进度位置（单位：毫秒，整数） */
  @Param onSeek: (position: number) => void = () => {};

  /** 是否处于hover态 */
  @Local isHovered: boolean = false;
  /** 是否处于拖动状态 */
  @Local isPressed: boolean = false;
  /** 拖动过程中的实时进度值（松手前的临时进度） */
  @Local seekProgress: number = 0;
  /** 是否处于seek过渡期（松手后、播放器seek生效前），用于防止进度条回退 */
  @Local isSeeking: boolean = false;
  /** 进度条的实际可用宽度（像素），始终等于viewWidth，代表完整歌曲时长 */
  @Local progressWidth: number = 0;
  /** 进度条相对于容器左边的偏移量（像素），始终为0 */
  @Local progressLeft: number = 0;
  /** 进度条代表的总时长（毫秒），始终等于progressMax（完整歌曲时长） */
  @Local progressTotal: number = 0;
  /** 整个Stack容器的实际渲染宽度（像素），通过onAreaChange获取，是各像素值计算的基准 */
  @Local viewWidth: number = 0;
  /** 滑块（thumb）的X坐标位置（像素），跟随播放进度自动更新 */
  @Local thumbX: number = 0;

  /** 滑块宽高（固定值，单位vp） */
  private readonly thumbWidth: number = 28;
  /** 试听端点宽高，单位vp */
  private readonly tryPlayPointWidth: number = 10;

  /** Hover态下进度条放大倍数 */
  private hoverScale = 2;
  /** 组件实际渲染大小，根据hover/拖动状态动态切换，hover态下放大2倍 */
  private renderSize(normalSize: number): number {
    return (this.isHovered || this.isPressed || this.isSeeking) ? normalSize * this.hoverScale : normalSize;
  }
  /** 进度条最大高度, 进度条高度在hover态下的高度 */
  private get seekbarHeight(): number {
    return this.progressHeight * this.hoverScale;
  }

  /** 手势操作的起始X坐标（像素），拖动时记录按下位置，后续通过offsetX计算实际位置 */
  private startX: number = 0;

  /** 监听播放进度变化，实时更新滑块位置 */
  @Monitor('progress')
  onProgress() {
    // seek过渡期结束：当外部progress更新后，取消isSeeking状态
    if (this.isSeeking) {
      this.isSeeking = false;
    }
    this.thumbX = this.getCenterPosition(this.progress);
  }

  /**
   * 监听进度相关参数变化，重新计算进度条的布局参数
   * 进度条始终展示完整歌曲时长，试听区间仅用于限制拖拽范围和显示端点标记
   */
  @Monitor('progressMax', 'tryListenStart', 'tryListenEnd')
  onProgressInfoChanged() {
    MLog.i(TAG, `tryStart = ${this.tryListenStart}, tryEnd = ${this.tryListenEnd}, total = ${this.progressMax}`);
    // 进度条始终占满整个容器宽度，代表完整歌曲时长
    this.progressLeft = 0;
    this.progressWidth = this.viewWidth;
    this.progressTotal = this.progressMax;
    MLog.i(TAG, `${this.progressLeft}-${this.progressWidth}-${this.progressTotal}`)
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Start }) {
        // 底部背景
        Row()
          .backgroundColor(this.bgColor)
          .width('100%')
          .height(this.renderSize(this.progressHeight))
          .borderRadius(this.renderSize(this.progressHeight) / 2)

        // 播放进度条（拖动或seek过渡期显示seekProgress，否则显示实际播放进度）
        // 进度条始终展示完整歌曲时长，value和total都使用绝对时间
        Progress({
          value: (this.isPressed || this.isSeeking) ? this.seekProgress : this.progress,
          total: this.progressTotal,
          type: ProgressType.Linear
        })
          .color(this.playColor)
          .backgroundColor(Color.Transparent)
          .style({
            strokeWidth: this.renderSize(this.progressHeight),
            enableSmoothEffect: false
          })
          .width('100%')
        // 试听起始端点标记（仅在有试听区间时显示，大小跟随hover状态同步放大）
        if (this.tryListenStart > 0) {
          Text()
            .backgroundColor(this.playColor)
            .width(this.renderSize(this.tryPlayPointWidth))
            .height(this.renderSize(this.tryPlayPointWidth))
            .borderRadius(this.renderSize(this.tryPlayPointWidth) / 2)
            .position({
              x: this.getCenterPosition(this.tryListenStart),
              y: this.seekbarHeight / 2
            })
            .markAnchor({
              x: this.renderSize(this.tryPlayPointWidth) / 2,
              y: this.renderSize(this.tryPlayPointWidth) / 2
            })
        }

        // 试听结束端点标记（仅在有试听区间时显示，大小跟随hover状态同步放大）
        if (this.tryListenEnd > 0) {
          Text()
            .backgroundColor(this.playColor)
            .width(this.renderSize(this.tryPlayPointWidth))
            .height(this.renderSize(this.tryPlayPointWidth))
            .borderRadius(this.renderSize(this.tryPlayPointWidth) / 2)
            .position({
              x: this.getCenterPosition(this.tryListenEnd),
              y: this.seekbarHeight / 2
            })
            .markAnchor({
              x: this.renderSize(this.tryPlayPointWidth) / 2,
              y: this.renderSize(this.tryPlayPointWidth) / 2
            })
        }

        // 滑块thumb, 仅在hover态或拖动态时显示
        if (this.isHovered || this.isPressed || this.isSeeking) {
          Text()
            .backgroundColor(this.playColor)
            .width(this.thumbWidth)
            .height(this.thumbWidth)
            .borderRadius(this.thumbWidth / 2)
            .position({
              x: (this.isPressed || this.isSeeking) ? this.getCenterPosition(this.seekProgress) : this.thumbX,
              y: this.seekbarHeight / 2
            })
            .markAnchor({
              x: this.thumbWidth / 2,
              y: this.thumbWidth / 2
            })
        }
      }
      .height(this.seekbarHeight)
      .clip(false)
      // 上下各扩展 thumbWidth 的响应区，布局高度不变，视觉不受影响
      .responseRegion({
        x: 0,
        y: -this.thumbWidth,
        width: '100%',
        height: this.seekbarHeight + this.thumbWidth * 2
      })
      .gesture(
        GestureGroup(GestureMode.Parallel,
          PanGesture({ direction: PanDirection.Horizontal, distance: 0.1 })
            .onActionStart((event) => {
              if (this.enableInteraction && this.progressMax > 0) {
                this.isPressed = true;
                this.startX = event.fingerList[0]?.localX ?? 0;
              }
            })
            .onActionUpdate((event) => {
              if (this.enableInteraction && this.progressMax > 0) {
                this.seekToPosition(this.startX + event.offsetX);
              }
            })
            .onActionEnd((event) => {
              if (this.enableInteraction && this.progressMax > 0) {
                this.seekToPosition(this.startX + event.offsetX, true);
                // 进入seek过渡期，保持显示seekProgress，直到外部progress更新
                this.isSeeking = true;
                this.thumbX = this.getCenterPosition(this.seekProgress);
                this.isPressed = false;
              }
            }),
          TapGesture({ count: 1 })
            .onAction((event) => {
              if (this.enableInteraction && this.progressMax > 0) {
                this.startX = event.fingerList[0]?.localX ?? 0;
                this.seekToPosition(this.startX, true);
                // 点击也进入seek过渡期
                this.isSeeking = true;
                this.thumbX = this.getCenterPosition(this.seekProgress);
              }
            })
        )
      )
      .onAreaChange((_oldVal, newVal) => {
        if (typeof newVal.width === 'number') {
          this.viewWidth = newVal.width;
          MLog.d(TAG, 'viewWidth = ' + this.viewWidth);
          this.onProgressInfoChanged();
        }
      })
      .onHover((isHover: boolean) => {
        if (!this.enableInteraction) {
          return;
        }
        this.isHovered = isHover;
        this.seekBarHoverChange(isHover);
      })

      // 展示时间（左侧为当前播放时间，右侧为总时长）
      if (this.isShowTime) {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text(TimeUtils.formatCountDown(Math.floor(((this.isPressed || this.isSeeking) ? Math.max(this.seekProgress, 0) : this.progress) / 1000)))
            .textAlign(TextAlign.Center)
            .fontColor($r('app.color.color_FFFFFF_50'))
            .fontSize(16)

          Text(TimeUtils.formatCountDown(Math.floor(this.progressMax / 1000)))
            .textAlign(TextAlign.Center)
            .fontColor($r('app.color.color_FFFFFF_50'))
            .fontSize(16)
        }
        .margin({ top: (this.thumbWidth - this.seekbarHeight) / 2 })
      }
    }
  }

  /**
   * 将手势的像素位置转换为播放进度，并更新seekProgress
   * 使用完整进度条宽度计算位置，但结果限制在试听区间内（如有）
   * @param targetPos - 手势在容器中的X坐标（像素）
   * @param seek - 是否真正执行seek操作（拖动结束或点击时为true）
   */
  private seekToPosition(targetPos: number, seek: boolean = false) {
    // 将目标位置限制在容器范围内
    const pos = Math.max(0, Math.min(targetPos, this.viewWidth));
    // 像素坐标按完整宽度比例转换为绝对播放时间
    const absolutePosition = Math.round(pos / this.viewWidth * this.progressMax);
    // 限制在试听区间内（如有试听区间），否则限制在完整范围内
    const minPos = this.tryListenEnd > 0 ? this.tryListenStart : 0;
    const maxPos = this.tryListenEnd > 0 ? this.tryListenEnd : this.progressMax;
    this.seekProgress = Math.max(minPos, Math.min(absolutePosition, maxPos));
    // 仅在需要seek时，触发回调
    if (seek) {
      MLog.i(TAG, `seekToPosition absolute = ${this.seekProgress}, progressMax = ${this.progressMax}, tryStart = ${this.tryListenStart}, tryEnd = ${this.tryListenEnd}`);
      this.onSeek(this.seekProgress);
    }
  }

  /**
   * 将播放进度值转换为中心点X坐标（vp），配合markAnchor使用实现居中定位
   * @param progress - 播放进度值（绝对时间）
   * @returns 进度对应的X坐标（vp），即元素中心应在的位置
   */
  private getCenterPosition(progress: number): number {
    // progress是绝对时间，直接用 progress/progressMax 得到在整个视图中的比例
    return Math.min(progress / this.progressMax, 1) * this.viewWidth;
  }
}
