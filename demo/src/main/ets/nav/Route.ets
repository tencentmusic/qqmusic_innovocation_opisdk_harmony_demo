/**
 * @Description: 页面路由配置信息（Demo 项目）
 * @param name: 路由名（对应 NavDestination name）
 * @param singleTask: 页面是否单实例，若为单实例 push 时会 pop 到已存在页面
 * @param showFloatingPlayer: 是否展示悬浮播放器 FloatingPlayerPage，默认 true
 * @param pageBuilder: 页面的 WrappedBuilder 构造器
 */
export class Route {
  name: string;
  singleTask: boolean;
  showFloatingPlayer: boolean;
  pageBuilder: WrappedBuilder<[Object]>;

  constructor(name: string, pageBuilder: WrappedBuilder<[Object]>, singleTask: boolean = true,
    showFloatingPlayer: boolean = true) {
    this.name = name;
    this.pageBuilder = pageBuilder;
    this.singleTask = singleTask;
    this.showFloatingPlayer = showFloatingPlayer;
  }

  toString(): string {
    return `Route(name=${this.name}, singleTask=${this.singleTask}, showFloatingPlayer=${this.showFloatingPlayer})`
  }
}