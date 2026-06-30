import { MLog } from '@qqmusic/opisdk-base'
import { MineViewModel } from '../../viewmodel/MineViewModel'
import { NavController } from '../../nav/NavController'
import { UserInfoCardView } from '../../view/mine/UserInfoCardView'
import { LoginButtonAreaView } from '../../view/mine/LoginButtonAreaView'
import { MineSongListView } from '../../view/mine/MineSongListView'
import { uiObserver } from '@kit.ArkUI'
import { AppUtil } from '../../utils/AppUtil'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { DemoGlobal } from '../../utils/DemoGlobal'

const TAG: string = 'MinePage'

/**
 * "我的"页面入口，组合各子视图
 */
@ComponentV2
export struct MinePage {
  @Consumer('viewModel') viewModel: MineViewModel = new MineViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel()

  // 路由页面监听回调
  private routerListener = async (info: uiObserver.RouterPageInfo) => {
    if (info.state === uiObserver.RouterPageState.ON_PAGE_SHOW) {
      if (this.viewModel.userInfo !== null) {
        MLog.i(TAG, `MinePage observed ON_PAGE_SHOW, refreshing data...`)
        await this.viewModel.updateData()
      } else {
        MLog.i(TAG, `MinePage observed ON_PAGE_SHOW, skipping (cold start, init will handle)`)
      }
      const enablePersonalAssets = DemoGlobal.isPersonalAssets;
      MLog.i(TAG, `enablePersonalAssets = ${enablePersonalAssets}`)
      if (!enablePersonalAssets) {
        // 刷新 API 面板数据，确保收藏等数据实时更新
        this.homeViewModel.refreshAllApiData()
      }
    }
  }

  aboutToAppear(): void {
    const uiObserverInstance = AppUtil.uiContext?.getUIObserver()
    if (uiObserverInstance) {
      uiObserverInstance.on('routerPageUpdate', this.routerListener)
    }
  }

  aboutToDisappear(): void {
    const uiObserverInstance = AppUtil.uiContext?.getUIObserver()
    if (uiObserverInstance) {
      uiObserverInstance.off('routerPageUpdate', this.routerListener)
    }
  }

  build() {
    Column() {
      // 用户信息卡片
      UserInfoCardView()

      Blank().height(16)

      // 登录/退出按钮区域
      LoginButtonAreaView()
      Blank().height(16)

      // 歌单列表区域
      MineSongListView()
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 70 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }
}
