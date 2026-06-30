import { MLog } from '@qqmusic/opisdk-base'
import { Route } from './Route'
import { RouteMap } from './RouteMap'

/**
 * @Description: 导航栈管理类，所有页面的导航操作收归到此处
 */
const TAG = 'NavController'

@ObservedV2
export class NavController {
  private static instance: NavController
  private _navPathStack: NavPathStack = new NavPathStack()

  /** 是否显示悬浮播放器 FloatingPlayerPage */
  @Trace showFloatingPlayer: boolean = true
  /** 当前是否在首页*/
  @Trace isAtHome: boolean = true

  get navPathStack(): NavPathStack {
    return this._navPathStack
  }

  static getInstance(): NavController {
    if (!NavController.instance) {
      NavController.instance = new NavController()
    }
    return NavController.instance
  }

  constructor() {
    this._navPathStack.setInterception({
      willShow: (from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
        operation: NavigationOperation) => {
        const fromPage = (from as NavDestinationContext)?.pathInfo?.name
        const toPage = (to as NavDestinationContext)?.pathInfo?.name
        MLog.i(TAG, `[NavigationInterception] willShow from=${fromPage}, to=${toPage}, operation=${operation}`)
        if (toPage) {
          // 导航到子页面：根据路由配置切换
          this.isAtHome = false
          const route = this.getRoute(toPage)
          if (route) {
            this.showFloatingPlayer = route.showFloatingPlayer
          }
        } else {
          // 回到 NavBar（首页 Tabs）：恢复显示悬浮播放器
          this.isAtHome = true
          this.showFloatingPlayer = true
        }
      },
      didShow: (from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
        operation: NavigationOperation) => {
        const fromPage = (from as NavDestinationContext)?.pathInfo?.name
        const toPage = (to as NavDestinationContext)?.pathInfo?.name
        MLog.i(TAG, `[NavigationInterception] didShow from=${fromPage}, to=${toPage}, operation=${operation}`)
      },
      modeChange: (mode: NavigationMode) => {
        MLog.i(TAG, `[NavigationInterception] mode change=${mode}`)
      }
    })
  }

  /**
   * push 新页面
   *
   * @param name: 页面名称
   * @param params: 页面参数
   * @param onPop: 当返回这个页面时会触发的回调
   * @param animated: 是否启用转场动画，默认 true
   */
  push(name: string, params?: Object, onPop?: (result?: Object) => void, animated?: boolean): boolean {
    const navPath: NavPathInfo = { name: name, param: params, onPop }
    const route = this.getRoute(name)
    if (!route) {
      MLog.w(TAG, `can not find route name=${name}`)
      return false
    }
    let options: NavigationOptions = {
      launchMode: route.singleTask ? LaunchMode.POP_TO_SINGLETON : LaunchMode.STANDARD,
      animated: animated ?? true,
    }
    this._navPathStack.pushPath(navPath, options)
    return true
  }

  /**
   * 退出页面，默认退出栈顶页面；当指定了参数 name 时，退出到 name 页面
   *
   * @param name 退出到指定页面
   * @param animated 是否启用转场动画，默认 true
   */
  pop(name?: string, animated?: boolean): void {
    if (name) {
      this._navPathStack.popToName(name, animated ?? true)
    } else {
      this._navPathStack.pop(animated ?? true)
    }
  }

  /**
   * 退出页面，默认退出栈顶页面
   * @param result 为带回的参数
   * @param animated 是否启用转场动画，默认 true
   */
  popCallBack(result?: Object, animated?: boolean): void {
    this._navPathStack.pop(result, animated ?? true)
  }

  /**
   * 获取页面路由配置
   *
   * @param name 页面名称
   * @returns 获取路由配置
   */
  getRoute(name: string): Route | undefined {
    return RouteMap.ROUTE_MAP.get(name)
  }

  /**
   * 获取页面构造器用于构造页面
   *
   * @param name 页面名称
   * @returns 页面构造器
   */
  getPageBuilder(name: string): WrappedBuilder<[Object]> | undefined {
    return this.getRoute(name)?.pageBuilder
  }

  /**
   * 判断当前是否在指定页面
   * @param pageName 页面名称
   * @returns 是否在指定页面
   */
  isCurrentRoute(pageName: string): boolean {
    const pathNameList: Array<string> = this._navPathStack.getAllPathName()
    if (pathNameList.length === 0) {
      return false
    }
    return pathNameList[pathNameList.length - 1] === pageName
  }

  /**
   * 获取当前页面栈大小
   */
  getPageSize(): number {
    return this._navPathStack.size()
  }
}
