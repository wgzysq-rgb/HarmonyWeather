import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WxCity, WxCityWeather } from '../model/WeatherModels';
import { wxLoadCityWeather } from '../service/WeatherRepository';
import { WxCityStore } from '../service/CityStore';
import {
  wxBuildWidgetSnapshot,
  wxForgetFormLayout,
  wxLoadWidgetSnapshotSync,
  wxRecallFormLayout,
  wxRememberFormLayout,
  wxSaveWidgetSnapshot,
  WxWidgetSnapshot
} from '../service/WidgetSnapshot';
import {
  wxBuildPlaceholderBinding,
  wxBuildWidgetBinding,
  wxDimensionLayout,
  WxWidgetBinding
} from '../service/WidgetBinding';

const DOMAIN: number = 0x0002;
const TAG: string = 'EntryFormAbility';

function readString(params: Record<string, Object>, key: string): string {
  const value: Object | undefined = params[key];
  return typeof value === 'string' ? value : '';
}

function readNumber(params: Record<string, Object>, key: string, fallback: number): number {
  const value: Object | undefined = params[key];
  return typeof value === 'number' ? value : fallback;
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const params: Record<string, Object> = want.parameters ?? {};
    const formId: string = readString(params, formInfo.FormParam.IDENTITY_KEY);
    const dimension: number = readNumber(params, formInfo.FormParam.DIMENSION_KEY,
      formInfo.FormDimension.Dimension_2_2 as number);
    const layout: string = wxDimensionLayout(dimension);
    wxRememberFormLayout(this.context, formId, layout);

    const snapshot: WxWidgetSnapshot | null = wxLoadWidgetSnapshotSync(this.context);
    const binding: WxWidgetBinding = snapshot !== null
      ? wxBuildWidgetBinding(snapshot, layout)
      : wxBuildPlaceholderBinding(layout);

    // 先返回本地快照保证「添加即出图」，再异步拉一次最新数据
    this.refresh(formId, layout).catch((error: Error) => {
      hilog.warn(DOMAIN, TAG, 'refresh on add failed: %{public}s', error.message);
    });
    return formBindingData.createFormBindingData(binding);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    const layout: string = wxRecallFormLayout(this.context, formId);
    this.refresh(formId, layout).catch((error: Error) => {
      hilog.warn(DOMAIN, TAG, 'refresh on update failed: %{public}s', error.message);
    });
  }

  onFormEvent(formId: string, message: string): void {
    const layout: string = wxRecallFormLayout(this.context, formId);
    this.refresh(formId, layout).catch((error: Error) => {
      hilog.warn(DOMAIN, TAG, 'refresh on event failed: %{public}s', error.message);
    });
  }

  onRemoveForm(formId: string): void {
    wxForgetFormLayout(this.context, formId);
  }

  private async refresh(formId: string, layout: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    try {
      const city: WxCity | null = await this.resolveCity();
      if (city === null) {
        return;
      }
      const data: WxCityWeather = await wxLoadCityWeather(city);
      await wxSaveWidgetSnapshot(this.context, data);
      const fresh: WxWidgetSnapshot = wxBuildWidgetSnapshot(data);
      await formProvider.updateForm(formId,
        formBindingData.createFormBindingData(wxBuildWidgetBinding(fresh, layout)));
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'refresh failed form=%{public}s: %{public}s', formId,
        (error as Error).message);
    }
  }

  /** 优先用页面写入的快照中的城市（页面只会写首页城市）；从未打开过应用时退回城市列表里的第一个 */
  private async resolveCity(): Promise<WxCity | null> {
    const snapshot: WxWidgetSnapshot | null = wxLoadWidgetSnapshotSync(this.context);
    if (snapshot !== null) {
      return snapshot.city;
    }
    await WxCityStore.get().init(this.context);
    const cities: WxCity[] = await WxCityStore.get().loadCities();
    if (cities.length === 0) {
      return null;
    }
    return cities[0];
  }
}
