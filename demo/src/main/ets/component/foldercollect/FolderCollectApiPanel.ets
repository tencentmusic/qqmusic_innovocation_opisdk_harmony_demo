import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IFolder, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { EmptyView } from '../empty/EmptyView';
import { FolderCollectListItem } from './FolderCollectListItem';

@ComponentV2
export struct FolderCollectApiPanel {

  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();

  aboutToAppear(): void {
    this.homeViewModel.fetchCollectedFolder();
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
            this.homeViewModel.collectedFolderList
          , (item: IFolder) => {
            ListItem() {
              Column() {
                FolderCollectListItem({
                  folder: item,
                  enablePersonalAssets: false,
                  onUncollect: (folderId: number) => {
                    const index = this.homeViewModel.collectedFolderList.findIndex(f => f.getId() === folderId);
                    if (index > -1) {
                      this.homeViewModel.collectedFolderList.splice(index, 1);
                    }
                  }
                }).width('100%').layoutWeight(1)
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
            this.homeViewModel.refreshCollectedFolder();
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
            msg: '数据为空'
          })
        }
      }

    }
  }

  @Computed get isLoadingFolder() {
    return false
  }

  @Computed get requestFolderIsError() {
    return this.homeViewModel.collectedFolderList.length === 0
  }
}
