import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WxCity, WxCityWeather } from '../model/WeatherModels';
import { WxCityStore } from '../service/CityStore';
import { wxLoadCityWeather } from '../service/WeatherRepository';
import {
  wxBuildWidgetSnapshot,
  wxLoadFormIds,
  wxRecallFormLayout,
  wxSaveWidgetSnapshot,
  WxWidgetSnapshot
} from '../service/WidgetSnapshot';
import { wxBuildWidgetBinding } from '../service/WidgetBinding';

const DOMAIN: number = 0x0004;
const TAG: string = 'WxWorkAbility';

/**
 * 延迟任务：系统大约每 20 分钟唤醒一次，刷新首页城市并**直接推一次桌面卡片**。
 *
 * 早前它只是把结果写进 App 的本地缓存，缓存去掉之后这个产出就没有消费方了；
 * 现在改成写卡片快照 + updateForm，至少保证用户在后台放置时卡片不会太旧。
 * 注意：卡片本身最短只能 30 分钟自刷新一次（updateDuration 下限为 1），
 * 想更快只能在 App 前台用 5 分钟定时器推。
 */
export default class WeatherWorkAbility extends WorkSchedulerExtensionAbility {
  onWorkStart(work: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, TAG, 'work start, id=%{public}d', work.workId);
    this.refreshHome().catch((error: Error) => {
      hilog.warn(DOMAIN, TAG, 'refresh home failed: %{public}s', error.message);
    });
  }

  onWorkStop(work: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, TAG, 'work stop, id=%{public}d', work.workId);
  }

  private async refreshHome(): Promise<void> {
    await WxCityStore.get().init(this.context);
    const cities: WxCity[] = await WxCityStore.get().loadCities();
    if (cities.length === 0) {
      return;
    }
    const data: WxCityWeather = await wxLoadCityWeather(cities[0]);
    await wxSaveWidgetSnapshot(this.context, data);

    const formIds: string[] = wxLoadFormIds(this.context);
    const snapshot: WxWidgetSnapshot = wxBuildWidgetSnapshot(data);
    for (let i = 0; i < formIds.length; i++) {
      const formId: string = formIds[i];
      const layout: string = wxRecallFormLayout(this.context, formId);
      formProvider.updateForm(formId,
        formBindingData.createFormBindingData(wxBuildWidgetBinding(snapshot, layout)))
        .catch((error: Error) => {
          hilog.warn(DOMAIN, TAG, 'update form %{public}s failed: %{public}s', formId, error.message);
        });
    }
    hilog.info(DOMAIN, TAG, 'home refreshed: %{public}s, forms=%{public}d', data.city.name, formIds.length);
  }
}
