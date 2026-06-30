import { http } from '@kit.NetworkKit';
import { MLog } from '@qqmusic/opisdk-base';

/**
 * DevOps 实体
 * 对应 Android 中 DevOpsEntity
 */
export class DevOpsEntity {
  devopsName: string = '';

  constructor(name?: string) {
    this.devopsName = name ?? '';
  }
}

/** 远端返回的 DevOps 条目结构 */
interface RawDevopsItem {
  mesh_devops?: string;
}

/** 远端返回的顶层响应结构 */
interface DevopsResponse {
  data?: Record<string, RawDevopsItem>;
}

const TAG = 'DebugViewModel'

/**
 * Debug 页面 ViewModel
 * 对应 Android 中 DebugViewModel
 *
 * 负责加载 DevOps 环境列表
 */
@ObservedV2
export class DebugViewModel {
  @Trace loadingDevops: boolean = false;
  @Trace devOpsList: DevOpsEntity[] = [];
  @Trace curDevops: DevOpsEntity | null = null;

  private static readonly REQUEST_URL =
    'https://operator.tencentmusic.com/api/cicd_client_list?application=' + encodeURIComponent('Q音微服务');

  /**
   * 从 SP 加载当前选中的 DevOps
   */
  loadCurDevops(devopsName: string | null): void {
    this.curDevops = new DevOpsEntity(devopsName ?? 'DevopsBase');
  }

  /**
   * 从远端加载 DevOps 列表
   */
  async loadDevopsList(): Promise<void> {
    this.loadingDevops = true;

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(DebugViewModel.REQUEST_URL, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000,
      });

      MLog.i(TAG, `[loadDevopsList] code = ${response.responseCode} result = ${response.result}`);
      if (response.responseCode === 200) {
        const body: string = response.result as string;
        const jsonObj: DevopsResponse = JSON.parse(body) as DevopsResponse;
        const dataObj: Record<string, RawDevopsItem> = jsonObj.data ?? {};
        const tempList: DevOpsEntity[] = [];

        const keys: string[] = Object.keys(dataObj);
        for (let i = 0; i < keys.length; i++) {
          const key: string = keys[i];
          try {
            const entity: RawDevopsItem = dataObj[key];
            const devops: DevOpsEntity = new DevOpsEntity(entity.mesh_devops ?? key);
            tempList.push(devops);
          } catch (_e) {
            // 跳过解析失败的条目
          }
        }
        this.devOpsList = tempList;
      } else {
        MLog.w(TAG, `[loadDevopsList] unexpected code = ${response.responseCode}, body = ${response.result}`);
      }
    } catch (_e) {
      // 请求失败，保持为空列表
      MLog.e(TAG, `[loadDevopsList] error = ${JSON.stringify(_e)}`);
    } finally {
      this.loadingDevops = false;
    }
  }
}
