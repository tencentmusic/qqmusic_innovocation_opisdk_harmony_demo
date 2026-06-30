import { OpenApiSdk } from "@qqmusic/opisdk-base"
import { ISinger } from "@qqmusic/opisdk-qmutils"
import { PersonalAssetsDataInfoRetCode } from "@qqmusic/opisdk-entity"
import { EmptyView } from "../empty/EmptyView"
import { SingerCollectListItem } from "./SingerCollectListItem"

@ComponentV2
export struct SingerCollectPanel {
  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(OpenApiSdk.personalAssetsApi?.singerFavApi.getData().list, (item: ISinger) => {
            ListItem() {
              Column() {
                SingerCollectListItem({ singer: item }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: ISinger) => `${item.getSingerId()?.toString()}_${new Date().getTime().toString()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            OpenApiSdk.personalAssetsApi?.singerFavApi.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      }.width('100%').height('100%')

      if (this.isLoadingSinger) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
        }.width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.Transparent)
      } else if (this.singerFavIsEmpty) {
        EmptyView({
          msg: '数据为空'
        })
      } else if (this.requestSingerIsError) {
        EmptyView({
          msg: OpenApiSdk.personalAssetsApi?.singerFavApi.getData().message
        })
      }
    }
  }

  @Computed get singerFavIsEmpty() {
    return OpenApiSdk.personalAssetsApi?.singerFavApi.getData().isEmpty
  }

  @Computed get isLoadingSinger() {
    return OpenApiSdk.personalAssetsApi?.singerFavApi.getData().isLoading
  }

  @Computed get requestSingerIsError() {
    return OpenApiSdk.personalAssetsApi?.singerFavApi.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }

}