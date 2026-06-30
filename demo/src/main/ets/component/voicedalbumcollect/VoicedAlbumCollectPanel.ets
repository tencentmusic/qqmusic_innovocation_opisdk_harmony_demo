import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IAlbum, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { EmptyView } from '../empty/EmptyView';
import { VoicedAlbumCollectListItem } from './VoicedAlbumCollectListItem';

@ComponentV2
export struct VoicedAlbumCollectPanel {
  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(OpenApiSdk.personalAssetsApi?.audioAlbumFavApi.getData().list ?? [], (item: IAlbum) => {
            ListItem() {
              Column() {
                VoicedAlbumCollectListItem({ album: item }).width('100%').layoutWeight(1)
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
            OpenApiSdk.personalAssetsApi?.audioAlbumFavApi.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      }.width('100%').height('100%')

      if (this.isLoadingVoicedAlbum) {
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
        if (this.requestVoicedAlbumIsError) {
          EmptyView({
            msg: OpenApiSdk.personalAssetsApi?.audioAlbumFavApi.getData().message
          })
        }
      }

    }
  }

  @Computed get isLoadingVoicedAlbum() {
    return OpenApiSdk.personalAssetsApi?.audioAlbumFavApi.getData().isLoading
  }

  @Computed get requestVoicedAlbumIsError() {
    return OpenApiSdk.personalAssetsApi?.audioAlbumFavApi.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
