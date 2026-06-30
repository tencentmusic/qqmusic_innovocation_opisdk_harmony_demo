import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { ISearchFolder, IFolder, OpenApiResponse } from "@qqmusic/opisdk-entity";

@ObservedV2
export class SearchFolderModel {
  @Trace searchFolderList: IFolder[] = [];
  hasMore: boolean = false;
  nextPage: number = 0;
  keyword: string = '';

  clear() {
    this.searchFolderList = [];
    this.nextPage = 0;
    this.keyword = '';
    this.hasMore = false;
  }

  searchFolder(key: string) {
    this.clear();
    this.keyword = key;
    this.loadMore();
  }

  loadMore() {
    if (this.nextPage > 0 && !this.hasMore) {
      return;
    }
    OpenApiSdk.openApi?.searchApi.searchFolder(this.keyword, this.nextPage).then((res: OpenApiResponse<ISearchFolder>) => {
      if (res.isSuccess() && res.data) {
        const folderList = res.data.getFolderList();
        if (folderList?.length && folderList.length > 0) {
          this.searchFolderList.push(...folderList);
          this.nextPage++;
          this.hasMore = res.hasMore;
        }
      }
    })
  }
}
