import image from '@ohos.multimedia.image';
import { MagicColorAlgorithm } from './MagicColorAlgorithm';
import { BitmapAlgorithms } from './BitmapAlgorithms';
import { MLog } from '@qqmusic/opisdk-base';

/**
 * 魔法色工具类
 */
export class MagicColorUtil {
  static readonly TOP_HALF_ALPHA: number = 0x66;    // 40% 不透明
  static readonly BOTTOM_HALF_ALPHA: number = 0x99; // 60% 不透明

  static readonly defaultColorPair: [number, number] = [
    MagicColorAlgorithm.hsvToColor(0xFF, [0, 0, 0.25]),
    MagicColorAlgorithm.hsvToColor(0xFF, [0, 0, 0.45])
  ];

  static readonly defaultLightMagicColor: [number, number] = [
    MagicColorAlgorithm.hsvToColor(0xFF, [153, 0.4, 0.94]),
    MagicColorAlgorithm.hsvToColor(0xFF, [153, 0.16, 1])
  ];

  private static readonly defaultDarkMagicColorPair: [number, number] = [
    MagicColorAlgorithm.hsvToColor(0xFF, [0, 0, 0.4]),
    MagicColorAlgorithm.hsvToColor(0xFF, [0, 0, 0.56])
  ];

  private static colorPairGenerator(f1: number[] | null, f2: number[] | null): [number, number] {
    const color1 = MagicColorAlgorithm.hsvToColor(0xFF, f1);
    const color2 = MagicColorAlgorithm.hsvToColor(0xFF, f2);
    return [color1, color2];
  }

  /** 默认光效魔法色 */
  static readonly defaultMultiMagicColor: [number, number] = [
    MagicColorAlgorithm.defaultColor,
    MagicColorAlgorithm.defaultColor
  ];

  /**
   * 封面分成上下两半，取上下两半的第一色相
   */
  static async getPlayerMagicColor(
    source: image.PixelMap | null,
    topHalfAlpha: number = MagicColorUtil.TOP_HALF_ALPHA,
    bottomHalfAlpha: number = MagicColorUtil.BOTTOM_HALF_ALPHA
  ): Promise<[number, number]> {
    const resizedBitmap = await BitmapAlgorithms.resizedBitmap(source, 10, 10);
    if (resizedBitmap !== null) {
      try {
        const topBitmap = await BitmapAlgorithms.getResizedBitmap(resizedBitmap, 0, 0, 10, 5);
        const info = await resizedBitmap.getImageInfo();
        const bottomBitmap = await BitmapAlgorithms.getResizedBitmap(resizedBitmap, 0, Math.floor(info.size.height / 2), 10, 5);
        try {
          const topColor = await MagicColorAlgorithm.generateMagicColorNotNull(topBitmap, topHalfAlpha);
          const bottomColor = await MagicColorAlgorithm.generateMagicColorNotNull(bottomBitmap, bottomHalfAlpha);
          return [topColor, bottomColor];
        } finally {
          topBitmap?.release();
          bottomBitmap?.release();
        }
      } finally {
        // 释放缩放后的临时图，原图 source 由调用方管理
        resizedBitmap.release();
      }
    } else {
      return [MagicColorUtil.defaultMultiMagicColor[0], MagicColorUtil.defaultMultiMagicColor[1]];
    }
  }

  /**
   * 默认光效走偏暗光的黑胶光效取色和偏移
   */
  static async getLightEffectMagicColor(source: image.PixelMap | null): Promise<[number, number]> {
    return MagicColorUtil.getDarkMagicColorPairFromBitmap(source);
  }

  /**
   * 获取排名前二的色相数组的魔法色
   */
  static async getOriginMagicColorPair(source: image.PixelMap | null): Promise<[number | null, number | null]> {
    const resizedBitmap = await BitmapAlgorithms.resizedBitmap(source, 10, 10);
    if (resizedBitmap === null) {
      return [null, null];
    }
    try {
      return await MagicColorAlgorithm.generateMultiMagicColor(resizedBitmap);
    } finally {
      // resizedBitmap 是 source 的副本（或原图本身），释放副本
      if (resizedBitmap !== source) {
        resizedBitmap.release();
      }
    }
  }

  /**
   * 偏亮光的黑胶光效取色和偏移
   */
  static async getLightMagicColorPair(source: image.PixelMap | null): Promise<[number, number]>;
  /**
   * 偏亮光的黑胶光效偏移（从已有颜色对计算）
   */
  static async getLightMagicColorPair(pair: [number | null, number | null]): Promise<[number, number]>;
  static async getLightMagicColorPair(arg: image.PixelMap | null | [number | null, number | null]): Promise<[number, number]> {
    if (Array.isArray(arg)) {
      return MagicColorUtil.getLightMagicColorPairFromPair(arg as [number | null, number | null]);
    } else {
      const pair = await MagicColorUtil.getOriginMagicColorPair(arg as image.PixelMap | null);
      return MagicColorUtil.getLightMagicColorPairFromPair(pair);
    }
  }

