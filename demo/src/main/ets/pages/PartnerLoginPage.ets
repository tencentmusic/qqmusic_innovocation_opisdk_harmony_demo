import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base';
import { MMKVHelper } from '@qqmusic/opisdk-qmutils';
import { IPartnerLoginApi } from '@qqmusic/opisdk-entity';

@ComponentV2
export struct PartnerLoginPage {
  private impl?: IPartnerLoginApi
  @Local appId: string = '';
  @Local accountId: string = '';
  @Local token: string = '';
  @Local result: string = '';
  @Local isForceBind: boolean = true;

  async aboutToAppear() {
    // 初始化 Preferences
    try {
      this.appId = MMKVHelper.getObject(MMKVHelper.getCommonMMKV(), 'appId', '')!
      this.accountId = MMKVHelper.getObject(MMKVHelper.getCommonMMKV(), 'accountId', '')!
      this.token = MMKVHelper.getObject(MMKVHelper.getCommonMMKV(), 'token', '')!
    } catch (err) {
      MLog.e('PartnerLoginPage', `getPreferences failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  // 保存账号信息
  async saveAccountInfo() {
    try {
      MMKVHelper.setObject(MMKVHelper.getCommonMMKV(), 'appId', this.appId)
      MMKVHelper.setObject(MMKVHelper.getCommonMMKV(), 'accountId', this.accountId)
      MMKVHelper.setObject(MMKVHelper.getCommonMMKV(), 'token', this.token)
      this.result = "写入成功";
    } catch (err) {
      this.result = "写入失败";
    }
  }

  build() {
    NavDestination() {
    Scroll() {
      Column() {
        Row() {
          Column({ space: 10 }) {
            this.InputGroup("AppId", this.appId, (val) => this.appId = val)
            this.InputGroup("AccountId", this.accountId, (val) => this.accountId = val)
            this.InputGroup("token", this.token, (val) => this.token = val)
          }
          .layoutWeight(1)
          .padding({ right: 10 })

          Button("写入帐号信息")
            .onClick(() => {
              this.saveAccountInfo();
            })
            .height('100%')
            .width(100)
        }
        .height(200)
        .width('100%')
        .padding(10)

        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Text(this.result)
            .textAlign(TextAlign.Center)
        }
        .height(60)
        .width('100%')

        Row() {
          Checkbox({ name: 'forceBind', group: 'bind' })
            .select(this.isForceBind)
            .onChange((value: boolean) => {
              this.isForceBind = value;
            })
          Text("强制绑定").padding({ left: 5, right: 10 })

          Button("绑定音乐帐号")
            .layoutWeight(1)
            .onClick(() => {
              this.result = " 执行中  ";
              OpenApiSdk.loginApi?.updateThirdPartyAccount(
                this.appId, this.token, this.accountId, this.isForceBind
              ).then((response) => {
                this.result = `ret: ${response?.ret} msg : ${response?.errorMsg} bindAccountID: ${response?.data}`;
              })
            })
        }
        .width('100%')
        .height(60)
        .padding({ left: 30, right: 30 })
        .margin({ top: 30 })

        // --- 解除绑定 ---
        Button("解除绑定")
          .width('100%')
          .height(60)
          .margin({ top: 30, left: 30, right: 30 })
          .onClick(() => {
            this.result = " 执行中  ";
            OpenApiSdk.loginApi?.deleteThirdPartyAccountBindState(
              this.appId, this.token, this.accountId
            ).then((response) => {
              this.result = `ret: ${response?.ret} msg : ${response?.errorMsg}`;
            })
          })

        // --- 查询绑定状态  ---
        Button("查询绑定状态")
          .width('100%')
          .height(60)
          .margin({ top: 30, left: 30, right: 30 })
          .onClick(() => {
            this.result = " 执行中  ";
            OpenApiSdk.loginApi?.queryThirdPartyAccountBindState(
              this.appId, this.token, this.accountId
            ).then((response) => {
              this.result = `ret: ${response?.ret} msg : ${response?.errorMsg}  bindAccountID: ${response?.data}`;
            })
          })

        // --- 查询当前第三方帐号ID  ---
        Button("查询当前第三方帐号ID")
          .width('100%')
          .height(60)
          .margin({ top: 30, left: 30, right: 30 })
          .onClick(() => {
            this.result = " 执行中  ";
            const id = OpenApiSdk.loginApi?.queryThirdPartyAccountID();
            this.result = `当前登录帐号的ID 是  ${id}`;
          })

        // --- 登录第三方帐号  ---
        Button("登录第三方帐号")
          .width('100%')
          .height(60)
          .margin({
            top: 30,
            left: 30,
            right: 30,
            bottom: 50
          })
          .onClick(() => {
            this.result = " 执行中  ";
            OpenApiSdk.loginApi?.enableRestoreLogin(true);
            OpenApiSdk.loginApi?.thirdPartyAccountLogin(
              this.appId, this.token, this.accountId
            ).then((response) => {
              this.result = `ret: ${response?.ret} msg : ${response?.errorMsg}`;
            })
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    }
    .hideTitleBar(true)
  }

  @Builder
  InputGroup(label: string, value: string, onChange: (val: string) => void) {
    Column() {
      TextInput({ placeholder: label, text: value })
        .onChange((val) => {
          onChange(val);
        })
        .width('100%')
    }
  }
}

@Builder
export function PartnerLoginPageBuilder(params: Object) {
  PartnerLoginPage()
}