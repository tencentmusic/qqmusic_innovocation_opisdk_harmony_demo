import { Route } from './Route'

// 页面 @Builder 导出（将在各页面改造完成后生效）
import { FolderListPageBuilder } from '../pages/folderlist/FolderListPage'
import { PlayerPageBuilder } from '../pages/player/PlayerPage'
import { PlayerNewPageBuilder } from '../pages/player/PlayerNewPage'
import { PlayListPageBuilder } from '../pages/player/PlayListPage'
import { OtherSettingPageBuilder } from '../pages/setting/OtherSettingPage'
import { DebugSettingPageBuilder } from '../pages/setting/DebugSettingPage'
import { AboutPageBuilder } from '../pages/setting/AboutPage'
import { DebuggingPageBuilder } from '../pages/DebuggingPage'
import { MusicTestPageBuilder } from '../debug/MusicTestPage'
import { LyricTestPageBuilder } from '../debug/LyricTestPage'
import { OpenApiLayoutBuilder } from '../pages/OpenApiPage'
import { OpiQRCodePageBuilder } from '../pages/OpiQRCodePage'
import { PartnerLoginPageBuilder } from '../pages/PartnerLoginPage'
import { MvRecommendPageBuilder } from '../view/home/mv/MvRecommendPage'
import { MvAreaPageBuilder } from '../view/home/mv/MvAreaPage'
import { MvAreaDetailPageBuilder } from '../view/home/mv/MvAreaDetailPage'
import { EdgeLivePlayerDemoPageBuilder } from '../pages/EdgeLivePlayerDemoPage'
import { CommonWebPageBuilder } from '../pages/CommonWebPage'
import { RankListPageBuilder } from '../pages/musichall/RankListPage'
import { RankDetailPageBuilder } from '../pages/musichall/RankDetailPage'
import { SingerListPageBuilder } from '../pages/musichall/SingerListPage'
import { SingerDetailPageBuilder } from '../pages/musichall/SingerDetailPage'
import { LongAudioRankPageBuilder } from '../pages/longaudio/LongAudioRankPage'
import { LongAudioCategoryPageBuilder } from '../pages/longaudio/LongAudioCategoryPage'
import { LongAudioModuleContentPageBuilder } from '../pages/longaudio/LongAudioModuleContentPage'
import { OpenApiDemoPageBuilder } from '../pages/setting/OpenApiDemoPage'
import { MVPlayerPageBuilder } from '../pages/mvplayer/MVPlayerPage'
import { MVDetailPageBuilder } from '../pages/mvplayer/MVDetailPage'
import { SongListPageBuilder } from '../pages/songlist/SongListPage'
import { SongProfilePageBuilder } from '../pages/songprofile/SongProfilePage'
import { AlbumListPageBuilder } from '../pages/longaudio/AlbumListPage'
import { LocalMatchPageBuilder } from '../pages/setting/LocalMatchPage'
import { SongCacheDemoPageBuilder } from '../pages/setting/SongCacheDemoPage'
import { AreaListPageBuilder } from '../pages/AreaListPage'
import { LyricPageBuilder } from '../pages/lyric/LyricPage'

/**
 * @Description: Demo 项目路由名称常量
 */
