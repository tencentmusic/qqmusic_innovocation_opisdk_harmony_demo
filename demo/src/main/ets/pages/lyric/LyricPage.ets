import { ILyricInfo } from "@qqmusic/opisdk-entity";

@ComponentV2
export struct LyricPage {
  @Param args: Object | undefined = undefined;
  @Local lyric: string = '';

  aboutToAppear(): void {
    const params = this.args as ILyricInfo;
    if (params) {
      this.lyric = params.getLyric();
    }
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Text(this.lyric)
        }
      }
    }
  }
}

@Builder
export function LyricPageBuilder(params?: Object) {
  LyricPage({ args: params })
}