import { OpenApiSdk } from "@qqmusic/opisdk-base";
import {
  IHotKeyGroup,
  ISearchHintItem,
  IMusicSkillResult,
  OpenApiResponse
} from "@qqmusic/opisdk-entity";
import { SearchType } from "../component/SearchPage";
import { SearchAlbumModel } from "../model/search/SearchAlbumModel";
import { SearchFolderModel } from "../model/search/SearchFolderModel";
import { SearchLyricModel } from "../model/search/SearchLyricModel";
import { SearchMVModel } from "../model/search/SearchMVModel";
import { SearchRadioModel } from "../model/search/SearchRadioModel";
import { SearchSingerModel } from "../model/search/SearchSingerModel";
import { SearchSongModel } from "../model/search/SearchSongModel";

export enum SearchPageStatus {
  HOTKEY,
  SMART_SEARCH,
  RESULT
}

@ObservedV2
export class SearchViewModel{

  @Trace pageStatus: number = 0;

  @Trace hotKeyWord: IHotKeyGroup[] = [];

  @Trace smartSearch: string[] = [];

  @Trace smartSearchWithLight: ISearchHintItem[] = [];

  @Trace voiceSearchResult: IMusicSkillResult | null = null;

  searchSongModel: SearchSongModel = new SearchSongModel();

  searchAlbumModel: SearchAlbumModel = new SearchAlbumModel();

  searchFolderModel: SearchFolderModel = new SearchFolderModel();

  searchMVModel: SearchMVModel = new SearchMVModel();

  searchLyricModel: SearchLyricModel = new SearchLyricModel();

  searchSingerModel: SearchSingerModel = new SearchSingerModel();

  searchRadioModel: SearchRadioModel = new SearchRadioModel();

  search(key: string, type: SearchType){
    if (type === SearchType.SONG) {
      this.searchSongModel.searchSong(key);
    } else if (type  === SearchType.ALBUM) {
      this.searchAlbumModel.searchAlbum(key);
    } else if (type === SearchType.FOLDER) {
      this.searchFolderModel.searchFolder(key);
    } else if (type === SearchType.MV) {
      this.searchMVModel.searchMV(key);
    } else if (type === SearchType.LYRIC) {
      this.searchLyricModel.searchLyric(key);
    } else if (type === SearchType.SINGER) {
      this.searchSingerModel.searchSinger(key);
    } else if (type === SearchType.RADIO) {
      this.searchRadioModel.searchRadio(key);
    }
  }

  fetchHotKey() {
    OpenApiSdk.openApi?.searchApi.fetchHotKeyList([], 2).then((res: OpenApiResponse<IHotKeyGroup[]>) => {
      if(res.isSuccess() && res.data) {
        this.hotKeyWord = res.data;
      }
    })
  }

  smartSearchKey(key: string) {
    OpenApiSdk.openApi?.searchApi.searchSmart(key).then((res: OpenApiResponse<string[]>) => {
      if(res.isSuccess() && res.data) {
        this.smartSearch = res.data;
      }
    })
  }

  smartSearchKeyWithLight(key: string) {
    OpenApiSdk.openApi?.searchApi.searchSmartWithLight(key).then((res: OpenApiResponse<ISearchHintItem[]>) => {
      if(res.isSuccess() && res.data) {
        this.smartSearchWithLight = res.data;
      }
    })
  }

  voiceSearch(intent: string, slots: Map<string, string>, originQuestion: string, currentSongId: number, num: number) {
    OpenApiSdk.openApi?.searchApi.voiceSearch(intent, slots, originQuestion, currentSongId, num).then((res: OpenApiResponse<IMusicSkillResult>) => {
      if(res.isSuccess() && res.data) {
        this.voiceSearchResult = res.data;
      }
    })
  }
}
