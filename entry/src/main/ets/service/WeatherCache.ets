import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WxCity, WxCityWeather } from '../model/WeatherModels';

const DOMAIN: number = 0x0003;
const TAG: string = 'WxCache';
const PREF_NAME: string = 'wx_cache';
const KEY_PREFIX: string = 'c_';

/**
 * 本地天气缓存的有效期。
 * 30 分钟与后台定时刷新周期一致；想改成 1 小时就改成 60 * 60 * 1000。
 */
export const WX_CACHE_TTL_MS: number = 30 * 60 * 1000;

export interface WxCacheEntry {
  savedAt: number;
  weather: WxCityWeather;
}

let prefInstance: preferences.Preferences | null = null;

function cachePref(context: Context): preferences.Preferences | null {
  if (prefInstance !== null) {
    return prefInstance;
  }
  try {
    prefInstance = preferences.getPreferencesSync(context, { name: PREF_NAME });
    return prefInstance;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'open cache failed: %{public}s', (error as Error).message);
    return null;
  }
}

export function wxCacheGetSync(context: Context, cityId: string): WxCacheEntry | null {
  const pref: preferences.Preferences | null = cachePref(context);
  if (pref === null) {
    return null;
  }
  try {
    const raw: string = pref.getSync(`${KEY_PREFIX}${cityId}`, '') as string;
    if (raw.length === 0) {
      return null;
    }
    return JSON.parse(raw) as WxCacheEntry;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'read cache failed: %{public}s', (error as Error).message);
    return null;
  }
}

export function wxCachePutSync(context: Context, weather: WxCityWeather): void {
  const pref: preferences.Preferences | null = cachePref(context);
  if (pref === null) {
    return;
  }
  try {
    const entry: WxCacheEntry = { savedAt: Date.now(), weather: weather };
    pref.putSync(`${KEY_PREFIX}${weather.city.id}`, JSON.stringify(entry));
    pref.flushSync();
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'write cache failed: %{public}s', (error as Error).message);
  }
}

/** 一次性读出多个城市的缓存，供启动时同步铺满首屏 */
export function wxCacheReadMany(context: Context, cities: WxCity[]): Map<string, WxCacheEntry> {
  const result: Map<string, WxCacheEntry> = new Map();
  for (let i = 0; i < cities.length; i++) {
    const entry: WxCacheEntry | null = wxCacheGetSync(context, cities[i].id);
    if (entry !== null) {
      result.set(cities[i].id, entry);
    }
  }
  return result;
}

export function wxCacheIsFresh(entry: WxCacheEntry | null): boolean {
  if (entry === null) {
    return false;
  }
  const age: number = Date.now() - entry.savedAt;
  // age < 0：本机时间被往前调过，savedAt 落在「未来」，按过期处理
  return age >= 0 && age < WX_CACHE_TTL_MS;
}

/** 缓存已存了多久（分钟），用于界面上标注数据是不是旧的 */
export function wxCacheAgeMinutes(entry: WxCacheEntry | null): number {
  if (entry === null) {
    return 0;
  }
  return Math.max(0, Math.floor((Date.now() - entry.savedAt) / 60000));
}

/** 清理已从城市列表移除的城市缓存，避免缓存目录无限增长 */
export function wxCachePrune(context: Context, cities: WxCity[]): void {
  const pref: preferences.Preferences | null = cachePref(context);
  if (pref === null) {
    return;
  }
  try {
    const alive: string[] = [];
    for (let i = 0; i < cities.length; i++) {
      alive.push(`${KEY_PREFIX}${cities[i].id}`);
    }
    const all: Object = pref.getAllSync();
    const keys: string[] = Object.keys(all);
    let removed: boolean = false;
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      if (key.startsWith(KEY_PREFIX) && !alive.includes(key)) {
        pref.deleteSync(key);
        removed = true;
      }
    }
    if (removed) {
      pref.flushSync();
    }
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'prune cache failed: %{public}s', (error as Error).message);
  }
}
