import { IAlbum } from '@qqmusic/opisdk-entity'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'

/**
 * 长音频专辑横向卡片
 * Row: 封面(60x60, 带播放量叠加) + 专辑信息(名称/副标题/歌手) + 收藏按钮
 *
 */
@ComponentV2
export struct LongAudioAlbumItemView {
  @Param album: IAlbum | null = null
  @Event onCollect: ((album: IAlbum) => void) | null = null
  @Event onItemClick: ((album: IAlbum) => void) | null = null
  @Local isCollected: boolean = false

  @Monitor('album')
  onAlbumChanged(): void {
    if (this.album) {
      this.isCollected = this.album.getFavState() === 1
    } else {
      this.isCollected = false
    }
  }

  aboutToAppear(): void {
    if (this.album) {
      this.isCollected = this.album.getFavState() === 1
    }
  }

  build() {
    Row({ space: 12 }) {
      // 封面（带播放量叠加）
      Stack() {
        Image(this.album?.getPic() ?? '')
          .width(60)
          .height(60)
          .objectFit(ImageFit.Cover)
          .borderRadius(4)
          .backgroundColor('#E0E0E0')

        // 播放量标签（叠加在封面底部）
        Text(`播放量:${NumberFormatUtils.formatNumber(this.album?.getListenNum() ?? 0)}`)
          .fontSize(8)
          .fontColor(Color.White)
          .backgroundColor('#99000000')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .width(60)
          .textAlign(TextAlign.Center)
      }
      .width(60)
      .height(60)
      .alignContent(Alignment.Bottom)

      // 专辑信息
      Column({ space: 4 }) {
        Text(this.album?.getName() ?? '')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.album?.getSubName()) {
          Text(this.album!.getSubName()!)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Text(this.album?.getSingerName() ?? '')
          .fontSize(12)
          .fontColor(Color.Gray)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)

      // 收藏按钮 — 使用 @Local isCollected 驱动 UI 即时刷新
      Image(this.isCollected ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
        .width(32)
        .height(32)
        .padding(6)
        .onClick(() => {
          if (this.album && this.onCollect) {
            // 乐观更新：先翻转本地状态，UI 即时响应
            this.isCollected = !this.isCollected
            this.onCollect(this.album)
          }
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .margin({ top: 4, bottom: 4 })
    .borderRadius(8)
    .onClick(() => {
      if (this.album && this.onItemClick) {
        this.onItemClick(this.album)
      }
    })
  }
}
