import { MLog, OpenApiSdk } from "@qqmusic/opisdk-base"
import { OpenApiResponse } from "@qqmusic/opisdk-entity"
import { IAreaShelf, IAreaShelfItem, AreaShelfType } from "@qqmusic/opisdk-entity"

const TAG = 'AreaListViewModel'

/**
 * AreaList 页面的 ViewModel
 * 负责分页加载专区模块内容（歌曲/专辑/歌单）
 */
@ObservedV2
export class AreaListViewModel {
  /** 专区ID */
  areaId: number = 0
  /** 模块类型（歌曲/专辑/歌单） */
  areaShelfType: number = 0
  /** 模块ID */
  shelfId: number = 0
  /** 页面标题 */
  title: string = ''
  /** LazyForEach 数据源（保持引用稳定，通过 listener 通知 UI 刷新） */
  dataSource: AreaShelfDataSource = new AreaShelfDataSource([])

  /** 数据列表 */
  @Trace shelfItems: IAreaShelfItem[] = []
  /** 是否正在加载 */
  @Trace isLoading: boolean = false
  /** 是否还有更多 */
  @Trace hasMore: boolean = true
  /** 当前页最后一项的ID，用于分页 */
  private lastContentId: string = ''
  /** 每页大小 */
  private readonly pageSize: number = 20
  /** 防止重复加载的标记 */
  private lastLoadMoreTime: number = 0
  /** 防抖间隔（毫秒），防止弹簧回弹导致 onReachEnd 触发两次 */
  private readonly loadMoreDebounceMs: number = 500
  /**
   * 初始化参数
   */
  init(areaId: number, areaShelfType: number, shelfId: number, title: string): void {
    this.areaId = areaId
    this.areaShelfType = areaShelfType
    this.shelfId = shelfId
    this.title = title
    MLog.i(TAG, `init: areaId=${areaId}, shelfType=${areaShelfType}, shelfId=${shelfId}, title=${title}`)
  }

  /**
   * 刷新数据（重新加载第一页）
   */
  async refresh(): Promise<void> {
    this.lastContentId = ''
    this.hasMore = true
    this.isLoading = true
    this.lastLoadMoreTime = 0
    MLog.i(TAG, `refresh: shelfId=${this.shelfId}, areaId=${this.areaId}`)

    try {
      const result: OpenApiResponse<IAreaShelf> | undefined =
        (await OpenApiSdk.openApi?.operAreaApi.fetchShelfContent(
          this.shelfId,
          this.pageSize,
          '',
          this.areaId
        )) as OpenApiResponse<IAreaShelf>

      if (result && result.isSuccess()) {
        const data = result.data
        if (data) {
          const items = data.getShelfItems() ?? []
          this.shelfItems = items
          this.hasMore = result.hasMore
          MLog.i(TAG, `shelfItems size = ${this.shelfItems.length}, hasMore=${this.hasMore}`);
          this.dataSource.reloadData(items)
          this.updateLastContentId()
        } else {
          this.shelfItems = []
          this.hasMore = false
          this.dataSource.reloadData([])
        }
      } else {
        MLog.e(TAG, `refresh failed: code=${result?.ret}, msg=${result?.errorMsg}`)
        this.shelfItems = []
        this.hasMore = false
        this.dataSource.reloadData([])
      }
    } catch (e) {
      MLog.e(TAG, `refresh error: ${JSON.stringify(e)}`)
      this.shelfItems = []
      this.hasMore = false
      this.dataSource.reloadData([])
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 加载更多（分页加载下一页）
   */
  async loadMore(): Promise<void> {
    const now = Date.now()
    if (!this.hasMore || now - this.lastLoadMoreTime < this.loadMoreDebounceMs) {
      return
    }
    this.lastLoadMoreTime = now
    this.isLoading = true
    MLog.i(TAG, `loadMore: shelfId=${this.shelfId}, lastContentId=${this.lastContentId}`)
    try {
      const result: OpenApiResponse<IAreaShelf> | undefined =
        (await OpenApiSdk.openApi?.operAreaApi.fetchShelfContent(
          this.shelfId,
          this.pageSize,
          this.lastContentId,
          this.areaId
        )) as OpenApiResponse<IAreaShelf>

      if (result && result.isSuccess()) {
        const data = result.data
        if (data && data.getShelfItems() && data.getShelfItems().length > 0) {
          const newItems = data.getShelfItems()
          this.shelfItems.push(...newItems)
          this.hasMore = result.hasMore
          MLog.i(TAG, `loadMore: shelfItems size = ${this.shelfItems.length}, hasMore=${this.hasMore}`)
          this.dataSource.addData(newItems)
          this.updateLastContentId()
        } else {
          this.hasMore = false
        }
      } else {
        MLog.e(TAG, `loadMore failed: code=${result?.ret}, msg=${result?.errorMsg}`)
        this.hasMore = false
      }
    } catch (e) {
      MLog.e(TAG, `loadMore error: ${JSON.stringify(e)}`)
      this.hasMore = false
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 根据当前模块类型更新 lastContentId
   */
  private updateLastContentId(): void {
    if (this.shelfItems.length === 0) {
      this.lastContentId = ''
      return
    }
    const lastItem = this.shelfItems[this.shelfItems.length - 1]
    if (this.areaShelfType === AreaShelfType.AreaShelfType_Song) {
      this.lastContentId = lastItem.getSongInfo()?.getSongId()?.toString() ?? ''
    } else if (this.areaShelfType === AreaShelfType.AreaShelfType_Folder) {
      this.lastContentId = lastItem.getFolder()?.getId().toString() ?? ''
    } else if (this.areaShelfType === AreaShelfType.AreaShelfType_Album) {
      this.lastContentId = lastItem.getAlbum()?.getId().toString() ?? ''
    }
  }
}

/**
 * LazyForEach 数据源适配器
 */
export class AreaShelfDataSource implements IDataSource {
  private dataArray: IAreaShelfItem[] = []
  private listeners: DataChangeListener[] = []

  constructor(data: IAreaShelfItem[]) {
    this.dataArray = data
  }

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): IAreaShelfItem {
    return this.dataArray[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }
  /**
   * 替换全部数据（首次加载/刷新时调用）
   */
  reloadData(newData: IAreaShelfItem[]): void {
    this.dataArray = newData
    for (const listener of this.listeners) {
      listener.onDataReloaded()
    }
  }
  /**
   * 追加数据（加载更多时调用）
   */
  addData(newItems: IAreaShelfItem[]): void {
    const startIndex = this.dataArray.length
    this.dataArray.push(...newItems)
    for (const listener of this.listeners) {
      listener.onDataAdd(startIndex)
    }
  }
}