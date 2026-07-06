/**
 * OpenApiDemoActivity - 对应 Android OpenApiDemoActivity.kt
 *
 * 提供 OpenApi SDK 各接口的测试功能：
 * - 方法名搜索过滤
 * - 下拉选择方法
 * - 动态参数输入（最多5个）
 * - 发送请求并显示结果
 * - 一键测试所有接口
 */
import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { InterfaceParams } from '../../model/InterfaceParams';
import { NavController } from '../../nav/NavController';
import { ToastUtil } from '../../utils/ToastUtil';
import { AppUtil } from '../../utils/AppUtil';
import {
  CashierCreateOrderItem, CashierCreateOrderParams, GetVipGuideConfigParam, MusicSkillSlotItem
} from '@qqmusic/opisdk-openapi';
import { RecentPlayType } from '@qqmusic/opisdk-entity';
import { ISongInfo } from '@qqmusic/opisdk-qmutils'

@Builder
export function OpenApiDemoPageBuilder(args?: Object) {
  OpenApiDemoPage({ args: args })
}

@ComponentV2
export struct OpenApiDemoPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Param args: object | undefined = undefined;
  // ========== 状态变量 ==========
  @Local displayText: string = ''
  @Local loginInfo: boolean = false
  @Local inputKey: string = ''
  @Local showDebugButton: boolean = false
  // 方法选择相关
  @Local apiMethod: string = 'searchSong'
  @Local resultMeans: string[] = []
  @Local apiMeans: string[] = []
  private select: number | number[] = 0
  // 参数相关
  @Local apiMeansList: Map<string, InterfaceParams> = new Map()
  @Local currentValues: InterfaceParams | null = null
  @Local params: string[] = ['', '', '', '', '']
  // 一键测试相关
  private createFolderId: string = ''
  private createFolderSuccess: boolean = false
  private createdFolderDeleted: boolean = false
  private folderSongAdded: boolean = false
  private orderId: string = ''
  private displayMode: boolean = true
  private errorOpiNameAndMsg: string[] = []
  // 方法名到 API 调用的映射
  private methodNameToBlock: Map<string, (param: InterfaceParams) => void> = new Map()

  // ========== 工具方法 ==========

  /**
   * 逗号分隔字符串转数字数组
   */
  private splitByCommaToNumber(input: string): number[] {
    if (!input || input.trim().length === 0) {
      return []
    }
    return input.split(',')
      .map(s => s.trim())
      .filter(s => s.length > 0)
      .map(s => Number(s))
      .filter(n => !Number.isNaN(n))
  }

  /**
   * 逗号分隔字符串转字符串数组
   */
  private splitByComma(input: string): string[] {
    if (!input || input.trim().length === 0) {
      return []
    }
    return input.split(',')
      .map(s => s.trim())
      .filter(s => s.length > 0)
  }

  /**
   * 获取搜索结果
   */
  private getSearchResults(): string[] {
    if (!this.inputKey.trim()) {
      return this.apiMeans
    }
    return this.apiMeans.filter(item =>
    item.toLowerCase().includes(this.inputKey.toLowerCase())
    )
  }

  /**
   * 获取参数值，若为空则返回 null
   */
  private getParam(index: number): string | null {
    const val = this.params[index]
    if (!val || val.trim().length === 0) {
      return null
    }
    return val.trim()
  }

  /**
   * 显示 OpenApi 响应结果
   */
  private displayResponse(result: Object): void {
    try {
      this.displayText = JSON.stringify(result, null, 2)
    } catch (e) {
      this.displayText = String(result)
    }
  }

  // ========== 生命周期 ==========

  async aboutToAppear(): Promise<void> {
    if (this.args) {
      this.showDebugButton = this.args['isDebug'] as boolean
    }

    // 初始化登录状态
    this.loginInfo = OpenApiSdk.loginApi?.hasLogin() ?? false

    // 初始化方法列表
    this.initMethodNameList()
    this.apiMeans = []
    this.apiMeansList.forEach((_value, key) => {
      this.apiMeans.push(key)
    })
    this.apiMeans.sort()
    this.resultMeans = this.apiMeans

    // 初始化方法名到 API 调用的映射
    this.setupMethodNameToBlock()

    // 默认选中第一个
    if (this.apiMeans.length > 0) {
      this.apiMethod = this.apiMeans[0]
      this.currentValues = this.apiMeansList.get(this.apiMethod) ?? null
      this.resetParams()
    }
  }

  /**
   * 重置参数数组
   */
  private resetParams(): void {
    this.params = ['', '', '', '', '']
    if (this.currentValues && this.currentValues.values.length > 0) {
      const vals = this.currentValues.values
      for (let i = 0; i < Math.min(vals.length, 5); i++) {
        this.params[i] = vals[i]
      }
    }
  }

  // ========== 初始化方法列表（对应 Android initMethodNameList） ==========

  private initMethodNameList(): void {
    // 推荐相关
    this.apiMeansList.set('fetchSimilarSong', new InterfaceParams(
      ['歌曲id', '歌曲mid', '已推荐歌曲id列表'],
      ['314818717', '', '']
    ))
    this.apiMeansList.set('fetchHomepageRecommendation', new InterfaceParams(
      ['内容类型：200,500'],
      ['200,500']
    ))
    this.apiMeansList.set('fetchGuessLikeLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchDailyRecommendSong', new InterfaceParams(
      ['请求数量'],
      ['1']
    ))
    this.apiMeansList.set('fetchPersonalRecommendSong', new InterfaceParams(
      ['请求数量'],
      ['1']
    ))

    // 用户/会员信息
    this.apiMeansList.set('fetchGreenMemberInformation', new InterfaceParams([], []))
    this.apiMeansList.set('fetchIotMemberInformation', new InterfaceParams([], []))
    this.apiMeansList.set('fetchPartnerMemberInformation', new InterfaceParams([], []))
    this.apiMeansList.set('fetchUserInfo', new InterfaceParams([], []))

    // 绿钻订单
    this.apiMeansList.set('createGreenOrder', new InterfaceParams(
      ['matchId', '充值账号', '充值时长(月)'],
      ['test01', '', '1']
    ))
    this.apiMeansList.set('queryGreenOrder', new InterfaceParams(
      ['matchId', '订单id'],
      ['test01', '']
    ))

    // 收银台
    this.apiMeansList.set('fetchCashierGears', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCashierPayUrl', new InterfaceParams(
      ['cOrder', 'offerID(套餐ID)', 'totalAmount(订单总金额)', 'productId,skuId', 'activityIds(活动id列表)'],
      ['', '', '', '', '']
    ))
    this.apiMeansList.set('pollCashierOrderStatus', new InterfaceParams(
      ['订单ID'],
      ['']
    ))

    // VIP引导配置
    this.apiMeansList.set('getVipGuideConfig', new InterfaceParams(
      ['点位id，多个用英文逗号分隔'],
      ['']
    ))

    // 搜索
    this.apiMeansList.set('searchAlbum', new InterfaceParams(
      ['关键字', '页码', '每页数量'],
      ['周杰伦', '0', '20']
    ))
    this.apiMeansList.set('searchSong', new InterfaceParams(
      ['关键字', '页码', '每页数量'],
      ['周杰伦', '0', '20']
    ))
    this.apiMeansList.set('searchFolder', new InterfaceParams(
      ['关键字', '页码', '每页数量'],
      ['周杰伦', '0', '20']
    ))
    this.apiMeansList.set('searchRadio', new InterfaceParams(
      ['关键字', '页码', '每页数量'],
      ['周杰伦', '0', '20']
    ))
    this.apiMeansList.set('searchLyric', new InterfaceParams(
      ['关键字', '页码', '每页数量'],
      ['周杰伦', '0', '10']
    ))
    this.apiMeansList.set('searchMV', new InterfaceParams(
      ['关键字', '页码', '每页数量'],
      ['周杰伦', '0', '10']
    ))
    this.apiMeansList.set('searchSinger', new InterfaceParams(
      ['关键字', '页码', '每页数量'],
      ['周杰伦', '0', '10']
    ))
    this.apiMeansList.set('searchSmart', new InterfaceParams(
      ['关键字'],
      ['周杰伦']
    ))

    // 歌单
    this.apiMeansList.set('createFolder', new InterfaceParams(
      ['歌单名称'],
      ['OpenApi测试歌单']
    ))
    this.apiMeansList.set('deleteFolder', new InterfaceParams(
      ['歌单id'],
      ['8202113137']
    ))
    this.apiMeansList.set('deleteFolder(批量,分割)', new InterfaceParams(
      ['歌单id'],
      ['8202113137,3805603854']
    ))
    this.apiMeansList.set('addSongToFolder', new InterfaceParams(
      ['歌单id', '歌曲id列表', '歌曲mid列表', '歌曲类型'],
      ['', '', '', '']
    ))
    this.apiMeansList.set('deleteSongFromFolder', new InterfaceParams(
      ['歌单id', '歌曲id列表', '歌曲mid列表', '歌曲类型'],
      ['', '', '', '']
    ))
    this.apiMeansList.set('fetchSongOfFolder', new InterfaceParams(
      ['歌单id', '页码', '每页数量'],
      ['3805603854', '0', '200']
    ))
    this.apiMeansList.set('fetchSongOfFolder-新翻页方式', new InterfaceParams(
      ['歌单id', 'passback', '每页数量'],
      ['3805603854', '', '20']
    ))
    this.apiMeansList.set('fetchPersonalFolder', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCollectedFolder', new InterfaceParams([], []))
    this.apiMeansList.set('collectFolder', new InterfaceParams(
      ['歌单id'],
      ['3805603854']
    ))
    this.apiMeansList.set('unCollectFolder', new InterfaceParams(
      ['歌单id'],
      ['3805603854']
    ))
    this.apiMeansList.set('unCollectFolder(批量,分割)', new InterfaceParams(
      ['歌单id'],
      ['8202113137,3805603854']
    ))
    this.apiMeansList.set('fetchCategoryOfFolder', new InterfaceParams([], []))
    this.apiMeansList.set('fetchFolderListByCategory', new InterfaceParams(
      ['分类id列表', '页码', '每页数量'],
      ['0,3317', '0', '20']
    ))
    this.apiMeansList.set('fetchFolderDetail', new InterfaceParams(
      ['歌单id'],
      ['3805603854']
    ))
    this.apiMeansList.set('fetchSongInfoBatch', new InterfaceParams(
      ['歌曲id列表', '歌曲mid列表'],
      ['314818717,317968884,316868744,291130348', '']
    ))

    // 排行榜
    this.apiMeansList.set('fetchAllRankGroup', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCategoryOfRank', new InterfaceParams([], []))
    this.apiMeansList.set('fetchRankDetailByCategory', new InterfaceParams(
      ['分类id列表'],
      ['0,62']
    ))
    this.apiMeansList.set('fetchSongOfRank', new InterfaceParams(
      ['榜单id', '页码', '每页数量'],
      ['62', '0', '200']
    ))
    this.apiMeansList.set('fetchJustListenRank', new InterfaceParams([], []))
    this.apiMeansList.set('fetchFreeSongInfoList', new InterfaceParams([], []))

    // 新歌推荐
    this.apiMeansList.set('fetchNewSongRecommend', new InterfaceParams(
      ['标签'],
      ['12']
    ))

    // 歌词
    this.apiMeansList.set('fetchLyric', new InterfaceParams(
      ['歌曲id', '歌曲mid'],
      ['314818717', '']
    ))
    this.apiMeansList.set('fetchAllLyric', new InterfaceParams(
      ['歌曲id', '歌曲mid'],
      ['335918510', '']
    ))
    this.apiMeansList.set('fetchOtherVersionSongs', new InterfaceParams(
      ['歌曲id', '歌曲mid'],
      ['97743', '']
    ))

    // 电台
    this.apiMeansList.set('fetchCategoryOfPublicRadio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchPublicRadioListByCategory', new InterfaceParams(
      ['分类id列表'],
      ['22']
    ))
    this.apiMeansList.set('fetchSongOfPublicRadio', new InterfaceParams(
      ['电台一级分类id', '电台二级分类id', '过滤条件id', '过滤条件类型', '每页数量'],
      ['568', '0', '0', '0', '10']
    ))
    this.apiMeansList.set('fetchJustListenRadio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchSongOfJustListenRadio', new InterfaceParams(
      ['电台id'],
      ['601']
    ))

    // 专辑
    this.apiMeansList.set('fetchAlbumDetail', new InterfaceParams(
      ['专辑id', '专辑mid'],
      ['4805991', '']
    ))
    this.apiMeansList.set('fetchSongOfAlbum', new InterfaceParams(
      ['专辑id', '专辑mid', '页码', '每页数量', '排序(0,1,2)'],
      ['4805991', '', '0', '20', '0']
    ))

    // 歌手
    this.apiMeansList.set('fetchSongOfSinger', new InterfaceParams(
      ['歌手id', '歌手mid', '页码', '每页数量', '排序类型(0按时间;1按热度)'],
      ['19535', '', '0', '200', '0']
    ))
    this.apiMeansList.set('fetchSingerWiki', new InterfaceParams(
      ['歌手id', '歌手mid'],
      ['4558', '']
    ))
    this.apiMeansList.set('fetchHotSingerList', new InterfaceParams(
      ['区域', '性别', '流派'],
      ['-100', '-100', '-100']
    ))
    this.apiMeansList.set('fetchHotSingerListWithFilter', new InterfaceParams(
      ['区域', '性别', '流派', '字母筛选'],
      ['-100', '-100', '-100', 'hot']
    ))
    this.apiMeansList.set('fetchAlbumOfSinger', new InterfaceParams(
      ['歌手id', '歌手mid', '页码', '每页数量', '排序类型(0按时间;1按热度)'],
      ['19535', '', '0', '20', '0']
    ))

    // 长音频
    this.apiMeansList.set('fetchCategoryOfRecommendLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchAlbumListOfRecommendLongAudioByCategory', new InterfaceParams(
      ['分类id列表'],
      ['898115530']
    ))
    this.apiMeansList.set('fetchCategoryOfRankLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchAlbumListOfRankLongAudioByCategory', new InterfaceParams(
      ['分类id列表'],
      ['4013,937']
    ))
    this.apiMeansList.set('fetchCategoryOfLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCategoryFilterOfLongAudio', new InterfaceParams(
      ['分类id列表'],
      ['1001,1502']
    ))
    this.apiMeansList.set('fetchAlbumListOfLongAudioByCategory', new InterfaceParams(
      ['分类id列表', '过滤id列表', '页码', '每页数量', '排序类型'],
      ['1001,1502', '2,0', '0', '20', '0']
    ))
    this.apiMeansList.set('fetchRecentUpdateLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchLikeListLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchRecentPlayLongAudio', new InterfaceParams([], []))

    // 最近播放
    this.apiMeansList.set('fetchRecentPlaySong', new InterfaceParams(
      ['最后更新时间'],
      ['0']
    ))
    this.apiMeansList.set('fetchRecentPlayAlbum', new InterfaceParams(
      ['最后更新时间'],
      ['0']
    ))
    this.apiMeansList.set('fetchRecentPlayFolder', new InterfaceParams(
      ['最后更新时间'],
      ['0']
    ))
    this.apiMeansList.set('deleteRecentPlay', new InterfaceParams(
      ['id列表', '播放类型(2:单曲,3:专辑,4:歌单,5:电台,6:视频,12:长音频,14:播客)'],
      ['8219435055', '2']
    ))
    this.apiMeansList.set('reportRecentPlay', new InterfaceParams(
      ['歌曲id'],
      ['316868744']
    ))

    // 热搜
    this.apiMeansList.set('fetchHotKeyList', new InterfaceParams(
      ['热词类型'],
      ['0']
    ))

    // AI歌单
    this.apiMeansList.set('fetchGetAiSongList', new InterfaceParams([], []))
    this.apiMeansList.set('fetchGetSongListSquare', new InterfaceParams(
      ['起始位置', '歌单数量', '拉取方式(2:最新,5:最热)', '分类id(可选)'],
      ['0', '10', '2', '']
    ))
    this.apiMeansList.set('fetchAllTypeAiSongList', new InterfaceParams(
      ['歌单分页数量', '取第几页'],
      ['12', '0']
    ))

    // 收藏专辑
    this.apiMeansList.set('fetchCollectedAlbum', new InterfaceParams(
      ['起始偏移量', '每页数量', '类型'],
      ['0', '20', '0']
    ))
    this.apiMeansList.set('collectAlbum', new InterfaceParams(
      ['收藏(0:取消,1:收藏)', '专辑id列表'],
      ['1', '8218']
    ))

    // 收藏歌手
    this.apiMeansList.set('collectSinger', new InterfaceParams(
      ['订阅/取消(true/false)', '歌手ID列表'],
      ['true', '4558']
    ))
    this.apiMeansList.set('fetchCollectedSinger', new InterfaceParams(
      ['页码', '分页大小'],
      ['0', '20']
    ))

    // 长音频收藏
    this.apiMeansList.set('fetchCollectedLongAudioSongList', new InterfaceParams(
      ['类型', '页码'],
      ['1', '0']
    ))
    this.apiMeansList.set('collectLongAudioSong', new InterfaceParams(
      ['收藏(true/false)', '歌曲id列表'],
      ['true', '314377847']
    ))

    // 长音频分类页
    this.apiMeansList.set('fetchCategoryPageOfLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCategoryPageDetailOfLongAudio', new InterfaceParams(
      ['品类一级id', '品类二级id', '页码'],
      ['', '', '']
    ))

    // 专区
    this.apiMeansList.set('fetchAreaSectionByShelfTypes', new InterfaceParams(
      ['专区类型'],
      ['675']
    ))
    this.apiMeansList.set('fetchShelfContent', new InterfaceParams(
      ['shelfId', '分页大小', '分页起始ID', '分区ID'],
      ['5317', '8', '879438977', '']
    ))

    // 新专辑
    this.apiMeansList.set('fetchNewAlbum', new InterfaceParams(
      ['地区', '页码', '每页数量', '专辑类型'],
      ['1', '0', '10', '']
    ))

    // 自定义歌单
    this.apiMeansList.set('fetchCustomSongListSquare', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCustomSongListItemDetail', new InterfaceParams(
      ['itemid', 'itemType'],
      ['9095655857', '2']
    ))
    this.apiMeansList.set('fetchCustomSceneSongList', new InterfaceParams(
      ['itemid', 'itemType', 'scene', 'page', 'count'],
      ['27', '1', '快乐', '0', '20']
    ))

    // 免费听
    this.apiMeansList.set('openFreeListenMode', new InterfaceParams([], []))
    this.apiMeansList.set('getFreeListenInfo', new InterfaceParams([], []))

    // 运营信息
    this.apiMeansList.set('getOperationsInfo', new InterfaceParams([], []))

    // AI创作
    this.apiMeansList.set('getHotAICreateSongList', new InterfaceParams(
      ['分页起始id', '分页大小'],
      ['0', '10']
    ))

    // musicSkill
    this.apiMeansList.set('musicSkill', new InterfaceParams(
      ['意图', '槽位值(kv以冒号分隔，多个逗号分隔)', '原始语音', '当前在播歌曲id', '返回数量'],
      ['', '', '', '', '20']
    ))
    this.apiMeansList.set('musicSkillWithSlots', new InterfaceParams(
      ['意图', '槽位值(kv以:分隔，多个逗号分隔)', '原始语音', '当前在播歌曲id', '返回数量'],
      ['', '', '', '', '20']
    ))
  }

  // ========== 方法名到 API 调用的映射（对应 Android setupMethodNameToBlock） ==========

  private setupMethodNameToBlock(): void {
    // 推荐相关
    this.methodNameToBlock.set('fetchSimilarSong', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const songId = this.getParamNum(0)
      const mid = this.getParam(1)
      const hasRecommendList = this.getParamNumList(2)
      OpenApiSdk.openApi?.recommendApi.fetchSimilarSong(songId ?? null, mid, hasRecommendList)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchHomepageRecommendation', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const types = this.getParamNumList(0)
      OpenApiSdk.openApi?.recommendApi.fetchHomepageRecommendationWithSongInfo(types ?? [])
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchGuessLikeLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.recommendApi.fetchGuessLikeLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchDailyRecommendSong', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const num = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.recommendApi.fetchDailyRecommendSong(num)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchPersonalRecommendSong', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const num = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.recommendApi.fetchPersonalRecommendSong(num)
        .then(r => this.displayResponse(r))
    })

    // 用户/会员信息
    this.methodNameToBlock.set('fetchGreenMemberInformation', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.userApi.fetchGreenMemberInformation()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchIotMemberInformation', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.userApi.fetchIotMemberInformation()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchPartnerMemberInformation', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.userApi.fetchPartnerMemberInformation()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchUserInfo', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.userApi.fetchUserInfo()
        .then(r => this.displayResponse(r))
    })

    // 绿钻订单
    this.methodNameToBlock.set('createGreenOrder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const matchId = this.getParam(0) ?? ''
      const openId = this.getParam(1) ?? ''
      const num = this.getParamNum(2) ?? 1
      OpenApiSdk.openApi?.greenOrderApi.createGreenOrder(matchId, openId, num)
        .then(r => {
          if (r.isSuccess()) {
            this.orderId = r.data ?? ''
          }
          this.displayResponse(r)
        })
    })

    this.methodNameToBlock.set('queryGreenOrder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const matchId = this.getParam(0) ?? ''
      const orderId = this.getParam(1) ?? ''
      OpenApiSdk.openApi?.greenOrderApi.queryGreenOrder(matchId, orderId)
        .then(r => this.displayResponse(r))
    })

    // 收银台
    this.methodNameToBlock.set('fetchCashierGears', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.vipApi.fetchCashierGears()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCashierPayUrl', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const cOrder = this.getParam(0) ?? ''
      const offerId = this.getParam(1) ?? ''
      const totalAmount = this.getParamNum(2) ?? 0
      const productInfo = (this.getParam(3) ?? '').split(',')
      const marketingActivities = this.getParam(4)?.split(',')
      const req: CashierCreateOrderParams = new CashierCreateOrderParams()
      req.cOrder = cOrder
      req.offerId = offerId
      req.totalAmount = totalAmount
      const item: CashierCreateOrderItem = new CashierCreateOrderItem()
      item.productId = productInfo[0] ?? ''
      item.skuId = productInfo[1] ?? ''
      item.quantity = 1
      req.items.push(item)
      req.activityIds = marketingActivities ?? null
      OpenApiSdk.openApi?.vipApi.fetchCashierPayUrl(req)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('pollCashierOrderStatus', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const orderId = this.getParam(0) ?? ''
      OpenApiSdk.openApi?.vipApi.pollCashierOrderStatus(orderId)
        .then(r => this.displayResponse(r))
    })

    // VIP引导配置
    this.methodNameToBlock.set('getVipGuideConfig', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const raw = this.getParam(0) ?? ''
      const positions = raw.split(',').map(s => {
        return new GetVipGuideConfigParam(Number(s.trim()) || 0)
      })
      OpenApiSdk.openApi?.vipApi.getVipGuideConfig(positions)
        .then(r => this.displayResponse(r))
    })

    // 搜索
    this.methodNameToBlock.set('searchAlbum', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 20
      OpenApiSdk.openApi?.searchApi.searchAlbum(keyword, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('searchSong', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 20
      OpenApiSdk.openApi?.searchApi.searchSong(keyword, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('searchFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 20
      OpenApiSdk.openApi?.searchApi.searchFolder(keyword, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('searchRadio', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 20
      OpenApiSdk.openApi?.searchApi.searchRadio(keyword, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('searchLyric', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 10
      OpenApiSdk.openApi?.searchApi.searchLyric(keyword, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('searchMV', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 10
      OpenApiSdk.openApi?.searchApi.searchMV(keyword, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('searchSinger', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 10
      OpenApiSdk.openApi?.searchApi.searchSinger(keyword, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('searchSmart', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const keyword = this.getParam(0) ?? ''
      OpenApiSdk.openApi?.searchApi.searchSmart(keyword)
        .then(r => this.displayResponse(r))
    })

    // 歌单
    this.methodNameToBlock.set('createFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderName = this.getParam(0) ?? ''
      OpenApiSdk.openApi?.folderApi.createFolderByName(folderName)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('deleteFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.folderApi.deleteFolder(folderId)
        .then(r => {
          this.createdFolderDeleted = r.data === true
          this.displayResponse(r)
        })
    })

    this.methodNameToBlock.set('deleteFolder(批量,分割)', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderIds = this.getParamNumList(0) ?? []
      OpenApiSdk.openApi?.folderApi.deleteFolder(folderIds)
        .then(r => {
          this.createdFolderDeleted = r.data === true
          this.displayResponse(r)
        })
    })

    this.methodNameToBlock.set('addSongToFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      const songIds = this.getParamNumList(1)
      const songMids = this.getParamStrList(2)
      const songTypes = this.getParamStrList(3)
      OpenApiSdk.openApi?.folderApi.addSongToFolderByIds(folderId, songIds ?? undefined, songMids ?? undefined,
        songTypes ?? undefined)
        .then(r => {
          if (r.isSuccess()) {
            this.folderSongAdded = r.data === true
          }
          this.displayResponse(r)
        })
    })

    this.methodNameToBlock.set('deleteSongFromFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      const songIds = this.getParamNumList(1)
      const songMids = this.getParamStrList(2)
      const songTypes = this.getParamStrList(3)
      OpenApiSdk.openApi?.folderApi.deleteSongFromFolder(folderId, songIds ?? undefined, songMids ?? undefined,
        songTypes ?? undefined)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSongOfFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 200
      // 旧版翻页：传空 passBack + page 参数
      OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(folderId, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSongOfFolder-新翻页方式', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      const passBack = this.getParam(1) ?? ''
      const count = this.getParamNum(2) ?? 20
      OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(folderId, passBack, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchPersonalFolder', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.folderApi.fetchPersonalFolder()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCollectedFolder', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.folderApi.fetchCollectedFolder()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('collectFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.folderApi.collectFolder(folderId)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('unCollectFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.folderApi.unCollectFolder(folderId)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('unCollectFolder(批量,分割)', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderIds = this.getParamNumList(0) ?? []
      OpenApiSdk.openApi?.folderApi.unCollectFolder(folderIds)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCategoryOfFolder', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.folderApi.fetchCategoryOfFolder()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchFolderListByCategory', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryIdList = this.getParamNumList(0) ?? []
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 20
      OpenApiSdk.openApi?.folderApi.fetchFolderListByCategory(categoryIdList, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchFolderDetail', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const folderId = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.folderApi.fetchFolderDetail(folderId)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSongInfoBatch', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const songIds = this.getParamNumList(0)
      const songMids = this.getParamStrList(1)
      OpenApiSdk.openApi?.songApi.fetchSongInfoBatch(songIds ?? undefined, songMids ?? undefined)
        .then(r => this.displayResponse(r))
    })

    // 排行榜
    this.methodNameToBlock.set('fetchAllRankGroup', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.rankApi.fetchAllRankGroup()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCategoryOfRank', (_param: InterfaceParams) => {
      // 鸿蒙 rankApi 没有 fetchCategoryOfRank，用 fetchAllRankGroup 替代
      OpenApiSdk.openApi?.rankApi.fetchAllRankGroup()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchRankDetailByCategory', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryIds = this.getParamNumList(0) ?? []
      // 鸿蒙没有按分类获取榜单详情的接口，取第一个分类id作为 rankId
      const rankId = categoryIds.length > 0 ? categoryIds[0] : 0
      OpenApiSdk.openApi?.rankApi.fetchRankDetail(rankId, 0, 200)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSongOfRank', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const rankId = this.getParamNum(0) ?? 0
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 200
      OpenApiSdk.openApi?.rankApi.fetchSongOfRank(rankId, page, count)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchJustListenRank', (_param: InterfaceParams) => {
      // 鸿蒙没有 fetchJustListenRank，用 fetchAllRankGroup 替代
      OpenApiSdk.openApi?.rankApi.fetchAllRankGroup()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchFreeSongInfoList', (_param: InterfaceParams) => {
      // 鸿蒙没有 fetchFreeSongInfoList，用 fetchAllRankGroup 获取榜单后取第一榜歌曲
      OpenApiSdk.openApi?.rankApi.fetchAllRankGroup()
        .then(r => {
          if (r.isSuccess() && r.data && r.data.length > 0) {
            const firstGroup = r.data[0]
            const rankList = firstGroup.getRankList?.()
            if (rankList && rankList.length > 0) {
              const rankId = rankList[0].getId?.() ?? 0
              OpenApiSdk.openApi?.rankApi.fetchSongOfRank(rankId, 0, 50)
                .then(sr => this.displayResponse(sr))
            } else {
              this.displayResponse(r)
            }
          } else {
            this.displayResponse(r)
          }
        })
    })

    // 新歌推荐
    this.methodNameToBlock.set('fetchNewSongRecommend', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const tag = this.getParamNum(0) ?? 12
      OpenApiSdk.openApi?.songApi.fetchNewSongRecommend(tag)
        .then(r => this.displayResponse(r))
    })

    // 歌词
    this.methodNameToBlock.set('fetchLyric', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const songId = this.getParamNum(0) ?? 0
      const mid = this.getParam(1) ?? ''
      OpenApiSdk.openApi?.lyricApi.fetchAllLyric(songId, mid)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchAllLyric', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const songId = this.getParamNum(0) ?? 0
      const mid = this.getParam(1) ?? ''
      OpenApiSdk.openApi?.lyricApi.fetchAllLyric(songId, mid)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchOtherVersionSongs', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const songId = this.getParamNum(0)
      const mid = this.getParam(1)
      OpenApiSdk.openApi?.songApi.fetchOtherVersionSongs(songId ?? undefined, mid ?? undefined)
        .then(r => this.displayResponse(r))
    })

    // 电台
    this.methodNameToBlock.set('fetchCategoryOfPublicRadio', (_param: InterfaceParams) => {
      // 鸿蒙没有 publicRadio 接口，用 longAudioApi 的品类接口替代
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchPublicRadioListByCategory', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryIdList = this.getParamNumList(0) ?? []
      OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfLongAudioByCategory(categoryIdList, [], 0, 20, 0)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSongOfPublicRadio', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const radioId1 = this.getParamNum(0) ?? 0
      const radioId2 = this.getParamNum(1) ?? 0
      const filterId1 = this.getParamNum(2) ?? 0
      const filterId2 = this.getParamNum(3) ?? 0
      const count = this.getParamNum(4) ?? 10
      OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfLongAudioByCategory([radioId1, radioId2], [filterId1, filterId2], 0, count, 0)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchJustListenRadio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSongOfJustListenRadio', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const radioId = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfLongAudioByCategory([radioId], [], 0, 10, 0)
        .then(r => this.displayResponse(r))
    })

    // 专辑
    this.methodNameToBlock.set('fetchAlbumDetail', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const albumId = this.getParamNum(0)
      const albumMid = this.getParam(1)
      OpenApiSdk.openApi?.albumApi.fetchAlbumDetail(albumId ?? undefined, albumMid ?? undefined)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSongOfAlbum', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const albumId = this.getParamNum(0)
      const albumMid = this.getParam(1)
      const page = this.getParamNum(2) ?? 0
      const count = this.getParamNum(3) ?? 20
      const orderBy = this.getParamNum(4) ?? 0
      OpenApiSdk.openApi?.albumApi.fetchSongOfAlbum(albumId ?? undefined, albumMid ?? undefined, page, count, 0, orderBy)
        .then(r => this.displayResponse(r))
    })

    // 歌手
    this.methodNameToBlock.set('fetchSongOfSinger', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const singerId = this.getParamNum(0) ?? 0
      const singerMid = this.getParam(1) ?? ''
      const page = this.getParamNum(2) ?? 0
      const count = this.getParamNum(3) ?? 200
      const sortType = this.getParamNum(4) ?? 0
      OpenApiSdk.openApi?.singerApi.fetchSongOfSinger(singerId, singerMid, page, count, sortType)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchSingerWiki', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const singerId = this.getParamNum(0)
      const singerMid = this.getParam(1)
      OpenApiSdk.openApi?.singerApi.fetchSingerWiki(singerId ?? null, singerMid ?? null)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchHotSingerList', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const area = this.getParamNum(0) ?? -100
      const sex = this.getParamNum(1) ?? -100
      const genre = this.getParamNum(2) ?? -100
      OpenApiSdk.openApi?.singerApi.fetchHotSingerList(area, sex, genre, 0)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchHotSingerListWithFilter', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const area = this.getParamNum(0) ?? -100
      const sex = this.getParamNum(1) ?? -100
      const genre = this.getParamNum(2) ?? -100
      const index = this.getParam(3) ?? 'hot'
      OpenApiSdk.openApi?.singerApi.fetchHotSingerListWithFilter(area, sex, genre, index, 0)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchAlbumOfSinger', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const singerId = this.getParamNum(0)
      const singerMid = this.getParam(1)
      const page = this.getParamNum(2) ?? 0
      const count = this.getParamNum(3) ?? 20
      const sortType = this.getParamNum(4) ?? 0
      OpenApiSdk.openApi?.albumApi.fetchAlbumOfSinger(singerId ?? null, singerMid ?? null, page, count, sortType)
        .then(r => this.displayResponse(r))
    })

    // 长音频
    this.methodNameToBlock.set('fetchCategoryOfRecommendLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfRecommendLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchAlbumListOfRecommendLongAudioByCategory', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryIdList = this.getParamNumList(0) ?? []
      OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfRecommendLongAudioByCategory(categoryIdList)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCategoryOfRankLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfRankLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchAlbumListOfRankLongAudioByCategory', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryIdList = this.getParamNumList(0) ?? []
      OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfRankLongAudioByCategory(categoryIdList)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCategoryOfLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCategoryFilterOfLongAudio', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryIdList = this.getParamNumList(0) ?? []
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryFilterOfLongAudio(categoryIdList)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchAlbumListOfLongAudioByCategory', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryIdList = this.getParamNumList(0) ?? []
      const filterIdList = this.getParamNumList(1) ?? []
      const page = this.getParamNum(2) ?? 0
      const count = this.getParamNum(3) ?? 20
      const sortType = this.getParamNum(4) ?? 0
      OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfLongAudioByCategory(categoryIdList, filterIdList, page, count,
        sortType)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchRecentUpdateLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.longAudioApi.fetchRecentUpdateLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchLikeListLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.longAudioApi.fetchLikeListLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchRecentPlayLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayLongAudio(0)
        .then(r => this.displayResponse(r))
    })

    // 最近播放
    this.methodNameToBlock.set('fetchRecentPlaySong', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const updateTime = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlaySong(updateTime)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchRecentPlayAlbum', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const updateTime = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayAlbum(updateTime)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchRecentPlayFolder', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const updateTime = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayFolder(updateTime)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('deleteRecentPlay', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const ids = this.getParamStrList(0) ?? []
      const typeNum = this.getParamNum(1) ?? 2
      // 将数字转换为 RecentPlayType 枚举值
      const type = typeNum as RecentPlayType
      OpenApiSdk.openApi?.recentPlayApi.deleteRecentPlay(type, ids)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('reportRecentPlay', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const songId = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.recentPlayApi.reportRecentPlay(songId, RecentPlayType.SONG)
        .then(r => this.displayResponse(r))
    })

    // 热搜
    this.methodNameToBlock.set('fetchHotKeyList', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const type = this.getParamNum(0) ?? 0
      OpenApiSdk.openApi?.searchApi.fetchHotKeyList([type], 1)
        .then(r => this.displayResponse(r))
    })

    // AI歌单
    this.methodNameToBlock.set('fetchGetAiSongList', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.folderApi.fetchGetAiSongList()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchGetSongListSquare', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const start = this.getParamNum(0) ?? 0
      const size = this.getParamNum(1) ?? 10
      const order = this.getParam(2) ?? '2'
      const categoryId = this.getParamNum(3)
      OpenApiSdk.openApi?.folderApi.fetchGetSongListSquare(start, size, order, categoryId ?? null)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchAllTypeAiSongList', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const size = this.getParamNum(0) ?? 12
      const page = this.getParamNum(1) ?? 0
      OpenApiSdk.openApi?.folderApi.fetchAllTypeAiSongList(size, page)
        .then(r => this.displayResponse(r))
    })

    // 收藏专辑
    this.methodNameToBlock.set('fetchCollectedAlbum', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const start = this.getParamNum(0) ?? 0
      const size = this.getParamNum(1) ?? 20
      const type = this.getParamNum(2) ?? 0
      OpenApiSdk.openApi?.albumApi.fetchCollectedAlbum(start, size, type)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('collectAlbum', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const isCollect = (this.getParamNum(0) ?? 1) > 0
      const albumIds = this.getParamNumList(1) ?? []
      OpenApiSdk.openApi?.albumApi.collectAlbum(isCollect, albumIds)
        .then(r => this.displayResponse(r))
    })

    // 收藏歌手
    this.methodNameToBlock.set('collectSinger', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const isCollect = this.getParam(0) === 'true'
      const singerIdList = this.getParamNumList(1) ?? []
      OpenApiSdk.openApi?.singerApi.collectSinger(isCollect, singerIdList)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCollectedSinger', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const page = this.getParamNum(0) ?? 0
      const count = this.getParamNum(1) ?? 20
      OpenApiSdk.openApi?.singerApi.fetchCollectedSinger(page, count)
        .then(r => this.displayResponse(r))
    })

    // 长音频收藏
    this.methodNameToBlock.set('fetchCollectedLongAudioSongList', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const type = this.getParamNum(0) ?? 1
      const page = this.getParamNum(1) ?? 0
      OpenApiSdk.openApi?.longAudioApi.fetchCollectedLongAudioSongList(type, page)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('collectLongAudioSong', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const isCollect = this.getParam(0) === 'true'
      const songIdList = this.getParamNumList(1) ?? []
      OpenApiSdk.openApi?.longAudioApi.collectLongAudioSong(isCollect, songIdList, 1)
        .then(r => this.displayResponse(r))
    })

    // 长音频分类页
    this.methodNameToBlock.set('fetchCategoryPageOfLongAudio', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageOfLongAudio()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCategoryPageDetailOfLongAudio', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const categoryId = this.getParamNum(0) ?? 0
      const subCategoryId = this.getParamNum(1) ?? 0
      const page = this.getParamNum(2) ?? 0
      OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageDetailOfLongAudio(categoryId, subCategoryId, page)
        .then(r => this.displayResponse(r))
    })

    // 专区
    this.methodNameToBlock.set('fetchAreaSectionByShelfTypes', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const areaId = this.getParamNum(0) ?? 675
      OpenApiSdk.openApi?.operAreaApi.fetchAreaSectionByShelfTypes(areaId, [1004])
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchShelfContent', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const shelfId = this.getParamNum(0) ?? 5317
      const contentSize = this.getParamNum(1) ?? 8
      const lastContentId = this.getParam(2) ?? '879438977'
      const areaId = this.getParamNum(3) ?? 740
      OpenApiSdk.openApi?.operAreaApi.fetchShelfContent(shelfId, contentSize, lastContentId, areaId)
        .then(r => this.displayResponse(r))
    })

    // 新专辑
    this.methodNameToBlock.set('fetchNewAlbum', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const area = this.getParamNum(0) ?? 1
      const page = this.getParamNum(1) ?? 0
      const count = this.getParamNum(2) ?? 10
      const type = this.getParamNum(3)
      OpenApiSdk.openApi?.albumApi.fetchNewAlbum(area, page, count, type ?? null)
        .then(r => this.displayResponse(r))
    })

    // 自定义歌单
    this.methodNameToBlock.set('fetchCustomSongListSquare', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.folderApi.fetchCustomSongListSquare()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCustomSongListItemDetail', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const itemId = this.getParam(0) ?? ''
      const itemType = this.getParamNum(1) ?? 0
      OpenApiSdk.openApi?.folderApi.fetchCustomSceneSongList(itemId, itemType, '', 0, 20)
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('fetchCustomSceneSongList', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      const itemId = this.getParam(0) ?? ''
      const itemType = this.getParamNum(1) ?? 0
      const scene = this.getParam(2) ?? ''
      const page = this.getParamNum(3) ?? 0
      const count = this.getParamNum(4) ?? 20
      OpenApiSdk.openApi?.folderApi.fetchCustomSceneSongList(itemId, itemType, scene, page, count)
        .then(r => this.displayResponse(r))
    })

    // 免费听
    this.methodNameToBlock.set('openFreeListenMode', (_param: InterfaceParams) => {
      // 鸿蒙没有 openFreeListenMode，用 freeListenApi.getAllFreeListenInfo 替代
      OpenApiSdk.openApi?.freeListenApi.getAllFreeListenInfo()
        .then(r => this.displayResponse(r))
    })

    this.methodNameToBlock.set('getFreeListenInfo', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.freeListenApi.getAllFreeListenInfo()
        .then(r => this.displayResponse(r))
    })

    // 运营信息
    this.methodNameToBlock.set('getOperationsInfo', (_param: InterfaceParams) => {
      OpenApiSdk.openApi?.operationsInfoApi.getOperationsInfo()
        .then(r => this.displayResponse(r))
    })

    // AI创作
    this.methodNameToBlock.set('getHotAICreateSongList', (param: InterfaceParams) => {
      this.fillDefaultParamIfNull(param)
      // 鸿蒙没有 AIFunctionApi，用 AI 歌单接口替代
      const start = this.getParam(0) ?? '0'
      const size = this.getParamNum(1) ?? 10
      OpenApiSdk.openApi?.folderApi.fetchGetSongListSquare(Number(start), size, '2', null)
        .then(r => this.displayResponse(r))
    })

    // musicSkill
    this.methodNameToBlock.set('musicSkill', (param: InterfaceParams) => {
      this.testMusicSkill(param, 'musicSkill')
    })

    this.methodNameToBlock.set('musicSkillWithSlots', (param: InterfaceParams) => {
      this.testMusicSkill(param, 'musicSkillWithSlots')
    })
  }

  // ========== 辅助方法 ==========

  /**
   * 获取参数的数字值
   */
  private getParamNum(index: number): number | null {
    const val = this.getParam(index)
    if (val === null) {
      return null
    }
    const num = Number(val)
    return Number.isNaN(num) ? null : num
  }

  /**
   * 获取逗号分隔的数字列表
   */
  private getParamNumList(index: number): number[] | null {
    const val = this.getParam(index)
    if (val === null) {
      return null
    }
    return val.split(',')
      .map(s => s.trim())
      .filter(s => s.length > 0)
      .map(s => Number(s))
      .filter(n => !Number.isNaN(n))
  }

  /**
   * 获取逗号分隔的字符串列表
   */
  private getParamStrList(index: number): string[] | null {
    const val = this.getParam(index)
    if (val === null) {
      return null
    }
    return val.split(',')
      .map(s => s.trim())
      .filter(s => s.length > 0)
  }

  /**
   * 如果参数为空则填充默认值（对应 Android fillDefaultParamIfNull）
   */
  private fillDefaultParamIfNull(param: InterfaceParams): void {
    if (this.displayMode) {
      const defaultParam = param.values
      if (this.params[0].trim().length === 0 && defaultParam.length > 0) {
        this.params[0] = defaultParam[0]
      }
      if (this.params[1].trim().length === 0 && defaultParam.length > 1) {
        this.params[1] = defaultParam[1]
      }
      if (this.params[2].trim().length === 0 && defaultParam.length > 2) {
        this.params[2] = defaultParam[2]
      }
      if (this.params[3].trim().length === 0 && defaultParam.length > 3) {
        this.params[3] = defaultParam[3]
      }
      if (this.params[4].trim().length === 0 && defaultParam.length > 4) {
        this.params[4] = defaultParam[4]
      }
    } else {
      this.params = ['', '', '', '', '']
      const defaultParam = param.values
      if (defaultParam.length > 0) {
        this.params[0] = defaultParam[0]
      }
      if (defaultParam.length > 1) {
        this.params[1] = defaultParam[1]
      }
      if (defaultParam.length > 2) {
        this.params[2] = defaultParam[2]
      }
      if (defaultParam.length > 3) {
        this.params[3] = defaultParam[3]
      }
      if (defaultParam.length > 4) {
        this.params[4] = defaultParam[4]
      }
    }
  }

  /**
   * musicSkill 测试方法（对应 Android testMusicSkill）
   */
  private testMusicSkill(param: InterfaceParams, method: string): void {
    this.fillDefaultParamIfNull(param)
    const intent = this.getParam(0) ?? ''
    const originQuestion = this.getParam(2) ?? ''
    const currentSongId = this.getParamNum(3)
    const num = this.getParamNum(4) ?? 20

    const doMusicSkillResponse = (data: Object): void => {
      // 当 intent 为 SearchSong 或为空时，尝试解析语音点歌结果
      if (intent === '' || intent === 'SearchSong') {
        const result = data as Record<string, Object>
        if (result && (result as Record<string, Object>).ret === 0) {
          const respData = (result as Record<string, Object>).data as Record<string, Object>
          if (respData) {
            // 显示 speak_command 文本
            const speakCommand = respData['getSpeakCommand'] ?
              (respData['getSpeakCommand'] as Function)() as Record<string, Object> : null
            const speakText = speakCommand ? (speakCommand['getText'] ?
              (speakCommand['getText'] as Function)() as string : null) : null
            if (speakText) {
              ToastUtil.show(speakText)
            }

            // 解析 play_command.play_list 并执行播放
            const playCommand = respData['getPlayCommand'] ?
              (respData['getPlayCommand'] as Function)() as Record<string, Object> : null
            if (playCommand) {
              const playList = playCommand['getPlayList'] ?
                (playCommand['getPlayList'] as Function)() as Array<ISongInfo> : null
              const playType = playCommand['getType'] ?
                (playCommand['getType'] as Function)() as number : 0
              const suggestCnt = playCommand['getSuggestPlayListSize'] ?
                (playCommand['getSuggestPlayListSize'] as Function)() as number : 0

              if (playList && playList.length > 0) {
                const songIds = playList.map(s => s.getSongId()).filter(id => id > 0);
                const limitCnt = suggestCnt > 0 ? Math.min(suggestCnt, songIds.length) : songIds.length;
                const limitedSongIds = songIds.slice(0, limitCnt);

                if (limitedSongIds.length > 0) {
                  OpenApiSdk.openApi?.songApi.fetchSongInfoBatch(limitedSongIds)
                    .then(songResp => {
                      if (songResp.isSuccess() && songResp.data) {
                        const songs = songResp.data
                        if (playType === 0) {
                          // 插入到当前播放位置之后并切歌
                          const pos = OpenApiSdk.playerApi?.getCurPlayPos() ?? 0
                          OpenApiSdk.playerApi?.appendSongToPlaylist(songs, pos + 1)
                          setTimeout(() => {
                            OpenApiSdk.playerApi?.next()
                          }, 200)
                        } else if (playType === 1) {
                          // 直接播放
                          OpenApiSdk.playerApi?.playSongsWithPos(songs, 0)
                        }
                      }
                    })
                }
              }
            }
          }
        }
      }
      // 最终显示结果
      this.displayResponse(data)
    }

    if (method === 'musicSkill') {
      const slotsMap = new Map<string, string>()
      const kvStrList = (this.getParam(1) ?? '').split(',')
      for (const kvStr of kvStrList) {
        const kv = kvStr.split(':')
        if (kv.length > 1) {
          slotsMap.set(kv[0], kv[1])
        }
      }
      OpenApiSdk.openApi?.searchApi.voiceSearch(intent, slotsMap, originQuestion, currentSongId ?? undefined, num)
        .then(r => doMusicSkillResponse(r))
    } else if (method === 'musicSkillWithSlots') {
      const slotItems = new Array<MusicSkillSlotItem>()
      const kvStrList = (this.getParam(1) ?? '').split(',')
      for (const kvStr of kvStrList) {
        const kv = kvStr.split(':')
        slotItems.push(new MusicSkillSlotItem(kv[0] ?? '', kv[1] ?? '', Number(kv[2]) || 0))
      }
      OpenApiSdk.openApi?.searchApi.voiceSearch(intent, slotItems, originQuestion, currentSongId ?? undefined, num)
        .then(r => doMusicSkillResponse(r))
    }
  }

  // ========== UI 构建 ==========

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_back_dark'))
            .width(44).height(44)
            .onClick(() => this.navController.pop())
          Text('OpenApi Demo')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16 })
        .borderWidth({ bottom: 0.5 })
        .borderColor('#36000000')

        // 内容区域
        Scroll() {
          Column({ space: 10 }) {
            // ===== 搜索框 =====
            Row() {
              Text('搜索方法名')
                .fontSize(14)
                .width(80)
              TextInput({ text: this.inputKey, placeholder: '输入关键字过滤' })
                .fontSize(14)
                .layoutWeight(1)
                .height(36)
                .backgroundColor(Color.White)
                .borderRadius(4)
                .onChange((value: string) => {
                  this.inputKey = value
                  this.resultMeans = this.getSearchResults()
                })
            }
            .width('100%')
            .padding({ left: 12, right: 12 })

            // ===== 方法选择器 =====
            Row() {
              Text('选择方法')
                .fontSize(14)
                .width(80)
              Button(this.apiMethod)
                .fontSize(13)
                .layoutWeight(1)
                .height(36)
                .backgroundColor(Color.White)
                .borderRadius(4)
                .borderWidth(1)
                .borderColor('#CCCCCC')
                .fontColor(Color.Black)
                .onClick(() => {
                  if (this.resultMeans.length === 0) {
                    ToastUtil.show('无匹配方法')
                    return
                  }
                  // 找到当前选中项在过滤列表中的索引
                  let selectedIdx = this.resultMeans.indexOf(this.apiMethod)
                  if (selectedIdx < 0) {
                    selectedIdx = 0
                  }
                  AppUtil.uiContext?.showTextPickerDialog({
                    range: this.resultMeans,
                    selected: selectedIdx,
                    value: this.apiMethod,
                    canLoop: false,
                    defaultPickerItemHeight: 40,
                    onAccept: (value: TextPickerResult) => {
                      this.select = value.index as number
                      this.apiMethod = value.value as string
                      this.currentValues = this.apiMeansList.get(this.apiMethod) ?? null
                      this.resetParams()
                    },
                  })
                })
            }
            .width('100%')
            .padding({ left: 12, right: 12 })

            // ===== 登录状态 =====
            Row() {
              Text('是否登录：' + (this.loginInfo ? '是' : '否'))
                .fontSize(13)
                .fontColor(this.loginInfo ? '#07C160' : '#FA5151')
            }
            .width('100%')
            .padding({ left: 12, right: 12 })

            // ===== 参数输入区域（动态显示最多5个） =====
            if (this.currentValues && this.currentValues.fileds.length > 0) {
              ForEach(this.currentValues.fileds, (field: string, index: number) => {
                TextInput({ text: this.params[index], placeholder: field || `参数${index + 1}` })
                  .fontSize(13)
                  .height(36)
                  .backgroundColor(Color.White)
                  .borderRadius(4)
                  .borderWidth(1)
                  .borderColor('#E0E0E0')
                  .margin({ left: 12, right: 12 })
                  .onChange((value: string) => {
                    this.params[index] = value
                  })
              }, (field: string, index: number) => `${field}_${index}`)
            } else {
              Text('无参数')
                .fontSize(13)
                .fontColor(Color.Gray)
                .margin({ left: 12 })
            }

            // ===== 发送请求按钮 =====
            Button('发送请求')
              .fontSize(15)
              .width('93%')
              .height(40)
              .backgroundColor('#007AFF')
              .borderRadius(8)
              .fontColor(Color.White)
              .onClick(() => {
                this.displayText = '请求已发送, 正在等待响应...'
                this.displayMode = true
                const block = this.methodNameToBlock.get(this.apiMethod)
                if (block && this.currentValues) {
                  block(this.currentValues)
                } else {
                  this.displayText = '未找到对应方法: ' + this.apiMethod
                }
              })

            // ===== 一键测试按钮 =====
            if (this.showDebugButton) {
              Button('一键测试所有接口')
                .fontSize(14)
                .width('93%')
                .height(40)
                .backgroundColor('#FF9500')
                .borderRadius(8)
                .fontColor(Color.White)
                .onClick(() => {
                  this.runAllTests()
                })
            }

            // ===== 结果显示区域 =====
            Column() {
              Text('响应结果：')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .padding({ left: 12, top: 8, bottom: 4 })

              Text(this.displayText)
                .fontSize(12)
                .fontColor('#333333')
                .width('100%')
                .padding({ left: 12, right: 12, bottom: 16 })
                .textAlign(TextAlign.Start)
                .fontFamily('monospace')
            }
            .width('93%')
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ top: 4 })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }

  // ========== 一键测试所有接口 ==========

  private async runAllTests(): Promise<void> {
    this.errorOpiNameAndMsg = []
    this.displayText = '正在请求所有接口, 请稍等...'
    this.displayMode = false

    // 先创建一个歌单，用作后续 deleteFolder、addSongToFolder、deleteSongFromFolder 的默认值
    try {
      const createResp = await OpenApiSdk.openApi?.folderApi.createFolderByName('一键测试的前置创建歌单')
      if (createResp && createResp.isSuccess()) {
        this.createFolderId = createResp.data ?? ''
        this.createFolderSuccess = true
      } else {
        this.createFolderSuccess = false
      }

      // 更新 deleteFolder 的默认参数
      const deleteParam = this.apiMeansList.get('deleteFolder')
      if (deleteParam) {
        deleteParam.values = [this.createFolderId]
      }
      const deleteBatchParam = this.apiMeansList.get('deleteFolder(批量,分割)')
      if (deleteBatchParam) {
        deleteBatchParam.values = [this.createFolderId]
      }

      // 更新 addSongToFolder 的默认参数
      const addParam = this.apiMeansList.get('addSongToFolder')
      if (addParam) {
        addParam.values = [this.createFolderId, '314818717,317968884,316868744,291130348', '', '']
      }

      // 更新 deleteSongFromFolder 的默认参数
      const delSongParam = this.apiMeansList.get('deleteSongFromFolder')
      if (delSongParam) {
        delSongParam.values = [this.createFolderId, '314818717', '', '']
      }
    } catch (e) {
      this.createFolderSuccess = false
    }

    this.createdFolderDeleted = false
    this.folderSongAdded = false

    const allKeys = Array.from(this.methodNameToBlock.keys())
    const totalCount = allKeys.length
    let completedCount = 0

    for (const name of allKeys) {
      // 跳过条件判断
      if (name === 'deleteFolder' || name === 'deleteFolder(批量,分割)') {
        if (this.createFolderSuccess === false) {
          completedCount++
          continue
        }
      } else if (name === 'addSongToFolder') {
        if (this.createFolderSuccess === false || this.createdFolderDeleted) {
          completedCount++
          continue
        }
      } else if (name === 'deleteSongFromFolder') {
        if (this.createFolderSuccess === false || this.createdFolderDeleted || !this.folderSongAdded) {
          completedCount++
          continue
        }
      }

      const param = this.apiMeansList.get(name)
      const block = this.methodNameToBlock.get(name)
      if (block && param) {
        try {
          block(param)
        } catch (e) {
          this.errorOpiNameAndMsg.push(`${name}: ${String(e)}`)
        }
      }
      completedCount++

      // 每10个接口更新一次进度
      if (completedCount % 10 === 0) {
        this.displayText = `正在请求... ${completedCount}/${totalCount}`
      }
    }

    // 等待所有异步请求完成（简化处理：根据接口数量动态等待）
    const waitTime = Math.max(3000, totalCount * 50)
    setTimeout(() => {
      if (this.errorOpiNameAndMsg.length > 0) {
        this.displayText = '失败的接口:\n' + this.errorOpiNameAndMsg.join('\n')
      } else {
        this.displayText = '所有接口已通'
      }
      this.displayMode = true
    }, waitTime)
  }
}
