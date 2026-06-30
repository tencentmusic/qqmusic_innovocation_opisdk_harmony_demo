import { IAlbum } from '@qqmusic/opisdk-entity';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { AlbumApiListItem } from '../apilistitem/AlbumApiListItem';
import { BuyLongAudioListItem } from './BuyLongAudioListItem';

@ComponentV2
export struct BuyLongAudioApiPanel {

  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoadingAlbum: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchRecentLongAudio();
    this.isLoadingAlbum = false;
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(
              this.homeViewModel.longAudioBuyRecordList
          , (item: IAlbum) => {
            ListItem() {
              Column() {
                AlbumApiListItem({ album: item }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: IAlbum) => `${item.getId()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
      }.width('100%').height('100%')

      if (this.isLoadingAlbum) {
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
