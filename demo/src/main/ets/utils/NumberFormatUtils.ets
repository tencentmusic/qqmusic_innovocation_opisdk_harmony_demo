/**
 * 数字格式化工具类
 *
 * - 小于 1 万：直接显示原数字
 * - 1 万 ~ 1 亿：显示为 X万 或 X.X万
 * - 1 亿 ~ 1 万亿：显示为 X亿 或 X.X亿
 * - 大于等于 1 万亿：显示为 X万亿 或 X.X万亿
 */
export class NumberFormatUtils {
  /**
   * 格式化数字为中文计数单位
   * @param number 要格式化的数字，可为 null/undefined
   * @returns 格式化后的字符串，如 "123"、"1.2万"、"3.5亿"
   */
  static formatNumber(number: number | null | undefined): string {
    if (number === null || number === undefined) {
      return '0'
    }
    const num = number as number
    if (num < 10000) {
      return num.toString()
    } else if (num < 100000000) {
      return NumberFormatUtils.format(num, 10000, '万')
    } else if (num < 1000000000000) {
      return NumberFormatUtils.format(num, 100000000, '亿')
    } else {
      return NumberFormatUtils.format(num, 1000000000000, '万亿')
    }
  }

  /**
   * 内部格式化方法
   * @param num 原始数字
   * @param divisor 除数（10000 / 1亿 / 1万亿）
   * @param suffix 后缀（万 / 亿 / 万亿）
   * @returns 格式化后的字符串
   */
  private static format(num: number, divisor: number, suffix: string): string {
    const divided = num / divisor
    // 判断是否为整数（除以除数后没有小数部分）
    if (divided % 1 === 0) {
      return `${Math.floor(divided)}${suffix}`
    } else {
      // 保留一位小数
      return `${divided.toFixed(1)}${suffix}`
    }
  }
}
