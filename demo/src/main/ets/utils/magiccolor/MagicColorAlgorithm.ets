import image from '@ohos.multimedia.image';

/**
 * 魔法色核心算法
 */
export class MagicColorAlgorithm {
  static readonly S_DISTANCE_BEST: number = 0.6;
  static readonly B_DISTANCE_BEST: number = 0.6;
  static readonly NONE_ALPHA: number = 0xFF; // 100% 不透明

  static readonly defaultColor: number = MagicColorAlgorithm.hsvToColor(0xFF, [0, 0, 0.25]);

  // S(饱和度) / B(明度) 最接近 0.6
  static distance(hsv: number[]): number {
    return Math.sqrt(
      (hsv[1] - MagicColorAlgorithm.S_DISTANCE_BEST) * (hsv[1] - MagicColorAlgorithm.S_DISTANCE_BEST) +
        (hsv[2] - MagicColorAlgorithm.B_DISTANCE_BEST) * (hsv[2] - MagicColorAlgorithm.B_DISTANCE_BEST)
    );
  }

  static calculate(value: number): number {
    return 0.2 * value + 0.5;
  }

  static async generateMagicColorNotNull(source: image.PixelMap | null, alpha: number = MagicColorAlgorithm.NONE_ALPHA): Promise<number> {
    return (await MagicColorAlgorithm.generateMagicColor(source, alpha, MagicColorAlgorithm.defaultColor))!;
  }

  /**
   * 根据排名第一的色相组生成对应魔法色
   */
  static async generateMagicColor(
    source: image.PixelMap | null,
    alpha: number = MagicColorAlgorithm.NONE_ALPHA,
    defaultColor: number | null
  ): Promise<number | null> {
    if (source === null) {
      return defaultColor;
    }
    const hueValues = await MagicColorAlgorithm.getHueGroup(source);
    if (hueValues[0].length > 0) {
      const hsb = hueValues[0].reduce((min, cur) =>
      MagicColorAlgorithm.distance(cur) < MagicColorAlgorithm.distance(min) ? cur : min
      );
      if (hsb) {
        MagicColorAlgorithm.changeColorSB(hsb);
        return MagicColorAlgorithm.hsvToColor(alpha, hsb);
      }
    }
    return defaultColor;
  }

  /**
   * 根据排名前二的色相组生成对应魔法色
   */
  static async generateMultiMagicColor(
    source: image.PixelMap | null,
    alpha: number = MagicColorAlgorithm.NONE_ALPHA
  ): Promise<[number | null, number | null]> {
    if (source === null) {
      return [null, null];
    }
    const hueValues = await MagicColorAlgorithm.getHueGroup(source);
    if (hueValues[0].length > 0 && hueValues[1].length > 0) {
      // 获得色相数组中第一色相和第二色相中最接近饱和度和明度中心点 0.6 和 0.6 的颜色
      const max0 = hueValues[0].reduce((min, cur) =>
      MagicColorAlgorithm.distance(cur) < MagicColorAlgorithm.distance(min) ? cur : min
      );
      const max1 = hueValues[1].reduce((min, cur) =>
      MagicColorAlgorithm.distance(cur) < MagicColorAlgorithm.distance(min) ? cur : min
      );
      MagicColorAlgorithm.changeColorSB(max0);
      MagicColorAlgorithm.changeColorSB(max1);
      return [
        MagicColorAlgorithm.hsvToColor(alpha, max0),
        MagicColorAlgorithm.hsvToColor(alpha, max1)
      ];
    } else if (hueValues[0].length > 0) {
      // 只有一个色相
      const max0 = hueValues[0].reduce((min, cur) =>
      MagicColorAlgorithm.distance(cur) < MagicColorAlgorithm.distance(min) ? cur : min
      );
      if (max0) {
        MagicColorAlgorithm.changeColorSB(max0);
        return [MagicColorAlgorithm.hsvToColor(alpha, max0), null];
      }
    }
    return [null, null];
  }

  private static changeColorSB(max0: number[] | null): void {
    if (max0 === null) {
      return;
    }
    // 通过 S = 0.2 * s + 0.5 的方式将数值映射到 0.5～0.7
    max0[1] = Math.min(MagicColorAlgorithm.calculate(max0[1]), 0.7);
    max0[1] = Math.max(max0[1], 0.5);
    // 通过 B = 0.2 * B + 0.5 的方式将数值映射到 0.5～0.7
    max0[2] = Math.min(MagicColorAlgorithm.calculate(max0[2]), 0.7);
    max0[2] = Math.max(max0[2], 0.5);
  }