  /**
   * 偏暗光的黑胶光效取色和偏移
   */
  static async getDarkMagicColorPairFromBitmap(source: image.PixelMap | null): Promise<[number, number]> {
    const pair = await MagicColorUtil.getOriginMagicColorPair(source);
    return MagicColorUtil.getDarkMagicColorPairFromPair(pair);
  }

  /**
   * 地暮动效的方形、圆形、静态方形播放器样式使用
   */
  static getDuskLightEffectMagicColorPair(pair: [number | null, number | null]): [number, number] {
    const firstColor = pair[0];
    const secondColor = pair[1];
    if (firstColor !== null && secondColor !== null) {
      const max0 = MagicColorAlgorithm.colorToHsv(firstColor);
      const max1 = MagicColorAlgorithm.colorToHsv(secondColor);
      const firstH = max0[0];
      if (firstH > 21 && firstH < 190) {
        max0[1] = 0.7;
        max0[2] = 0.8;
      }
      const secondH = max1[0];
      if (secondH > 21 && secondH < 190) {
        max1[1] = 0.4;
        max1[2] = 0.95;
      }
      return MagicColorUtil.colorPairGenerator(max0, max1);
    } else if (firstColor !== null) {
      const max0 = MagicColorAlgorithm.colorToHsv(firstColor);
      const firstH = max0[0];
      if (firstH > 21 && firstH < 190) {
        max0[1] = 0.7;
        max0[2] = 0.8;
      }
      const max1: number[] = [max0[0], 0.4, 0.95];
      return MagicColorUtil.colorPairGenerator(max0, max1);
    } else {
      return [MagicColorUtil.defaultLightMagicColor[0], MagicColorUtil.defaultLightMagicColor[1]];
    }
  }

  /**
   * 地暮动效的方形、圆形、静态方形播放器样式使用（普通版）
   */
  static getDuskNormalMagicColorPair(pair: [number | null, number | null]): [number, number] {
    const firstColor = pair[0];
    const secondColor = pair[1];
    if (firstColor !== null && secondColor !== null) {
      const max0 = MagicColorAlgorithm.colorToHsv(firstColor);
      if (max0[1] > 0.1) { // 防止灰度颜色被染成紫红色
        max0[1] = max0[1] * 0.1 + 0.3;
      }
      max0[2] = Math.min(max0[2] * 0.1 + 0.9, 1);
      const max1 = MagicColorAlgorithm.colorToHsv(secondColor);
      if (max1[1] > 0.1) { // 修复：此处应判断 max1[1]，原代码误写为 max0[1]
        max1[1] = max1[1] * 0.1 + 0.3;
      }
      max1[2] = Math.min(max1[2] * 0.1 + 0.9, 1);
      return MagicColorUtil.colorPairGenerator(max0, max1);
    } else {
      return [MagicColorUtil.defaultDarkMagicColorPair[0], MagicColorUtil.defaultDarkMagicColorPair[1]];
    }
  }

  /**
   * 偏亮光的黑胶光效偏移（内部实现）
   */
  private static getLightMagicColorPairFromPair(pair: [number | null, number | null]): [number, number] {
    const firstColor = pair[0];
    const secondColor = pair[1];
    if (firstColor !== null && secondColor !== null) {
      const max0 = MagicColorAlgorithm.colorToHsv(firstColor);
      const max1 = MagicColorAlgorithm.colorToHsv(secondColor);
      max0[1] = 0.4; max0[2] = 0.94;
      max1[1] = 0.4; max1[2] = 0.94;
      return MagicColorUtil.colorPairGenerator(max0, max1);
    } else if (firstColor !== null) {
      const max0 = MagicColorAlgorithm.colorToHsv(firstColor);
      max0[1] = 0.4; max0[2] = 0.94;
      const max1 = [max0[0], 0.16, 1];
      return MagicColorUtil.colorPairGenerator(max0, max1);
    } else {
      return [MagicColorUtil.defaultLightMagicColor[0], MagicColorUtil.defaultLightMagicColor[1]];
    }
  }

  /**
   * 偏暗光的黑胶光效偏移（内部实现）
   */
  private static getDarkMagicColorPairFromPair(pair: [number | null, number | null]): [number, number] {
    const firstColor = pair[0];
    const secondColor = pair[1];
    if (firstColor !== null && secondColor !== null) {
      return [firstColor, secondColor];
    } else if (firstColor !== null) {
      const max0 = MagicColorAlgorithm.colorToHsv(firstColor);
      const s1 = max0[1] > 0.6 ? max0[1] - 0.2 : max0[1] < 0.6 ? max0[1] + 0.2 : max0[1];
      const v1 = max0[2] > 0.6 ? max0[2] - 0.2 : max0[2] < 0.6 ? max0[2] + 0.2 : max0[2];
      const max1 = [max0[0], s1, v1];
      return MagicColorUtil.colorPairGenerator(max0, max1);
    } else {
      return [MagicColorUtil.defaultDarkMagicColorPair[0], MagicColorUtil.defaultDarkMagicColorPair[1]];
    }
  }

