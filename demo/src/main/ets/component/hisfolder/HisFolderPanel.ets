import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IFolder, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { EmptyView } from '../empty/EmptyView';
import { HisFolderListItem } from './HisFolderListItem';

@ComponentV2
export struct HisFolderPanel {
  build() {
    Stack() {

      Column() {


        List({ space: 0 }) {
          ForEach(
            OpenApiSdk.personalAssetsApi?.folderHisApi.getData().list
            , (item: IFolder) => {
            ListItem() {
              Column() {
                HisFolderListItem({ folder: item }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: IFolder) => `${item.getId()?.toString()}_${new Date().getTime()}`)
        }
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            OpenApiSdk.personalAssetsApi?.folderHisApi.refresh()
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
          msg: OpenApiSdk.personalAssetsApi?.folderHisApi.getData().message
        })
      }

    }.width('100%').height('100%')
  }

  @Computed
  get isEmpty() {
    return OpenApiSdk.personalAssetsApi?.folderHisApi.getData().isEmpty
  }

  @Computed
  get isLoading() {
    return OpenApiSdk.personalAssetsApi?.folderHisApi.getData().isLoading
  }

  @Computed
  get requestIsError() {
    return OpenApiSdk.personalAssetsApi?.folderHisApi.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
