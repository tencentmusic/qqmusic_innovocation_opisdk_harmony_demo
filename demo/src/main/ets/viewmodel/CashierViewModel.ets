import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import {
  ICashierGears,
  ICashierTab,
  ICashierOffer,
  ICashierOfferProduct,
  ICashierOrderInfo,
  OpenApiResponse
} from '@qqmusic/opisdk-entity'
import {
  CashierCreateOrderItem,
  CashierCreateOrderParams
} from '@qqmusic/opisdk-openapi'

/**
 * 收银台加载状态枚举
 */
export enum CashierLoadState {
  IDLE = 0,
  LOADING = 1,
  FAIL = 2,
  SUCCESS = 3
}

/**
 * 收银台 ViewModel
 */
@ObservedV2
export class CashierViewModel {
  private readonly TAG = 'CashierViewModel'

  // 档位列表加载状态
  @Trace gearsState: CashierLoadState = CashierLoadState.IDLE
  // 档位数据
  @Trace gears: ICashierGears | null = null
  // 错误消息
  @Trace errorMsg: string | null = null

  // 下单加载状态
  @Trace createOrderState: CashierLoadState = CashierLoadState.IDLE
  // 当前选中的 productId -> 订单信息
  @Trace selectedProductId: string = ''
  @Trace orderInfo: ICashierOrderInfo | null = null
  // 支付状态: -1=加载失败, 0=待支付, 1=已支付, 2=已过期
  @Trace payStatus: number = -1
  // 活动ID列表
  @Trace activityIds: string[] | null = null
  // 下单错误消息
  @Trace orderErrorMsg: string | null = null

  // 档位 tabs（从 gears 提取）
  @Trace tabs: ICashierTab[] = []
  // 当前选中的 tab 索引
  @Trace currentTabIndex: number = 0
  // 当前 tab 下所有 offer 列表（摊平 groups）
  @Trace currentOffers: ICashierOffer[] = []

  /**
   * 获取收银台档位信息
   */
  async fetchCashierGears(): Promise<void> {
    this.gearsState = CashierLoadState.LOADING
    this.errorMsg = null
    this.createOrderState = CashierLoadState.IDLE

    try {
      const resp = await OpenApiSdk.openApi?.vipApi?.fetchCashierGears()
      if (resp && resp.isSuccess() && resp.data) {
        this.gears = resp.data
        this.gearsState = CashierLoadState.SUCCESS

        // 初始化 tabs
        const allTabs = resp.data.getTabs()
        if (allTabs && allTabs.length > 0) {
          this.tabs = allTabs
          this.selectTab(0)
        }
      } else {
        this.gearsState = CashierLoadState.FAIL
        this.errorMsg = resp?.errorMsg ?? '获取收银台档位失败'
        MLog.e(this.TAG, `fetchCashierGears failed: ${this.errorMsg}`)
      }
    } catch (e) {
      this.gearsState = CashierLoadState.FAIL
      this.errorMsg = `获取收银台档位异常: ${e}`
      MLog.e(this.TAG, `fetchCashierGears error: ${e}`)
    }
  }

  /**
   * 选择 tab
   */
  selectTab(index: number): void {
    if (index < 0 || index >= this.tabs.length) {
      return
    }
    this.currentTabIndex = index
    const tab = this.tabs[index]
    const groups = tab.getGroups()
    if (groups && groups.length > 0) {
      const allOffers: ICashierOffer[] = []
      groups.forEach(group => {
        const offers = group.getOffers()
        if (offers) {
          offers.forEach(offer => allOffers.push(offer))
        }
      })
      this.currentOffers = allOffers

      // 自动选中第一个 offer 并下单
      const firstOffer = allOffers[0]
      if (firstOffer) {
        this.fetchCashierOrder(firstOffer, 1)
      }
    } else {
      this.currentOffers = []
    }
  }

  /**
   * 下单获取支付链接
   */
  async fetchCashierOrder(offer: ICashierOffer, amount: number = 1): Promise<void> {
    this.createOrderState = CashierLoadState.LOADING
    this.orderErrorMsg = null
    this.payStatus = -1

    const product = offer.getProduct()
    if (!product) {
      this.createOrderState = CashierLoadState.FAIL
      this.orderErrorMsg = '商品信息为空'
      return
    }

    const offerId = offer.getId()
    const productId = product.getProductId()

    // 提取活动 ID
    const subscriptionActivity = offer.getMarketingActivity()?.getSubscriptionActivity()
    const activityList: string[] = []
    const activityId = subscriptionActivity?.getActivityId()
    if (activityId) {
      activityList.push(activityId)
    }
    this.activityIds = activityList.length > 0 ? activityList : null

    try {
      const item = new CashierCreateOrderItem()
      item.productId = productId
      item.skuId = product.getSkuId()
      item.quantity = amount

      const params = new CashierCreateOrderParams()
      params.cOrder = Date.now().toString()
      params.offerId = offerId
      params.totalAmount = product.getPrice() * amount
      params.items = [item]
      params.activityIds = this.activityIds

      const resp = await OpenApiSdk.openApi?.vipApi?.fetchCashierPayUrl(params)
      if (resp && resp.isSuccess() && resp.data) {
        this.selectedProductId = productId
        this.orderInfo = resp.data
        this.createOrderState = CashierLoadState.SUCCESS

        // 开始轮询支付状态
        const orderId = resp.data.getOrderId()
        if (orderId) {
          this.startPollingOrderStatus(orderId)
        }
      } else {
        this.createOrderState = CashierLoadState.FAIL
        this.orderErrorMsg = resp?.errorMsg ?? '下单失败'
        this.selectedProductId = productId
        this.orderInfo = null
        MLog.e(this.TAG, `fetchCashierOrder failed: ${this.orderErrorMsg}`)
      }
    } catch (e) {
      this.createOrderState = CashierLoadState.FAIL
      this.orderErrorMsg = `下单异常: ${e}`
      this.selectedProductId = productId
      this.orderInfo = null
      MLog.e(this.TAG, `fetchCashierOrder error: ${e}`)
    }
  }

