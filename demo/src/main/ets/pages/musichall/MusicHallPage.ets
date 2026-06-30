import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'

interface HallEntry {
  name: string
  icon: Resource
  routeName: string
}

/**
 * 音乐馆页（歌手 + 排行榜入口）
 */
@ComponentV2
export struct MusicHallPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()

  private readonly entries: HallEntry[] = [
    { name: '歌手', icon: $r('app.media.icon_mine_placeholder'), routeName: RouteName.SINGER_LIST_PAGE },
    { name: '排行榜', icon: $r('app.media.icon_home_placeholder'), routeName: RouteName.RANK_LIST_PAGE },
  ]

  build() {
    Column() {
      // 入口网格
      Grid() {
        Repeat(this.entries).each((repeatItem) => {
          GridItem() {
            Column({ space: 8 }) {
              Image(repeatItem.item.icon)
                .width(48)
                .height(48)
                .objectFit(ImageFit.Contain)
                .fillColor('#6200EE')

              Text(repeatItem.item.name)
                .fontSize(14)
                .fontColor('#333333')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(12)
          }
          .onClick(() => {
            this.navController.push(repeatItem.item.routeName)
          })
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .height(160)
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
