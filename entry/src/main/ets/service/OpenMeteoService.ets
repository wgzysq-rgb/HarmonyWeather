import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WxRawForecast, WxRawAir, WxGeoResponse, WxGeoItem, WxCity } from '../model/WeatherModels';

const DOMAIN: number = 0x0001;
const TAG: string = 'WxApi';

/**
 * 数据源：Open-Meteo（https://open-meteo.com）
 * 完全免费、无需 API Key，商业/非商业用途均可（CC BY 4.0）。
 * 若需换成和风天气等商业数据源，只需替换本文件内的两个 URL 与解析逻辑，
 * 上层 Repository / UI 不需要任何改动。
 */
const FORECAST_URL: string = 'https://api.open-meteo.com/v1/forecast';
const GEO_URL: string = 'https://geocoding-api.open-meteo.com/v1/search';
const AIR_URL: string = 'https://air-quality-api.open-meteo.com/v1/air-quality';

const CURRENT_FIELDS: string =
  'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,' +
  'weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m';
const HOURLY_FIELDS: string = 'temperature_2m,weather_code,precipitation_probability,is_day,visibility';
const DAILY_FIELDS: string =
  'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,' +
  'precipitation_probability_max,precipitation_sum,wind_speed_10m_max';

function wxHttpGet(url: string): Promise<string> {
  return new Promise<string>((resolve, reject) => {
    const request = http.createHttp();
    let settled: boolean = false;
    const timer: number = setTimeout(() => {
      if (!settled) {
        settled = true;
        request.destroy();
        reject(new Error('网络请求超时，请检查网络后重试'));
      }
    }, 20000);

    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 15000,
      header: { 'Accept': 'application/json' }
    };

    request.request(url, options, (err: BusinessError, resp: http.HttpResponse) => {
      if (settled) {
        return;
      }
      settled = true;
      clearTimeout(timer);
      request.destroy();
      if (err) {
        hilog.error(DOMAIN, TAG, 'request failed: %{public}s %{public}s', url, err.message);
        reject(new Error('网络请求失败，请检查网络连接'));
        return;
      }
      if (resp.responseCode !== 200) {
        hilog.error(DOMAIN, TAG, 'http %{public}d %{public}s', resp.responseCode, url);
        reject(new Error(`天气服务返回异常（${resp.responseCode}）`));
        return;
      }
      resolve(resp.result as string);
    });
  });
}

/** 拉取某坐标的 10 天预报 + 逐小时预报 */
export async function wxFetchForecast(lat: number, lon: number): Promise<WxRawForecast> {
  const url: string = `${FORECAST_URL}?latitude=${lat.toFixed(4)}&longitude=${lon.toFixed(4)}` +
    `&current=${CURRENT_FIELDS}&hourly=${HOURLY_FIELDS}&daily=${DAILY_FIELDS}` +
    `&timezone=auto&past_days=1&forecast_days=10&wind_speed_unit=kmh`;
  const text: string = await wxHttpGet(url);
  return JSON.parse(text) as WxRawForecast;
}

/** 拉取空气质量，失败时返回 null（不阻塞主天气展示） */
export async function wxFetchAir(lat: number, lon: number): Promise<WxRawAir | null> {
  try {
    const url: string = `${AIR_URL}?latitude=${lat.toFixed(4)}&longitude=${lon.toFixed(4)}` +
      `&current=pm2_5,pm10,european_aqi&timezone=auto`;
    const text: string = await wxHttpGet(url);
    return JSON.parse(text) as WxRawAir;
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'air quality failed: %{public}s', (error as Error).message);
    return null;
  }
}

/** 城市检索（中文优先） */
export async function wxSearchCities(keyword: string): Promise<WxCity[]> {
  const query: string = keyword.trim();
  const result: WxCity[] = [];
  if (query.length === 0) {
    return result;
  }
  const url: string =
    `${GEO_URL}?name=${encodeURIComponent(query)}&count=12&language=zh&format=json`;
  const text: string = await wxHttpGet(url);
  const parsed: WxGeoResponse = JSON.parse(text) as WxGeoResponse;
  const items: WxGeoItem[] = parsed.results ?? [];
  const seen: string[] = [];
  for (let i = 0; i < items.length; i++) {
    const item: WxGeoItem = items[i];
    if (item.latitude === undefined || item.longitude === undefined) {
      continue;
    }
    const name: string = item.name ?? query;
    const admin: string = item.admin1 ?? '';
    const country: string = item.country ?? '';
    let region: string = admin;
    if (region.length === 0) {
      region = country;
    } else if (country.length > 0 && country !== admin) {
      region = `${admin}，${country}`;
    }
    const dedupeKey: string = `${name}|${admin}|${country}`;
    if (seen.includes(dedupeKey)) {
      continue;
    }
    seen.push(dedupeKey);
    const id: string = `${name}_${item.latitude.toFixed(3)}_${item.longitude.toFixed(3)}`;
    result.push({
      id: id,
      name: name,
      region: region,
      lat: item.latitude,
      lon: item.longitude,
      isLocated: false
    });
    if (result.length >= 8) {
      break;
    }
  }
  return result;
}
