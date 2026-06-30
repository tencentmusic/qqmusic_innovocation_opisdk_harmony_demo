import { OpenApiSdk } from "@qqmusic/opisdk-base"
import { ISongInfo } from "@qqmusic/opisdk-qmutils"
import { HomeViewModel } from "../../viewmodel/HomeViewModel";
import { EmptyView } from "../empty/EmptyView"
import { OtherPlatListeningListItem } from "./OtherPlatListeningListItem";

@ComponentV2
export struct OtherPlatListeningApiPanel {

  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoading: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchOtherPlatListeningList();
    this.isLoading = false;
  }


  build() {

    Stack() {
      Column() {
        Text('来自'+this.homeViewModel.otherPlatListeningList?.getPlatformString()+'平台的'+this.homeViewModel.otherPlatListeningList?.getPlayList()?.length+'首歌'+this.homeViewModel.otherPlatListeningList?.getSuggestShowText()).fontSize(18).fontWeight(FontWeight.Bold)
        List({ space: 0 }) {
          ForEach(
            this.homeViewModel.otherPlatListeningList?.getPlayList(),
            (item: ISongInfo, index: number) => {
              ListItem() {
                Column() {
                  OtherPlatListeningListItem({ song: item, index : index,songList:this.homeViewModel.otherPlatListeningList?.getPlayList() }).width('100%').layoutWeight(1)
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
            OpenApiSdk.personalAssetsApi?.songHisApi.refresh()
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
      } else if (this.homeViewModel.otherPlatListeningList?.getPlayList()?.length === 0) {
        EmptyView({
          msg: '数据为空'
        })
      }
    }.width('100%').height('100%')
  }
}
