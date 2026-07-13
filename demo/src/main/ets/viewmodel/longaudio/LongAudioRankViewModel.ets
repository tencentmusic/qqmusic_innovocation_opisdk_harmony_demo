import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ICategory, IAlbum } from '@qqmusic/opisdk-entity'
import { Album } from '@qqmusic/opisdk-openapi'

const TAG = 'LongAudioRankViewModel'

@ObservedV2
export class LongAudioRankViewModel {
  @Trace public rankCategories: ICategory[] = []
  @Trace public albumList: IAlbum[] = []
  @Trace public isLoading: boolean = false
  @Trace public isTogglingCollect: boolean = false
  @Trace public tag: string = ''
  @Trace public currentTopIndex: number = 0
  @Trace public currentSubIndex: number = 0
  @Trace public isAllLoaded: boolean = false
  @Trace public showAllLoadedTip: boolean = false

  get topCategories(): ICategory[] {
    return this.rankCategories
  }

  get currentSubCategories(): ICategory[] {
    if (this.topCategories.length === 0) {
      return []
    }
    return this.topCategories[this.currentTopIndex]?.subCategory ?? []
  }

  /**
   * 根据 tag 定位初始 Tab 索引
   */
  private locateInitialTabByTag(): void {
    if (!this.tag) {
      return
    }
    // 先在一级分类中匹配
    for (let i = 0; i < this.rankCategories.length; i++) {
      const topCat = this.rankCategories[i]
      if (topCat.name === this.tag) {
        this.currentTopIndex = i
        this.currentSubIndex = 0
        return
      }
      // 再在二级分类中匹配
      const subList = topCat.subCategory ?? []
      for (let j = 0; j < subList.length; j++) {
        if (subList[j].name === this.tag) {
          this.currentTopIndex = i
          this.currentSubIndex = j
          return
        }
      }
    }
  }

  async fetchRankCategories(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfRankLongAudio()
      if (resp && resp.isSuccess() && resp.data) {
        this.rankCategories = resp.data
        MLog.i(TAG, `fetchRankCategories success, count: ${this.rankCategories.length}`)
        if (this.rankCategories.length > 0) {
          // 根据 tag 定位初始 Tab
          this.locateInitialTabByTag()
          await this.fetchAlbumList()
        }
      } else {
        MLog.w(TAG, `fetchRankCategories failed: ${resp?.errorMsg}`)
        this.rankCategories = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchRankCategories error: ${JSON.stringify(e)}`)
      this.rankCategories = []
    } finally {
      this.isLoading = false
    }
  }

  async fetchAlbumList(): Promise<void> {
    const topId = this.topCategories[this.currentTopIndex]?.id ?? 0
    const subId = this.currentSubCategories[this.currentSubIndex]?.id ?? 0
    if (topId <= 0) {
      return
    }
    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfRankLongAudioByCategory([topId, subId])
      if (resp && resp.isSuccess() && resp.data) {
        this.albumList = resp.data
        this.isAllLoaded = true
        MLog.i(TAG, `fetchAlbumList success, count: ${this.albumList.length}`)
      } else {
        MLog.w(TAG, `fetchAlbumList failed: ${resp?.errorMsg}`)
        this.albumList = []
        this.isAllLoaded = false
      }
    } catch (e) {
      MLog.e(TAG, `fetchAlbumList error: ${JSON.stringify(e)}`)
      this.albumList = []
      this.isAllLoaded = false
    } finally {
      this.isLoading = false
    }
  }

  selectTopCategory(index: number): void {
    this.currentTopIndex = index
    this.currentSubIndex = 0
    this.fetchAlbumList()
  }

  selectSubCategory(index: number): void {
    this.currentSubIndex = index
    this.showAllLoadedTip = false
    this.fetchAlbumList()
  }

  /**
   * 切换专辑收藏状态
   * @param album 要切换收藏的专辑
   * @param index 专辑在 albumList 中的索引，用于替换元素触发 UI 刷新
   */
  async toggleAlbumCollect(album: IAlbum, index: number): Promise<void> {
    if (this.isTogglingCollect) {
      return
    }
    this.isTogglingCollect = true
    try {
      const newCollectState = album.getFavState() !== 1
      const resp = await OpenApiSdk.openApi?.albumApi.collectAlbum(newCollectState, [album.getId()])
      if (resp && resp.isSuccess()) {
        // 同步更新 album 对象的 favState
        if (album instanceof Album) {
          const typedAlbum: Album = album as Album
          typedAlbum.setFavState(newCollectState ? 1 : 0)
        }
        MLog.i(TAG, `toggleAlbumCollect success, isCollected: ${newCollectState}`)
      } else {
        MLog.w(TAG, `toggleAlbumCollect failed: ${resp?.errorMsg}`)
        // 接口失败时，通过替换数组触发 @Monitor 回滚 isCollected
        const newList: IAlbum[] = [...this.albumList]
        this.albumList = newList
      }
    } catch (e) {
      MLog.e(TAG, `toggleAlbumCollect error: ${JSON.stringify(e)}`)
      // 异常时同样触发回滚
      const newList: IAlbum[] = [...this.albumList]
      this.albumList = newList
    } finally {
      this.isTogglingCollect = false
    }
  }

  /**
   * 列表滚动到底部时调用，显示"已全部加载"提示
   */
  onReachListEnd(): void {
    if (this.isAllLoaded && this.albumList.length > 0) {
      this.showAllLoadedTip = true
    }
  }
}
