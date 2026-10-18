import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
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
  for (let i = 0; i < data.days.length && i < 8; i++) {
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

/**
 * 卡片实例的布局记录：每个 formId 一行 `formId:layout`，存在应用 files 目录。
 *
 * **不能用 preferences**。App 进程和 FormExtensionAbility（卡片进程）各自缓存
 * preferences 实例，卡片进程新增 / 删除 formId 后 App 进程读不到 ——
 * 表现为「新加的卡片永远收不到推送」「已删的卡片 id 一直残留」。
 * 文件由两个进程共享且每次读盘，没有这个问题。
 */
const FORMS_FILE: string = 'wx_forms.txt';

function formsPath(context: Context): string {
  return `${context.filesDir}/${FORMS_FILE}`;
}

function readFormLines(context: Context): string[] {
  try {
    const path: string = formsPath(context);
    if (!fileIo.accessSync(path)) {
      return [];
    }
    const stat: fileIo.Stat = fileIo.statSync(path);
    if (stat.size <= 0) {
      return [];
    }
    const file: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
    fileIo.readSync(file.fd, buffer);
    fileIo.closeSync(file);
    const text: string = util.TextDecoder.create('utf-8').decodeToString(new Uint8Array(buffer));
    const result: string[] = [];
    const parts: string[] = text.split('\n');
    for (let i = 0; i < parts.length; i++) {
      const line: string = parts[i].trim();
      if (line.length > 0) {
        result.push(line);
      }
    }
    return result;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'read forms failed: %{public}s', (error as Error).message);
    return [];
  }
}

function writeFormLines(context: Context, lines: string[]): void {
  try {
    const path: string = formsPath(context);
    const file: fileIo.File = fileIo.openSync(path,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    const bytes: Uint8Array = new util.TextEncoder().encodeInto(lines.join('\n'));
    fileIo.writeSync(file.fd, bytes.buffer);
    fileIo.closeSync(file);
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'write forms failed: %{public}s', (error as Error).message);
  }
}

function upsertFormLine(context: Context, formId: string, layout: string): void {
  const lines: string[] = readFormLines(context);
  const next: string[] = [];
  const entry: string = `${formId}:${layout}`;
  for (let i = 0; i < lines.length; i++) {
    const key: string = lines[i].split(':')[0];
    if (key !== formId) {
      next.push(lines[i]);
    }
  }
  next.push(entry);
  writeFormLines(context, next);
}

/** 记住某个卡片实例的布局形态（small / wide / large），供 onUpdateForm / onFormEvent 复用 */
export function wxRememberFormLayout(context: Context, formId: string, layout: string): void {
  if (formId.length === 0) {
    return;
  }
  upsertFormLine(context, formId, layout);
}

export function wxRecallFormLayout(context: Context, formId: string): string {
  const lines: string[] = readFormLines(context);
  for (let i = 0; i < lines.length; i++) {
    const parts: string[] = lines[i].split(':');
    if (parts.length >= 2 && parts[0] === formId) {
      return parts[1];
    }
  }
  return 'small';
}

export function wxForgetFormLayout(context: Context, formId: string): void {
  const lines: string[] = readFormLines(context);
  const next: string[] = [];
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].split(':')[0] !== formId) {
      next.push(lines[i]);
    }
  }
  writeFormLines(context, next);
}

/** 迁移用：早期版本把 formId 存在 preferences 里，现在改文件了，首次读时搬一次 */
const PREF_FORMS: string = 'wx_forms';

function migrateFormsFromPref(context: Context): string[] {
  const lines: string[] = [];
  try {
    const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_FORMS });
    const all: Object = pref.getAllSync();
    const keys: string[] = Object.keys(all);
    for (let i = 0; i < keys.length; i++) {
      const layout: string = pref.getSync(keys[i], 'small') as string;
      lines.push(`${keys[i]}:${layout}`);
    }
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'migrate forms failed: %{public}s', (error as Error).message);
  }
  return lines;
}

/** 桌面上当前存在的所有卡片实例 id */
export function wxLoadFormIds(context: Context): string[] {
  let lines: string[] = readFormLines(context);
  if (lines.length === 0) {
    const migrated: string[] = migrateFormsFromPref(context);
    if (migrated.length > 0) {
      writeFormLines(context, migrated);
      lines = migrated;
      hilog.info(DOMAIN, TAG, 'migrated %{public}d form ids to file', migrated.length);
    }
  }
  const ids: string[] = [];
  for (let i = 0; i < lines.length; i++) {
    const key: string = lines[i].split(':')[0];
    if (key.length > 0) {
      ids.push(key);
    }
  }
  return ids;
}
