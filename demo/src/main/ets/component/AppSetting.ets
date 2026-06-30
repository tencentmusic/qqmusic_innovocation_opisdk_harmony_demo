import { NavController } from '../nav/NavController';
import { RouteName } from '../nav/RouteMap';

@ComponentV2
export struct AppSetting {
  @Consumer('navController') navController: NavController = NavController.getInstance()

  build() {
    Column() {
      List() {
        ListItem() {
          this.SettingItem("其他设置页面", "", () => {
            this.navController.push(RouteName.OTHER_SETTING_PAGE)
          })
        }

        ListItem() {
          this.SettingItem("Debug调试页面", "", () => {
            this.navController.push(RouteName.DEBUG_SETTING_PAGE)
          })
        }

        ListItem() {
          this.SettingItem("本地歌曲匹配调试", "", () => {
            this.navController.push(RouteName.LOCAL_MATCH_PAGE)
          })
        }

        ListItem() {
          this.SettingItem("关于", "", () => {
            this.navController.push(RouteName.ABOUT_PAGE)
          })
        }

        // ListItem() {
        //   this.SettingItem("调试直播（测试环境）", "", () => {
        //     this.navController.push(RouteName.EDGE_LIVE_PLAYER_DEMO_PAGE)
        //   })
        // }
      }
      .width('100%')
      .divider({ strokeWidth: 1, color: '#EFEFEF' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  SettingItem(title: string, subTitle: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(16).fontColor(Color.Black)
      Blank()
      Text(subTitle).fontSize(14).fontColor(Color.Red).margin({ right: 5 })
      Image($r('app.media.icon_right_arrow_placeholder'))
        .width(16).height(16)
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 10 })
    .onClick(onClick)
  }
}