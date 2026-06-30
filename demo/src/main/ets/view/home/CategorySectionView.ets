import { ICategory } from '@qqmusic/opisdk-entity'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { FolderListPageParams, SongListPageParams } from '../../nav/RouteParams'

/**
 * 单个分类区块（含标题 + 子分类标签流）
 */
@ComponentV2
export struct CategorySectionView {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Param topCategory: ICategory | null = null
  @Param musicListType: number | undefined = undefined;

  private get name(): string {
    return this.topCategory?.name ?? ''
  }

  private get subList(): ICategory[] {
    return this.topCategory?.subCategory ?? []
  }

  build() {
    Column() {
      // 分类标题
      Text(this.name)
        .fontSize(16)
        .fontColor(Color.Gray)
        .fontWeight(FontWeight.Medium)
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 8
        })
        .width('100%')

      // 子分类标签流布局
      Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
        Repeat(this.subList).each((repeatItem) => {
          Text(repeatItem.item.name)
            .fontSize(14)
            .fontColor('#333333')
            .backgroundColor(Color.White)
            .borderRadius(20)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({
              left: 14,
              right: 14,
              top: 8,
              bottom: 8
            })
            .margin({ left: 8, right: 8, bottom: 10 })
            .onClick(() => {
              if (this.musicListType) {
                const params = new SongListPageParams(
                  this.musicListType,
                  repeatItem.item.id,
                  repeatItem.item.name,
                  true,
                  null,
                  null,
                  [this.topCategory?.id ?? 0, repeatItem.item.id]
                )
                this.navController.push(RouteName.SONG_LIST_PAGE, params)
              } else {
                const parentId = this.topCategory?.id ?? 0
                const subId = repeatItem.item.id
                const params = new FolderListPageParams(parentId, subId, repeatItem.item.name)
                this.navController.push(RouteName.FOLDER_LIST_PAGE, params)
              }
            })
        })
      }
      .padding({ left: 8, right: 8 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .margin({ bottom: 8 })
  }
}
