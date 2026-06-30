import { OpenApiSdk } from "@qqmusic/opisdk-base"
import { PersonalAssetsDataInfoRetCode } from "@qqmusic/opisdk-entity"
import { ISongInfo } from "@qqmusic/opisdk-qmutils"
import { EmptyView } from "../empty/EmptyView"
import { LongAudioSongListItem } from "./LongAudioSongListItem"

@ComponentV2
export struct LongAudioSongPanel {

  build() {
    Stack() {

      Column() {
        List({ space: 0 }) {
          ForEach(
            OpenApiSdk.personalAssetsApi?.longAudioHisApi.getData().list,
            (item: ISongInfo, index: number) => {
              ListItem() {
                Column() {
                  LongAudioSongListItem({ song: item, index }).width('100%').layoutWeight(1)
                  Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
                }.width('100%').height('100%')
              }.width('100%').height(80)
            }
            , (item: ISongInfo) => `${item.getSongId()?.toString()}_${new Date().getTime().toString()}`
          )
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            OpenApiSdk.personalAssetsApi?.longAudioHisApi.refresh()
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
          msg: OpenApiSdk.personalAssetsApi?.longAudioHisApi.getData().message
        })
      }

    }.width('100%').height('100%')
  }

  @Computed
  get isEmpty() {
    return OpenApiSdk.personalAssetsApi?.longAudioHisApi.getData().isEmpty
  }

  @Computed
  get isLoading() {
    return OpenApiSdk.personalAssetsApi?.longAudioHisApi.getData().isLoading
  }

  @Computed
  get requestIsError() {
    return OpenApiSdk.personalAssetsApi?.longAudioHisApi.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
