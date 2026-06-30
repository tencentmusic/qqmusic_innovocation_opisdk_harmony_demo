import { ICard } from '@qqmusic/opisdk-entity'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { SongItemView } from './SongItemView'

/**
 * 推荐单曲列表（type=200）
 */
@ComponentV2
export struct RecommendSongsView {
  @Param cardList: ICard[] = []
  @Param title: string = ''
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()

  build() {
    Column({ space: 8 }) {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .padding({ bottom: 4 })

      Repeat(this.cardList).each((repeatItem) => {
        SongItemView({ card: repeatItem.item })
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
