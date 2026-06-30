import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IAlbum } from '@qqmusic/opisdk-entity';
import { MusicListType } from '@qqmusic/opisdk-qmutils';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { SongListPageParams } from '../../nav/RouteParams';
import { ToastUtil } from '../../utils/ToastUtil';

@ComponentV2
export struct AlbumApiListItem {
  @Param @Require album: IAlbum;
  /** 取消收藏后的回调，用于通知父组件从列表中移除该项 */
  @Event onUncollect?: (albumId: number) => void;
  @Local isCollect: boolean = false;
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    this.isCollect = this.album.getFavState() === 1 ;
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
            if (this.isCollect) {
              OpenApiSdk.openApi?.albumApi.collectAlbum(false, [this.album.getId()])
                .then((resp)=>{
                  if (resp.isSuccess()) {
                    ToastUtil.show('取消收藏成功');
                    this.isCollect = !this.isCollect;
                    if (this.onUncollect) {
                      this.onUncollect(this.album.getId());
                    }
                  } else {
                    ToastUtil.show('取消收藏失败 ' + resp.errorMsg);
                  }
                })
            } else {
              OpenApiSdk.openApi?.albumApi.collectAlbum(true, [this.album.getId()])
                .then((resp)=>{
                  if (resp.isSuccess()) {
                    ToastUtil.show('收藏成功');
                    this.isCollect = !this.isCollect;
                  } else {
                    ToastUtil.show('收藏失败 ' + resp.errorMsg);
                  }
                })
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
