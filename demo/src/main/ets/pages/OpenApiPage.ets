// OpenApiLayout.ets
import {
  CashierCreateOrderItem,
  CashierCreateOrderParams,
  EditFolderParam,
  RecommendProfileAdjustment,
  VipGuideConfigItem,
  MusicSkillSlotItem,
  AppStyleData,
  MediaResDetail,
  MediaGroupRes,
  Action
} from '@qqmusic/opisdk-openapi'
import { InterfaceParams } from '../model/InterfaceParams'
import { GalleryImageUtil, PickImageAddr } from "../utils/GalleryImageUtil";
import { IEditFolderParam, MLog, OpenApiSdk } from "@qqmusic/opisdk-base";
import { LoginApi } from "@qqmusic/opisdk-login";
import { NavController } from '../nav/NavController';
import { AppUtil } from '../utils/AppUtil';
import { IPlayerStyleData, IUserProfit, IVipGuideConfigItem, PreferencesConstants } from '@qqmusic/opisdk-entity'
import { JsonUtil } from '@qqmusic/opisdk-qmutils'
import { MMKVHelper } from '@qqmusic/opisdk-qmutils';

@ComponentV2
export struct OpenApiLayout {
  navController: NavController = NavController.getInstance()
  @Local displayText: string = '';
  @Local loginInfo: boolean = true;
  @Local inputKey: string = '';
  @Local resultMeans: string[] = [];
  @Local apiMethod: string = 'QueryWeatherInfo';
  @Local apiMeans: string[] = [
    'logApi',
    'QueryWeatherInfo',

    // 推荐相关
    'fetchSimilarSong',
    'fetchHomepageRecommendationWithSongInfo',
    'fetchGuessLikeLongAudio',
    'fetchDailyRecommendSong',
    'fetchPersonalRecommendSong',
    'fetchBannerConfig',
    'fetchPersonalRecommendRequirement',
    'setPersonalRecommendRequirement',
    //歌词
    "fetchLyric",
    "fetchAllLyric",
    "fetchAllLyricMap",
    "fetchLyricImages",
    "fetchQrcLyric",
    "fetchLyricEffectAndMirInfo",

    // 专区
    'fetchHiresSectionByShelfTypes',
    'fetchDolbySectionByShelfTypes',
    'fetchGalaxySectionByShelfTypes',
    'fetchAreaSectionByShelfTypes',
    'fetchShelfContent',

    // 专辑
    'collectAlbum',
    'fetchAlbumOfSinger',
    'fetchCollectedAlbum',
    'fetchAlbumDetail',
    'fetchNewAlbumsByArea',
    'fetchNewAlbum',
    'fetchBuyRecord',
    'fetchSongOfAlbum',
    'fetchSongOf51Album',

    // 第三方登录
    'updateThirdPartyAccount',
    'deleteThirdPartyAccountBindState',
    'queryThirdPartyAccountBindState',
    'thirdPartyLogin',

    //用户会员信息
    'fetchGreenMemberInformation',
    'fetchIotMemberInformation',
    'fetchPartnerMemberInformation',
    'fetchUserInfo',
    'canTryPlayExcellentQuality',
    'canTryPlayGalaxyQuality',
    'getFreeLimitedTimeProfitInfo',
    'canTryPlayDolbyQuality',
    'openFreeLimitedTimeAuth',

    //会员信息
    'getVipRenewalInfo',
    'getPayUrl',
    'getPayUrlInfo',
    'getCheckoutUrl',
    'fetchCashierGears',
    'fetchCashierPayUrl',
    'pollCashierOrderStatus',
    'getVipGuideConfig',
    'getUnionVipOrderList',

    // 歌曲
    'fetchSongOfSinger',
    'fetchSingerWiki',
    'fetchSingerFavState',
    'fetchSingerDetail',
    'fetchHotSingerList',
    'fetchHotSingerListWithRecommendSinger',
    'fetchHotSingerListWithFilterByPage',
    'fetchOftenSingerList',
    'fetchHotSingerListWithFilter',
    'collectSinger',
    'fetchCollectedSinger',

    // 歌单
    'createFolderByName',
    'createFolder',
    'editFolder',
    'getEditFolderTags',
    'deleteFolder',
    'fetchSongOfFolder',
    'fetchSongOfMyLikeFolder',
    'unCollectFolder',
    'fetchPersonalFolder',
    'fetchCollectedFolder',
    'collectFolder',
    'operSongOfMyLikeSongList',
    'addSongToFolderByIds',
    'deleteSongFromFolder',
    'fetchHotCategoryOfFolder',
    'fetchCategoryOfFolder',
    'fetchCategoryOfSongListScene',
    'fetchGetAiSongList',
    'fetchAllTypeAiSongList',
    'fetchFolderListByCategory',
    'fetchFolderDetail',
    'fetchSongOfAutoShow',
    'fetchCollectedSinger',
    'fetchCustomSongListSquare',
    'fetchCustomSceneSongList',
    'reportCustomScenePlay',

    // 排行榜
    'fetchSongOfRank',
    'fetchRankDetail',
    'fetchAllRankGroup',

    // 搜索
    'search',
    'searchLyric',
    'searchSong',
    'searchSmart',
    'searchSmartWithLight',
    'fetchHotKeyList',
    'voiceSearch',

    // app样式
    'fetchStyleList',
    'fetchStyleById',
    'openFreeLimitedTimeByStyleId',
    'openFreeLimitedTimeByStyleData',

    //长音频
    'fetchCategoryPageOfLongAudio',
    'fetchCategoryPageDetailOfLongAudio',
    'fetchCategoryPageModuleContentLongAudio',
    'fetchCategoryOfRecommendLongAudio',
    'fetchCategoryOfRankLongAudio',
    'fetchCategoryOfLongAudio',
    'fetchCategoryFilterOfLongAudio',
    'fetchLikeListLongAudio',
    'fetchRecentUpdateLongAudio',
    'fetchAlbumListOfRankLongAudioByCategory',
    'fetchAlbumListOfLongAudioByCategory',
    'fetchAlbumListOfRecommendLongAudioByCategory',
    'fetchCollectedLongAudioSongList',
    'collectLongAudioSong',

    //最近播放
    'deleteRecentPlay',
    'fetchRecentPlayLongAudio',
    'fetchRecentPlaySong',
    'fetchRecentPlayAlbum',
    'fetchRecentPlayFolder',
    'reportRecentPlayLongAudio',
    'reportRecentPlay',
    'reportRecentPlayNew',
    'fetchOtherPlatListeningList',

    // 绿钻付费包订单
    'createGreenOrder',
    'queryGreenOrder',

    // 免登录
    "fetchFreeSongInfo",

    // 音效配置
    'fetchCommonConfig',
    'fetchSoundEffectConfig',
    'trySuperQualityV1',

    // 下载相关
    'getDownloadUrlInfo',
    'reportDownloadQuota',

    // ai陪伴
    'operationAiListenTogetherTime',
    'getGlobalAiAccompanyRoleList',
    'getGlobalAiAccompanySongPlayUrl',
    'openGlobalAiAccompanyTry',
    'getAiAccompanyRoleList',
    'fetchAiListenTogetherRecSong',

    // 音乐治疗相关
    'fetchMusicTherapyConfigList',
    'fetchMusicTherapyTrack',

    // Session和CDN相关
    'getSession',
    'getAudioCdn',

    // 免费听相关
    'getAllFreeListenInfo',

    // 运营信息相关
    'getOperationsInfo',

    // 歌曲
    'fetchSongInfoLite',
    'fetchMirInfo',

    // 配置
    'initCommonConfig',

    // EdgeMedia
    'getMediaInfo',
    'getMediaInfoWithToken',
    'operateMediaCollectStatus',
    'getCollectList',
    'getRecommendMVList',
    'getContentArea',
    'getAreaDetail',
    'getMvRank',
    'getKTVMVInfo',

    // 播放器样式
    'fetchPlayerStyleList',
    'fetchDeskLyricDatalist',
    'fetchPlayerImmersiveLyricList',
    'fetchLyricStyleById',
    'fetchDeskLyricStyleById',
    'fetchPlayerStyleById',
    'openFreeLimitedTimeByPlayStyleV1',
    'openFreeLimitedTime',
    'openFreeLimitedTimeByPlayStyleV2',
    'fetchUploadPicQRCode',
    'fetchLoopQRCodeStatus',
    'fetchMaskDiagram',
    'uploadDiyPic',

    // 直播
    'fetchLiveInfo',
  ]
  @Local apiMeansList: Map<string, InterfaceParams> = new Map();
  private select: number | number[] = 0;
  @Local currentValues: InterfaceParams | null = null;
  @Local params: string[] = [];
  @Local imagePath: string = '';
  @Local orderId: string = '';

  splitByComma(input: string): string[] {
    return input
      .split(' ')
      .map(s => s.trim())
      .filter(s => s.length > 0)
  }

