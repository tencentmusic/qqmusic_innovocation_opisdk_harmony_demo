import { MLog } from "@qqmusic/opisdk-base";
import { NavController } from "../../nav/NavController";
import { RouteName } from "../../nav/RouteMap";
import { SingerDetailPageParams } from "../../nav/RouteParams";
import { SearchViewModel } from "../../viewmodel/SearchViewModel";
import { ISinger } from "@qqmusic/opisdk-qmutils";

const TAG = "SingerResult"

@ComponentV2
export struct SingerResultList{
  @Consumer('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();

  build() {
    Column() {
      List() {
        Repeat(this.searchViewModel.searchSingerModel.searchSingerList).each((singer) => {
          SingerListItem({
            singer: singer.item
          })
        })
      }
      .onReachEnd(() => {
        this.searchViewModel.searchSingerModel.loadMore();
      })
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }.layoutWeight(1)
  }
}

@ComponentV2
struct SingerListItem{

  @Param @Require singer: ISinger;

  build() {
    ListItem() {
      Row() {
        Image(this.singer.getSingerPic())
          .aspectRatio(1)
          .height('100%')

        Column() {
          Text('歌手ID ：' + this.singer.getSingerId())
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('歌手 ：' + this.singer.getSingerName())
            .fontSize(16)
            .fontColor(Color.Black)
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
      MLog.i(TAG, `click singer: ${this.singer.getSingerName()}, id: ${this.singer.getSingerId()}`);
      const params = new SingerDetailPageParams(
        this.singer.getSingerId(),
        this.singer.getSingerMid() ?? '',
        this.singer.getSingerName()
      );
      NavController.getInstance().push(RouteName.SINGER_DETAIL_PAGE, params);
    })
  }
}