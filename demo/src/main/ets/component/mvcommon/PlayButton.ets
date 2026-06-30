import { PLAY_IMAGE_URL, PAUSE_IMAGE_URL } from "./ComponentConstants";
import { ControllerBase } from './ControllerBase';

// 按钮组件的状态变换回调
export interface StateChangeDelegate {
  /*
   * @param state 播放还是暂停
   */
  onPlayingStatusChanged: (state: boolean)=> void;
}

// 按钮组件的控制器，用以从父组件控制其状态
export class PlayButtonController extends  ControllerBase<PlayButton> {

  /*
   * 切换按钮组件播放/暂停状态
   * @param state 播放还是暂停
   */
  public changeToState(state: boolean) {
    this.component?.changeToState(state);
  }
}

@Component
export struct PlayButton {
  private readonly logTag: string = "PlayButton";
  // 当前展示的图标
  @State currentImage: string = PLAY_IMAGE_URL;

  // 状态变换回调实例，由父组件提供
  private delegate: StateChangeDelegate | null = null;

  // 控制器，由父组件提供
  private controller: PlayButtonController | null = null;

  // 当前状态
  private isInPlayingState: boolean = false;

  build() {
    Image($r(this.currentImage))
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Gray)
      .onClick((event) => {
        this.isInPlayingState = !this.isInPlayingState;
        this.currentImage = this.isInPlayingState ? PAUSE_IMAGE_URL : PLAY_IMAGE_URL;
        this.delegate?.onPlayingStatusChanged(this.isInPlayingState);
      });
  }

  // 切换按钮组件播放/暂停状态
  public changeToState(state: boolean) {
    this.isInPlayingState = state;
    this.currentImage = this.isInPlayingState ? PAUSE_IMAGE_URL : PLAY_IMAGE_URL;
  }

  // 将控制器绑定到自身的时机函数
  override aboutToAppear() {
    this.controller?.attach(this);
    this.controller = null;
  }
}