  /**
   * 默认播放器渐变光效浅色背景下调整后的魔法色
   */
  static getAdjustDefaultPlayerLightMagicColorPair(pair: [number, number]): [number, number] {
    const max0 = MagicColorAlgorithm.colorToHsv(pair[0]);
    const max1 = MagicColorAlgorithm.colorToHsv(pair[1]);
    // h1 和 h2 的偏差不超过 10%，超过后 h2 向 h1 靠拢
    const deltaH = 0.1 * 360;
    const h1 = max0[0];
    let h2 = max1[0];
    if (h2 < h1) h2 += 360;
    if (h2 < h1 + 0.5 * 360) {
      h2 = Math.min(h1 + deltaH, h2);
    } else {
      h2 = Math.max(h2, h1 + 360 - deltaH);
    }
    if (h2 >= 360) h2 -= 360;
    max1[0] = h2;
    max0[1] = Math.min(Math.max(max0[1] + 0.2, 0), 1);
    max0[2] = Math.min(Math.max(max0[2] - 0.04, 0), 1);
    max1[1] = Math.min(Math.max(max1[1] + 0.2, 0), 1);
    max1[2] = Math.min(Math.max(max1[2] - 0.04, 0), 1);
    return MagicColorUtil.colorPairGenerator(max0, max1);
  }

  /**
   * minibar 频谱光效浅色背景下调整后的魔法色
   */
  static getAdjustMinibarSpectrumLightMagicColorPair(pair: [number, number]): [number, number] {
    const max0 = MagicColorAlgorithm.colorToHsv(pair[0]);
    const max1 = MagicColorAlgorithm.colorToHsv(pair[1]);
    max0[1] = 0.3; max0[2] = 0.8;
    max1[1] = 0.3; max1[2] = 0.8;
    return MagicColorUtil.colorPairGenerator(max0, max1);
  }

  /**
   * 对图片进行颜色渲染
   */
  static async getColorRenderedBitmap(
    source: image.PixelMap | null,
    magicColorPair: [number, number] | null,
    bgColor: number | null = null
  ): Promise<image.PixelMap | null> {
    if (source === null) return null;
    if (magicColorPair === null) return source;

    const info = await source.getImageInfo();
    const width = info.size.width;
    const height = info.size.height;
    if (width === 0 || height === 0) return null;

    try {
      const buf = new ArrayBuffer(width * height * 4);
      await source.readPixelsToBuffer(buf);
      const data = new Uint8Array(buf);

      const fromColor = magicColorPair[0];
      const toColor = magicColorPair[1];
      const fromR = (fromColor >> 16) & 0xFF;
      const fromG = (fromColor >> 8) & 0xFF;
      const fromB = fromColor & 0xFF;
      const toR = (toColor >> 16) & 0xFF;
      const toG = (toColor >> 8) & 0xFF;
      const toB = toColor & 0xFF;

      for (let idx = 0; idx < width * height; idx++) {
        const base = idx * 4;
        const srcR = data[base];
        const srcG = data[base + 1];
        const srcB = data[base + 2];
        const alpha = data[base + 3];

        let newR = Math.floor(fromR + (toR - fromR) * srcR / 255);
        let newG = Math.floor(fromG + (toG - fromG) * srcG / 255);
        let newB = Math.floor(fromB + (toB - fromB) * srcB / 255);

        if (bgColor === null) {
          data[base] = newR;
          data[base + 1] = newG;
          data[base + 2] = newB;
          // alpha 不变
        } else {
          const alphaRatio = alpha / 255;
          const bgR = (bgColor >> 16) & 0xFF;
          const bgG = (bgColor >> 8) & 0xFF;
          const bgB = bgColor & 0xFF;
          const bgA = (bgColor >> 24) & 0xFF;
          data[base] = Math.floor(bgR * (1 - alphaRatio) + newR * alphaRatio);
          data[base + 1] = Math.floor(bgG * (1 - alphaRatio) + newG * alphaRatio);
          data[base + 2] = Math.floor(bgB * (1 - alphaRatio) + newB * alphaRatio);
          data[base + 3] = bgA;
        }
      }

      const opts: image.InitializationOptions = {
        size: { width, height },
        pixelFormat: image.PixelMapFormat.RGBA_8888
      };
      return await image.createPixelMap(buf, opts);
    } catch (e) {
      MLog.e('MagicColorUtil', 'getColorRenderedBitmap error: ' + JSON.stringify(e));
    }
    return null;
  }

  static getHSBStr(array: number[]): string {
    return `H = ${array[0]} S = ${array[1]} B = ${array[2]}`;
  }

  static getHSBStrFromColor(color: number): string {
    const array = MagicColorAlgorithm.colorToHsv(color);
    return `H = ${array[0]} S = ${array[1]} B = ${array[2]}`;
  }
}
