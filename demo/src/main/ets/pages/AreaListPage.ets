import { MLog, OpenApiSdk } from "@qqmusic/opisdk-base"
import { AreaShelfType, IAreaShelfItem, IPlayParam } from "@qqmusic/opisdk-entity"
import { ISongInfo, MusicListType, PlayError } from "@qqmusic/opisdk-qmutils"
import { NavController } from "../nav/NavController"
import { RouteName } from "../nav/RouteMap"
import { AreaListPageParams, SongListPageParams } from "../nav/RouteParams"
import { ToastUtil } from "../utils/ToastUtil"
import { AreaListViewModel } from "../viewmodel/AreaListViewModel"


const TAG = 'AreaListPage'

@Builder
export function AreaListPageBuilder(args?: Object) {
  AreaListPage({ args: args })
}


@ComponentV2
export struct AreaListPage {
  @Param args: Object | undefined = undefined;
  /** 页面状态 */
  @Local private viewModel: AreaListViewModel = new AreaListViewModel()

  aboutToAppear(): void {
    const args = this.args as AreaListPageParams;
    if (args) {
      this.viewModel.init(args.areaId, args.areaShelfType, args.shelfId, args.title)
    }
    // 加载数据
    this.viewModel.refresh()
  }

  build() {
    NavDestination(){
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.ic_back_dark'))
            .width(24)
            .height(24)
            .margin({ left: 16 })
            .onClick(() => {
              NavController.getInstance().pop()
            })

          Text(this.viewModel.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 40 }) // 平衡返回按钮的宽度

          // 歌曲类型时显示"播放全部"按钮
          if (this.viewModel.areaShelfType === AreaShelfType.AreaShelfType_Song) {
            Text('播放全部')
              .fontSize(14)
              .fontColor('#007AFF')
              .margin({ right: 16 })
              .onClick(() => {
                this.playAllSongs()
              })
          }
        }
        .width('100%')
        .height(56)
        .alignItems(VerticalAlign.Center)

        // 分割线
        Divider()
          .width('100%')
          .height(1)
          .color('#E0E0E0')

