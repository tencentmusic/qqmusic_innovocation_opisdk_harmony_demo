import { DescShowType, LyricTextParam, LyricView } from "@qqmusic/opisdk-lyricview";

@ComponentV2
export struct LyricTestPage {
  @Local showTranslation: number = 0;
  @Local switchLyricBtnText: string = '仅歌词'
  @Local lyricType: LyricType[] = [
    new LyricType('#000000','#000000', '#FF0000', 10, TextAlign.Start, ScrollAlign.CENTER),
    new LyricType('#A8DCE2','#D37C90','#DD9ABD', 10, TextAlign.Center, ScrollAlign.CENTER),
    new LyricType('#A8DCE2','#D37C90','#DD9ABD', 0, TextAlign.Center, ScrollAlign.CENTER),
    new LyricType('#151330','#A8DCE2','#C3AEB5', 0, TextAlign.Start, ScrollAlign.CENTER),
    new LyricType('#000000','#FFFF00','#F3D112', 10, TextAlign.End, ScrollAlign.CENTER)
  ];
  @Local lineTextParam: LyricTextParam = new LyricTextParam(16, 20, false, this.lyricType[0].lineColor);
  @Local highlightTextParam: LyricTextParam = new LyricTextParam(20, 28, true, this.lyricType[0].highlightColor, this.lyricType[0].maskColor);
  @Local lineSpace: number = this.lyricType[0].lineSpace;
  @Local lyricTextAlign: TextAlign = this.lyricType[0].lyricTextAlign;
  @Local scrollAlign: ScrollAlign = this.lyricType[0].scrollAlign;

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Row({space: 5}) {
            ForEach(this.lyricType, (item: LyricType, index: number) => {
              Button('样式' + (index + 1))
                .onClick(()=>{
                  this.lineTextParam.fontColor = item.lineColor;
                  this.highlightTextParam.fontColor = item.highlightColor;
                  this.highlightTextParam.maskColor = item.maskColor;
                  this.lineSpace = item.lineSpace;
                  this.lyricTextAlign = item.lyricTextAlign;
                  this.scrollAlign = item.scrollAlign;
                })
            })
          }
        }.scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        // 歌词
        if (this.showTranslation === 0) {
          LyricView({
            lineTextParam: this.lineTextParam,
            highlightTextParam: this.highlightTextParam,
            lineSpace: this.lineSpace,
            lyricTextAlign: this.lyricTextAlign,
            lyricShowType: DescShowType.NONE,
            scrollAlign: this.scrollAlign,
            emptyView: this.lyricEmptyView
          })
            .width('100%')
            .layoutWeight(1)
            .margin({
              top: 40,
              bottom: 40
            })

        } else if (this.showTranslation === 1) {
          LyricView({
            lineTextParam: this.lineTextParam,
            highlightTextParam: this.highlightTextParam,
            lineSpace: this.lineSpace,
            lyricTextAlign: this.lyricTextAlign,
            lyricShowType: DescShowType.TRANSLATE,
            scrollAlign: this.scrollAlign,
            emptyView: this.lyricEmptyView
          })
            .width('100%')
            .layoutWeight(1)
            .margin({
              top: 40,
              bottom: 40
            })

        } else if (this.showTranslation === 2) {
          LyricView({
            lineTextParam: this.lineTextParam,
            highlightTextParam: this.highlightTextParam,
            lineSpace: this.lineSpace,
            lyricTextAlign: this.lyricTextAlign,
            lyricShowType: DescShowType.ROMA,
            scrollAlign: this.scrollAlign,
            emptyView: this.lyricEmptyView
          })
            .width('100%')
            .layoutWeight(1)
            .margin({
              top: 40,
              bottom: 40
            })

        }

        Button(this.switchLyricBtnText)
          .fontSize(16)
          .onClick(() => {
            this.showTranslation = (this.showTranslation + 1) % 3;
            if (this.showTranslation === 0) {
              this.switchLyricBtnText = '仅歌词';
            } else if (this.showTranslation === 1) {
              this.switchLyricBtnText = '翻译歌词';
            } else if (this.showTranslation === 2) {
              this.switchLyricBtnText = '音译歌词';
            }
          })

      }
      .padding({left: 20, right: 20})
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  lyricEmptyView() {
    Column() {
      Text('暂无歌词')
        .fontSize(16)
        .fontColor('#888888')
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

@Builder
export function LyricTestPageBuilder() {
  LyricTestPage()
}

@ObservedV2
class LyricType {
  @Trace lineColor: ResourceColor = '#7F000000'
  @Trace highlightColor: ResourceColor = '#FF000000'
  @Trace maskColor : ResourceColor = '#FFFF0000'
  @Trace lineSpace: number = 0;
  @Trace lyricTextAlign: TextAlign = TextAlign.Center;
  @Trace scrollAlign: ScrollAlign = ScrollAlign.CENTER;

  constructor(lineColor: ResourceColor = '#7F000000',
    highlightColor: ResourceColor = '#99FFFFFF',
    maskColor: ResourceColor = '#99FFFFFF',
    lineSpace: number = 0,
    lyricTextAlign: TextAlign = TextAlign.Center,
    scrollAlign: ScrollAlign = ScrollAlign.CENTER) {
    this.lineColor = lineColor;
    this.highlightColor = highlightColor;
    this.maskColor = maskColor;
    this.lineSpace = lineSpace;
    this.lyricTextAlign = lyricTextAlign;
    this.scrollAlign = scrollAlign;
  }
}