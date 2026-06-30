import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ICategory } from '@qqmusic/opisdk-entity'
import { IArea, IAreaShelf } from "@qqmusic/opisdk-entity"


const TAG = 'LongAudioHomeViewModel'

@ObservedV2
export class LongAudioHomeViewModel {
  // 一级品类列表
  @Trace public categories: ICategory[] = []
  // 当前选中的一级品类索引
  @Trace public currentCategoryIndex: number = 0
  // 当前选中的二级子分类索引
  @Trace public currentSubCategoryIndex: number = 0
  // 当前品类详情（Area 含 shelves）
  @Trace public currentArea: IArea | null = null
  // 加载状态
  @Trace public isLoadingCategories: boolean = false
  @Trace public isLoadingDetail: boolean = false

  private get currentCategory(): ICategory | null {
    if (this.categories.length === 0) {
      return null
    }
    return this.categories[this.currentCategoryIndex] ?? null
  }

  get currentSubCategories(): ICategory[] {
    return this.currentCategory?.subCategory ?? []
  }

  get currentCategoryId(): number {
    return this.currentCategory?.id ?? 0
  }

  get currentSubCategoryId(): number {
    const subList = this.currentSubCategories
    if (subList.length === 0) {
      return 0
    }
    return subList[this.currentSubCategoryIndex]?.id ?? 0
  }

  get shelves(): IAreaShelf[] {
    return this.currentArea?.getShelves() ?? []
  }

  async fetchCategories(): Promise<void> {
    if (this.isLoadingCategories) {
      return
    }
    this.isLoadingCategories = true
    try {
      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageOfLongAudio()
      if (resp && resp.isSuccess() && resp.data) {
        this.categories = resp.data
        MLog.i(TAG, `fetchCategories success, count: ${this.categories.length}`)
        // 加载第一个品类的详情
        if (this.categories.length > 0) {
          this.currentCategoryIndex = 0
          this.currentSubCategoryIndex = 0
          this.fetchCategoryDetail()
        }
      } else {
        MLog.w(TAG, `fetchCategories failed: ${resp?.errorMsg}`)
        this.categories = []
      }
    } catch (e) {
      MLog.e(TAG, `fetchCategories error: ${JSON.stringify(e)}`)
      this.categories = []
    } finally {
      this.isLoadingCategories = false
    }
  }

  async fetchCategoryDetail(): Promise<void> {
    if (this.isLoadingDetail) {
      return
    }
    const categoryId = this.currentCategoryId
    const subCategoryId = this.currentSubCategoryId
    if (categoryId <= 0) {
      return
    }
    this.isLoadingDetail = true
    try {
      const resp = await OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageDetailOfLongAudio(
        categoryId, subCategoryId, 0
      )
      if (resp && resp.isSuccess() && resp.data) {
        this.currentArea = resp.data
        MLog.i(TAG, `fetchCategoryDetail success, shelves: ${this.currentArea?.getShelves()?.length ?? 0}`)
      } else {
        MLog.w(TAG, `fetchCategoryDetail failed: ${resp?.errorMsg}`)
        this.currentArea = null
      }
    } catch (e) {
      MLog.e(TAG, `fetchCategoryDetail error: ${JSON.stringify(e)}`)
      this.currentArea = null
    } finally {
      this.isLoadingDetail = false
    }
  }

  selectCategory(index: number): void {
    if (index === this.currentCategoryIndex) {
      return
    }
    this.currentCategoryIndex = index
    this.currentSubCategoryIndex = 0
    this.fetchCategoryDetail()
  }

  selectSubCategory(index: number): void {
    if (index === this.currentSubCategoryIndex) {
      return
    }
    this.currentSubCategoryIndex = index
    this.fetchCategoryDetail()
  }
}