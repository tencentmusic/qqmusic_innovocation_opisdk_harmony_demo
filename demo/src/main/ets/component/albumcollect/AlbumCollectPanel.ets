import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IAlbum, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { ISongInfo } from '@qqmusic/opisdk-qmutils';
import { Album } from '@qqmusic/opisdk-openapi';
import { EmptyView } from '../empty/EmptyView';
import { AlbumCollectListItem } from './AlbumCollectListItem';
@ComponentV2
export struct AlbumCollectPanel {
  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
              OpenApiSdk.personalAssetsApi?.albumFavApi.getData().list ?? []
          , (item: IAlbum) => {
            ListItem() {
              Column() {
                AlbumCollectListItem({ album: item }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: IAlbum) => `${item.getId()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            this.currentAlbumApi?.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      }.width('100%').height('100%')

      if (this.isLoadingAlbum) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
        }.width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.Transparent)
      } else {
        if (this.requestAlbumIsError) {
          EmptyView({
            msg: this.currentAlbumApi?.getData().message
          })
        }
      }

    }
  }

  @Computed get currentAlbumApi() {
    return OpenApiSdk.personalAssetsApi?.albumFavApi

  }

  @Computed get isLoadingAlbum() {
    return this.currentAlbumApi?.getData().isLoading
  }

  @Computed get requestAlbumIsError() {
    return this.currentAlbumApi?.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }

  songInfoListToAlbumInfo(songInfo: ISongInfo[]): IAlbum[] {
    let albumList: IAlbum[] = []
    songInfo.forEach((song: ISongInfo) => {
      let album = new Album()
      album.id = song.getAlbumId()
      album.mid = song.getAlbumMid() ?? undefined
      album.name = song.getAlbumName() ?? ''
      album.pic = song.getAlbumPic() ?? undefined
      album.pic150x150 = song.getAlbumPic150x150() ?? undefined
      album.pic300x300 = song.getAlbumPic300x300() ?? undefined
      album.pic500x500 = song.getAlbumPic500x500() ?? undefined
      albumList.push(album)
    })
    return albumList
  }

}
