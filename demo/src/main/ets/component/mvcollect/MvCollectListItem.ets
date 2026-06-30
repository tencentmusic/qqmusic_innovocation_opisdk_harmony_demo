import { IObserver, OpenApiSdk } from '@qqmusic/opisdk-base';
import { IMediaResDetail, IMediaSinger, LoadType, OperateMediaCollectCmd } from '@qqmusic/opisdk-entity';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { MVPlayerPageParams } from '../../nav/RouteParams';

@ComponentV2
export struct MvCollectListItem {
  @Param @Require mv: IMediaResDetail;
  /** 是否启用 personalAssets 模式（影响收藏状态判断和操作方式） */
  @Param enablePersonalAssets: boolean = true;
  /** 取消收藏后的回调，用于通知父组件从列表中移除该项 */
  @Event onUncollect?: (vid: string) => void;
  @Local isCollect: boolean = false;
  private observer?: IObserver<LoadType>;
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    if (this.enablePersonalAssets) {
      // personalAssets 模式：通过 VideoCollectManager 判断收藏状态
      this.observer = {
        update: (_: LoadType) => {
          this.isCollect = OpenApiSdk.personalAssetsApi?.videoFavApi.isCollectedById(this.mv.getVid()) ?? false;
        }
      };
      OpenApiSdk.personalAssetsApi?.videoFavApi.register(LoadType.VIDEO, this.observer);
      this.isCollect = OpenApiSdk.personalAssetsApi?.videoFavApi.isCollectedById(this.mv.getVid()) ?? false;
    } else {
      // API 模式：直接从数据对象的 is_fav 字段判断
      this.isCollect = this.mv.getIsCollect() === 1;
    }
  }

  aboutToDisappear(): void {
    if (this.enablePersonalAssets) {
      OpenApiSdk.personalAssetsApi?.videoFavApi.unregister(LoadType.VIDEO, this.observer);
    }
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
            if (this.enablePersonalAssets) {
              // personalAssets 模式
              OpenApiSdk.personalAssetsApi?.videoFavApi.setCollectOrCancel(!this.isCollect, this.mv);
            } else {
              // API 模式：直接调用 API 并更新本地状态
              const operate = this.isCollect ? OperateMediaCollectCmd.UN_COLLECT : OperateMediaCollectCmd.COLLECT;
              OpenApiSdk.openApi?.edgeMediaApi.operateMediaCollectStatus([this.mv], operate)
                .then((resp) => {
                  if (resp && resp.isSuccess()) {
                    this.isCollect = !this.isCollect;
                    // 取消收藏时通知父组件移除该项
                    if (!this.isCollect && this.onUncollect) {
                      this.onUncollect(this.mv.getVid() ?? '');
                    }
                  }
                });
            }
          })
      }
      .padding({ right: 16 })
    }.onClick(async ()=>{
      const params = new MVPlayerPageParams(this.mv.getVid() ?? '')
      this.navController.push(RouteName.MV_PLAYER_PAGE, params)
       //测试播放mv
      //AssetsReportManager.getInstance().reportRecentPlayMv(this.mv)

      //测试删除mv
        // HistoryMvManager.getInstance().delLocalMvRecord([this.mv])


    })
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16 })
    .backgroundColor(Color.White)
  }
}