        // 内容列表
        if (this.viewModel.isLoading && this.viewModel.shelfItems.length === 0) {
          // 首次加载中
          LoadingProgress()
            .width(40)
            .height(40)
            .margin({ top: 100 })
        } else if (this.viewModel.shelfItems.length === 0) {
          // 空状态
          Column() {
            Text('暂无内容')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          // 列表
          List() {
            LazyForEach(
              this.viewModel.dataSource,
              (item: IAreaShelfItem, index: number) => {
                ListItem() {
                  this.buildShelfItem(item, index)
                }
              },
              (item: IAreaShelfItem, index: number) => {
                return this.getItemKey(item, index)
              }
            )

            // 底部加载更多指示器
            if (this.viewModel.hasMore) {
              ListItem() {
                Row() {
                  if (this.viewModel.isLoading) {
                    LoadingProgress()
                      .width(20)
                      .height(20)
                      .margin({ right: 8 })
                    Text('加载中...')
                      .fontSize(14)
                      .fontColor('#999999')
                  } else {
                    Text('上拉加载更多')
                      .fontSize(14)
                      .fontColor('#999999')
                  }
                }
                .width('100%')
                .height(50)
                .justifyContent(FlexAlign.Center)
                // .onClick(() => {
                //   this.viewModel.loadMore()
                // })
              }
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ bottom: 60 })
          .scrollBar(BarState.Off)
          .onReachEnd(() => {
            // 滚动到底部时自动加载更多（移除手动点击，仅靠滚动触发）
            this.viewModel.loadMore()
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }

  /**
   * 根据模块类型构建不同的列表项
   */
  @Builder
  buildShelfItem(item: IAreaShelfItem, index: number): void {
    if (this.viewModel.areaShelfType === AreaShelfType.AreaShelfType_Album) {
      this.buildAlbumItem(item)
    } else if (this.viewModel.areaShelfType === AreaShelfType.AreaShelfType_Folder) {
      this.buildFolderItem(item)
    } else if (this.viewModel.areaShelfType === AreaShelfType.AreaShelfType_Song) {
      this.buildSongItem(item)
    }
  }

  /**
   * 构建专辑列表项
   */
  @Builder
  buildAlbumItem(item: IAreaShelfItem): void {
    Row() {
      // 专辑封面
      Image(item.getAlbum()?.getPic() ?? '' ?? '')
        .width(50)
        .height(50)
        .borderRadius(4)
        .margin({ left: 16, top: 8, bottom: 8 })

      // 专辑信息
      Column() {
        Text(item.getAlbum()?.getName() ?? '未知专辑')
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${item.getAlbum()?.getSongNum()?.toString() ?? '0'}首`)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      // 箭头
      Image($r('app.media.icon_right_arrow_placeholder'))
        .width(16)
        .height(16)
        .margin({ right: 16 })
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .height(66)
    .backgroundColor(Color.White)
    .onClick(() => {
      const album = item.getAlbum()
      if (album) {
        MLog.i(TAG, `Album clicked: name=${album.getName()}, id=${album.getId()}`)
        NavController.getInstance().push(
          RouteName.SONG_LIST_PAGE,
          new SongListPageParams(
            MusicListType.TYPE_ALBUM,
            Number(album.getId()),
            album.getName() ?? ''
          )
        )
      }
    })

    // 分割线
    Divider()
      .width('100%')
      .height(0.5)
      .color('#F0F0F0')
      .margin({ left: 78 }) // 与封面右边对齐
  }

  /**
   * 构建歌单列表项
   */
  @Builder
  buildFolderItem(item: IAreaShelfItem): void {
    Row() {
      // 歌单封面
      Image(item.getFolder()?.getPicUrl() ?? '')
        .width(50)
        .height(50)
        .borderRadius(4)
        .margin({ left: 16, top: 8, bottom: 8 })

      // 歌单信息
      Column() {
        Text(item.getFolder()?.getName() ?? '未知歌单')
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${item.getFolder()?.getSongNum()?.toString() ?? '0'}首`)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      // 箭头
      Image($r('app.media.icon_right_arrow_placeholder'))
        .width(16)
        .height(16)
        .margin({ right: 16 })
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .height(66)
    .backgroundColor(Color.White)
    .onClick(() => {
      const folder = item.getFolder()
      if (folder) {
        MLog.i(TAG, `Folder clicked: name=${folder.getName()}, id=${folder.getId()}`)
        NavController.getInstance().push(
          RouteName.SONG_LIST_PAGE,
          new SongListPageParams(
            MusicListType.TYPE_FOLDER,
            Number(folder.getId()),
            folder.getName() ?? ''
          )
        )
      }
    })

    // 分割线
    Divider()
      .width('100%')
      .height(0.5)
      .color('#F0F0F0')
      .margin({ left: 78 })
  }

  /**
   * 构建歌曲列表项
   */
  @Builder
  buildSongItem(item: IAreaShelfItem): void {
    Row() {
      // 歌曲封面
      Image(item.getSongInfo()?.smallCoverUrl() ?? item.getSongInfo()?.getAlbumPic() ?? '')
        .width(48)
        .height(48)
        .borderRadius(4)
        .margin({ left: 16, top: 10, bottom: 10 })
        .backgroundColor('#F0F0F0')

      // 歌曲信息
      Column() {
        Row() {
          Text(item.getSongInfo()?.getSongName() ?? '未知歌曲')
            .fontSize(15)
            .fontColor(item.getSongInfo()?.canPlay() ? '#333333' : '#B3B3B3')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // VIP 标签
          if (item.getSongInfo()?.isVip()) {
            Text('VIP')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(2)
              .backgroundColor('#FF6B6B')
              .margin({ left: 6 })
          }

          // 不可播放标签
          if (!item.getSongInfo()?.canPlay()) {
            Text('不可播放')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(2)
              .backgroundColor('#CCCCCC')
              .margin({ left: 4 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 歌手名 + 专辑名
        Row() {
          Text(item.getSongInfo()?.getSingerName() ?? '未知歌手')
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (item.getSongInfo()?.getAlbumName()) {
            Text(' · ')
              .fontSize(12)
              .fontColor('#CCCCCC')

            Text(item.getSongInfo()!.getAlbumName()!)
              .fontSize(12)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      // 播放图标
      Image($r('app.media.icon_right_arrow_placeholder'))
        .width(16)
        .height(16)
        .margin({ right: 16 })
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .backgroundColor(Color.White)
    .onClick(() => {
      const song = item.getSongInfo()
      if (song) {
        this.playSingleSong(song)
      }
      NavController.getInstance().push(RouteName.PLAYER_PAGE);
    })

    // 分割线
    Divider()
      .width('100%')
      .height(0.5)
      .color('#F0F0F0')
      .margin({ left: 76 }) // 与封面右边对齐
  }

  /**
   * 获取列表项的唯一Key
   */
  private getItemKey(item: IAreaShelfItem, index: number): string {
    if (this.viewModel.areaShelfType === AreaShelfType.AreaShelfType_Song) {
      return `song_${item.getSongInfo()?.getSongId() ?? index}`
    } else if (this.viewModel.areaShelfType === AreaShelfType.AreaShelfType_Folder) {
      return `folder_${item.getFolder()?.getId() ?? index}`
    } else {
      return `album_${item.getAlbum()?.getId() ?? index}`
    }
  }

  /**
   * 播放单首歌曲
   */
  private playSingleSong(song: ISongInfo): void {
    MLog.i(TAG, `playSingleSong: ${song.getSongName()}, id=${song.getSongId()}`)
    const playParam: IPlayParam = {
      playListType: MusicListType.TYPE_ONLINE,
      playListTypeId: 0,
      songList: [song],
      startPos: 0,
      from: 0
    }
    const ret = OpenApiSdk.playerApi?.playSongs(playParam)
    if (ret !== PlayError.PLAY_ERR_NONE) {
      ToastUtil.show(`播放失败: ${ret}`)
    }
  }

  /**
   * 播放全部歌曲
   */
  private playAllSongs(): void {
    const songs: ISongInfo[] = []
    for (const item of this.viewModel.shelfItems) {
      if (item.getSongInfo()) {
        songs.push(item.getSongInfo()!)
      }
    }

    if (songs.length === 0) {
      ToastUtil.show('没有可播放的歌曲')
      return
    }

    MLog.i(TAG, `playAllSongs: count=${songs.length}`)
    const playParam: IPlayParam = {
      playListType: MusicListType.TYPE_ONLINE,
      playListTypeId: 0,
      songList: songs,
      startPos: 0,
      from: 0
    }
    const ret = OpenApiSdk.playerApi?.playSongs(playParam)
    if (ret === PlayError.PLAY_ERR_NONE) {
      ToastUtil.show(`播放歌曲数:${songs.length}`);
      NavController.getInstance().push(RouteName.PLAYER_PAGE);
    } else {
      ToastUtil.show(`播放失败: ${ret}`)
    }
  }
}
