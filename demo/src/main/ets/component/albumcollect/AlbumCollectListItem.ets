import { IObserver, OpenApiSdk } from '@qqmusic/opisdk-base';
import { IAlbum, LoadType } from '@qqmusic/opisdk-entity';
import { MusicListType } from '@qqmusic/opisdk-qmutils';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { SongListPageParams } from '../../nav/RouteParams';

@ComponentV2
export struct AlbumCollectListItem {
  @Param @Require album: IAlbum;
  // 观察者对象
  private observer?: IObserver<LoadType>;
  @Local isCollect: boolean = false;
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    this.observer = {
      update: (_: LoadType) => {
        this.isCollect = OpenApiSdk.personalAssetsApi?.albumFavApi.isCollectedById(this.album.getId().toString()) ?? false;
      }
    };

    OpenApiSdk.personalAssetsApi?.albumFavApi.register(LoadType.ALBUM, this.observer);

    this.isCollect = OpenApiSdk.personalAssetsApi?.albumFavApi.isCollectedById(this.album.getId().toString()) ?? false;
  }

  aboutToDisappear(): void {
    OpenApiSdk.personalAssetsApi?.albumFavApi.unregister(LoadType.ALBUM, this.observer);
  }

  private getSingerName(): string {
    let name = this.album.getSingerName();
    if (name) {
      return name;
    }
    let singers = this.album.getSingers();
    if (singers && singers.length > 0) {
      return singers[0].getSingerName();
    }
    return 'null';
  }

  build() {
    Row() {
      Row() {
        // 专辑封面
        Image(this.album.getAlbumSmallUrl() || this.album.getAlbumPic() || $r('app.media.logo'))
          .width(60)
          .aspectRatio(1)
          .borderRadius(4)
          .backgroundColor('#E0E0E0')
          .objectFit(ImageFit.Cover)

        Blank().width(10)

        Column() {
          Text(this.album.getName())
            .fontSize(15)
            .fontWeight(FontWeight.Normal)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor('#333333')
          
          Blank().height(5)
          
          Text(this.getSingerName())
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .onClick(async ()=>{
        const params = new SongListPageParams(
          MusicListType.TYPE_ALBUM,
          this.album.getId(),
          this.album.getName()
        )
        this.navController.push(RouteName.SONG_LIST_PAGE, params)
         //测试删除专辑
          //HistoryAlbumManager.getInstance().delLocalAlbumRecord([this.album ])

        //测试最近播放记录专辑
         //AssetsReportManager.getInstance().reportRecentPlay(new SongInfo(), 11, this.album.getId())

      })

      // 收藏红心
      Row() {
        Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .width(24)
          .aspectRatio(1)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            OpenApiSdk.personalAssetsApi?.albumFavApi.setCollectOrCancel(!this.isCollect, this.album);
          })
      }
      .padding({ right: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16 })
    .backgroundColor(Color.White)
  }
}
