import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchSong, OpenApiResponse } from "@qqmusic/opisdk-entity";
import { SongListViewModel } from "../../viewmodel/songlist/SongListViewModel";

@ObservedV2
export class SearchSongModel {
  @Trace songListViewModel: SongListViewModel = new SongListViewModel();
  @Trace isLike: boolean[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';
  /** 监听歌曲收藏状态 */

  constructor() {
    this.songListViewModel.registerPlayEventListener();
  }

  clear() {
    this.songListViewModel.songList = [];
    this.isLike = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchSong(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchSong(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchSong>) => {
      if (res.isSuccess() && res.data) {
        const songList = res.data.getSongList();
        if (songList?.length && songList.length > 0) {
          this.songListViewModel.songList.push(...songList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}