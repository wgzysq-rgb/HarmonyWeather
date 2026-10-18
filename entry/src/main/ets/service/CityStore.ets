import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { WxCity } from '../model/WeatherModels';

const PREF_NAME: string = 'wx_settings';
const KEY_CITIES: string = 'cities';

/** 首次启动时的示例城市 */
export const WX_DEFAULT_CITIES: WxCity[] = [
  {
    id: 'beijing_39.904_116.407',
    name: '北京',
    region: '北京市，中国',
    lat: 39.9042,
    lon: 116.4074,
    isLocated: false
  },
  {
    id: 'shanghai_31.230_121.473',
    name: '上海',
    region: '上海市，中国',
    lat: 31.2304,
    lon: 121.4737,
    isLocated: false
  },
  {
    id: 'guangzhou_23.129_113.264',
    name: '广州',
    region: '广东省，中国',
    lat: 23.1291,
    lon: 113.2644,
    isLocated: false
  }
];

/** 城市列表的本地持久化 */
export class WxCityStore {
  private static instance: WxCityStore | null = null;
  private pref: preferences.Preferences | null = null;

  static get(): WxCityStore {
    if (WxCityStore.instance === null) {
      WxCityStore.instance = new WxCityStore();
    }
    return WxCityStore.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
    } catch (error) {
      this.pref = null;
    }
  }

  async loadCities(): Promise<WxCity[]> {
    if (this.pref === null) {
      return WX_DEFAULT_CITIES.slice();
    }
    try {
      const raw: string = await this.pref.get(KEY_CITIES, '') as string;
      if (raw.length === 0) {
        return WX_DEFAULT_CITIES.slice();
      }
      const parsed: WxCity[] = JSON.parse(raw) as WxCity[];
      if (parsed.length === 0) {
        return WX_DEFAULT_CITIES.slice();
      }
      return parsed;
    } catch (error) {
      return WX_DEFAULT_CITIES.slice();
    }
  }

  async saveCities(cities: WxCity[]): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      await this.pref.put(KEY_CITIES, JSON.stringify(cities));
      await this.pref.flush();
    } catch (error) {
      // 持久化失败不影响当前会话使用
    }
  }
}
