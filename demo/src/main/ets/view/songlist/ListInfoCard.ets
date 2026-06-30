import { SongListViewModel } from '../../viewmodel/songlist/SongListViewModel'
import { MusicListType } from '@qqmusic/opisdk-qmutils'
import { CopyableInfoField } from '../common/CopyableInfoField'
import { NumberFormatUtils } from '../../utils/NumberFormatUtils'

/**
 * 列表信息卡片组件
 * 根据 playListType 展示专辑/歌单/榜单/歌手的详情信息
 * 封面在左，信息字段在右（横排布局）
 *
 * 使用 CopyableInfoField 渲染每个可复制字段
 */
@ComponentV2
export struct ListInfoCard {
  @Consumer('viewModel') viewModel: SongListViewModel = new SongListViewModel()

  /** 封面图宽度 */
  private readonly coverSize: number = 120

  /** 歌单描述是否展开全部 */
  @Local isFolderDescExpanded: boolean = false
  /** 榜单描述是否展开全部 */
  @Local isRankDescExpanded: boolean = false
  /** 歌手简介是否展开全部（含 basicInfo / groupListInfo / desc / otherInfo） */
  @Local isSingerWikiExpanded: boolean = false

  private get showCard(): boolean {
    if (this.viewModel.playListType === MusicListType.TYPE_FOLDER) {
      return this.viewModel.folder !== null
    } else if (this.viewModel.playListType === MusicListType.TYPE_ONLINE) {
      return this.viewModel.rankDetail !== null
    } else if (this.viewModel.playListType === MusicListType.TYPE_SINGER) {
      return this.viewModel.singerDetail !== null
    }
    return this.viewModel.album !== null
  }

  private get typePrefix(): string {
    if (this.viewModel.playListType === MusicListType.TYPE_FOLDER) {
      return '歌单'
    } else if (this.viewModel.playListType === MusicListType.TYPE_ONLINE) {
      return '榜单'
    } else if (this.viewModel.playListType === MusicListType.TYPE_SINGER) {
      return '歌手'
    }
    return '专辑'
  }

  /** 歌单描述截取文本（未展开时截取前15字） */
  private get folderDescDisplayText(): string {
    const intro = this.viewModel.folderIntroduction
    if (intro.length <= 15 || this.isFolderDescExpanded) {
      return intro
    }
    return intro.substring(0, 15) + '...'
  }

  /** 是否显示歌单描述展开/收起图标 */
  private get showFolderDescToggle(): boolean {
    return this.viewModel.folderIntroduction.length > 15
  }

  /** 榜单描述截取文本（未展开时截取前15字） */
  private get rankDescDisplayText(): string {
    const desc = this.viewModel.rankDesc
    if (desc.length <= 15 || this.isRankDescExpanded) {
      return desc
    }
    return desc.substring(0, 15) + '...'
  }

  /** 是否显示榜单描述展开/收起图标 */
  private get showRankDescToggle(): boolean {
    return this.viewModel.rankDesc.length > 15
  }

  /** 格式化后的播放量（如 "1.2万"、"3.5亿"） */
  private get formattedListenCount(): string {
    return NumberFormatUtils.formatNumber(this.viewModel.listListenCount)
  }

  /** 格式化后的收藏量 */
  private get formattedFavCount(): string {
    return NumberFormatUtils.formatNumber(this.viewModel.listFavCount)
  }

  /** 格式化后的歌曲数 */
  private get formattedSongCount(): string {
    return `${this.viewModel.listSongCount}首`
  }

  /** 格式化后的关注数 */
  private get formattedConcernCount(): string {
    return NumberFormatUtils.formatNumber(this.viewModel.listListenCount)
  }

