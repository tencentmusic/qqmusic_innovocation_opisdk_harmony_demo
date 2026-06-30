import { SearchPageStatus, SearchViewModel } from '../viewmodel/SearchViewModel'
import { AlbumResultList } from './searchresult/AlbumResult'
import { FolderResultList } from './searchresult/FolderResult'
import { LyricResultList } from './searchresult/LyricResult'
import { MvResultList } from './searchresult/MvResult'
import { RadioResultList } from './searchresult/RadioResult'
import { SingerResultList } from './searchresult/SingerResult'
import { SongResultList } from './searchresult/SongResult'

export enum SearchType {
  SONG, ALBUM, FOLDER, MV, LYRIC, SINGER,RADIO
}

const TAG: string = "SearchPage"
const tabList: Array<[string, SearchType]> = [
  ["歌曲", SearchType.SONG],
  ["专辑", SearchType.ALBUM],
  ["歌单", SearchType.FOLDER],
  ["MV", SearchType.MV],
  ["歌词", SearchType.LYRIC],
  ["歌手", SearchType.SINGER],
  ["电台", SearchType.RADIO]
]

@ComponentV2
export struct SearchPage {
  @Local searchInput: string = ""
  @Local currentTab: number = 0
  @Local smartKey: Array<string> = []
  @Local doSmartSearch: boolean = true;
  @Provider('searchViewModel') searchViewModel: SearchViewModel = new SearchViewModel();
  controller: TextInputController = new TextInputController();

  aboutToAppear(): void {
    this.searchViewModel.fetchHotKey();
  }

  build() {
    Column({ space: 0 }) {

      Row({ space: 16 }) {
        TextInput({
          placeholder: "输入search关键字",
          text: $$this.searchInput
        })
          .cancelButton({
            style: CancelButtonStyle.CONSTANT,
            icon: {
              src: $r('sys.media.ohos_ic_public_cancel_filled')
            }
          })
          .width('300vp')
          .onChange((value: string) => {
            if(value === "") {
              this.searchViewModel.pageStatus = SearchPageStatus.HOTKEY;
              this.doSmartSearch = true;
              return;
            }
            if (!this.doSmartSearch) {
              this.doSmartSearch = true;
              return;
            }
            this.searchViewModel.pageStatus = SearchPageStatus.SMART_SEARCH;
            this.searchViewModel.smartSearchKey(value);
          })
        Image($r('app.media.icon_search_placeholder'))
          .width(20).height(20)
          .fillColor('#6200ee')
          .onClick(() => {
            this.doSmartSearch = false;
            if (this.searchViewModel.pageStatus === SearchPageStatus.RESULT){
              this.searchViewModel.search(this.searchInput, tabList[this.currentTab][1])
            } else {
              this.searchViewModel.pageStatus = SearchPageStatus.RESULT;
            }
          })
      }.padding(16)

      if (this.searchViewModel.pageStatus === SearchPageStatus.SMART_SEARCH) {
        // 智能关键词网格
        Grid() {
          Repeat(this.searchViewModel.smartSearch).each((repeatItem) => {
            GridItem() {
              Text(repeatItem.item)
                .height('40vp')
                .width('100%')
                .textAlign(TextAlign.Center)
                .backgroundColor(Color.White)
                .borderRadius(4)
                .onClick(() => {
                  this.currentTab = 0;
                  this.doSmartSearch = false;
                  this.searchInput = repeatItem.item;
                  this.searchViewModel.pageStatus = SearchPageStatus.RESULT;
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .padding(16)
      } else if (this.searchViewModel.pageStatus === SearchPageStatus.HOTKEY) {
        Scroll() {
          Row() {
            Repeat(this.searchViewModel.hotKeyWord).each((hotKeyGroup) => {
              List() {
                ListItem() {
                  Text(hotKeyGroup.item.getTabNameInCN())
                    .textAlign(TextAlign.Start)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.Black)
                }

                Repeat(hotKeyGroup.item.getHotKeyList()).each((repeatItem) => {
                  ListItem() {
                    Text(repeatItem.item.getQuery())
                      .textAlign(TextAlign.Start)
                      .fontSize(16)
                      .fontColor(Color.Black)
                      .onClick(() => {
                        this.currentTab = 0;
                        this.doSmartSearch = false;
                        this.searchInput = repeatItem.item.getQuery() ?? '';
                        this.searchViewModel.pageStatus = SearchPageStatus.RESULT;
                      })
                  }
                })
              }
              .height('100%')
              .constraintSize({
                maxWidth: 200
              })
              .scrollBar(BarState.Off)
            })
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .width('100%')
      } else if (this.searchViewModel.pageStatus === SearchPageStatus.RESULT) {
        this.SearchResultTabs()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 70 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SearchResultTabs() {
    Tabs({
      barPosition: BarPosition.Start,
      index: $$this.currentTab
    }) {
      Repeat(tabList).each((repeatItem) => {
        TabContent() {
          this.TabContentBuilder(repeatItem.item[1])
        }
        .onWillShow(()=>{
          this.searchViewModel.search(this.searchInput, repeatItem.item[1]);
        })
        .tabBar(this.TabBuilder(repeatItem.item[0], repeatItem.index))
      })
    }
    .width('100%')
    .layoutWeight(1)
    .barBackgroundColor('#6200ee')
  }

  @Builder
  TabBuilder(title: string, index: number) {
    Text(title)
      .fontColor(this.currentTab === index ? Color.White : Color.Gray)
      .fontSize(16)
  }

  @Builder
  TabContentBuilder(searchType: SearchType) {
    if (searchType === SearchType.SONG) {
      SongResultList()
    } else if (searchType === SearchType.ALBUM) {
      AlbumResultList()
    } else if (searchType === SearchType.FOLDER) {
      FolderResultList()
    } else if (searchType === SearchType.MV) {
      MvResultList()
    } else if (searchType === SearchType.LYRIC) {
      LyricResultList()
    } else if (searchType === SearchType.SINGER) {
      SingerResultList()
    } else if (searchType === SearchType.RADIO) {
      RadioResultList()
    }
  }
}
