import { PlayerViewModel, QualityItem } from '../../viewmodel/PlayerViewModel'
import { NavController } from '../../nav/NavController'
import { RouteName } from '../../nav/RouteMap'
import { MVPlayerPageParams } from '../../nav/RouteParams'
import { ToastUtil } from '../../utils/ToastUtil'
import { LyricView } from '@qqmusic/opisdk-lyricview'
import { LyricTextParam } from '@qqmusic/opisdk-lyricview'
import { ISoundEffectItem, PlayError, PlayStatus, VipType } from '@qqmusic/opisdk-qmutils'
import { SeekbarComponent } from '../player/SeekbarComponent'
import { OpenApiSdk } from '@qqmusic/opisdk-base'
import { LyricManager } from '@qqmusic/opisdk-lyricview'

const TAG = 'PlayerPage'

/**
 * 全屏播放页面
 *
 * 布局：封面 | 歌曲信息 | 歌词 | 品质/下载/收藏/音效 | 进度条 | 播放控制 | 状态文本 | 测试入口
 */
@ComponentV2
export struct PlayerPage {
  @Consumer('playerViewModel') model: PlayerViewModel = new PlayerViewModel()
  @Consumer('navController') navController: NavController = NavController.getInstance()
  @Local qualitySheetVisible: boolean = false
  @Local effectSheetVisible: boolean = false
  @Local soundEffect: ISoundEffectItem | null = null;
  @Local lyricManager: LyricManager = LyricManager.getInstance();

  aboutToAppear(): void {
    this.model.init()
    this.model.onPageEnter()
    OpenApiSdk.playerApi?.getCurSoundEffect().then((res) => {
      this.soundEffect = res;
    });
  }

  @Builder
  lyricEmptyView() {
    Column() {
      Text('暂无歌词')
        .fontSize(16)
        .fontColor('#888888')
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标题栏
        this.buildTopBar()

        // 可滚动内容
        Scroll() {
          Column({ space: 0 }) {
            // 封面
            this.buildCover()

            // 歌曲名
            Text(this.model.songName)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ top: 16 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('90%')
              .textAlign(TextAlign.Center)

            // 歌手名
            Text(this.model.singerName)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                ToastUtil.show(`歌手: ${this.model.singerName}`)
              })

            // 歌词区域
            this.buildLyricArea()

            // 操作按钮行：品质 / 下载 / 收藏 / 音效
            this.buildActionRow()

            // 进度条
            this.buildProgressBar()

            // 播放控制行：模式 | 上一曲 | 播放暂停 | 下一曲 | 列表
            this.buildPlayControlRow()

            // 播放状态文本
            Text(this.model.playStateText)
              .fontSize(12)
              .fontColor('#AAAAAA')
              .margin({ top: 8 })
            // 时长信息
            Text(`A:${this.model.formatTime(this.model.actualDuration)} T:${this.model.formatTime(this.model.duration)}`)
              .fontSize(11)
              .fontColor('#BBBBBB')
              .margin({ top: 4 })
            // 倍速信息
            if (this.model.playSpeed !== 1.0) {
              Text(`倍速: ${this.model.playSpeed.toFixed(1)}x`)
                .fontSize(11)
                .fontColor('#BBBBBB')
                .margin({ top: 4 })
            }

            // 测试入口
            this.buildTestButtons()
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
    }
    .hideTitleBar(true)
  }

  @Builder
  buildCover() {
    Image(this.model.coverUrl)
      .width(280)
      .height(280)
      .objectFit(ImageFit.Cover)
      .borderRadius(20)
      .backgroundColor('#E0E0E0')
      .margin({ top: 16 })
      .shadow({ radius: 20, color: '#33000000', offsetY: 8 })
  }

