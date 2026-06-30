import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IFolder, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { EmptyView } from '../empty/EmptyView';
import { HisFolderListItem } from './HisFolderListItem';

@ComponentV2
export struct HisFolderApiPanel {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoading: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchRecentFolder();
    this.isLoading = false;
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
            this.homeViewModel.recentFolderList
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
      } else if (this.homeViewModel.recentFolderList.length === 0) {
        EmptyView({
          msg: '数据为空'
        })
      }
    }.width('100%').height('100%')
  }
}
