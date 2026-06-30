import { IObserver, MLog, OpenApiSdk } from "@qqmusic/opisdk-base"
import { NavController } from "../../nav/NavController"
import { RouteName } from "../../nav/RouteMap"
import { SingerDetailPageParams } from "../../nav/RouteParams"
import { ISinger } from "@qqmusic/opisdk-qmutils"
import { LoadType } from "@qqmusic/opisdk-entity"
import { ToastUtil } from "../../utils/ToastUtil"

@ComponentV2
export struct SingerCollectListItem {
  @Param @Require singer: ISinger
  /** 是否启用 personalAssets 模式 */
  @Param enablePersonalAssets: boolean = true;
  /** 取消订阅后的回调 */
  @Event onUncollect?: (singerId: number) => void;
  // 观察者对象
  private observer?: IObserver<LoadType>
  @Local isCollect: boolean = false
  @Consumer('navController') navController: NavController = NavController.getInstance()

  aboutToAppear(): void {
    if (this.enablePersonalAssets) {
      this.observer = {
        update: (_: LoadType) => {
          this.isCollect = OpenApiSdk.personalAssetsApi?.singerFavApi.isCollected(this.singer) ?? false;
        }
      }

      OpenApiSdk.personalAssetsApi?.singerFavApi.register(LoadType.SINGER, this.observer)

      this.isCollect = OpenApiSdk.personalAssetsApi?.singerFavApi.isCollected(this.singer) ?? false;
    } else {
      // API 模式：订阅歌手列表中的歌手默认都是已订阅状态
      this.isCollect = true;
    }
  }

  aboutToDisappear(): void {
    if (this.enablePersonalAssets) {
      OpenApiSdk.personalAssetsApi?.singerFavApi.unregister(LoadType.SINGER, this.observer)
    }
  }

  build() {
    Row() {
      Row() {
        Image(this.getAvatar()).width(60).aspectRatio(1).borderRadius(30)
        Blank().width(10)
        Row() {
          Column() {
            Text('歌手ID: ' + this.singer.getSingerId()).fontSize(15).fontWeight(FontWeight.Bold)
            Blank().height(10)
            Text('歌手: ' + this.singer.getSingerName()).fontSize(15)
          }.alignItems(HorizontalAlign.Start)
          Image(this.isCollect ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart')).width(44).height(44).onClick(() => {
            if (this.enablePersonalAssets) {
              OpenApiSdk.personalAssetsApi?.singerFavApi.setCollectOrCancel(!this.isCollect, this.singer)
            } else {
              // API 模式：取消订阅歌手
              OpenApiSdk.openApi?.singerApi.collectSinger(false, [this.singer.getSingerId()])
                .then((resp) => {
                  if (resp.isSuccess()) {
                    ToastUtil.show('取消订阅成功');
                    this.isCollect = false;
                    if (this.onUncollect) {
                      this.onUncollect(this.singer.getSingerId());
                    }
                  } else {
                    ToastUtil.show('取消订阅失败 ' + resp.errorMsg);
                  }
                });
            }
          })
        }.height('100%').layoutWeight(1).padding({ left: 10, right: 10}).justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center)
      }.onClick(()=>{
        const params = new SingerDetailPageParams(
          this.singer.getSingerId(),
          this.singer.getSingerMid() ?? '',
          this.singer.getSingerName()
        )
        this.navController.push(RouteName.SINGER_DETAIL_PAGE, params)
      })
    }.width('100%').height('100%').justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center)
  }

  getAvatar(): string | null {
    if (this.singer.getSingerPic()) {
      return this.singer.getSingerPic()
    } else if (this.singer.getSingerPic150x150()) {
      return this.singer.getSingerPic150x150()
    } else if (this.singer.getSingerPic300x300()) {
      return this.singer.getSingerPic300x300()
    } else if (this.singer.getSingerPic500x500()) {
      return this.singer.getSingerPic500x500()
    } else {
      return null
    }
  }
}
