import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ISinger } from '@qqmusic/opisdk-qmutils'

const TAG = 'SingerListViewModel'

// ========= 筛选选项类型定义 =========

export interface FilterOption {
  label: string
  value: number
}

export interface FilterIndexOption {
  label: string
  value: string
}

// ========= 筛选数据常量 =========

export const FILTER_AREAS: FilterOption[] = [
  { label: '全部', value: -100 },
  { label: '内地', value: 200 },
  { label: '港台', value: 2 },
  { label: '韩国', value: 3 },
  { label: '日本', value: 4 },
  { label: '欧美', value: 5 },
]

export const FILTER_SEX: FilterOption[] = [
  { label: '全部', value: -100 },
  { label: '男', value: 0 },
  { label: '女', value: 1 },
  { label: '组合', value: 2 },
]

export const FILTER_GENRE: FilterOption[] = [
  { label: '全部', value: -100 },
  { label: '流行', value: 1 },
  { label: '摇滚', value: 2 },
  { label: '民谣', value: 3 },
  { label: '电子', value: 4 },
  { label: '爵士', value: 5 },
  { label: '嘻哈', value: 6 },
  { label: 'R&B', value: 8 },
  { label: '轻音乐', value: 9 },
  { label: '民歌', value: 10 },
  { label: '古典', value: 14 },
  { label: '蓝调', value: 20 },
  { label: '乡村', value: 25 },
]

export const FILTER_INDEX: FilterIndexOption[] = [
  { label: 'HOT', value: 'hot' },
  { label: 'A', value: 'A' },
  { label: 'B', value: 'B' },
  { label: 'C', value: 'C' },
  { label: 'D', value: 'D' },
  { label: 'E', value: 'E' },
  { label: 'F', value: 'F' },
  { label: 'G', value: 'G' },
  { label: 'H', value: 'H' },
  { label: 'I', value: 'I' },
  { label: 'J', value: 'J' },
  { label: 'K', value: 'K' },
  { label: 'L', value: 'L' },
  { label: 'M', value: 'M' },
  { label: 'N', value: 'N' },
  { label: 'O', value: 'O' },
  { label: 'P', value: 'P' },
  { label: 'Q', value: 'Q' },
  { label: 'R', value: 'R' },
  { label: 'S', value: 'S' },
  { label: 'T', value: 'T' },
  { label: 'U', value: 'U' },
  { label: 'V', value: 'V' },
  { label: 'W', value: 'W' },
  { label: 'X', value: 'X' },
  { label: 'Y', value: 'Y' },
  { label: 'Z', value: 'Z' },
]

// ========= 筛选分类枚举 =========

export enum FilterCategory {
  AREA = 'area',
  SEX = 'sex',
  GENRE = 'genre',
  INDEX = 'index'
}

// ========= ViewModel =========

@ObservedV2
export class SingerListViewModel {
  @Trace public singerList: ISinger[] = []
  @Trace public isLoading: boolean = false
  @Trace public hasError: boolean = false
  @Trace public selectedArea: number = -100
  @Trace public selectedSex: number = -100
  @Trace public selectedGenre: number = -100
  @Trace public selectedIndex: string = 'hot'

  @Trace public selectedAreaLabel: string = '全部'
  @Trace public selectedSexLabel: string = '全部'
  @Trace public selectedGenreLabel: string = '全部'
  @Trace public selectedIndexLabel: string = 'HOT'

  /**
   * 当前激活的筛选分类（用于控制下拉面板展开）
   */
  @Trace public activeFilterCategory: FilterCategory | null = null

  private updateAreaLabel(): void {
    const found = FILTER_AREAS.find((item) => item.value === this.selectedArea)
    this.selectedAreaLabel = found ? found.label : '全部'
  }

  private updateSexLabel(): void {
    const found = FILTER_SEX.find((item) => item.value === this.selectedSex)
    this.selectedSexLabel = found ? found.label : '全部'
  }

  private updateGenreLabel(): void {
    const found = FILTER_GENRE.find((item) => item.value === this.selectedGenre)
    this.selectedGenreLabel = found ? found.label : '全部'
  }

  private updateIndexLabel(): void {
    const found = FILTER_INDEX.find((item) => item.value === this.selectedIndex)
    this.selectedIndexLabel = found ? found.label : 'HOT'
  }

  // ========= 筛选操作方法 =========

  selectArea(value: number): void {
    if (this.selectedArea === value) {
      return
    }
    this.selectedArea = value
    this.updateAreaLabel()
    this.activeFilterCategory = null
    this.loadData()
  }

  selectSex(value: number): void {
    if (this.selectedSex === value) {
      return
    }
    this.selectedSex = value
    this.updateSexLabel()
    this.activeFilterCategory = null
    this.loadData()
  }

  selectGenre(value: number): void {
    if (this.selectedGenre === value) {
      return
    }
    this.selectedGenre = value
    this.updateGenreLabel()
    this.activeFilterCategory = null
    this.loadData()
  }

  selectIndex(value: string): void {
    if (this.selectedIndex === value) {
      return
    }
    this.selectedIndex = value
    this.updateIndexLabel()
    this.activeFilterCategory = null
    this.loadData()
  }

  toggleFilterPanel(category: FilterCategory): void {
    if (this.activeFilterCategory === category) {
      this.activeFilterCategory = null
    } else {
      this.activeFilterCategory = category
    }
  }

  closeFilterPanel(): void {
    this.activeFilterCategory = null
  }

  // ========= 数据加载 =========

  async loadData(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    this.hasError = false
    // 切换筛选条件时立即清空旧数据，避免显示不匹配的内容
    this.singerList = []

    try {
      const resp = await OpenApiSdk.openApi?.singerApi.fetchHotSingerListWithFilter(
        this.selectedArea,
        this.selectedSex,
        this.selectedGenre,
        this.selectedIndex,
        0
      )
      if (resp && resp.isSuccess() && resp.data) {
        this.singerList = resp.data
        MLog.i(TAG, `loadData success, count: ${this.singerList.length}`)
      } else {
        MLog.w(TAG, `loadData failed: ${resp?.errorMsg}`)
        this.hasError = true
        this.singerList = []
      }
    } catch (e) {
      MLog.e(TAG, `loadData error: ${JSON.stringify(e)}`)
      this.hasError = true
      this.singerList = []
    } finally {
      this.isLoading = false
    }
  }
}
