import { ISongInfo } from '@qqmusic/opisdk-qmutils'

/**
 * 通用歌曲列表项宿接口
 */
export interface ISongListItemHost {

  /** 判断歌曲是否已收藏 */
  isSongCollected(song: ISongInfo): boolean

  /** 切换单首歌曲收藏状态 */
  toggleSongCollect(song: ISongInfo): void

  /** 判断歌曲是否为当前正在播放的歌曲 */
  isCurrentPlayingSong(song: ISongInfo): boolean

  /** 播放指定位置的歌曲，返回是否成功 */
  playSongAt(index: number, songList: ISongInfo[]): boolean

  /** 整行点击回调（由组件在 onClick 中调用） */
  onSongClick(song: ISongInfo, index: number, songList: ISongInfo[]): void

  /** 添加歌曲到下一曲 */
  addToNext(song: ISongInfo): void

  /** 添加歌曲到播放列表末尾 */
  appendToPlaylist(song: ISongInfo): void

  /** 是否处于多选编辑模式 */
  isEditorMode?(): boolean

  /** 判断歌曲是否被多选选中 */
  isSongSelected?(song: ISongInfo): boolean

  /** 切换单首歌曲多选状态 */
  toggleSongSelection?(song: ISongInfo): void

  /** 获取指定位置的序号颜色，默认前三名红色 */
  getIndexColor?(index: number): string

  /** 取消收藏回调（用于 API 面板从列表中移除歌曲） */
  onSongUncollect?: (songId: number) => void
}