  @Builder
  buildLyricArea() {
    if (this.model.currentState === PlayStatus.PLAYING || this.model.currentState === PlayStatus.PAUSE) {
      // 正常歌词显示
      Column() {
        LyricView({
          lineTextParam: new LyricTextParam(16, 20, false, 0x7F000000),
          highlightTextParam: new LyricTextParam(20, 28, true, 0xFF000000, 0xFFFF0000),
          paddingTop: 10,
          lineSpace: 16,
          enableInteraction: false,
          enableWordByWord: false,
          scrollAlign: ScrollAlign.CENTER,
          emptyView: this.lyricEmptyView
        })
      }
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        NavController.getInstance().push(RouteName.LYRIC_TEST_PAGE);
      })
      .height(200)
      .borderRadius(12)
      .backgroundColor('#F5F5F5')
      .margin({ top: 12 })
    } else {
      // 歌词加载中状态
      Column() {
        LoadingProgress()
          .width(32)
          .height(32)
          .color('#6200EE')
        Text('歌词加载中...')
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 8 })
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(12)
      .backgroundColor('#F5F5F5')
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => {
        NavController.getInstance().push(RouteName.LYRIC_TEST_PAGE);
      })
      .margin({ top: 12 })
    }
  }

  @Builder
  buildTopBar() {
    Row() {
      Image($r('app.media.icon_back_placeholder'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.navController.pop()
        })
        .margin({ left: 16, top: 12, bottom: 12 })

      Text('播放页')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  buildActionRow() {
    Row() {
      // 品质 - 点击打开音质弹窗
      Text(this.model.getQualityText(this.model.currentQuality))
        .fontSize(16)
        .fontColor('#666666')
        .onClick(() => {
          this.qualitySheetVisible = true;
        })
        .bindSheet($$this.qualitySheetVisible, this.buildQualitySheet(), {
          height: SheetSize.FIT_CONTENT,
          dragBar: true,
          backgroundColor: Color.White,
          onDisappear: () => {
            this.qualitySheetVisible = false
          }
        })

      // 下载
      Image($r('app.media.icon_setting_placeholder'))
        .width(20)
        .height(20)
        .onClick(() => {
          ToastUtil.show('下载功能开发中')
        })

      // 收藏
      Image(this.model.isFavorite ? $r('app.media.ic_heart_red') : $r('app.media.ic_heart'))
        .width(20)
        .height(20)
        .onClick(() => {
          this.model.toggleFavorite()
        })

      // 音效

      Text('音效')
        .fontSize(16)
        .fontColor('#666666')
        .onClick(() => {
          this.model.getSoundEffect();
          setTimeout(() => {
            this.effectSheetVisible = true
          }, 500)
        })
        .bindSheet($$this.effectSheetVisible, this.buildEffectSheet(), {
          height: SheetSize.FIT_CONTENT,
          dragBar: true,
          backgroundColor: Color.White,
          onDisappear: () => {
            this.effectSheetVisible = false
          }
        })
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: 16,
      bottom: 16
    })
  }

  @Builder
  buildProgressBar() {
    Row() {
      Text(this.model.formatTime(this.model.playPosition))
        .fontSize(11)
        .fontColor('#888888')
        .width(44)
        .textAlign(TextAlign.Center)

      SeekbarComponent({
        progress: this.model.playPosition,
        progressMax: this.model.duration,
        playColor: '#6200EE',
        bgColor: '#E0E0E0',
        tryListenStart: this.model.currentSong?.canOnlyPlayTry() ? (this.model.currentSong?.getTryBegin() ?? 0) : 0,
        tryListenEnd: this.model.currentSong?.canOnlyPlayTry() ? (this.model.currentSong?.getTryEnd() ?? 0) : 0,
        isShowTime: true,
        enableInteraction: true,
        progressHeight: 3,
        onSeek: (position: number) => {
          this.model.seekTo(position)
        }
      })
        .layoutWeight(1)

      Text(this.model.formatTime(this.model.duration))
        .fontSize(11)
        .fontColor('#888888')
        .width(44)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
  }

  @Builder
  buildPlayControlRow() {
    Row() {
      // 播放模式 - 根据模式展示不同图标和文本
      Column({ space: 2 }) {
        Image(this.model.modeIcon)
          .width(30)
          .height(30)
          .objectFit(ImageFit.Contain)
        Text(this.model.modeText)
          .fontSize(9)
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 16 })
      .onClick(() => {
        this.model.cyclePlayMode()
      })

      // 上一曲
      Image($r('app.media.icon_back_placeholder'))
        .width(44)
        .height(44)
        .margin({ right: 16 })
        .onClick(() => {
          this.model.prev()
        })

      // 播放/暂停
      Image(this.model.isPlaying ? $r('app.media.ic_state_playing') : $r('app.media.ic_state_paused'))
        .width(60)
        .height(60)
        .margin({ right: 16 })
        .onClick(() => {
          this.model.playPause()
        })

      // 下一曲
      Image($r('app.media.icon_back_placeholder'))
        .width(44)
        .height(44)
        .rotate({ angle: 180 })
        .margin({ right: 16 })
        .onClick(() => {
          this.model.next()
        })

      // 播放列表
      Image($r('app.media.ic_playlist'))
        .width(28)
        .height(28)
        .onClick(() => {
          this.navController.push(RouteName.PLAY_LIST_PAGE)
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({ top: 12 })
  }

  /**
   * 音质选择弹窗
   * 显示当前歌曲支持的所有音质，当前音质高亮标记
   */
  @Builder
  buildQualitySheet() {
    Column() {
      // 标题
      Text('选择音质')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 })

      // 品质列表
      List({ space: 0 }) {
        ForEach(this.model.qualityList, (item: QualityItem) => {
          ListItem() {
            Row() {
              // 音质名称（含大小、权限、试听标签）
              Text(item.name)
                .fontSize(13)
                .fontColor(item.hasQuality ? '#333333' : '#BBBBBB')
                .layoutWeight(1)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              // 不可用标记
              if (!item.hasQuality) {
                Text('不可用')
                  .fontSize(12)
                  .fontColor('#CCCCCC')
                  .margin({ left: 4 })
              }
              // 当前音质标记
              if (item.isCurrent) {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#6200EE')
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .height(52)
            .padding({
              left: 20,
              right: 20,
              top: 8,
              bottom: 8
            })
            .alignItems(VerticalAlign.Center)
            .borderRadius(8)
            .backgroundColor(item.isCurrent ? '#F3E8FF' : Color.Transparent)
            .onClick(() => {
              if (this.model.changeQuality(item.quality)) {
                this.qualitySheetVisible = false
              }
            })
          }
        }, (item: QualityItem) => `${item.quality}`)
      }
      .width('100%')
      .constraintSize({ maxHeight: 400 })
      .padding({ bottom: 24 })
    }
    .width('100%')
  }

  /**
   * 音质选择弹窗
   * 显示当前歌曲支持的所有音质，当前音质高亮标记
   */
  @Builder
  buildEffectSheet() {
    Column() {
      // 标题
      Text('选择音效')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 })

      // 音效列表
      List({ space: 0 }) {
        ForEach(this.model.items, (item: ISoundEffectItem) => {
          ListItem() {
            Row() {
              // 音效名称
              Text(item.getName())
                .fontSize(15)
                .fontColor('#333333')
                .width(100)

              if (item.isCustomEffect()) {
                Text(' 定制音效')
                  .fontSize(15)
                  .fontColor('#333333')
                  .width(100)
              } else if (item.getVipType() === VipType.SUPER_VIP) {
                Text(' 超级会员')
                  .fontSize(15)
                  .fontColor(Color.Yellow)
                  .width(100)
              } else if (item.getVipType() === VipType.GREEN_VIP) {
                Text(' 豪华绿钻')
                  .fontSize(15)
                  .fontColor(Color.Green)
                  .width(100)
              }

              Blank()
                .layoutWeight(1)

              if (this.soundEffect !== null && this.soundEffect.getSdkId() === item.getSdkId()) {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#6200EE')
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .height(52)
            .padding({ left: 20, right: 20 })
            .alignItems(VerticalAlign.Center)
            .borderRadius(8)
            .onClick(() => {
              if (this.soundEffect !== null && this.soundEffect.getSdkId() === item.getSdkId()) {
                OpenApiSdk.playerApi?.setSoundEffectType(null);
                OpenApiSdk.playerApi?.getCurSoundEffect().then((res) => {
                  this.soundEffect = res;
                })
                ToastUtil.show("取消音效->" + item.getName());
                return;
              }

              const ret = OpenApiSdk.playerApi?.setSoundEffectType(item, (status: number) => {
                switch (status) {
                  case 1:
                    ToastUtil.show("设置音效->开始下载音效");
                    break;
                  case 2:
                    ToastUtil.show("设置音效->下载完成");
                    break;
                  case 3:
                    ToastUtil.show("设置音效->下载失败");
                    break;
                  case 4:
                    ToastUtil.show("设置音效->已在下载中");
                    break;
                }
                return true;
              });
              switch (ret) {
                case 0:
                  OpenApiSdk.playerApi?.getCurSoundEffect().then((res) => {
                    this.soundEffect = res;
                  })
                  ToastUtil.show("设置音效->" + item.getName() + " 成功");
                  break;
                case PlayError.PLAY_ERR_UNSUPPORT_WANOS:
                  ToastUtil.show("为保证您的听歌体验，WANOS歌曲播放中不建议叠加其他音效等效果");
                  break;
                case PlayError.PLAY_ERR_UNSUPPORT_EXCELLENT:
                  ToastUtil.show("为保证您的听歌体验，臻品2.0播放中不建议叠加其他音效等效果");
                  break;
                case PlayError.PLAY_ERR_UNSUPPORT_GALAXY:
                  ToastUtil.show("为保证您的听歌体验，臻品全景声音质播放中不建议叠加其他音效等效果");
                  break;
                case PlayError.PLAY_ERR_UNSUPPORT_MASTER_TAPE:
                  ToastUtil.show("为保证您的听歌体验，臻品母带音质播放中不建议叠加其他音效等效果");
                  break;
                case PlayError.PLAY_ERR_NEED_VIP:
                  ToastUtil.show("需要vip");
                  break;
                case PlayError.PLAY_ERR_NEED_SUPER_VIP:
                  ToastUtil.show("需要超级会员");
                  if (OpenApiSdk.openApi?.soundEffectApi.canTrySoundEffect(item)) {
                    OpenApiSdk.openApi?.soundEffectApi.tryOpenSoundEffect(item, null
                      //     {
                      //     onSuccess: ()=>{
                      //       ToastUtil.show("try suc");
                      //     },
                      //     onFailure: (errCode, msg)=> {
                      //       ToastUtil.show("try failed:" + msg);
                      //     }
                      // }
                    )
                  }
                  break;
                default:
                  ToastUtil.show("ret:" + ret);
                  break;
              }
            })
          }
        })
      }
      .width('100%')
      .constraintSize({ maxHeight: 400 })
      .padding({ bottom: 24 })
    }
    .width('100%')
  }

  @Builder
  buildTestButtons() {
    Column({ space: 8 }) {
      Button('进入播放测试页')
        .fontSize(14)
        .onClick(() => {
          this.navController.push(RouteName.MUSIC_TEST_PAGE)
        })
        .margin({ top: 16 })

      Button('播放MV')
        .fontSize(14)
        .onClick(() => {
          if (this.model.hasMvVid) {
            const params = new MVPlayerPageParams(this.model.currentSong?.getMvVid() ?? '')
            this.navController.push(RouteName.MV_PLAYER_PAGE, params)
          } else {
            ToastUtil.show('该歌曲没有MV可以播放')
          }
        })
    }
    .alignItems(HorizontalAlign.Center)
  }
}

@Builder
export function PlayerPageBuilder(params: Object) {
  PlayerPage()
}
