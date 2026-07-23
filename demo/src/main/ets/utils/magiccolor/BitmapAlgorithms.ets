import image from '@ohos.multimedia.image';
import { MLog } from '@qqmusic/opisdk-base';

/**
 * 图片算法工具类
 */
export class BitmapAlgorithms {
  private static readonly TAG: string = 'BitmapAlgorithms';

  /**
   * PixelMap 拉伸与缩放
   */
  static async resizedBitmap(oldBt: image.PixelMap | null, newWidth: number, newHeight: number): Promise<image.PixelMap | null> {
    if (oldBt === null) {
      return null;
    }
    try {
      const info = await oldBt.getImageInfo();
      const width = info.size.width;
      const height = info.size.height;
      const scaleWidth = newWidth / width;
      const scaleHeight = newHeight / height;
      if (scaleWidth === 1 && scaleHeight === 1) {
        return oldBt;
      }
      // 鸿蒙通过 scale 接口缩放，对副本操作，保留原图不变
      const newPixelMap = await BitmapAlgorithms.copyPixelMap(oldBt);
      if (newPixelMap === null) {
        return null;
      }
      await newPixelMap.scale(scaleWidth, scaleHeight);
      return newPixelMap;
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'resizedBitmap error: ' + JSON.stringify(e));
    }
    return null;
  }

  /**
   * 图片裁剪
   */
  static async getResizedBitmap(
    originalImage: image.PixelMap | null,
    x: number, y: number,
    width: number, height: number
  ): Promise<image.PixelMap | null> {
    if (originalImage === null) {
      return null;
    }
    try {
      const info = await originalImage.getImageInfo();
      const originWidth = info.size.width;
      const originHeight = info.size.height;
      if (x >= 0 && y >= 0 && width > 0 && height > 0
        && x + width <= originWidth && y + height <= originHeight) {
        const newPixelMap = await BitmapAlgorithms.copyPixelMap(originalImage);
        if (newPixelMap === null) {
          return null;
        }
        await newPixelMap.crop({ x, y, size: { width, height } });
        return newPixelMap;
      }
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'getResizedBitmap error: ' + JSON.stringify(e));
    }
    return null;
  }

  /**
   * 针对歌单/专辑页面头图中间部分的图片处理（边缘透明）
   */
  static async billCenterAlbum(bitmap0: image.PixelMap | null, height: number): Promise<image.PixelMap | null> {
    if (bitmap0 === null || height <= 0) {
      return null;
    }
    try {
      const info = await bitmap0.getImageInfo();
      const wd0 = info.size.width;
      const hi0 = info.size.height;
      let hi1 = hi0;
      while (hi1 < height) {
        hi1 += (hi0 >> 1);
      }
      const scaleHeight = hi1 / hi0;
      const newH = Math.floor(hi0 * height / hi1);
      const cropY = (hi0 - newH) >> 1;
      // 先裁剪
      const bitmap1 = await BitmapAlgorithms.getResizedBitmap(bitmap0, 0, cropY, wd0, newH);
      if (bitmap1 === null) {
        return null;
      }
      // 再缩放
      await bitmap1.scale(scaleHeight, scaleHeight);
      // 边缘透明处理
      const bitmap2 = await BitmapAlgorithms.blurEdge(bitmap1);
      bitmap1.release();
      return bitmap2;
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'billCenterAlbum error: ' + JSON.stringify(e));
    }
    return null;
  }

  /**
   * 边缘透明处理（私有）
   */
  private static async blurEdge(bitmap0: image.PixelMap): Promise<image.PixelMap | null> {
    try {
      const info = await bitmap0.getImageInfo();
      const w0 = info.size.width;
      const h0 = info.size.height;
      const buf = new ArrayBuffer(w0 * h0 * 4);
      await bitmap0.readPixelsToBuffer(buf);
      const pixels = new Int32Array(buf);
      const arfWidth = Math.floor(w0 / 8);
      // arfWidth <= 1 时无需渐变（宽度太小），直接返回原图
      if (arfWidth <= 1) {
        const opts0: image.InitializationOptions = {
          size: { width: w0, height: h0 },
          pixelFormat: image.PixelMapFormat.RGBA_8888
        };
        return await image.createPixelMap(buf, opts0);
      }
      const f = 255 / (arfWidth - 1);
      for (let j = 0; j < w0; j++) {
        let b = false;
        let bfb = 0;
        if (j < arfWidth) {
          bfb = Math.floor(j * f);
          b = true;
        } else if (j >= (w0 - arfWidth)) {
          bfb = Math.floor((w0 - 1 - j) * f);
          b = true;
        }
        if (b) {
          for (let i = 0; i < h0; i++) {
            const idx = i * w0 + j;
            const pixColor = pixels[idx];
            const alf = (pixColor >>> 24) & 0xFF;
            const pixR = (pixColor >> 16) & 0xFF;
            const pixG = (pixColor >> 8) & 0xFF;
            const pixB = pixColor & 0xFF;
            const newAlf = Math.floor(alf * bfb / 255);
            pixels[idx] = (newAlf << 24) | (pixR << 16) | (pixG << 8) | pixB;
          }
        }
      }
      const opts: image.InitializationOptions = {
        size: { width: w0, height: h0 },
        pixelFormat: image.PixelMapFormat.RGBA_8888
      };
      const result = await image.createPixelMap(buf, opts);
      return result;
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'blurEdge error: ' + JSON.stringify(e));
    }
    return null;
  }

  /**
   * 针对歌单/专辑页面头图背景部分的图片处理
   */
  static async billAlbumBGBlur(bitmap0: image.PixelMap | null, width: number, height: number): Promise<image.PixelMap | null> {
    try {
      if (bitmap0 === null || height <= 0 || width <= 0) {
        return null;
      }
      const soo = 4;
      width = Math.floor(width / soo);
      height = Math.floor(height / soo);
      const info = await bitmap0.getImageInfo();
      const wd0 = info.size.width;
      const hi0 = info.size.height;
      let hi1 = hi0;
      while (hi1 < height) {
        hi1 += (hi0 >> 1);
      }
      const scaleWidth = width / wd0;
      const scaleHeight = hi1 / hi0;
      const newH = Math.floor(hi0 * height / hi1);
      const cropY = (hi0 - newH) >> 1;
      const bitmap1 = await BitmapAlgorithms.getResizedBitmap(bitmap0, 0, cropY, wd0, newH);
      if (bitmap1 === null) {
        return null;
      }
      await bitmap1.scale(scaleWidth, scaleHeight);
      const b1Info = await bitmap1.getImageInfo();
      const bitmap2 = await BitmapAlgorithms.blurAlbumAmeliorate(bitmap1, b1Info.size.width, b1Info.size.height);
      bitmap1.release();
      return bitmap2;
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'billAlbumBGBlur error: ' + JSON.stringify(e));
    }
    return null;
  }

  static async blurAlbumAmeliorateWithRadius(
    bitmap0: image.PixelMap | null,
    wid: number, hei: number,
    hRadius: number, wRadius: number
  ): Promise<image.PixelMap | null> {
    if (bitmap0 === null) {
      return null;
    }
    try {
      const bitmap1 = await BitmapAlgorithms.resizedBitmap(bitmap0, wid, hei);
      const bitmap2 = await BitmapAlgorithms.boxBlurFilter(bitmap1, 3, hRadius, wRadius);
      if (bitmap1 !== null && bitmap1 !== bitmap0) {
        bitmap1.release();
      }
      if (bitmap2 === null) {
        return null;
      }
      const b2Info = await bitmap2.getImageInfo();
      const j = 0.03;
      const jw = Math.floor(j * b2Info.size.width);
      const jh = Math.floor(j * b2Info.size.height);
      if (jh > 0) {
        const bitmap3 = await BitmapAlgorithms.getResizedBitmap(
          bitmap2, jw, jh,
          b2Info.size.width - (jw << 1),
          b2Info.size.height - (jh << 1)
        );
        bitmap2.release();
        return bitmap3;
      } else {
        return bitmap2;
      }
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'blurAlbumAmeliorateWithRadius error: ' + JSON.stringify(e));
    }
    return null;
  }

  static async blurAlbumAmeliorate(bitmap0: image.PixelMap | null, wid: number, hei: number): Promise<image.PixelMap | null> {
    return BitmapAlgorithms.blurAlbumAmeliorateWithRadius(bitmap0, wid, hei, 5, 5);
  }

  /**
   * 假高斯模糊（矩形采样，无白边）
   * o：采样半径（像素），采样矩形 r = 2*o+1
   */
  static async blur2D(bmp: image.PixelMap | null, o: number): Promise<image.PixelMap | null> {
    if (bmp === null) {
      return null;
    }
    try {
      const info = await bmp.getImageInfo();
      const width = info.size.width;
      const height = info.size.height;
      const buf = new ArrayBuffer(width * height * 4);
      await bmp.readPixelsToBuffer(buf);
      const pixels = new Int32Array(buf);
      const pixelsResult = new Int32Array(width * height);
      if (o < 1) {
        o = 1;
      }
      const st = 1 - o;
      const ed = o - 1;

      for (let i = 0; i < height; i++) {
        let tmpLeftDelta = 0;
        let tmpLeftR = 0;
        let tmpLeftG = 0;
        let tmpLeftB = 0;
        let lastWidthSumDelta = 0;
        let lastWidthSumR = 0;
        let lastWidthSumG = 0;
        let lastWidthSumB = 0;
        let newR = 0, newG = 0, newB = 0, delta = 0;

        for (let k = 0; k < width; k++) {
          if (k === 0) {
            for (let n = st; n <= ed; n++) {
              for (let m = st; m <= ed; m++) {
                if ((i + m) >= 0 && (i + m) < height && (k + n) >= 0 && (k + n) < width) {
                  const pixColor = pixels[(i + m) * width + k + n];
                  const pixR = (pixColor >> 16) & 0xFF;
                  const pixG = (pixColor >> 8) & 0xFF;
                  const pixB = pixColor & 0xFF;
                  newR += pixR;
                  newG += pixG;
                  newB += pixB;
                  delta++;
                  if (n === st) {
                    tmpLeftR += pixR;
                    tmpLeftG += pixG;
                    tmpLeftB += pixB;
                    tmpLeftDelta++;
                  }
                }
              }
            }
          } else {
            let tmpLeftDelta2 = 0, tmpLeftR2 = 0, tmpLeftG2 = 0, tmpLeftB2 = 0;
            for (let n = st; n <= ed; n += (ed - st)) {
              for (let m = st; m <= ed; m++) {
                if ((i + m) >= 0 && (i + m) < height && (k + n) >= 0 && (k + n) < width) {
                  const pixColor = pixels[(i + m) * width + k + n];
                  const pixR = (pixColor >> 16) & 0xFF;
                  const pixG = (pixColor >> 8) & 0xFF;
                  const pixB = pixColor & 0xFF;
                  if (n === ed) {
                    newR += pixR;
                    newG += pixG;
                    newB += pixB;
                    delta++;
                  } else if (n === st) {
                    tmpLeftR2 += pixR;
                    tmpLeftG2 += pixG;
                    tmpLeftB2 += pixB;
                    tmpLeftDelta2++;
                  }
                }
              }
            }
            newR += lastWidthSumR;
            newG += lastWidthSumG;
            newB += lastWidthSumB;
            delta += lastWidthSumDelta;
            newR -= tmpLeftR;
            newG -= tmpLeftG;
            newB -= tmpLeftB;
            delta -= tmpLeftDelta;
            tmpLeftR = tmpLeftR2;
            tmpLeftG = tmpLeftG2;
            tmpLeftB = tmpLeftB2;
            tmpLeftDelta = tmpLeftDelta2;
          }
          lastWidthSumR = newR;
          lastWidthSumG = newG;
          lastWidthSumB = newB;
          lastWidthSumDelta = delta;
          if (delta === 0) {
            delta = 1;
          }
          newR = Math.floor(newR / delta);
          newG = Math.floor(newG / delta);
          newB = Math.floor(newB / delta);
          newR = Math.min(255, Math.max(0, newR));
          newG = Math.min(255, Math.max(0, newG));
          newB = Math.min(255, Math.max(0, newB));
          pixelsResult[i * width + k] = (255 << 24) | (newR << 16) | (newG << 8) | newB;
          newR = 0;
          newG = 0;
          newB = 0;
          delta = 0;
        }
      }

      const resultBuf = new ArrayBuffer(width * height * 4);
      new Int32Array(resultBuf).set(pixelsResult);
      const opts: image.InitializationOptions = {
        size: { width, height },
        pixelFormat: image.PixelMapFormat.RGBA_8888
      };
      return await image.createPixelMap(resultBuf, opts);
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'blur2D error: ' + JSON.stringify(e));
    }
    return null;
  }

  /**
   * Box 模糊滤镜
   * iterations：迭代次数，hRadius：横向模糊度，vRadius：纵向模糊度
   */
  static async boxBlurFilter(
    bmp: image.PixelMap | null,
    iterations: number,
    hRadius: number,
    vRadius: number
  ): Promise<image.PixelMap | null> {
    if (bmp === null) {
      return null;
    }
    try {
      const info = await bmp.getImageInfo();
      const width = info.size.width;
      const height = info.size.height;
      const buf = new ArrayBuffer(width * height * 4);
      await bmp.readPixelsToBuffer(buf);
      let inPixels = new Int32Array(buf);
      let outPixels = new Int32Array(width * height);

      for (let i = 0; i < iterations; i++) {
        BitmapAlgorithms.blur(inPixels, outPixels, width, height, hRadius);
        BitmapAlgorithms.blur(outPixels, inPixels, height, width, vRadius);
      }
      BitmapAlgorithms.blurFractional(inPixels, outPixels, width, height, hRadius);
      BitmapAlgorithms.blurFractional(outPixels, inPixels, height, width, vRadius);

      const resultBuf = new ArrayBuffer(width * height * 4);
      new Int32Array(resultBuf).set(inPixels);
      const opts: image.InitializationOptions = {
        size: { width, height },
        pixelFormat: image.PixelMapFormat.RGBA_8888
      };
      return await image.createPixelMap(resultBuf, opts);
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'boxBlurFilter error: ' + JSON.stringify(e));
    }
    return null;
  }

  private static blurFractional(
    inArr: Int32Array, outArr: Int32Array,
    width: number, height: number, radius: number
  ): void {
    radius -= Math.floor(radius);
    const f = 1.0 / (1 + 2 * radius);
    let inIndex = 0;
    for (let y = 0; y < height; y++) {
      let outIndex = y;
      outArr[outIndex] = inArr[0];
      outIndex += height;
      for (let x = 1; x < width - 1; x++) {
        const i = inIndex + x;
        const rgb1 = inArr[i - 1];
        const rgb2 = inArr[i];
        const rgb3 = inArr[i + 1];
        let a1 = (rgb1 >> 24) & 0xFF, r1 = (rgb1 >> 16) & 0xFF, g1 = (rgb1 >> 8) & 0xFF, b1 = rgb1 & 0xFF;
        const a2 = (rgb2 >> 24) & 0xFF, r2 = (rgb2 >> 16) & 0xFF, g2 = (rgb2 >> 8) & 0xFF, b2 = rgb2 & 0xFF;
        const a3 = (rgb3 >> 24) & 0xFF, r3 = (rgb3 >> 16) & 0xFF, g3 = (rgb3 >> 8) & 0xFF, b3 = rgb3 & 0xFF;
        a1 = Math.floor((a2 + (a1 + a3) * radius) * f);
        r1 = Math.floor((r2 + (r1 + r3) * radius) * f);
        g1 = Math.floor((g2 + (g1 + g3) * radius) * f);
        b1 = Math.floor((b2 + (b1 + b3) * radius) * f);
        outArr[outIndex] = (a1 << 24) | (r1 << 16) | (g1 << 8) | b1;
        outIndex += height;
      }
      outArr[outIndex] = inArr[width - 1];
      inIndex += width;
    }
  }

  private static blur(
    inArr: Int32Array, outArr: Int32Array,
    width: number, height: number, radius: number
  ): void {
    const widthMinus1 = width - 1;
    const r = Math.floor(radius);
    const tableSize = 2 * r + 1;
    const divide = new Int32Array(256 * tableSize);
    for (let i = 0; i < 256 * tableSize; i++) {
      divide[i] = Math.floor(i / tableSize);
    }
    let inIndex = 0;
    for (let y = 0; y < height; y++) {
      let outIndex = y;
      let ta = 0, tr = 0, tg = 0, tb = 0;
      for (let i = -r; i <= r; i++) {
        const rgb = inArr[inIndex + BitmapAlgorithms.clamp(i, 0, width - 1)];
        ta += (rgb >> 24) & 0xFF;
        tr += (rgb >> 16) & 0xFF;
        tg += (rgb >> 8) & 0xFF;
        tb += rgb & 0xFF;
      }
      for (let x = 0; x < width; x++) {
        outArr[outIndex] = (divide[ta] << 24) | (divide[tr] << 16) | (divide[tg] << 8) | divide[tb];
        let i1 = x + r + 1;
        if (i1 > widthMinus1) {
          i1 = widthMinus1;
        }
        let i2 = x - r;
        if (i2 < 0) {
          i2 = 0;
        }
        const rgb1 = inArr[inIndex + i1];
        const rgb2 = inArr[inIndex + i2];
        ta += ((rgb1 >> 24) & 0xFF) - ((rgb2 >> 24) & 0xFF);
        tr += ((rgb1 & 0xFF0000) - (rgb2 & 0xFF0000)) >> 16;
        tg += ((rgb1 & 0xFF00) - (rgb2 & 0xFF00)) >> 8;
        tb += (rgb1 & 0xFF) - (rgb2 & 0xFF);
        outIndex += height;
      }
      inIndex += width;
    }
  }

  private static clamp(x: number, a: number, b: number): number {
    return x < a ? a : x > b ? b : x;
  }

  /**
   * 将 readPixelsToBuffer 读出的 BGRA 字节序转换为 createPixelMap(RGBA_8888) 期望的 RGBA 字节序
   * （原地交换每个像素的 R/B 通道）
   */
  static swapRB(buf: ArrayBuffer): void {
    const data = new Uint8Array(buf);
    for (let i = 0; i < data.length; i += 4) {
      const tmp = data[i]; // B
      data[i] = data[i + 2]; // 位置0 = R
      data[i + 2] = tmp; // 位置2 = B
    }
  }

  /**
   * 深拷贝一个 PixelMap（鸿蒙无法直接修改原图，需要先复制）
   * 注意：readPixelsToBuffer 输出的字节序为 BGRA，而 createPixelMap(RGBA_8888) 期望 RGBA，
   * 因此需要手动交换 R/B 通道，保证颜色正确。
   */
  private static async copyPixelMap(src: image.PixelMap): Promise<image.PixelMap | null> {
    try {
      const info = await src.getImageInfo();
      const buf = new ArrayBuffer(src.getPixelBytesNumber());
      await src.readPixelsToBuffer(buf);
      // readPixelsToBuffer 输出 BGRA，createPixelMap(RGBA_8888) 期望 RGBA，交换 R/B 通道
      BitmapAlgorithms.swapRB(buf);
      const opts: image.InitializationOptions = {
        editable: true,
        size: info.size,
        pixelFormat: image.PixelMapFormat.RGBA_8888
      };
      return await image.createPixelMap(buf, opts);
    } catch (e) {
      MLog.e(BitmapAlgorithms.TAG, 'copyPixelMap error: ' + JSON.stringify(e));
    }
    return null;
  }
}
