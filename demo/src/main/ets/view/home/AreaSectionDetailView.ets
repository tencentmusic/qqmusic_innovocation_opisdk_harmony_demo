import { MLog, OpenApiSdk } from '@qqmusic/opisdk-base'
import { IPlayParam, IAreaShelf, AreaShelfType, IArea, IAreaShelfItem } from '@qqmusic/opisdk-entity'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { AreaListPageParams, SongListPageParams } from '../../nav/RouteParams'
import { ToastUtil } from '../../utils/ToastUtil'
import { ISongInfo, MusicListType, PlayError } from '@qqmusic/opisdk-qmutils'

const TAG = 'AreaSectionDetailView'

/**
 * 专区详情页
 */
@ComponentV2
export struct AreaSectionDetailView {
  @Param title: string = ''
  @Param areaId: number = 0
  @Param viewModel: HomeViewModel = new HomeViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()

  /** 当前专区数据 */
  @Local areaShelves: IAreaShelf[] = []
  @Local areaTitle: string = ''
  @Local areaDesc: string = ''
  @Local areaCover: string = ''
  /** 是否已加载过数据 */
  private hasLoaded: boolean = false

  aboutToAppear(): void {
    MLog.i(TAG, `AreaSectionDetailView aboutToAppear: title=${this.title}, areaId=${this.areaId}`)
    if (!this.hasLoaded) {
      this.loadAreaData()
    }
  }

  aboutToDisappear(): void {
    MLog.i(TAG, 'AreaSectionDetailView aboutToDisappear')
  }

  /**
   * 加载专区数据
   */
  private async loadAreaData(): Promise<void> {
    this.hasLoaded = true
    await this.viewModel.fetchAreaDataById(this.areaId)

    // 从 viewModel 中同步数据到本地状态
    const area: IArea | null = this.viewModel.currentArea
    if (area) {
      this.areaTitle = area.getTitle()
      this.areaDesc = area.getDesc()
      this.areaCover = area.getCover() ?? '';
      this.areaShelves = area.getShelves() ?? []
      MLog.i(TAG, `loadAreaData success: areaShelves=${JSON.stringify(this.areaShelves)}`)
    } else if (this.viewModel.areaErrorMsg.length > 0) {
      ToastUtil.show(this.viewModel.areaErrorMsg)
    }
  }

