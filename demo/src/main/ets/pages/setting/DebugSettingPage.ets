import { Global, MLog, OpenApiSdk, UrlConfig } from '@qqmusic/opisdk-base';
import { SingleItem } from '../../view/setting/SingleItem';
import { DebugViewModel, DevOpsEntity } from '../../viewmodel/setting/DebugViewModel';
import { SPUtils } from '../../utils/SPUtils';
import { DomainSelectDialog } from '../../dialog/setting/DomainSelectDialog';
import { DevopsSelectDialog } from '../../dialog/setting/DevopsSelectDialog';
import { InputDialog } from '../../dialog/setting/InputDialog';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { ToastUtil } from '../../utils/ToastUtil';
import { AuthType, OpenIdInfo } from '@qqmusic/opisdk-entity';
import { LoginTypeSelectDialog } from '../../dialog/setting/LoginTypeSelectDialog';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { AppCheckModeSelectDialog } from '../../dialog/setting/AppCheckModeSelectDialog';
import { BaseFuncProxy } from '../../utils/BaseFuncProxy';

// 域名映射
const DOMAIN_MAP: Map<string, string> = new Map([
  [UrlConfig.CLOUD_URL_MAIN, '正式域名'],
  [UrlConfig.CLOUD_URL_SZ, '深圳域名'],
  [UrlConfig.CLOUD_URL_SH, '上海域名']
]);

const DOMAIN_REVERSE_MAP: Record<string, string> = {
  '深圳域名': UrlConfig.CLOUD_URL_SZ,
  '上海域名': UrlConfig.CLOUD_URL_SH,
};

const ENV_TEST = '测试环境';
const ENV_RELEASE = '正式环境';
const ENV_PRE_RELEASE = '预发布环境';
const OPEN = '打开';
const CLOSE = '关闭';

// 帐号检查模式
const APP_CHECK_MODE_LIST: string[] = ['严格模式', '无检查模式', '自定义模式'];

// 小票过期错误码
const ERROR_CODE_TOKEN_EXPIRE = 11108;
const TAG = 'DebugSettingPage';

/**
 * Debug 调试页面
 * 对应 Android DebugActivity.kt / DebugScreen Composable
 *
 * 提供环境切换、域名切换、DevOps选择、日志开关等调试功能
 */
@ComponentV2
export struct DebugSettingPage {
  // 环境相关
  @Local curEnv: string = this.initCurEnv();
  // TODO(chezijian): 鸿蒙侧 Global.isWnsTestEnv 不存在 , 暂时直接写死 ENV_TEST;
  @Local curWnsEnv: string = ENV_TEST;
  // @Local curWnsEnv: string = Global.isWnsTestEnv ? ENV_TEST : ENV_RELEASE;
  @Local curDomain: string = DOMAIN_MAP[Global.curDomain] ?? '正式域名';
  @Local curDevopsName: string = SPUtils.getString('devopsName', 'DevopsBase');
  // 开关状态
  @Local isEnableLog: boolean = SPUtils.getBool('enableLog', true);
  @Local enableHttpDns: boolean = SPUtils.getBool('enableHttpDns', true);
  @Local tdeEnv: boolean = SPUtils.getBool('enableTdeEnv', false);
  @Local useIpc: boolean = false;
  @Local tryPauseFirst: boolean = SPUtils.getBool('tryPauseFirst', false);
  @Local curAppCheckMode: string = APP_CHECK_MODE_LIST[BaseFuncProxy.getAppCheckMode()];
  // 对话框控制器
  private domainDialog: CustomDialogController | null = null;
  private devopsDialog: CustomDialogController | null = null;
  private logDirDialog: CustomDialogController | null = null;
  private sessionActivityDialog: CustomDialogController | null = null;
  private loginTypeDialog: CustomDialogController | null = null;
  private appCheckModeDialog: CustomDialogController | null = null;
  // ViewModel
  private viewModel: DebugViewModel = new DebugViewModel();

  private initCurEnv(): string {
    if (Global.isTestEnv) {
      return ENV_TEST;
    }
    if (Global.isPreReleaseEnv) {
      return ENV_PRE_RELEASE;
    }
    return ENV_RELEASE;
  }

