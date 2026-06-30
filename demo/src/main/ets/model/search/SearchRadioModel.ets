import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchAlbum, IAlbum, OpenApiResponse } from "@qqmusic/opisdk-entity";

@ObservedV2
export class SearchRadioModel {
  @Trace searchRadioList: IAlbum[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';

  clear() {
    this.searchRadioList = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchRadio(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchRadio(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchAlbum>) => {
      if (res.isSuccess() && res.data) {
        const radioList = res.data.getAlbumList();
        if (radioList?.length && radioList.length > 0) {
          this.searchRadioList.push(...radioList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}
