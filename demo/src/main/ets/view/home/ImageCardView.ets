import { NavController } from '../../nav/NavController'
import { SongListPageParams } from '../../nav/RouteParams'
import { RouteName } from '../../nav/RouteMap'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { ICard } from '@qqmusic/opisdk-entity'

/**
 * 歌单封面卡片（封面图 + 标题 + 副标题）
 * 点击跳转 SongListPage（歌单场景）
 */
@ComponentV2
export struct ImageCardView {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Param card: ICard | null = null

  private get coverUrl(): string {
    return this.card?.getCover() ?? ''
  }

  private get folderTitle(): string {
    return this.card?.getTitle() ?? ''
  }

  private get folderSubTitle(): string {
    return this.card?.getSubTitle() ?? ''
  }

  private get folderId(): number {
    const idStr = this.card?.getId() ?? '0'
    return parseInt(idStr)
  }

  build() {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(this.coverUrl)
          .width(120)
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .backgroundColor('#E0E0E0')

        if (this.folderSubTitle.length > 0) {
          Text(this.folderSubTitle)
            .fontSize(10)
            .fontColor('#333333')
            .backgroundColor('#CCFFFFFF')
            .padding({
              left: 4,
              right: 4,
              top: 2,
              bottom: 2
            })
            .borderRadius({
              topLeft: 0,
              topRight: 4,
              bottomLeft: 0,
              bottomRight: 0
            })
        }
      }
      .width(120)
      .height(120)
      .alignContent(Alignment.BottomStart)

      Text(this.folderTitle)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(120)
        .height(34)
    }
    .width(120)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      const params = new SongListPageParams(
        MusicListType.TYPE_FOLDER,
        this.folderId,
        this.folderTitle,
        true
      )
      this.navController.push(RouteName.SONG_LIST_PAGE, params)
    })
  }
}
