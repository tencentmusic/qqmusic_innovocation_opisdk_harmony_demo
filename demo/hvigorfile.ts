import { hapTasks } from '@ohos/hvigor-ohos-plugin';
import { OpiSdkPlugin } from '@qqmusic/opi-sdk-plugin';

export default {
  system: hapTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [
    OpiSdkPlugin()
  ]       /* Custom plugin to extend the functionality of Hvigor. */
}