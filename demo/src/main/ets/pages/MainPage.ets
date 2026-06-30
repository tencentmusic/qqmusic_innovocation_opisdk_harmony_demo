import { AppSetting } from '../component/AppSetting';
import { MineViewModel } from '../viewmodel/MineViewModel';
import { HomeViewModel } from '../viewmodel/HomeViewModel';
import { PlayerViewModel } from '../viewmodel/PlayerViewModel';
import { HomePage } from './home/HomePage';
import { FloatingPlayerPage } from './FloatingPlayerPage';
import { MinePage } from './mine/MinePage';
import { SearchPage } from '../component/SearchPage';
import { globalEventHandler, MLog } from '@qqmusic/opisdk-base';
import { BaseBusinessEvent, IIconlist, IProfitInfo, IUserIconsUI, IVipInfo, LoginEvent } from '@qqmusic/opisdk-entity';
import { NavController } from '../nav/NavController';
import { ToastUtil } from '../utils/ToastUtil';
import { AppUtil } from '../utils/AppUtil';

@Entry
@ComponentV2
struct MainPage {
  @Local currentIndex: number = 0;
  private TAG = 'MainPage'
  @Provider('viewModel') mineViewModel: MineViewModel = new MineViewModel();
  @Provider('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  @Provider('playerViewModel') playerViewModel: PlayerViewModel = new PlayerViewModel();
  @Provider('navController') navController: NavController = NavController.getInstance();
  private controller: TabsController = new TabsController();

  aboutToAppear() {
    this.initGlobalEvent();
    this.playerViewModel.init();
    this.homeViewModel.init();
    this.mineViewModel.init();
  }

  aboutToDisappear() {
    // 移除监听，防止内存泄漏
    globalEventHandler.removeHandler(this);
    this.mineViewModel.onDestroy()
    this.playerViewModel.onDestroy()
  }

  /**
   * 拦截系统返回键
   * 当用户在非首页 Tab（搜索、我的、设置）时按返回键，切换到首页 Tab
   * @returns true 表示已消费返回事件，false 表示使用默认逻辑
   */
  onBackPress(): boolean {
    if (this.currentIndex !== 0) {
      MLog.i(this.TAG, `onBackPress: 从 Tab[${this.currentIndex}] 返回首页`);
      this.currentIndex = 0;
      this.controller.changeIndex(0);
      return true;
    }
    return false;
  }

  initGlobalEvent() {
    MLog.i(this.TAG, "Register Business Event Handler");
    globalEventHandler.registerHandler(this);
  }

  handle(event: BaseBusinessEvent): void {
    if (event.tag === LoginEvent.EventTag) {
      switch (event.code) {
        case LoginEvent.MusicUserLogIn:
          MLog.d(this.TAG, "Handle Event: MusicUserLogIn");
          this.showLoginDialog(true);
          // 登录成功后刷新续费提醒信息
          this.mineViewModel.refreshVipRenewalInfo();
          // 登录后刷新首页数据
          this.homeViewModel.refreshAfterLogin();
          break;

        case LoginEvent.MusicAccountAutoLoginIn:
          MLog.d(this.TAG, "Handle Event: LogIn/AutoLogin");
          this.mineViewModel.updateData();
          // 自动登录后也刷新首页数据
          this.homeViewModel.refreshAfterLogin();
          break;

        case LoginEvent.MusicUserLogOut:
          MLog.d(this.TAG, "Handle Event: MusicUserLogOut");
          this.showLoginDialog(false);
          this.homeViewModel.refreshAfterLogin();
          break;

        case LoginEvent.UserVipInfoUpdate:
          MLog.d(this.TAG, "Handle Event: UserVipInfoUpdate");
          if (event.data) {
            this.mineViewModel.userVipInfo = event.data as IVipInfo;
          }
          break;

        case LoginEvent.UserAccountLoginExpired:
          this.showLoginExpiredDialog();
          break;

        case LoginEvent.UserDeauthorization:
          MLog.d(this.TAG, "Handle Event: UserDeauthorization");
          this.showToastDialog("登录授权", "用户取消了登录授权");
          break;

        case LoginEvent.MusicAccountLoginFailed:
          this.showToastDialog("Music帐号发生变化", "Music帐号自动登录失败");
          break;

        case LoginEvent.ProfitInfoChange:
          const profitVip = event.data as IVipInfo;
          let profitName = "未知权益";
          if (profitVip) {
            const list: IProfitInfo[] | null = profitVip.getProfitInfoList();
            if (list && list.length > 0) {
              profitName = list[0].getType().toString();
            }
          }
          this.showToastDialog("试用权益发生变更", profitName);
          break;

        case LoginEvent.UserVipIconsChange:
          const iconVip = event.data as IVipInfo;
          let iconDesc = "图标更新";
          if (iconVip) {
            const ui: IUserIconsUI | null = iconVip.getUserIconsUI();
            if (ui) {
              const iconList: IIconlist[] = ui.getIconlist();
              if (iconList && iconList.length > 0) {
                iconDesc = iconList[0].getDesc();
              }
            }
          }
          this.showToastDialog("会员图标变化", iconDesc);
          break;

        case LoginEvent.AcountDeregisterPending:
          MLog.d(this.TAG, "Handle Event: AcountDeregisterPending");
          this.showLoginExpiredDialog();
          break;

        case LoginEvent.AcountDeregisterDone:
          MLog.d(this.TAG, "Handle Event: AcountDeregisterDone");
          this.showLoginExpiredDialog();
          break;
      }
    }
  }

  showLoginDialog(isLogin: boolean) {
    AppUtil.uiContext?.showAlertDialog({
      title: '用户登录状态更新',
      message: isLogin ? '登录成功' : '用户退出',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      confirm: {
        value: '知道了',
        action: () => {
        }
      }
    })
  }

  showLoginExpiredDialog() {
    AppUtil.uiContext?.showAlertDialog({
      title: '登录过期啦',
      message: '请重新登录',
      autoCancel: false,
      alignment: DialogAlignment.Center,
      confirm: {
        value: '知道了',
        action: () => {
          // 可以在这里处理跳转登录页逻辑
        }
      }
    })
  }

  showToastDialog(title: string, message: string) {
    ToastUtil.show(`${title}: ${message}`);
  }

  showTransactionDialog(data: Object | undefined) {
    AlertDialog.show({
      title: '支付/交易通知',
      message: '收到支付结果通知，详情请查看日志',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      confirm: {
        value: '关闭',
        action: () => {
        }
      }
    })
  }

  @Builder
  TabBuilder(title: string, index: number, icon: ResourceStr) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? Color.Black : Color.Gray)
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? Color.Black : Color.Gray)
        .margin({ top: 4 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  routerMap(name: string, param?: object) {
    NavController.getInstance().getPageBuilder(name)?.builder(param);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Navigation(this.navController.navPathStack) {
        Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
          // 首页 Tab
          TabContent() {
            HomePage()
          }.tabBar(this.TabBuilder("首页", 0, $r('app.media.icon_home_placeholder')))

          // 搜索 Tab
          TabContent() {
            SearchPage()
          }.tabBar(this.TabBuilder("搜索", 1, $r('app.media.icon_search_placeholder')))

          // 我的 Tab
          TabContent() {
            MinePage()
          }.tabBar(this.TabBuilder("我的", 2, $r('app.media.icon_mine_placeholder')))

          // 设置 Tab
          TabContent() {
            AppSetting()
          }.tabBar(this.TabBuilder("设置", 3, $r('app.media.icon_setting_placeholder')))
        }
        .vertical(false)
        .scrollable(false)
        .onChange((index: number) => {
          this.currentIndex = index
          // 切换到"我的"Tab 时刷新 API 数据
          if (index === 2) {
            this.homeViewModel.refreshAllApiData()
          }
        })
      }
      .hideTitleBar(true)
      .hideToolBar(true)
      .mode(NavigationMode.Stack)
      .navDestination(this.routerMap)
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_primary_dark'))

      if (this.navController.showFloatingPlayer) {
        FloatingPlayerPage()
      }
    }
    .width('100%')
    .height('100%')
  }
}
