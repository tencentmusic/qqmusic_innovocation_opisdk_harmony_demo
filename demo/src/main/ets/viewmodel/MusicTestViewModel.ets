import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { OpenApiResponse, PlaySpeedType } from "@qqmusic/opisdk-entity";
import { ISongInfo, MusicListType, PlayerEnums } from "@qqmusic/opisdk-qmutils";
import { NavController } from "../nav/NavController";
import { RouteName } from "../nav/RouteMap";
import { MVPlayerPageParams, SongListPageParams } from "../nav/RouteParams";
import { ToastUtil } from "../utils/ToastUtil";

export class MusicTestViewModel{

  getSongList(songListStr: string): Promise<OpenApiResponse<ISongInfo[]>> | undefined {
    const songIds = songListStr.split(',');
    //const songIdList = songIds.map(id => parseInt(id))
    let songIdList: number[] = [];
    let songMidList: string[] = [];
    songIds.forEach((id) => {
      const songId = Number(id);
      if(isNaN(songId)){
        songMidList.push(id);
      } else {
        songIdList.push(songId);
      }
    })
    return OpenApiSdk.openApi?.songApi.fetchSongInfoBatch(songIdList, songMidList);
  }

  play(songListStr: string): void {
    this.getSongList(songListStr)?.then((res) => {
      if(res.isSuccess() && res.data && res.data.length > 0) {
        const randomPos = Math.floor( Math.random() * res.data.length );
        OpenApiSdk.playerApi?.playSongsWithPos(res.data, randomPos);
      } else {
        ToastUtil.show(res.errorMsg);
      }
    });
  }

  playList(songListStr: string): void {
    this.getSongList(songListStr)?.then((res) => {
      if(res.isSuccess() && res.data && res.data.length > 0) {
        OpenApiSdk.playerApi?.setPlayList(res.data, -1);
      } else {
        ToastUtil.show(res.errorMsg);
      }
    });
  }

  addToNext(songListStr: string): void {
    this.getSongList(songListStr)?.then((res) => {
      if(res.isSuccess() && res.data && res.data.length > 0) {
        OpenApiSdk.playerApi?.addToNext(false, ...res.data);
      } else {
        ToastUtil.show(res.errorMsg);
      }
    });
  }

  addToNextAndPlay(songListStr: string): void {
    this.getSongList(songListStr)?.then((res) => {
      if(res.isSuccess() && res.data && res.data.length > 0) {
        OpenApiSdk.playerApi?.addToNext(true, ...res.data);
      } else {
        ToastUtil.show(res.errorMsg);
      }
    });
  }

  searchSongList(songListId: string): void {
    const params = new SongListPageParams(
      MusicListType.TYPE_FOLDER,
      parseInt(songListId),
      ''
    );
    NavController.getInstance().push(RouteName.SONG_LIST_PAGE, params);
  }

  addSongListToPlayList(songFolderIdStr: string): void {
    let hasMore = true;
    let page = 0;
    const folderId: number = parseInt(songFolderIdStr);
    let songList: ISongInfo[] = [];
    while (hasMore) {
      OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(folderId, page, 50).then((res) => {
        if (res.isSuccess() && res.data && res.data.length > 0) {
          songList = songList.concat(res.data);
          hasMore = res.hasMore;
        } else {
          hasMore = false;
        }
      });
    }
    if (songList.length > 0) {
      OpenApiSdk.playerApi?.appendSongToPlaylist(songList);
    }
  }

  updatePlayList(songFolderIdStr: string): void {
    let hasMore = true;
    let page = 0;
    const folderId: number = parseInt(songFolderIdStr);
    let songList: ISongInfo[] = [];
    while (hasMore) {
      OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(folderId, page, 50).then((res) => {
        if (res.isSuccess() && res.data && res.data.length > 0) {
          songList = songList.concat(res.data);
          hasMore = res.hasMore;
        } else {
          hasMore = false;
        }
      });
    }
    if (songList.length < 2) {
      ToastUtil.show("请保持列表数大于1个");
      return;
    } else {
      OpenApiSdk.playerApi?.updatePlayList(songList);
    }
  }

  searchAlbum(songFolderIdStr: string): void {
    const params = new SongListPageParams(
      MusicListType.TYPE_ALBUM,
      parseInt(songFolderIdStr),
      ''
    );
    NavController.getInstance().push(RouteName.SONG_LIST_PAGE, params);
  }

  initPlayerEnv() {
    OpenApiSdk.playerApi?.setPreferSongQuality(PlayerEnums.Quality.STANDARD);
    OpenApiSdk.playerApi?.setCurrentPlaySongQuality(PlayerEnums.Quality.STANDARD);
    OpenApiSdk.playerApi?.setSoundEffectType(null);
    OpenApiSdk.playerApi?.clearPlayList();

    ToastUtil.show("恢复完成");
  }

  testMV(mvIdStr: string) {
    const mvParams = new MVPlayerPageParams(mvIdStr, null);
    NavController.getInstance().push(RouteName.MV_PLAYER_PAGE, mvParams)
  }

  stopPlay() {
    OpenApiSdk.playerApi?.stop();
  }

  fetchSimilarSong(songIdStr: string) {
    let songId: number | null = null;
    let songMid: string | null = null;
    const id = Number(songIdStr);
    if(isNaN(id)){
      songMid = songIdStr
    } else {
      songId = id;
    }
    const hasRecList: ISongInfo[] = OpenApiSdk.playerApi?.getPlayList() ?? [];
    let recList: number[] = [];
    hasRecList.forEach((song) => {
      if (song.getSongId()) {
        recList.push(song.getSongId());
      }
    });
    if (recList.length > 0) {
      OpenApiSdk.openApi?.recommendApi.fetchSimilarSong(songId, songMid, recList).then((res) => {
        if (res.isSuccess()) {
          if (res.data) {
            OpenApiSdk.playerApi?.addToNext(true, ...res.data);
          }
        }
      });
    }
  }
}