import { ISearchMVInfo } from "@qqmusic/opisdk-entity";
import { NavController } from "../../nav/NavController";
import { RouteName } from "../../nav/RouteMap";
import { MVPlayerPageParams } from "../../nav/RouteParams";
import { SearchViewModel } from "../../viewmodel/SearchViewModel";

@ComponentV2
export struct MvResultList{
  @Consumer('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();

  build() {
    Column() {
      List() {
        Repeat(this.searchViewModel.searchMVModel.searchMVInfoList).each((mvInfo) => {
          MvListItem({
            mvInfo: mvInfo.item
          })
        })
      }
      .onReachEnd(() => {
        this.searchViewModel.searchMVModel.loadMore();
      })
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }.layoutWeight(1)
  }
}

@ComponentV2
struct MvListItem {
  @Param @Require mvInfo: ISearchMVInfo;

  build() {
    ListItem() {
      Row() {
        Image(this.mvInfo.getPicUrl())
          .aspectRatio(1)

        Column() {
          Text(`标题：${this.mvInfo.getMvTitle()}`)
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`歌手：${this.mvInfo.getSingerName()}`)
            .fontSize(12)
            .fontColor(Color.Gray)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`播放量：${this.mvInfo.getPlayCount()}`)
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
      const vid = this.mvInfo.getMvVid()
      if (vid) {
        const params = new MVPlayerPageParams(vid)
        NavController.getInstance().push(RouteName.MV_PLAYER_PAGE, params)
      }
    })
  }
}