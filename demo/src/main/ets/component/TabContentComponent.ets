import { FolderCollectPanel } from "./foldercollect/FolderCollectPanel";
import { MvCollectPanel } from "./mvcollect/MvCollectPanel";
import { VoicedSongCollectPanel } from "./voicedsongcollect/VoicedSongCollectPanel";
import { VoicedAlbumCollectPanel } from "./voicedalbumcollect/VoicedAlbumCollectPanel";
import { AlbumCollectPanel } from "./albumcollect/AlbumCollectPanel";
import { SingerCollectPanel } from "./singercollect/SingerCollectPanel";
import { SongCollectPanel } from "./songcollect/SongCollectPanel";
import { HisSongPanel } from "./hissong/HisSongPanel";
import { HisAlbumPanel } from "./hisalbum/HisAlbumPanel";
import { HisFolderPanel } from "./hisfolder/HisFolderPanel";
import { LongAudioSongPanel } from "./hislongaudio/LongAudioSongPanel";
import { HisMvPanel } from "./hismv/HisMvPanel";
import { SongCollectApiPanel } from "./songcollect/SongCollectApiPanel";
import { AlbumCollectApiPanel } from "./albumcollect/AlbumCollectApiPanel";
import { MvCollectApiPanel } from "./mvcollect/MvCollectApiPanel";
import { VoicedSongCollectApiPanel } from "./voicedsongcollect/VoicedSongCollectApiPanel";
import { SingerCollectApiPanel } from "./singercollect/SingerCollectApiPanel";
import { HisSongApiPanel } from "./hissong/HisSongApiPanel";
import { HisAlbumApiPanel } from "./hisalbum/HisAlbumApiPanel";
import { HisFolderApiPanel } from "./hisfolder/HisFolderApiPanel";
import { LongAudioSongApiPanel } from "./hislongaudio/LongAudioSongApiPanel";
import { HisMvApiPanel } from "./hismv/HisMvApiPanel";
import { FolderCollectApiPanel } from "./foldercollect/FolderCollectApiPanel";
import { VoicedAlbumCollectApiPanel } from "./voicedalbumcollect/VoicedAlbumCollectApiPanel";
import { PersonalFolderApiPanel } from "./personalFolder/PersonalFolderApiPanel";
import { BuyAlbumApiPanel } from "./buyRecord/BuyAlbumApiPanel";
import { BuySongApiPanel } from "./buyRecord/BuySongApiPanel";
import { BuyLongAudioApiPanel } from "./buyRecord/BuyLongAudioApiPanel";
import { OtherPlatListeningApiPanel } from "./otherPlatListening/OtherPlatListeningApiPanel";
import { DemoGlobal } from "../utils/DemoGlobal";

@ComponentV2
export struct TabContentComponent {
  @Param currentPrimaryIndex: number = 0;
  @Param currentSecondaryIndex: number = 0;
  @Param items: string[] = [];
  @Event onChangeIndex?: (index: number) => void;
  @Local enablePersonalAssets: boolean = DemoGlobal.isPersonalAssets;

  build() {
    Column() {
      // 这里根据不同的二级tab显示不同的内容
      if (this.currentPrimaryIndex == 0) {
        if (this.currentSecondaryIndex == 0) {
          //我喜欢
          if (this.enablePersonalAssets) {
            SongCollectPanel({ showTurnThePage: true })
          } else {
            SongCollectApiPanel()
          }
        } else if(this.currentSecondaryIndex == 1) {
          //自建歌单
          PersonalFolderApiPanel()
        }
      } else if (this.currentPrimaryIndex == 1) {
        // 收藏栏目
        if (this.currentSecondaryIndex == 0) {
          // 收藏歌单
          if (this.enablePersonalAssets) {
            FolderCollectPanel()
          } else {
            FolderCollectApiPanel()
          }
        } else if (this.currentSecondaryIndex == 1) {
          // 收藏专辑
          if (this.enablePersonalAssets) {
            AlbumCollectPanel()
          } else {
            AlbumCollectApiPanel()
          }
        } else if (this.currentSecondaryIndex == 2) {
          // 收藏的MV
          if (this.enablePersonalAssets) {
            MvCollectPanel()
          } else {
            MvCollectApiPanel()
          }
        } else if (this.currentSecondaryIndex == 3) {
          // 收藏有声单曲
          if (this.enablePersonalAssets) {
            VoicedSongCollectPanel()
          } else {
            VoicedSongCollectApiPanel()
          }
        } else if (this.currentSecondaryIndex == 4) {
          // 收藏有声专辑
          if (this.enablePersonalAssets) {
            VoicedAlbumCollectPanel()
          } else {
            VoicedAlbumCollectApiPanel()
          }
        } else {
          this.buildFoldePanel()
        }
      } else if (this.currentPrimaryIndex == 5) {
        if (this.currentSecondaryIndex == 0) {
          //订阅歌手
          if (this.enablePersonalAssets) {
            SingerCollectPanel()
          } else {
            SingerCollectApiPanel()
          }
        } else if (this.currentSecondaryIndex == 1) {
          OtherPlatListeningApiPanel()
        }

      } else if (this.currentPrimaryIndex == 2) {
        if (this.currentSecondaryIndex == 0) {
          //最近播放单曲
          if (this.enablePersonalAssets) {
            HisSongPanel()
          } else {
            HisSongApiPanel()
          }
        } else if (this.currentSecondaryIndex == 1) {
          //最近播放专辑
          if (this.enablePersonalAssets) {
            HisAlbumPanel()
          } else {
            HisAlbumApiPanel()
          }
        } else if (this.currentSecondaryIndex == 2) {
          //最近播放歌单
          if (this.enablePersonalAssets) {
            HisFolderPanel()
          } else {
            HisFolderApiPanel()
          }
        } else if (this.currentSecondaryIndex == 3) {
          //最近播放长音频
          if (this.enablePersonalAssets) {
            LongAudioSongPanel()
          } else {
            LongAudioSongApiPanel()
          }
        } else if (this.currentSecondaryIndex == 4) {
          //最近播放mv
          if (this.enablePersonalAssets) {
            HisMvPanel()
          } else {
            HisMvApiPanel()
          }
        }
      }else if (this.currentPrimaryIndex == 4 ){
        if (this.currentSecondaryIndex == 0) {
          BuyAlbumApiPanel()
        } else if (this.currentSecondaryIndex == 1) {
          BuySongApiPanel()
        } else if (this.currentSecondaryIndex == 2) {
          BuyLongAudioApiPanel()
        }
      } else {
        this.buildFoldePanel()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildFoldePanel() {
    List({ space: 10 }) {
      Repeat([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]).each((repeatItem) => {
        ListItem() {
          Column() {
            Text(`内容项目 ${repeatItem.item}`)
              .fontSize(14)
              .fontColor('#333333')
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .width('100%')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ left: 16, right: 16 })
        }
      })
    }
    .layoutWeight(1)
    .width('100%')
    .edgeEffect(EdgeEffect.Spring)
  }

}
