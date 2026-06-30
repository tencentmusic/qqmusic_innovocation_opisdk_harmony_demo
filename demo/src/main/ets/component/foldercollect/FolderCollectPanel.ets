import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IFolder, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { EmptyView } from '../empty/EmptyView';
import { FolderCollectListItem } from './FolderCollectListItem';

@ComponentV2
export struct FolderCollectPanel {

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
            OpenApiSdk.personalAssetsApi?.folderFavApi.getData().list ?? []
          , (item: IFolder) => {
            ListItem() {
              Column() {
                FolderCollectListItem({ folder: item }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: IFolder) => `${item.getId()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            this.currentFolderApi?.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      }.width('100%').height('100%')

      if (this.isLoadingFolder) {
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
        if (this.requestFolderIsError) {
          EmptyView({
            msg: this.currentFolderApi?.getData().message
          })
        }
      }

    }
  }

  @Computed get currentFolderApi() {
    return OpenApiSdk.personalAssetsApi?.folderFavApi

  }

  @Computed get isLoadingFolder() {
    return this.currentFolderApi?.getData().isLoading
  }

  @Computed get requestFolderIsError() {
    return this.currentFolderApi?.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