  /**
   * 生成色相组（按数量降序排列）
   */
  static async getHueGroup(source: image.PixelMap): Promise<number[][][]> {
    const hueValues: number[][][] = [[], [], [], [], [], [], [], []];
    const info = await source.getImageInfo();
    const width = info.size.width;
    const height = info.size.height;
    const buf = new ArrayBuffer(width * height * 4);
    await source.readPixelsToBuffer(buf);
    const data = new Uint8Array(buf);

    for (let j = 0; j < height; j++) {
      const rowBase = j * width * 4;
      for (let i = 0; i < width; i++) {
        const offset = rowBase + i * 4;
        const r = data[offset];
        const g = data[offset + 1];
        const b = data[offset + 2];
        // data[offset + 3] 是 alpha，此处不使用
        const hsv = MagicColorAlgorithm.rgbToHsv(r, g, b);
        if (hsv[1] >= 0.12 && hsv[2] >= 0.18) { // 有色系（无色系 S<0.12 || B<0.18）
          const hue = hsv[0] / 360;
          if (hue < 0.06) { // 红色 (1-20)
            hueValues[0].push(hsv);
          } else if (hue < 0.11) { // 橙色 (21-40)
            hueValues[1].push(hsv);
          } else if (hue < 0.21) { // 黄色 (41-75)
            hueValues[2].push(hsv);
          } else if (hue < 0.43) { // 绿色 (76-155)
            hueValues[3].push(hsv);
          } else if (hue < 0.53) { // 蓝绿色 (156-190)
            hueValues[4].push(hsv);
          } else if (hue < 0.71) { // 蓝色 (191-256)
            hueValues[5].push(hsv);
          } else if (hue < 0.82) { // 紫蓝色 (257-295)
            hueValues[6].push(hsv);
          } else if (hue < 0.91) { // 紫红色 (296-329)
            hueValues[7].push(hsv);
          } else { // 红色 (330-360)
            hueValues[0].push(hsv);
          }
        }
      }
    }
    // 按数量降序排列
    hueValues.sort((a, b) => b.length - a.length);
    return hueValues;
  }

  /**
   * 根据排名前二的色相组生成对应魔法色
   */
  static async generateMultiMagicColorDefined(
    source: image.PixelMap | null,
    alpha: number = MagicColorAlgorithm.NONE_ALPHA
  ): Promise<[number | null, number | null]> {
    if (source === null) {
      return [null, null];
    }
    const hueValues = await MagicColorAlgorithm.getHueGroupDefined(source);
    if (hueValues[0].length > 0 && hueValues[1].length > 0) {
      const max0 = MagicColorAlgorithm.generateFinalColorDefined(hueValues[0]);
      const max1 = MagicColorAlgorithm.generateFinalColorDefined(hueValues[1]);
      return [
        MagicColorAlgorithm.hsvToColor(alpha, max0),
        MagicColorAlgorithm.hsvToColor(alpha, max1)
      ];
    } else if (hueValues[0].length > 0) {
      const max0 = MagicColorAlgorithm.generateFinalColorDefined(hueValues[0]);
      if (max0 !== null) {
        return [MagicColorAlgorithm.hsvToColor(alpha, max0), null];
      }
    }
    return [null, null];
  }