  build() {
    Column() {
      if (this.viewModel.isLoadingArea) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#6200EE')
          Text('加载中...')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.viewModel.showRefreshButton) {
        // 加载失败，显示重试
        Column() {
          Image($r('app.media.icon_home_placeholder'))
            .width(64)
            .height(64)
            .opacity(0.3)
          Text(this.viewModel.areaErrorMsg || '加载失败')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 12 })
          Button('重新加载')
            .margin({ top: 16 })
            .onClick(() => {
              this.loadAreaData()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 专区内容列表
        this.buildContentList()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildContentList() {
    List() {
      // 封面区域（第一个元素）
      if (this.areaCover.length > 0 || this.areaTitle.length > 0) {
        ListItem() {
          this.buildCoverSection()
        }
      }

      // 各 Shelf 模块
      Repeat(this.areaShelves).each((repeatItem) => {
        ListItem() {
          this.buildShelfSection(repeatItem.item, repeatItem.index)
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
  }

  /**
   * 构建封面区域
   */
  @Builder
  buildCoverSection() {
    Stack() {
      // 封面图
      if (this.areaCover.length > 0) {
        Image(this.areaCover)
          .width('100%')
          .height(160)
          .objectFit(ImageFit.Cover)
          .onClick(() => {
            // 点击封面可跳转 WebView
            MLog.i(TAG, `Cover clicked: ${this.areaCover}`)
          })
      } else {
        Row()
          .width('100%')
          .height(160)
          .backgroundColor('#E0E0E0')
      }

      Column() {
        // 标题
        if (this.areaTitle.length > 0) {
          Text(this.areaTitle)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 16, right: 16, top: 8, bottom: 4 })
            .backgroundColor('#33000000')
            .borderRadius(4)
            .margin({ left: 16, top: 12 })
        }

        Blank()

        // 描述
        if (this.areaDesc.length > 0) {
          Text(this.areaDesc)
            .fontSize(14)
            .fontColor(Color.White)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding({ left: 16, right: 16, top: 4, bottom: 8 })
            .backgroundColor('#22000000')
            .borderRadius(4)
            .margin({ left: 16, bottom: 12 })
        }
      }
      .width('100%')
      .height(160)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height(160)
  }

  /**
   * 构建 Shelf 模块区域
   */
  @Builder
  buildShelfSection(shelf: IAreaShelf, index: number) {
    Column() {
      // Shelf 标题栏
      Row() {
        Text(shelf.getShelfTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getShelfTitleColor(shelf.getShelfType()))

        Blank()

        // "更多" 按钮
        Text(this.getMoreText(shelf.getShelfType()))
          .fontSize(14)
          .fontColor(Color.Gray)
          .onClick(() => {
            const params: AreaListPageParams = new AreaListPageParams(this.areaId, shelf.getShelfType(), shelf.getShelfId(), shelf.getShelfTitle());
            MLog.i(TAG, `More clicked: params=${JSON.stringify(params)}`);
            NavController.getInstance().push(RouteName.AREA_LIST_PAGE, params);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // Shelf 内容（最多展示 6 个）
      this.buildShelfItems(shelf)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .margin({ top: 8, bottom: 4 })
    .borderRadius(8)
    .padding({ bottom: 12 })
  }

  /**
   * 构建 Shelf 内容项（FlowRow 效果，鸿蒙中用 Flex 换行模拟）
   */
  @Builder
  buildShelfItems(shelf: IAreaShelf) {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
      Repeat(shelf.getShelfItems().slice(0, 6)).each((repeatItem: RepeatItem<IAreaShelfItem>) => {
        if (shelf.getShelfType() === AreaShelfType.AreaShelfType_Song  && repeatItem.item.getSongInfo()) {
          // 歌曲类型 — 内联 UI
          Column() {
            if ((repeatItem.item.getSongInfo()?.isLongAudioSong() ?? false)) {
              // 长音频播客样式
              Row({ space: 8 }) {
                Image(repeatItem.item.getSongInfo()?.smallCoverUrl() ?? '')
                  .width(40).height(40)
                  .objectFit(ImageFit.Cover).borderRadius(4)
                  .backgroundColor('#E0E0E0')
                Column({ space: 2 }) {
                  Text(repeatItem.item.getSongInfo()?.getSongName() ?? '未知歌曲')
                    .fontSize(14)
                    .fontColor((repeatItem.item.getSongInfo()?.canPlay() ?? false) ? '#333333' : '#AAAAAA')
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text((repeatItem.item.getSongInfo()?.getSingerName() ?? '未知') + ', ' +
                    (repeatItem.item.getSongInfo()?.getUpdateTime() ?? '') + ', ' +
                    (repeatItem.item.getSongInfo()?.getListenCount()?.toString() ?? '0'))
                    .fontSize(11)
                    .fontColor((repeatItem.item.getSongInfo()?.canPlay() ?? false) ? '#999999' : '#CCCCCC')
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row({ space: 4 }) {
                    if (repeatItem.item.getSongInfo()?.isVip() ?? false) {
                      Text('VIP').fontSize(10).fontColor('#FF6600')
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .border({ width: 0.5, color: '#FF6600', radius: 2 })
                    }
                    if ((repeatItem.item.getSongInfo()?.getLongAudioVip() ?? 0) === 1) {
                      Text('长音频VIP').fontSize(10).fontColor('#FF6600')
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .border({ width: 0.5, color: '#FF6600', radius: 2 })
                    }
                  }
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              .width('100%').alignItems(VerticalAlign.Center)
            } else {
              // 普通歌曲样式
              Column({ space: 4 }) {
                Text(repeatItem.item.getSongInfo()?.getSongName() ?? '未知歌曲')
                  .fontSize(14)
                  .fontColor((repeatItem.item.getSongInfo()?.canPlay() ?? false) ? '#333333' : '#AAAAAA')
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .textAlign(TextAlign.Center)
                Text('VIP: ' + ((repeatItem.item.getSongInfo()?.isVip() ?? false) ? 'VIP' : '普通'))
                  .fontSize(11)
                  .fontColor((repeatItem.item.getSongInfo()?.canPlay() ?? false) ? '#999999' : '#CCCCCC')
                  .textAlign(TextAlign.Center)
              }
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
            }
          }
          .width('50%').padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .onClick(() => {
            const s = repeatItem.item.getSongInfo()
            if (s && (s.canPlay() ?? false)) {
              this.playSong(s)
            } else {
              ToastUtil.show('该歌曲暂时无法播放')
            }
          })
        } else if (shelf.getShelfType() === AreaShelfType.AreaShelfType_Folder && repeatItem.item.getFolder()) {
          // 歌单类型 — 内联 UI
          Column({ space: 4 }) {
            Text(repeatItem.item.getFolder()?.getName() ?? '未知歌单')
              .fontSize(14).fontColor('#333333')
              .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
            Text('歌曲数量: ' + (repeatItem.item.getFolder()?.getSongNum()?.toString() ?? '0'))
              .fontSize(11).fontColor('#999999')
              .textAlign(TextAlign.Center)
          }
          .width('50%').padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          .onClick(() => {
            const f = repeatItem.item.getFolder()
            if (f) {
              MLog.i(TAG, `Folder clicked: name=${f.getName()}, id=${f.getId()}`)
              this.navController.push(RouteName.SONG_LIST_PAGE, new SongListPageParams(
                MusicListType.TYPE_FOLDER, Number(f.getId()), f.getName()
              ))
            }
          })
        } else if (shelf.getShelfType() === AreaShelfType.AreaShelfType_Album && repeatItem.item.getAlbum()) {
          // 专辑类型 — 内联 UI
          Column({ space: 4 }) {
            Text(repeatItem.item.getAlbum()?.getName() ?? '未知专辑')
              .fontSize(14).fontColor('#333333')
              .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
            Text('歌曲数量: ' + (repeatItem.item.getAlbum()?.getSongNum()?.toString() ?? '0'))
              .fontSize(11).fontColor('#999999')
              .textAlign(TextAlign.Center)
          }
          .width('50%').padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          .onClick(() => {
            const a = repeatItem.item.getAlbum()
            if (a) {
              MLog.i(TAG, `Album clicked: name=${a.getName()}, id=${a.getId()}`)
              this.navController.push(RouteName.SONG_LIST_PAGE, new SongListPageParams(
                MusicListType.TYPE_ALBUM, Number(a.getId()), a.getName()
              ))
            }
          })
        }
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
  }
  /**
   * 播放单曲
   */
  private playSong(song: ISongInfo): void {
    MLog.i(TAG, `playSong: ${song.getSongName()}, id=${song.getSongId()}`)
    OpenApiSdk.openApi?.songApi.fetchSongInfoBatch([song.getSongId()])
      .then((res) => {
        if (res.isSuccess()) {
          const data = res.data ?? [];
          const playParam: IPlayParam = {
            playListType: MusicListType.TYPE_ONLINE,
            playListTypeId: 0,
            songList: data,
            startPos: 0,
            startPlay: true
          }
          const result = OpenApiSdk.playerApi?.playSongs(playParam) ?? -1
          if (result !== PlayError.PLAY_ERR_NONE) {
            MLog.w(TAG, `playSong failed, error: ${result}`)
            ToastUtil.show('播放失败')
          }
        }
      })
  }

  /**
   * 根据 Shelf 类型获取标题颜色
   */
  private getShelfTitleColor(shelfType: number): string {
    switch (shelfType) {
      case AreaShelfType.AreaShelfType_Song:
        return '#FF0000' // 红色 - 歌曲
      case AreaShelfType.AreaShelfType_Folder:
        return '#FFAA00' // 黄色 - 歌单
      case AreaShelfType.AreaShelfType_Album:
        return '#0066FF' // 蓝色 - 专辑
      default:
        return '#888888'
    }
  }

  /**
   * 根据 Shelf 类型获取"更多"文本
   */
  private getMoreText(shelfType: number): string {
    switch (shelfType) {
      case AreaShelfType.AreaShelfType_Song:
        return '更多歌曲 >'
      case AreaShelfType.AreaShelfType_Folder:
        return '更多歌单 >'
      case AreaShelfType.AreaShelfType_Album:
        return '更多专辑 >'
      default:
        return '更多 >'
    }
  }
}
