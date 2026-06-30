/**
 * 通用 WebView 页面
 * 支持加载任意 URL，可用于展示 H5 收银台、协议文档等
 */
import { webview } from '@kit.ArkWeb';
import { NavController } from '../nav/NavController';
import { CommonWebPageParams } from '../nav/RouteParams';
import { ToastUtil } from '../utils/ToastUtil';

@ComponentV2
struct CommonWebPage {
  private controller: webview.WebviewController = new webview.WebviewController();
  @Param args: Object | undefined = undefined;
  @Local pageTitle: string = '加载中';
  @Local currentUrl: ResourceStr = '';
  @Local isLoading: boolean = true;
  @Local progressValue: number = 0;
  @Local showProgress: boolean = true;

  aboutToAppear(): void {
    const params = this.args as CommonWebPageParams;
    if (params) {
      this.currentUrl = params.webUrl;
      this.showProgress = params.showProgress;
      if (params.pageTitle) {
        this.pageTitle = params.pageTitle;
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_back_dark'))
            .width(44).height(44)
            .onClick(() => NavController.getInstance().pop())

          Text(this.pageTitle)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 刷新按钮
          Image($r('app.media.icon_refresh'))
            .width(24)
            .height(24)
            .margin({ right: 16 })
            .onClick(() => {
              if (this.currentUrl) {
                this.controller.loadUrl(this.currentUrl);
                this.isLoading = true;
                this.progressValue = 0;
              }
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16 })
        .borderWidth({ bottom: 0.5 })
        .borderColor('#36000000')

        // 加载进度条
        if (this.showProgress && this.isLoading && this.progressValue > 0 && this.progressValue < 100) {
          Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(2)
            .color(Color.Blue)
            .backgroundColor('#FFEEEEEE')
        }

        // WebView
        if (this.currentUrl) {
          Web({ src: this.currentUrl, controller: this.controller })
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .mixedMode(MixedMode.All)
            .onPageBegin((event) => {
              if (event) {
                this.isLoading = true;
              }
            })
            .onPageEnd((event) => {
              if (event) {
                this.isLoading = false;
                this.progressValue = 100;
              }
            })
            .onProgressChange((event) => {
              if (event) {
                this.progressValue = event.newProgress;
              }
            })
            .onTitleReceive((event) => {
              // 如果外部没传 pageTitle，则用 WebView 页面标题
              if (event && this.pageTitle === '加载中') {
                this.pageTitle = event.title || '加载中';
              }
            })
            .onErrorReceive((event) => {
              if (event) {
                this.isLoading = false;
                ToastUtil.show('页面加载失败');
              }
            })
            .width('100%')
            .layoutWeight(1)
        } else {
          Column() {
            LoadingProgress()
              .width(50).height(50)
              .color(Color.Blue)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .hideTitleBar(true)
  }
}


@Builder
export function CommonWebPageBuilder(params?: Object) {
  CommonWebPage({args: params})
}