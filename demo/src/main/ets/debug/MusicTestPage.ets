import { NavController } from '../nav/NavController';
import { MusicTestViewModel } from '../viewmodel/MusicTestViewModel';
import { PlayerViewModel, QualityItem } from '../viewmodel/PlayerViewModel';

const TAG = 'MusicTestPage';

@ComponentV2
export struct MusicTestPage {
  navController: NavController = NavController.getInstance();
  musicTestViewModel: MusicTestViewModel = new MusicTestViewModel();
  @Local playSongStr: string = '335918510,317178463,316688109,332183304';
  @Local songFolderIdStr: string = '';
  @Local videoStr: string = '';
  @Local similarSongStr: string = '';
  @Consumer('playerViewModel') model: PlayerViewModel = new PlayerViewModel()
  @Local qualitySheetVisible: boolean = false

  aboutToAppear(): void {

  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {

        Row() {
          TextInput({
            text: this.playSongStr,
          })
            .layoutWeight(1)

          Button('播放')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.play(this.playSongStr);
            })
        }

        Row() {
          Button('设置播放列表')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.playList(this.playSongStr);
            })

          Button('添加播放列表到下一首')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.addToNext(this.playSongStr);
            })

          Button('添加播放列表到下一首并播放')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.addToNextAndPlay(this.playSongStr);
            })
        }

        Row() {
          Button('切换')
            .fontSize(16)
            .onClick(() => {
              this.qualitySheetVisible = true;
            })
            .bindSheet($$this.qualitySheetVisible, this.buildQualitySheet(), {
              height: SheetSize.FIT_CONTENT,
              dragBar: true,
              backgroundColor: Color.White,
              onDisappear: () => {
                this.qualitySheetVisible = false
              }
            })
          Text('当前默认音质：' + this.model.getQualityText(this.model.preferSongQuality))
            .fontSize(16)
        }

        Row() {
          Button('填入杜比歌曲')
            .fontSize(16)
            .onClick(() => {
              this.playSongStr = "370513537";
            })

          Button('填入HIRES歌曲')
            .fontSize(16)
            .onClick(() => {
              this.playSongStr = "381885920,262607197";
            })

          Button('填入黑胶歌曲')
            .fontSize(16)
            .onClick(() => {
              this.playSongStr = "399932197,399932192,399932196";
            })
        }

        TextInput({
          placeholder: '输入歌单/专辑',
          text: this.songFolderIdStr,
        })

        Row() {
          Text('歌单：')
            .fontSize(16)
          Button('搜索歌单')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.searchSongList(this.songFolderIdStr);
            })

          Button('添加歌单到播放列表')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.addSongListToPlayList(this.songFolderIdStr);
            })

          Button('更新播放列表')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.updatePlayList(this.songFolderIdStr);
            })
        }

        Row() {
          Text('专辑：')
            .fontSize(16)

          Button('查看专辑详情')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.searchAlbum(this.songFolderIdStr);
            })
        }

        Button('初始化播放条件')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.musicTestViewModel.initPlayerEnv();
          })

        Row() {
          TextInput({
            placeholder: 'a0040pizz4a',
            text: this.videoStr,
          })
            .layoutWeight(1)

          Button('播放测试视频')
            .fontSize(16)
            .onClick(() => {
              this.musicTestViewModel.testMV(this.videoStr);
            })
        }

        Text('播放控制：')
          .fontSize(16)
        Button('停止播放')
          .fontSize(16)
          .onClick(() => {
            this.musicTestViewModel.stopPlay();
          })

        TextInput({
          placeholder: '输入一个songId/mid,用于推荐相似单曲',
          text: this.similarSongStr
        })
        Button('相似单曲')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.musicTestViewModel.fetchSimilarSong(this.similarSongStr);
          })

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .hideTitleBar(true)
  }

  /**
   * 音质选择弹窗
   * 显示当前歌曲支持的所有音质，当前音质高亮标记
   */
  @Builder
  buildQualitySheet() {
    Column() {
      // 标题
      Text('选择音质')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 })

      // 品质列表
      List({ space: 0 }) {
        ForEach(this.model.qualityList, (item: QualityItem) => {
          ListItem() {
            Row() {
              // 音质名称
              Text(item.name)
                .fontSize(15)
                .fontColor(item.hasQuality ? '#333333' : '#BBBBBB')
                .layoutWeight(1)

              // 不可用标记
              if (!item.hasQuality) {
                Text('不可用')
                  .fontSize(12)
                  .fontColor('#CCCCCC')
              }

              // 当前音质标记
              if (item.isCurrent) {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#6200EE')
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .height(52)
            .padding({ left: 20, right: 20 })
            .alignItems(VerticalAlign.Center)
            .borderRadius(8)
            .backgroundColor(item.isCurrent ? '#F3E8FF' : Color.Transparent)
            .onClick(() => {
              if (this.model.changeQuality(item.quality)) {
                this.qualitySheetVisible = false
              }
            })
          }
        }, (item: QualityItem) => `${item.quality}`)
      }
      .width('100%')
      .constraintSize({ maxHeight: 400 })
      .padding({ bottom: 24 })
    }
    .width('100%')
  }

}

@Builder
export function MusicTestPageBuilder(params: Object) {
  MusicTestPage()
}