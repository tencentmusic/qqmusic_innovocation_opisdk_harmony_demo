import { IObserver, OpenApiSdk } from '@qqmusic/opisdk-base';
import { IMediaResDetail, IMediaSinger, LoadType } from '@qqmusic/opisdk-entity';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { MVPlayerPageParams } from '../../nav/RouteParams';
import { ToastUtil } from '../../utils/ToastUtil';

@ComponentV2
export struct HisMvListItem {
  @Param @Require mv: IMediaResDetail;
  @Local isCollect: boolean = false;
  private observer?: IObserver<LoadType>;
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    this.observer = {
      update: (_: LoadType) => {
        this.isCollect = OpenApiSdk.personalAssetsApi?.videoFavApi.isCollectedById(this.mv.getVid()) ?? false;
      }
    };
    OpenApiSdk.personalAssetsApi?.videoFavApi.register(LoadType.VIDEO, this.observer);
    this.isCollect = OpenApiSdk.personalAssetsApi?.videoFavApi.isCollectedById(this.mv.getVid()) ?? false;
  }

  aboutToDisappear(): void {
    OpenApiSdk.personalAssetsApi?.videoFavApi.unregister(LoadType.VIDEO, this.observer);
  }

  private getDisplaySingerName(): string {
    const name = this.mv.getSingerName();
    if (name && name.length > 0) {
      return name;
    }
    // 尝试从 singers 列表补救
    const singers = this.mv.getSingers();

    if (singers && singers.length > 0) {
      const names: string[] = [];
      singers.forEach((s: IMediaSinger) => {
        const sName = s.getName();
        if (sName && sName.length > 0) {
           names.push(sName);
        }
      });

      if (names.length > 0) {
        return names.join(' & ');
      }
    }
    return 'null';
  }

  build() {
    Row() {
      Row() {
        // MV Cover (Rectangular)
        Image(this.mv.getCoverImage() || $r('app.media.logo'))
          .width(100) // 16:9ish
          .height(56) // ~16:9
          .borderRadius(4)
          .backgroundColor('#E0E0E0')
          .objectFit(ImageFit.Cover)

        Blank().width(10)

        Column() {
          Text(this.mv.getTitle())
            .fontSize(15)
            .fontWeight(FontWeight.Normal)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor('#333333')
          
          Blank().height(5)
          
          Text(this.getDisplaySingerName())
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)

      // Heart Icon
      Row() {
        Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .width(24)
          .aspectRatio(1)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            OpenApiSdk.personalAssetsApi?.videoFavApi.setCollectOrCancel(!this.isCollect, this.mv);
          })
      }
      .padding({ right: 16 })
    }.onClick(async ()=>{
          const params = new MVPlayerPageParams(this.mv.getVid() ?? '')
          this.navController.push(RouteName.MV_PLAYER_PAGE, params)

       //测试播放mv
      //AssetsReportManager.getInstance().reportRecentPlayPlay(new SongInfo(), 0, String(this.mv.getVid()), 6)

      //测试删除mv
      //if(await HistoryManager.getInstance().delRecentlyMv([this.mv.getVid() ??''])){
       //  HistoryManager.getInstance().delLocalMvRecord([this.mv])
     // }

    })
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16 })
    .backgroundColor(Color.White)
  }
}