  private static generateFinalColorDefined(list: number[][]): number[] | null {
    if (list.length === 0) {
      return null;
    }
    const finalHsv = [0, 0, 0];
    const color = list[0];
    if (
      MagicColorAlgorithm.isWhite(color) || MagicColorAlgorithm.isBlack(color) ||
        MagicColorAlgorithm.isGray(color) || MagicColorAlgorithm.isDarkGray(color) ||
        MagicColorAlgorithm.isLightGray(color)
    ) {
      const countMap = new Map<number, number>();
      let maxCount = 0;
      let mostRepeatedH: number | null = null;
      let countS = 0, countV = 0;
      for (const array of list) {
        countS += array[1];
        countV += array[2];
        const key = array[0];
        const num = countMap.get(key) ?? 0;
        const count = num + 1;
        countMap.set(key, count);
        if (count > maxCount) {
          maxCount = count;
          mostRepeatedH = key;
        }
      }
      if (mostRepeatedH !== null) {
        finalHsv[0] = mostRepeatedH;
        finalHsv[1] = countS / list.length;
        finalHsv[2] = countV / list.length;
        return finalHsv;
      }
      return null;
    } else if (MagicColorAlgorithm.isRed(color)) {
      let countH = 0, countS = 0, countV = 0;
      let hasHighInterval = false, hasLowInterval = false, needAdd360 = false;
      for (const array of list) {
        if (array[0] >= 330 && array[0] <= 360) {
          hasHighInterval = true;
          if (hasLowInterval) {
            break;
          }
        } else {
          hasLowInterval = true;
          if (hasHighInterval) {
            break;
          }
        }
      }
      if (hasLowInterval && hasHighInterval) {
        needAdd360 = true;
      }
      for (const array of list) {
        countH += (array[0] >= 330 && array[0] <= 360)
          ? array[0]
          : (needAdd360 ? array[0] + 360 : array[0]);
        countS += array[1];
        countV += array[2];
      }
      finalHsv[0] = countH / list.length;
      finalHsv[1] = countS / list.length;
      finalHsv[2] = countV / list.length;
      return finalHsv;
    } else {
      let countH = 0, countS = 0, countV = 0;
      for (const array of list) {
        countH += array[0];
        countS += array[1];
        countV += array[2];
      }
      finalHsv[0] = countH / list.length;
      finalHsv[1] = countS / list.length;
      finalHsv[2] = countV / list.length;
      return finalHsv;
    }
  }

  /**
   * 生成精细色相组（13组，含无彩色）
   */
  static async getHueGroupDefined(source: image.PixelMap): Promise<number[][][]> {
    const hueValues: number[][][] = [[], [], [], [], [], [], [], [], [], [], [], [], []];
    const info = await source.getImageInfo();
    const width = info.size.width;
    const height = info.size.height;
    const buf = new ArrayBuffer(width * height * 4);
    await source.readPixelsToBuffer(buf);
    const data = new Uint8Array(buf);

    for (let j = 0; j < height; j++) {
      const rowBase = j * width * 4;
      for (let i = 0; i < width; i++) {
        const offset = rowBase + i * 4;
        const r = data[offset];
        const g = data[offset + 1];
        const b = data[offset + 2];
        const hsv = MagicColorAlgorithm.rgbToHsv(r, g, b);

        if (MagicColorAlgorithm.isWhite(hsv)) {
          hueValues[0].push(hsv);
        } else if (MagicColorAlgorithm.isLightGray(hsv)) {
          hueValues[1].push(hsv);
        } else if (MagicColorAlgorithm.isGray(hsv)) {
          hueValues[2].push(hsv);
        } else if (MagicColorAlgorithm.isDarkGray(hsv)) {
          hueValues[3].push(hsv);
        } else if (MagicColorAlgorithm.isBlack(hsv)) {
          hueValues[4].push(hsv);
        } else if (MagicColorAlgorithm.isRed(hsv)) {
          hueValues[5].push(hsv);
        } else if (hsv[0] >= 20 && hsv[0] <= 40 && hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1) {
          hueValues[6].push(hsv); // 橙色
        } else if (hsv[0] >= 40 && hsv[0] <= 75 && hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1) {
          hueValues[7].push(hsv); // 黄色
        } else if (hsv[0] >= 75 && hsv[0] <= 155 && hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1) {
          hueValues[8].push(hsv); // 绿色
        } else if (hsv[0] >= 155 && hsv[0] <= 190 && hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1) {
          hueValues[9].push(hsv); // 绿蓝色
        } else if (hsv[0] >= 190 && hsv[0] <= 256 && hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1) {
          hueValues[10].push(hsv); // 蓝色
        } else if (hsv[0] >= 256 && hsv[0] <= 295 && hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1) {
          hueValues[11].push(hsv); // 蓝紫色
        } else if (hsv[0] >= 295 && hsv[0] <= 330 && hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1) {
          hueValues[12].push(hsv); // 紫红色
        }
      }
    }
    hueValues.sort((a, b) => b.length - a.length);
    return hueValues;
  }