  aboutToAppear(): void {
    this.viewModel.loadCurDevops(this.curDevopsName);

    this.domainDialog = new CustomDialogController({
      builder: DomainSelectDialog({
        onSelect: (domain: string) => this.onDomainSelected(domain)
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.devopsDialog = new CustomDialogController({
      builder: DevopsSelectDialog({
        viewModel: this.viewModel,
        onSelect: (entity: DevOpsEntity) => this.onDevopsSelected(entity)
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.logDirDialog = new CustomDialogController({
      builder: InputDialog({
        title: '设置Log存储路径',
        hint: '输入路径',
        prefKey: 'logFileDir',
        onConfirm: (_val: string) => ToastUtil.show('请重启应用')
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.sessionActivityDialog = new CustomDialogController({
      builder: InputDialog({
        title: '设置SessionActivity',
        hint: '输入SessionActivity',
        prefKey: 'sessionActivity',
        onConfirm: (val: string) => {
          // TODO(chezijian): 鸿蒙侧 setMediaSessionActivityName 对应 API 暂未实现；
          // OpenApiSdk.playerApi?.setMediaSessionActivityName(val);
          ToastUtil.show('切歌生效');
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.loginTypeDialog = new CustomDialogController({
      builder: LoginTypeSelectDialog({
        onSelect: (authType: AuthType) => this.onLoginTypeSelected(authType)
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.appCheckModeDialog = new CustomDialogController({
      builder: AppCheckModeSelectDialog(),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true,
      onWillDismiss: () => {
        // 对话框关闭后刷新状态
        this.curAppCheckMode = APP_CHECK_MODE_LIST[BaseFuncProxy.getAppCheckMode()];
      }
    });
  }

  // ========== 业务回调 ==========

  private onDomainSelected(option: string): void {
    const domain = DOMAIN_REVERSE_MAP[option] ?? UrlConfig.CLOUD_URL_MAIN;
    SPUtils.setString('curDomain', domain);
    Global.curDomain = domain;
    this.curDomain = option;
    ToastUtil.show(`${option}域名切换成功,立即生效`);
  }

  private onDevopsSelected(entity: DevOpsEntity): void {
    this.curDevopsName = entity.devopsName;
    SPUtils.setString('devopsName', entity.devopsName);
    Global.meshDevops = entity.devopsName;
    ToastUtil.show(`设置${entity.devopsName}成功`);
  }

  /**
   * 测试小票过期：使用选中的登录方式构造一个过期的小票并更新到SDK
   * 对应 Android 中 LoginExpiredDialogN / MyMultiSelectDialogN 选择 AuthType 后的逻辑
   */
  private onLoginTypeSelected(authType: AuthType): void {
    const loginApi = OpenApiSdk.loginApi;
    if (!loginApi) {
      ToastUtil.show('loginApi 未初始化');
      return;
    }
    if (!loginApi.hasLogin()) {
      ToastUtil.show('未登录');
      return;
    }
    const source = loginApi.getOpenIdInfo();
    if (!source) {
      ToastUtil.show('未登录');
      return;
    }
    // 构造过期小票：expireTime 设为过去的时间戳，accessToken 设为无效值
    const expiredInfo = new OpenIdInfo(
      1662361845, // 过去的时间戳，模拟过期
      'auh148e418a6a50c19d5e17c21b535e02ff5fec7cedf73e002c56af56cf28fb2be4', // 无效 accessToken
      source.openId,
      source.refreshToken,
      authType
    );
    expiredInfo.loginToken = source.loginToken;
    expiredInfo.partnerToken = source.partnerToken;
    expiredInfo.loginType = source.loginType;
    expiredInfo.scanApp = source.scanApp;
    expiredInfo.musicId = source.musicId;
    expiredInfo.openAppId = source.openAppId;
    expiredInfo.accType = source.accType;

    loginApi.updateOpenIdInfo(expiredInfo);
    ToastUtil.show(`已设置 ${authType.desc} 过期小票`);

    // 触发一次网络请求验证小票过期效果
    OpenApiSdk.openApi?.folderApi.fetchCollectedFolder()
      .then((res) => {
        MLog.i(TAG, `[onLoginTypeSelected] code: ${res.ret}, msg: ${res.errorMsg}`);
        if (res.ret === ERROR_CODE_TOKEN_EXPIRE) {
          // 分发刷新小票事件
          // globalEventHandler.pushEvent(new LoginEvent(LoginEvent.AccessTokenExpired_Inner));
        }
      })
  }

  private toggleEnv(): void {
    const envList = [ENV_TEST, ENV_PRE_RELEASE, ENV_RELEASE];
    const idx = envList.indexOf(this.curEnv);
    const next = envList[(idx + 1) % envList.length];
    this.curEnv = next;
    Global.isTestEnv = next === ENV_TEST;
    Global.isPreReleaseEnv = next === ENV_PRE_RELEASE;
    SPUtils.setBool('isTestEnv', Global.isTestEnv);
    SPUtils.setBool('isPreReleaseEnv', Global.isPreReleaseEnv);
    ToastUtil.show('切换成功');
  }

  private toggleWnsEnv(): void {
    const envList = [ENV_TEST, ENV_RELEASE];
    const idx = envList.indexOf(this.curWnsEnv);
    const next = envList[(idx + 1) % envList.length];
    this.curWnsEnv = next;
    // TODO(chezijian): 鸿蒙侧 Global.isWnsTestEnv 不存在 , 暂时直接写死 ENV_TEST;
    // Global.isWnsTestEnv = next === ENV_TEST;
    // SPUtils.setBool('isWnsTestEnv', Global.isWnsTestEnv);
    ToastUtil.show('切换成功，重启生效');
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          // ========== 调试开关项 ==========

          // 切换帐号检查模式
          SingleItem({
            title: '切换帐号检查模式',
            item: `${this.curAppCheckMode}-${Global.opiAppId}`, onItemClick: () => {
              this.appCheckModeDialog?.open();
            }
          })

          // 日志打印
          SingleItem({
            title: '是否关闭日志打印功能',
            item: this.isEnableLog ? '开启' : '关闭', onItemClick: () => {
              const next = !this.isEnableLog;
              SPUtils.setBool('enableLog', next);
              this.isEnableLog = next;
              OpenApiSdk.logApi?.setLogEnable(next);
              ToastUtil.show(`已切换为${next ? '开启状态' : '关闭状态'}`);
            }
          })

          // 允许抓包
          SingleItem({
            title: '允许抓包',
            item: this.enableHttpDns ? CLOSE : OPEN, onItemClick: () => {
              const next = !this.enableHttpDns;
              SPUtils.setBool('enableHttpDns', next);
              // TODO(chezijian): 鸿蒙侧 Global.enableHttpDns 不存在 , 暂时注释;
              // Global.enableHttpDns = next;
              this.enableHttpDns = next;
              ToastUtil.show(`已${next ? CLOSE : OPEN}`);
            }
          })

          // 切换环境
          SingleItem({
            title: '切换环境', item: this.curEnv, onItemClick: () => {
              this.toggleEnv();
            }
          })

          // 切换域名
          SingleItem({
            title: '切换域名', item: this.curDomain, onItemClick: () => {
              this.domainDialog?.open();
            }
          })

          // 选择DevOps
          SingleItem({
            title: '选择DevOps', item: this.curDevopsName, onItemClick: () => {
              this.viewModel.loadDevopsList()
                .then(() => {
                  this.devopsDialog?.open();
                })
                .catch(() => {
                  ToastUtil.show('获取DevOps列表失败');
                })
            }
          })
          // 切换TDE测试环境
          SingleItem({
            title: '切换TDE测试环境',
            item: this.tdeEnv ? OPEN : CLOSE, onItemClick: () => {
              const next = !this.tdeEnv;
              SPUtils.setBool('enableTdeEnv', next);
              this.tdeEnv = next;
              ToastUtil.show(`已${next ? OPEN : CLOSE}`);
            }
          })

          // 切换WNS环境
          SingleItem({
            title: '切换WNS环境', item: this.curWnsEnv, onItemClick: () => {
              this.toggleWnsEnv();
            }
          })

          // 是否启用IPC
          // TODO: 鸿蒙侧 IPC 对应 API 待确认
          SingleItem({
            title: '是否启用IPC(仅当前生命周期有效)',
            item: this.useIpc ? OPEN : CLOSE, onItemClick: () => {
              this.useIpc = !this.useIpc;
              ToastUtil.show('切换成功,仅当前生命周期有效');
            }
          })

          // OpenApi接口
          SingleItem({
            title: 'OpenApi接口', item: '', onItemClick: () => {
              const params: Record<string, boolean> = { 'isDebug': true };
              NavController.getInstance().push(RouteName.OPEN_API_DEMO_PAGE, params);
            }
          })

          // Player播放调试页
          SingleItem({
            title: 'Player播放调试页', item: '', onItemClick: () => {
              NavController.getInstance().push(RouteName.MUSIC_TEST_PAGE);
            }
          })

          // 设置Log存储路径
          SingleItem({
            title: '设置Log存储路径', item: '', onItemClick: () => {
              this.logDirDialog?.open();
            }
          })

          // 清空大票
          SingleItem({
            title: '点击清空大票', item: '', onItemClick: () => {
              const source = OpenApiSdk.loginApi?.getOpenIdInfo();
              if (source) {
                const openIdInfo = new OpenIdInfo(
                  source.expireTime,
                  source.accessToken,
                  source.openId,
                  '', // refreshToken 置空
                  source.type
                );
                openIdInfo.loginToken = source.loginToken;
                openIdInfo.partnerToken = source.partnerToken;
                openIdInfo.loginType = source.loginType;
                openIdInfo.scanApp = source.scanApp;
                openIdInfo.musicId = source.musicId;
                openIdInfo.openAppId = source.openAppId;
                openIdInfo.accType = source.accType;
                OpenApiSdk.loginApi?.updateOpenIdInfo(openIdInfo, openIdInfo.type ?? AuthType.UNKNOWN);
              }
              ToastUtil.show(`操作成功，refreshToken=${OpenApiSdk.loginApi?.getOpenIdInfo()?.refreshToken}`);
            }
          })

          // 测试小票过期
          SingleItem({
            title: '测试小票过期', item: '点击选择登录方式', onItemClick: () => {
              this.loginTypeDialog?.open();
            }
          })
          // 播放页操作前进行暂停
          SingleItem({
            title: '播放页操作前进行暂停',
            item: this.tryPauseFirst.toString(), onItemClick: () => {
              const next = !this.tryPauseFirst;
              SPUtils.setBool('tryPauseFirst', next);
              this.tryPauseFirst = next;
              ToastUtil.show('设置成功，重启生效');
            }
          })

          // 设置SessionActivity
          SingleItem({
            title: '设置SessionActivity', item: '', onItemClick: () => {
              // this.sessionActivityDialog?.open();
              ToastUtil.show('暂不支持 【设置SessionActivity】');
            }
          })

          // ========== Crash测试 & 初始化/销毁 ==========
          Row({ space: 8 }) {
            Button('立即Crash!').fontSize(12).height(36)
              .onClick(() => {
                OpenApiSdk.fireEyeApi?.testJavaCrash();
              })
            Button('Native').fontSize(12).height(36)
              .onClick(() => {
                OpenApiSdk.fireEyeApi?.testNativeCrash();
              })
            Button('ANR').fontSize(12).height(36)
              .onClick(() => {
                OpenApiSdk.fireEyeApi?.testANRCrash();
              })
            Button('清理臻品乐航资源').fontSize(12).height(36)
              .onClick(() => {
                ToastUtil.show('暂未实现');
              })
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 8
          })

          Row({ space: 8 }) {
            Button('初始化SDK').fontSize(12).height(36)
              .onClick(() => {
                ToastUtil.show('初始化成功');
              })
            Button('销毁SDK').fontSize(12).height(36)
              .onClick(() => {
                OpenApiSdk.destroy();
                ToastUtil.show('销毁成功');
              })
            Button('销毁播放服务').fontSize(12).height(36)
              .onClick(() => {
                ToastUtil.show('暂未实现');
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })

          Blank().height(30)
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('debug调试页')
    .backgroundColor('#F5F5F5')
  }
}

@Builder
export function DebugSettingPageBuilder(params?: Object) {
  DebugSettingPage()
}
