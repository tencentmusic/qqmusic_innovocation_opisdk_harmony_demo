import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchMV, ISearchMVInfo, OpenApiResponse } from "@qqmusic/opisdk-entity";

@ObservedV2
export class SearchMVModel {
  @Trace searchMVInfoList: ISearchMVInfo[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';

  clear() {
    this.searchMVInfoList = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchMV(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchMV(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchMV>) => {
      if (res.isSuccess() && res.data) {
        const mvList = res.data.getMvList();
        if (mvList?.length && mvList.length > 0) {
          this.searchMVInfoList.push(...mvList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}