  /**
   * 轮询订单支付状态
   */
  private async startPollingOrderStatus(orderId: string): Promise<void> {
    const poll = async () => {
      try {
        const resp = await OpenApiSdk.openApi?.vipApi?.pollCashierOrderStatus(orderId)
        if (resp && resp.isSuccess() && resp.data !== undefined) {
          this.payStatus = resp.data
          // 如果未支付(-1 需重试)或仍在等待(0)，继续轮询
          if (this.payStatus === 0 || this.payStatus === -1) {
            setTimeout(poll, 1000)
          }
        } else {
          this.payStatus = -1
          // 失败也重试
          setTimeout(poll, 1000)
        }
      } catch (e) {
        this.payStatus = -1
        setTimeout(poll, 1000)
      }
    }
    poll()
  }

  /**
   * 获取档位分类名（中文）
   */
  getCategoryName(categoryTag: string | null): string {
    switch (categoryTag) {
      case 'hhlz':
        return '豪华绿钻'
      case 'cjhy':
        return '超级会员'
      case 'ffb':
        return '付费包'
      case 'lvhy':
        return '情侣会员'
      default:
        return categoryTag ?? ''
    }
  }

  /**
   * 获取周期单位中文
   */
  getPeriodUnitName(unit: number): string {
    switch (unit) {
      case 1:
        return '天'
      case 2:
        return '周'
      case 3:
        return '月'
      case 4:
        return '季'
      case 5:
        return '半年'
      case 6:
        return '年'
      default:
        return ''
    }
  }

  /**
   * 获取支付类型名
   */
  getPayTypeName(payType: number): string {
    switch (payType) {
      case 1:
        return '自动续费'
      case 2:
        return '常规包月'
      default:
        return ''
    }
  }

  /**
   * 获取优惠类型名
   */
  getOfferTypeName(type: number): string {
    switch (type) {
      case 0:
        return '单品'
      case 1:
        return '套餐'
      default:
        return ''
    }
  }

  /**
   * 获取支付状态文本
   */
  getPayStatusText(): string {
    switch (this.payStatus) {
      case -1:
        return '加载失败'
      case 0:
        return '待支付'
      case 1:
        return '已支付'
      case 2:
        return '已过期'
      default:
        return '未知状态'
    }
  }


  /**
   * 判断 offer 是否选中
   */
  isOfferSelected(offer: ICashierOffer): boolean {
    return offer.getProduct()?.getProductId() === this.selectedProductId
  }

  /**
   * 格式化价格：分 → 元字符串
   */
  formatPrice(price: number): string {
    return `￥${(price / 100).toFixed(2)}`
  }

  /**
   * 格式化支付类型 + 周期（如 "自动续费 12月卡"）
   */
  formatPayTypeAndPeriod(product: ICashierOfferProduct): string {
    const payTypeName = this.getPayTypeName(product.getPayType())
    const periodUnitName = this.getPeriodUnitName(product.getPeriodUnit())
    const periodStr = product.getPeriodNumber() > 0 ?
      `${product.getPeriodNumber()}${periodUnitName}卡` : ''
    return `${payTypeName} ${periodStr}`.trim()
  }

  /**
   * 获取当前选中的 offer（用于自动续费协议显示判断）
   */
  getSelectedOffer(): ICashierOffer | null {
    const found = this.currentOffers.find(
      (o: ICashierOffer) => o.getProduct()?.getProductId() === this.selectedProductId
    )
    return found ?? null
  }

  /**
   * 获取选中 offer 是否自动续费
   */
  isSelectedOfferAutoRenew(): boolean {
    const offer = this.getSelectedOffer()
    return offer?.getProduct()?.getPayType() === 1
  }

  /**
   * 获取订单支付链接（用于二维码）
   */
  getOrderPayUrl(): string {
    return this.orderInfo?.getPayUrl() ?? ''
  }

  /**
   * 获取过期时间文本
   */
  getExpireTimeText(): string {
    const expireAt = this.orderInfo?.getExpireAt()
    if (!expireAt) {
      return ''
    }
    const expireTime = new Date(expireAt * 1000)
    return `${expireTime.getFullYear()}-${this.padZero(expireTime.getMonth() + 1)}-${this.padZero(expireTime.getDate())} ${this.padZero(expireTime.getHours())}:${this.padZero(expireTime.getMinutes())}:${this.padZero(expireTime.getSeconds())}`
  }

  /**
   * 重试下单时获取已选 offer
   */
  tryRetryOrder(): void {
    const offer = this.getSelectedOffer()
    if (offer) {
      this.fetchCashierOrder(offer, 1)
    }
  }

  private padZero(num: number): string {
    return num < 10 ? `0${num}` : `${num}`
  }
}
