import {
  WxCity,
  WxCityWeather,
  WxRawForecast,
  WxRawAir,
  WxRawCurrent,
  WxRawHourly,
  WxRawDaily,
  WxHourPoint,
  WxDayPoint,
  WxMetrics,
  WxTheme
} from '../model/WeatherModels';
import { wxFetchForecast, wxFetchAir } from './OpenMeteoService';
import { wxDesc, wxTheme, wxWindDir, wxUvDesc, wxAqiDesc } from '../common/WeatherCode';

const WEEK_NAMES: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

function wxWeekday(dateStr: string, index: number, todayIndex: number): string {
  if (index < todayIndex) {
    return '昨天';
  }
  if (index === todayIndex) {
    return '今天';
  }
  if (index === todayIndex + 1) {
    return '明天';
  }
  const year: number = Number.parseInt(dateStr.substring(0, 4));
  const month: number = Number.parseInt(dateStr.substring(5, 7));
  const day: number = Number.parseInt(dateStr.substring(8, 10));
  const date: Date = new Date(year, month - 1, day);
  return WEEK_NAMES[date.getDay()] ?? '周一';
}

function wxClock(iso: string): string {
  if (iso.length < 16) {
    return '--:--';
  }
  return iso.substring(11, 16);
}

function wxNowClock(): string {
  const now: Date = new Date();
  const hh: string = now.getHours() < 10 ? `0${now.getHours()}` : `${now.getHours()}`;
  const mm: string = now.getMinutes() < 10 ? `0${now.getMinutes()}` : `${now.getMinutes()}`;
  return `${hh}:${mm}`;
}

function wxRound(value: number): number {
  return Math.round(value);
}

