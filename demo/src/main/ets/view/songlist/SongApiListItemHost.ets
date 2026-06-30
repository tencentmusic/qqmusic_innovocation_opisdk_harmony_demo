import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import { ISongInfo } from '@qqmusic/opisdk-qmutils'
import { ISongListItemHost } from './ISongListItemHost'
import { ToastUtils } from '@qqmusic/opisdk-qmutils'
import { IFolder } from '@qqmusic/opisdk-entity'
import { DemoGlobal } from '../../utils/DemoGlobal'

const TAG = 'SongApiListItemHost'

/**
 * API 面板歌曲列表项宿主实现
 */
@ObservedV2
export class SongApiListItemHost implements ISongListItemHost {
  /** 歌曲列表引用 */
  private songListProvider: () => ISongInfo[]
  /** 已收藏歌曲ID集合（用于 personalAssets 模式） */
  @Trace public collectedIds: Set<number> = new Set()
  /** 取消收藏回调（用于 API 面板从列表中移除歌曲） */
  onSongUncollect?: (songId: number) => void

  constructor(songListProvider: () => ISongInfo[]) {
    this.songListProvider = songListProvider
  }

  /**
   * 初始化收藏状态（在组件 aboutToAppear 中调用）
   * 默认所有歌曲标记为已收藏
   */
  initCollectedState(): void {
    const newSet = new Set<number>()
    const list = this.songListProvider()
    for (let i = 0; i < list.length; i++) {
      // API 面板展示的歌曲默认都视为已收藏
      newSet.add(list[i].getSongId())
    }
    this.collectedIds = newSet
  }

  isSongCollected(song: ISongInfo): boolean {
    // API 模式下，歌曲在列表中即视为已收藏（实时反映列表变化）
    const enablePersonalAssets = DemoGlobal.isPersonalAssets;
    if (!enablePersonalAssets) {
      const list = this.songListProvider()
      return list.some(s => s.getSongId() === song.getSongId())
    }
    return this.collectedIds.has(song.getSongId())
  }

  toggleSongCollect(song: ISongInfo): void {
    const isCurrentlyCollected = this.isSongCollected(song)
    const targetState = !isCurrentlyCollected
    const enablePersonalAssets = DemoGlobal.isPersonalAssets;

    if (enablePersonalAssets) {
      // 资产模块路径
      OpenApiSdk.personalAssetsApi?.songFavApi.setCollectOrCancel(targetState, song).then((result) => {
        if (result) {
          const newSet = new Set(this.collectedIds)
          if (isCurrentlyCollected) {
            newSet.delete(song.getSongId())
          } else {
            newSet.add(song.getSongId())
          }
          this.collectedIds = newSet
        }
      })
    } else {
      // 非资产模块路径：直接操作"我喜欢"歌单
      this.toggleSongCollectViaApi(song, targetState, isCurrentlyCollected)
    }
  }

  /**
   * 非资产模块路径：通过 OpenApi 直接操作"我喜欢"歌单
   */
  private toggleSongCollectViaApi(song: ISongInfo, targetState: boolean, isCurrentlyCollected: boolean): void {
    OpenApiSdk.openApi?.folderApi.fetchPersonalFolder().then((folders) => {
      const folder = folders.data?.find((f: IFolder) => f.getName() === '我喜欢')
      if (folder) {
        const folderId = folder.getId()
        if (isCurrentlyCollected) {
          const idList = [song.getSongId()]
          const midList = [song.getSongMid() ?? '']
          const typeList = [song.getSongType().toString() ?? '']
          OpenApiSdk.openApi?.folderApi.deleteSongFromFolder(folderId, idList, midList, typeList)
            .then((resp) => {
              if (resp.isSuccess()) {
                const newSet = new Set(this.collectedIds)
                newSet.delete(song.getSongId())
                this.collectedIds = newSet
                // 通知外部从列表中移除
                if (this.onSongUncollect) {
                  this.onSongUncollect(song.getSongId())
                }
              } else {
                ToastUtils.showToastContent(`code=${resp.ret},msg=${resp.errorMsg}`)
                MLog.e(TAG, `del resp: code=${resp.ret},msg=${resp.errorMsg}`)
              }
            })
        } else {
          OpenApiSdk.openApi?.folderApi.addSongToFolder(folderId, [song])
            .then((resp) => {
              if (resp.isSuccess()) {
                const newSet = new Set(this.collectedIds)
                newSet.add(song.getSongId())
                this.collectedIds = newSet
              } else {
                ToastUtils.showToastContent(`code=${resp.ret},msg=${resp.errorMsg}`)
                MLog.e(TAG, `add resp: code=${resp.ret},msg=${resp.errorMsg}`)
              }
            })
        }
      }
    })
  }

  isCurrentPlayingSong(_song: ISongInfo): boolean {
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
