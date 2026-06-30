import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { IAlbum, IAreaInfo, OpenApiResponse } from '@qqmusic/opisdk-entity'

const TAG = 'NewAlbumViewModel'

/**
 * 单个地区的专辑数据模型
 * 对应 Android 端 AreaNewAlbumModel
 */
@ObservedV2
class AreaNewAlbumModel {
  /** 地区ID */
  private areaId: number
  /** 专辑列表 */
  @Trace public albumList: IAlbum[] = []
  /** 是否有更多 */
  @Trace public hasMore: boolean = false
  /** 当前筛选类型 */
  @Trace public type: number | null = null
  /** 下一页页码 */
  private nextPage: number = 0
  /** 是否正在加载 */
  @Trace public isLoading: boolean = false

  constructor(areaId: number) {
    this.areaId = areaId
  }

  /**
   * 获取新碟列表
   * @param type 专辑类型：null=全部, 10=单曲, 11=EP, 0=录音室专辑, 1=现场专辑
   */
  async fetchNewAlbumList(type: number | null): Promise<void> {
    // 如果类型变了，重置分页
    if (this.type !== type) {
      this.type = type
      this.nextPage = 0
      this.albumList = []
      this.hasMore = false
    }

    if (this.isLoading) {
      return
    }
    this.isLoading = true

    try {
      const resp: OpenApiResponse<IAlbum[]> | null | undefined =
        await OpenApiSdk.openApi?.albumApi.fetchNewAlbum(this.areaId, this.nextPage, 50, type)

      if (resp && resp.isSuccess()) {
        const newList: IAlbum[] = [...this.albumList]
        const data = resp.data ?? []
        for (const album of data) {
          newList.push(album)
        }
        this.albumList = newList
        this.hasMore = resp.hasMore ?? false
        this.nextPage++
        MLog.i(TAG, `fetchNewAlbumList success: areaId=${this.areaId}, type=${type}, page=${this.nextPage}, count=${data.length}, hasMore=${this.hasMore}`)
      } else {
        MLog.w(TAG, `fetchNewAlbumList failed: areaId=${this.areaId}, error=${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `fetchNewAlbumList error: areaId=${this.areaId}, ${JSON.stringify(e)}`)
    } finally {
      this.isLoading = false
    }
  }
}

/**
 * 新碟专区 ViewModel
 * 对应 Android 端 AreaViewModel（新碟部分）
 */
@ObservedV2
export class NewAlbumViewModel {
  /** 地区列表 */
  @Trace public areaList: IAreaInfo[] = []
  /** 是否正在加载地区列表 */
  @Trace public isLoadingArea: boolean = false
  /** 地区加载错误信息 */
  @Trace public areaErrorMsg: string = ''

  /** 各地区专辑模型缓存 */
  private areaModels: Map<number, AreaNewAlbumModel> = new Map()

  /**
   * 获取新碟地区分类列表
   */
  async fetchNewAlbumAreaList(): Promise<void> {
    if (this.isLoadingArea) {
      return
    }
    this.isLoadingArea = true
    this.areaErrorMsg = ''

    try {
      const resp = await OpenApiSdk.openApi?.albumApi.fetchNewAlbumsByArea()
      if (resp && resp.isSuccess()) {
        this.areaList = resp.data ?? []
        MLog.i(TAG, `fetchNewAlbumAreaList success: count=${this.areaList.length}`)
      } else {
        this.areaErrorMsg = resp?.errorMsg ?? '获取地区列表失败'
        MLog.w(TAG, `fetchNewAlbumAreaList failed: ${this.areaErrorMsg}`)
      }
    } catch (e) {
      this.areaErrorMsg = '网络请求异常'
      MLog.e(TAG, `fetchNewAlbumAreaList error: ${JSON.stringify(e)}`)
    } finally {
      this.isLoadingArea = false
    }
  }

  /**
   * 获取或创建地区专辑模型
   */
  private getAreaModel(areaId: number): AreaNewAlbumModel {
    let model = this.areaModels.get(areaId)
    if (!model) {
      model = new AreaNewAlbumModel(areaId)
      this.areaModels.set(areaId, model)
    }
    return model
  }

  /**
   * 获取指定地区的专辑数据（首次加载）
   * @param areaId 地区ID
   * @param type 专辑类型筛选
   */
  async fetchNewAlbum(areaId: number, type: number | null): Promise<void> {
    const model = this.getAreaModel(areaId)
    await model.fetchNewAlbumList(type)
  }

  /**
   * 加载更多专辑
   * @param areaId 地区ID
   */
  async fetchMoreNewAlbum(areaId: number): Promise<void> {
    const model = this.getAreaModel(areaId)
    await model.fetchNewAlbumList(model.type)
  }

  /**
   * 获取指定地区的专辑列表
   */
  getAlbumList(areaId: number): IAlbum[] {
    return this.getAreaModel(areaId).albumList
  }

  /**
   * 获取指定地区是否还有更多
   */
  hasMore(areaId: number): boolean {
    return this.getAreaModel(areaId).hasMore
  }

  /**
   * 获取指定地区是否正在加载
   */
  isLoading(areaId: number): boolean {
    return this.getAreaModel(areaId).isLoading
  }

  /**
   * 获取指定地区的当前筛选类型
   */
  getType(areaId: number): number | null {
    return this.getAreaModel(areaId).type
  }

  /**
   * 清除所有数据
   */
  clear(): void {
    this.areaList = []
    this.areaModels.clear()
    this.isLoadingArea = false
    this.areaErrorMsg = ''
  }
}
