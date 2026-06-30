import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { IFolder } from '@qqmusic/opisdk-entity'

const TAG = 'FolderListViewModel'

@ObservedV2
export class FolderListViewModel {
  @Trace public folderList: IFolder[] = []
  @Trace public isLoading: boolean = false
  @Trace public hasMore: boolean = true
  @Trace public page: number = 0
  public readonly pageSize: number = 20
  public groupId: number = 0
  public labelId: number = 0
  public categoryName: string = ''

  async loadData(isLoadMore: boolean = false) {
    if (this.isLoading) {
      return
    }
    if (!isLoadMore) {
      this.page = 0
      this.folderList = []
      this.hasMore = true
    } else if (!this.hasMore) {
      return
    }

    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.fetchFolderListByCategory(
        [this.groupId, this.labelId],
        this.page,
        this.pageSize
      )
      if (resp && resp.isSuccess() && resp.data) {
        const list = resp.data
        if (isLoadMore) {
          this.folderList = this.folderList.concat(list)
        } else {
          this.folderList = list
        }
        this.hasMore = list.length >= this.pageSize
        this.page++
        MLog.i(TAG, `loadData success, page: ${this.page - 1}, count: ${list.length}`)
      } else {
        MLog.w(TAG, `loadData failed: ${resp?.errorMsg}`)
        if (!isLoadMore) {
          this.folderList = []
        }
        this.hasMore = false
      }
    } catch (e) {
      MLog.e(TAG, `loadData error: ${JSON.stringify(e)}`)
      if (!isLoadMore) {
        this.folderList = []
      }
      this.hasMore = false
    } finally {
      this.isLoading = false
    }
  }
}
