import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { NavController } from '../nav/NavController'
import { RouteName } from '../nav/RouteMap'
import { LyricView } from '@qqmusic/opisdk-lyricview'
import { LyricTextParam } from '@qqmusic/opisdk-lyricview'
import { AppUtil } from '../utils/AppUtil'

/**
 * 悬浮播放器页面
 *
 * 布局：封面 | 歌名+歌词 | VIP图标 | 播放/暂停 | 播放列表
 */
@ComponentV2
export struct FloatingPlayerPage {
  @Consumer('playerViewModel') viewModel: PlayerViewModel = new PlayerViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()

  private get songName(): string {
    return this.viewModel.currentSong?.getSongName() ?? ''
  }

  private get coverUrl(): string {
    return this.viewModel.currentSong?.smallCoverUrl() ?? ''
  }

  private get isVip(): boolean {
    return this.viewModel.currentSong?.isVip() ?? false
  }

  private get isLongAudioVip(): boolean {
    return (this.viewModel.currentSong?.getLongAudioVip() ?? 0) === 1
  }

  private get playIcon(): ResourceStr {
    return this.viewModel.isPlaying
      ? $r('app.media.ic_state_playing')
      : $r('app.media.ic_state_paused')
  }

  @Builder
  lyricEmptyView() {
    Column() {
    }
    .width('100%')
    .height(16)
  }

  build() {
    Column() {
      Row() {
        // 封面
        Image(this.coverUrl)
          .width(60)
          .height(60)
          .objectFit(ImageFit.Cover)
          .borderRadius(4)
          .backgroundColor('#E0E0E0')
          .margin({ left: 10 })

        // 歌名 + VIP图标 + 歌词
        Column({ space: 2 }) {
          // 歌名 + VIP图标
          Row({ space: 4 }) {
            Text(this.songName)
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.MARQUEE })

            // VIP图标（付费歌曲）—— 紧跟歌名右侧
            if (this.isVip) {
              Image($r('app.media.pay_icon_in_cell_old'))
                .objectFit(ImageFit.Contain)
                .width(18)
                .height(12)
            }

            // 长音频VIP图标 —— 紧跟歌名右侧
            if (this.isLongAudioVip) {
              Image($r('app.media.ic_long_audio_vip_new'))
                .objectFit(ImageFit.Contain)
                .width(28)
                .height(12)
            }
          }
          .padding({ right: 12 })
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 迷你歌词
          LyricView({
            lineTextParam: new LyricTextParam(11, 14, false, 0x7F888888),
            highlightTextParam: new LyricTextParam(11, 14, false, 0x7F888888),
            paddingTop: 0,
            lineSpace: 0,
            enableInteraction: false,
            enableWordByWord: false,
            scrollAlign: ScrollAlign.CENTER,
            emptyView: this.lyricEmptyView
          })
            .width('100%')
            .height(16)
            .clip(true)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 8 })
        .padding({ top: 8, bottom: 8 })

        // 播放/暂停按钮
        Image(this.playIcon)
          .width(40)
          .height(40)
          .onClick(() => {
            this.viewModel.playPause()
          })

        // 播放列表按钮
        Image($r('app.media.ic_playlist'))
          .width(40)
          .height(40)
          .onClick(() => {
            this.navController.push(RouteName.PLAY_LIST_PAGE)
          })
          .margin({ left: 4, right: 10 })
      }
      .width('100%')
      .height(70)
      .backgroundColor('#F0FFF0')
    }
    .width('100%')
    .height(70)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: Color.Gray })
    .margin({ bottom: this.navController.isAtHome ? 56 : -AppUtil.bottomSafeArea })
    .onClick(() => {
      this.navController.push(RouteName.PLAYER_PAGE)
    })
  }
}
