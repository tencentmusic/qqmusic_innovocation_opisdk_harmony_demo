import { NavController } from '../../../nav/NavController'
import { MvRecommendView } from './MvRecommendView'

/**
 * MV 推荐列表页面
 */
@ComponentV2
export struct MvRecommendPage {
  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.icon_back_placeholder'))
            .width(24)
            .height(24)
            .margin({ left: 16, top: 12, bottom: 12 })
            .onClick(() => {
              NavController.getInstance().pop()
            })

          Text('MV推荐')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ top: 12, bottom: 12 })

          // 右侧占位保持居中
          Blank()
            .width(40)
        }
        .width('100%')
        .backgroundColor(Color.White)

        // MV 推荐列表内容
        MvRecommendView()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }
}

@Builder
export function MvRecommendPageBuilder(params: Object) {
  MvRecommendPage()
}
