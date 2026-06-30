import { SongListItemView } from "../../view/songlist/SongListItemView";
import { SearchViewModel } from "../../viewmodel/SearchViewModel";
import { SongListViewModel } from "../../viewmodel/songlist/SongListViewModel";


@ComponentV2
export struct SongResultList{
  @Consumer('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();
  @Provider('viewModel') viewModel: SongListViewModel = this.searchViewModel.searchSongModel.songListViewModel;

  aboutToAppear(): void {
    this.viewModel.registerPlayEventListener();
  }

  aboutToDisappear(): void {
    this.viewModel.unregisterPlayEventListener();
  }

  build() {
    Column() {
      List() {
        Repeat(this.viewModel.songList).each((songInfo) => {
          SongListItemView({
            host: this.viewModel,
            songList: this.viewModel.songList,
            song: songInfo.item,
            index: songInfo.index,
          })
        })
      }
      .onReachEnd(() => {
        this.searchViewModel.searchSongModel.loadMore();
      })
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }.layoutWeight(1)
  }
}