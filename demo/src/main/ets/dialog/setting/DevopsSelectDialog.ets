import { DebugViewModel, DevOpsEntity } from '../../viewmodel/setting/DebugViewModel';

/**
 * DevOps 选择对话框
 * 对应 Android 中 DevOpsDialog Composable
 */
@CustomDialog
export struct DevopsSelectDialog {
  controller: CustomDialogController;
  @State searchText: string = '';
  viewModel?: DebugViewModel;
  onSelect?: (entity: DevOpsEntity) => void;

  build() {
    Column() {
      Text('选择DevOps').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 8 })

      if (this.viewModel?.loadingDevops) {
        Text('正在加载中...').fontSize(14).padding(20)
      } else if (!this.viewModel?.devOpsList || this.viewModel.devOpsList.length === 0) {
        Text('暂无可选环境，默认使用DevopsBase').fontSize(14).padding(20)
      } else {
        TextInput({ text: this.searchText, placeholder: '输入关键字进行过滤' })
          .fontSize(14).margin({ bottom: 8 })
          .onChange((v: string) => { this.searchText = v })

        List() {
          ForEach(this.getFilteredList(), (entity: DevOpsEntity) => {
            ListItem() {
              Row() {
                Text(entity.devopsName || '').fontSize(16).padding(14)
              }
              .width('100%')
              .onClick(() => {
                this.controller.close();
                if (this.onSelect) this.onSelect(entity);
              })
            }
          })
        }
        .layoutWeight(1)
      }

      Button('取消')
        .margin({ top: 8 }).width('100%')
        .backgroundColor('#F0F0F0').fontColor('#333333')
        .onClick(() => this.controller.close())
    }
    .padding(20)
    .height(700)
    .backgroundColor(Color.White)
  }

  private getFilteredList(): DevOpsEntity[] {
    const list = this.viewModel?.devOpsList ?? [];
    if (this.searchText.length === 0) return list;
    return list.filter(e => e.devopsName.toLowerCase().includes(this.searchText.toLowerCase()));
  }
}
