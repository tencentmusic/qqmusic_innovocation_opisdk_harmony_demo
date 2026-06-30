import { IObserver, OpenApiSdk } from '@qqmusic/opisdk-base'
import { hidebug } from '@kit.PerformanceAnalysisKit'
import { LoadType } from '@qqmusic/opisdk-entity'
import { Singer, SongInfo } from '@qqmusic/opisdk-openapi'
import { NavController } from '../nav/NavController'
import { ISinger, ISongInfo, ToastUtils } from '@qqmusic/opisdk-qmutils'
import { router } from '@kit.ArkUI'

const TAG_DEBUG = 'DebuggingPage'

/**
 * DebuggingPage 专用的观察者实现
 * 避免在组件内使用匿名对象字面量
 */
class DebuggingObserver implements IObserver<LoadType> {
  private page: DebuggingPage
  constructor(page: DebuggingPage) {
    this.page = page
  }

  update(loadType: LoadType): void {
    switch (loadType) {
      case LoadType.SONG:
        this.page.isSongCollect = OpenApiSdk.personalAssetsApi?.songFavApi.isCollectedById(this.page.songId.toString()) ?? false;
        break;
      case LoadType.SINGER:
        this.page.isSingerCollect = OpenApiSdk.personalAssetsApi?.singerFavApi.isCollectedById(this.page.singerId.toString()) ?? false;
        break;
      case LoadType.ALL: {
        this.page.isSongCollect = OpenApiSdk.personalAssetsApi?.songFavApi.isCollectedById(this.page.songId.toString()) ?? false;
        this.page.isSingerCollect = OpenApiSdk.personalAssetsApi?.singerFavApi.isCollectedById(this.page.singerId.toString()) ?? false;
        break;
      }
    }
  }
}

@Entry
@ComponentV2
export struct DebuggingPage {
  @Consumer('navController') navController: NavController = NavController.getInstance()
  // 模拟内存泄露对象
  leakedArray: Array<Array<Object>> = []
  // 观察者对象
  private observer: DebuggingObserver | null = null

  aboutToAppear(): void {
    this.observer = new DebuggingObserver(this)

    OpenApiSdk.personalAssetsApi?.songFavApi.register(LoadType.SONG, this.observer)
    OpenApiSdk.personalAssetsApi?.singerFavApi.register(LoadType.SINGER, this.observer)

    this.isSongCollect = OpenApiSdk.personalAssetsApi?.songFavApi.isCollectedById(this.songId.toString()) ?? false;
    this.isSingerCollect =
      OpenApiSdk.personalAssetsApi?.singerFavApi.isCollectedById(this.singerId.toString()) ?? false;
  }

  aboutToDisappear(): void {
    if (this.observer) {
      OpenApiSdk.personalAssetsApi?.songFavApi.unregister(LoadType.SONG, this.observer)
      OpenApiSdk.personalAssetsApi?.singerFavApi.unregister(LoadType.SINGER, this.observer)
    }
  }

  @Builder
  fireEyePanel() {
    Column() {
      Text('火眼测试').fontSize(18).width('100%')
      Blank().height(5)
      Row() {
        Button('Native').onClick(() => {
          OpenApiSdk.fireEyeApi?.testNativeCrash()
        })
        Button('Java').onClick(() => {
          OpenApiSdk.fireEyeApi?.testJavaCrash()
        })
        Button('ANR').onClick(() => {
          OpenApiSdk.fireEyeApi?.testANRCrash()
        })
      }.width('100%').justifyContent(FlexAlign.SpaceEvenly)

      Blank().height(10)
      Row() {
        Button('js内存泄漏插件测试').onClick(() => {
          router.pushUrl({ url: 'pages/LeakChildPage' })
        })
        Button('生成一个js泄漏').onClick(() => {
          hidebug.setAppResourceLimit('js_heap', 85, true)
          for (let index = 0; index < 1000; index++) {
            this.leakedArray.push(new Array(500000).fill(1))
          }
        })
      }.width('100%').justifyContent(FlexAlign.SpaceEvenly)
    }
  }

