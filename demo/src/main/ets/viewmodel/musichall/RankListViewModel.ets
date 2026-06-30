import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { IRank, IRankGroup } from '@qqmusic/opisdk-entity'

const TAG = 'RankListViewModel'

@ObservedV2
export class RankListViewModel {
  @Trace public rankGroups: IRankGroup[] = []
  @Trace public isLoading: boolean = false

  async loadData() {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.rankApi.fetchAllRankGroup()
      if (resp && resp.isSuccess() && resp.data) {
        this.rankGroups = resp.data
        MLog.i(TAG, `loadData success, groups: ${this.rankGroups.length}`)
      } else {
        MLog.w(TAG, `loadData failed: ${resp?.errorMsg}`)
        this.rankGroups = []
      }
    } catch (e) {
      MLog.e(TAG, `loadData error: ${JSON.stringify(e)}`)
      this.rankGroups = []
    } finally {
      this.isLoading = false
    }
  }
}
