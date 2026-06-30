import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ISongInfo } from '@qqmusic/opisdk-qmutils'

const TAG = 'RankDetailViewModel'

@ObservedV2
export class RankDetailViewModel {
  @Trace public songList: ISongInfo[] = []
  @Trace public isLoading: boolean = false
  @Trace public rankName: string = ''
  @Trace public hasMore: boolean = true
  public rankId: number = 0
  public page: number = 0
  public readonly pageSize: number = 30

  async loadData(isLoadMore: boolean = false) {
    if (this.isLoading) {
      return
    }
    if (!isLoadMore) {
      this.page = 0
      this.songList = []
      this.hasMore = true
    } else if (!this.hasMore) {
      return
    }

    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.rankApi.fetchSongOfRank(
        this.rankId,
        this.page,
        this.pageSize
      )
      if (resp && resp.isSuccess() && resp.data) {
        const list = resp.data
        if (isLoadMore) {
          this.songList = this.songList.concat(list)
        } else {
          this.songList = list
        }
        this.hasMore = resp.hasMore ?? false
        this.page++
        MLog.i(TAG, `loadData success, page: ${this.page - 1}, count: ${list.length}`)
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
