import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WxCity, WxCityWeather } from '../model/WeatherModels';
import { WxCityStore } from '../service/CityStore';
import { wxLoadCityWeather } from '../service/WeatherRepository';
import { wxCachePrune, wxCachePutSync } from '../service/WeatherCache';

const DOMAIN: number = 0x0004;
const TAG: string = 'WxWorkAbility';
const MAX_CITIES: number = 6;

/**
 * 延迟任务：系统每约 30 分钟唤醒一次，把城市列表里的天气重新拉一遍写入本地缓存。
 * 执行时长有限，因此最多刷新 6 个城市。
 */
export default class WeatherWorkAbility extends WorkSchedulerExtensionAbility {
  onWorkStart(work: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, TAG, 'work start, id=%{public}d', work.workId);
    this.refreshAll().catch((error: Error) => {
      hilog.warn(DOMAIN, TAG, 'refresh all failed: %{public}s', error.message);
    });
  }

  onWorkStop(work: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, TAG, 'work stop, id=%{public}d', work.workId);
  }

  private async refreshAll(): Promise<void> {
    await WxCityStore.get().init(this.context);
    const cities: WxCity[] = await WxCityStore.get().loadCities();
    wxCachePrune(this.context, cities);
    const limit: number = Math.min(cities.length, MAX_CITIES);
    const tasks: Promise<void>[] = [];
    for (let i = 0; i < limit; i++) {
      tasks.push(this.refreshOne(cities[i]));
    }
    await Promise.all(tasks);
    hilog.info(DOMAIN, TAG, 'refreshed %{public}d cities', limit);
  }

  private async refreshOne(city: WxCity): Promise<void> {
    try {
      const data: WxCityWeather = await wxLoadCityWeather(city);
      wxCachePutSync(this.context, data);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'refresh %{public}s failed: %{public}s', city.name,
        (error as Error).message);
    }
  }
}
