import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { IAlbum, ISongInfo, IPlayParam, MusicListType, PlayError } from '@qqmusic/opisdk-entity'

const TAG = 'AlbumDetailViewModel'

@ObservedV2
export class AlbumDetailViewModel {
  @Trace public album: IAlbum | null = null
  @Trace public songList: ISongInfo[] = []
  @Trace public isLoading: boolean = false
  @Trace public isLoadingSongs: boolean = false
  @Trace public hasMore: boolean = true
  @Trace public albumName: string = ''
  @Trace public isAlbumCollected: boolean = false
  @Trace public isTogglingCollect: boolean = false
  public albumId: number = 0
  public page: number = 0
  public readonly pageSize: number = 30

  async fetchAlbumDetail(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      const resp = await OpenApiSdk.openApi?.albumApi.fetchAlbumDetail(this.albumId)
      if (resp && resp.isSuccess() && resp.data) {
        this.album = resp.data
        this.albumName = resp.data.getName()
        this.isAlbumCollected = resp.data.getFavState() === 1
        MLog.i(TAG, `fetchAlbumDetail success: ${this.albumName}, favState: ${resp.data.getFavState()}`)
      } else {
        MLog.w(TAG, `fetchAlbumDetail failed: ${resp?.errorMsg}`)
        this.album = null
      }
    } catch (e) {
      MLog.e(TAG, `fetchAlbumDetail error: ${JSON.stringify(e)}`)
      this.album = null
    } finally {
      this.isLoading = false
    }
  }

  async loadSongs(isLoadMore: boolean = false): Promise<void> {
    if (this.isLoadingSongs) {
      return
    }
    if (!isLoadMore) {
      this.page = 0
      this.songList = []
      this.hasMore = true
    } else if (!this.hasMore) {
      return
    }

    this.isLoadingSongs = true
    try {
      const resp = await OpenApiSdk.openApi?.albumApi.fetchSongOfAlbum(
        this.albumId,
        undefined,
        this.page,
        this.pageSize,
        0,
        0
      )
      if (resp && resp.isSuccess() && resp.data) {
        const list = resp.data.songList ?? []
        if (isLoadMore) {
          this.songList = this.songList.concat(list)
        } else {
          this.songList = list
        }
        this.hasMore = list.length >= this.pageSize
        this.page++
        MLog.i(TAG, `loadSongs success, page: ${this.page - 1}, count: ${list.length}`)
      } else {
        MLog.w(TAG, `loadSongs failed: ${resp?.errorMsg}`)
        this.hasMore = false
      }
    } catch (e) {
      MLog.e(TAG, `loadSongs error: ${JSON.stringify(e)}`)
      this.hasMore = false
    } finally {
      this.isLoadingSongs = false
    }
  }

  /**
   * 播放全部歌曲
   */
  playAllSongs(): void {
    if (this.songList.length === 0) {
      MLog.w(TAG, 'playAllSongs: songList is empty')
      return
    }
    const playParam: IPlayParam = {
      playListType: MusicListType.TYPE_ALBUM,
      playListTypeId: this.albumId,
      songList: this.songList,
      startPos: 0,
      startPlay: true
    }
    const result = OpenApiSdk.playerApi?.playSongs(playParam) ?? -1
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `playAllSongs failed, error: ${result}`)
    } else {
      MLog.i(TAG, `playAllSongs success, count: ${this.songList.length}`)
    }
  }

  /**
   * 播放指定索引的歌曲
   */
  playSongAt(index: number): void {
    if (index < 0 || index >= this.songList.length) {
      MLog.w(TAG, `playSongAt: invalid index ${index}`)
      return
    }
    const playParam: IPlayParam = {
      playListType: MusicListType.TYPE_ALBUM,
      playListTypeId: this.albumId,
      songList: this.songList,
      startPos: index,
      startPlay: true
    }
    const result = OpenApiSdk.playerApi?.playSongs(playParam) ?? -1
    if (result !== PlayError.PLAY_ERR_NONE) {
      MLog.w(TAG, `playSongAt failed, index: ${index}, error: ${result}`)
    } else {
      MLog.i(TAG, `playSongAt success, index: ${index}, song: ${this.songList[index].getSongName()}`)
    }
  }

  /**
   * 切换专辑收藏状态
   */
  async toggleAlbumCollect(): Promise<void> {
    if (this.isTogglingCollect || this.album === null) {
      return
    }
    this.isTogglingCollect = true
    try {
      const newCollectState = !this.isAlbumCollected
      const resp = await OpenApiSdk.openApi?.albumApi.collectAlbum(newCollectState, [this.albumId])
      if (resp && resp.isSuccess()) {
        this.isAlbumCollected = newCollectState
        MLog.i(TAG, `toggleAlbumCollect success, isCollected: ${this.isAlbumCollected}`)
      } else {
        MLog.w(TAG, `toggleAlbumCollect failed: ${resp?.errorMsg}`)
      }
    } catch (e) {
      MLog.e(TAG, `toggleAlbumCollect error: ${JSON.stringify(e)}`)
    } finally {
      this.isTogglingCollect = false
    }
  }

  /**
   * 切换单首歌曲收藏状态
   */
  async toggleSongCollect(song: ISongInfo): Promise<void> {
    try {
      const isCurrentlyCollected = OpenApiSdk.personalAssetsApi?.isSongCollected(song) ?? false
      const result = await OpenApiSdk.personalAssetsApi?.setSongCollected(song, !isCurrentlyCollected) ?? false
      MLog.i(TAG, `toggleSongCollect: ${song.getSongName()}, collected: ${!isCurrentlyCollected}, result: ${result}`)
    } catch (e) {
      MLog.e(TAG, `toggleSongCollect error: ${JSON.stringify(e)}`)
    }
  }

  /**
   * 判断歌曲是否已收藏
   */
  isSongCollected(song: ISongInfo): boolean {
    return OpenApiSdk.personalAssetsApi?.isSongCollected(song) ?? false
  }

  /**
   * 判断歌曲是否为当前正在播放的歌曲
   */
  isCurrentPlayingSong(song: ISongInfo): boolean {
    const currentSong = OpenApiSdk.playerApi?.getCurrentSongInfo()
    return currentSong !== null && currentSong !== undefined && currentSong.getSongId() === song.getSongId()
  }
}
