import { IObserver, MLog, OpenApiSdk } from "@qqmusic/opisdk-base"
import { LoadType } from "@qqmusic/opisdk-entity"

import { ISongInfo } from "@qqmusic/opisdk-qmutils";
import { SongInfo } from "@qqmusic/opisdk-openapi"
import { RouteName } from "../../nav/RouteMap";
import { SongProfilePageParams } from "../../nav/RouteParams";
import { SongProfileCache } from "../../pages/songprofile/SongProfileCache";
import { NavController } from "../../nav/NavController";
import { ToastUtil } from "../../utils/ToastUtil";

@ComponentV2
export struct SongCollectListItem {
  @Param @Require song: ISongInfo
  @Param @Require index: number
  // 观察者对象
  private observer?: IObserver<LoadType>
  @Local isCollect: boolean = false
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    this.observer = {
      update: (_: LoadType) => {
        this.isCollect =
          OpenApiSdk.personalAssetsApi?.songFavApi.isCollectedById(this.song.getSongId().toString()) ?? false;
      }
    }

    OpenApiSdk.personalAssetsApi?.songFavApi.register(LoadType.SONG, this.observer)

    this.isCollect =
      OpenApiSdk.personalAssetsApi?.songFavApi.isCollectedById(this.song.getSongId().toString()) ?? false;
  }

  aboutToDisappear(): void {
    OpenApiSdk.personalAssetsApi?.songFavApi.unregister(LoadType.SONG, this.observer)
  }

  build() {
    Row() {
      Row() {
        Image(this.song.getAlbumPic()).width(60).aspectRatio(1)
        Blank().width(10)
        Column() {
          Text(this.song.getSongName()).fontSize(15).fontWeight(FontWeight.Bold)
          Blank().height(5)
          Text(this.allSingerName).fontSize(12)
        }.layoutWeight(1).height(60).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start)
      }.width('60%')

      Row() {
        Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .width(24).aspectRatio(1)
          .onClick(() => {
            OpenApiSdk.personalAssetsApi?.songFavApi.setCollectOrCancel(!this.isCollect, this.song)
          })
        Blank().width(30)
        Column() {
          Text('添加下一曲').fontSize(15).fontColor('#D134B6')
            .onClick(() => {
              if (this.song) {
                this.addToNext(this.song)
                ToastUtil.show('已添加到下一曲')
              }
            })
          Blank().height(5)
          Text('添加末尾').fontSize(15).fontColor('#D134B6')
            .onClick(() => {
              if (this.song) {
                this.appendToPlaylist(this.song)
                ToastUtil.show('已添加到末尾')
              }
            })
          Blank().height(5)
          Text('详情').fontSize(15).fontColor('#D134B6')
            .onClick(() => {
              // 跳转到歌曲详情页
              if (this.song) {
                // 将完整的 ISongInfo 对象缓存到全局单例，供详情页直接使用
                SongProfileCache.getInstance().setSong(this.song)
                const params = new SongProfilePageParams(
                  this.song.getSongId(),
                  this.song.getSongMid() ?? '',
                  this.song.getSongName() ?? '',
                  this.song.getSingerName() ?? '',
                  this.song.getAlbumName() ?? '',
                  this.song.getAlbumPic300x300() ?? this.song.smallCoverUrl() ?? '',
                  this.song instanceof SongInfo ? JSON.stringify(this.song) : ''
                )
                this.navController.push(RouteName.SONG_PROFILE_PAGE, params)
              }
          })
        }.height(60).justifyContent(FlexAlign.Start)
      }.width('40%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .onClick(async () => {
      let songs = OpenApiSdk.personalAssetsApi?.songFavApi.getData().list;
      if (songs == undefined) {
        return
      }
      OpenApiSdk.playerApi?.playSongsWithPos(songs, this.index)
      //测试歌曲播放记录
     // AssetsReportManager.getInstance().reportRecentPlay(this.song, 0, this.song.getSongId())
      //测试删除歌曲
      //HistorySongManager.getInstance().delLocalSongInfoRecord([this.song])



      //测试删除长音频
      // HistoryManager.getInstance().delLocalLongAudioRecord([this.song])
      //测试最近播放记录长音频
      //HistoryLongAudioManager.getInstance().reportRecentPlay(this.song, 0, this.song.getSongId())

      //播放器记录歌曲
      // let songs = OpenApiSdk.personalAssetsApi?.songHisApi.getList();
      // if (songs == undefined) {
      //   return
      // }
      // OpenApiSdk.playerApi?.playSongsWithPos(songs, this.index)
    })
  }

  @Computed get
  allSingerName() {
    let singerNameList: string[] = []
    if (this.song.getSingerName()) {
      singerNameList.push(this.song.getSingerName()!)
    }

    let otherSingers = this.song.getOtherSingerList()
    otherSingers.forEach(singer => {
      if (singer.getSingerName()) {
        singerNameList.push(singer.getSingerName())
      }
    })

    return singerNameList.length > 0 ?singerNameList.join('/') : ''
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