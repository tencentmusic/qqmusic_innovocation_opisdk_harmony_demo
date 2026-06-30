import { CashierViewModel, CashierLoadState } from '../viewmodel/CashierViewModel'
import { ICashierOffer, ICashierTab } from '@qqmusic/opisdk-entity'
import { NavController } from '../nav/NavController'
import { RouteName } from '../nav/RouteMap'
import { CommonWebPageParams } from '../nav/RouteParams'

/**
 * 收银台弹窗
 * 使用 CustomDialog + CustomDialogController 实现
 */
@CustomDialog
export struct CashierDialog {
  controller: CustomDialogController
  viewModel: CashierViewModel = new CashierViewModel()
  // 是否正在关闭中（防止重复关闭）
  private isClosing: boolean = false

  aboutToAppear() {
    // 打开弹窗时自动加载档位数据
    this.viewModel.fetchCashierGears()
  }

  build() {
    Column() {
      // 顶部标题栏 + 关闭按钮
      this.buildHeader()

      // 错误消息
      if (this.viewModel.errorMsg) {
        Text(this.viewModel.errorMsg)
          .fontSize(14)
          .fontColor(Color.Red)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .width('100%')
      }

      // 主内容区域
      if (this.viewModel.gearsState === CashierLoadState.LOADING) {
        this.buildLoading()
      } else if (this.viewModel.gearsState === CashierLoadState.SUCCESS) {
        this.buildCashierContent()
      } else if (this.viewModel.gearsState === CashierLoadState.FAIL) {
        this.buildLoadFail()
      }
    }
    .width('100%')
    .height('85%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 12, topRight: 12 })
  }

  /**
   * 顶部标题栏
   */
  @Builder
  buildHeader() {
    Row() {
      Text('开通会员')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)

      Image($r('sys.media.ohos_ic_public_close'))
        .fillColor(Color.Black)
        .backgroundColor(Color.Transparent)
        .width(36)
        .height(36)
        .onClick(() => this.safeClose())
    }
    .width('100%')
    .padding({ left: 20, right: 12, top: 16, bottom: 8 })
  }

