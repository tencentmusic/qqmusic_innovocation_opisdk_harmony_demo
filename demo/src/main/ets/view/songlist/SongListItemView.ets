import { ISinger, ISongInfo, PlayerEnums } from '@qqmusic/opisdk-qmutils'
import { SongInfo } from '@qqmusic/opisdk-openapi'
import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { ISongListItemHost } from './ISongListItemHost'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { MVPlayerPageParams, SongProfilePageParams } from '../../nav/RouteParams'
import { ToastUtil } from '../../utils/ToastUtil'
import { SongProfileCache } from '../../pages/songprofile/SongProfileCache'

const TAG = 'SongListItemView'

/**
 * 歌曲列表项组件
 * 包含：多选 checkbox、序号、封面、歌曲信息、标签行、MV 图标、收藏爱心、操作按钮列
 */
@ComponentV2
export struct SongListItemView {
  /** 宿主接口，提供收藏/播放/多选等行为 */
  @Param host: ISongListItemHost | null = null
  /** 外部传入的完整歌曲列表（用于播放时定位） */
  @Param songList: ISongInfo[] = []
  @Param song: ISongInfo | null = null
  @Param index: number = 0
  @Consumer('navController') navController: NavController = NavController.getInstance()

  /** 是否显示序号 */
  @Param showIndex: boolean = true
  /** 是否显示封面 */
  @Param showCover: boolean = true
  /** 是否显示音质标签行 */
  @Param showTagRow: boolean = true
  /** 是否显示 MV 入口 */
  @Param showMvEntry: boolean = true
  /** 是否显示收藏爱心 */
  @Param showCollectHeart: boolean = true
  /** 是否显示正在播放指示 */
  @Param showPlayingIndicator: boolean = true
  /** 是否显示操作按钮列（添加下一曲/添加末尾/详情） */
  @Param showActionButtons: boolean = true
  /** 封面尺寸 */
  @Param coverSize: number = 45
  /** 封面圆角 */
  @Param coverBorderRadius: number = 4
  /** 行高 */
  @Param rowHeight: number = 50

  /** 歌手文本 */
  private get singerText(): string {
    const mainSinger = this.song?.getSingerName() ?? '未知'
    if (!this.song || !(this.song instanceof SongInfo)) {
      return mainSinger
    }
    const otherSingerList: Array<ISinger> | null = this.song.getOtherSingerList()
    if (otherSingerList === null || otherSingerList.length === 0) {
      return mainSinger
    }
    const otherNames: string[] = []
    for (let i = 0; i < otherSingerList.length; i++) {
      const title = otherSingerList[i].getSingerTitle()
      const name = otherSingerList[i].getSingerName()
      const displayName = (title !== null && title.length > 0) ? title : name
      if (displayName.length > 0) {
        otherNames.push(displayName)
      }
    }
    if (otherNames.length === 0) {
      return mainSinger
    }
    const otherSingers = otherNames.join('/')
    const allSingers = `${mainSinger}/${otherSingers}`
    if (allSingers.length < 12) {
      return allSingers
    }
    if (mainSinger.length > 12 && otherSingers.length > 6) {
      return `${mainSinger.substring(0, 8)}/${otherSingers.substring(0, 6)}...`
    }
    return `${allSingers.substring(0, 11)}...`
  }

  /** 序号颜色：通过 host 获取，兜底前三名红色 */
  private get indexColor(): string {
    if (this.host?.getIndexColor) {
      return this.host.getIndexColor(this.index)
    }
    return this.index < 3 ? '#FF4D4F' : '#666666'
  }

  /** 序号字体大小：根据数字位数自适应，大数字用小字体 */
  private get indexFontSize(): number {
    const num = this.index + 1
    if (num >= 10000) {
      return 8
    } else if (num >= 1000) {
      return 10
    } else if (num >= 100) {
      return 12
    }
    return 16
  }

  /** 是否有 MV */
  private get hasMv(): boolean {
    const vid = this.song?.getMvVid()
    return vid !== null && vid !== undefined && vid.length > 0
  }

