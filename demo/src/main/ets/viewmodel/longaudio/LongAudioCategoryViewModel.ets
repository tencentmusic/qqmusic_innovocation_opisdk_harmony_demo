import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ICategory, IAlbum } from '@qqmusic/opisdk-entity'
import { Album } from '@qqmusic/opisdk-openapi'

const TAG = 'LongAudioCategoryViewModel'

@ObservedV2
export class LongAudioCategoryViewModel {
  @Trace public categories: ICategory[] = []
  @Trace public filters: ICategory[] = []
  @Trace public albumList: IAlbum[] = []
  @Trace public isLoading: boolean = false
  @Trace public isLoadingCategories: boolean = false
  @Trace public isTogglingCollect: boolean = false
  @Trace public hasMore: boolean = true
  @Trace public tag: string = ''
  @Trace public categoryId: number = 0
  @Trace public subCategoryId: number = 0
  @Trace public currentCategoryIndex: number = 0
  @Trace public currentSubCategoryIndex: number = 0
  @Trace public currentFilterIndex: number = 0
  @Trace public sortType: number = 0
  public page: number = 0
  public readonly pageSize: number = 20
  /** jumpInfo 中的 intArrVal，用于匹配初始 Tab 索引 */
  public intArrVal: number[] | null = null

  get currentSubCategories(): ICategory[] {
    if (this.categories.length === 0) {
      return []
    }
    return this.categories[this.currentCategoryIndex]?.subCategory ?? []
  }

  /**
   * 根据 intArrVal 或 tag 定位初始 Tab 索引
   * 优先用 tag 匹配分类名，其次用 intArrVal[0] 匹配一级分类 id，intArrVal[1] 匹配二级分类 id
   */
  private locateInitialTab(): void {
    // 优先用 tag 匹配分类名
    if (this.tag) {
      for (let i = 0; i < this.categories.length; i++) {
        const cat = this.categories[i]
        if (cat.name === this.tag) {
          this.currentCategoryIndex = i
          this.categoryId = cat.id
          this.subCategoryId = 0
          this.currentSubCategoryIndex = 0
          return
        }
        // 也尝试匹配二级分类名
        if (cat.subCategory) {
          for (let j = 0; j < cat.subCategory.length; j++) {
            if (cat.subCategory[j].name === this.tag) {
              this.currentCategoryIndex = i
              this.categoryId = cat.id
              this.subCategoryId = cat.subCategory[j].id
              this.currentSubCategoryIndex = j
              return
            }
          }
        }
      }
    }

    // 回退到 intArrVal 匹配
    if (!this.intArrVal || this.intArrVal.length === 0) {
      return
    }
    const targetFirstId = this.intArrVal[0]
    const targetSecondId = this.intArrVal.length > 1 ? this.intArrVal[1] : undefined

    for (let i = 0; i < this.categories.length; i++) {
      const cat = this.categories[i]
      if (cat.id === targetFirstId) {
        this.currentCategoryIndex = i
        if (targetSecondId !== undefined && targetSecondId !== 0 && cat.subCategory) {
          for (let j = 0; j < cat.subCategory.length; j++) {
            if (cat.subCategory[j].id === targetSecondId) {
              this.categoryId = cat.id
              this.subCategoryId = cat.subCategory[j].id
              this.currentSubCategoryIndex = j
              return
            }
          }
        }
        this.categoryId = cat.id
        this.subCategoryId = 0
        this.currentSubCategoryIndex = 0
        return
      }
    }
  }

  async fetchCategories(): Promise<void> {
    if (this.isLoadingCategories) {
      return
    }
    this.isLoadingCategories = true
    try {
      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfLongAudio()
      if (resp && resp.isSuccess() && resp.data) {
        this.categories = resp.data
        MLog.i(TAG, `fetchCategories success, count: ${this.categories.length}`)
        // 根据 tag 或 intArrVal 定位初始 Tab，更新 categoryId/subCategoryId
        this.locateInitialTab()
        // 定位完成后触发后续请求
        this.fetchFilters()
        this.loadData()
      } else {
        this.categories = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchCategories error: ${JSON.stringify(e)}`)
      this.categories = []
    } finally {
      this.isLoadingCategories = false
    }
  }

  async fetchFilters(): Promise<void> {
    if (this.categoryId <= 0) {
      return
    }
    try {
      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchCategoryFilterOfLongAudio([this.categoryId, this.subCategoryId])
      if (resp && resp.isSuccess() && resp.data) {
        this.filters = resp.data
        MLog.i(TAG, `fetchFilters success, count: ${this.filters.length}`)
      } else {
        this.filters = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchFilters error: ${JSON.stringify(e)}`)
      this.filters = []
    }
  }

  async loadData(isLoadMore: boolean = false): Promise<void> {
    if (this.isLoading) {
      return
    }
    if (!isLoadMore) {
      this.page = 0
      this.albumList = []
      this.hasMore = true
    } else if (!this.hasMore) {
      return
    }

    this.isLoading = true
    try {
      const filterIdList: number[] = this.filters.length > 0 && this.currentFilterIndex >= 0
        ? [this.filters[this.currentFilterIndex]?.id ?? -1, -1]
        : [-1, -1]

      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfLongAudioByCategory(
        [this.categoryId, this.subCategoryId],
        filterIdList,
        this.page,
        this.pageSize,
        this.sortType
      )
      if (resp && resp.isSuccess() && resp.data) {
        const list = resp.data
        if (isLoadMore) {
          this.albumList = this.albumList.concat(list)
        } else {
          this.albumList = list
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

  selectCategory(index: number): void {
    if (index === this.currentCategoryIndex) {
      return
    }
    const cat = this.categories[index]
    if (!cat) {
      return
    }
    this.currentCategoryIndex = index
    this.currentSubCategoryIndex = 0
    this.categoryId = cat.id
    this.subCategoryId = 0
    this.currentFilterIndex = 0
    this.fetchFilters()
    this.loadData()
  }

  selectSubCategory(index: number): void {
    if (index === this.currentSubCategoryIndex) {
      return
    }
    const subCat = this.currentSubCategories[index]
    if (!subCat) {
      return
    }
    this.currentSubCategoryIndex = index
    this.subCategoryId = subCat.id
    this.currentFilterIndex = 0
    this.fetchFilters()
    this.loadData()
  }

  selectFilter(index: number): void {
    this.currentFilterIndex = index
    this.loadData()
  }

  toggleSortType(): void {
    this.sortType = this.sortType === 0 ? 1 : 0
    this.loadData()
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
}
