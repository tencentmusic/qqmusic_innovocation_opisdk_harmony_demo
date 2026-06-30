import { MLog } from "@qqmusic/opisdk-base";
import { IAlbum } from "@qqmusic/opisdk-entity";
import { MusicListType } from "@qqmusic/opisdk-qmutils";
import { NavController } from "../../nav/NavController";
import { RouteName } from "../../nav/RouteMap";
import { SongListPageParams } from "../../nav/RouteParams";
import { SearchViewModel } from "../../viewmodel/SearchViewModel";

const TAG = "RadioResult"

@ComponentV2
export struct RadioResultList{
  @Consumer('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();

  build() {
    Column() {
      List() {
        Repeat(this.searchViewModel.searchRadioModel.searchRadioList).each((radio) => {
          RadioListItem({
            radio: radio.item
          })
        })
      }
      .onReachEnd(() => {
        this.searchViewModel.searchRadioModel.loadMore();
      })
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }.layoutWeight(1)
  }
}

@ComponentV2
struct RadioListItem {
  @Param @Require radio: IAlbum;

  build() {
    ListItem() {
      Row() {
        Image(this.radio.getAlbumPic())
          .aspectRatio(1)
          .height('100%')

        Column() {
          Text(this.radio.getName())
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.radio.getSingerName())
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
      MLog.i(TAG, `click album: ${this.radio.getName()}, id: ${this.radio.getId()}`);
      const params = new SongListPageParams(
        MusicListType.TYPE_ALBUM,
        this.radio.getId(),
        this.radio.getName()
      )
      NavController.getInstance().push(RouteName.SONG_LIST_PAGE, params)
    })
  }
}