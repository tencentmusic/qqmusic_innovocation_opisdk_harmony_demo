
@ComponentV2
export struct EmptyView {
  @Param msg: string = ''

  build() {
    Column() {
      Text(this.msg)
    }.width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
  }
}