export namespace RouteName {
  export const FOLDER_LIST_PAGE = 'FolderListPage'
  export const PLAYER_PAGE = 'PlayerPage'
  export const PLAYER_NEW_PAGE = 'PlayerNewPage'
  export const PLAY_LIST_PAGE = 'PlayListPage'
  export const OTHER_SETTING_PAGE = 'OtherSettingPage'
  export const DEBUG_SETTING_PAGE = 'DebugSettingPage'
  export const ABOUT_PAGE = 'AboutPage'
  export const DEBUGGING_PAGE = 'DebuggingPage'
  export const MUSIC_TEST_PAGE = 'MusicTestPage'
  export const LYRIC_TEST_PAGE = 'LyricTestPage'
  export const OPEN_API_PAGE = 'OpenApiPage'
  export const OPI_QR_CODE_PAGE = 'OpiQRCodePage'
  export const PARTNER_LOGIN_PAGE = 'PartnerLoginPage'
  export const MV_RECOMMEND_PAGE = 'MvRecommendPage'
  export const MV_AREA_PAGE = 'MvAreaPage'
  export const MV_AREA_DETAIL_PAGE = 'MvAreaDetailPage'
  export const MV_PLAYER_PAGE = 'MVPlayerPage'
  export const MV_DETAIL_PAGE = 'MVDetailPage'
  export const EDGE_LIVE_PLAYER_DEMO_PAGE = 'EdgeLivePlayerDemoPage'
  export const COMMON_WEB_PAGE = 'CommonWebPage'
  export const RANK_LIST_PAGE = 'RankListPage'
  export const RANK_DETAIL_PAGE = 'RankDetailPage'
  export const SINGER_LIST_PAGE = 'SingerListPage'
  export const SINGER_DETAIL_PAGE = 'SingerDetailPage'
  export const LONG_AUDIO_RANK_PAGE = 'LongAudioRankPage'
  export const LONG_AUDIO_CATEGORY_PAGE = 'LongAudioCategoryPage'
  export const LONG_AUDIO_MODULE_CONTENT_PAGE = 'LongAudioModuleContentPage'
  export const OPEN_API_DEMO_PAGE = 'OpenApiDemoPage'
  export const SONG_LIST_PAGE = 'SongListPage'
  export const SONG_PROFILE_PAGE = 'SongProfilePage'
  export const ALBUM_LIST_PAGE = 'AlbumListPage'
  export const LOCAL_MATCH_PAGE = 'LocalMatchPage'
  export const SONG_CACHE_DEMO_PAGE = 'SongCacheDemoPage'
  export const AREA_LIST_PAGE = 'AreaListPageBuilder'
  export const LYRIC_PAGE = 'LyricPage'
}

/**
 * @Description: Demo 项目路由映射表
 */
