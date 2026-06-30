import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ISongListItem } from '@qqmusic/opisdk-entity'

const TAG = 'CustomSongListViewModel'

@ObservedV2
export class CustomSongListViewModel {
  @Trace squares: ISongListItem[] = []
  @Trace isLoading: boolean = false

  /**
   * 获取合作方运营歌单广场数据
   */
  async fetchSongListSquare(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.folderApi.fetchCustomSongListSquare()
      if (resp && resp.isSuccess() && resp.data) {
        this.squares = resp.data
        MLog.i(TAG, `fetchSongListSquare success, count: ${this.squares.length}`)
      } else {
        MLog.w(TAG, `fetchSongListSquare failed: ${resp?.errorMsg}`)
        this.squares = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchSongListSquare error: ${JSON.stringify(e)}`)
      this.squares = []
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 获取 item 类型的中文描述
   */
  getTypeLabel(type: number | null): string {
    if (type === 1) {
      return '榜单'
    } else if (type === 2) {
      return '歌单'
    }
    return '未知'
  }
}
