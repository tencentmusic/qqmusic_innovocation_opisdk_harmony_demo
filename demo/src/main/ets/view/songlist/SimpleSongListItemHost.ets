import { IObserver, MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import { LoadType, IFolder } from '@qqmusic/opisdk-entity'
import { ISongInfo } from '@qqmusic/opisdk-qmutils'
import { ISongListItemHost } from './ISongListItemHost'
import { DemoGlobal } from '../../utils/DemoGlobal'

const TAG = 'SimpleSongListItemHost'

/**
 * 通用歌曲列表项宿主实现
 */
@ObservedV2
export class SimpleSongListItemHost implements ISongListItemHost {
  /** 歌曲列表引用（外部传入，播放时使用） */
  private songListProvider: () => ISongInfo[]
  /** 已收藏歌曲ID集合 */
  @Trace private collectedIds: Set<string> = new Set()
  /** favApi 变化监听器 */
  private observer: IObserver<LoadType> | null = null
  /** 是否已注册 observer */
  private observerRegistered: boolean = false

  /**
   * @param songListProvider 返回当前歌曲列表的函数（用于播放时获取最新列表）
   */
  constructor(songListProvider: () => ISongInfo[]) {
    this.songListProvider = songListProvider
  }

  /**
   * 注册收藏状态监听（在组件 aboutToAppear 中调用）
   */
  registerObserver(): void {
    if (this.observerRegistered) {
      return
    }
    this.observer = {
      update: (_: LoadType) => {
        this.refreshCollectedState()
      }
    }
    OpenApiSdk.personalAssetsApi?.songFavApi.register(LoadType.SONG, this.observer)
    this.observerRegistered = true
    this.refreshCollectedState()
  }

  /**
   * 解注册收藏状态监听（在组件 aboutToDisappear 中调用）
   */
  unregisterObserver(): void {
    if (!this.observerRegistered || !this.observer) {
      return
    }
    OpenApiSdk.personalAssetsApi?.songFavApi.unregister(LoadType.SONG, this.observer)
    this.observerRegistered = false
    this.observer = null
  }

  /**
   * 刷新已收藏状态
   */
  private refreshCollectedState(): void {
    const newSet = new Set<string>()
    const list = this.songListProvider()
    for (let i = 0; i < list.length; i++) {
      const id = list[i].getSongId().toString()
      if (OpenApiSdk.personalAssetsApi?.songFavApi.isCollectedById(id) ?? false) {
        newSet.add(id)
      }
    }
    this.collectedIds = newSet
  }

  isSongCollected(song: ISongInfo): boolean {
    return this.collectedIds.has(song.getSongId().toString())
  }

  toggleSongCollect(song: ISongInfo): void {
    const isCurrentlyCollected = this.isSongCollected(song)
    const targetState = !isCurrentlyCollected
    const enablePersonalAssets = DemoGlobal.isPersonalAssets;

    if (enablePersonalAssets) {
      // 资产模块路径
      OpenApiSdk.personalAssetsApi?.songFavApi.setCollectOrCancel(targetState, song)
    } else {
      // 非资产模块路径：直接操作"我喜欢"歌单
      this.toggleSongCollectViaApi(song, targetState)
    }
  }

  /**
   * 非资产模块路径：通过 OpenApi 直接操作"我喜欢"歌单
   */
  private toggleSongCollectViaApi(song: ISongInfo, targetState: boolean): void {
    OpenApiSdk.openApi?.folderApi.fetchPersonalFolder().then((folders) => {
      const folder = folders.data?.find((f: IFolder) => f.getName() === '我喜欢')
      if (!folder) {
        MLog.w(TAG, 'toggleSongCollectViaApi: 我喜欢 folder not found')
        return
      }
      const folderId = folder.getId()
      if (targetState) {
        OpenApiSdk.openApi?.folderApi.addSongToFolder(folderId, [song])
      } else {
        const idList = [song.getSongId()]
        const midList: string[] = []
        const mid = song.getSongMid()
        if (mid) {
          midList.push(mid)
        }
        const typeList: string[] = []
        const st = song.getSongType()
        if (st !== null && st !== undefined) {
          typeList.push(st.toString())
        }
        OpenApiSdk.openApi?.folderApi.deleteSongFromFolder(
          folderId, idList, midList.length > 0 ? midList : undefined, typeList.length > 0 ? typeList : undefined
        )
      }
    })
  }

  isCurrentPlayingSong(_song: ISongInfo): boolean {
    // 简单场景暂不追踪当前播放歌曲
    return false
  }

  playSongAt(index: number, songList: ISongInfo[]): boolean {
    const list = songList.length > 0 ? songList : this.songListProvider()
    if (index < 0 || index >= list.length) {
      MLog.w(TAG, `playSongAt: invalid index ${index}`)
      return false
    }
    OpenApiSdk.playerApi?.playSongsWithPos(list, index)
    return true
  }

  onSongClick(song: ISongInfo, index: number, songList: ISongInfo[]): void {
    this.playSongAt(index, songList)
  }

  addToNext(song: ISongInfo): void {
    OpenApiSdk.playerApi?.addToNext(true, song)
  }

  appendToPlaylist(song: ISongInfo): void {
    OpenApiSdk.playerApi?.appendSongToPlaylist([song])
  }
}
