import { NavController } from '../../nav/NavController';
import { RouteName } from '../../nav/RouteMap';
import { CommonWebPageParams } from '../../nav/RouteParams';

/**
 * 协议链接项组件
 * 点击蓝色下划线文本复制链接到剪贴板
 */
@ComponentV2
export struct UrlItem {
  @Param tag: string = '';
  @Param url: ResourceStr = '';

  build() {
    Row() {
      Text(this.tag)
        .fontSize(14)
        .fontColor(Color.Blue)
        .decoration({ type: TextDecorationType.Underline })
        .padding({ left: 16, top: 8, bottom: 8 })
        .onClick(() => {
          NavController.getInstance().push(RouteName.COMMON_WEB_PAGE,
            new CommonWebPageParams(this.url, this.tag))
        })
    }
    .width('100%')
  }
}
