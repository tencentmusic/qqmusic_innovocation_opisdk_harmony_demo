/**
 * LocalMatchViewModel - 对应 Android SongMatchDebugViewModel
 *
 * 负责本地歌曲匹配调试的业务逻辑：
 * - 手动输入 ID3 信息进行匹配
 * - 通过文件 URI 进行音频指纹匹配
 */
import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { ISongID3Info, IMatchLocalSongInfo, OpenApiResponse } from '@qqmusic/opisdk-entity';
import { ISongInfo } from '@qqmusic/opisdk-qmutils'

/**
 * 匹配结果数据类 - 对应 Android MatchResult
 */
export class MatchResult {
  inputInfo: string
  isSuccess: boolean
  matchedSong: IMatchLocalSongInfo | null = null
  matchedSongByFingerprint: ISongInfo | null = null
  errorMessage: string | null = null
  timestamp: number = Date.now()

  constructor(
    inputInfo: string,
    isSuccess: boolean,
    matchedSong?: IMatchLocalSongInfo | null,
    matchedSongByFingerprint?: ISongInfo | null,
    errorMessage?: string | null
  ) {
    this.inputInfo = inputInfo
    this.isSuccess = isSuccess
    this.matchedSong = matchedSong ?? null
    this.matchedSongByFingerprint = matchedSongByFingerprint ?? null
    this.errorMessage = errorMessage ?? null
  }
}

@ObservedV2
export class LocalMatchViewModel {
  @Trace matchResults: MatchResult[] = []
  @Trace isLoading: boolean = false

  /**
   * 通过手动输入的 ID3 信息进行匹配
   * 对应 Android matchByManualInput
   */
  async matchByManualInput(songName: string, singer: string, album: string): Promise<void> {
    this.isLoading = true

    const id3Info: ISongID3Info = {
      song: songName,
      singer: singer,
      album: album
    }

    try {
      const response: OpenApiResponse<IMatchLocalSongInfo[]> =
        await OpenApiSdk.openApi?.localSong.matchSongsByID3([id3Info]) ??
        OpenApiResponse.createFromErrorMsg('localSong API 未初始化')

      const newResults: MatchResult[] = []
      newResults.push(new MatchResult(
        `手动输入: ${songName} - ${singer} - ${album}`,
        response.isSuccess(),
        response.data?.[0] ?? null,
        null,
        response.errorMsg
      ))
      this.matchResults = newResults
    } catch (error) {
      const newResults: MatchResult[] = []
      newResults.push(new MatchResult(
        `手动输入: ${songName} - ${singer} - ${album}`,
        false,
        null,
        null,
        `异常: ${(error as Error).message}`
      ))
      this.matchResults = newResults
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 通过文件 URI 进行音频指纹匹配
   * 对应 Android matchByFileUri
   */
  async matchByFileUri(uri: string): Promise<void> {
    this.isLoading = true

    try {
      const response: OpenApiResponse<ISongInfo[]> =
        await OpenApiSdk.openApi?.localSong.matchSongByFingerPrint(null, uri) ??
        OpenApiResponse.createFromErrorMsg('localSong API 未初始化')

      const newResults: MatchResult[] = []
      const firstMatch = response.data?.[0] ?? null
      newResults.push(new MatchResult(
        `选择文件: ${uri}`,
        response.isSuccess(),
        null,
        firstMatch,
        response.errorMsg
      ))
      this.matchResults = newResults
    } catch (error) {
      const newResults: MatchResult[] = []
      newResults.push(new MatchResult(
        `选择文件: ${uri}`,
        false,
        null,
        null,
        `异常: ${(error as Error).message}`
      ))
      this.matchResults = newResults
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 清空匹配结果
   */
  clearResults(): void {
    this.matchResults = []
  }
}
