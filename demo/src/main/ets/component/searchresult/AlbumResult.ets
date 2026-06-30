import { MLog } from "@qqmusic/opisdk-base";
import { IAlbum } from "@qqmusic/opisdk-entity";
import { MusicListType } from "@qqmusic/opisdk-qmutils";
import { NavController } from "../../nav/NavController";
import { RouteName } from "../../nav/RouteMap";
import { SongListPageParams } from "../../nav/RouteParams";
import { SearchViewModel } from "../../viewmodel/SearchViewModel";

const TAG = "AlbumResult"

@ComponentV2
export struct AlbumResultList{
  @Consumer('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();

  build() {
    Column() {
      List() {
        Repeat(this.searchViewModel.searchAlbumModel.searchAlbumList).each((album) => {
          AlbumListItem({
            album: album.item
          })
        })
      }
      .onReachEnd(() => {
        this.searchViewModel.searchAlbumModel.loadMore();
      })
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }.layoutWeight(1)
  }
}

@ComponentV2
struct AlbumListItem{

  @Param @Require album: IAlbum;

  build() {
    ListItem() {
      Row() {
        Image(this.album.getAlbumPic())
          .aspectRatio(1)
          .height('100%')

        Column() {
          Text(this.album.getName())
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.album.getSingerName())
            .fontSize(12)
            .fontColor(Color.Gray)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(50)
    }
    .onClick(() => {
      MLog.i(TAG, `click album: ${this.album.getName()}, id: ${this.album.getId()}`);
      const params = new SongListPageParams(
        MusicListType.TYPE_ALBUM,
        this.album.getId(),
        this.album.getName()
      )
      NavController.getInstance().push(RouteName.SONG_LIST_PAGE, params);
    })
  }
}