import { OpenApiSdk } from '@qqmusic/opisdk-base';
import { IEditFolderParam, IFolder, PersonalAssetsDataInfoRetCode } from '@qqmusic/opisdk-entity';
import { EditFolderParam } from '@qqmusic/opisdk-openapi';
import { JsonUtil } from '@qqmusic/opisdk-qmutils';
import { CreatFolderDialog } from '../../dialog/CreatFolderDialog';
import { FolderDialog } from '../../dialog/FolderDialog';
import { ToastUtil } from '../../utils/ToastUtil';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { EmptyView } from '../empty/EmptyView';
import { FolderPersonalListItem } from './FolderPersonalListItem';

@ComponentV2
export struct PersonalFolderApiPanel {

  @Consumer('homeViewModel') homeViewModel: HomeViewModel = new HomeViewModel();
  private folderDialogController: CustomDialogController = new CustomDialogController({
    builder: CreatFolderDialog({
      confirmAction: (name: string,imagePath:string) => {
        if(imagePath === ""){
          OpenApiSdk.openApi?.folderApi.createFolderByName(name).then((res) => {
            if (res.isSuccess()) {
              this.homeViewModel.fetchPersonalFolder();
            } else {
              ToastUtil.show(res.errorMsg);
            }
          });
        }else {
           this.createFolder(name,imagePath)
        }
      }
    }),
    alignment: DialogAlignment.Center
  })
  aboutToAppear(): void {
    this.homeViewModel.fetchPersonalFolder();
  }

  build() {
    Stack() {
      Column() {
        Button('创建自建歌单').onClick(() => {
          this.folderDialogController.open()
        })
        List({ space: 0 }) {
          ForEach(
            this.homeViewModel.personalFolderList
          , (item: IFolder) => {
            ListItem() {
              Column() {
                FolderPersonalListItem({ folder: item }).width('100%').layoutWeight(1)
                Blank().width('100%').height(0.4).backgroundColor(Color.Gray).opacity(0.2)
              }.width('100%').height('100%')
            }.width('100%').height(80)
          }, (item: IFolder) => `${item.getId()?.toString()}_${new Date().getTime()}`)
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)

        Row() {
          Button('刷新').onClick(() => {
            this.currentFolderApi?.refresh()
          })
        }.height(44).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      }.width('100%').height('100%')

      if (this.isLoadingFolder) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
        }.width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.Transparent)
      } else {
        if (this.requestFolderIsError) {
          EmptyView({
            msg: this.currentFolderApi?.getData().message
          })
        }
      }

    }
  }

  @Computed get currentFolderApi() {
    return OpenApiSdk.personalAssetsApi?.folderFavApi

  }

  @Computed get isLoadingFolder() {
    return this.currentFolderApi?.getData().isLoading
  }

  @Computed get requestFolderIsError() {
    return this.currentFolderApi?.getData().code != PersonalAssetsDataInfoRetCode.CODE_SUCCESS
  }


  createFolder(name: string,imagePath:string) {
    const raw =  name
    const param = JsonUtil.fromString<IEditFolderParam>(raw.length > 0 ? raw : '{}', EditFolderParam)
    if (param != null) {
      param.folderPicPath = imagePath
      OpenApiSdk.openApi?.folderApi.createFolder(param)
        .then((result) => {
          if (result.isSuccess()) {
            this.homeViewModel.fetchPersonalFolder();
          } else {
            ToastUtil.show(result.errorMsg);
          }
        })
    }
  }
}
