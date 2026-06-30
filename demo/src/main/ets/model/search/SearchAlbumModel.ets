import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchAlbum, IAlbum, OpenApiResponse } from "@qqmusic/opisdk-entity";

@ObservedV2
export class SearchAlbumModel {
  @Trace searchAlbumList: IAlbum[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';

  clear() {
    this.searchAlbumList = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchAlbum(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchAlbum(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchAlbum>) => {
      if (res.isSuccess() && res.data) {
        const albumList = res.data.getAlbumList();
        if (albumList?.length && albumList.length > 0) {
          this.searchAlbumList.push(...albumList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}
