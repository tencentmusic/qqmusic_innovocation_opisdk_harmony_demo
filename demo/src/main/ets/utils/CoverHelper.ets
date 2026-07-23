import { ISinger, ISongInfo } from '@qqmusic/opisdk-qmutils';
import { IAlbum, IFolder, IRank } from '@qqmusic/opisdk-entity';

/**
 * 专辑/歌手封面图统一获取工具类
 */
export class CoverHelper {
  /**
   * 获取默认专辑封面资源
   *
   * @returns Resource 随机返回一个默认背景资源
   */
  static getAlbumDefault(): ResourceStr {
    // 生成 0 或 1 的随机整数
    const randomNum = Math.floor(Math.random() * 2);

    if (randomNum === 0) {
      return $r('app.media.card_default_bg_1');
    } else {
      return $r('app.media.card_default_bg_2');
    }
  }

  /**
   * 从 ISongInfo 获取封面图 URL
   *
   * 优先级：500x500 → 300x300 → 150x150 → getAlbumPic() → ''
   *
   * @param songInfo 歌曲信息对象，可为 null
   * @returns 封面图 URL 字符串，无图时返回空字符串
   */
  static getCoverUrl(songInfo: ISongInfo | null): string {
    if (!songInfo) {
      return '';
    }

    // 优先取 500x500
    const pic500 = songInfo.getAlbumPic500x500();
    if (pic500 && pic500.length > 0) {
      return pic500;
    }

    // 降级 300x300
    const pic300 = songInfo.getAlbumPic300x300();
    if (pic300 && pic300.length > 0) {
      return pic300;
    }

    // 降级 150x150
    const pic150 = songInfo.getAlbumPic150x150();
    if (pic150 && pic150.length > 0) {
      return pic150;
    }

    // 降级 getAlbumPic()
    const albumPic = songInfo.getAlbumPic();
    if (albumPic && albumPic.length > 0) {
      return albumPic;
    }

    return '';
  }

  /**
   * 从 IAlbum 获取封面图 URL
   *
   * @param album 专辑对象，可为 null
   * @returns 封面图 URL 字符串，无图时返回空字符串
   */
  static getCoverUrlFromAlbum(album: IAlbum | null): string {
    if (!album) {
      return '';
    }

    const albumBigUrl = album.getAlbumBigUrl() || album.getPic500x500();
    if (albumBigUrl && albumBigUrl.length > 0) {
      return albumBigUrl;
    }

    const albumMediumUrl = album.getAlbumMediumUrl() || album.getPic300x300();
    if (albumMediumUrl && albumMediumUrl.length > 0) {
      return albumMediumUrl;
    }

    const albumSmallUrl = album.getAlbumSmallUrl() || album.getPic150x150();
    if (albumSmallUrl && albumSmallUrl.length > 0) {
      return albumSmallUrl;
    }

    const pic = album.getPic();
    if (pic && pic.length > 0) {
      return pic;
    }

    return '';
  }

  /**
   * 从 ISongInfo 获取歌手封面图 URL
   * @param songInfo
   * @returns
   */
  static getSingerCoverFromSong(songInfo: ISongInfo|null|undefined) : string {
    if (!songInfo) {
      return '';
    }

    const pic500 = songInfo.getSingerPic500x500();
    if (pic500 && pic500.length > 0) {
      return pic500;
    }

    const pic300 = songInfo.getSingerPic300x300();
    if (pic300 && pic300.length > 0) {
      return pic300;
    }

    const pic150 = songInfo.getSingerPic150x150();
    if (pic150 && pic150.length > 0) {
      return pic150;
    }

    const singerPic = songInfo.getSingerPic();
    if (singerPic && singerPic.length > 0) {
      return singerPic;
    }

    return '';
  }

  /**
   * 从 ISinger 获取封面图 URL
   *
   * @param singer 歌手对象，可为 null
   * @returns 封面图 URL 字符串，无图时返回空字符串
   */
  static getCoverUrlFromSinger(singer: ISinger | null): string {
    if (!singer) {
      return '';
    }

    const pic500 = singer.getSingerPic500x500();
    if (pic500 && pic500.length > 0) {
      return pic500;
    }

    const pic300 = singer.getSingerPic300x300();
    if (pic300 && pic300.length > 0) {
      return pic300;
    }

    const pic150 = singer.getSingerPic150x150();
    if (pic150 && pic150.length > 0) {
      return pic150;
    }

    const singerPic = singer.getSingerPic();
    if (singerPic && singerPic.length > 0) {
      return singerPic;
    }

    return '';
  }

  /**
   * 从 IFolder 获取封面图 URL
   *
   * @param folder 歌单对象，可为 null
   * @returns 封面图 URL 字符串，无图时返回空字符串
   */
  static getCoverUrlFromFolder(folder: IFolder | null): string {
    if (!folder) {
      return '';
    }

    const picUrl = folder.getPicUrl();
    if (picUrl && picUrl.length > 0) {
      return picUrl;
    }

    return '';
  }

  /**
   * 从 IRank 获取封面图 URL
   *
   * @param rank 榜单对象，可为 null
   * @returns 封面图 URL 字符串，无图时返回空字符串
   */
  static getCoverUrlFromRank(rank: IRank | null): string {
    if (!rank) {
      return '';
    }

    const headerPic = rank.getTopHeaderPic();
    if (headerPic && headerPic.length > 0) {
      return headerPic;
    }

    const bannerPic = rank.getTopBannerPic();
    if (bannerPic && bannerPic.length > 0) {
      return bannerPic;
    }

    return '';
  }
}
