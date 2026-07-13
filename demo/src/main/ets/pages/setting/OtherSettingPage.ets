/**
 * 其他设置页面
 * 对应 Android OtherActivity.kt / OtherScreen Composable
 *
 * 提供各类调试/功能开关配置项
 */
import { Global, OpenApiSdk } from '@qqmusic/opisdk-base';
import { SingleItem } from '../../view/setting/SingleItem';
import { RetrySelectDialog } from '../../dialog/setting/RetrySelectDialog';
import { RetryInputDialog } from '../../dialog/setting/RetryInputDialog';
import { TimeoutConfigDialog } from '../../dialog/setting/TimeoutConfigDialog';
import { QrCodeShortLinkDialog } from '../../dialog/setting/QrCodeShortLinkDialog';
import { SPUtils } from '../../utils/SPUtils';
import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { ToastUtil } from '../../utils/ToastUtil';
import { CommonWebPageParams } from '../../nav/RouteParams';
import { MLog } from '@qqmusic/opisdk-base';

@ComponentV2
export struct OtherSettingPage {
  @Local isUseNewPlayerPage: boolean = SPUtils.getBool('newPlayerPage', false);
  @Local restorePlayList: boolean = SPUtils.getBool('restore_play_list', true);
  @Local launchAutoPlay: boolean = SPUtils.getBool('launch_auto_play', true);
  @Local isAutoNext: boolean = SPUtils.getBool('restore_next_song', true);
  @Local isUseForegroundService: boolean = SPUtils.getBool('isUseForegroundService', true);
  @Local playWhenRequestFocusFailed: boolean = SPUtils.getBool('playWhenRequestFocusFailed', true);
  @Local playHigherQualityCache: boolean = SPUtils.getBool('playHigherQualityCache', true);
  @Local filterAddToNextOneSong: boolean = SPUtils.getBool('filterAddToNextOneSong', false);
  @Local needFadeWhenPlay: boolean = SPUtils.getBool('needFadeWhenPlay', true);
  @Local enableMediaButton: boolean = SPUtils.getBool('enableMediaButton', true);
  @Local enableAccountPartner: boolean = SPUtils.getBool('accountModePartner', false);
  @Local enableMemoryMode: boolean = SPUtils.getBool('lowMemoryMode', false);
  @Local useMediaPlayer: boolean = SPUtils.getBool('useMediaPlayerWhenPlayDolby', false);
  @Local delayGetAudioFocus: boolean = SPUtils.getBool('delayGetAudioFocus', false);
  @Local useCustomNetworkCheck: boolean = SPUtils.getBool('useCustomNetworkCheck', false);
  @Local networkAvailable: boolean = SPUtils.getBool('networkAvailable', true);
  @Local enableWns: boolean = SPUtils.getBool('enableWns', true);
  @Local enablePersonalAssets: boolean = SPUtils.getBool('enablePersonalAssets', true);
  @Local retryNumber: number = SPUtils.getInt('restore_play_list_err_num', 0);
  // 是否支持杜比
  @Local supportDolby: boolean = false;
  // 收银台参数
  @Local cashierErrorCode: string = '208';
  @Local cashierScene: string = 'svip_privilege';
  // 对话框控制器
  private retrySelectDialog: CustomDialogController | null = null;
  private retryInputDialog: CustomDialogController | null = null;
  private timeoutDialog: CustomDialogController | null = null;
  private qrCodeDialog: CustomDialogController | null = null;

