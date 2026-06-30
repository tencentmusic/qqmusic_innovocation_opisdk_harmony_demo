import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { SpecialArea, IMediaSimpleRes, IMediaArea, IMediaGroupRes } from '@qqmusic/opisdk-entity'
const TAG = 'MvAreaViewModel'

/**
 * MV 专区 ViewModel
 * 管理 Dolby 视界 / 4K 臻品 专区数据
 */
@ObservedV2
export class MvAreaViewModel {
  // 专区数据
  @Trace public areaData: IMediaArea | null = null
  // 专区详情列表（二级页面用）
  @Trace public areaDetailList: IMediaGroupRes[] = []
  // 加载状态
  @Trace public isLoading: boolean = false
  @Trace public isLoadingDetail: boolean = false
  // 专区类型
  private specialArea: SpecialArea = SpecialArea.Dolby
  // 当前查看的分组
  @Trace public currentGroupRes: IMediaGroupRes | null = null

  /**
   * 设置专区类型
   */
  setSpecialArea(area: SpecialArea): void {
    this.specialArea = area
  }

  getSpecialArea(): SpecialArea {
    return this.specialArea
  }

  /**
   * 获取专区首页内容
   */
  async fetchContentArea(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.edgeMediaApi?.getContentArea(this.specialArea)
      if (resp && resp.isSuccess() && resp.data) {
        this.areaData = resp.data
        MLog.i(TAG, `fetchContentArea success, specialArea: ${this.specialArea}`)
      } else {
        MLog.w(TAG, `fetchContentArea failed: ${resp?.errorMsg}`)
        this.areaData = null
      }
    } catch (e) {
      MLog.e(TAG, `fetchContentArea error: ${JSON.stringify(e)}`)
      this.areaData = null
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 设置当前分组并加载详情（用于分组标题点击跳转）
   */
  setGroupAndLoadDetail(groupRes: IMediaGroupRes): void {
    this.currentGroupRes = groupRes
    this.fetchAreaDetail(groupRes, null)
  }
  /**
   * 获取专区详情（翻页）
   */
  async fetchAreaDetail(groupRes: IMediaGroupRes, lastItem: IMediaSimpleRes | null): Promise<void> {
    if (this.isLoadingDetail) {
      return
    }
    this.isLoadingDetail = true
    try {
      const resp = await OpenApiSdk.openApi?.edgeMediaApi?.getAreaDetail(
        this.specialArea, groupRes, lastItem, 4
      )
      if (resp && resp.isSuccess() && resp.data) {
        if (lastItem === null) {
          this.areaDetailList = []
        }
        const newData = resp.data
        if (newData) {
          this.areaDetailList.push(newData)
        }
        MLog.i(TAG, `fetchAreaDetail success, count: ${this.areaDetailList.length}`)
      } else {
        MLog.w(TAG, `fetchAreaDetail failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `fetchAreaDetail error: ${JSON.stringify(e)}`)
    } finally {
      this.isLoadingDetail = false
    }
  }

  /**
   * 加载更多（翻页）
   */
  async loadMoreDetail(): Promise<void> {
    if (this.currentGroupRes === null || this.areaDetailList.length === 0) {
      return
    }
    // 收集所有已加载的 MV 项，取最后一个作为翻页锚点
    const allItems: IMediaSimpleRes[] = []
    for (const group of this.areaDetailList) {
      const items = group.getItems()
      if (items) {
        for (const item of items) {
          const mediaItem = item.getMediaItem()
          if (mediaItem) {
            allItems.push(mediaItem)
          }
        }
      }
    }
    const lastItem = allItems.length > 0 ? allItems[allItems.length - 1] : null
    await this.fetchAreaDetail(this.currentGroupRes, lastItem)
  }

  /**
   * 获取专区名称
   */
  getAreaTitle(): string {
    if (this.specialArea === SpecialArea.Dolby) {
      return 'Dolby视界专区'
    } else if (this.specialArea === SpecialArea.Excellent) {
      return '4K臻品世界'
    }
    return '视频专区'
  }

  /**
   * 清除数据
   */
  clear(): void {
    this.areaData = null
    this.areaDetailList = []
    this.currentGroupRes = null
    this.isLoading = false
    this.isLoadingDetail = false
  }
}
