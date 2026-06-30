import { ISinger } from "@qqmusic/opisdk-qmutils"
import { HomeViewModel } from "../../viewmodel/HomeViewModel";
import { SingerCollectListItem } from "./SingerCollectListItem"

@ComponentV2
export struct SingerCollectApiPanel {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoadingSinger: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchCollectedSingerList();
    this.isLoadingSinger = false;
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(this.homeViewModel.collectedSingerList, (item: ISinger) => {
            ListItem() {
              Column() {
                SingerCollectListItem({
                  singer: item,
                  enablePersonalAssets: false,
                  onUncollect: (singerId: number) => {
                    const index = this.homeViewModel.collectedSingerList.findIndex(s => s.getSingerId() === singerId);
                    if (index > -1) {
                      this.homeViewModel.collectedSingerList.splice(index, 1);
                    }
                  }
                }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: ISinger) => `${item.getSingerId()?.toString()}_${new Date().getTime().toString()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
      }.width('100%').height('100%')

      if (this.isLoadingSinger) {
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
      }
    }
  }
}