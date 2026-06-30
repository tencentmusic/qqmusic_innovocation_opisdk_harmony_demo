import { ILyricInfo } from "@qqmusic/opisdk-entity";
import { NavController } from "../../nav/NavController";
import { RouteName } from "../../nav/RouteMap";
import { SearchViewModel } from "../../viewmodel/SearchViewModel";

@ComponentV2
export struct LyricResultList{
  @Consumer('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();

  build() {
    Column() {
      List() {
        Repeat(this.searchViewModel.searchLyricModel.searchLyricInfoList).each((lyricInfo) => {
          LyricListItem({
            lyric: lyricInfo.item
          })
        })
      }
      .onReachEnd(() => {
        this.searchViewModel.searchLyricModel.loadMore();
      })
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }.layoutWeight(1)
  }
}

@ComponentV2
struct LyricListItem{

  @Param @Require lyric: ILyricInfo;

  build() {
    ListItem() {
      Row() {
        Column() {
          Text('歌曲：' + this.lyric.getSongName())
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('专辑：' + this.lyric.getAlbumName())
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('歌手：' + this.lyric.getSingerName())
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height(60)
    }
    .onClick(() => {
      NavController.getInstance().push(RouteName.LYRIC_PAGE, this.lyric);
    })
  }
}