  songId = 626997953
  @Local isSongCollect: boolean = false
  @Builder
  loadCollectSong() {
    Column() {
      Text('歌曲收藏测试').fontSize(18).width('100%')

      Blank().height(5)

      Row() {
        Column() {
          Text('收藏歌曲列表')
          List() {
            ForEach(OpenApiSdk.personalAssetsApi?.songFavApi.getData().list ?? [], (song: ISongInfo) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(song.getSongId().toString()).fontSize(12)
                    Text(song.getSongName()).fontSize(12)
                  }.width('100%').layoutWeight(1).justifyContent(FlexAlign.SpaceBetween)

                  Blank().width('100%').height(0.5).backgroundColor(Color.Gray).opacity(0.2)
                }
              }.width('100%').height(45)
            }, (song: ISongInfo) => song.getSongId().toString() + '_' + new Date().getTime().toString())
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .borderWidth(1)
          .borderColor(Color.Red)
        }.width('50%').height(150)

        Column() {
          Button('收藏/取消收藏').onClick(() => {
            let song: SongInfo = new SongInfo()
            song.songId = this.songId
            // song.songName = '失去后一切如常'
            let isCollect = !this.isSongCollect
            OpenApiSdk.personalAssetsApi?.songFavApi.setCollectOrCancel(isCollect, song).then(success => {
              if (success) {
                ToastUtils.showToastContent(isCollect ? '收藏成功' : '取消收藏成功')
              } else {
                ToastUtils.showToastContent(isCollect ? '收藏失败' : '取消收藏失败')
              }
            })
          })
          Text(`ID为${this.songId}的歌曲是否已收藏: ${this.isSongCollect}`)
        }.width('50%').height(150)
      }.width('100%').justifyContent(FlexAlign.SpaceEvenly)
    }
  }

  singerId = 7221
  @Local isSingerCollect: boolean = false

  @Builder
  loadCollectSinger() {
    Column() {
      Text('歌手收藏(关注)测试').fontSize(18).width('100%')

      Blank().height(5)

      Row() {
        Column() {
          List() {
            ForEach(OpenApiSdk.personalAssetsApi?.singerFavApi.getData().list ?? [], (singer: ISinger) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(singer.getSingerId().toString()).fontSize(12)
                    Text(singer.getSingerName()).fontSize(12)
                  }.width('100%').layoutWeight(1).justifyContent(FlexAlign.SpaceBetween)

                  Blank().width('100%').height(0.5).backgroundColor(Color.Gray).opacity(0.2)
                }
              }.width('100%').height(45)
            }, (singer: ISinger) => singer.getSingerId().toString() + '_' + new Date().getTime().toString())
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .borderWidth(1)
          .borderColor(Color.Red)
        }.width('50%').height(150)

        Column() {
          Button('收藏/取消收藏').onClick(() => {
            let singer: Singer= new Singer();
            singer.id = this.singerId
            // singer.name = '许嵩'
            let isCollect = !this.isSingerCollect
            OpenApiSdk.personalAssetsApi?.singerFavApi.setCollectOrCancel(isCollect, singer as ISinger).then(success => {
              if (success) {
                ToastUtils.showToastContent(isCollect ? '收藏成功' : '取消收藏成功')
              } else {
                ToastUtils.showToastContent(isCollect ? '收藏失败' : '取消收藏失败')
              }
            })
          })
          Text(`ID为${this.singerId}的歌曲是否已收藏: ${this.isSingerCollect}`)
        }.width('50%').height(150)
      }.width('100%').justifyContent(FlexAlign.SpaceEvenly)
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            Image($r('app.media.ic_back_dark')).width(44).height(44)
              .onClick(() => {
                this.navController.pop()
              })
          }
          .width('100%')
          .height(44)
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .borderWidth({ bottom: 0.5 })
          .borderColor('#36000000')

          Scroll() {
            Column() {
              // 火眼面板
              this.fireEyePanel()
              Blank().height(20)

              // 加载已收藏的歌手数据
              this.loadCollectSinger()
              Blank().height(20)

            }.width('100%').padding({ top: 10 })
          }.width('100%').layoutWeight(1)
        }.width('100%').height('100%')
        .padding({ left: 20, right: 20, bottom: 20 })
      }.width('100%').height('100%')
    }
    .hideTitleBar(true)
  }
}

@Builder
export function DebuggingPageBuilder(params: Object) {
  DebuggingPage()
}