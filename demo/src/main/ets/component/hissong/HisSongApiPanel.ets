import { OpenApiSdk } from "@qqmusic/opisdk-base"
import { ISongInfo } from "@qqmusic/opisdk-qmutils"
import { HomeViewModel } from "../../viewmodel/HomeViewModel";
import { SongListItemView } from "../../view/songlist/SongListItemView";
import { SimpleSongListItemHost } from "../../view/songlist/SimpleSongListItemHost";
import { EmptyView } from "../empty/EmptyView"

@ComponentV2
export struct HisSongApiPanel {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoading: boolean = true;
  /** 通用歌曲列表项宿主 */
  private host: SimpleSongListItemHost = new SimpleSongListItemHost(() => this.homeViewModel.recentSongList)

  aboutToAppear(): void {
    this.homeViewModel.fetchRecentSong();
    this.isLoading = false;
    this.host.registerObserver()
  }

  aboutToDisappear(): void {
    this.host.unregisterObserver()
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
            this.homeViewModel.recentSongList,
            (item: ISongInfo, index: number) => {
              ListItem() {
                Column() {
                  SongListItemView({
                    host: this.host,
                    songList: this.homeViewModel.recentSongList,
                    song: item,
                    index: index,
                    showIndex: false,
                    showTagRow: true,
                    showMvEntry: true,
                    showCollectHeart: true,
                    showPlayingIndicator: false,
                    showActionButtons: true,
                    coverSize: 60,
                    rowHeight: 80
                  }).width('100%').layoutWeight(1)
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
      } else if (this.homeViewModel.recentSongList.length === 0) {
        EmptyView({
          msg: '数据为空'
        })
      }
    }.width('100%').height('100%')
  }
}
