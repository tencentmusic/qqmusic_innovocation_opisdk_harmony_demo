import { ISongInfo } from "@qqmusic/opisdk-qmutils";
import { HomeViewModel } from "../../viewmodel/HomeViewModel";
import { SongListItemView } from "../../view/songlist/SongListItemView";
import { SongApiListItemHost } from "../../view/songlist/SongApiListItemHost";

@ComponentV2
export struct SongCollectApiPanel {
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoadingSong: boolean = true;
  /** API 面板歌曲列表项宿主 */
  private host: SongApiListItemHost = new SongApiListItemHost(() => this.homeViewModel.collectedSongList)

  aboutToAppear(): void {
    this.homeViewModel.fetchCollectedSong();
    this.isLoadingSong = false;
    this.host.initCollectedState()
    // 设置取消收藏回调：从列表中移除歌曲
    this.host.onSongUncollect = (songId: number) => {
      const index = this.homeViewModel.collectedSongList.findIndex(s => s.getSongId() === songId);
      if (index > -1) {
        this.homeViewModel.collectedSongList.splice(index, 1);
      }
    }
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
              this.homeViewModel.collectedSongList,
            (item: ISongInfo, index: number) => {
              ListItem() {
                Column() {
                  SongListItemView({
                    host: this.host,
                    songList: this.homeViewModel.collectedSongList,
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
      }.width('100%').height('100%')

      if (this.isLoadingSong) {
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
    }.width('100%').height('100%')
  }
}
