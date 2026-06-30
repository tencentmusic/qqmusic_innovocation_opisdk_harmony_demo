import { MLog, OpenApiSdk } from "@qqmusic/opisdk-base"
import { ISongInfo, ToastUtils } from "@qqmusic/opisdk-qmutils";
import { SongInfo } from "@qqmusic/opisdk-openapi";
import { RouteName } from "../../nav/RouteMap";
import { SongProfilePageParams } from "../../nav/RouteParams";
import { SongProfileCache } from "../../pages/songprofile/SongProfileCache";
import { NavController } from "../../nav/NavController";

@ComponentV2
export struct SongApiListItem {
  @Param @Require song: ISongInfo
  @Param @Require index: number
  @Local isCollect: boolean = false
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    this.isCollect = this.song.getHot() === 1
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
            OpenApiSdk.openApi?.folderApi.fetchPersonalFolder().then((folders) => {
              const folder = folders.data?.find((folder) => {
                return folder.getName() === '我喜欢'
              })
              if (folder) {
                const folderId = folder.getId();
                if (this.isCollect) {
                  const idList = [this.song.getSongId()];
                  const midList = [this.song.getSongMid() ?? ""];
                  const typeList = [this.song.getSongType.toString() ?? ""];
                  OpenApiSdk.openApi?.folderApi.deleteSongFromFolder(folderId, idList, midList, typeList)
                    .then((resp) => {
                      if (resp.isSuccess()) {
                        this.isCollect = !this.isCollect;
                      } else {
                        ToastUtils.showToastContent(`code=${resp.ret},msg=${resp.errorMsg}`);
                        MLog.e("SongCollectListItem", `del resp: code=${resp.ret},msg=${resp.errorMsg}`);
                      }
                    });
                } else {
                  OpenApiSdk.openApi?.folderApi.addSongToFolder(folderId, [this.song])
                    .then((resp) => {
                      if (resp.isSuccess()) {
                        this.isCollect = !this.isCollect;
                      } else {
                        ToastUtils.showToastContent(`code=${resp.ret},msg=${resp.errorMsg}`);
                        MLog.e("SongCollectListItem", `add resp: code=${resp.ret},msg=${resp.errorMsg}`);
                      }
                    });
                }
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
      }
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
    })
  }
}