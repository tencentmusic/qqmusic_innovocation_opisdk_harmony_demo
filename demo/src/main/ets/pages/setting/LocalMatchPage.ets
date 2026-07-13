/**
 * LocalMatchPage - 对应 Android LocalMatchActivity.kt / SongMatchDebugScreen
 *
 * 提供本地歌曲匹配调试功能：
 * - 手动输入 ID3 信息（歌曲名、歌手名、专辑名）进行匹配
 * - 选择音频文件进行音频指纹匹配
 * - 显示匹配结果
 */
import { LocalMatchViewModel, MatchResult } from '../../viewmodel/setting/LocalMatchViewModel';
import { IMatchLocalSongInfo } from '@qqmusic/opisdk-entity';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ISongInfo } from '@qqmusic/opisdk-qmutils';

@ComponentV2
export struct LocalMatchPage {
  @Local viewModel: LocalMatchViewModel = new LocalMatchViewModel()

  // 手动输入状态
  @Local songName: string = ''
  @Local singer: string = ''
  @Local album: string = ''

  // 文件选择器状态 - 防多次点击
  @Local isPickingFile: boolean = false

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          // ========== 输入区域 ==========
          this.buildInputSection()

          // ========== 输出区域 ==========
          this.buildOutputSection()
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
    .title('本地歌曲匹配调试')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 输入区域 - 对应 Android InputSection
   */
  @Builder
  buildInputSection() {
    Column() {
      Text('输入区域')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ bottom: 12 })

      // 手动输入模式
      this.buildManualInputSection()

      Divider()
        .margin({ top: 16, bottom: 16 })

      // 文件选择模式
      this.buildFileSelectionSection()
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  /**
   * 手动输入 ID3 信息区域 - 对应 Android ManualInputSection
   */
  @Builder
  buildManualInputSection() {
    Column() {
      Text('手动输入 ID3 信息')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ bottom: 8 })

      TextInput({ text: this.songName, placeholder: '歌曲名称' })
        .fontSize(14)
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        .margin({ bottom: 8 })
        .onChange((value: string) => {
          this.songName = value
        })

      TextInput({ text: this.singer, placeholder: '歌手名称' })
        .fontSize(14)
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        .margin({ bottom: 8 })
        .onChange((value: string) => {
          this.singer = value
        })

      TextInput({ text: this.album, placeholder: '专辑名称' })
        .fontSize(14)
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        .margin({ bottom: 8 })
        .onChange((value: string) => {
          this.album = value
        })

