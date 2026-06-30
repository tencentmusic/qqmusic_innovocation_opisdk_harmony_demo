import { OpenApiSdk } from "@qqmusic/opisdk-base";
import { PlayerModuleFunctionConfigParam } from "@qqmusic/opisdk-entity";
import { SPUtils } from "./SPUtils";

export class ResumePlayback {
  static start() {
    OpenApiSdk.playerApi?.setSDKSpecialNeedInterface({
      getPlayerModuleFunctionConfigParam: ():PlayerModuleFunctionConfigParam => {
        let param = new PlayerModuleFunctionConfigParam();
        param.autoPlayErrNum = SPUtils.getInt("restore_play_list_err_num", 0);
        param.enableRestorePlaylistFunctionality = SPUtils.getBool("restore_play_list", true);
        param.playHigherQualityCache = SPUtils.getBool("playHigherQualityCache", true);
        param.filterAddToNextOneSong = SPUtils.getBool("filterAddToNextOneSong", false);
        return param;
      }
    });
  }
}