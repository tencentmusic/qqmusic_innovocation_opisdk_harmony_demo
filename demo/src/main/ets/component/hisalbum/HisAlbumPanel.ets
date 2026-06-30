import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IAlbum, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { Album } from '@qqmusic/opisdk-openapi';
import { ISongInfo } from '@qqmusic/opisdk-qmutils';
import { EmptyView } from '../empty/EmptyView';
import { HisAlbumListItem } from './HisAlbumListItem';

@ComponentV2
export struct HisAlbumPanel {
  build() {
    Stack() {

      Column() {

        List({ space: 0 }) {
          ForEach(
            OpenApiSdk.personalAssetsApi?.albumHisApi.getData().list
            , (item: IAlbum) => {
            ListItem() {
              Column() {
                HisAlbumListItem({ album: item }).width('100%').layoutWeight(1)
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
            OpenApiSdk.personalAssetsApi?.albumHisApi.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)

      }.width('100%').height('100%')


      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.Transparent)
      } else if (this.isEmpty) {
        EmptyView({
          msg: '数据为空'
        })
      } else if (this.requestIsError) {
        EmptyView({
          msg: OpenApiSdk.personalAssetsApi?.albumHisApi.getData().message
        })
      }
    }.width('100%').height('100%')
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

  @Computed
  get isEmpty() {
    return OpenApiSdk.personalAssetsApi?.albumHisApi.getData().isEmpty
  }

  @Computed
  get isLoading() {
    return OpenApiSdk.personalAssetsApi?.albumHisApi.getData().isLoading
  }

  @Computed
  get requestIsError() {
    return OpenApiSdk.personalAssetsApi?.albumHisApi.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