      Button('开始匹配')
        .fontSize(15)
        .width('100%')
        .height(40)
        .backgroundColor(this.songName.trim().length > 0 ? '#007AFF' : '#CCCCCC')
        .borderRadius(8)
        .fontColor(Color.White)
        .enabled(this.songName.trim().length > 0)
        .onClick(() => {
          this.viewModel.matchByManualInput(
            this.songName.trim(),
            this.singer.trim(),
            this.album.trim()
          )
        })
    }
    .width('100%')
  }

  /**
   * 文件选择区域 - 对应 Android FileSelectionSection
   */
  @Builder
  buildFileSelectionSection() {
    Column() {
      Text('文件选择')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ bottom: 8 })

      Button(this.isPickingFile ? '正在打开文件选择器...' : '选择音频文件')
        .fontSize(15)
        .width('100%')
        .height(40)
        .backgroundColor(this.isPickingFile ? '#999999' : '#34C759')
        .borderRadius(8)
        .fontColor(Color.White)
        .enabled(!this.isPickingFile)
        .onClick(() => {
          this.selectAudioFile()
        })
    }
    .width('100%')
  }

  /**
   * 输出区域 - 对应 Android OutputSection
   */
  @Builder
  buildOutputSection() {
    Column() {
      Text('匹配结果')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ bottom: 12 })

      if (this.viewModel.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#007AFF')
          Text('正在匹配...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.viewModel.matchResults.length === 0) {
        // 空状态
        Column() {
          Text('暂无匹配结果')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .height(80)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 结果列表
        ForEach(this.viewModel.matchResults, (result: MatchResult, index: number) => {
          this.buildMatchResultItem(result)
        }, (result: MatchResult, index: number) => `${result.timestamp}_${index}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  /**
   * 匹配结果单项 - 对应 Android MatchResultItem
   */
  @Builder
  buildMatchResultItem(result: MatchResult) {
    Column() {
      // 状态标题
      Row() {
        Text(result.isSuccess ? '✅ 匹配成功' : '❌ 匹配失败')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(result.isSuccess ? '#34C759' : '#FF3B30')
      }
      .width('100%')
      .padding({ bottom: 4 })

      // 输入信息
      Text(`输入: ${result.inputInfo}`)
        .fontSize(12)
        .fontColor('#666666')
        .width('100%')
        .fontFamily('monospace')
        .padding({ bottom: 4 })
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(3)

      if (result.isSuccess) {
        // 匹配成功 - 显示匹配到的歌曲信息
        if (result.matchedSong) {
          Text(`匹配到: ${this.formatMatchedSong(result.matchedSong)}`)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
            .fontFamily('monospace')
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(5)
        } else if (result.matchedSongByFingerprint) {
          Text(`匹配到: ${this.formatSongInfo(result.matchedSongByFingerprint)}`)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
            .fontFamily('monospace')
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(5)
        }
      } else {
        // 匹配失败 - 显示错误信息
        Text(`错误: ${result.errorMessage ?? '未知错误'}`)
          .fontSize(12)
          .fontColor('#FF3B30')
          .width('100%')
          .fontFamily('monospace')
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(5)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(result.isSuccess ? '#F0FFF4' : '#FFF0F0')
    .borderRadius(8)
  }

  /**
   * 格式化匹配歌曲信息
   */
  private formatMatchedSong(matched: IMatchLocalSongInfo): string {
    const parts: string[] = []
    if (matched.keyId) {
      parts.push(`keyId: ${matched.keyId}`)
    }
    if (matched.result) {
      parts.push(`result: ${matched.result}`)
    }
    if (matched.songInfo) {
      const song = JSON.parse(JSON.stringify(matched.songInfo)) as Record<string, Object>
      const songParts: string[] = []
      const songId = song['song_id'] as number
      if (songId && songId > 0) {
        songParts.push(`songId: ${songId}`)
      }
      const songName = song['song_name'] as string
      if (songName) {
        songParts.push(`songName: ${songName}`)
      }
      const singerName = song['singer_name'] as string
      if (singerName) {
        songParts.push(`singer: ${singerName}`)
      }
      const albumName = song['album_name'] as string
      if (albumName) {
        songParts.push(`album: ${albumName}`)
      }
      if (songParts.length > 0) {
        parts.push(`track: { ${songParts.join(', ')} }`)
      }
    }
    return parts.length > 0 ? parts.join(', ') : '无详细信息'
  }

  /**
   * 格式化歌曲信息（指纹匹配返回的 ISongInfo）
   */
  private formatSongInfo(song: ISongInfo): string {
    const songInfo = JSON.parse(JSON.stringify(song)) as Record<string, Object>
    const parts: string[] = []
    const songId = songInfo['song_id'] as number

    if (songId && songId > 0) {
      parts.push(`songId: ${songId}`)
    }
    const songName = songInfo['song_name'] as string
    if (songName) {
      parts.push(`songName: ${songName}`)
    }
    const singerName = songInfo['singer_name'] as string
    if (singerName) {
      parts.push(`singer: ${singerName}`)
    }
    const albumName = songInfo['album_name'] as string
    if (albumName) {
      parts.push(`album: ${albumName}`)
    }
    return parts.length > 0 ? parts.join(', ') : '无详细信息'
  }

  /**
   * 选择音频文件 - 使用鸿蒙 FilePicker
   * 包含防多次点击和超时兜底机制
   */
  private selectAudioFile(): void {
    if (this.isPickingFile) {
      return
    }
    this.isPickingFile = true

    // 超时兜底：15秒后自动重置状态，防止 picker 未正常回调导致按钮永久禁用
    const timeoutId = setTimeout(() => {
      if (this.isPickingFile) {
        this.isPickingFile = false
      }
    }, 10000)

    try {
      const documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      documentSelectOptions.fileSuffixFilters = ['mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a']

      const documentViewPicker = new picker.DocumentViewPicker()
      documentViewPicker.select(documentSelectOptions).then((documentSelectResult: string[]) => {
        clearTimeout(timeoutId)
        this.isPickingFile = false
        if (documentSelectResult && documentSelectResult.length > 0) {
          const uri = documentSelectResult[0]
          this.viewModel.matchByFileUri(uri)
        }
      }).catch((err: BusinessError) => {
        clearTimeout(timeoutId)
        this.isPickingFile = false
        console.error(`LocalMatchPage: selectAudioFile error: ${err.message}`)
      })
    } catch (error) {
      clearTimeout(timeoutId)
      this.isPickingFile = false
      console.error(`LocalMatchPage: selectAudioFile exception: ${(error as Error).message}`)
    }
  }
}

@Builder
export function LocalMatchPageBuilder(params?: Object) {
  LocalMatchPage()
}
