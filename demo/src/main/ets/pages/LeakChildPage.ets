

const leakHolder: Object[] = [];

class LeakRefBox {
  leakTag: number;

  constructor(tag: number) {
    this.leakTag = tag;
  }
}


@Entry
@Component
struct LeakChildPage {

  aboutToAppear(): void {
    leakHolder.push(this);
  }

  build() {
    Text('泄漏子组件（每次进入都会向全局数组强引用自身）')
      .fontSize(14)
      .margin({ left: 12, top: 4 })
  }

}