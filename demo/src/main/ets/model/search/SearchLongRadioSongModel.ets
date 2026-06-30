import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchSong, ISongInfo, OpenApiResponse } from "@qqmusic/opisdk-entity";

@ObservedV2
export class SearchLongRadioSongModel {
  @Trace searchLongRadioSongList: ISongInfo[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';

  clear() {
    this.searchLongRadioSongList = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchLongRadioSong(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchLongRadioSong(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchSong>) => {
      if (res.isSuccess() && res.data) {
        const longRadioSongList = res.data.getSongList();
        if (longRadioSongList?.length && longRadioSongList.length > 0) {
          this.searchLongRadioSongList.push(...longRadioSongList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}
