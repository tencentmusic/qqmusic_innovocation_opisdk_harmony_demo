import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { IAlbum } from '@qqmusic/opisdk-entity'

const TAG = 'AlbumListViewModel'

/**
 * 专辑列表页 ViewModel
 * 对应安卓 AlbumActivity + AlbumViewModel
 * 展示单个专辑信息（含收藏状态），点击后跳转专辑详情页
 */
@ObservedV2
export class AlbumListViewModel {
  @Trace public album: IAlbum | null = null
  @Trace public isLoading: boolean = false
  @Trace public isAlbumCollected: boolean = false
  @Trace public isTogglingCollect: boolean = false
  public albumId: number = 0
  public albumName: string = ''

  async fetchAlbumDetail(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.albumApi.fetchAlbumDetail(this.albumId)
      if (resp && resp.isSuccess() && resp.data) {
        this.album = resp.data
        this.albumName = resp.data.getName()
        this.isAlbumCollected = resp.data.getFavState() === 1
        MLog.i(TAG, `fetchAlbumDetail success: ${this.albumName}, favState: ${resp.data.getFavState()}`)
      } else {
        MLog.w(TAG, `fetchAlbumDetail failed: ${resp?.errorMsg}`)
        this.album = null
      }
    } catch (e) {
      MLog.e(TAG, `fetchAlbumDetail error: ${JSON.stringify(e)}`)
      this.album = null
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 切换专辑收藏状态
   */
  async toggleAlbumCollect(): Promise<void> {
    if (this.isTogglingCollect || this.album === null) {
      return
    }
    this.isTogglingCollect = true
    try {
      const newCollectState = !this.isAlbumCollected
      const resp = await OpenApiSdk.openApi?.albumApi.collectAlbum(newCollectState, [this.albumId])
      if (resp && resp.isSuccess()) {
        this.isAlbumCollected = newCollectState
        MLog.i(TAG, `toggleAlbumCollect success, isCollected: ${this.isAlbumCollected}`)
      } else {
        MLog.w(TAG, `toggleAlbumCollect failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `toggleAlbumCollect error: ${JSON.stringify(e)}`)
    } finally {
      this.isTogglingCollect = false
    }
  }
}