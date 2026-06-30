import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { IAreaShelfItem } from "@qqmusic/opisdk-entity"
const TAG = 'LongAudioModuleContentViewModel'

@ObservedV2
export class LongAudioModuleContentViewModel {
  @Trace public shelfItems: IAreaShelfItem[] = []
  @Trace public isLoading: boolean = false
  @Trace public hasMore: boolean = true
  @Trace public shelfTitle: string = ''
  public moduleId: number = 0
  public page: number = 0

  async loadData(isLoadMore: boolean = false): Promise<void> {
    if (this.isLoading) {
      return
    }
    if (!isLoadMore) {
      this.page = 0
      this.shelfItems = []
      this.hasMore = true
    } else if (!this.hasMore) {
      return
    }

    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageModuleContentLongAudio(
        this.moduleId, this.page
      )
      if (resp && resp.isSuccess() && resp.data) {
        const shelf = resp.data
        const items = shelf.getShelfItems() ?? []
        if (isLoadMore) {
          this.shelfItems = this.shelfItems.concat(items)
        } else {
          this.shelfItems = items
        }
        this.hasMore = resp.hasMore ?? false
        this.page++
        MLog.i(TAG, `loadData success, page: ${this.page - 1}, items: ${items.length}`)
      } else {
        MLog.w(TAG, `loadData failed: ${resp?.errorMsg}`)
        this.hasMore = false
      }
    } catch (e) {
      MLog.e(TAG, `loadData error: ${JSON.stringify(e)}`)
      this.hasMore = false
    } finally {
      this.isLoading = false
    }
  }
}