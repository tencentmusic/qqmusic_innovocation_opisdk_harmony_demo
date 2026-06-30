import { ICard } from '@qqmusic/opisdk-entity'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'

/**
 * 单曲项（封面 + 歌名 + 副标题，点击播放）
 */
@ComponentV2
export struct SongItemView {
  @Param card: ICard | null = null
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()

  private get coverUrl(): string {
    return this.card?.getCover() ?? ''
  }

  private get songTitle(): string {
    return this.card?.getTitle() ?? ''
  }

  private get songSubTitle(): string {
    return this.card?.getSubTitle() ?? ''
  }

  private get singerName(): string {
    return this.card?.getSongInfo()?.getSingerName() ?? ''
  }

  private get displaySubTitle(): string {
    if (this.songSubTitle.length > 0) {
      return this.songSubTitle
    }
    return this.singerName
  }

  build() {
    Row({ space: 8 }) {
      Image(this.coverUrl)
        .width(56)
        .height(56)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .backgroundColor('#E0E0E0')

      Column({ space: 4 }) {
        Text(this.songTitle)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.displaySubTitle)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 6, bottom: 6 })
    .borderRadius(8)
    .backgroundColor(Color.White)
    .onClick(() => {
      if (this.card !== null) {
        this.homeViewModel.playRecommendSongs(this.card)
      }
    })
  }
}