  aboutToAppear(): void {
    // 初始化杜比支持状态
    this.supportDolby = OpenApiSdk.playerApi?.supportDolbyDecoder() ?? false;

    this.retrySelectDialog = new CustomDialogController({
      builder: RetrySelectDialog({
        onSelect: (option: string) => this.onRetryOptionSelected(option)
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.timeoutDialog = new CustomDialogController({
      builder: TimeoutConfigDialog(),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });
  }

  /** 获取重试策略描述 */
  private getRetryDesc(): string {
    if (this.retryNumber < 0) {
      return `当前值:${this.retryNumber}->不重试`;
    }
    if (this.retryNumber > 0) {
      return `当前值:${this.retryNumber}->重试${this.retryNumber}次`;
    }
    return '当前值:0->列表重试';
  }

  /** 重试策略选择回调 */
  private onRetryOptionSelected(option: string): void {
    if (option === '重试n次' || option === '自定义') {
      this.retryInputDialog = new CustomDialogController({
        builder: RetryInputDialog({
          onConfirm: (value: number) => {
            this.retryNumber = value;
            SPUtils.setInt('restore_play_list_err_num', value);
            ToastUtil.show(`已设置为：${value},请重启应用`);
          }
        }),
        alignment: DialogAlignment.Center,
        autoCancel: true,
        customStyle: true
      });
      this.retryInputDialog.open();
    } else {
      const num = option === '列表重试' ? 0 : -1;
      this.retryNumber = num;
      SPUtils.setInt('restore_play_list_err_num', num);
      ToastUtil.show(`已设置为：${num},请重启应用`);
    }
  }

  /** 切换布尔开关的通用处理 */
  private toggleBool(key: string, current: boolean, toastMsg?: string): boolean {
    const next = !current;
    SPUtils.setBool(key, next);
    if (toastMsg) {
      ToastUtil.show(toastMsg);
    }
    return next;
  }

  /**
   * 展示二维码短链弹窗
   * 对应 Android MvBuyQRDialog.showQRCodeDialog
   */
  private showQrCodeDialog(payUrl: string, expireSeconds: number | null, expireTs: number | null): void {
    this.qrCodeDialog = new CustomDialogController({
      builder: QrCodeShortLinkDialog({
        payUrl: payUrl,
        expireSeconds: expireSeconds,
        expireTs: expireTs
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });
    this.qrCodeDialog.open();
  }

  build() {
    NavDestination() {
      // 可滚动内容
      Scroll() {
        Column() {
          // ========== 设置项列表 ==========

          // 新版本播放页面
          SingleItem({
            title: '是否启用新版本播放页面',
            item: this.isUseNewPlayerPage ? '新版播放页面' : '旧版播放页面',
            onItemClick: () => {
              this.isUseNewPlayerPage = this.toggleBool('newPlayerPage', this.isUseNewPlayerPage);
            }
          })

          // OpenApi测试界面
          SingleItem({
            title: 'OpenApi测试界面',
            item: '',
            onItemClick: () => {
              NavController.getInstance().push(RouteName.OPEN_API_DEMO_PAGE);
            }
          })

          // 缓存测试界面
          SingleItem({
            title: '缓存测试界面',
            item: '',
            onItemClick: () => {
              NavController.getInstance().push(RouteName.SONG_CACHE_DEMO_PAGE);
            }
          })

          // 播放测试界面
          SingleItem({
            title: '播放测试界面',
            item: '',
            onItemClick: () => {
              NavController.getInstance().push(RouteName.MUSIC_TEST_PAGE);
            }
          })

          // 试用/限免相关
          SingleItem({
            title: '试用/限免相关',
            item: '',
            onItemClick: () => {
              ToastUtil.show('试用/限免相关暂未实现');
            }
          })

          // 是否支持杜比
          SingleItem({
            title: '是否支持杜比',
            item: this.supportDolby ? '支持' : '不支持',
            onItemClick: () => {
              ToastUtil.show(this.supportDolby ? '支持杜比' : '不支持杜比');
            }
          })

          // 播放列表重启自动恢复
          SingleItem({
            title: '播放列表重启自动恢复功能',
            item: this.restorePlayList ? '开启' : '关闭',
            onItemClick: () => {
              this.restorePlayList = this.toggleBool('restore_play_list', this.restorePlayList, '重启app生效');
            }
          })

          if (this.restorePlayList) {
            // 启动后自动播放
            SingleItem({
              title: '启动后自动播放音乐',
              item: this.launchAutoPlay ? '开启' : '关闭',
              onItemClick: () => {
                this.launchAutoPlay = this.toggleBool('launch_auto_play', this.launchAutoPlay, '重启app生效');
              }
            })

            // 播放错误自动重试配置
            SingleItem({
              title: '播放错误自动重试配置',
              item: this.getRetryDesc(),
              onItemClick: () => {
                // todo: 播放那边说暂时没有这个功能，所以先注释
                // this.retrySelectDialog?.open();
                ToastUtil.show('暂不支持【播放错误自动重试配置】');
              }
            })
          }

          // 自动播放下一曲
          SingleItem({
            title: '正常播放情况下是否播放下一曲',
            item: this.isAutoNext ? '开启' : '关闭',
            onItemClick: () => {
              this.isAutoNext = this.toggleBool('restore_next_song', this.isAutoNext, '重启app生效');
            }
          })

          // 前台服务
          SingleItem({
            title: '前台服务功能',
            item: this.isUseForegroundService ? '开启' : '关闭',
            onItemClick: () => {
              // todo: 播放那边说暂时没有这个功能
              // this.isUseForegroundService = this.toggleBool('isUseForegroundService', this.isUseForegroundService, '请重启应用');
              ToastUtil.show('暂不支持【前台服务】');
            }
          })

          // 申请焦点失败继续播放
          SingleItem({
            title: '申请焦点失败继续播放功能',
            item: this.playWhenRequestFocusFailed ? '开启' : '关闭',
            onItemClick: () => {
              this.playWhenRequestFocusFailed = this.toggleBool('playWhenRequestFocusFailed', this.playWhenRequestFocusFailed, '请重启应用');
            }
          })

          // 优先播放高音质完整缓存
          SingleItem({
            title: '优先播放高音质完整缓存',
            item: this.playHigherQualityCache ? '开启' : '关闭',
            onItemClick: () => {
              this.playHigherQualityCache = this.toggleBool('playHigherQualityCache', this.playHigherQualityCache, '请重启应用');
            }
          })

          // addToNext过滤相同歌曲
          SingleItem({
            title: 'addToNext过滤相同歌曲',
            item: this.filterAddToNextOneSong ? '开启' : '关闭',
            onItemClick: () => {
              this.filterAddToNextOneSong = this.toggleBool('filterAddToNextOneSong', this.filterAddToNextOneSong, '请重启应用');
            }
          })

          // 淡入淡出
          SingleItem({
            title: '开启淡入淡出',
            item: this.needFadeWhenPlay ? '开启' : '关闭',
            onItemClick: () => {
              // TODO: 暂不支持 PlayerModuleFunctionConfigParam.needFadeWhenPlayNewSong;
              // this.needFadeWhenPlay = this.toggleBool('needFadeWhenPlay', this.needFadeWhenPlay, '设置成功，重启生效');
              ToastUtil.show('暂不支持【淡入淡出】');
            }
          })
          // 接口超时时间
          SingleItem({
            title: '设置接口超时时间',
            item: '',
            onItemClick: () => {
              this.timeoutDialog?.open();
            }
          })

          // MediaButton事件
          SingleItem({
            title: '是否处理MediaButton事件',
            item: this.enableMediaButton ? '开启' : '关闭',
            onItemClick: () => {
              this.enableMediaButton = this.toggleBool('enableMediaButton', this.enableMediaButton);
              OpenApiSdk.playerApi?.setEnableMediaButton(this.enableMediaButton);
              ToastUtil.show('设置成功，立即生效');
            }
          })

          // 三方账号独立登录
          SingleItem({
            title: '是否使用三方账号独立登录模式(TV暗账号)',
            item: this.enableAccountPartner ? '开启' : '关闭',
            onItemClick: () => {
              // TODO: 暂不支持  InitConfig.accountMode;
              // this.enableAccountPartner = this.toggleBool('accountModePartner', this.enableAccountPartner, '设置成功，重启生效');
              ToastUtil.show('暂不支持【三方账号独立登录】');
            }
          })

          // 低内存模式
          SingleItem({
            title: '是否使用低内存模式(部分音质屏蔽)',
            item: this.enableMemoryMode ? '开启' : '关闭',
            onItemClick: () => {
              this.enableMemoryMode = this.toggleBool('lowMemoryMode', this.enableMemoryMode, '设置成功，重启生效');
            }
          })

          // 系统播放器播放杜比
          SingleItem({
            title: '是否用系统播放器来播放杜比',
            item: this.useMediaPlayer ? 'MediaPlayer' : 'MediaCodec',
            onItemClick: () => {
              this.useMediaPlayer = this.toggleBool('useMediaPlayerWhenPlayDolby', this.useMediaPlayer, '设置成功，重启生效');
            }
          })

          // 延迟获取焦点
          SingleItem({
            title: '是否延迟获取焦点',
            item: this.delayGetAudioFocus ? '开启' : '关闭',
            onItemClick: () => {
              // TODO: 暂不支持  InitConfig.acceptsDelayedFocusGain;
              // this.delayGetAudioFocus = this.toggleBool('delayGetAudioFocus', this.delayGetAudioFocus, '设置成功，立刻生效，效果需查看日志');
              ToastUtil.show('暂不支持【延迟获取焦点】');
            }
          })

          // 自定义网络检测
          SingleItem({
            title: '是否自定义判断网络连接状态',
            item: this.useCustomNetworkCheck ? '打开' : '关闭',
            onItemClick: () => {
              // TODO: 暂不支持  InitConfig.networkChecker;
              // this.useCustomNetworkCheck = this.toggleBool('useCustomNetworkCheck', this.useCustomNetworkCheck, '设置成功，重启生效');
              ToastUtil.show('暂不支持【自定义网络检测】');
            }
          })

          if (this.useCustomNetworkCheck) {
            SingleItem({
              title: '网络是否可用',
              item: this.networkAvailable ? '可用' : '不可用',
              onItemClick: () => {
                // TODO: 暂不支持  InitConfig.networkChecker;
                // this.networkAvailable = this.toggleBool('networkAvailable', this.networkAvailable, '设置成功，立即生效');
                ToastUtil.show('暂不支持【自定义网络检测】');
              }
            })
          }

          // WNS
          SingleItem({
            title: '是否启用WNS',
            item: this.enableWns ? '打开' : '关闭',
            onItemClick: () => {
              // TODO: 暂不支持  InitConfig.needWnsPushService;
              // this.enableWns = this.toggleBool('enableWns', this.enableWns, '设置成功，重启生效');
              ToastUtil.show('暂不支持【WNS】');
            }
          })

          // WNS
          SingleItem({
            title: '是否启用个人资产模块',
            item: this.enablePersonalAssets ? '打开' : '关闭',
            onItemClick: () => {
              this.enablePersonalAssets = this.toggleBool('enablePersonalAssets', this.enablePersonalAssets, '设置成功,重启生效');
            }
          })

          // ========== 收银台测试 ==========
          Column() {
            Text('收银台测试')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .padding({ left: 16, top: 16, bottom: 8 })
              .backgroundColor(Color.White)

            Text('受阻错误码: 0-默认,200-绿豪,208-超会')
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .padding({ left: 16, top: 4, bottom: 4 })
              .backgroundColor(Color.White)

            TextInput({ text: this.cashierErrorCode })
              .type(InputType.Number)
              .fontSize(14)
              .height(40)
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .margin({ left: 16, right: 16, bottom: 8 })
              .onChange((v: string) => {
                this.cashierErrorCode = v.split('').filter(c => c >= '0' && c <= '9').join('');
              })

            Text('获取链接使用场景')
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .padding({ left: 16, top: 8, bottom: 4 })
              .backgroundColor(Color.White)

            TextInput({ text: this.cashierScene })
              .fontSize(14)
              .height(40)
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .margin({ left: 16, right: 16, bottom: 8 })
              .onChange((v: string) => {
                this.cashierScene = v
              })

            Row({ space: 12 }) {
              Button('车载收银台H5').fontSize(12).height(36)
                .onClick(() => {
                  const code = parseInt(this.cashierErrorCode);
                  if (isNaN(code)) {
                    ToastUtil.show('错误码请输入数字');
                    return;
                  }
                  // 调用 getCheckoutUrl，成功后用 CommonWebPage 打开收银台 H5
                  OpenApiSdk.openApi?.vipApi.getCheckoutUrl('demoCheckoutOrderId', code, 0)
                    .then((res) => {
                      if (res.isSuccess() && res.data) {
                        const payUrl = res.data.getUrl();
                        if (payUrl) {
                          NavController.getInstance().push(RouteName.COMMON_WEB_PAGE, new CommonWebPageParams(payUrl, '车载收银台'));
                        } else {
                          ToastUtil.show('获取收银台链接为空');
                        }
                      } else {
                        ToastUtil.show(res.errorMsg ?? '获取收银台链接失败');
                      }
                      MLog.i('OtherPage', `getCheckoutUrl res:${JSON.stringify(res)}`);
                    });
                })

              Button('二维码短链').fontSize(12).height(36)
                .onClick(() => {
                  const code = parseInt(this.cashierErrorCode);
                  if (isNaN(code)) {
                    ToastUtil.show('错误码请输入数字');
                    return;
                  }
                  // 调用 getPayUrlInfo，成功后展示二维码弹窗
                  OpenApiSdk.openApi?.vipApi.getPayUrlInfo('demoOrderId', code, this.cashierScene)
                    .then((resp) => {
                      if (resp.isSuccess() && resp.data) {
                        const payUrl = resp.data.getUrl();
                        const expireSeconds = resp.data.getExpireTime();
                        const expireTs = resp.data.getExpireTs();
                        if (payUrl) {
                          this.showQrCodeDialog(payUrl, expireSeconds, expireTs);
                        } else {
                          ToastUtil.show('获取短链为空');
                        }
                      } else {
                        ToastUtil.show(resp.errorMsg ?? '获取短链失败');
                      }
                    });
                })
            }
            .width('100%').padding({ left: 16, top: 8, bottom: 16 })
            .backgroundColor(Color.White)
          }
          .width('100%').margin({ top: 12 })

          // 冷启动事件数据上报
          Button('冷启动事件数据上报')
            .margin({ top: 12, bottom: 30 }).width('90%')
            .onClick(() => OpenApiSdk.reportApi?.launchReport('1').report())
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('其他设置页')
    .backgroundColor('#F5F5F5')
  }
}

@Builder
export function OtherSettingPageBuilder(params?: Object) {
  OtherSettingPage()
}
