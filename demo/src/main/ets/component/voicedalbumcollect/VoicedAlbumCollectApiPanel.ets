import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IAlbum, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { AlbumApiListItem } from '../apilistitem/AlbumApiListItem';
import { EmptyView } from '../empty/EmptyView';
import { VoicedAlbumCollectListItem } from './VoicedAlbumCollectListItem';

@ComponentV2
export struct VoicedAlbumCollectApiPanel {

  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Local isLoadingVoicedAlbum: boolean = true;

  aboutToAppear(): void {
    this.homeViewModel.fetchCollectedVoicedAlbum();
    this.isLoadingVoicedAlbum = false;
  }

  build() {
    Stack() {
      Column() {
        List({ space: 0 }) {
          ForEach(this.homeViewModel.collectedVoicedAlbumList, (item: IAlbum) => {
            ListItem() {
              Column() {
                AlbumApiListItem({
                  album: item,
                  onUncollect: (albumId: number) => {
                    const index = this.homeViewModel.collectedVoicedAlbumList.findIndex(a => a.getId() === albumId);
                    if (index > -1) {
                      this.homeViewModel.collectedVoicedAlbumList.splice(index, 1);
                    }
                  }
                }).width('100%').layoutWeight(1)
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

      if (this.isLoadingVoicedAlbum) {
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
