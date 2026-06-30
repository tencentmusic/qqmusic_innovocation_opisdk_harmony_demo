import { ICard } from '@qqmusic/opisdk-entity'
import { ImageCardView } from './ImageCardView'

/**
 * 推荐歌单横向列表（type=500）
 */
@ComponentV2
export struct RecommendFolderListView {
  @Param cardList: ICard[] = []
  @Param title: string = ''

  build() {
    Column({ space: 8 }) {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .padding({ bottom: 4 })

      Scroll() {
        Row({ space: 8 }) {
          Repeat(this.cardList).each((repeatItem) => {
            ImageCardView({ card: repeatItem.item })
          })
        }
        .alignItems(VerticalAlign.Top)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
