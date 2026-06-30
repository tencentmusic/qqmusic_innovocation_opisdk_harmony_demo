import { OpenApiSdk } from "@qqmusic/opisdk-base"
import { PersonalAssetsDataInfoRetCode } from "@qqmusic/opisdk-entity"
import { ISongInfo } from "@qqmusic/opisdk-qmutils"
import { HomeViewModel } from "../../viewmodel/HomeViewModel"
import { LongAudioSongApiListItem } from "../apilistitem/LongAudioSongApiListItem"
import { EmptyView } from "../empty/EmptyView"
import { LongAudioSongListItem } from "./LongAudioSongListItem"

@ComponentV2
export struct LongAudioSongApiPanel {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoading: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchRecentLongAudio();
    this.isLoading = false;
  }
  build() {
    Stack() {

      Column() {
        List({ space: 0 }) {
          ForEach(
            this.homeViewModel.recentLongAudioList,
            (item: ISongInfo, index: number) => {
              ListItem() {
                Column() {
                  LongAudioSongApiListItem({ song: item, index, songList: this.homeViewModel.recentLongAudioList }).width('100%').layoutWeight(1)
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
      } else if (this.homeViewModel.recentLongAudioList.length === 0) {
        EmptyView({
          msg: '数据为空'
        })
      }
    }.width('100%').height('100%')
  }
}