export namespace RouteMap {
  export const ROUTE_MAP: Map<string, Route> = new Map<string, Route>([
    // 显示悬浮播放器的页面
    [RouteName.FOLDER_LIST_PAGE, new Route(RouteName.FOLDER_LIST_PAGE, wrapBuilder(FolderListPageBuilder), false, true)],
    [RouteName.RANK_DETAIL_PAGE, new Route(RouteName.RANK_DETAIL_PAGE, wrapBuilder(RankDetailPageBuilder), false, true)],
    [RouteName.SINGER_DETAIL_PAGE, new Route(RouteName.SINGER_DETAIL_PAGE, wrapBuilder(SingerDetailPageBuilder), false, true)],
    [RouteName.LONG_AUDIO_RANK_PAGE, new Route(RouteName.LONG_AUDIO_RANK_PAGE, wrapBuilder(LongAudioRankPageBuilder), false, true)],
    [RouteName.LONG_AUDIO_CATEGORY_PAGE, new Route(RouteName.LONG_AUDIO_CATEGORY_PAGE, wrapBuilder(LongAudioCategoryPageBuilder), false, true)],
    [RouteName.LONG_AUDIO_MODULE_CONTENT_PAGE, new Route(RouteName.LONG_AUDIO_MODULE_CONTENT_PAGE, wrapBuilder(LongAudioModuleContentPageBuilder), false, true)],
    [RouteName.SONG_LIST_PAGE, new Route(RouteName.SONG_LIST_PAGE, wrapBuilder(SongListPageBuilder), false, true)],
    [RouteName.SONG_PROFILE_PAGE, new Route(RouteName.SONG_PROFILE_PAGE, wrapBuilder(SongProfilePageBuilder), false, true)],
    [RouteName.ALBUM_LIST_PAGE, new Route(RouteName.ALBUM_LIST_PAGE, wrapBuilder(AlbumListPageBuilder), false, true)],
    [RouteName.RANK_LIST_PAGE, new Route(RouteName.RANK_LIST_PAGE, wrapBuilder(RankListPageBuilder), false, true)],
    [RouteName.SINGER_LIST_PAGE, new Route(RouteName.SINGER_LIST_PAGE, wrapBuilder(SingerListPageBuilder), false, true)],
    [RouteName.MV_AREA_DETAIL_PAGE, new Route(RouteName.MV_AREA_DETAIL_PAGE, wrapBuilder(MvAreaDetailPageBuilder), false, true)],
    [RouteName.AREA_LIST_PAGE, new Route(RouteName.AREA_LIST_PAGE, wrapBuilder(AreaListPageBuilder), false, true)],
    [RouteName.LYRIC_PAGE, new Route(RouteName.LYRIC_PAGE, wrapBuilder(LyricPageBuilder), false, true)],

    // 不显示悬浮播放器的页面
    [RouteName.PLAYER_PAGE, new Route(RouteName.PLAYER_PAGE, wrapBuilder(PlayerPageBuilder), true, false)],
    [RouteName.PLAYER_NEW_PAGE, new Route(RouteName.PLAYER_NEW_PAGE, wrapBuilder(PlayerNewPageBuilder), true, false)],
    [RouteName.PLAY_LIST_PAGE, new Route(RouteName.PLAY_LIST_PAGE, wrapBuilder(PlayListPageBuilder), true, false)],
    [RouteName.MV_PLAYER_PAGE, new Route(RouteName.MV_PLAYER_PAGE, wrapBuilder(MVPlayerPageBuilder), true, false)],
    [RouteName.MV_DETAIL_PAGE, new Route(RouteName.MV_DETAIL_PAGE, wrapBuilder(MVDetailPageBuilder), true, false)],
    [RouteName.OTHER_SETTING_PAGE, new Route(RouteName.OTHER_SETTING_PAGE, wrapBuilder(OtherSettingPageBuilder), true, false)],
    [RouteName.DEBUG_SETTING_PAGE, new Route(RouteName.DEBUG_SETTING_PAGE, wrapBuilder(DebugSettingPageBuilder), true, false)],
    [RouteName.ABOUT_PAGE, new Route(RouteName.ABOUT_PAGE, wrapBuilder(AboutPageBuilder), true, false)],
    [RouteName.DEBUGGING_PAGE, new Route(RouteName.DEBUGGING_PAGE, wrapBuilder(DebuggingPageBuilder), true, false)],
    [RouteName.MUSIC_TEST_PAGE, new Route(RouteName.MUSIC_TEST_PAGE, wrapBuilder(MusicTestPageBuilder), true, false)],
    [RouteName.LYRIC_TEST_PAGE, new Route(RouteName.LYRIC_TEST_PAGE, wrapBuilder(LyricTestPageBuilder), true, false)],
    [RouteName.OPEN_API_PAGE, new Route(RouteName.OPEN_API_PAGE, wrapBuilder(OpenApiLayoutBuilder), true, false)],
    [RouteName.OPI_QR_CODE_PAGE, new Route(RouteName.OPI_QR_CODE_PAGE, wrapBuilder(OpiQRCodePageBuilder), true, false)],
    [RouteName.PARTNER_LOGIN_PAGE, new Route(RouteName.PARTNER_LOGIN_PAGE, wrapBuilder(PartnerLoginPageBuilder), true, false)],
    [RouteName.EDGE_LIVE_PLAYER_DEMO_PAGE, new Route(RouteName.EDGE_LIVE_PLAYER_DEMO_PAGE, wrapBuilder(EdgeLivePlayerDemoPageBuilder), true, false)],
    [RouteName.COMMON_WEB_PAGE, new Route(RouteName.COMMON_WEB_PAGE, wrapBuilder(CommonWebPageBuilder), true, false)],
    [RouteName.OPEN_API_DEMO_PAGE, new Route(RouteName.OPEN_API_DEMO_PAGE, wrapBuilder(OpenApiDemoPageBuilder), true, false)],
    [RouteName.LOCAL_MATCH_PAGE, new Route(RouteName.LOCAL_MATCH_PAGE, wrapBuilder(LocalMatchPageBuilder), true, false)],
    [RouteName.SONG_CACHE_DEMO_PAGE, new Route(RouteName.SONG_CACHE_DEMO_PAGE, wrapBuilder(SongCacheDemoPageBuilder), true, false)],
    [RouteName.MV_RECOMMEND_PAGE, new Route(RouteName.MV_RECOMMEND_PAGE, wrapBuilder(MvRecommendPageBuilder), false, false)],
    [RouteName.MV_AREA_PAGE, new Route(RouteName.MV_AREA_PAGE, wrapBuilder(MvAreaPageBuilder), false, false)],
  ])
}
