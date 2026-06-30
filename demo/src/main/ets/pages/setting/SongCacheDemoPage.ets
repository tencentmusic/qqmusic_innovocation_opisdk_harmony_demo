import { OpenApiSdk, MLog } from '@qqmusic/opisdk-base';
import { ISongInfo } from '@qqmusic/opisdk-qmutils';
import { SingleItem } from '../../view/setting/SingleItem';
import { NavController } from '../../nav/NavController';
import { ToastUtil } from '../../utils/ToastUtil';

const TAG = 'SongCacheDemoPage';

@ComponentV2
export struct SongCacheDemoPage {
  @Local songCacheResult: string = '';
  @Local cachedSizeMb: number = 0;
  @Local cachedMVSizeMb: number = 0;
  @Local songCacheMaxSizeText: string = '200';
  @Local mvCacheMaxSizeText: string = '200';
  @Local cachedSongList: ISongInfo[] = [];
  @Local isLoading: boolean = false;
  /**
   * 判断字符串是否为合法正整数
   */
  private isStrInt(str: string): boolean {
    if (!str || str.trim().length === 0) {
      return false;
    }
    const num = Number(str);
    return Number.isInteger(num) && num > 0;
  }

  /**
   * 格式化字节大小显示
   */
  private formatSize(bytes: number): string {
    if (bytes <= 0) {
      return '0 B';
    }
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return `${size.toFixed(2)} ${units[unitIndex]}`;
  }

  /**
   * 获取歌曲缓存大小（MB）
   */
  private getSongCacheSize(): number {
    const cacheSize = OpenApiSdk.songCacheApi?.getCacheSize() ?? -1;
    MLog.d(TAG, `song cache: ${cacheSize} cacheSize=${cacheSize / 1024 / 1024} MB`);
    const sizeMb = cacheSize > 0 ? Math.floor(cacheSize / 1024 / 1024) : 0;
    ToastUtil.show(`歌曲缓存大小: ${this.formatSize(cacheSize)}`);
    return sizeMb;
  }

  /**
   * 获取 MV 缓存大小（MB）
   */
  private getMVCacheSize(): number {
    const cacheSize = OpenApiSdk.videoPlayerApi?.getCachedMvSize() ?? 0;
    MLog.d(TAG, `mv cache: ${cacheSize} cacheSize=${cacheSize / 1024 / 1024} MB`);
    const sizeMb = cacheSize > 0 ? Math.floor(cacheSize / 1024 / 1024) : 0;
    ToastUtil.show(`MV缓存大小: ${this.formatSize(cacheSize)}`);
    return sizeMb;
  }

  /**
   * 显示设置缓存上限的结果
   */
  private showSetCacheSizeRet(isSong: boolean, ret: number): void {
    if (ret === 0) {
      if (isSong) {
        this.cachedSizeMb = this.getSongCacheSize();
      } else {
        this.cachedMVSizeMb = this.getMVCacheSize();
      }
    } else {
      const errMap = new Map<number, string>();
      errMap.set(-1, 'sdk异常');
      errMap.set(-2, '参数不合法');
      errMap.set(-200, '播放进程未启动或已死亡');
      const errMsg = errMap.get(ret) ?? `未知错误(${ret})`;
      ToastUtil.show(`设置失败: ${errMsg}`);
    }
  }
  /**
   * 查询当前播放歌曲是否已缓存
   */
  private async checkCurrentSongCached(): Promise<void> {
    const songInfo = OpenApiSdk.playerApi?.getCurrentSongInfo();
    if (!songInfo) {
      this.songCacheResult = '当前无播放歌曲';
      ToastUtil.show('当前无播放歌曲');
      return;
    }
    try {
      const isCached = await OpenApiSdk.songCacheApi?.isSongCached(songInfo);
      if (isCached) {
        this.songCacheResult = `已缓存: ${songInfo.getSongId()}-《${songInfo.getSongName()}》`;
      } else {
        this.songCacheResult = `未缓存: ${songInfo.getSongId()}-《${songInfo.getSongName()}》`;
      }
      ToastUtil.show(this.songCacheResult);
    } catch (e) {
      this.songCacheResult = '查询失败';
      ToastUtil.show('查询缓存状态失败');
    }
  }

