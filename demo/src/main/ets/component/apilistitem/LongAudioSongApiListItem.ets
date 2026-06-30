import { IObserver, MLog, OpenApiSdk } from "@qqmusic/opisdk-base"
import { LoadType } from "@qqmusic/opisdk-entity"
import { ISongInfo, PlayError, ToastUtils } from "@qqmusic/opisdk-qmutils"
import { ToastUtil } from "../../utils/ToastUtil"
import { HomeViewModel } from "../../viewmodel/HomeViewModel"

@ComponentV2
export struct LongAudioSongApiListItem {
  @Param @Require song: ISongInfo
  @Param @Require index: number
  /** 播放列表数据源（由调用方传入，确保 index 与列表对应） */
  @Param songList: ISongInfo[] = []
  /** 取消收藏后的回调 */
  @Event onUncollect?: (songId: number) => void;
  @Local isCollect: boolean = false
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();

  aboutToAppear(): void {
    // API 模式下，收藏列表中的歌曲默认都是已收藏状态
    this.isCollect = true;
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
            OpenApiSdk.openApi?.longAudioApi.collectLongAudioSong(!this.isCollect, [this.song.getSongId()], 1)
              .then((resp) => {
                if (resp.isSuccess()) {
                  ToastUtils.showToastContent(this.isCollect ? '取消收藏成功' : '收藏成功');
                  this.isCollect = !this.isCollect;
                  if (!this.isCollect && this.onUncollect) {
                    this.onUncollect(this.song.getSongId());
                  }
                } else {
                  ToastUtils.showToastContent(`code=${resp.ret},msg=${resp.errorMsg}`);
                  MLog.e("LongAudioSongCollectListItem", `del resp: code=${resp.ret},msg=${resp.errorMsg}`);
                }
              })
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
    .onClick(async () => {
      const data = this.songList.length > 0 ? this.songList : this.homeViewModel.collectedVoicedSongList
      OpenApiSdk.openApi?.songApi.refreshSongInfoBatch(data)
        .then((res) => {
          if (res.isSuccess() && res.data) {
            MLog.i('LongAudioSongApiListItem', `res.data=${JSON.stringify(res.data)}`)
            const result = OpenApiSdk.playerApi?.playSongsWithPos(res.data, this.index)
            MLog.i('LongAudioSongApiListItem', `res=${JSON.stringify(result)}`)
            if (result !== PlayError.PLAY_ERR_NONE) {
              ToastUtil.show(`播放出错。原因：${res.data[this.index].getUnplayableMsg()}`);
            }
          } else {
            ToastUtil.show(`code=${res.ret},msg=${res.errorMsg}`);
            MLog.e("LongAudioSongApiListItem", `refresh resp: code=${res.ret},msg=${res.errorMsg}`);
          }
        })
    })
  }
}