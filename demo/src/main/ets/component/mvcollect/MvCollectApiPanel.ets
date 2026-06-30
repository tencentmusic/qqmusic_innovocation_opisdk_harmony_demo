import { IMediaResDetail } from '@qqmusic/opisdk-entity';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { MvCollectListItem } from './MvCollectListItem';

@ComponentV2
export struct MvCollectApiPanel {

  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoadingMv: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchCollectedMv();
    this.isLoadingMv = false;
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(this.homeViewModel.collectedMvList, (item: IMediaResDetail) => {
              ListItem() {
                Column() {
                  MvCollectListItem({
                    mv: item,
                    enablePersonalAssets: false,
                    onUncollect: (vid: string) => {
                      // 取消收藏后从列表中移除该项
                      const index = this.homeViewModel.collectedMvList.findIndex(m => m.getVid() === vid);
                      if (index > -1) {
                        this.homeViewModel.collectedMvList.splice(index, 1);
                      }
                    }
                  }).width('100%').layoutWeight(1)
                  Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
                }.width('100%').height('100%')
              }.width('100%').height(80)
            }, (item: IMediaResDetail) => `${item.getVid()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

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
      }
    }
  }
}
