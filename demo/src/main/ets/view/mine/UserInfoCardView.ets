import { MineViewModel } from '../../viewmodel/MineViewModel'
import { CashierDialog } from '../../dialog/CashierDialog'

/**
 * 用户信息卡片：头像 + 昵称 + VIP 信息 + 开通/续费按钮
 */
@ComponentV2
export struct UserInfoCardView {
  @Consumer('viewModel') viewModel: MineViewModel = new MineViewModel()
  private cashierDialogController: CustomDialogController | null = null

  private get avatarUrl(): string {
    return this.viewModel.userInfo?.getAvatarUrl() ?? ''
  }

  private get nickName(): string {
    return this.viewModel.userInfo?.getNickName() ?? ''
  }

  private get vipLevel(): string {
    const level = this.viewModel.userVipInfo?.getVipLevel()
    if (level !== null && level !== undefined) {
      return level.toString()
    }
    return ''
  }

  private get isVip(): boolean {
    return this.viewModel.userVipInfo?.isVip() ?? false
  }

  private get loginType(): string {
    return this.viewModel.getLoginType(this.viewModel.loginInfo)
  }

  private get hasVipInfo(): boolean {
    return this.viewModel.userVipInfo !== null
  }

  private get hasPartnerAccount(): boolean {
    return this.viewModel.partnerAccountInfo !== null
  }

  build() {
    Column() {
      Row() {
        // 用户头像
        if (this.avatarUrl.length > 0) {
          Image(this.avatarUrl)
            .width(60)
            .height(60)
            .borderRadius(30)
            .margin({ right: 10 })
            .objectFit(ImageFit.Cover)
        }

        // 用户信息列
        Column({ space: 4 }) {
          Text(`用户昵称：${this.nickName}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)

          Text(`会员 Level : ${this.vipLevel}级`)
            .fontSize(14)
            .fontColor(Color.Gray)

          ForEach(this.viewModel.getVipText(this.viewModel.userVipInfo), (item: string) => {
            Text(item)
              .fontSize(14)
              .fontColor(Color.Gray)
          })

          if (this.isVip) {
            Text(`开始时间：${this.viewModel.getVipTimeStartText(this.viewModel.userVipInfo)}`)
              .fontSize(12)
            Text(`结束时间：${this.viewModel.getVipEndTimeText(this.viewModel.userVipInfo)}`)
              .fontSize(12)
          }

          Text(`登录方式：${this.loginType}`)
            .fontSize(12)
            .margin({ top: 4 })

          if (this.hasPartnerAccount) {
            Text(`已登录第三方帐号 id：${this.viewModel.partnerAccountInfo}`)
              .fontSize(12)
          }

          // 开通/续费会员按钮
          if (this.hasVipInfo) {
            Button(this.isVip ? '立即续费' : '开通会员')
              .fontSize(13)
              .fontColor('#6200EE')
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: '#6200EE' })
              .borderRadius(20)
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .margin({ top: 8 })
              .onClick(() => {
                this.openCashier()
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 20,
        bottom: 20
      })
      .backgroundColor(0xF0FFF0)
      .borderRadius(20)
    }
    .width('100%')
    .padding({ top: 20 })
  }

  /**
   * 打开收银台
   */
  private openCashier(): void {
    this.cashierDialogController = new CustomDialogController({
      builder: CashierDialog(),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    })
    this.cashierDialogController.open()
  }
}