  /** 是否处于多选编辑模式 */
  private get isEditorMode(): boolean {
    return this.host?.isEditorMode?.() ?? false
  }

  /** 封面 URL：优先使用 smallCoverUrl，回退到 getAlbumPic */
  private get coverUrl(): string {
    return this.song?.smallCoverUrl() ?? this.song?.getAlbumPic() ?? ''
  }

  build() {
    Row({ space: 0 }) {
      // 多选 checkbox
      if (this.isEditorMode && this.song && this.host?.isSongSelected) {
        Toggle({ type: ToggleType.Checkbox, isOn: this.host.isSongSelected(this.song) })
          .onChange((value: boolean) => {
            if (this.song && this.host?.toggleSongSelection &&
              value !== this.host.isSongSelected?.(this.song)) {
              this.host.toggleSongSelection(this.song)
            }
          })
          .margin({ right: 4 })
      }

      // 序号：根据数字位数自适应字体大小
      if (this.showIndex) {
        Text(`${this.index + 1}`)
          .fontSize(this.indexFontSize)
          .fontColor(this.indexColor)
          .fontWeight(FontWeight.Bold)
          .width(28)
          .textAlign(TextAlign.Center)
          .margin({ right: 4 })
      }

      // 封面
      if (this.showCover) {
        Image(this.coverUrl)
          .width(this.coverSize)
          .height(this.coverSize)
          .objectFit(ImageFit.Cover)
          .borderRadius(this.coverBorderRadius)
          .backgroundColor('#E0E0E0')
          .margin({ right: 5 })
      }

      // 歌曲信息列
      Column({ space: 2 }) {
        // 歌曲名 - 不可播放置灰
        Text(this.song?.getSongName() ?? '')
          .fontSize(12)
          .fontColor(this.song?.canPlay() ? '#333333' : Color.Gray)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 歌手行
        Text(this.singerText)
          .fontSize(10)
          .fontColor(Color.Gray)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 标签行
        if (this.showTagRow) {
          this.buildTagRow()
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceAround)

      // MV 跳转图标
      if (this.showMvEntry && this.hasMv) {
        Image($r('app.media.mv_song_list_tip_icon'))
          .objectFit(ImageFit.Contain)
          .width(50)
          .height(35)
          .padding(10)
          .onClick(() => {
            const vid = this.song?.getMvVid()
            if (vid && vid.length > 0) {
              MLog.i(TAG, `click mv: ${this.song?.getSongName()}, vid: ${vid}`)
              const params = new MVPlayerPageParams(vid)
              this.navController.push(RouteName.MV_PLAYER_PAGE, params)
            }
          })
      }

      // 收藏爱心
      if (this.showCollectHeart && this.song && this.host) {
        Image(this.host.isSongCollected(this.song) ?
          $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
          .objectFit(ImageFit.Contain)
          .width(40)
          .height(40)
          .padding(10)
          .onClick(() => {
            if (this.song && this.host) {
              this.host.toggleSongCollect(this.song)
            }
          })
      }

      // 正在播放指示
      if (this.showPlayingIndicator && this.song && this.host?.isCurrentPlayingSong(this.song)) {
        Image($r('app.media.list_icon_playing'))
          .objectFit(ImageFit.Contain)
          .width(30)
          .height(30)
          .margin({ left: 8 })
      }

      // 操作按钮列
      if (this.showActionButtons && !this.isEditorMode) {
        this.buildActionButtons()
      }
    }
    .width('100%')
    .height(this.rowHeight)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
    .onClick(() => {
      if (this.isEditorMode) {
        return
      }
      if (this.song && this.host) {
        this.host.onSongClick(this.song, this.index, this.songList)
        // 播放成功后跳转播放页（由 host.onSongClick 内部调用 playSongAt）
        if (this.song.canPlay() && this.host.playSongAt(this.index, this.songList)) {
          this.navController.push(RouteName.PLAYER_PAGE)
        }
      }
    })
  }

  @Builder
  buildTagRow() {
    Row({ space: 2 }) {
      if (this.song?.isVip()) {
        Image($r('app.media.pay_icon_in_cell_old'))
          .objectFit(ImageFit.Contain)
          .width(18)
          .height(10)
      }

      if (this.song?.getLongAudioVip() === 1) {
        Image($r('app.media.ic_long_audio_vip_new'))
          .objectFit(ImageFit.Contain)
          .width(18)
          .height(10)
      }

      if (this.song?.isFreeLimit()) {
        Image($r('app.media.free_icon'))
          .objectFit(ImageFit.Contain)
          .width(18)
          .height(10)
      }

      if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.DOLBY) === true) {
        Image($r('app.media.action_icon_dolby_quality'))
          .width(26)
          .padding({ right: 1 })
      }

      if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.GALAXY) === true) {
        Image($r('app.media.action_icon_galaxy_quality'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.HIRES) === true) {
        Image($r('app.media.action_icon_quality_hires'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.EXCELLENT) === true) {
        Image($r('app.media.action_icon_excellent_quality'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.SQ) === true) {
        Image($r('app.media.action_icon_quality_sq'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.song?.hasQualityHQ()) {
        Image($r('app.media.hq_icon'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.STANDARD) === true) {
        Image($r('app.media.action_icon_quality_standard'))
          .width(26)
          .padding({ right: 1 })
      }

      if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.WANOS) === true) {
        Image($r('app.media.acion_icon_quality_wanos'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.VINYL) === true) {
        Image($r('app.media.action_icon_quality_vinyl'))
          .width(26)
          .padding({ right: 1 })
      } else if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.MASTER_TAPE) === true) {
        Image($r('app.media.master_tape_icon'))
          .width(26)
          .padding({ right: 1 })
      }

      if (this.song && OpenApiSdk.playerApi?.getSongHasQuality(this.song, PlayerEnums.Quality.VOCAL_ACCOMPANY) === true) {
        Image($r('app.media.action_icon_quality_va'))
          .width(26)
          .padding({ right: 1 })
      }

      if (this.song?.isAISong()) {
        Text('AI')
          .fontSize(8)
          .fontColor('#1FCF91')
          .padding({ left: 2, right: 2 })
      }

      if (this.song?.getExtra()?.getMood()) {
        Text(this.song?.getExtra()?.getMood() ?? '')
          .fontSize(8)
          .fontColor('#1FCF91')
          .padding({ left: 2, right: 2 })
      }
    }
  }

  @Builder
  buildActionButtons() {
    Column({ space: 0 }) {
      Text('添加下一曲')
        .fontSize(10)
        .fontColor('#1890FF')
        .height(18)
        .onClick(() => {
          if (this.song && this.host) {
            this.host.addToNext(this.song)
            ToastUtil.show('已添加到下一曲')
          }
        })

      Text('添加末尾')
        .fontSize(10)
        .fontColor('#52C41A')
        .height(18)
        .onClick(() => {
          if (this.song && this.host) {
            this.host.appendToPlaylist(this.song)
            ToastUtil.show('已添加到末尾')
          }
        })

      Text('详情')
        .fontSize(10)
        .fontColor('#722ED1')
        .height(18)
        .onClick(() => {
          MLog.i(TAG, `click detail: ${this.song?.getSongName()}, id: ${this.song?.getSongId()}`)
          if (this.song) {
            SongProfileCache.getInstance().setSong(this.song)
            const params = new SongProfilePageParams(
              this.song.getSongId(),
              this.song.getSongMid() ?? '',
              this.song.getSongName() ?? '',
              this.song.getSingerName() ?? '',
              this.song.getAlbumName() ?? '',
              this.song.getAlbumPic300x300() ?? this.song.smallCoverUrl() ?? '',
              this.song instanceof SongInfo ? JSON.stringify(this.song) : ''
            )
            this.navController.push(RouteName.SONG_PROFILE_PAGE, params)
          }
        })
    }
  }
}
