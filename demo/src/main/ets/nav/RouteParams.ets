/**
 * @Description: 路由参数类型定义
 * 用于 NavController.push 时的 params 参数，避免匿名对象字面量
 */
import { IMediaGroupRes, IMediaResDetail } from "@qqmusic/opisdk-entity"

/** 歌单列表页参数 */
export class FolderListPageParams {
  groupId: number
  labelId: number
  categoryName: string

  constructor(groupId: number, labelId: number, categoryName: string) {
    this.groupId = groupId
    this.labelId = labelId
    this.categoryName = categoryName
  }
}

/** MV 播放页参数 */
export class MvTestPageParams {
  mvId: string

  constructor(mvId: string) {
    this.mvId = mvId
  }
}

/** 通用键值参数（扫码登录、第三方登录等） */
export class KeyValueParams {
  KEY_DEV_NAME: string

  constructor(devName: string) {
    this.KEY_DEV_NAME = devName
  }
}

/** 统一Web页面路由参数 */
export class CommonWebPageParams {
  /** 要加载的 URL */
  webUrl: ResourceStr;
  /** 页面标题，不传则显示"加载中" */
  pageTitle: string
  /** 是否显示加载进度条，默认 true */
  showProgress: boolean

  constructor(webUrl: ResourceStr, pageTitle?: string, showProgress?: boolean) {
    this.webUrl = webUrl
    this.pageTitle = pageTitle ?? '加载中'
    this.showProgress = showProgress ?? true
  }
}

/** 排行榜详情页参数 */
export class RankDetailPageParams {
  rankId: number
  rankName: string

  constructor(rankId: number, rankName: string) {
    this.rankId = rankId
    this.rankName = rankName
  }
}

/** 长音频排行榜页参数 */
export class LongAudioRankPageParams {
  tag: string

  constructor(tag: string) {
    this.tag = tag
  }
}

/** 长音频分类页参数 */
export class LongAudioCategoryPageParams {
  tag: string
  categoryId: number
  subCategoryId: number
  /** jumpInfo 中的 intArrVal，用于匹配初始 Tab 索引（Shelf"更多"跳转场景） */
  intArrVal: number[] | null

  constructor(tag: string, categoryId: number, subCategoryId: number, intArrVal: number[] | null = null) {
    this.tag = tag
    this.categoryId = categoryId
    this.subCategoryId = subCategoryId
    this.intArrVal = intArrVal
  }
}

/** 长音频模块更多页参数 */
export class LongAudioModuleContentPageParams {
  moduleId: number
  shelfTitle: string

  constructor(moduleId: number, shelfTitle: string) {
    this.moduleId = moduleId
    this.shelfTitle = shelfTitle
  }
}

/** MV 播放页面参数 */
export class MVPlayerPageParams {
  mvVid: string
  mvResDetail: IMediaResDetail | null

  constructor(mvVid: string, mvResDetail: IMediaResDetail | null = null) {
    this.mvVid = mvVid
    this.mvResDetail = mvResDetail
  }
}

/** MV 详情页面参数 */
export class MVDetailPageParams {
  mvResDetail: IMediaResDetail | null

  constructor(mvResDetail: IMediaResDetail | null) {
    this.mvResDetail = mvResDetail
  }
}

/** MV 内容专区页面参数 */
export class MVContentPageParams {
  contentType: number

  constructor(contentType: number) {
    this.contentType = contentType
  }
}

/** MV 专区详情页参数（分组内容翻页） */
export class MvAreaDetailPageParams {
  specialArea: number
  groupRes: IMediaGroupRes

  constructor(specialArea: number, groupRes: IMediaGroupRes) {
    this.specialArea = specialArea
    this.groupRes = groupRes
  }
}

/** 专辑详情页参数 */
export class AlbumDetailPageParams {
  albumId: number
  albumName: string

  constructor(albumId: number, albumName: string) {
    this.albumId = albumId
    this.albumName = albumName
  }
}

/** 专辑列表页参数 */
export class AlbumListPageParams {
  albumId: number
  albumName: string

  constructor(albumId: number, albumName: string) {
    this.albumId = albumId
    this.albumName = albumName
  }
}

/** 歌曲详情页参数 */
export class SongProfilePageParams {
  songId: number
  songMid: string
  songName: string
  singerName: string
  albumName: string
  albumPicUrl: string
  songJson: string

  constructor(songId: number, songMid: string, songName: string, singerName: string,
    albumName: string, albumPicUrl: string, songJson: string) {
    this.songId = songId
    this.songMid = songMid
    this.songName = songName
    this.singerName = singerName
    this.albumName = albumName
    this.albumPicUrl = albumPicUrl
    this.songJson = songJson
  }
}

/** 歌曲列表页通用参数（支持专辑/歌单/歌手/榜单/场景分类/指定歌曲ID等多种场景） */
export class SongListPageParams {
  /** 播放列表类型，对应 MusicListType */
  playListType: number
  /** 列表ID（专辑ID 或 歌单ID 或 榜单ID 或 歌手ID） */
  listId: number
  /** 列表名称 */
  listName: string
  /** 列表Mid（歌手场景使用） */
  listMid: string | null
  /** 是否使用简化工具栏 */
  showSimpleToolbar: boolean
  /**
   * 指定歌曲ID列表（TYPE_SONG_LIST 场景使用）
   * 对应安卓 KEY_SONG / pagingSongIds
   */
  songIds: number[] | null
  /**
   * 场景分类ID列表，[groupId, subGroupId]（歌单场景分类使用）
   * 对应安卓 KEY_CATEGORY_IDS / pagingSongListScene
   */
  categoryIds: number[] | null
  /**
   * 来源标识（歌单场景使用）
   * 对应安卓 KEY_SOURCE
   */
  source: number | null

  constructor(playListType: number, listId: number, listName: string, showSimpleToolbar: boolean = false, listMid: string|null = null,songIds: number[] | null = null,
    categoryIds: number[] | null = null,
    source: number | null = null) {
    this.playListType = playListType
    this.listId = listId
    this.listName = listName
    this.showSimpleToolbar = showSimpleToolbar
    this.listMid = listMid
    this.songIds = songIds
    this.categoryIds = categoryIds
    this.source = source
  }
}

/** 歌手详情页参数 */
export class SingerDetailPageParams {
  singerId: number
  singerMid: string
  singerName: string

  constructor(singerId: number, singerMid: string, singerName: string) {
    this.singerId = singerId
    this.singerMid = singerMid
    this.singerName = singerName
  }
}


/**
 * AreaListPage 路由参数
 */
export class AreaListPageParams {
  areaId: number
  areaShelfType: number
  shelfId: number
  title: string

  constructor(areaId: number, areaShelfType: number, shelfId: number, title: string) {
    this.areaId = areaId
    this.areaShelfType = areaShelfType
    this.shelfId = shelfId
    this.title = title
  }
}