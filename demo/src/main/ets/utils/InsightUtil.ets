export class InsightUtil {
  static convertErrorCode(code: number): string {
    switch (code) {
      case 0: return "操作正常。";
      case 1: return "SDK内部遇到异常，请联系开发人员。";
      case 2: return "存储空间不足，请清理存储。";
      case 3: return "待播放的文件不存在，请检查文件路径。";
      case 4: return "操作不支持，请检查当前状态。";
      case 5: return "无网络连接，请检查网络状态。";
      case 6: return "没有可播放的歌曲，请选择歌曲。";
      case 7: return "播放列表为空，请添加歌曲。";
      case 9: return "播放没有错误，但本次操作无影响。";
      case 10: return "播放操作太频繁，请稍后再试。";
      case 11: return "当前播放时传入的索引非法，请检查。";
      case 19: return "添加的歌曲与正在播放的歌曲为同一首，无法添加。";
      case 21: return "当前正在恢复或暂停播放，无法重复操作。";
      case 22: return "当前正在停止播放，无法重复操作。";
      case 32: return "播放器准备时发生异常，请检查文件。";
      case 33: return "设置数据源时发生异常，请检查数据源。";
      case 35: return "播放服务未启动或已被系统杀死，请重启服务。";
      case 63: return "安全锚点检查失败，命令未执行。";
      case 65: return "获取音频焦点失败，请重试。";
      case 300: return "播放服务已重启，请重新尝试。";
      case 200: return "操作需要VIP权限，请升级您的账户等级。";
      case 201: return "该歌曲目前无权限播放，请检查用户 是否登陆、VIP等级，如仍旧失败，请提交日志。";
      case 202: return "没有SD卡或本地存储空间已满，请检查存储。";
      case 203: return "未知异常，请检查播放器状态。";
      case 204: return "播放器异常，请查看日志。";
      case 205: return "该歌曲没有对应的音质，请选择其他品质。";
      case 206: return "二次缓冲失败，请检查网络连接。";
      case 207: return "设备不支持该操作，请检查设备设置。";
      case 208: return "操作需要超级会员权限，请升级您的账户等级。";
      case 209: return "播放所需的资源没有加载完成，请稍后再试。";
      case 210: return "需要登录才能执行该操作，请登录。";
      case 211: return "无法试听，请检查歌曲权限。";
      case 212: return "触发播放库的同步限制，请重试。";
      case 213: return "播放链接为空且网络不可用，请检查网络。";
      case 214: return "播放链接为空，请检查链接。";
      case 215: return "免登录歌曲权限token过期，请重新获取。";
      case 216: return "操作需要单曲购买，请购买后重试。";
      case 217: return "操作需要数字专辑购买，请购买后重试。";
      case 218: return "操作需要听书会员，请升级您的账户。";
      case 219: return "播放列表中的所有歌曲都无法播放，请检查。";
      case 220: return "伴唱模式下不支持切换音质。";
      case 221: return "伴唱模式当前处于未开启状态，请开启后重试。";
      case 222: return "伴唱模式暂未准备好，请稍后重试。";
      case 223: return "伴唱试听刷新歌曲信息失败，请重试。";
      case 224: return "该歌曲不能完整播放，请选择其他歌曲。";
      case 225: return "操作需要强登录，请登录后重试。";
      case 226: return "电台播放没有上一首，请选择其他电台。";
      case 238: return "操作需要联合会员";
      case 401: return "杜比全景声播放时不支持设置音效。";
      case 402: return "臻品音质2.0播放时不支持设置音效。";
      case 403: return "臻品全景声播放时不支持设置音效。";
      case 404: return "臻品母带播放时不支持设置音效。";
      case 405: return "Wanos播放时不支持设置音效。";
      case 411: return "该歌曲下该音质不支持设置，请选择其他音质。";
      default: return "未知错误，请检查播放器状态或日志分析。";
    }
  }
}