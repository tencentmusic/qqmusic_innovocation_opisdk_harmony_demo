import {
  MAX_PROGRESS,
  PROGRESS_STEP,
  KNOB_IMAGE_URL,
  SLIDER_BLOCK_COLOR,
  SLIDER_TRACK_COLOR,
  SLIDER_SELECTED_COLOR } from "./ComponentConstants"
import { ControllerBase } from './ControllerBase'

// 进度条组件的状态变换回调
export interface ProgressDelegate {
  /*
   * 进度条开始拖动
   * @param progress 播放进度，0~1.0
   */
  onStartTrackingTouch: (progress: number) => void;

  /*
   * 进度条值变化
   * @param progress 播放进度，0~1.0
   */
  onProgressChanged: (progress: number) => void;

  /*
   * 进度条结束拖动
   * @param progress 播放进度，0~1.0
   */
  onStopTrackingTouch: (progress: number) => void;
}

// 进度条组件的控制器，用以从父组件控制其状态
export class ProgressBarController extends  ControllerBase<ProgressBar> {
  /*
   * 设置进度
   * @param mainProgress 主播放进度，0~1.0
   * @param mainProgress 加载进度，0~1.0
   */
  public setProgress(mainProgress: number, secondaryProgress: number) {
    this.component?.setProgress(mainProgress, secondaryProgress);
  }
}

@Component
export struct ProgressBar {
  private readonly logTag: string = "ProgressBar";

  // 主进度
  @State mainProgress: number = 0.0;

  // 辅进度
  @State secondaryProgress: number = 0.0;

  // 状态回调实例，由父组件提供
  private delegate: ProgressDelegate | null = null;

  // 控制器，由父组件提供
  private controller: ProgressBarController | null = null;

  // 是否在拖动
  private isDragging: boolean = false;

  // 最近一次拖动的进度
  private lastDragPosition: number = 0.0;

  build() {
    /*
     * 这个进度条是通过叠加两个slider组件构建的
     * 两者背景色一样，在上层的slider显示播放进度，
     * 下层的显示加载进度，只有上层的滑块是可见的
     */
    Stack() {
      // 加载进度条
      Slider({
        value: this.secondaryProgress * MAX_PROGRESS,
        max: MAX_PROGRESS,
        step: PROGRESS_STEP,
        style: SliderStyle.OutSet,
        direction: Axis.Horizontal,

      })
        .width('100%')
        .blockColor(SLIDER_BLOCK_COLOR)
        .blockSize({ width: 0, height: 0})
        .trackColor(SLIDER_TRACK_COLOR)
        .selectedColor(SLIDER_SELECTED_COLOR)
        .showSteps(false);

      // 播放进度条
      Slider({
        value: this.mainProgress * MAX_PROGRESS,
        max: MAX_PROGRESS,
        step: PROGRESS_STEP,
        style: SliderStyle.OutSet,
        direction: Axis.Horizontal,
      })
        .width('100%')
        .blockStyle({
          type: SliderBlockType.IMAGE,
          image: $r(KNOB_IMAGE_URL),
        })
        // 这个字段无法引用资源文件，使用定义值
        .trackColor(SLIDER_TRACK_COLOR)
        .selectedColor(Color.Orange)
        .showSteps(true)
        .onChange((value: number, mode: SliderChangeMode) => {
          switch (mode) {
            case SliderChangeMode.Begin:
              break;
            case SliderChangeMode.Moving: {
              if (!this.isDragging && (value < 0 || value > MAX_PROGRESS)) {
                return;
              }
              let progress = value / MAX_PROGRESS;
              progress = Math.min(progress, 1.0);
              progress = Math.max(progress, 0.0);
              if (!this.isDragging) {
                this.isDragging = true;
                this.delegate?.onStartTrackingTouch(progress);
                this.lastDragPosition = progress;
              }
              this.lastDragPosition = progress;
              this.delegate?.onProgressChanged(progress);
              break;
            }
            case SliderChangeMode.End:
              if (this.isDragging) {
                this.delegate?.onStopTrackingTouch(this.lastDragPosition);
              }
              this.isDragging = false;
              break;
            case SliderChangeMode.Click:
              break;
            default:
              break;
          }
        });
    }.align(Alignment.TopStart);
  }

  /*
   * 设置进度
   * @param mainProgress 主播放进度，0~1.0
   * @param mainProgress 加载进度，0~1.0
   */
  public setProgress(mainProgress: number, secondaryProgress: number) {
    this.mainProgress = mainProgress;
    this.secondaryProgress = secondaryProgress;
  }

  // 将控制器绑定到自身的时机函数
  override aboutToAppear() {
    this.controller?.attach(this);
    this.controller = null;
  }
}