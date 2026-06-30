import { PlayerViewModel } from '../../viewmodel/PlayerViewModel'
import { NavController } from '../../nav/NavController'
import { ISongInfo, PlayerEnums } from '@qqmusic/opisdk-qmutils'
import { OpenApiSdk } from '@qqmusic/opisdk-base';

/**
 * 播放列表页面
 *
 * 当前为占位实现，后续需完善播放列表功能
 */
@ComponentV2
export struct PlayListPage {
  @Local isEdit: boolean = false;
  @Consumer('playerViewModel') viewModel: PlayerViewModel = new PlayerViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.icon_back_placeholder'))
            .width(24)
            .height(24)
            .onClick(() => {
              this.navController.pop()
            })
            .margin({ left: 16, top: 12, bottom: 12 })

          Text('播放列表')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .backgroundColor(Color.White)

        // 操作
        Row() {
          Text(`共${this.viewModel.songList.length}首`)

          Blank().layoutWeight(1)

          if(this.isEdit) {
            Button('取消')
              .onClick(() => {
                this.isEdit = false;
                this.viewModel.selectedList = new Array(this.viewModel.songList.length).fill(false);
              })

            Button('删除')
              .onClick(() => {
                this.isEdit = false
                let songList: ISongInfo[] = [];
                this.viewModel.selectedList.forEach((selected: boolean, index: number) => {
                  if (selected) {
                    songList.push(this.viewModel.songList[index]);
                  }
                })
                if (songList.length > 0) {
                  OpenApiSdk.playerApi?.deleteSongList(songList);
                }
              })
          } else {
            Button('编辑')
              .onClick(() => {
                this.isEdit = true;
              })
          }

          Button('清除全部')
            .onClick(() => {
              OpenApiSdk.playerApi?.clearPlayList();
            })
        }

        // 播放列表内容
        if (this.viewModel.songList.length > 0 && this.viewModel.currentSong !== null) {
          List() {
            Repeat(this.viewModel.songList).each((song) => {
              PlayListSongInfoItem({
                index: song.index,
                songInfo: song.item,
                isEdit: this.isEdit,
                isSelect: this.viewModel.selectedList[song.index],
                isPlaying: this.viewModel.currentSong?.getSongId() === song.item.getSongId(),
                onSelectChange: (value: boolean) => {
                  this.viewModel.selectedList[song.index] = value
                },
                playSong: () => {
                  OpenApiSdk.playerApi?.playPos(song.index);
                }
              })
            })
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: '#000000' })
        } else {
          // 空状态
          Column() {
            Image($r('app.media.icon_home_placeholder'))
              .width(64)
              .height(64)
              .opacity(0.3)
            Text('播放列表为空')
              .fontSize(16)
              .fontColor(Color.Gray)
              .margin({ top: 16 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}

@Builder
export function PlayListPageBuilder(params: Object) {
  PlayListPage()
}

@ComponentV2
struct PlayListSongInfoItem {
  @Param @Require songInfo: ISongInfo;
  @Param index: number = 0;
  @Param isEdit: boolean = false;
  @Param isSelect: boolean = false;
  @Param isPlaying: boolean = false;
  @Event onSelectChange: (value: boolean) => void;
  @Event playSong: () => void;

  build() {
    ListItem() {
      Column() {
        Row({ space: 4 }) {
          if (this.isEdit) {
            Checkbox()
              .select(this.isSelect)
              .onChange((value: boolean) => {
                this.onSelectChange(value);
              })
          }

          Text(this.index + " " + this.songInfo.getSongName())
            .fontSize(16)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          this.buildTagRow()
        }

        Row({ space: 4 }) {
          Text(this.songInfo.getSingerName() ?? '')
            .fontSize(14)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 正在播放指示
          if (this.isPlaying) {
            Image($r('app.media.list_icon_playing'))
              .objectFit(ImageFit.Contain)
              .width(30)
              .height(30)
          }
        }.height(30)
      }
      .onClick(() => {
        if (this.isEdit) {
          this.onSelectChange(!this.isSelect);
        } else {
          this.playSong();
        }
      })
      .alignItems(HorizontalAlign.Start)
      .margin({
        left: 4
      })
    }
    .height(60)
  }

  @Builder
  buildTagRow() {
    Row({ space: 2 }) {
      if (this.songInfo?.isVip()) {
        Image($r('app.media.pay_icon_in_cell_old'))
          .objectFit(ImageFit.Contain)
          .width(18)
          .height(10)
      }

      if (this.songInfo?.getLongAudioVip() === 1) {
        Image($r('app.media.ic_long_audio_vip_new'))
          .objectFit(ImageFit.Contain)
          .width(18)
          .height(10)
      }

      if (this.songInfo?.isFreeLimit()) {
        Image($r('app.media.free_icon'))
          .objectFit(ImageFit.Contain)
          .width(18)
          .height(10)
      }

      if (this.songInfo && OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.DOLBY) === true) {
        Image($r('app.media.action_icon_dolby_quality'))
          .width(26)
          .padding({ right: 1 })
      }

      if (this.songInfo && OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.GALAXY) === true) {
        Image($r('app.media.action_icon_galaxy_quality'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.songInfo && OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.HIRES) === true) {
        Image($r('app.media.action_icon_quality_hires'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.songInfo &&
        OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.EXCELLENT) === true) {
        Image($r('app.media.action_icon_excellent_quality'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.songInfo && OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.SQ) === true) {
        Image($r('app.media.action_icon_quality_sq'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.songInfo?.hasQualityHQ()) {
        Image($r('app.media.hq_icon'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.songInfo &&
        OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.STANDARD) === true) {
        Image($r('app.media.action_icon_quality_standard'))
          .width(26)
          .padding({ right: 1 })
      }

      if (this.songInfo && OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.WANOS) === true) {
        Image($r('app.media.acion_icon_quality_wanos'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.songInfo && OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.VINYL) === true) {
        Image($r('app.media.action_icon_quality_vinyl'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.songInfo &&
        OpenApiSdk.playerApi?.getSongHasQuality(this.songInfo, PlayerEnums.Quality.MASTER_TAPE) === true) {
        Image($r('app.media.master_tape_icon'))
          .width(26)
          .padding({ right: 1 })
      }
    }
  }
}