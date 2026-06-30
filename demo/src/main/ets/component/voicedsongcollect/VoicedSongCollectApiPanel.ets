import { ISongInfo } from '@qqmusic/opisdk-qmutils';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { LongAudioSongApiListItem } from '../apilistitem/LongAudioSongApiListItem';
import { VoicedSongCollectListItem } from './VoicedSongCollectListItem';

@ComponentV2
export struct VoicedSongCollectApiPanel {

  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoadingVoicedSong: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchCollectedVoicedSong();
    this.isLoadingVoicedSong = false;
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(this.homeViewModel.collectedVoicedSongList, (item: ISongInfo,index: number) => {
            ListItem() {
              Column() {
                LongAudioSongApiListItem({
                  song: item,
                  index: index,
                  songList: this.homeViewModel.collectedVoicedSongList,
                  onUncollect: (songId: number) => {
                    const idx = this.homeViewModel.collectedVoicedSongList.findIndex(s => s.getSongId() === songId);
                    if (idx > -1) {
                      this.homeViewModel.collectedVoicedSongList.splice(idx, 1);
                    }
                  }
                }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: ISongInfo) => `${item.getSongId()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
      }.width('100%').height('100%')

      if (this.isLoadingVoicedSong) {
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
    }
  }
}
