import { TabContentComponent } from '../../component/TabContentComponent'

/**
 * 二级 Tab 数据结构
 */
export class HeaderContent {
  title: string = ''
  items: string[] = []

  constructor(title: string, items: string[]) {
    this.title = title
    this.items = items
  }
}

/**
 * 我的歌单列表：一级 Tab 栏 + 二级 Tab 栏 + 内容
 */
@ComponentV2
export struct MineSongListView {
  @Local currentPrimaryIndex: number = 0
  @Local currentSecondaryIndex: number = 0

  // 数据源
  private readonly tabData: HeaderContent[] = [
    new HeaderContent("自建歌单", ["我喜欢", "自建歌单列表"]),
    new HeaderContent("收藏", ["收藏歌单", "收藏专辑", "收藏的MV", "收藏有声单曲", "收藏有声专辑"]),
    new HeaderContent("最近播放", ["最近播放单曲", "最近播放专辑", "最近播放歌单", "最近播放长音频", "最近播放MV"]),
    new HeaderContent("本地", ["已下载歌曲"]),
    new HeaderContent("已购内容", ["已购数专", "已购单曲","已购长音频"]),
    new HeaderContent("其他", ["订阅歌手", "其他端播放列表", "联合会员订单列表"])
  ]

  build() {
    Column({ space: 0 }) {
      // 一级Tab栏
      this.buildPrimaryTabBar()

      // 二级Tab栏和内容
      this.buildSecondaryContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建一级Tab栏
   */
  @Builder
  buildPrimaryTabBar() {
    Scroll() {
      Row({ space: 0 }) {
        Repeat(this.tabData).each((repeatItem) => {
          Column() {
            Text(repeatItem.item.title)
              .fontSize(16)
              .fontColor(this.currentPrimaryIndex === repeatItem.index ? '#FF5722' : '#666666')
              .fontWeight(this.currentPrimaryIndex === repeatItem.index ? FontWeight.Bold : FontWeight.Normal)
              .padding({ top: 12, bottom: 12, left: 16, right: 16 })

            // 选中指示器
            if (this.currentPrimaryIndex === repeatItem.index) {
              Divider()
                .color('#FF5722')
                .height(3)
                .width(20)
                .margin({ top: -2 })
            }
          }
          .onClick(() => {
            this.currentPrimaryIndex = repeatItem.index
            this.currentSecondaryIndex = 0
          })
        })
      }
      .justifyContent(FlexAlign.Start)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .backgroundColor(Color.White)
    .height(48)
    .width('100%')
    .align(Alignment.Start)
  }

  /**
   * 构建二级Tab栏和内容
   */
  @Builder
  buildSecondaryContent() {
    Column() {
      // 二级Tab栏
      this.buildSecondaryTabBar()

      // 内容
      TabContentComponent({
        currentPrimaryIndex: this.currentPrimaryIndex,
        currentSecondaryIndex: this.currentSecondaryIndex,
        items: this.tabData[this.currentPrimaryIndex].items,
        onChangeIndex: (index: number) => {
          this.currentSecondaryIndex = index
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建二级Tab栏
   */
  @Builder
  buildSecondaryTabBar() {
    Scroll() {
      Row({ space: 0 }) {
        Repeat(this.tabData[this.currentPrimaryIndex].items).each((repeatItem) => {
          Column() {
            Text(repeatItem.item)
              .fontSize(14)
              .fontColor(this.currentSecondaryIndex === repeatItem.index ? '#FF5722' : '#333333')
              .fontWeight(this.currentSecondaryIndex === repeatItem.index ? FontWeight.Medium : FontWeight.Normal)
              .padding({ top: 10, bottom: 10, left: 16, right: 16 })

            // 选中指示器
            if (this.currentSecondaryIndex === repeatItem.index) {
              Divider()
                .color('#FF5722')
                .height(2)
                .width(16)
                .margin({ top: -2 })
            }
          }
          .onClick(() => {
            this.currentSecondaryIndex = repeatItem.index
          })
        })
      }
      .justifyContent(FlexAlign.Start)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .backgroundColor(Color.White)
    .height(44)
    .width('100%')
    .align(Alignment.Start)
  }
}
