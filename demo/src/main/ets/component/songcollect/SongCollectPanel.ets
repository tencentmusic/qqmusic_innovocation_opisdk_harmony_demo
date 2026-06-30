import { OpenApiSdk } from "@qqmusic/opisdk-base"
import { PersonalAssetsDataInfoRetCode } from "@qqmusic/opisdk-entity"
import { ISongInfo } from "@qqmusic/opisdk-qmutils";
import { EmptyView } from "../empty/EmptyView"
import { SongListItemView } from "../../view/songlist/SongListItemView"
import { SimpleSongListItemHost } from "../../view/songlist/SimpleSongListItemHost"

@ComponentV2
export struct SongCollectPanel {
  @Param showTurnThePage: boolean = false // 是否显示翻页面板
  /** 通用歌曲列表项宿主 */
  private host: SimpleSongListItemHost = new SimpleSongListItemHost(() => this.currentSongList)

  aboutToAppear(): void {
    this.host.registerObserver()
  }

  aboutToDisappear(): void {
    this.host.unregisterObserver()
  }

  /** 当前歌曲列表（供 host 和 ForEach 使用） */
  private get currentSongList(): ISongInfo[] {
    return OpenApiSdk.personalAssetsApi?.songFavApi.getData().list ?? []
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
            this.currentSongList,
            (item: ISongInfo, index: number) => {
              ListItem() {
                Column() {
                  SongListItemView({
                    host: this.host,
                    songList: this.currentSongList,
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

        if (this.showTurnThePage) {
          Blank().height(10)
          Row() {
            Button('刷新').onClick(() => {
              this.songApi?.refresh()
            })
            Button('下一页').onClick(() => {
              if (OpenApiSdk.personalAssetsApi?.songFavApi.hasMore()) {
                OpenApiSdk.personalAssetsApi?.songFavApi.nextPage()
              }
            })
          }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
        }
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
      } else {
        if (this.requestSongIsError) {
          EmptyView({
            msg: OpenApiSdk.personalAssetsApi?.songFavApi.getData().message
          })
        }
      }

    }.width('100%').height('100%')
  }

  @Computed get songApi() {
   return OpenApiSdk.personalAssetsApi?.songFavApi
  }

  @Computed get isLoadingSong() {
    return this.songApi?.getData().isLoading
  }

  @Computed get requestSongIsError() {
    return this.songApi?.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }
}
