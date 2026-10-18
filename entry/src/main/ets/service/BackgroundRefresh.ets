import { workScheduler } from '@kit.BackgroundTasksKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0004;
const TAG: string = 'WxBackground';
const WORK_ID: number = 4101;
const WORK_ABILITY: string = 'WeatherWorkAbility';

/**
 * 后台刷新周期：30 分钟。
 * WorkScheduler 的 repeatCycleTime 下限是 20 分钟，且系统会按电量/使用频率做合并调度，
 * 实际触发时间可能晚于这个值（不保证准点）。
 */
const CYCLE_MS: number = 30 * 60 * 1000;

export function wxRegisterBackgroundRefresh(context: common.UIAbilityContext): void {
  try {
    const work: workScheduler.WorkInfo = {
      workId: WORK_ID,
      bundleName: context.abilityInfo.bundleName,
      abilityName: WORK_ABILITY,
      isRepeat: true,
      repeatCycleTime: CYCLE_MS,
      isPersisted: true,
      networkType: workScheduler.NetworkType.NETWORK_TYPE_ANY
    };
    workScheduler.startWork(work);
    hilog.info(DOMAIN, TAG, 'background refresh registered, cycle=%{public}d ms', CYCLE_MS);
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'register failed: %{public}s', (error as Error).message);
  }
}

export function wxUnregisterBackgroundRefresh(context: common.UIAbilityContext): void {
  try {
    const work: workScheduler.WorkInfo = {
      workId: WORK_ID,
      bundleName: context.abilityInfo.bundleName,
      abilityName: WORK_ABILITY
    };
    workScheduler.stopWork(work, true);
    hilog.info(DOMAIN, TAG, 'background refresh unregistered');
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'unregister failed: %{public}s', (error as Error).message);
  }
}
