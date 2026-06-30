import { PlayButton, StateChangeDelegate, PlayButtonController } from './PlayButton';
import { ProgressBar, ProgressDelegate, ProgressBarController} from './ProgressBar';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ControllerBase } from './ControllerBase';

// 播放控制组件的状态变换回调
export interface PlayerControlDelegate {
  onPlayButtonStatusChanged: (state: boolean) => void;
  onProgressBarSeekStart: (positionMs: number) => void;
  onProgressBarPositionChanged: (positionMs: number) => void;
  onProgressBarSeekEnd: (positionMs: number) => void;
}

// 播放控制组件的控制器
export class PlayerController extends  ControllerBase<PlayerControlView> {
  /* 更新播放进度
   * @param positionMs 当前播放位置
   * @param availablePositionMs 当前可播位置
   */
  public updatePlayPosition(positionMs: number, availablePositionMs: number) {
    if (this.component === null) {
      return;
    }
    this.component.updatePlayPosition(positionMs, availablePositionMs);
  }

  /* 更新播放按钮的播放状态
   * @param state 播放状态(true/播放,false/暂停)
   */
  public changePlayButtonToState(state: boolean) {
    if (this.component === null) {
      return;
    }
    this.component.changePlayButtonToState(state);
  }

  /* 设置视频总时长
   * @param durationMs 视频总时长
   */
  public setDurationMs(durationMs: number) {
    if (this.component === null) {
      return;
    }
    this.component.setDurationMs(durationMs);
  }
}

@Component
export struct PlayerControlView {
  private readonly logTag: string = "PlayerControlView";

  //播放时间点字符串
  @State timeString: string = '00:00/00:00';

  // 状态变换回调实例，由父组件提供
  private delegate?: PlayerControlDelegate;

  // 控制器，由父组件提供
  private controller: PlayerController | null = null;

  // 视频总时长
  private durationMs: number = 1 * 60 * 60 * 1000;

  // 进度条控制器
  private progressController: ProgressBarController = new ProgressBarController();

  // 播放按钮控制器
  private playButtonController: PlayButtonController = new PlayButtonController();

  build() {
    Row() {
      // 播放按钮
      PlayButton( {
        delegate: {
          onPlayingStatusChanged: (state: boolean) => {
            this.delegate?.onPlayButtonStatusChanged(state)
          }
        },
        controller: this.playButtonController
      })
        .width('10%')
        .height('100%');

      // 播放进度条
      ProgressBar({
        delegate: {
          onStartTrackingTouch: (progress: number) => {
            let currentPositionMs = this.durationMs * progress
            this.delegate?.onProgressBarSeekStart(currentPositionMs)
            this.showPlayPosition(currentPositionMs)
          },
          onProgressChanged: (progress: number) => {
            let currentPositionMs = this.durationMs * progress
            this.delegate?.onProgressBarPositionChanged(currentPositionMs)
            this.showPlayPosition(currentPositionMs)
          },

          onStopTrackingTouch: (progress: number) => {
            let currentPositionMs = this.durationMs * progress
            this.delegate?.onProgressBarSeekEnd(currentPositionMs)
            this.showPlayPosition(currentPositionMs)
          }
        },
        controller: this.progressController
      })
        .width('78%')
        .height('100%');

      // 播放时间点
      Text(this.timeString)
        .width('12%')
        .height('100%')
        .draggable(false)
        .fontSize(6);
    }
  }

  public changePlayButtonToState(state: boolean) {
    this.playButtonController.changeToState(state);
  }

  public updatePlayPosition(positionMs: number, availablePositionMs: number) {
    if (this.durationMs <= 0) {
      return;
    }
    this.progressController.setProgress(positionMs / this.durationMs, availablePositionMs / this.durationMs);
    this.showPlayPosition(positionMs);
  }

  public setDurationMs(durationMs: number) {
    this.durationMs = durationMs;
  }

  private showPlayPosition(positionMs: number) {
    this.timeString = this.msToTimeString(positionMs) + '/' + this.msToTimeString(this.durationMs);
  }

  // 将毫秒转换成h:m:s的时分秒格式字符串
  private msToTimeString(ms: number): string {
    let positionSec = Math.round(ms / 1000);
    let seconds = positionSec % 60;
    let minute = positionSec >= 60 ? (positionSec / 60) % 60 : 0;
    let hour = positionSec / 60 >= 60 ? (positionSec / 60) / 60 : 0;
    if (Number.isNaN(seconds) || !Number.isFinite(seconds)) {
      seconds = 0;
    }
    if (Number.isNaN(minute) || !Number.isFinite(minute)) {
      minute = 0;
    }
    if (Number.isNaN(hour) || !Number.isFinite(hour)) {
      hour = 0;
    }
    hour = Math.floor(hour);
    minute = Math.floor(minute);
    seconds = Math.floor(seconds);
    if (hour > 0) {
      return `${hour}:${minute}:${seconds}`;
    }
    return `${minute}:${seconds}`;
  }

  // 将控制器绑定到自身的时机函数
  override aboutToAppear() {
    this.controller?.attach(this);
    this.controller = null;
  }
}