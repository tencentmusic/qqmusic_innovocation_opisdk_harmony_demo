import { ISongInfo } from '@qqmusic/opisdk-qmutils'

/**
 * 歌曲详情页全局缓存
 * 用于在 SongListItemView 和 SongProfilePage 之间传递完整的 ISongInfo 对象
 */
export class SongProfileCache {
  private static instance: SongProfileCache
  private _song: ISongInfo | null = null

  static getInstance(): SongProfileCache {
    if (!SongProfileCache.instance) {
      SongProfileCache.instance = new SongProfileCache()
    }
    return SongProfileCache.instance
  }

  setSong(song: ISongInfo): void {
    this._song = song
  }

  getSong(): ISongInfo | null {
    return this._song
  }

  clear(): void {
    this._song = null
  }
}