/** 把 Open-Meteo 的原始响应整理成 UI 可直接消费的快照 */
export async function wxLoadCityWeather(city: WxCity): Promise<WxCityWeather> {
  const airPromise: Promise<WxRawAir | null> = wxFetchAir(city.lat, city.lon);
  const forecast: WxRawForecast = await wxFetchForecast(city.lat, city.lon);
  const air: WxRawAir | null = await airPromise;

  const cur: WxRawCurrent = forecast.current ?? {};
  const hourly: WxRawHourly = forecast.hourly ?? {};
  const daily: WxRawDaily = forecast.daily ?? {};

  const isDay: boolean = (cur.is_day ?? 1) === 1;
  const code: number = cur.weather_code ?? 0;

  const times: string[] = hourly.time ?? [];
  const temps: number[] = hourly.temperature_2m ?? [];
  const codes: number[] = hourly.weather_code ?? [];
  const pops: number[] = hourly.precipitation_probability ?? [];
  const dayFlags: number[] = hourly.is_day ?? [];
  const visibilities: number[] = hourly.visibility ?? [];

  // 定位当前小时在 hourly 序列中的位置
  const curTime: string = cur.time ?? '';
  const curHourKey: string = curTime.length >= 13 ? curTime.substring(0, 13) : '';
  let startIndex: number = 0;
  if (curHourKey.length > 0) {
    const found: number = times.findIndex((item: string): boolean => item.substring(0, 13) === curHourKey);
    if (found >= 0) {
      startIndex = found;
    }
  }

  const hours: WxHourPoint[] = [];
  const hourEnd: number = Math.min(startIndex + 24, times.length);
  for (let i = startIndex; i < hourEnd; i++) {
    const timeStr: string = times[i];
    const hourValue: number = Number.parseInt(timeStr.substring(11, 13));
    hours.push({
      key: timeStr,
      label: i === startIndex ? '现在' : `${hourValue}时`,
      temp: wxRound(temps[i] ?? 0),
      pop: pops[i] ?? 0,
      code: codes[i] ?? 0,
      isDay: (dayFlags[i] ?? 1) === 1
    });
  }

  const dayTimes: string[] = daily.time ?? [];
  const dayCodes: number[] = daily.weather_code ?? [];
  const dayMax: number[] = daily.temperature_2m_max ?? [];
  const dayMin: number[] = daily.temperature_2m_min ?? [];
  const dayPop: number[] = daily.precipitation_probability_max ?? [];
  const dayPrecip: number[] = daily.precipitation_sum ?? [];
  const dayWind: number[] = daily.wind_speed_10m_max ?? [];
  const dayUv: number[] = daily.uv_index_max ?? [];

  const days: WxDayPoint[] = [];
  // daily 序列带 past_days=1，第 0 项是昨天；先定位「今天」的下标
  const currentDate: string = curTime.length >= 10 ? curTime.substring(0, 10) : '';
  let todayIndex: number = 0;
  if (currentDate.length === 10) {
    const foundToday: number = dayTimes.findIndex((item: string): boolean => item === currentDate);
    if (foundToday >= 0) {
      todayIndex = foundToday;
    }
  }

  for (let i = 0; i < dayTimes.length && i < 11; i++) {
    days.push({
      key: dayTimes[i],
      weekday: wxWeekday(dayTimes[i], i, todayIndex),
      code: dayCodes[i] ?? 0,
      min: wxRound(dayMin[i] ?? 0),
      max: wxRound(dayMax[i] ?? 0),
      pop: dayPop[i] ?? 0,
      precip: dayPrecip[i] ?? 0,
      windMax: wxRound(dayWind[i] ?? 0),
      uvMax: dayUv[i] ?? 0,
      isPast: i < todayIndex
    });
  }

  const todayOffset: number = todayIndex < days.length ? todayIndex : 0;
  const sunriseIso: string = (daily.sunrise ?? [])[todayOffset] ?? '';
  const sunsetIso: string = (daily.sunset ?? [])[todayOffset] ?? '';
  const uvToday: number = (selectedOrZero(dayUv, todayOffset));
  const aqiValue: number = air?.current?.european_aqi ?? -1;

  const metrics: WxMetrics = {
    airTemp: wxRound(cur.temperature_2m ?? 0),
    feelsLike: wxRound(cur.apparent_temperature ?? 0),
    humidity: wxRound(cur.relative_humidity_2m ?? 0),
    windSpeed: wxRound(cur.wind_speed_10m ?? 0),
    windDir: wxWindDir(cur.wind_direction_10m ?? 0),
    windGust: wxRound(cur.wind_gusts_10m ?? 0),
    pressure: wxRound(cur.pressure_msl ?? 0),
    visibility: Math.round(((visibilities[startIndex] ?? 10000) / 1000) * 10) / 10,
    uvIndex: Math.round(uvToday * 10) / 10,
    uvDesc: wxUvDesc(uvToday),
    sunrise: wxClock(sunriseIso),
    sunset: wxClock(sunsetIso),
    precipToday: Math.round(((dayPrecip[todayOffset] ?? 0)) * 10) / 10,
    aqi: aqiValue,
    aqiDesc: aqiValue >= 0 ? wxAqiDesc(aqiValue) : '',
    pm25: Math.round((air?.current?.pm2_5 ?? 0) * 10) / 10,
    cloudCover: wxRound(cur.cloud_cover ?? 0)
  };

  const theme: WxTheme = wxTheme(code, isDay);
  const desc: string = wxDesc(code);
  const high: number = days.length > todayOffset ? days[todayOffset].max : wxRound(cur.temperature_2m ?? 0);
  const low: number = days.length > todayOffset ? days[todayOffset].min : wxRound(cur.temperature_2m ?? 0);

  return {
    city: city,
    temp: wxRound(cur.temperature_2m ?? 0),
    feelsLike: metrics.feelsLike,
    code: code,
    isDay: isDay,
    desc: desc,
    high: high,
    low: low,
    summary: `今天：${desc}，最高 ${high}°，最低 ${low}°`,
    hours: hours,
    days: days,
    metrics: metrics,
    theme: theme,
    updatedAt: curTime.length >= 16 ? wxClock(curTime) : wxNowClock(),
    timezone: forecast.timezone ?? ''
  };
}

function selectedOrZero(source: number[], index: number): number {
  if (index < 0 || index >= source.length) {
    return 0;
  }
  return source[index] ?? 0;
}
