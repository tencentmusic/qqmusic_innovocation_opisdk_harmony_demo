import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { ISongInfo } from '@qqmusic/opisdk-qmutils';
import { EmptyView } from '../empty/EmptyView';
import { VoicedSongCollectListItem } from './VoicedSongCollectListItem';

@ComponentV2
export struct VoicedSongCollectPanel {
  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.getData().list ?? [], (item: ISongInfo,index : number) => {
            ListItem() {
              Column() {
                VoicedSongCollectListItem({ song: item ,index : index}).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: ISongInfo) => `${item.getSongId()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      }.width('100%').height('100%')

      if (this.isLoadingVoicedSong) {
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
        if (this.requestVoicedSongIsError) {
          EmptyView({
            msg: OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.getData().message
          })
        }
      }

    }
  }

  @Computed get isLoadingVoicedSong() {
    return OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.getData().isLoading
  }

  @Computed get requestVoicedSongIsError() {
    return OpenApiSdk.personalAssetsApi?.audioProgramsFavApi.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
