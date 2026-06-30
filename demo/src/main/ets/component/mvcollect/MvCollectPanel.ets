import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IMediaResDetail, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { EmptyView } from '../empty/EmptyView';
import { MvCollectListItem } from './MvCollectListItem';

@ComponentV2
export struct MvCollectPanel {
  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
              OpenApiSdk.personalAssetsApi?.videoFavApi.getData().list ?? [], (item: IMediaResDetail) => {
            ListItem() {
              Column() {
                MvCollectListItem({ mv: item }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: IMediaResDetail) => `${item.getVid()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            this.currentMvApi?.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      }.width('100%').height('100%')

      if (this.isLoadingMv) {
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
        if (this.requestMvIsError) {
          EmptyView({
            msg: this.currentMvApi?.getData().message
          })
        }
      }

    }
  }

  @Computed get currentMvApi() {
    return OpenApiSdk.personalAssetsApi?.videoFavApi
  }

  @Computed get isLoadingMv() {
    return this.currentMvApi?.getData().isLoading
  }

  @Computed get requestMvIsError() {
    return this.currentMvApi?.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