  /**
   * 清除所有缓存
   */
  private async clearAllCaches(): Promise<void> {
    this.isLoading = true;
    try {
      const result = await OpenApiSdk.songCacheApi?.clearAllCaches();
      if (result) {
        ToastUtil.show('缓存清除成功');
      } else {
        ToastUtil.show('缓存清除失败');
      }
      this.cachedSizeMb = this.getSongCacheSize();
    } catch (e) {
      ToastUtil.show('清除缓存异常');
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 获取已缓存歌曲列表
   */
  private async fetchCachedSongList(): Promise<void> {
    this.isLoading = true;
    try {
      const list = await OpenApiSdk.songCacheApi?.getCachedSongList();
      this.cachedSongList = list ?? [];
    } catch (e) {
      this.cachedSongList = [];
      ToastUtil.show('获取缓存列表失败');
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 简化的缓存歌曲列表项（不依赖 SongListViewModel Provider/Consumer）
   */
  @Builder
  buildCachedSongItem(song: ISongInfo, index: number) {
    Row({ space: 0 }) {
      // 序号
      Text(`${index + 1}`)
        .fontSize(16)
        .fontColor(index < 3 ? '#FF4D4F' : '#666666')
        .fontWeight(FontWeight.Bold)
        .width(28)
        .textAlign(TextAlign.Center)
        .margin({ right: 4 })

      // 封面小图
      Image(song.smallCoverUrl() ?? '')
        .width(45)
        .height(45)
        .objectFit(ImageFit.Cover)
        .borderRadius(4)
        .backgroundColor('#E0E0E0')
        .margin({ right: 5 })

      // 歌曲信息
      Column({ space: 2 }) {
        Text(song.getSongName() ?? '')
          .fontSize(12)
          .fontColor(song.canPlay() ? '#333333' : Color.Gray)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(song.getSingerName() ?? '未知')
          .fontSize(10)
          .fontColor(Color.Gray)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(50)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
    .borderWidth({ bottom: 0.5 })
    .borderColor('#F0F0F0')
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_back_dark'))
            .width(44).height(44)
            .onClick(() => NavController.getInstance().pop())
          Text('缓存测试页')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16 })
        .borderWidth({ bottom: 0.5 })
        .borderColor('#36000000')

        // 可滚动内容
        Scroll() {
          Column() {
            // ========== 查询当前播放歌曲是否已缓存 ==========
            SingleItem({
              title: '查询当前播放歌曲是否已缓存',
              item: '',
              onItemClick: () => {
                this.checkCurrentSongCached();
              }
            })

            if (this.songCacheResult.length > 0) {
              Text(this.songCacheResult)
                .fontSize(13)
                .fontColor('#333333')
                .width('100%')
                .padding({ left: 20, top: 4, bottom: 8 })
                .backgroundColor(Color.White)
            }

            // ========== 获取已缓存歌曲大小 ==========
            Row({ space: 0 }) {
              Button('获取已缓存歌曲大小')
                .fontSize(13)
                .height(36)
                .margin({ left: 16 })
                .onClick(() => {
                  this.cachedSizeMb = this.getSongCacheSize();
                })

              Text(`缓存大小：${this.cachedSizeMb} Mb`)
                .fontSize(13)
                .fontColor('#333333')
                .margin({ left: 12 })
            }
            .width('100%')
            .height(60)
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)

            // ========== 获取已缓存MV大小 ==========
            Row({ space: 0 }) {
              Button('获取已缓存MV大小')
                .fontSize(13)
                .height(36)
                .margin({ left: 16 })
                .onClick(() => {
                  this.cachedMVSizeMb = this.getMVCacheSize();
                })

              Text(`缓存大小：${this.cachedMVSizeMb} Mb`)
                .fontSize(13)
                .fontColor('#333333')
                .margin({ left: 12 })
            }
            .width('100%')
            .height(60)
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)

            // ========== 设置歌曲缓存上限 ==========
            Row({ space: 8 }) {
              TextInput({ text: this.songCacheMaxSizeText, placeholder: '输入歌曲缓存上限-Mb' })
                .type(InputType.Number)
                .fontSize(13)
                .height(36)
                .layoutWeight(1)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .margin({ left: 16 })
                .onChange((value: string) => {
                  this.songCacheMaxSizeText = value;
                })

              Button('设置')
                .fontSize(13)
                .height(36)
                .margin({ right: 16 })
                .onClick(() => {
                  if (this.isStrInt(this.songCacheMaxSizeText)) {
                    const ret = OpenApiSdk.songCacheApi?.setCacheMaxSize(Number(this.songCacheMaxSizeText)) ?? -1;
                    this.showSetCacheSizeRet(true, ret);
                  } else {
                    ToastUtil.show('请输入合法正整数');
                  }
                })
            }
            .width('100%')
            .height(60)
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)

            // ========== 设置MV缓存上限 ==========
            Row({ space: 8 }) {
              TextInput({ text: this.mvCacheMaxSizeText, placeholder: '输入MV缓存上限-Mb' })
                .type(InputType.Number)
                .fontSize(13)
                .height(36)
                .layoutWeight(1)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .margin({ left: 16 })
                .onChange((value: string) => {
                  this.mvCacheMaxSizeText = value;
                })

              Button('设置')
                .fontSize(13)
                .height(36)
                .margin({ right: 16 })
                .onClick(() => {
                  if (this.isStrInt(this.mvCacheMaxSizeText)) {
                    OpenApiSdk.videoPlayerApi?.setCacheSize(Number(this.mvCacheMaxSizeText));
                    this.showSetCacheSizeRet(false, 0);
                  } else {
                    ToastUtil.show('请输入合法正整数');
                  }
                })
            }
            .width('100%')
            .height(60)
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)

            // ========== 清除缓存 ==========
            Button('清除缓存')
              .fontSize(14)
              .width('90%')
              .height(40)
              .backgroundColor('#FA5151')
              .borderRadius(8)
              .fontColor(Color.White)
              .margin({ top: 12, left: '5%', right: '5%' })
              .onClick(() => {
                this.clearAllCaches();
              })

            // ========== 获取已缓存歌曲 ==========
            Row({ space: 0 }) {
              Button('获取已缓存歌曲')
                .fontSize(13)
                .height(36)
                .margin({ left: 16 })
                .onClick(() => {
                  this.fetchCachedSongList();
                })

              Text(`歌曲数量：${this.cachedSongList.length}首`)
                .fontSize(13)
                .fontColor('#333333')
                .margin({ left: 12 })
            }
            .width('100%')
            .height(60)
            .backgroundColor(Color.White)
            .alignItems(VerticalAlign.Center)

            // ========== 已缓存歌曲列表 ==========
            if (this.isLoading) {
              LoadingProgress()
                .width(40)
                .height(40)
                .margin({ top: 20 })
            } else if (this.cachedSongList.length === 0) {
              Text('暂无已缓存歌曲')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ top: 20, bottom: 30 })
            } else {
              // 渲染已缓存歌曲列表（简化版，不依赖 SongListViewModel Provider）
              ForEach(this.cachedSongList, (song: ISongInfo, index: number) => {
                this.buildCachedSongItem(song, index)
              }, (song: ISongInfo, index: number) => `${song.getSongId()}_${index}`)

              Blank().height(30)
            }
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}

@Builder
export function SongCacheDemoPageBuilder(params?: Object) {
  SongCacheDemoPage()
}
