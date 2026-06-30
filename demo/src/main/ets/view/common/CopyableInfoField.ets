import { ClipboardUtils } from '../../utils/ClipboardUtils'

/**
 * 可复制信息字段组件
 * 显示 "label: value" 格式的文本，点击 value 部分复制到剪贴板
 *
 * 使用场景：
 * - SongListPage 列表信息卡片中的各个字段
 * - CustomSongListView 信息区域中的各个字段
 * - 任何需要"点击复制"的信息展示场景
 */
@ComponentV2
export struct CopyableInfoField {
  /** 字段标签，如 "歌单ID"、"创建者" 等 */
  @Param label: string = ''
  /** 字段值，点击可复制 */
  @Param value: string = ''
  /** 字体大小，默认 12 */
  @Param fontSize: number = 12
  /** 字体颜色，默认 #666666 */
  @Param fontColor: string = '#666666'
  /** 是否加粗 */
  @Param fontWeight: number = FontWeight.Normal
  /** 最大行数 */
  @Param maxLines: number = 1
  /** 是否显示 label 前缀，默认 true。设为 false 则只显示 value */
  @Param showLabel: boolean = true

  private get displayText(): string {
    if (this.showLabel) {
      return `${this.label}: ${this.value}`
    }
    return this.value
  }

  build() {
    Text(this.displayText)
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .fontWeight(this.fontWeight)
      .maxLines(this.maxLines)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
      .onClick(() => {
        ClipboardUtils.copy(this.value, this.label)
      })
  }
}
