import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchLyric, ILyricInfo, OpenApiResponse } from "@qqmusic/opisdk-entity";

@ObservedV2
export class SearchLyricModel {
  @Trace searchLyricInfoList: ILyricInfo[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';

  clear() {
    this.searchLyricInfoList = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchLyric(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchLyric(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchLyric>) => {
      if (res.isSuccess() && res.data) {
        const lyricInfoList = res.data.getLyricInfoList();
        if (lyricInfoList?.length && lyricInfoList.length > 0) {
          this.searchLyricInfoList.push(...lyricInfoList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}
