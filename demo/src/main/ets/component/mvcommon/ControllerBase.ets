// 控制器基类
export class ControllerBase<T> {
  // 控制器绑定的进度条组件实例
  protected component: T | null = null;

  /*
   * 将组件实例绑定到此控制器上
   * @param component 组件实例
   */
  public attach(component: T) {
    this.component = component;
  }
}