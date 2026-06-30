import { NavController } from '../../nav/NavController'
import { SongProfilePageParams } from '../../nav/RouteParams'
import { ISongInfo } from '@qqmusic/opisdk-qmutils'
import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base'
import { SongProfileCache } from './SongProfileCache'
import { AppUtil } from '../../utils/AppUtil'

const TAG = 'SongProfilePage'

/**
 * 歌曲详情页
 * 展示歌曲基础信息、标签、内容安全限制、歌曲权限、JSON原始数据
 */
@ComponentV2
export struct SongProfilePage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local song: ISongInfo | null = null
  @Local songJson: string = ''
  @Local isJsonExpanded: boolean = false
  // 从路由参数缓存的基础字段（防止找不到 ISongInfo 时也能展示）
  @Local cachedSongId: number = 0
  @Local cachedSongMid: string = ''
  @Local cachedSongName: string = ''
  @Local cachedSingerName: string = ''
  @Local cachedAlbumName: string = ''
  @Local cachedAlbumPicUrl: string = ''

  aboutToAppear(): void {
    const size = this.navController.navPathStack.size()
    if (size > 0) {
      const raw = this.navController.navPathStack.getParamByIndex(size - 1) as SongProfilePageParams
      if (raw) {
        // 缓存基础字段
        this.cachedSongId = raw.songId
        this.cachedSongMid = raw.songMid
        this.cachedSongName = raw.songName
        this.cachedSingerName = raw.singerName
        this.cachedAlbumName = raw.albumName
        this.cachedAlbumPicUrl = raw.albumPicUrl
        // 优先从全局缓存获取完整的 ISongInfo 对象（SongListItemView 点击详情时写入）
        const cachedSong = SongProfileCache.getInstance().getSong()
        if (cachedSong && cachedSong.getSongId() === raw.songId) {
          this.song = cachedSong
        } else {
          // 兜底：从播放器查找
          this.song = this.findSongById(raw.songId)
        }
        this.songJson = raw.songJson
        MLog.i(TAG, `aboutToAppear songId=${raw.songId}, name=${raw.songName}, foundSong=${this.song !== null}`)
      }
    }
  }

  private findSongById(songId: number): ISongInfo | null {
    // 尝试从当前播放列表查找
    const currentSong = OpenApiSdk.playerApi?.getCurrentSongInfo()
    if (currentSong && currentSong.getSongId() === songId) {
      return currentSong
    }
    // 尝试从播放列表中查找
    const playList = OpenApiSdk.playerApi?.getPlayList()
    if (playList) {
      for (let i = 0; i < playList.length; i++) {
        if (playList[i].getSongId() === songId) {
          return playList[i]
        }
      }
    }
    return null
  }

  /** 其他歌手文本 */
  private get otherSingersText(): string {
    if (!this.song) {
      return ''
    }
    const extra = this.song.getExtra()
    if (!extra) {
      return ''
    }
    try {
      // 通过 JSON 转换绕过 ArkTS 类型限制，安全访问动态字段
      const jsonStr = JSON.stringify(extra)
      const obj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>
      const otherSingerList: Object = obj['otherSingerList']
      if (otherSingerList !== undefined && Array.isArray(otherSingerList)) {
        const names: string[] = []
        for (let i = 0; i < otherSingerList.length; i++) {
          const s: Record<string, string> = otherSingerList[i] as Record<string, string>
          const name: string = s['name'] ?? s['title'] ?? ''
          if (name.length > 0) {
            names.push(name)
          }
        }
        if (names.length > 0) {
          return names.join(', ')
        }
      }
    } catch (e) {
      MLog.w(TAG, `parse otherSingers error: ${e}`)
    }
    return ''
  }

  /** 心情标签 */
  private get moodText(): string {
    return this.song?.getExtra()?.getMood() ?? 'null'
  }

  /** 是否AI作品 */
  private get isAiSongText(): string {
    return this.song?.isAISong() ? '是' : '否'
  }

  /** 纯人声限制 */
  private get pureVocalText(): string {
    if (!this.song) {
      return 'false'
    }
    // isForbidVocalAccomPureVocal: true 表示禁止纯人声
    return this.song.isForbidVocalAccomPureVocal() ? 'false' : 'true'
  }

  /** 纯伴奏限制 */
  private get pureAccomText(): string {
    if (!this.song) {
      return 'false'
    }
    // isForbidVocalAccomPureAccom: true 表示禁止纯伴奏
    return this.song.isForbidVocalAccomPureAccom() ? 'false' : 'true'
  }

  /** 内容安全限制码 */
  private get saCode(): string {
    const sa = this.song?.getSa()
    return sa !== undefined && sa !== null ? `${sa}` : ''
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        this.buildHeader()

        Scroll() {
          Column({ space: 0 }) {
            // 基础信息卡片
            this.buildBasicInfoCard()

            // 标签信息
            Column({ space: 0 }) {
              this.buildCardTitle('标签信息')
              this.buildInfoRow('心情', this.moodText)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 12 })

            // 内容安全限制
            Column({ space: 0 }) {
              this.buildCardTitle(`内容安全限制(${this.saCode})`)
              this.buildInfoRow('AI作品', this.isAiSongText)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 12 })

            // 歌曲权限
            Column({ space: 0 }) {
              this.buildCardTitle('歌曲权限')
              this.buildInfoRow('伴唱限制', `纯人声:${this.pureVocalText},纯伴奏:${this.pureAccomText}`)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 12 })

            // 歌曲JSON信息（可展开）
            this.buildJsonSection()

            // 底部留白
            Blank().height(40)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .padding({ bottom: 70 - AppUtil.bottomSafeArea })
    }
    .hideTitleBar(true)
  }
  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_back_dark'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.navController.pop()
        })

      Text('歌曲详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank().width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  buildBasicInfoCard() {
    Column({ space: 8 }) {
      // 标题 + 封面
      Row() {
        Text('基础信息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Image(this.song?.getAlbumPic300x300() ?? this.song?.getAlbumPic150x150() ?? this.song?.smallCoverUrl() ?? this.cachedAlbumPicUrl)
          .width(80)
          .height(80)
          .objectFit(ImageFit.Cover)
          .borderRadius(4)
          .backgroundColor('#E0E0E0')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 歌曲id
      this.buildInfoRow('歌曲id', `${this.song?.getSongId() ?? this.cachedSongId}`)

      // 歌曲mid
      this.buildInfoRow('歌曲mid', this.song?.getSongMid() ?? this.cachedSongMid)

      // 歌曲名
      this.buildInfoRow('歌曲名', this.song?.getSongName() ?? this.cachedSongName)

      // 歌手
      this.buildInfoRow('歌手', this.song?.getSingerName() ?? this.cachedSingerName)

      // 其他歌手
      this.buildInfoRow('其他歌手', this.otherSingersText)

      // 歌曲专辑
      this.buildInfoRow('歌曲专辑', this.song?.getAlbumName() ?? this.cachedAlbumName)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  @Builder
  buildCardTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
    }
    .width('100%')
    .padding({ top: 0, bottom: 8 })
  }

  @Builder
  buildInfoRow(label: string, value: string) {
    Row() {
      Text(label + ':')
        .fontSize(14)
        .fontColor('#666666')
        .width(80)

      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildJsonSection() {
    Column({ space: 0 }) {
      // 标题行（可点击展开/折叠）
      Row() {
        Text('歌曲JSON信息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(this.isJsonExpanded ? '▲' : '▼')
          .fontSize(16)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ top: 12, bottom: 8 })
      .onClick(() => {
        this.isJsonExpanded = !this.isJsonExpanded
      })

      // JSON内容
      if (this.isJsonExpanded && this.songJson.length > 0) {
        Text(this.formatJson(this.songJson))
          .fontSize(12)
          .fontColor('#333333')
          .width('100%')
          .padding(12)
          .backgroundColor('#F8F8F8')
          .borderRadius(4)
          .textAlign(TextAlign.Start)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ top: 4 })
  }

  /**
   * 简单格式化 JSON 字符串（缩进）
   */
  private formatJson(jsonStr: string): string {
    try {
      const obj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>
      return JSON.stringify(obj, null, 2)
    } catch (e) {
      return jsonStr
    }
  }
}

@Builder
export function SongProfilePageBuilder(params: Object) {
  SongProfilePage()
}
