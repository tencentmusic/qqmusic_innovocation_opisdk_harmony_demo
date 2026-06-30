
import { RecommendSongsView } from './RecommendSongsView'
import { RecommendFolderListView } from './RecommendFolderListView'
import { ICard, IShelf } from '@qqmusic/opisdk-entity'

/**
 * 推荐项：根据 cardList 首项 type 区分单曲(200) / 歌单(500)
 */
@ComponentV2
export struct RecommendItemView {
  @Param shelf: IShelf | null = null

  private get title(): string {
    return this.shelf?.getTitle() ?? ''
  }

  private get cardList(): ICard[] {
    return this.shelf?.getCardList() ?? []
  }

  private get firstCardType(): number {
    if (this.cardList.length > 0) {
      return this.cardList[0].getType()
    }
    return 0
  }

  build() {
    if (this.cardList.length > 0) {
      if (this.firstCardType === 200) {
        RecommendSongsView({ cardList: this.cardList, title: this.title })
      } else if (this.firstCardType === 500) {
        RecommendFolderListView({ cardList: this.cardList, title: this.title })
      }
    }
  }
}