  build() {
    if (this.showCard) {
      Row({ space: 16 }) {
        Image(this.viewModel.listCoverUrl)
          .width(this.coverSize)
          .height(this.coverSize)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .backgroundColor('#E0E0E0')

        Column({ space: 8 }) {
          // 列表名称（所有类型通用）
          CopyableInfoField({
            label: `${this.typePrefix}-名称`,
            value: this.viewModel.listName,
            fontSize: 18,
            fontColor: '#333333',
            fontWeight: FontWeight.Bold,
            maxLines: 2
          })

          // 根据类型展示不同字段
          if (this.viewModel.playListType === MusicListType.TYPE_FOLDER) {
            this.buildFolderFields()
          } else if (this.viewModel.playListType === MusicListType.TYPE_ONLINE) {
            this.buildRankFields()
          } else if (this.viewModel.playListType === MusicListType.TYPE_SINGER) {
            this.buildSingerFields()
          } else {
            this.buildAlbumFields()
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .margin({ bottom: 8 })
    }
  }

  @Builder
  buildFolderFields() {
    // 创建者
    if (this.viewModel.listCreatorName.length > 0) {
      CopyableInfoField({
        label: '创建者',
        value: this.viewModel.listCreatorName,
        fontSize: 14,
        fontColor: '#666666'
      })
    }

    // 歌单ID
    CopyableInfoField({
      label: '歌单ID',
      value: `${this.viewModel.folderId}`,
      fontSize: 11,
      fontColor: '#666666'
    })

    // 歌单描述
    if (this.viewModel.folderIntroduction.length > 0) {
      Row({ space: 4 }) {
        CopyableInfoField({
          label: '歌单描述',
          value: this.folderDescDisplayText,
          fontSize: 13,
          fontColor: '#666666',
          maxLines: this.isFolderDescExpanded ? 99 : 2
        })
        if (this.showFolderDescToggle) {
          Text(this.isFolderDescExpanded ? '▲' : '▼')
            .fontSize(12)
            .fontColor('#1890FF')
            .onClick(() => {
              this.isFolderDescExpanded = !this.isFolderDescExpanded
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }

    // 创建时间
    if (this.viewModel.folderCreateTime.length > 0) {
      CopyableInfoField({
        label: '创建时间',
        value: this.viewModel.folderCreateTime,
        fontColor: '#666666'
      })
    }

    // 更新时间
    if (this.viewModel.folderUpdateTime.length > 0) {
      CopyableInfoField({
        label: '更新时间',
        value: this.viewModel.folderUpdateTime,
        fontColor: '#666666'
      })
    }
    // 歌曲数
    if (this.viewModel.listSongCount > 0) {
      CopyableInfoField({
        label: '歌曲数',
        value: this.formattedSongCount,
        fontColor: '#666666'
      })
    }

    // 播放量
    if (this.viewModel.listListenCount > 0) {
      CopyableInfoField({
        label: '播放',
        value: this.formattedListenCount,
        fontColor: '#666666'
      })
    }
    // 收藏量
    if (this.viewModel.listFavCount > 0) {
      CopyableInfoField({
        label: '收藏',
        value: this.formattedFavCount,
        fontColor: '#666666'
      })
    }
  }

  @Builder
  buildRankFields() {
    // 榜单描述
    if (this.viewModel.rankDesc.length > 0) {
      Row({ space: 4 }) {
        CopyableInfoField({
          label: '描述',
          value: this.rankDescDisplayText,
          fontSize: 13,
          fontColor: '#666666',
          maxLines: this.isRankDescExpanded ? 99 : 2
        })
        if (this.showRankDescToggle) {
          Text(this.isRankDescExpanded ? '▲' : '▼')
            .fontSize(12)
            .fontColor('#1890FF')
            .onClick(() => {
              this.isRankDescExpanded = !this.isRankDescExpanded
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }

    // 榜单ID
    CopyableInfoField({
      label: '榜单ID',
      value: `${this.viewModel.rankId}`,
      fontSize: 11,
      fontColor: '#666666'
    })
    // 歌曲数
    if (this.viewModel.listSongCount > 0) {
      CopyableInfoField({
        label: '歌曲数',
        value: this.formattedSongCount,
        fontColor: '#666666'
      })
    }

    // 播放量
    if (this.viewModel.listListenCount > 0) {
      CopyableInfoField({
        label: '播放',
        value: this.formattedListenCount,
        fontColor: '#666666'
      })
    }

    // 更新时间
    if (this.viewModel.rankUpdateTime.length > 0) {
      CopyableInfoField({
        label: '更新',
        value: this.viewModel.rankUpdateTime,
        fontColor: '#666666'
      })
    }
  }

  @Builder
  buildAlbumFields() {
    // 歌手
    if (this.viewModel.listSingerName.length > 0) {
      CopyableInfoField({
        label: '歌手',
        value: this.viewModel.listSingerName,
        fontSize: 14,
        fontColor: '#666666'
      })
    }

    // 专辑ID
    CopyableInfoField({
      label: '专辑ID',
      value: `${this.viewModel.albumId}`,
      fontSize: 11,
      fontColor: '#666666'
    })

    // 发布时间
    if (this.viewModel.listPublicTime.length > 0) {
      CopyableInfoField({
        label: '发布时间',
        value: this.viewModel.listPublicTime,
        fontColor: '#666666'
      })
    }

    // 歌曲数
    if (this.viewModel.listSongCount > 0) {
      CopyableInfoField({
        label: '歌曲数',
        value: this.formattedSongCount,
        fontColor: '#666666'
      })
    }

    // 收藏量
    if (this.viewModel.listFavCount > 0) {
      CopyableInfoField({
        label: '收藏',
        value: this.formattedFavCount,
        fontColor: '#666666'
      })
    }

    // 播放量
    if (this.viewModel.listListenCount > 0) {
      CopyableInfoField({
        label: '播放',
        value: this.formattedListenCount,
        fontColor: '#666666'
      })
    }
  }

  @Builder
  buildSingerFields() {
    // 歌手名称
    if (this.viewModel.singerName.length > 0) {
      CopyableInfoField({
        label: '歌手名称',
        value: this.viewModel.singerName,
        fontSize: 14,
        fontColor: '#666666'
      })
    }

    // 歌手ID
    CopyableInfoField({
      label: '歌手ID',
      value: `${this.viewModel.singerId}`,
      fontSize: 11,
      fontColor: '#666666'
    })

    // 歌手mid
    if (this.viewModel.singerMid.length > 0) {
      CopyableInfoField({
        label: '歌手mid',
        value: this.viewModel.singerMid,
        fontSize: 11,
        fontColor: '#666666'
      })
    }

    // 外文名
    if (this.viewModel.singerTranslatorName.length > 0) {
      CopyableInfoField({
        label: '外文名',
        value: this.viewModel.singerTranslatorName,
        fontSize: 14,
        fontColor: '#666666'
      })
    }

    // 区域
    if (this.viewModel.singerArea.length > 0) {
      CopyableInfoField({
        label: '国籍/区域',
        value: this.viewModel.singerArea,
        fontSize: 14,
        fontColor: '#666666'
      })
    }

    // 歌曲数
    if (this.viewModel.listSongCount > 0) {
      CopyableInfoField({
        label: '歌曲数',
        value: this.formattedSongCount,
        fontColor: '#666666'
      })
    }

    // 关注数
    if (this.viewModel.listListenCount > 0) {
      CopyableInfoField({
        label: '关注数',
        value: this.formattedConcernCount,
        fontColor: '#666666'
      })
    }

    // 歌手 Wiki 信息
    this.buildSingerWikiSection()
  }

  @Builder
  buildSingerWikiSection() {
    if (this.viewModel.singerWiki !== null) {
      // 歌手简介标题行 + 展开/收起按钮
      Row({ space: 4 }) {
        Text('歌手简介:')
          .fontSize(13)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
        Text(this.isSingerWikiExpanded ? '▲' : '▼')
          .fontSize(12)
          .fontColor('#1890FF')
          .onClick(() => {
            this.isSingerWikiExpanded = !this.isSingerWikiExpanded
          })
      }
      .width('100%')

      // 展开时显示全部 Wiki 信息（basicInfo / groupListInfo / desc / otherInfo）
      if (this.isSingerWikiExpanded) {
        this.buildWikiBasicInfo()
        this.buildWikiGroupListInfo()

        if (this.viewModel.singerWikiDesc.length > 0) {
          Text(this.viewModel.singerWikiDesc)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
            .maxLines(99)
        }

        this.buildWikiOtherInfo()
      }
    }
  }

  @Builder
  buildWikiBasicInfo() {
    ForEach(this.viewModel.singerWikiBasicInfoEntries, (entry: [string, string]) => {
      CopyableInfoField({
        label: entry[0],
        value: entry[1],
        fontSize: 13,
        fontColor: '#666666'
      })
    })
  }
  @Builder
  buildWikiGroupListInfo() {
    ForEach(this.viewModel.singerWikiGroupListEntries, (groupEntries: [string, string][]) => {
      ForEach(groupEntries, (entry: [string, string]) => {
        CopyableInfoField({
          label: entry[0],
          value: entry[1],
          fontSize: 13,
          fontColor: '#666666'
        })
      })
    })
  }
  @Builder
  buildWikiOtherInfo() {
    ForEach(this.viewModel.singerWikiOtherInfoEntries, (entry: [string, string]) => {
      CopyableInfoField({
        label: entry[0],
        value: entry[1],
        fontSize: 13,
        fontColor: '#666666'
      })
    })
  }
}
