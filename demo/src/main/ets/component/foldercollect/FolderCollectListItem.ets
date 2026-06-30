import { IObserver, OpenApiSdk } from '@qqmusic/opisdk-base';
import { IFolder, LoadType } from '@qqmusic/opisdk-entity';
import { MusicListType } from '@qqmusic/opisdk-qmutils';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { SongListPageParams } from '../../nav/RouteParams';
import { ToastUtil } from '../../utils/ToastUtil';

@ComponentV2
export struct FolderCollectListItem {
  @Param @Require folder: IFolder;
  /** 是否启用 personalAssets 模式 */
  @Param enablePersonalAssets: boolean = true;
  /** 取消收藏后的回调 */
  @Event onUncollect?: (folderId: number) => void;
  @Local isCollect: boolean = false;
  private observer?: IObserver<LoadType>;
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    if (this.enablePersonalAssets) {
      this.observer = {
        update: (_: LoadType) => {
          this.isCollect = OpenApiSdk.personalAssetsApi?.folderFavApi.isCollectedById(this.folder.getId().toString()) ?? false;
        }
      };
      OpenApiSdk.personalAssetsApi?.folderFavApi.register(LoadType.COLLECT_FOLDER, this.observer);
      this.isCollect = OpenApiSdk.personalAssetsApi?.folderFavApi.isCollectedById(this.folder.getId().toString()) ?? false;
    } else {
      // API 模式：收藏歌单列表中的歌单默认都是已收藏状态
      this.isCollect = true;
    }
  }

  aboutToDisappear(): void {
    if (this.enablePersonalAssets) {
      OpenApiSdk.personalAssetsApi?.folderFavApi.unregister(LoadType.COLLECT_FOLDER, this.observer);
    }
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

      // Heart Icon
      Row() {
        Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .width(24)
          .aspectRatio(1)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            if (this.enablePersonalAssets) {
              OpenApiSdk.personalAssetsApi?.folderFavApi.setCollectOrCancel(!this.isCollect, this.folder);
            } else {
              // API 模式：取消收藏歌单
              OpenApiSdk.openApi?.folderApi.unCollectFolder(this.folder.getId())
                .then((resp) => {
                  if (resp.isSuccess()) {
                    ToastUtil.show('取消收藏成功');
                    this.isCollect = false;
                    if (this.onUncollect) {
                      this.onUncollect(this.folder.getId());
                    }
                  } else {
                    ToastUtil.show('取消收藏失败 ' + resp.errorMsg);
                  }
                });
            }
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
