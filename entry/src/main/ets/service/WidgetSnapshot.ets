import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WxCity, WxCityWeather } from '../model/WeatherModels';

const DOMAIN: number = 0x0002;
const TAG: string = 'WxWidget';
const PREF_NAME: string = 'wx_settings';
const KEY_SNAPSHOT: string = 'widget_snapshot';

/** 卡片里的每小时条目（字段名与卡片页保持字面一致） */
export interface WxWidgetHour {
  label: string;
  temp: number;
  code: number;
  isDay: boolean;
}

/** 卡片里的逐日条目 */
export interface WxWidgetDay {
  weekday: string;
  min: number;
  max: number;
  code: number;
  isPast: boolean;
}

/** 卡片渲染所需的精简快照，落盘后供 FormExtensionAbility 秒开 */
export interface WxWidgetSnapshot {
  city: WxCity;
  cityName: string;
  tempText: string;
  desc: string;
  rangeText: string;
  code: number;
  isDay: boolean;
  updated: string;
  g0: string;
  g1: string;
  g2: string;
  hours: WxWidgetHour[];
  days: WxWidgetDay[];
  savedAt: number;
}

/** 把完整天气快照裁剪成卡片需要的最小集合 */
export function wxBuildWidgetSnapshot(data: WxCityWeather): WxWidgetSnapshot {
  const hours: WxWidgetHour[] = [];
  for (let i = 0; i < data.hours.length && i < 6; i++) {
    hours.push({
      label: data.hours[i].label,
      temp: data.hours[i].temp,
      code: data.hours[i].code,
      isDay: data.hours[i].isDay
    });
  }
  const days: WxWidgetDay[] = [];
  for (let i = 0; i < data.days.length && i < 6; i++) {
    days.push({
      weekday: data.days[i].weekday,
      min: data.days[i].min,
      max: data.days[i].max,
      code: data.days[i].code,
      isPast: data.days[i].isPast
    });
  }
  const gradient: string[] = data.theme.gradient;
  return {
    city: data.city,
    cityName: data.city.name,
    tempText: `${data.temp}°`,
    desc: data.desc,
    rangeText: `最高 ${data.high}°  最低 ${data.low}°`,
    code: data.code,
    isDay: data.isDay,
    updated: data.updatedAt,
    g0: gradient.length > 0 ? gradient[0] : '#2C6FC4',
    g1: gradient.length > 1 ? gradient[1] : '#4E9BD8',
    g2: gradient.length > 2 ? gradient[2] : '#8FC6EA',
    hours: hours,
    days: days,
    savedAt: Date.now()
  };
}

export async function wxSaveWidgetSnapshot(context: Context, data: WxCityWeather): Promise<void> {
  const snapshot: WxWidgetSnapshot = wxBuildWidgetSnapshot(data);
  try {
    const pref: preferences.Preferences = await preferences.getPreferences(context, PREF_NAME);
    await pref.put(KEY_SNAPSHOT, JSON.stringify(snapshot));
    await pref.flush();
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'save snapshot failed: %{public}s', (error as Error).message);
  }
}

export async function wxLoadWidgetSnapshot(context: Context): Promise<WxWidgetSnapshot | null> {
  try {
    const pref: preferences.Preferences = await preferences.getPreferences(context, PREF_NAME);
    const raw: string = await pref.get(KEY_SNAPSHOT, '') as string;
    if (raw.length === 0) {
      return null;
    }
    return JSON.parse(raw) as WxWidgetSnapshot;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'load snapshot failed: %{public}s', (error as Error).message);
    return null;
  }
}

/** 同步读取：卡片 onAddForm 必须同步返回，用它做到「添加即显示上次数据」 */
export function wxLoadWidgetSnapshotSync(context: Context): WxWidgetSnapshot | null {
  try {
    const pref: preferences.Preferences =
      preferences.getPreferencesSync(context, { name: PREF_NAME });
    const raw: string = pref.getSync(KEY_SNAPSHOT, '') as string;
    if (raw.length === 0) {
      return null;
    }
    return JSON.parse(raw) as WxWidgetSnapshot;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'sync load snapshot failed: %{public}s', (error as Error).message);
    return null;
  }
}

const PREF_FORMS: string = 'wx_forms';

function wxFormPref(context: Context): preferences.Preferences | null {
  try {
    return preferences.getPreferencesSync(context, { name: PREF_FORMS });
  } catch (error) {
    return null;
  }
}

/** 记住某个卡片实例的布局形态（small / wide / large），供 onUpdateForm / onFormEvent 复用 */
export function wxRememberFormLayout(context: Context, formId: string, layout: string): void {
  if (formId.length === 0) {
    return;
  }
  const pref: preferences.Preferences | null = wxFormPref(context);
  if (pref === null) {
    return;
  }
  try {
    pref.putSync(formId, layout);
    pref.flushSync();
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'remember layout failed: %{public}s', (error as Error).message);
  }
}

export function wxRecallFormLayout(context: Context, formId: string): string {
  const pref: preferences.Preferences | null = wxFormPref(context);
  if (pref === null) {
    return 'small';
  }
  try {
    const value: string = pref.getSync(formId, 'small') as string;
    return value;
  } catch (error) {
    return 'small';
  }
}

export function wxForgetFormLayout(context: Context, formId: string): void {
  const pref: preferences.Preferences | null = wxFormPref(context);
  if (pref === null) {
    return;
  }
  try {
    pref.deleteSync(formId);
    pref.flushSync();
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'forget layout failed: %{public}s', (error as Error).message);
  }
}

/** 桌面上当前存在的所有卡片实例 id（key 就是 formId） */
export function wxLoadFormIds(context: Context): string[] {
  const pref: preferences.Preferences | null = wxFormPref(context);
  if (pref === null) {
    return [];
  }
  try {
    const all: Object = pref.getAllSync();
    return Object.keys(all);
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'load form ids failed: %{public}s', (error as Error).message);
    return [];
  }
}