  static isBlack(hsv: number[]): boolean {
    return hsv[2] >= 0 && hsv[2] <= 0.1;
  }

  static isDarkGray(hsv: number[]): boolean {
    return hsv[1] <= 0.05 && hsv[2] < 0.25 && hsv[2] > 0.1;
  }

  static isGray(hsv: number[]): boolean {
    return hsv[1] <= 0.05 && hsv[2] < 0.5 && hsv[2] >= 0.25;
  }

  static isLightGray(hsv: number[]): boolean {
    return hsv[1] <= 0.05 && hsv[2] < 0.75 && hsv[2] >= 0.5;
  }

  static isWhite(hsv: number[]): boolean {
    return hsv[1] <= 0.05 && hsv[2] >= 0.75;
  }

  static isRed(hsv: number[]): boolean {
    return ((hsv[0] >= 0 && hsv[0] <= 20) || (hsv[0] >= 330 && hsv[0] <= 360)) &&
      hsv[1] >= 0.06 && hsv[2] >= 0.1 && hsv[2] <= 1;
  }


  /**
   * HSV 转 ARGB 整数颜色值
   * hsv[0]: H(0~360), hsv[1]: S(0~1), hsv[2]: V(0~1)
   */
  static hsvToColor(alpha: number, hsv: number[] | null): number {
    if (!hsv) {
      return 0;
    }
    const h = hsv[0], s = hsv[1], v = hsv[2];
    let r = 0, g = 0, b = 0;
    if (s === 0) {
      r = g = b = Math.round(v * 255);
    } else {
      const sector = h / 60;
      const i = Math.floor(sector);
      const f = sector - i;
      const p = v * (1 - s);
      const q = v * (1 - s * f);
      const t = v * (1 - s * (1 - f));
      switch (i % 6) {
        case 0:
          r = v;
          g = t;
          b = p;
          break;
        case 1:
          r = q;
          g = v;
          b = p;
          break;
        case 2:
          r = p;
          g = v;
          b = t;
          break;
        case 3:
          r = p;
          g = q;
          b = v;
          break;
        case 4:
          r = t;
          g = p;
          b = v;
          break;
        case 5:
          r = v;
          g = p;
          b = q;
          break;
      }
      r = Math.round(r * 255);
      g = Math.round(g * 255);
      b = Math.round(b * 255);
    }
    // 返回 ARGB 整数（高位 alpha）
    return ((alpha & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
  }

  /**
   * ARGB 整数颜色值转 HSV 数组
   * 返回 [H(0~360), S(0~1), V(0~1)]
   */
  static colorToHsv(color: number): number[] {
    const r = (color >> 16) & 0xFF;
    const g = (color >> 8) & 0xFF;
    const b = color & 0xFF;
    return MagicColorAlgorithm.rgbToHsv(r, g, b);
  }

  /**
   * RGB(0~255) 转 HSV 数组 [H(0~360), S(0~1), V(0~1)]
   */
  static rgbToHsv(r: number, g: number, b: number): number[] {
    const rf = r / 255, gf = g / 255, bf = b / 255;
    const max = Math.max(rf, gf, bf);
    const min = Math.min(rf, gf, bf);
    const d = max - min;
    let h = 0;
    const s = max === 0 ? 0 : d / max;
    const v = max;
    if (d !== 0) {
      if (max === rf) {
        h = ((gf - bf) / d + (gf < bf ? 6 : 0)) * 60;
      } else if (max === gf) {
        h = ((bf - rf) / d + 2) * 60;
      } else {
        h = ((rf - gf) / d + 4) * 60;
      }
    }
    return [h, s, v];
  }

  /**
   * 将 ARGB 整数颜色值转为 ArkUI rgba 字符串
   * @param argb ARGB 整数（高位为 alpha）
   * @param alphaOverride 可选，覆盖 alpha（0~1）
   */
  static argbToRgba(argb: number, alphaOverride?: number): string {
    const r = (argb >> 16) & 0xFF;
    const g = (argb >> 8) & 0xFF;
    const b = argb & 0xFF;
    const a = alphaOverride !== undefined ? alphaOverride : (((argb >> 24) & 0xFF) / 255);
    return `rgba(${r}, ${g}, ${b}, ${a.toFixed(2)})`;
  }
}
