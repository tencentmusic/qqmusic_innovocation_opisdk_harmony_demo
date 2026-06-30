import { MLog } from '@qqmusic/opisdk-base'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { AreaId } from '@qqmusic/opisdk-entity'
import { AreaSectionDetailView } from './AreaSectionDetailView'
import { NewAlbumPage } from './NewAlbumPage'
import { CategorySectionView } from './CategorySectionView'
import { MusicListType } from '@qqmusic/opisdk-qmutils'

const TAG = 'AreaSectionView'

/**
 * 专区入口 + 详情页容器
 * - areaIndex === -1：显示专区入口网格
 * - areaIndex >= 0：显示对应专区详情页
 */
@ComponentV2
export struct AreaSectionView {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()
  @Local areaIndex: number = -1
  private readonly pageNames: string[] = [
    '臻品乐航专区',
    'Hires专区',
    'Dolby专区',
    '臻品全景声专区',
    'Wanos专区',
    '黑胶专区',
    '臻品母带专区',
    '场景歌单',
    '新碟',
    '小宇宙',
    'DTS专区'
  ]

  /** 专区名称 → AreaId 映射 */
  private readonly areaIdMap: Map<string, number> = new Map([
    ['Hires专区', AreaId.AreaHires],
    ['Dolby专区', AreaId.AreaDolby],
    ['臻品全景声专区', AreaId.AreaGalaxy],
    ['Wanos专区', AreaId.Wanos],
    ['黑胶专区', AreaId.Vinly],
    ['臻品母带专区', AreaId.Master],
    ['小宇宙', AreaId.XiaoYuZhou],
    ['DTS专区', AreaId.DTS],
    ['臻品乐航专区', AreaId.Voyage]
  ])

  aboutToAppear(): void {
    MLog.i(TAG, 'AreaSectionView aboutToAppear')
  }

  aboutToDisappear(): void {
    MLog.i(TAG, 'AreaSectionView aboutToDisappear')
    this.areaIndex = -1
    this.homeViewModel.cleanAreaData()
  }

  build() {
    Column() {
      if (this.areaIndex === -1) {
        // 专区入口网格页
        this.buildGridPage()
      } else {
        // 专区详情页
        this.buildDetailPage()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildGridPage() {
    Grid() {
      Repeat(this.pageNames).each((repeatItem) => {
        GridItem() {
          this.buildGridItem(repeatItem.item, repeatItem.index)
        }
      })
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .padding(16)
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  @Builder
  buildGridItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(100)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .onClick(() => {
      this.areaIndex = index
      MLog.i(TAG, `Grid item clicked: ${title}, index: ${index}`)
    })
  }

  /**
   * 构建专区详情页
   */
  @Builder
  buildDetailPage() {
    Column() {
      // 顶部返回栏
      Row() {
        Button() {
          Text('< 返回')
            .fontSize(16)
            .fontColor('#333333')
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.areaIndex = -1
          this.homeViewModel.cleanAreaData()
          MLog.i(TAG, 'Back to grid page')
        })

        Text(this.pageNames[this.areaIndex] ?? '专区')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Blank()
          .width(64)
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })

      // 专区详情内容
      Column() {
        if (this.areaIndex >= 0 && this.areaIndex < this.pageNames.length) {
          if (this.areaIdMap.get(this.pageNames[this.areaIndex]) !== undefined) {
            AreaSectionDetailView({
              title: this.pageNames[this.areaIndex],
              areaId: this.areaIdMap.get(this.pageNames[this.areaIndex])!,
              viewModel: this.homeViewModel
            })
          } else if (this.pageNames[this.areaIndex] === '场景歌单') {
            SceneSongListView()
          } else if (this.pageNames[this.areaIndex] === '新碟') {
            NewAlbumPage()
          } else {
            this.buildPlaceholder(this.pageNames[this.areaIndex])
          }
        } else {
          this.buildPlaceholder('未知专区')
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildPlaceholder(title: string) {
    Column() {
      Image($r('app.media.icon_home_placeholder'))
        .width(64)
        .height(64)
        .opacity(0.3)
      Text(`${title} 详情页`)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 16 })
      Text('功能开发中...')
        .fontSize(14)
        .fontColor('#AAAAAA')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

/**
 * 场景歌单列表页
 * 对应 Android 端 categoryFoldersPage(homeViewModel, fetchSceneSongList=true)
 * 复用 CategorySectionView 组件展示场景歌单分类
 */
@ComponentV2
struct SceneSongListView {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()

  aboutToAppear(): void {
    MLog.i('SceneSongListView', 'aboutToAppear')
    if (this.homeViewModel.sceneCategories.length === 0) {
      this.homeViewModel.fetchSceneCategory()
    }
  }

  build() {
    Column() {
      if (this.homeViewModel.sceneCategories.length === 0) {
        // 加载中 / 空状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#6200EE')
          Text('加载中...')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 场景歌单分类列表
        List() {
          Repeat(this.homeViewModel.sceneCategories).each((repeatItem) => {
            ListItem() {
              CategorySectionView({ topCategory: repeatItem.item, musicListType: MusicListType.TYPE_SONG_LIST })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
