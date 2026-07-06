/**
 * 关于页面
 * 对应 Android AboutActivity.kt / AboutScreen Composable
 *
 * 展示 SDK 版本、设备信息、协议链接，支持日志上传
 */
import { Global, OpenApiSdk, DeviceInfoManager, MLog } from '@qqmusic/opisdk-base';
import { LogUploadError } from '@qqmusic/opisdk-log';
import { SPUtils } from '../../utils/SPUtils';
import { InputDialog } from '../../dialog/setting/InputDialog';
import { CopyableItem } from '../../view/setting/CopyableItem';
import { EditorItem } from '../../view/setting/EditorItem';
import { UrlItem } from '../../view/setting/UrlItem';
import { NavController } from '../../nav/NavController';
import { ToastUtil } from '../../utils/ToastUtil';
import { deviceInfo } from '@kit.BasicServicesKit';
import { AppUtil } from '../../utils/AppUtil';

const TAG = 'AboutPage';

@ComponentV2
export struct AboutPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  // 可编辑字段
  @Local channelId: string = SPUtils.getString('DemoChannelId', Global.channelId || '');
  @Local opiDeviceId: string = SPUtils.getString('demoOpiDeviceId', '123456789');
  @Local carType: string = SPUtils.getString('demoHardwareInfo', 'L9');
  @Local brand: string = SPUtils.getString('demoBrand', 'Xiaomi');
  // 优先获取openId，没有的话获取deviceId，兜底使用随机串
  @Local openIdOrDeviceId: string = DeviceInfoManager.getInstance().uniqueId;
  // 对话框控制器
  private channelIdDialog: CustomDialogController | null = null;
  private deviceIdDialog: CustomDialogController | null = null;
  private carTypeDialog: CustomDialogController | null = null;
  private brandDialog: CustomDialogController | null = null;

  aboutToAppear(): void {
    this.channelIdDialog = new CustomDialogController({
      builder: InputDialog({
        title: '编辑ChannelId',
        hint: '输入ChannelId',
        prefKey: 'DemoChannelId',
        onConfirm: (val: string) => {
          this.channelId = val;
          SPUtils.setString('DemoChannelId', val);
          Global.channelId = val;
          ToastUtil.show('更新成功，重启生效');
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.deviceIdDialog = new CustomDialogController({
      builder: InputDialog({
        title: '编辑DeviceId',
        hint: '输入DeviceId',
        prefKey: 'demoOpiDeviceId',
        onConfirm: (val: string) => {
          if (val.length === 0) {
            ToastUtil.show('请输入DeviceId');
            return;
          }
          this.opiDeviceId = val;
          SPUtils.setString('demoOpiDeviceId', val);
          ToastUtil.show('更新成功，重启生效');
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.carTypeDialog = new CustomDialogController({
      builder: InputDialog({
        title: '编辑车型',
        hint: '输入车型(car_type)',
        prefKey: 'demoHardwareInfo',
        onConfirm: (val: string) => {
          this.carType = val;
          SPUtils.setString('demoHardwareInfo', val);
          ToastUtil.show('更新成功，重启生效');
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });

    this.brandDialog = new CustomDialogController({
      builder: InputDialog({
        title: '编辑品牌信息',
        hint: '输入品牌(brand)',
        prefKey: 'demoBrand',
        onConfirm: (val: string) => {
          this.brand = val;
          SPUtils.setString('demoBrand', val);
          ToastUtil.show('更新成功，重启生效');
        }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });
  }

  build() {
    NavDestination() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_back_dark'))
          .width(44)
          .height(44)
          .onClick(() => this.navController.pop())
        Text('关于')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16 })
      .borderWidth({ bottom: 0.5 })
      .borderColor('#36000000')

      Scroll() {
        Column() {
          // 包名
          CopyableItem({ title: '包名', content: AppUtil.abilityContext.abilityInfo.bundleName })

          // SDK版本号
          CopyableItem({ title: 'SDK版本号', content: Global.versionName })

          // APPID
          CopyableItem({ title: 'APPID', content: Global.opiAppId })

          // ChannelId（可编辑）
          EditorItem({
            title: 'ChannelId',
            content: this.channelId,
            onEdit: () => {
              this.channelIdDialog?.open();
            }
          })

          // DeviceId（可编辑）
          EditorItem({
            title: '合作方设备id(DeviceId)',
            content: this.opiDeviceId,
            onEdit: () => {
              this.deviceIdDialog?.open();
            }
          })

          // 车型（可编辑）
          EditorItem({
            title: '车型(car_type)',
            content: this.carType,
            onEdit: () => {
              this.carTypeDialog?.open();
            }
          })

          // 品牌（可编辑）
          EditorItem({
            title: '品牌信息(brand)',
            content: this.brand,
            onEdit: () => {
              this.brandDialog?.open();
            }
          })

          // 特殊模式
          CopyableItem({
            title: '特殊模式',
            content: `低内存模式:${SPUtils.getBool('lowMemoryMode', false)}` + '\n' + `IPC模式:${false}`
          })

          // openId / 设备Id
          CopyableItem({
            title: (OpenApiSdk.loginApi?.hasLogin() ? 'openId' : '设备id') + '(日志上报Id)',
            content: this.openIdOrDeviceId
          })

          // wnsId
          CopyableItem({
            title: 'wnsId',
            content: ''
          })

          // qimei36
          CopyableItem({
            title: 'qimei36',
            content: DeviceInfoManager.getInstance().q36
          })

          // 协议
          CopyableItem({
            title: '协议',
            content: Global.isNewProtocol ? '新协议' : '旧协议'
          })

          // 架构
          CopyableItem({
            title: '架构',
            content: deviceInfo.abiList
          })

          // ========== 协议链接 ==========
          Text('协议')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .padding({ left: 16, top: 16, bottom: 8 })

          UrlItem({
            tag: '隐私保护指引',
            url: 'https://privacy.qq.com/document/preview/240edaf9672d4df0a7060a38fc91fa1d'
          })

          UrlItem({
            tag: '服务许可协议',
            url: 'https://y.qq.com/y/static/protocol/car_service.html'
          })

          UrlItem({
            tag: '个人信息保护规则',
            url: 'https://privacy.qq.com/document/preview/8c8086a85e344bc8bad50fd3e554ee9e'
          })

          UrlItem({
            tag: '屏幕宽度',
            url: $rawfile('window-width.html')
          })

          // 日志上传按钮
          Button('日志上传')
            .margin({ top: 16, bottom: 30 })
            .width('90%')
            .onClick(() => {
              OpenApiSdk.logApi?.uploadLog((code, tips, uuid) => {
                MLog.i(TAG, `OtherScreen: code ${code}, tips ${tips}, uuid ${uuid}`);
                const title = code === LogUploadError.UPLOAD_LOG_SUCCESS ? '日志上传成功' : '日志上传失败';
                const message = `code:${code}, tips:${tips}, uuid:${uuid}`;
                if (uuid && uuid !== this.openIdOrDeviceId) {
                  this.openIdOrDeviceId = uuid;
                }
                this.getUIContext().getPromptAction().showDialog({
                  title: title,
                  message: message,
                }).catch(() => {
                  MLog.e(TAG, 'showDialog failed');
                });
              });
            })

          Blank().height(30)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}

@Builder
export function AboutPageBuilder(params: Object) {
  AboutPage()
}