import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { wxRegisterBackgroundRefresh } from '../service/BackgroundRefresh';

const DOMAIN: number = 0x0000;
const TAG: string = 'HarmonyWeather';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
    // 注册每 30 分钟一次的延迟任务，后台把天气写进本地缓存
    wxRegisterBackgroundRefresh(this.context);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      this.applyImmersiveStyle(windowStage);
    });
  }

  /** 让天气背景铺满全屏，状态栏文字保持白色 */
  private applyImmersiveStyle(windowStage: window.WindowStage): void {
    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true).catch((error: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'setWindowLayoutFullScreen failed: %{public}s', error.message);
      });
      mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: '#FFFFFFFF',
        navigationBarContentColor: '#FFFFFFFF'
      }).catch((error: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'setWindowSystemBarProperties failed: %{public}s', error.message);
      });
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'immersive style failed: %{public}s', (error as Error).message);
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
