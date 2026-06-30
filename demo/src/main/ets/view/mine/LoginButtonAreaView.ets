import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import { MineViewModel } from '../../viewmodel/MineViewModel'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { AppUtil } from '../../utils/AppUtil'
import { PhoneLoginDialog } from '../../dialog/PhoneLoginDialog'
import { OpenIdLoginDialog } from '../../dialog/OpenIdLoginDialog'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { KeyValueParams } from '../../nav/RouteParams'
import { ToastUtil } from '../../utils/ToastUtil'

const TAG: string = 'LoginButtonAreaView'

/**
 * 微信 AppID，由接入方配置。
 */
const WX_APP_ID: string = 'wx5aa333606550dfd5'
/**
 * 登录按钮区域：
 * - 未登录：显示多种登录方式按钮网格
 * - 已登录：显示退出登录 + 常驻按钮（第三方登录、token登录）
 */
@ComponentV2
export struct LoginButtonAreaView {
  @Consumer('viewModel') viewModel: MineViewModel = new MineViewModel()
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local loginText: string = ''
  phoneDialogController: CustomDialogController = new CustomDialogController({
    builder: PhoneLoginDialog(),
    alignment: DialogAlignment.Center
  })
  openIdDialogController: CustomDialogController = new CustomDialogController({
    builder: OpenIdLoginDialog(),
    alignment: DialogAlignment.Center
  })

  // 登录方式列表
  private readonly loginMethods: string[] =
    ['扫码登录', 'QQ登录', '微信登录', 'QQ音乐登录', '手机登录', 'OpenID登录', '第三方登录', 'token登录']

  build() {
    Column() {
      if (this.viewModel.loginInfo) {
        // 已登录状态
        this.buildLoggedInButtons()
      } else {
        // 未登录状态
        this.buildLoginMethodsGrid()
      }

      // 登录状态提示文字
      if (this.loginText.length > 0) {
        Text(this.loginText)
          .margin(10)
          .fontSize(12)
          .fontColor(Color.Gray)
      }
    }
    .width('100%')
  }

  /**
   * 已登录状态的按钮行
   */
  @Builder
  buildLoggedInButtons() {
    Row({ space: 8 }) {
      // 退出登录
      Button("退出登录")
        .fontSize(12)
        .fontColor(Color.Black)
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: Color.Black })
        .borderRadius(8)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .onClick(() => {
          this.viewModel.logout()
          this.homeViewModel.refreshAfterLogin()
        })

      // 第三方登录
      Button("第三方登录")
        .fontSize(12)
        .fontColor(Color.Black)
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: Color.Black })
        .borderRadius(8)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .onClick(() => {
          this.navController.push(RouteName.PARTNER_LOGIN_PAGE, new KeyValueParams('HarmonyDevice'))
        })

      // token 登录
      Button("token登录")
        .fontSize(12)
        .fontColor(Color.Black)
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: Color.Black })
        .borderRadius(8)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .onClick(() => {
          ToastUtil.show("暂不支持token登录")
        })
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  /**
   * 未登录状态的登录方式网格
   */
  @Builder
  buildLoginMethodsGrid() {
    Grid() {
      Repeat(this.loginMethods).each((repeatItem) => {
        GridItem() {
          Text(repeatItem.item)
            .fontColor(Color.Black)
            .fontSize(11)
            .borderRadius(8)
            .border({ color: Color.Black, width: 1 })
            .padding({ left: 8, right: 8, top: 6, bottom: 6 })
            .textAlign(TextAlign.Center)
            .width('100%')
            .onClick(() => {
              this.handleLoginMethodClick(repeatItem.item)
            })
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .height(80)
    .padding({ left: 16, right: 16 })
  }

  /**
   * 处理登录方式点击
   */
  private handleLoginMethodClick(item: string): void {
    if (item === '扫码登录') {
      this.navController.push(RouteName.OPI_QR_CODE_PAGE, new KeyValueParams('HarmonyDevice'))
    } else if (item === 'QQ登录') {
      const abilityContext = AppUtil.abilityContext
      if (abilityContext) {
        OpenApiSdk.loginApi?.loginManager.qqLoginWeb(abilityContext,
          async (sus: boolean, msg: string | undefined) => {
            if (sus) {
              MLog.i(TAG, "QQ登录成功")
              await this.viewModel.updateData()
              this.homeViewModel.refreshAfterLogin()
              return
            }
            MLog.e(TAG, "QQ登录失败: " + msg)
            ToastUtil.show("登录失败: " + (msg ?? ''))
          })
      } else {
        ToastUtil.show("上下文未初始化")
      }
    } else if (item === '微信登录') {
      ToastUtil.show("暂不支持微信登录")
      // const uiContext = AppUtil.abilityContext
      // if (uiContext) {
      //   OpenApiSdk.loginApi?.loginManager.wxLogin(uiContext, WX_APP_ID).then(
      //     async (res) => {
      //       if (res.data) {
      //         ToastUtil.show('正在唤起微信...')
      //         await this.viewModel.updateData()
      //         this.homeViewModel.refreshAfterLogin()
      //       } else {
      //         ToastUtil.show(res.errorMsg)
      //       }
      //     })
      // } else {
      //   ToastUtil.show('UI上下文未初始化')
      // }
    } else if (item === 'QQ音乐登录') {
      ToastUtil.show("暂不支持QQ音乐登录")
      // const abilityContext = AppUtil.abilityContext
      // if (abilityContext) {
      //   OpenApiSdk.loginApi?.loginManager.qqMusicLogin(abilityContext,
      //     async (sus: boolean, msg: string | undefined) => {
      //       if (sus) {
      //         MLog.i(TAG, "QQ音乐登录成功")
      //         await this.viewModel.updateData()
      //         this.homeViewModel.refreshAfterLogin()
      //         return
      //       }
      //       MLog.e(TAG, "QQ音乐登录失败: " + msg)
      //       ToastUtil.show("QQ音乐登录失败: " + (msg ?? ''))
      //     })
      // } else {
      //   ToastUtil.show("上下文未初始化")
      // }
    } else if (item === '手机登录') {
      ToastUtil.show("暂不支持手机号登录")
      // this.phoneDialogController.open()
    } else if (item === 'OpenID登录') {
      ToastUtil.show("暂不支持OpenID登录")
      // this.openIdDialogController.open()
    } else if (item === '第三方登录') {
      this.navController.push(RouteName.PARTNER_LOGIN_PAGE, new KeyValueParams('HarmonyDevice'))
    } else if (item === 'token登录') {
      ToastUtil.show("暂不支持token登录")
    }
  }
}