  /**
   * 加载中视图
   */
  @Builder
  buildLoading() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(Color.Gray)
      Text('加载中...')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 加载失败视图
   */
  @Builder
  buildLoadFail() {
    Column() {
      Text('加载失败')
        .fontSize(16)
        .fontColor(Color.Gray)
        .margin({ bottom: 12 })

      Button('点击重试')
        .fontSize(14)
        .onClick(() => this.viewModel.fetchCashierGears())
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 收银台主内容
   */
  @Builder
  buildCashierContent() {
    Column() {
      // Tab 栏 + 档位横向滚动区域
      if (this.viewModel.tabs.length > 0) {
        this.buildTabBar()
        this.buildOfferScrollArea()
      }

      Divider()
        .strokeWidth(0.5)
        .color('#E0E0E0')
        .margin({ top: 8, bottom: 8 })

      // 协议区域
      this.buildAgreementArea()

      Divider()
        .strokeWidth(0.5)
        .color('#E0E0E0')
        .margin({ top: 8, bottom: 8 })

      // 订单详情区域（二维码 + 订单信息）
      this.buildOrderArea()
    }
    .layoutWeight(1)
    .width('100%')
  }

  /**
   * Tab 栏
   */
  @Builder
  buildTabBar() {
    Row() {
      ForEach(this.viewModel.tabs, (tab: ICashierTab, index: number) => {
        Text(tab.getTabInfo()?.getTitle() ??
          this.viewModel.getCategoryName(tab.getGroups()?.[0]?.getOffers()?.[0]?.getCategoryTag() ?? null))
          .fontSize(15)
          .fontColor(this.viewModel.currentTabIndex === (index as number) ? '#6200EE' : Color.Gray)
          .fontWeight(this.viewModel.currentTabIndex === (index as number) ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => this.viewModel.selectTab(index as number))
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .justifyContent(FlexAlign.Start)
  }

  /**
   * 档位横向滚动选择区域
   */
  @Builder
  buildOfferScrollArea() {
    Scroll() {
      Row({ space: 10 }) {
        Blank().width(4)

        ForEach(this.viewModel.currentOffers, (offer: ICashierOffer) => {
          this.buildOfferItem(offer)
        })

        Blank().width(4)
      }
      .padding({ top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Center)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  /**
   * 单个档位卡片
   */
  @Builder
  buildOfferItem(offer: ICashierOffer) {
    Column() {
      if (offer.getIncentive()?.getMainOperateText()) {
        Text(offer.getIncentive()!.getMainOperateText()!)
          .fontSize(12)
          .fontColor('#FF6B00')
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Text(`${this.viewModel.getCategoryName(offer.getCategoryTag())} ${this.viewModel.getOfferTypeName(offer.getType())}`.trim())
        .fontSize(11)
        .fontColor(Color.Gray)
        .margin({ top: 4 })
        .width('100%')
        .textAlign(TextAlign.Center)

      if (offer.getIncentive()?.getMainText()) {
        Text(offer.getIncentive()!.getMainText()!)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontStyle(FontStyle.Italic)
          .fontColor('#333333')
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      if (offer.getProduct()) {
        Text(this.viewModel.formatPrice(offer.getProduct()!.getPrice()))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)

        if (offer.getProduct()!.getMarketPrice() > 0) {
          Text(this.viewModel.formatPrice(offer.getProduct()!.getMarketPrice()))
            .fontSize(10)
            .fontColor(Color.Gray)
            .decoration({ type: TextDecorationType.LineThrough })
            .margin({ top: 2 })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      }

      if (offer.getPack()?.getName()) {
        Text(offer.getPack()!.getName()!)
          .fontSize(11)
          .fontColor(Color.Gray)
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      if (offer.getProduct()) {
        Text(this.viewModel.formatPayTypeAndPeriod(offer.getProduct()!))
          .fontSize(10)
          .fontColor(Color.Gray)
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      if (offer.getPack()?.getImage()) {
        Image(offer.getPack()!.getImage()!)
          .width(48)
          .height(48)
          .objectFit(ImageFit.Contain)
          .margin({ top: 4 })
      }

      if (offer.getIncentive()?.getViceOperateText()) {
        Text(offer.getIncentive()!.getViceOperateText()!)
          .fontSize(11)
          .fontColor('#FF6B00')
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width(150)
    .height(280)
    .padding(10)
    .border({
      width: this.viewModel.isOfferSelected(offer) ? 2 : 1,
      color: this.viewModel.isOfferSelected(offer) ? '#4CAF50' : '#E0E0E0'
    })
    .borderRadius(8)
    .backgroundColor(this.viewModel.isOfferSelected(offer) ? '#F1F8E9' : Color.White)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.viewModel.fetchCashierOrder(offer, 1)
    })
  }

  /**
   * 协议区域
   */
  @Builder
  buildAgreementArea() {
    Row({ space: 8 }) {
      if (this.viewModel.gears?.getVipAgreementUrl()) {
        Text('会员服务协议')
          .fontSize(12)
          .fontColor('#6200EE')
          .decoration({ type: TextDecorationType.Underline })
          .onClick(() => {
            const url = this.viewModel.gears?.getVipAgreementUrl()
            if (url) {
              this.controller.close()
              NavController.getInstance().push(
                RouteName.COMMON_WEB_PAGE,
                new CommonWebPageParams(url, '会员服务协议')
              )
            }
          })
      }

      if (this.viewModel.gears?.getAutoRenewalAgreementUrl() && this.viewModel.isSelectedOfferAutoRenew()) {
        Text('自动续费协议')
          .fontSize(12)
          .fontColor('#6200EE')
          .decoration({ type: TextDecorationType.Underline })
          .onClick(() => {
            const url = this.viewModel.gears?.getAutoRenewalAgreementUrl()
            if (url) {
              this.controller.close()
              NavController.getInstance().push(
                RouteName.COMMON_WEB_PAGE,
                new CommonWebPageParams(url, '自动续费协议')
              )
            }
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  /**
   * 订单详情区域（二维码 + 订单信息）
   */
  @Builder
  buildOrderArea() {
    Column() {
      if (this.viewModel.createOrderState === CashierLoadState.LOADING) {
        LoadingProgress()
          .width(28)
          .height(28)
          .color(Color.Gray)
        Text('正在生成订单...')
          .fontSize(13)
          .fontColor(Color.Gray)
          .margin({ top: 8 })
      } else if (this.viewModel.createOrderState === CashierLoadState.SUCCESS &&
        this.viewModel.orderInfo) {
        if (this.viewModel.getOrderPayUrl().length > 0) {
          QRCode(this.viewModel.getOrderPayUrl())
            .width(160)
            .height(160)
            .margin({ top: 8, bottom: 8 })
        }

        Column() {
          Text(`订单号：${this.viewModel.orderInfo.getOrderId() ?? ''}`)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4 })

          if (this.viewModel.activityIds && this.viewModel.activityIds.length > 0) {
            Text(`活动Id：${this.viewModel.activityIds.join(', ')}`)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ top: 4 })
          }

          if (this.viewModel.getExpireTimeText().length > 0) {
            Text(`过期时间：${this.viewModel.getExpireTimeText()}`)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ top: 4 })
          }

          Text(`支付状态：${this.viewModel.getPayStatusText()}`)
            .fontSize(12)
            .fontColor(this.viewModel.payStatus === 1 ? '#4CAF50' : '#FF9800')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16 })
      } else if (this.viewModel.createOrderState === CashierLoadState.FAIL) {
        Text(this.viewModel.orderErrorMsg ?? '下单失败')
          .fontSize(13)
          .fontColor(Color.Red)
          .margin({ top: 8, bottom: 8 })

        Button('重试下单')
          .fontSize(13)
          .onClick(() => this.viewModel.tryRetryOrder())
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 安全关闭，防止重复触发
   */
  private safeClose() {
    if (!this.isClosing) {
      this.isClosing = true
      this.controller.close()
    }
  }
}
