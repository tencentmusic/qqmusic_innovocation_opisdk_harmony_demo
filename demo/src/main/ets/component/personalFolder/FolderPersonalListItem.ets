import { IObserver, OpenApiSdk } from '@qqmusic/opisdk-base';
import { IFolder, LoadType } from '@qqmusic/opisdk-entity';
import { MusicListType } from '@qqmusic/opisdk-qmutils';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { SongListPageParams } from '../../nav/RouteParams';

@ComponentV2
export struct FolderPersonalListItem {
  @Param @Require folder: IFolder;
  @Local isCollect: boolean = false;
  private observer?: IObserver<LoadType>;
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    this.observer = {
      update: (_: LoadType) => {
        this.isCollect = OpenApiSdk.personalAssetsApi?.folderFavApi.isCollectedById(this.folder.getId().toString()) ?? false;
      }
    };
    OpenApiSdk.personalAssetsApi?.folderFavApi.register(LoadType.COLLECT_FOLDER, this.observer);
    this.isCollect = OpenApiSdk.personalAssetsApi?.folderFavApi.isCollectedById(this.folder.getId().toString()) ?? false;
  }

  aboutToDisappear(): void {
    OpenApiSdk.personalAssetsApi?.folderFavApi.unregister(LoadType.COLLECT_FOLDER, this.observer);
  }

  build() {
    Row() {
      Row() {
        // Image
        Image(this.folder.getPicUrl() || $r('app.media.logo'))
          .width(60)
          .aspectRatio(1)
          .borderRadius(4)
          .backgroundColor('#E0E0E0')
          .objectFit(ImageFit.Cover)

        Blank().width(10)

        Column() {
          Text(this.folder.getName())
            .fontSize(15)
            .fontWeight(FontWeight.Normal)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor('#333333')
          
          Blank().height(5)
          
          Text(`${this.folder.getSongNum() || 0}首`)
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
           MusicListType.TYPE_FOLDER,
           this.folder.getId(),
           this.folder.getName()
         )
         this.navController.push(RouteName.SONG_LIST_PAGE, params)

        // //测试删除
        //    HistoryFolderManager.getInstance().delLocalFolderRecord([this.folder ])
        //
        //
        //  //测试最近播放记录
        //  AssetsReportManager.getInstance().reportRecentPlay(new SongInfo(), 16, this.folder.getId())
      })

      // Heart Icon (Assuming standardized interaction)
      Row() {
        Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .width(24)
          .aspectRatio(1)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            OpenApiSdk.personalAssetsApi?.folderFavApi.setCollectOrCancel(!this.isCollect, this.folder);
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
