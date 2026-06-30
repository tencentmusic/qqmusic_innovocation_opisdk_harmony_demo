import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { ISongInfo } from '@qqmusic/opisdk-qmutils';
import { ToastUtil } from '../../utils/ToastUtil';

@ComponentV2
export struct VoicedSongCollectListItem {
  @Param @Require song: ISongInfo;
  @Local isCollect: boolean = false;
  @Param @Require index: number;

  aboutToAppear(): void {
    this.isCollect = OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.isCollected(this.song) ?? false;
  }

  build() {
    Row() {
      Row() {
        Image(this.song.smallCoverUrl() || $r('app.media.logo'))
          .width(60)
          .aspectRatio(1)
          .borderRadius(4)
          .backgroundColor('#E0E0E0')
          .objectFit(ImageFit.Cover)
        Blank().width(10)
        Column() {
          Text(this.song.getSongName())
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor('#333333')
          Blank().height(5)
          Text(this.song.getSingerName() || 'null')
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)

      Row() {
        Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .width(24)
          .aspectRatio(1)
          .objectFit(ImageFit.Contain)
          .onClick(async () => {
            this.isCollect = !this.isCollect;
            OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.setCollectOrCancel(this.isCollect, this.song);
            this.isCollect = OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.isCollected(this.song) ?? false;
          })
        
        Blank().width(20)

        Column() {
          Text('添加下一曲').fontSize(12).fontColor('#D134B6')
            .onClick(() => {
              if (this.song) {
                this.addToNext(this.song)
                ToastUtil.show('已添加到下一曲')
              }
            })

          Blank().height(5)
          Text('添加末尾').fontSize(12).fontColor('#D134B6')
            .onClick(() => {
              if (this.song) {
                this.appendToPlaylist(this.song)
                ToastUtil.show('已添加到末尾')
              }
            })
          Blank().height(5)
          Text('详情').fontSize(12).fontColor('#D134B6')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.End)
      }
      .padding({ right: 16 })
    }
    .onClick(async () => {
      let songs = OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.getData().list;
      if (songs == undefined) {
        return
      }
      OpenApiSdk.playerApi?.playSongsWithPos(songs, this.index)
    })
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16 })
    .backgroundColor(Color.White)
  }


  /**
   * 添加歌曲到下一曲
   */
  addToNext(song: ISongInfo): void {
    OpenApiSdk.playerApi?.addToNext(true, song) ?? -1

  }

  /**
   * 添加歌曲到播放列表末尾
   */
  appendToPlaylist(song: ISongInfo): void {
    OpenApiSdk.playerApi?.appendSongToPlaylist([song]) ?? -1
  }
}