  async aboutToAppear(): Promise<void> {
    this.resultMeans = this.getSearchResults()

    this.apiMeansList.set('logApi', new InterfaceParams(['test1', 'test2', 'test3'], []))
    this.apiMeansList.set('QueryWeatherInfo', new InterfaceParams([], []))

    // 推荐
    this.apiMeansList.set('fetchSimilarSong', new InterfaceParams(['songId', 'mid', 'hasRecommendList'], ['97773', '0039MnYb0qxYhV', '97773']))
    this.apiMeansList.set('fetchHomepageRecommendationWithSongInfo', new InterfaceParams(['types'], ['200,500']))
    this.apiMeansList.set('fetchGuessLikeLongAudio', new InterfaceParams([], []))
    this.apiMeansList.set('fetchDailyRecommendSong', new InterfaceParams(['scene'], ['1']))
    this.apiMeansList.set('fetchPersonalRecommendSong', new InterfaceParams(['scene'], ['1']))
    this.apiMeansList.set('fetchBannerConfig', new InterfaceParams([], []))
    this.apiMeansList.set('fetchPersonalRecommendRequirement', new InterfaceParams([], []))
    this.apiMeansList.set('setPersonalRecommendRequirement', new InterfaceParams(['list'],
      [JsonUtil.toString<RecommendProfileAdjustment[]>([new RecommendProfileAdjustment(50, '10008', 0, 0)], {
        classKey: 'Array',
        genericTypes: [RecommendProfileAdjustment]
      })]))

    // 专区
    this.apiMeansList.set('fetchHiresSectionByShelfTypes', new InterfaceParams(['shelfTypes'], ['1006']))
    this.apiMeansList.set('fetchDolbySectionByShelfTypes', new InterfaceParams(['shelfTypes'], ['1006']))
    this.apiMeansList.set('fetchGalaxySectionByShelfTypes', new InterfaceParams(['shelfTypes'], ['1006']))
    this.apiMeansList.set('fetchAreaSectionByShelfTypes', new InterfaceParams(['AreaId', 'shelfTypes'], ['740', '1006']))
    this.apiMeansList.set('fetchShelfContent', new InterfaceParams(['shelfId', 'contentSize', 'lastContentId', 'areaId'], ['6681', '20', '', '740']))

    // 专辑
    this.apiMeansList.set('collectAlbum', new InterfaceParams(['isCollect', 'albumIdList'], ['1', '8218']))
    this.apiMeansList.set('fetchAlbumOfSinger', new InterfaceParams(['singerId', 'singerMid', 'page', 'count', 'sortType'], ['1', '1']))
    this.apiMeansList.set('fetchCollectedAlbum', new InterfaceParams(['start', 'size', 'type'], ['0', '50']))
    this.apiMeansList.set('fetchAlbumDetail', new InterfaceParams(['albumId'], ['4805991']))
    this.apiMeansList.set('fetchNewAlbumsByArea', new InterfaceParams([], []))
    this.apiMeansList.set('fetchNewAlbum', new InterfaceParams(['area', 'page', 'count', 'type'], ['1']))
    this.apiMeansList.set('fetchBuyRecord', new InterfaceParams(['tag', 'page'], ['2', '0']))
    this.apiMeansList.set('fetchSongOfAlbum', new InterfaceParams(['albumId', 'albumMid', 'page', 'count', 'orderType', 'orderBy', 'begin', 'beginSongId'], ['36062', '', '', '20', '', '', '', '']))
    this.apiMeansList.set('fetchSongOf51Album', new InterfaceParams(['albumId', 'begin', 'count'], ['36062', '0', '20']))

    // 第三方登录
    this.apiMeansList.set('updateThirdPartyAccount', new InterfaceParams(['partnerAppId', 'partnerAccessToken', 'partnerAccountId', 'forceBind'], []))
    this.apiMeansList.set('deleteThirdPartyAccountBindState', new InterfaceParams(['partnerAppId', 'partnerAccessToken', 'partnerAccountId'], []))
    this.apiMeansList.set('queryThirdPartyAccountBindState', new InterfaceParams(['partnerAppId', 'partnerAccessToken', 'partnerAccountId'], []))
    this.apiMeansList.set('thirdPartyLogin', new InterfaceParams(['partnerAppId', 'partnerAccessToken', 'partnerAccountId'], []))

    // 用户信息
    this.apiMeansList.set('fetchGreenMemberInformation', new InterfaceParams([], []))
    this.apiMeansList.set('fetchIotMemberInformation', new InterfaceParams([], []))
    this.apiMeansList.set('fetchPartnerMemberInformation', new InterfaceParams([], []))
    this.apiMeansList.set('fetchUserInfo', new InterfaceParams([], []))
    this.apiMeansList.set('canTryPlayExcellentQuality', new InterfaceParams([], []))
    this.apiMeansList.set('canTryPlayGalaxyQuality', new InterfaceParams([], []))
    this.apiMeansList.set('getFreeLimitedTimeProfitInfo', new InterfaceParams([], []))
    this.apiMeansList.set('canTryPlayDolbyQuality', new InterfaceParams([], []))
    this.apiMeansList.set('openFreeLimitedTimeAuth', new InterfaceParams([], []))

    // 会员信息
    this.apiMeansList.set('getVipRenewalInfo', new InterfaceParams([], []))
    this.apiMeansList.set('getPayUrl', new InterfaceParams([], []))
    this.apiMeansList.set('getPayUrlInfo', new InterfaceParams([], []))
    this.apiMeansList.set('getCheckoutUrl', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCashierGears', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCashierPayUrl', new InterfaceParams([], []))
    this.apiMeansList.set('pollCashierOrderStatus', new InterfaceParams([], []))
    this.apiMeansList.set('getVipGuideConfig', new InterfaceParams([], []))
    this.apiMeansList.set('getUnionVipOrderList', new InterfaceParams([], []))

    // 歌手
    this.apiMeansList.set('fetchSongOfSinger', new InterfaceParams(['singerId', 'singerMid', 'page', 'count', 'sortType'], []))
    this.apiMeansList.set('fetchSingerWiki', new InterfaceParams(['singerId', 'singerMid'], []))
    this.apiMeansList.set('fetchSingerFavState', new InterfaceParams(['singerId', 'singerMid'], []))
    this.apiMeansList.set('fetchSingerDetail', new InterfaceParams(['singerId', 'singerMid', 'page', 'count', 'sortType', 'needWiki', 'needFavState'], []))
    this.apiMeansList.set('fetchHotSingerList', new InterfaceParams(['area', 'sex', 'genre', 'bigResponse'], []))
    this.apiMeansList.set('fetchHotSingerListWithRecommendSinger', new InterfaceParams(['area', 'sex', 'genre', 'bigResponse'], []))
    this.apiMeansList.set('fetchHotSingerListWithFilterByPage', new InterfaceParams(['query', 'area', 'sex', 'page', 'page_size'], []))
    this.apiMeansList.set('fetchOftenSingerList', new InterfaceParams([], []))
    this.apiMeansList.set('fetchHotSingerListWithFilter', new InterfaceParams(['area', 'sex', 'genre', 'index', 'bigResponse'], []))
    this.apiMeansList.set('collectSinger', new InterfaceParams(['isCollect', 'singerIdList'], []))
    this.apiMeansList.set('fetchCollectedSinger', new InterfaceParams(['page', 'count'], ['0', '10']))

    // 歌词
    this.apiMeansList.set('fetchLyric', new InterfaceParams(['songId', 'mid'], []))
    this.apiMeansList.set('fetchAllLyric', new InterfaceParams(['songId', 'mid'], []))
    this.apiMeansList.set('fetchAllLyricMap', new InterfaceParams(['songId', 'songMid'], []))
    this.apiMeansList.set('fetchLyricImages', new InterfaceParams(['songId', 'resolutionType'], []))
    this.apiMeansList.set('fetchQrcLyric', new InterfaceParams(['songId', 'mid', 'lyricType'], []))
    this.apiMeansList.set('fetchLyricEffectAndMirInfo',
      new InterfaceParams(['type', 'songId', 'songMid', 'scene', 'templateId', 'cacheUniqId'], ['mir', '102350740', '003hj8yv0e6SW8', ' voyage', '0', '']))

    // 歌单
    this.apiMeansList.set('createFolderByName', new InterfaceParams(['folderName'], ['单元测试歌单1']))
    this.apiMeansList.set('createFolder', new InterfaceParams(['jsonParam'], [JsonUtil.toString(new EditFolderParam('1234567', 'testFolderId7'))]))
    this.apiMeansList.set('editFolder', new InterfaceParams(['jsonParam'], [JsonUtil.toString(new EditFolderParam('9632725537', 'testFolderId2'))]))
    this.apiMeansList.set('getEditFolderTags', new InterfaceParams([], []))
    this.apiMeansList.set('deleteFolder', new InterfaceParams(['folderIds'], ['9632693942']))
    this.apiMeansList.set('fetchSongOfFolder', new InterfaceParams(['folderId', 'passBack', 'count', 'source'], ['9416857216', '1', '1', '1']))
    this.apiMeansList.set('fetchSongOfMyLikeFolder', new InterfaceParams(['passBack', 'count'], []))
    this.apiMeansList.set('unCollectFolder', new InterfaceParams(['folderIds'], ['1']))
    this.apiMeansList.set('fetchPersonalFolder', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCollectedFolder', new InterfaceParams([], []))
    this.apiMeansList.set('collectFolder', new InterfaceParams(['folderId'], ['1']))
    this.apiMeansList.set('operSongOfMyLikeSongList', new InterfaceParams(['isAdd', 'songIds', 'songMids'], ['1', '314818717']))
    this.apiMeansList.set('addSongToFolderByIds', new InterfaceParams(['folderId', 'songIds', 'songMids'], ['9632693674', '314818717']))
    this.apiMeansList.set('deleteSongFromFolder', new InterfaceParams(['folderId', 'songIds', 'songMids'], ['9632693674', '314818717']))
    this.apiMeansList.set('fetchHotCategoryOfFolder', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCategoryOfFolder', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCategoryOfSongListScene', new InterfaceParams([], []))
    this.apiMeansList.set('fetchGetAiSongList', new InterfaceParams([], []))
    this.apiMeansList.set('fetchAllTypeAiSongList', new InterfaceParams(['size', 'page'], ['1', '1']))
    this.apiMeansList.set('fetchFolderListByCategory', new InterfaceParams(['groupId', 'labelId', 'page', 'count'], ['1', '1', '1', '1']))
    this.apiMeansList.set('fetchFolderDetail', new InterfaceParams(['folderId'], ['3805603854']))
    this.apiMeansList.set('fetchSongOfAutoShow', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCustomSongListSquare', new InterfaceParams([], []))
    this.apiMeansList.set('fetchCustomSceneSongList', new InterfaceParams([], []))
    this.apiMeansList.set('reportCustomScenePlay', new InterfaceParams([], []))

    // 排行榜
    this.apiMeansList.set('fetchSongOfRank', new InterfaceParams(['rankId', 'page', 'count'], []))
    this.apiMeansList.set('fetchRankDetail', new InterfaceParams(['rankId', 'page', 'count'], []))
    this.apiMeansList.set('fetchAllRankGroup', new InterfaceParams([], []))

    // 搜索
    this.apiMeansList.set('search', new InterfaceParams(['keyword', 'songtype', 'page', 'num'], []))
    this.apiMeansList.set('searchLyric', new InterfaceParams(['keyword', 'songtype', 'page', 'num'], []))
    this.apiMeansList.set('searchSong', new InterfaceParams(['keyword', 'songtype', 'page', 'num'], []))
    this.apiMeansList.set('searchSmart', new InterfaceParams(['keyword'], []))
    this.apiMeansList.set('searchSmartWithLight', new InterfaceParams(['keyword'], []))
    this.apiMeansList.set('fetchHotKeyList', new InterfaceParams(['type', 'mode'], []))
    this.apiMeansList.set('voiceSearch', new InterfaceParams([], []))

    // app样式
    this.apiMeansList.set('fetchStyleList', new InterfaceParams([], []))
    this.apiMeansList.set('fetchStyleById', new InterfaceParams([], []))
    this.apiMeansList.set('openFreeLimitedTimeByStyleId', new InterfaceParams([], []))
    this.apiMeansList.set('openFreeLimitedTimeByStyleData', new InterfaceParams([], []))

    // 最近播放
    this.apiMeansList.set('fetchRecentPlaySong', new InterfaceParams(['updateTime'], ['0']))

    // 绿钻付费包
    this.apiMeansList.set('createGreenOrder', new InterfaceParams(['matchId', 'openId', 'num'], ['test01', '', '1']))
    this.apiMeansList.set('queryGreenOrder', new InterfaceParams(['matchId', 'orderId'], ['test01', '']))

    // 免登录
    this.apiMeansList.set('fetchFreeSongInfo', new InterfaceParams(['songId', 'songToken'], ['626007228', '294c0aa3ecd76bfd627e2b045bf2fa898eacf466816ceef3cb074808cce0c95f']))

    // 音效配置
    this.apiMeansList.set('fetchCommonConfig', new InterfaceParams([], []))
    this.apiMeansList.set('fetchSoundEffectConfig', new InterfaceParams([], []))
    this.apiMeansList.set('fetchSoundEffectInfo', new InterfaceParams([], []))

    // 下载相关
    this.apiMeansList.set('getDownloadUrlInfo', new InterfaceParams([], []))
    this.apiMeansList.set('reportDownloadQuota', new InterfaceParams([], []))

    // ai陪伴
    this.apiMeansList.set('operationAiListenTogetherTime', new InterfaceParams([], []))
    this.apiMeansList.set('getGlobalAiAccompanyRoleList', new InterfaceParams([], []))
    this.apiMeansList.set('getGlobalAiAccompanySongPlayUrl', new InterfaceParams([], []))
    this.apiMeansList.set('openGlobalAiAccompanyTry', new InterfaceParams([], []))
    this.apiMeansList.set('getAiAccompanyRoleList', new InterfaceParams([], []))
    this.apiMeansList.set('fetchAiListenTogetherRecSong', new InterfaceParams([], []))

    // 音乐治疗
    this.apiMeansList.set('fetchMusicTherapyConfigList', new InterfaceParams([], []))
    this.apiMeansList.set('fetchMusicTherapyTrack', new InterfaceParams([], []))

    // Session和CDN相关
    this.apiMeansList.set('getSession', new InterfaceParams([], []))
    this.apiMeansList.set('getAudioCdn', new InterfaceParams([], []))

    // 免费听相关
    this.apiMeansList.set('getAllFreeListenInfo', new InterfaceParams([], []))

    // 运营信息相关
    this.apiMeansList.set('getOperationsInfo', new InterfaceParams([], []))

    // 歌曲
    this.apiMeansList.set('fetchSongInfoLite', new InterfaceParams([], []))
    this.apiMeansList.set('fetchMirInfo', new InterfaceParams([], []))
    this.apiMeansList.set('initCommonConfig', new InterfaceParams([], []))

    // EdgeMedia
    this.apiMeansList.set('getMediaInfo', new InterfaceParams(['mediaIds(comma separated)'], ['002KYH8j2ti2k8']))
    this.apiMeansList.set('getMediaInfoWithToken', new InterfaceParams(['vid(comma separated)', 'token(comma separated)'], ['002KYH8j2ti2k8', 'token1']))
    this.apiMeansList.set('operateMediaCollectStatus', new InterfaceParams(['operate(1-add, 2-cancel)', 'vid'], ['1', 'vid1']))
    this.apiMeansList.set('getCollectList', new InterfaceParams(['page', 'pageSize'], ['0', '20']))
    this.apiMeansList.set('getRecommendMVList', new InterfaceParams(['type', 'areaID', 'categoryType'], ['1', '0', '0']))
    this.apiMeansList.set('getContentArea', new InterfaceParams(['specialArea'], ['696']))
    this.apiMeansList.set('getAreaDetail', new InterfaceParams(['specialArea', 'groupId', 'size'], ['696', '1', '4']))
    this.apiMeansList.set('getMvRank', new InterfaceParams(['rankType', 'area', 'abstract(0/1)'], ['1', '0', '1']))
    this.apiMeansList.set('getKTVMVInfo', new InterfaceParams(['songIds(comma separated)'], ['101,102']))

    // 播放器样式
    this.apiMeansList.set('fetchPlayerStyleList', new InterfaceParams(['pageIndex', 'pageSize'], ['0', '30']))
    this.apiMeansList.set('fetchDeskLyricDatalist', new InterfaceParams(['pageIndex', 'pageSize'], ['0', '30']))
    this.apiMeansList.set('fetchPlayerImmersiveLyricList', new InterfaceParams(['pageIndex', 'pageSize'], ['0', '30']))
    this.apiMeansList.set('fetchLyricStyleById', new InterfaceParams(['styleId'], ['1']))
    this.apiMeansList.set('fetchDeskLyricStyleById', new InterfaceParams(['styleId'], ['1']))
    this.apiMeansList.set('fetchPlayerStyleById', new InterfaceParams(['styleId'], ['0']))
    this.apiMeansList.set('openFreeLimitedTimeByPlayStyleV1', new InterfaceParams(['styleId'], ['1']))
    this.apiMeansList.set('openFreeLimitedTime', new InterfaceParams(['bizType', 'bizId'], ['6', '0']))
    this.apiMeansList.set('openFreeLimitedTimeByPlayStyleV2', new InterfaceParams([], []))
    this.apiMeansList.set('fetchUploadPicQRCode', new InterfaceParams(['businessType'], ['uploadpic']))
    this.apiMeansList.set('fetchLoopQRCodeStatus', new InterfaceParams(['qrCode'], ['0']))
    this.apiMeansList.set('fetchMaskDiagram', new InterfaceParams(['requestType', 'businessTaskId'], []))
    this.apiMeansList.set('uploadDiyPic', new InterfaceParams(['requestType', 'code', 'data'], []))

    this.apiMeansList.set('fetchLiveInfo', new InterfaceParams([], []))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 10 }) {
          // 搜索关键字输入区域
          Row() {
            Text('输入搜索关键字')
              .fontSize(16)

            TextInput({ text: this.inputKey, placeholder: '' })
              .onChange((value: string) => {
                this.inputKey = value
                this.resultMeans = this.getSearchResults();
              }).layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 5, right: 5 })

          // 选择框
          Button(this.apiMethod).margin(20).onClick(() => {
            AppUtil.uiContext?.showTextPickerDialog({
              range: this.resultMeans,
              selected: this.select,
              value: this.apiMethod,
              canLoop: false,
              defaultPickerItemHeight: 40,
              onAccept: (value: TextPickerResult) => {
                // 设置select为按下确定按钮时候的选中项index，这样当弹窗再次弹出时显示选中的是上一次确定的选项
                this.select = value.index;
                MLog.i('OpenApiLayout', this.select + '');
                // 点击确定后，被选到的文本数据展示到页面
                this.apiMethod = value.value as string;
                MLog.i('OpenApiLayout', "TextPickerDialog:onAccept()" + JSON.stringify(value));
                this.currentValues = this.apiMeansList.get(this.apiMethod)
                if (this.currentValues) {
                  if (this.currentValues.values.length > 0) {
                    this.params = this.currentValues.values
                  } else {
                    this.params = []
                    for (let index = 0; index < this.currentValues.fileds.length; index++) {
                      this.params[index] = ''
                    }
                  }
                }
              },
            })
          })

          // 参数输入框
          if (this.currentValues && this.currentValues.fileds.length > 0) {
            ForEach(this.currentValues.fileds, (field: string, index: number) => {
              TextInput({ text: this.params[index], placeholder: field || "" })
                .fontSize(14)
                .margin(5)
                .onChange((value: string) => {
                  this.params[index] = value
                })
            })
          } else {
            Text('无参数')
              .fontSize(14)
              .fontColor(Color.Gray)
          }

          // 登录信息显示
          Text('是否登录：' + this.loginInfo)
            .fontSize(14)

          if (this.apiMethod === 'createFolder' || this.apiMethod === 'editFolder') {
            Button('获取图片地址')
              .onClick(async () => {
                try {
                  let addr: PickImageAddr = await GalleryImageUtil.pickOneImage()
                  addr = await GalleryImageUtil.exportPhotoUriToCache(addr.photoUri)
                  this.imagePath = addr.cachePath ?? ''
                } catch (e) {
                }
              })
              .margin({ top: 10 })
          }

          // 发送请求按钮
          Button('发送请求')
            .onClick(() => {
              switch (this.apiMethod) {
                case 'QueryWeatherInfo': {
                  this.fetchWeatherInfo()
                  break;
                }
                // 推荐相关
                case 'fetchSimilarSong': {
                  this.fetchSimilarSong()
                  break;
                }
                case 'fetchHomepageRecommendationWithSongInfo': {
                  this.fetchHomepageRecommendationWithSongInfo()
                  break;
                }
                case 'fetchGuessLikeLongAudio': {
                  this.fetchGuessLikeLongAudio()
                  break;
                }
                case 'fetchDailyRecommendSong': {
                  this.fetchDailyRecommendSong()
                  break;
                }
                case 'fetchPersonalRecommendSong': {
                  this.fetchPersonalRecommendSong()
                  break;
                }
                case 'fetchBannerConfig': {
                  this.fetchBannerConfig()
                  break;
                }
                case 'fetchPersonalRecommendRequirement': {
                  this.fetchPersonalRecommendRequirement()
                  break;
                }
                case 'setPersonalRecommendRequirement': {
                  this.setPersonalRecommendRequirement()
                  break;
                }

                // 专区
                case 'fetchHiresSectionByShelfTypes': {
                  this.fetchHiresSectionByShelfTypes()
                  break;
                }
                case 'fetchDolbySectionByShelfTypes': {
                  this.fetchDolbySectionByShelfTypes()
                  break;
                }
                case 'fetchGalaxySectionByShelfTypes': {
                  this.fetchGalaxySectionByShelfTypes()
                  break;
                }
                case 'fetchAreaSectionByShelfTypes': {
                  this.fetchAreaSectionByShelfTypes()
                  break;
                }
                case 'fetchShelfContent': {
                  this.fetchShelfContent()
                  break;
                }

                // 专辑
                case 'collectAlbum': {
                  this.collectAlbum()
                  break;
                }

                case 'fetchAlbumOfSinger': {
                  this.fetchAlbumOfSinger()
                  break;
                }
                case 'fetchCollectedAlbum': {
                  this.fetchCollectedAlbum()
                  break;
                }
                case 'fetchAlbumDetail': {
                  this.fetchAlbumDetail()
                  break;
                }
                case 'fetchNewAlbumsByArea': {
                  this.fetchNewAlbumsByArea()
                  break;
                }
                case 'fetchNewAlbum': {
                  this.fetchNewAlbum()
                  break;
                }
                case 'fetchBuyRecord': {
                  this.fetchBuyRecord()
                  break;
                }
                case 'fetchSongOfAlbum': {
                  this.fetchSongOfAlbum()
                  break;
                }
                case 'fetchSongOf51Album': {
                  this.fetchSongOf51Album()
                  break;
                }

                // 歌手
                case 'fetchSongOfSinger': {
                  this.fetchSongOfSinger()
                  break;
                }
                case 'fetchSingerWiki': {
                  this.fetchSingerWiki()
                  break;
                }
                case 'fetchSingerFavState': {
                  this.fetchSingerFavState()
                  break;
                }
                case 'fetchSingerDetail': {
                  this.fetchSingerDetail()
                  break;
                }
                case 'fetchHotSingerList': {
                  this.fetchHotSingerList()
                  break;
                }
                case 'fetchHotSingerListWithRecommendSinger': {
                  this.fetchHotSingerListWithRecommendSinger()
                  break;
                }
                case 'fetchHotSingerListWithFilterByPage': {
                  this.fetchHotSingerListWithFilterByPage()
                  break;
                }
                case 'fetchOftenSingerList': {
                  this.fetchOftenSingerList()
                  break;
                }
                case 'fetchHotSingerListWithFilter': {
                  this.fetchHotSingerListWithFilter()
                  break;
                }
                case 'collectSinger': {
                  this.collectSinger()
                  break;
                }
                case 'fetchCollectedSinger': {
                  this.fetchCollectedSinger()
                  break;
                }
                // 歌单
                case 'createFolderByName': {
                  this.createFolderByName()
                  break;
                }
                case 'createFolder': {
                  this.createFolder()
                  break;
                }
                case 'editFolder': {
                  this.editFolder()
                  break;
                }
                case 'getEditFolderTags': {
                  this.getEditFolderTags()
                  break;
                }
                case 'deleteFolder': {
                  this.deleteFolder()
                  break;
                }
                case 'fetchSongOfFolder': {
                  this.fetchSongOfFolder()
                  break;
                }
                case 'fetchSongOfMyLikeFolder': {
                  this.fetchSongOfMyLikeFolder()
                  break;
                }
                case 'unCollectFolder': {
                  this.unCollectFolder()
                  break;
                }
                case 'fetchPersonalFolder': {
                  this.fetchPersonalFolder()
                  break;
                }
                case 'fetchCollectedFolder': {
                  this.fetchCollectedFolder()
                  break;
                }
                case 'collectFolder': {
                  this.collectFolder()
                  break;
                }
                case 'operSongOfMyLikeSongList': {
                  this.operSongOfMyLikeSongList()
                  break;
                }
                case 'addSongToFolderByIds': {
                  this.addSongToFolderByIds()
                  break;
                }
                case 'deleteSongFromFolder': {
                  this.deleteSongFromFolder()
                  break;
                }
                case 'fetchHotCategoryOfFolder': {
                  this.fetchHotCategoryOfFolder()
                  break;
                }
                case 'fetchCategoryOfFolder': {
                  this.fetchCategoryOfFolder()
                  break;
                }
                case 'fetchCategoryOfSongListScene': {
                  this.fetchCategoryOfSongListScene()
                  break;
                }
                case 'fetchGetAiSongList': {
                  this.fetchGetAiSongList()
                  break;
                }
                case 'fetchAllTypeAiSongList': {
                  this.fetchAllTypeAiSongList()
                  break;
                }
                case 'fetchFolderListByCategory': {
                  this.fetchFolderListByCategory()
                  break;
                }
                case 'fetchFolderDetail': {
                  this.fetchFolderDetail()
                  break;
                }
                case 'fetchSongOfAutoShow': {
                  this.fetchSongOfAutoShow()
                  break;
                }
                case 'fetchCustomSongListSquare': {
                  this.fetchCustomSongListSquare()
                  break;
                }
                case 'fetchCustomSceneSongList': {
                  this.fetchCustomSceneSongList()
                  break;
                }
                case 'reportCustomScenePlay': {
                  this.reportCustomScenePlay()
                  break;
                }

                // 排行榜
                case 'fetchSongOfRank': {
                  this.fetchSongOfRank()
                  break;
                }
                case 'fetchRankDetail': {
                  this.fetchRankDetail()
                  break;
                }
                case 'fetchAllRankGroup': {
                  this.fetchAllRankGroup()
                  break;
                }
                //歌词
                case 'fetchAllLyric': {
                  this.fetchAllLyric();
                  break;
                }
                case 'fetchLyricImages': {
                  this.fetchLyricImages();
                  break;
                }
                case 'fetchLyricEffectAndMirInfo': {
                  this.fetchLyricEffectAndMirInfo();
                  break;
                }
                default: {
                  break;
                }

                //三方绑定
                case 'updateThirdPartyAccount': {
                  this.updateThirdPartyAccount()
                  break
                }
                case 'deleteThirdPartyAccountBindState': {
                  this.deleteThirdPartyAccountBindState()
                  break
                }
                case 'queryThirdPartyAccountBindState': {
                  this.queryThirdPartyAccountBindState()
                  break
                }
                case 'thirdPartyLogin': {
                  this.thirdPartyLogin()
                  break
                }

                //用户会员信息
                case 'fetchGreenMemberInformation': {
                  this.fetchGreenMemberInformation()
                  break
                }
                case 'fetchIotMemberInformation': {
                  this.fetchIotMemberInformation()
                  break
                }
                case 'fetchPartnerMemberInformation': {
                  this.fetchPartnerMemberInformation()
                  break
                }
                case 'fetchUserInfo': {
                  this.fetchUserInfo()
                  break
                }
                case 'canTryPlayExcellentQuality': {
                  this.canTryPlayExcellentQuality()
                  break
                }
                case 'canTryPlayGalaxyQuality': {
                  this.canTryPlayGalaxyQuality()
                  break
                }
                case 'getFreeLimitedTimeProfitInfo': {
                  this.getFreeLimitedTimeProfitInfo()
                  break
                }
                case 'canTryPlayDolbyQuality': {
                  this.canTryPlayDolbyQuality()
                  break
                }
                case 'openFreeLimitedTimeAuth': {
                  this.openFreeLimitedTimeAuth()
                  break
                }
                //会员信息
                case 'getVipRenewalInfo': {
                  this.getVipRenewalInfo()
                  break
                }
                case 'getPayUrl': {
                  this.getPayUrl()
                  break
                }
                case 'getPayUrlInfo': {
                  this.getPayUrlInfo()
                  break
                }
                case 'getCheckoutUrl': {
                  this.getCheckoutUrl()
                }
                case 'fetchCashierGears': {
                  this.fetchCashierGears()
                }
                case 'fetchCashierPayUrl': {
                  this.fetchCashierPayUrl()
                }
                case 'pollCashierOrderStatus': {
                  this.pollCashierOrderStatus()
                }
                case 'getVipGuideConfig': {
                  this.getVipGuideConfig()
                }
                case 'getUnionVipOrderList': {
                  this.getUnionVipOrderList()
                }
                // 搜索
                case 'search': {
                  this.search()
                  break;
                }
                case 'searchLyric': {
                  this.searchLyric()
                  break;
                }
                case 'searchSong': {
                  this.searchSong()
                  break;
                }
                case 'searchSmart': {
                  this.searchSmart()
                  break;
                }
                case 'searchSmartWithLight': {
                  this.searchSmartWithLight()
                  break;
                }
                case 'fetchHotKeyList': {
                  this.fetchHotKeyList()
                  break;
                }
                case 'voiceSearch': {
                  this.voiceSearch()
                  break;
                }
                // app样式
                case 'fetchStyleList': {
                  this.fetchStyleList()
                  break;
                }
                case 'fetchStyleById': {
                  this.fetchStyleById()
                  break
                }
                case 'openFreeLimitedTimeByStyleId': {
                  this.openFreeLimitedTimeByStyleId()
                  break
                }
                case 'openFreeLimitedTimeByStyleData': {
                  this.openFreeLimitedTimeByStyleData()
                  break
                }

                //长音频
                case 'fetchCategoryPageOfLongAudio': {
                  this.fetchCategoryPageOfLongAudio()
                }
                case 'fetchCategoryPageDetailOfLongAudio': {
                  this.fetchCategoryPageDetailOfLongAudio()
                }
                case 'fetchCategoryPageModuleContentLongAudio': {
                  this.fetchCategoryPageModuleContentLongAudio()
                }
                case 'fetchCategoryOfRecommendLongAudio': {
                  this.fetchCategoryOfRecommendLongAudio()
                }
                case 'fetchCategoryOfRankLongAudio': {
                  this.fetchCategoryOfRankLongAudio()
                }

                case 'fetchCategoryOfLongAudio': {
                  this.fetchCategoryOfLongAudio()
                }

                case 'fetchCategoryFilterOfLongAudio': {
                  this.fetchCategoryFilterOfLongAudio()
                }

                case 'fetchLikeListLongAudio': {
                  this.fetchLikeListLongAudio()
                }

                case 'fetchRecentUpdateLongAudio': {
                  this.fetchRecentUpdateLongAudio()
                }

                case 'fetchAlbumListOfRankLongAudioByCategory': {
                  this.fetchAlbumListOfRankLongAudioByCategory()
                }
                case 'fetchAlbumListOfLongAudioByCategory': {
                  this.fetchAlbumListOfLongAudioByCategory()
                }
                case 'fetchAlbumListOfRecommendLongAudioByCategory': {
                  this.fetchAlbumListOfLongAudioByCategory()
                }

                case 'fetchCollectedLongAudioSongList': {
                  this.fetchCollectedLongAudioSongList()
                }
                case 'collectLongAudioSong': {
                  this.collectLongAudioSong()
                }
                //最近播放
                case 'deleteRecentPlay': {
                  this.deleteRecentPlay()
                }
                case 'fetchRecentPlayLongAudio': {
                  this.fetchRecentPlayLongAudio()
                }
                case 'fetchRecentPlaySong': {
                  this.fetchRecentPlaySong()
                }
                case 'fetchRecentPlayAlbum': {
                  this.fetchRecentPlayAlbum()
                }

                case 'fetchRecentPlayFolder': {

                  this.fetchRecentPlayFolder()
                }
                case 'reportRecentPlayLongAudio': {
                  this.reportRecentPlayLongAudio()
                }
                case 'reportRecentPlay': {
                  this.reportRecentPlay()
                }
                case 'reportRecentPlayNew': {
                  this.reportRecentPlayNew()
                }

                case 'fetchOtherPlatListeningList': {
                  this.fetchOtherPlatListeningList()
                }

                // 绿钻付费包
                case 'createGreenOrder': {
                  this.createGreenOrder()
                }

                case 'queryGreenOrder': {
                  this.queryGreenOrder()
                }

                // 免登录
                case 'fetchFreeSongInfo': {
                  this.fetchFreeSongInfo()
                }

                // 音效配置
                case 'fetchCommonConfig': {
                  this.fetchCommonConfig()
                  break;
                }
                case 'fetchSoundEffectConfig': {
                  this.fetchSoundEffectConfig()
                  break;
                }
                case 'trySuperQualityV1': {
                  this.trySuperQualityV1()
                  break;
                }

                // 下载相关
                case 'getDownloadUrlInfo': {
                  this.getDownloadUrlInfo()
                  break;
                }
                case 'reportDownloadQuota': {
                  this.reportDownloadQuota()
                  break;
                }

                // ai陪伴
                case 'operationAiListenTogetherTime': {
                  this.operationAiListenTogetherTime()
                  break;
                }
                case 'getGlobalAiAccompanyRoleList': {
                  this.getGlobalAiAccompanyRoleList()
                  break;
                }
                case 'getGlobalAiAccompanySongPlayUrl': {
                  this.getGlobalAiAccompanySongPlayUrl()
                  break;
                }
                case 'openGlobalAiAccompanyTry': {
                  this.openGlobalAiAccompanyTry()
                  break;
                }
                case 'getAiAccompanyRoleList': {
                  this.getAiAccompanyRoleList()
                  break;
                }
                case 'fetchAiListenTogetherRecSong': {
                  this.fetchAiListenTogetherRecSong()
                  break;
                }

                // 音乐治疗
                case 'fetchMusicTherapyConfigList': {
                  this.fetchMusicTherapyConfigList()
                  break;
                }
                case 'fetchMusicTherapyTrack': {
                  this.fetchMusicTherapyTrack()
                  break;
                }

                // Session和CDN相关
                case 'getSession': {
                  this.getSession()
                  break;
                }
                case 'getAudioCdn': {
                  this.getAudioCdn()
                  break;
                }
                case 'getAllFreeListenInfo': {
                  this.getAllFreeListenInfo()
                  break
                }

                // 运营信息相关
                case 'getOperationsInfo': {
                  this.getOperationsInfo()
                  break;
                }

                // 歌曲
                case 'fetchSongInfoLite': {
                  this.fetchSongInfoLite()
                  break;
                }
                case 'fetchMirInfo': {
                  this.fetchMirInfo()
                  break;
                }
                case 'initCommonConfig': {
                  this.initCommonConfig()
                  break;
                }

                // EdgeMedia
                case 'getMediaInfo': {
                  this.getMediaInfo()
                  break;
                }
                case 'getMediaInfoWithToken': {
                  this.getMediaInfoWithToken()
                  break;
                }
                case 'operateMediaCollectStatus': {
                  this.operateMediaCollectStatus()
                  break;
                }
                case 'getCollectList': {
                  this.getCollectList()
                  break;
                }
                case 'getRecommendMVList': {
                  this.getRecommendMVList()
                  break;
                }
                case 'getContentArea': {
                  this.getContentArea()
                  break;
                }
                case 'getAreaDetail': {
                  this.getAreaDetail()
                  break;
                }
                case 'getMvRank': {
                  this.getMvRank()
                  break;
                }
                case 'getKTVMVInfo': {
                  this.getKTVMVInfo()
                  break;
                }

                // 播放器样式
                case 'fetchPlayerStyleList': {
                  this.fetchPlayerStyleList()
                  break;
                }
                case 'fetchDeskLyricDatalist': {
                  this.fetchDeskLyricDatalist()
                  break;
                }
                case 'fetchPlayerImmersiveLyricList': {
                  this.fetchPlayerImmersiveLyricList()
                  break;
                }
                case 'fetchLyricStyleById': {
                  this.fetchLyricStyleById()
                  break;
                }
                case 'fetchDeskLyricStyleById': {
                  this.fetchDeskLyricStyleById()
                  break;
                }
                case 'fetchPlayerStyleById': {
                  this.fetchPlayerStyleById()
                  break;
                }
                case 'openFreeLimitedTimeByPlayStyleV1': {
                  this.openFreeLimitedTimeByPlayStyleV1()
                  break;
                }
                case 'openFreeLimitedTime': {
                  this.openFreeLimitedTime()
                  break;
                }
                case 'openFreeLimitedTimeByPlayStyleV2': {
                  this.openFreeLimitedTimeByPlayStyleV2()
                  break;
                }
                case 'fetchUploadPicQRCode': {
                  this.fetchUploadPicQRCode()
                  break;
                }
                case 'fetchLoopQRCodeStatus': {
                  this.fetchLoopQRCodeStatus()
                  break;
                }
                case 'fetchMaskDiagram': {
                  this.fetchMaskDiagram()
                  break;
                }
                case 'uploadDiyPic': {
                  this.uploadDiyPic()
                  break;
                }
                case 'fetchLiveInfo': {
                  this.fetchLiveInfo()
                  break;
                }
              }
            })
            .margin({ top: 10 })


          Button('设置校验token为过期状态')
            .width('100%')
            .onClick(() => {
              // 设置token过期逻辑
            })

          // 显示结果区域
          Column() {
            Text(this.displayText)
              .textAlign(TextAlign.Start)
              .padding({ left: 20, right: 20, bottom: 20 })

          }
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
      }
    }
    .hideTitleBar(true)
  }

  //会员

  getVipRenewalInfo() {
    OpenApiSdk.openApi?.vipApi.getVipRenewalInfo().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  getPayUrlInfo() {
    OpenApiSdk.openApi?.vipApi.getPayUrlInfo('', 0, 'svip_privilege').then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  getPayUrl() {
    OpenApiSdk.openApi?.vipApi.getPayUrl('', 0).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  getCheckoutUrl() {
    OpenApiSdk.openApi?.vipApi.getCheckoutUrl('demoCheckoutOrderId', 208, 0).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCashierGears() {
    OpenApiSdk.openApi?.vipApi.fetchCashierGears().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCashierPayUrl() {
    const req = new CashierCreateOrderParams()
    req.offerId = 'car_cjhy_1158759'
    req.totalAmount = 4000
    req.cOrder = new Date().getTime().toString()

    const item = new CashierCreateOrderItem()
    item.productId = '1201653225949891'
    item.skuId = '2201652262293890'
    item.quantity = 1

    req.items.push(item)

    OpenApiSdk.openApi?.vipApi.fetchCashierPayUrl(req).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  pollCashierOrderStatus() {
    OpenApiSdk.openApi?.vipApi.pollCashierOrderStatus('2025122219586857080').then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  getVipGuideConfig() {
    const item1 = new VipGuideConfigItem();
    item1.guidePosition = 1;

    const item2 = new VipGuideConfigItem();
    item2.guidePosition = 4;

    const item3 = new VipGuideConfigItem();
    item3.guidePosition = 7;

    const requestParams: IVipGuideConfigItem[] = [item1, item2, item3];
    OpenApiSdk.openApi?.vipApi.getVipGuideConfig(requestParams).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  getUnionVipOrderList() {
    OpenApiSdk.openApi?.vipApi.getUnionVipOrderList(null, null, '', 30).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  //用户
  openFreeLimitedTimeAuth() {
    OpenApiSdk.openApi?.userApi.openFreeLimitedTimeAuth(6).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  canTryPlayDolbyQuality() {
    OpenApiSdk.openApi?.userApi.canTryPlayDolbyQuality().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  getFreeLimitedTimeProfitInfo() {
    OpenApiSdk.openApi?.userApi.getFreeLimitedTimeProfitInfo(7).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchPartnerMemberInformation() {
    OpenApiSdk.openApi?.userApi.fetchPartnerMemberInformation().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  canTryPlayGalaxyQuality() {
    OpenApiSdk.openApi?.userApi.canTryPlayGalaxyQuality().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  canTryPlayExcellentQuality() {
    OpenApiSdk.openApi?.userApi.canTryPlayExcellentQuality().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchUserInfo() {
    OpenApiSdk.openApi?.userApi.fetchUserInfo().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchGreenMemberInformation() {
    OpenApiSdk.openApi?.userApi.fetchGreenMemberInformation().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchIotMemberInformation() {
    OpenApiSdk.openApi?.userApi.fetchIotMemberInformation().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  updateThirdPartyAccount() {
    let partnerAppId = this.params[0] ?? ''
    let partnerAccessToken = this.params[1] ?? ''
    let partnerAccountId = this.params[2] ?? ''
    let forceBind = Boolean(this.params[3] ?? false)
    OpenApiSdk.openApi?.partnerLogin.updateThirdPartyAccount(partnerAppId, partnerAccessToken, partnerAccountId, forceBind).then((result) => {
      MLog.i('OpenApiLayout', '三方绑定响应' + JSON.stringify(result))
      this.displayText = JSON.stringify(result);
    })
  }

  deleteThirdPartyAccountBindState() {
    let partnerAppId = this.params[0] ?? ''
    let partnerAccessToken = this.params[1] ?? ''
    let partnerAccountId = this.params[2] ?? ''
    OpenApiSdk.openApi?.partnerLogin.deleteThirdPartyAccountBindState(partnerAppId, partnerAccessToken, partnerAccountId).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  queryThirdPartyAccountBindState() {
    let partnerAppId = this.params[0] ?? ''
    let partnerAccessToken = this.params[1] ?? ''
    let partnerAccountId = this.params[2] ?? ''
    OpenApiSdk.openApi?.partnerLogin.queryThirdPartyAccountBindState(partnerAppId, partnerAccessToken, partnerAccountId).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  thirdPartyLogin() {
    let partnerAppId = this.params[0] ?? ''
    let partnerAccessToken = this.params[1] ?? ''
    let partnerAccountId = this.params[2] ?? ''
    OpenApiSdk.openApi?.partnerLogin.thirdPartyAccountLogin(partnerAppId, partnerAccessToken, partnerAccountId).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchWeatherInfo() {
    OpenApiSdk.openApi?.weatherInfoApi.fetchWeatherInfo().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  getSearchResults(): string[] {
    if (!this.inputKey.trim()) {
      return this.apiMeans;
    } // 空搜索返回全部

    return this.apiMeans.filter(item =>
    item.toLowerCase().includes(this.inputKey.toLowerCase())
    );
  }

  // 推荐相关
  fetchSimilarSong() {
    let songId = Number(this.params[0] ?? 0)
    let mid = this.params[1]
    let strArray = this.params[2].split(',')
    let hasRecommendList: number[] = []
    strArray.forEach((str: string) => {
      hasRecommendList.push(Number(str))
    })
    OpenApiSdk.openApi?.recommendApi.fetchSimilarSong(songId, mid, hasRecommendList).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchHomepageRecommendationWithSongInfo() {
    let strTypes = this.params[0].split(',')
    let types: number[] = []
    strTypes.forEach((str: string) => {
      types.push(Number(str))
    })
    OpenApiSdk.openApi?.recommendApi.fetchHomepageRecommendationWithSongInfo(types).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchGuessLikeLongAudio() {
    OpenApiSdk.openApi?.recommendApi.fetchGuessLikeLongAudio().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchDailyRecommendSong() {
    let scene = Number(this.params[0] ?? 0)
    OpenApiSdk.openApi?.recommendApi.fetchDailyRecommendSong(scene).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchPersonalRecommendSong() {
    let scene = Number(this.params[0] ?? 0)
    OpenApiSdk.openApi?.recommendApi.fetchPersonalRecommendSong(scene).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchBannerConfig() {
    OpenApiSdk.openApi?.recommendApi.fetchBannerConfig().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchPersonalRecommendRequirement() {
    OpenApiSdk.openApi?.recommendApi.fetchPersonalRecommendRequirement().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  setPersonalRecommendRequirement() {
    let list: Array<RecommendProfileAdjustment> = []
    if (this.params[0].length > 0) {
      list = JsonUtil.fromString<RecommendProfileAdjustment[]>(this.params[0], {
        classKey: 'Array',
        genericTypes: [RecommendProfileAdjustment]
      }) ?? []
    }

    OpenApiSdk.openApi?.recommendApi.setPersonalRecommendRequirement(list).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  // 专区
  fetchHiresSectionByShelfTypes() {
    let strShelfTypes = this.params[0].split(',')
    let shelfTypes: number[] = []
    strShelfTypes.forEach((str: string) => {
      shelfTypes.push(Number(str))
    })
    OpenApiSdk.openApi?.operAreaApi.fetchHiresSectionByShelfTypes(shelfTypes).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchDolbySectionByShelfTypes() {
    let strShelfTypes = this.params[0].split(',')
    let shelfTypes: number[] = []
    strShelfTypes.forEach((str: string) => {
      shelfTypes.push(Number(str))
    })
    OpenApiSdk.openApi?.operAreaApi.fetchDolbySectionByShelfTypes(shelfTypes).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchGalaxySectionByShelfTypes() {
    let strShelfTypes = this.params[0].split(',')
    let shelfTypes: number[] = []
    strShelfTypes.forEach((str: string) => {
      shelfTypes.push(Number(str))
    })
    OpenApiSdk.openApi?.operAreaApi.fetchGalaxySectionByShelfTypes(shelfTypes).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchAreaSectionByShelfTypes() {
    let areaId = Number(this.params[0])
    let strShelfTypes = this.params[1].split(',')
    let shelfTypes: number[] = []
    strShelfTypes.forEach((str: string) => {
      shelfTypes.push(Number(str))
    })
    OpenApiSdk.openApi?.operAreaApi.fetchAreaSectionByShelfTypes(areaId, shelfTypes).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchShelfContent() {
    let shelfId = Number(this.params[0])
    let contentSize = Number(this.params[1])
    let lastContentId = this.params[2]
    let areaId = Number(this.params[3])
    OpenApiSdk.openApi?.operAreaApi.fetchShelfContent(shelfId, contentSize, lastContentId, areaId).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  // 专辑
  collectAlbum() {
    const isCollect = Boolean(this.params[0] ?? false)
    const albumIds = this.params[1]
    const albumIdList = this.splitByComma(albumIds).map(id => Number(id))
    OpenApiSdk.openApi?.albumApi.collectAlbum(isCollect, albumIdList).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchAlbumOfSinger() {
    let singerId = Number(this.params[0] ?? 0)
    let singerMid = this.params[1] ?? ''
    let page = Number(this.params[2] ?? 0)
    let count = Number(this.params[3] ?? 0)
    let sortType = Number(this.params[4] ?? 0)

    OpenApiSdk.openApi?.albumApi.fetchAlbumOfSinger(singerId, singerMid, page, count, sortType).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCollectedAlbum() {
    let start = Number(this.params[0] ?? 0)
    let size = Number(this.params[1] ?? 0)
    let type = Number(this.params[2] ?? 0)
    OpenApiSdk.openApi?.albumApi.fetchCollectedAlbum(start, size, type).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchAlbumDetail() {
    const albumId = Number(this.params[0] ?? 0)
    OpenApiSdk.openApi?.albumApi.fetchAlbumDetail(albumId).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchNewAlbumsByArea() {
    OpenApiSdk.openApi?.albumApi.fetchNewAlbumsByArea().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchNewAlbum() {
    let area = Number(this.params[0] ?? 0)
    let page = Number(this.params[1] ?? 0)
    let count = Number(this.params[2] ?? 0)
    let type = Number(this.params[3] ?? 0)
    OpenApiSdk.openApi?.albumApi.fetchNewAlbum(area, page, count, type).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchBuyRecord() {
    let tag = Number(this.params[0] ?? 0)
    let page = Number(this.params[1] ?? 0)
    OpenApiSdk.openApi?.albumApi.fetchBuyRecord(tag, page).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchSongOfAlbum() {
    const albumIdStr = (this.params[0] ?? '').trim()
    const albumId = albumIdStr.length > 0 ? Number(albumIdStr) : undefined

    const albumMidStr = (this.params[1] ?? '').trim()
    const albumMid = albumMidStr.length > 0 ? albumMidStr : undefined

    let page = Number(this.params[2] ?? 0)
    let count = Number(this.params[3] ?? 0)
    let orderType = Number(this.params[4] ?? 0)
    let orderBy = Number(this.params[5] ?? 0)

    const beginStr = (this.params[6] ?? '').trim()
    const begin = beginStr.length > 0 ? Number(beginStr) : undefined

    let beginSongId = Number(this.params[7] ?? 0)

    OpenApiSdk.openApi?.albumApi.fetchSongOfAlbum(albumId, albumMid, page, count, orderType, orderBy, begin, beginSongId).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchSongOf51Album() {
    const albumId = Number((this.params[0] ?? '0').trim())
    const begin = Number(this.params[1] ?? 0)
    const count = Number(this.params[2] ?? 20)

    OpenApiSdk.openApi?.albumApi.fetchSongOf51Album(albumId, begin, count).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  // 歌手
  fetchSongOfSinger() {
    const singerId = Number(this.params[0] ?? 0)
    const singerMid = this.params[1] ?? ''
    const page = Number(this.params[2] ?? 0)
    const count = Number(this.params[3] ?? 200)
    const orderType = Number(this.params[4] ?? 0)
    OpenApiSdk.openApi?.singerApi.fetchSongOfSinger(singerId, singerMid, page, count, orderType)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchSingerWiki() {
    const singerId = Number(this.params[0] ?? 0)
    const singerMid = this.params[1] ?? ''
    OpenApiSdk.openApi?.singerApi.fetchSingerWiki(singerId, singerMid)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchSingerFavState() {
    const singerId = Number(this.params[0] ?? 0)
    const singerMid = this.params[1] ?? ''
    OpenApiSdk.openApi?.singerApi.fetchSingerFavState(singerId, singerMid)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchSingerDetail() {
    const singerId = Number(this.params[0] ?? 0)
    const singerMid = this.params[1] ?? ''
    const page = Number(this.params[2] ?? 0)
    const count = Number(this.params[3] ?? 0)
    const sortType = Number(this.params[4] ?? 0)
    const needWiki = Boolean(this.params[5] ?? false)
    const needFavState = Boolean(this.params[6] ?? false)
    OpenApiSdk.openApi?.singerApi.fetchSingerDetail(singerId, singerMid, page, count, sortType, needWiki, needFavState)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchHotSingerList() {
    const area = Number(this.params[0] ?? 0)
    const sex = Number(this.params[1] ?? 0)
    const genre = Number(this.params[2] ?? 0)
    const bigResponse = Number(this.params[3] ?? 0)
    OpenApiSdk.openApi?.singerApi.fetchHotSingerList(area, sex, genre, bigResponse)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchHotSingerListWithRecommendSinger() {
    const area = Number(this.params[0] ?? 0)
    const sex = Number(this.params[1] ?? 0)
    const genre = Number(this.params[2] ?? 0)
    const bigResponse = Number(this.params[3] ?? 0)
    OpenApiSdk.openApi?.singerApi.fetchHotSingerListWithRecommendSinger(area, sex, genre, bigResponse)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchHotSingerListWithFilterByPage() {
    const query = this.params[0] ?? ''
    const area = Number(this.params[1] ?? 0)
    const sex = Number(this.params[2] ?? 0)
    const page = Number(this.params[3] ?? 0)
    const page_size = Number(this.params[4] ?? 0)
    OpenApiSdk.openApi?.singerApi.fetchHotSingerListWithFilterByPage(query, area, sex, page, page_size)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchOftenSingerList() {
    OpenApiSdk.openApi?.singerApi.fetchOftenSingerList()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchHotSingerListWithFilter() {
    const area = Number(this.params[0] ?? 0)
    const sex = Number(this.params[1] ?? 0)
    const genre = Number(this.params[2] ?? 0)
    const index = this.params[3] ?? ''
    const bigResponse = Number(this.params[4] ?? 0)
    OpenApiSdk.openApi?.singerApi.fetchHotSingerListWithFilter(area, sex, genre, index, bigResponse)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  collectSinger() {
    const isCollect = Boolean(this.params[0] ?? false)
    const singerIdList = this.params[1].split(',').map(Number)
    OpenApiSdk.openApi?.singerApi.collectSinger(isCollect, singerIdList)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchCollectedSinger() {
    const page = Number(this.params[0] ?? 0)
    const count = Number(this.params[1] ?? 0)
    OpenApiSdk.openApi?.singerApi.fetchCollectedSinger(page, count)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 歌单
  createFolderByName() {
    const folderName = this.params[0] ?? ''
    OpenApiSdk.openApi?.folderApi.createFolderByName(folderName)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getEditFolderTags() {
    OpenApiSdk.openApi?.folderApi.getEditFolderTags()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  createFolder() {
    const raw = (this.params[0] ?? '').trim()
    const param = JsonUtil.fromString<IEditFolderParam>(raw.length > 0 ? raw : '{}', EditFolderParam)
    if (param != null) {
      param.folderPicPath = this.imagePath
      OpenApiSdk.openApi?.folderApi.createFolder(param)
        .then((result) => {
          this.displayText = JSON.stringify(result)
        })
    }
  }

  editFolder() {
    const raw = (this.params[0] ?? '').trim()
    const param = JsonUtil.fromString<IEditFolderParam>(raw.length > 0 ? raw : '{}', EditFolderParam)
    if (param != null) {
      OpenApiSdk.openApi?.folderApi.editFolder(param)
        .then((result) => {
          this.displayText = JSON.stringify(result)
        })
    }
  }

  deleteFolder() {
    const folderIds = (this.params[0] ?? '').split(',').map(s => Number(s.trim())).filter(n => !Number.isNaN(n) && n > 0)
    OpenApiSdk.openApi?.folderApi.deleteFolder(folderIds)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchSongOfFolder() {
    const folderId = Number(this.params[0] ?? 0)
    const passBack = this.params[1] ?? ''
    const count = Number(this.params[2] ?? 0) || 200

    OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(folderId, passBack, count)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchSongOfMyLikeFolder() {
    const passBack = this.params[0] ?? ''
    const count = Number(this.params[1] ?? 0) || 300
    OpenApiSdk.openApi?.folderApi.fetchSongOfMyLikeFolder(passBack, count)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  unCollectFolder() {
    const folderIds = (this.params[0] ?? '').split(',').map(s => Number(s.trim())).filter(n => !Number.isNaN(n) && n > 0)
    OpenApiSdk.openApi?.folderApi.unCollectFolder(folderIds)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchPersonalFolder() {
    OpenApiSdk.openApi?.folderApi.fetchPersonalFolder()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchCollectedFolder() {
    OpenApiSdk.openApi?.folderApi.fetchCollectedFolder()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  collectFolder() {
    const folderId = Number(this.params[0] ?? 0)
    OpenApiSdk.openApi?.folderApi.collectFolder(folderId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  operSongOfMyLikeSongList() {
    const isAdd = Boolean(this.params[0] ?? false)
    const songIds = [Number(this.params[1])]
    const songMids = this.params[2] ? this.params[2].split(',') : []
    OpenApiSdk.openApi?.folderApi.operSongOfMyLikeSongList(isAdd, songIds, songMids)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  addSongToFolderByIds() {
    const folderId = Number(this.params[0] ?? 0)
    const songIds = this.params[1] ? this.params[1].split(',').map(Number) : []
    const songMids = this.params[2] ? this.params[2].split(',') : []
    OpenApiSdk.openApi?.folderApi.addSongToFolderByIds(folderId, songIds, songMids)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  deleteSongFromFolder() {
    const folderId = Number(this.params[0] ?? 0)
    const songIds = this.params[1] ? this.params[1].split(',').map(Number) : []
    const songMids = this.params[2] ? this.params[2].split(',') : []
    OpenApiSdk.openApi?.folderApi.deleteSongFromFolder(folderId, songIds, songMids)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 无权限访问
  fetchHotCategoryOfFolder() {
    OpenApiSdk.openApi?.folderApi.fetchHotCategoryOfFolder()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchCategoryOfFolder() {
    OpenApiSdk.openApi?.folderApi.fetchCategoryOfFolder()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchCategoryOfSongListScene() {
    OpenApiSdk.openApi?.folderApi.fetchCategoryOfSongListScene()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchGetAiSongList() {
    OpenApiSdk.openApi?.folderApi.fetchGetAiSongList()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchAllTypeAiSongList() {
    const size = Number(this.params[0] ?? 0)
    const page = Number(this.params[1] ?? 0)
    OpenApiSdk.openApi?.folderApi.fetchAllTypeAiSongList(size, page)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchFolderListByCategory() {
    const categoryIdList: number[] = []
    if (this.params[0]) {
      categoryIdList.push(Number(this.params[0]))
    }
    if (this.params[1]) {
      categoryIdList.push(Number(this.params[1]))
    }

    const page = Number(this.params[2] ?? 0)
    const count = Number(this.params[3] ?? 0)

    OpenApiSdk.openApi?.folderApi.fetchFolderListByCategory(categoryIdList, page, count)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchFolderDetail() {
    const folderId = this.params[0] ?? ''
    OpenApiSdk.openApi?.folderApi.fetchFolderDetail(Number(folderId))
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchCustomSongListSquare() {
    OpenApiSdk.openApi?.folderApi.fetchCustomSongListSquare()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchCustomSceneSongList() {
    const itemId = "1"
    const itemType = 6
    const scene = "快乐"
    const page = 0
    const count = 20
    OpenApiSdk.openApi?.folderApi.fetchCustomSceneSongList(itemId, itemType, scene, page, count)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  reportCustomScenePlay() {
    const itemId = '1'
    const songId = '314818717'
    OpenApiSdk.openApi?.folderApi.reportCustomScenePlay(itemId, songId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 需配置车展白名单歌曲
  fetchSongOfAutoShow() {
    OpenApiSdk.openApi?.folderApi.fetchSongOfAutoShow()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 排行榜
  fetchSongOfRank() {
    const rankId = Number(this.params[0] ?? 0)
    const page = Number(this.params[1] ?? 0)
    const count = Number(this.params[2] ?? 0)
    OpenApiSdk.openApi?.rankApi.fetchSongOfRank(rankId, page, count)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchRankDetail() {
    const rankId = Number(this.params[0] ?? 0)
    const page = Number(this.params[1] ?? 0)
    const count = Number(this.params[2] ?? 0)
    OpenApiSdk.openApi?.rankApi.fetchRankDetail(rankId, page, count)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchAllRankGroup() {
    OpenApiSdk.openApi?.rankApi.fetchAllRankGroup()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  //歌词
  fetchAllLyric() {
    OpenApiSdk.openApi?.lyricApi.fetchAllLyric(Number(this.params[0]), this.params[1]).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchLyricImages() {
    OpenApiSdk.openApi?.lyricApi.fetchLyricImages(Number(this.params[0]), this.params[1]).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchLyricEffectAndMirInfo() {
    OpenApiSdk.openApi?.lyricApi.fetchLyricEffectAndMirInfo(this.params[0], Number(this.params[1]), this.params[2], this.params[3], Number(this.params[4]), this.params[5]).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  search() {
    let keyword = '周杰伦'
    let page = 0
    let num = 20
    OpenApiSdk.openApi?.searchApi.searchMV(keyword, page, num)
  }

  searchLyric() {
    let keyword = '周杰伦'
    let page = 0
    let num = 20
    OpenApiSdk.openApi?.searchApi.searchLyric(keyword, page, num)
  }

  searchSong() {
    let keyword = '周杰伦'
    let page = 0
    let num = 20
    OpenApiSdk.openApi?.searchApi.searchSong(keyword, page, num)
  }

  searchSmart() {
    const keyword = '周杰'
    OpenApiSdk.openApi?.searchApi.searchSmart(keyword)
  }

  searchSmartWithLight() {
    const keyword = '周杰'
    OpenApiSdk.openApi?.searchApi.searchSmartWithLight(keyword)
  }

  fetchHotKeyList() {
    let type = 1
    OpenApiSdk.openApi?.searchApi.fetchHotKeyList([type], 1)
  }

  voiceSearch() {
    let items = new Array<MusicSkillSlotItem>()
    let item = new MusicSkillSlotItem('Singer', '刘德华', 0)
    items.push(item)
    OpenApiSdk.openApi?.searchApi.voiceSearch('SearchSong', items, '我想听刘德华的歌', 168778, 50)
  }

  fetchStyleList() {
    OpenApiSdk.openApi?.appStyleApi.fetchStyleList(0, 20)
  }

  fetchStyleById() {
    let id = 1
    OpenApiSdk.openApi?.appStyleApi.fetchStyleById(id)
  }

  openFreeLimitedTimeByStyleId() {
    let id = '1'
    OpenApiSdk.openApi?.appStyleApi.openFreeLimitedTimeByStyleById(id)
  }

  openFreeLimitedTimeByStyleData() {
    let app: AppStyleData = new AppStyleData()
    app.id = 1
    OpenApiSdk.openApi?.appStyleApi.openFreeLimitedTimeByStyleByData(app)
  }

  //长音频
  fetchCategoryPageOfLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageOfLongAudio().then((result) => {
      this.displayText = JSON.stringify(result);
    })

  }

  fetchCategoryPageDetailOfLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageDetailOfLongAudio(42800344, 9, 2).then((result) => {
      this.displayText = JSON.stringify(result);
    })

  }

  fetchCategoryPageModuleContentLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCategoryPageModuleContentLongAudio(524, 1).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCategoryOfRecommendLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfRecommendLongAudio().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCategoryOfRankLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfRankLongAudio().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCategoryOfLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCategoryOfLongAudio().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCategoryFilterOfLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchCategoryFilterOfLongAudio([1203, 1238]).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchLikeListLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchLikeListLongAudio().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchRecentUpdateLongAudio() {
    OpenApiSdk.openApi?.longAudioApi.fetchRecentUpdateLongAudio().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchAlbumListOfRankLongAudioByCategory() {
    OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfRankLongAudioByCategory([1203, 1238]).then((result) => {
      this.displayText = JSON.stringify(result);
    })

  }

  fetchAlbumListOfLongAudioByCategory() {
    OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfLongAudioByCategory([1203, 1238], [1203, 1238], 0, 20, 0).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchAlbumListOfRecommendLongAudioByCategory() {
    OpenApiSdk.openApi?.longAudioApi.fetchAlbumListOfRecommendLongAudioByCategory([1203, 1238]).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchCollectedLongAudioSongList() {
    OpenApiSdk.openApi?.longAudioApi.fetchCollectedLongAudioSongList(1, 0).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  collectLongAudioSong() {
    OpenApiSdk.openApi?.longAudioApi.collectLongAudioSong(true, [1203], 1).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  //最近播放
  deleteRecentPlay() {
    OpenApiSdk.openApi?.recentPlayApi.deleteRecentPlay(1, ["1203"]).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchRecentPlayLongAudio() {
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayLongAudio(0).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchRecentPlaySong() {
    let updateTime = Number(this.params[0] ?? 0)
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlaySong(Number(updateTime)).then((result) => {
      this.displayText = JsonUtil.toString(result);
    })
  }

  fetchRecentPlayAlbum() {
    const now = new Date();
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayAlbum(Number(now)).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchRecentPlayFolder() {
    const now = new Date();
    OpenApiSdk.openApi?.recentPlayApi.fetchRecentPlayFolder(Number(now)).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  reportRecentPlayLongAudio() {
    const now = new Date();
    OpenApiSdk.openApi?.recentPlayApi.reportRecentPlayLongAudio("495429854", 1238).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  reportRecentPlay() {
    OpenApiSdk.openApi?.recentPlayApi.reportRecentPlay(495429854, 2).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  reportRecentPlayNew() {
    OpenApiSdk.openApi?.recentPlayApi.reportRecentPlayNew("495429854", 2).then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  fetchOtherPlatListeningList() {
    OpenApiSdk.openApi?.recentPlayApi.fetchOtherPlatListeningList().then((result) => {
      this.displayText = JSON.stringify(result);
    })
  }

  // 绿钻付费包
  createGreenOrder() {
    const matchId = 'test01'
    const openId = OpenApiSdk.loginApi?.getUserOpenId() ?? ''
    const num = 1
    OpenApiSdk.openApi?.greenOrderApi.createGreenOrder(matchId, openId, num)
      .then((result) => {
        this.orderId = result.data ?? ''
        this.displayText = JSON.stringify(result)
      })
  }

  queryGreenOrder() {
    const matchId = 'test01'
    const orderId = this.orderId
    OpenApiSdk.openApi?.greenOrderApi.queryGreenOrder(matchId, orderId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 免登录
  fetchFreeSongInfo() {
    const songId = 626007228
    const songToken = '294c0aa3ecd76bfd627e2b045bf2fa898eacf466816ceef3cb074808cce0c95f'
    OpenApiSdk.openApi?.FreeLoginApi.fetchFreeSongInfo(songId, songToken)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 音效配置
  fetchCommonConfig() {
    OpenApiSdk.openApi?.commonConfigApi.fetchCommonConfig()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchSoundEffectConfig() {
    OpenApiSdk.openApi?.commonConfigApi.fetchSoundEffectConfig()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  trySuperQualityV1() {
    const type = 14
    OpenApiSdk.openApi?.soundEffectConfigApi.trySuperQualityV1(type)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 下载相关
  getDownloadUrlInfo() {
    const mids = null
    const ids = [213053019]

    OpenApiSdk.downloadApi?.getDownloadUrlInfo(mids, ids)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  reportDownloadQuota() {
    const songId = 213053019
    const songRate = 4

    OpenApiSdk.downloadApi?.reportDownloadQuota(songId, songRate)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // ai陪伴
  operationAiListenTogetherTime() {
    const roleId = 3
    const cmd = '2'
    const useTimeBySec = 0
    OpenApiSdk.openApi?.aiAccompanyApi.operationAiListenTogetherTime(roleId, cmd, useTimeBySec)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getGlobalAiAccompanyRoleList() {
    OpenApiSdk.openApi?.aiAccompanyApi.getGlobalAiAccompanyRoleList()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getGlobalAiAccompanySongPlayUrl() {
    const songIdList = [213053019]
    OpenApiSdk.openApi?.aiAccompanyApi.getGlobalAiAccompanySongPlayUrl(songIdList)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  openGlobalAiAccompanyTry() {
    const roleId = 3
    OpenApiSdk.openApi?.aiAccompanyApi.openGlobalAiAccompanyTry(roleId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getAiAccompanyRoleList() {
    OpenApiSdk.openApi?.aiAccompanyApi.getAiAccompanyRoleList(null)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchAiListenTogetherRecSong() {
    const roleId = 3
    const scenes: Map<string, string> = new Map()
    scenes.set('情绪', '开心')
    const needTransitionIntro = false
    OpenApiSdk.openApi?.aiAccompanyApi.fetchAiListenTogetherRecSong(roleId, scenes, needTransitionIntro)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchMusicTherapyConfigList() {
    OpenApiSdk.openApi?.musicTherapyApi.fetchMusicTherapyConfigList()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchMusicTherapyTrack() {
    const id = 213053019
    OpenApiSdk.openApi?.musicTherapyApi.fetchMusicTherapyTrack(id)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // Session和CDN相关
  getSession() {
    OpenApiSdk.openApi?.sessionApi.getSession()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getAudioCdn() {
    const useHttps = true
    OpenApiSdk.openApi?.cdnApi.getAudioCdn(useHttps)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 免费听相关
  getAllFreeListenInfo() {
    OpenApiSdk.openApi?.freeListenApi.getAllFreeListenInfo()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 运营信息相关
  getOperationsInfo() {
    OpenApiSdk.openApi?.operationsInfoApi.getOperationsInfo()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  // 歌曲
  async fetchSongInfoLite() {
    const res = await OpenApiSdk.openApi?.folderApi.fetchSongOfFolder(9410365838, 0)
    const songList = res?.data ?? []
    OpenApiSdk.openApi?.songApi.fetchSongInfoLite(songList)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchMirInfo() {
    const ids = []
    OpenApiSdk.openApi?.songApi.fetchMirInfo(ids)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  initCommonConfig() {
    OpenApiSdk.openApi?.configRefreshManager.initManager()
  }

  // EdgeMedia
  getMediaInfo() {
    const ids = this.params[0] ? this.params[0].split(',') : ['vid1']
    OpenApiSdk.openApi?.edgeMediaApi.getMediaInfo(ids)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getMediaInfoWithToken() {
    const vids = this.params[0] ? this.params[0].split(',') : []
    const tokens = this.params[1] ? this.params[1].split(',') : []
    const map = new Map<string, string>()
    vids.forEach((vid, index) => {
      if (index < tokens.length) {
        map.set(vid, tokens[index])
      }
    })
    OpenApiSdk.openApi?.edgeMediaApi.getMediaInfoWithToken(map)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  operateMediaCollectStatus() {
    const operate = Number(this.params[0] ?? 0)
    const vid = this.params[1] ?? ''
    const media = new MediaResDetail(vid)
    media.action = new Action(undefined, 0xFFFFFFFF)
    OpenApiSdk.openApi?.edgeMediaApi.operateMediaCollectStatus([media], operate)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getCollectList() {
    const page = Number(this.params[0] ?? 0)
    const pageSize = Number(this.params[1] ?? 20)
    OpenApiSdk.openApi?.edgeMediaApi.getCollectList(page, pageSize)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getRecommendMVList() {
    const type = Number(this.params[0] ?? 0)
    const areaID = Number(this.params[1] ?? 0)
    const categoryType = Number(this.params[2] ?? 0)
    OpenApiSdk.openApi?.edgeMediaApi.getRecommendMVList(type, areaID, categoryType)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getContentArea() {
    const specialArea = Number(this.params[0] ?? 0)
    OpenApiSdk.openApi?.edgeMediaApi.getContentArea(specialArea)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getAreaDetail() {
    const specialArea = Number(this.params[0]) ?? 696
    const groupId = Number(this.params[1]) ?? 0
    const size = Number(this.params[2] ?? 4)

    // Construct a dummy MediaGroupRes with the ID
    const groupRes = new MediaGroupRes()
    groupRes.id = groupId

    OpenApiSdk.openApi?.edgeMediaApi.getAreaDetail(specialArea, groupRes, null, size)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getMvRank() {
    const rankType = Number(this.params[0] ?? 0)
    const area = Number(this.params[1] ?? 0)
    const abstract = Number(this.params[2] ?? 0) === 1
    OpenApiSdk.openApi?.edgeMediaApi.getMvRank(rankType, area, abstract)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  getKTVMVInfo() {
    const ids = this.params[0] ? this.params[0].split(',').map(Number) : []
    OpenApiSdk.openApi?.edgeMediaApi.getKTVMVInfo(ids)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  //播放器样式
  fetchPlayerStyleList() {
    let pageIndex = 0
    let pageSize = 30
    OpenApiSdk.openApi?.playerStyleApi.fetchPlayerStyleList(pageIndex, pageSize)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchDeskLyricDatalist() {
    let pageIndex = 0
    let pageSize = 30
    OpenApiSdk.openApi?.playerStyleApi.fetchDeskLyricDatalist(pageIndex, pageSize)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchPlayerImmersiveLyricList() {
    let pageIndex = 0
    let pageSize = 30
    OpenApiSdk.openApi?.playerStyleApi.fetchPlayerImmersiveLyricList(pageIndex, pageSize)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchLyricStyleById() {
    let styleId = 1
    OpenApiSdk.openApi?.playerStyleApi.fetchLyricStyleById(styleId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchDeskLyricStyleById() {
    let styleId = 1
    OpenApiSdk.openApi?.playerStyleApi.fetchDeskLyricStyleById(styleId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  fetchPlayerStyleById() {
    let styleId = 0
    OpenApiSdk.openApi?.playerStyleApi.fetchPlayerStyleById(styleId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  openFreeLimitedTimeByPlayStyleV1() {
    let styleId = '1'
    OpenApiSdk.openApi?.playerStyleApi.openFreeLimitedTimeByPlayStyleV1(styleId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  openFreeLimitedTime() {
    let bizType = 6
    let bizId = '0'
    OpenApiSdk.openApi?.playerStyleApi.openFreeLimitedTime(bizType, bizId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  openFreeLimitedTimeByPlayStyleV2() {
    const playerStyleData: IPlayerStyleData = new IPlayerStyleData();
    playerStyleData.id = 1001;
    playerStyleData.userProfit = new IUserProfit(86400, 1, 6)
    return OpenApiSdk.openApi?.playerStyleApi.openFreeLimitedTimeByPlayStyleV2(playerStyleData)
      .then((result) => {
        this.displayText = JSON.stringify(result);
      })
  }

  //TODO:车机业务相关
  fetchUploadPicQRCode() {
    OpenApiSdk.openApi?.playerStyleApi.fetchUploadPicQRCode()
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  //TODO:车机业务相关
  fetchLoopQRCodeStatus() {
    let qrCode = this.params[0] ?? "0"
    OpenApiSdk.openApi?.playerStyleApi.fetchLoopQRCodeStatus(qrCode)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  //TODO:车机业务相关
  fetchMaskDiagram() {
    let requestType = 0
    let businessTaskId = ''
    OpenApiSdk.openApi?.playerStyleApi.fetchMaskDiagram(requestType, businessTaskId)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  //TODO:车机业务相关
  uploadDiyPic() {
    let requestType = 0
    let code = ''
    let data = ''
    OpenApiSdk.openApi?.playerStyleApi.uploadDiyPic(requestType, code, data)
      .then((result) => {
        this.displayText = JSON.stringify(result)
      })
  }

  async fetchLiveInfo() {
    const resp = await OpenApiSdk.openApi?.edgeMediaApi.getLiveShowInfo(10000398)

    this.displayText = JSON.stringify(resp);
    MLog.i('OpenApiLayout', `[NetworkCheck] fetchLiveInfo：${JSON.stringify(resp)}`);
  }
}

@Builder
export function OpenApiLayoutBuilder(params: Object) {
  OpenApiLayout()
}

