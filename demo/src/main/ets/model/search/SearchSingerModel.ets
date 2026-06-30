import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchSinger, OpenApiResponse } from "@qqmusic/opisdk-entity";
import { ISinger } from "@qqmusic/opisdk-qmutils";

@ObservedV2
export class SearchSingerModel {
  @Trace searchSingerList: ISinger[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';

  clear() {
    this.searchSingerList = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchSinger(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchSinger(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchSinger>) => {
      if (res.isSuccess() && res.data) {
        const singerList = res.data.getSingerList();
        if (singerList?.length && singerList.length > 0) {
          this.searchSingerList.push(...singerList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}
