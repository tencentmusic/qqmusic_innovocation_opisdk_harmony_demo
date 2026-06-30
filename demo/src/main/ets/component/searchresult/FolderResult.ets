import { MLog } from "@qqmusic/opisdk-base";
import { IFolder } from "@qqmusic/opisdk-entity";
import { MusicListType } from "@qqmusic/opisdk-qmutils";
import { NavController } from "../../nav/NavController";
import { RouteName } from "../../nav/RouteMap";
import { SongListPageParams } from "../../nav/RouteParams";
import { SearchViewModel } from "../../viewmodel/SearchViewModel";

const TAG = "FolderResult"

@ComponentV2
export struct FolderResultList{
  @Consumer('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();

  build() {
    Column() {
      List() {
        Repeat(this.searchViewModel.searchFolderModel.searchFolderList).each((folder) => {
          FolderListItem({
            folder: folder.item
          })
        })
      }
      .onReachEnd(() => {
        this.searchViewModel.searchFolderModel.loadMore();
      })
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }.layoutWeight(1)
  }
}

@ComponentV2
struct FolderListItem{

  @Param @Require folder: IFolder;

  build() {
    ListItem() {
      Row() {
        Image(this.folder.getPicUrl())
          .aspectRatio(1)
          .height('100%')

        Column() {
          Text(this.folder.getName())
            .fontSize(16)
            .fontColor(Color.Black)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${this.folder.getSongNum()} 首`)
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
      MLog.i(TAG, `click folder: ${this.folder.getName()}, id: ${this.folder.getId()}`);
      const params = new SongListPageParams(
        MusicListType.TYPE_FOLDER,
        this.folder.getId(),
        this.folder.getName()
      );
      NavController.getInstance().push(RouteName.SONG_LIST_PAGE, params);
    })
  }
}