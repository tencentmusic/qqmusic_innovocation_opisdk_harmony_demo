import { IObserver, MLog, OpenApiSdk } from "@qqmusic/opisdk-base"
import { LoadType } from "@qqmusic/opisdk-entity"
import { ISongInfo, PlayError } from "@qqmusic/opisdk-qmutils"
import { ToastUtil } from "../../utils/ToastUtil"

@ComponentV2
export struct LongAudioSongListItem {
  @Param @Require song: ISongInfo
  @Param @Require index: number
  // 观察者对象
  private observer?: IObserver<LoadType>
  @Local isCollect: boolean = false

  aboutToAppear(): void {
    this.observer = {
      update: (_: LoadType) => {
        this.isCollect =
          OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.isCollectedById(this.song.getSongId().toString()) ?? false;
      }
    }

    OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.register(LoadType.SONG, this.observer)

    this.isCollect =
      OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.isCollectedById(this.song.getSongId().toString()) ?? false;
  }

  aboutToDisappear(): void {
    OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.unregister(LoadType.SONG, this.observer)
  }

  build() {
    Row() {
      Row() {
        Image(this.song.getAlbumPic()).width(60).aspectRatio(1)
        Blank().width(10)
        Column() {
          Text(this.song.getSongName()).fontSize(15).fontWeight(FontWeight.Bold)
          Blank().height(5)
          Text(this.song.getSingerName()).fontSize(12)
        }.height(60).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start)
      }

      Row() {
        Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .width(24).aspectRatio(1)
          .onClick(() => {
            OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.setCollectOrCancel(!this.isCollect, this.song)
          })
        Blank().width(30)
        Column() {
          Text('添加下一曲').fontSize(15).fontColor('#D134B6')
          Blank().height(5)
          Text('添加末尾').fontSize(15).fontColor('#D134B6')
          Blank().height(5)
          Text('详情').fontSize(15).fontColor('#D134B6')
        }.height(60).justifyContent(FlexAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      let songs = OpenApiSdk.personalAssetsApi?.longAudioHisApi.getData().list;
      if (songs == undefined) {
        return
      }
      OpenApiSdk.openApi?.songApi.refreshSongInfoBatch(songs)
        .then((res) => {
          if (res.isSuccess() && res.data) {
            MLog.i('LongAudioSongListItem', `refreshSongInfoBatch, res.data:${JSON.stringify(res.data)}`);
            const result = OpenApiSdk.playerApi?.playSongsWithPos(res.data, this.index);
            MLog.i('LongAudioSongListItem', `playSongsWithPos, res:${result}`);
            if (result !== PlayError.PLAY_ERR_NONE) {
              ToastUtil.show(`播放出错。原因：${res.data[this.index].getUnplayableMsg()}`);
            }
          } else {
            ToastUtil.show(`code:${res.ret},msg:${res.errorMsg}`);
            MLog.i('LongAudioSongListItem', `refreshSongInfoBatch, res:${JSON.stringify(res)}`);
          }
        })
    })
  }
}