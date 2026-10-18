/**
 * 天气 App 的数据模型。
 * 命名统一加 Wx 前缀，避免跨文件 interface 重名（arkts-no-decl-merging）。
 */

/** 城市（本地持久化用） */
export interface WxCity {
  id: string;
  name: string;
  region: string;
  lat: number;
  lon: number;
  /** 是否为「定位得到」的城市 */
  isLocated: boolean;
}

/** Open-Meteo current 字段（全部可选，解析时统一兜底） */
export interface WxRawCurrent {
  time?: string;
  temperature_2m?: number;
  relative_humidity_2m?: number;
  apparent_temperature?: number;
  is_day?: number;
  precipitation?: number;
  weather_code?: number;
  cloud_cover?: number;
  pressure_msl?: number;
  wind_speed_10m?: number;
  wind_direction_10m?: number;
  wind_gusts_10m?: number;
}

export interface WxRawHourly {
  time?: string[];
  temperature_2m?: number[];
  weather_code?: number[];
  precipitation_probability?: number[];
  is_day?: number[];
  visibility?: number[];
}

export interface WxRawDaily {
  time?: string[];
  weather_code?: number[];
  temperature_2m_max?: number[];
  temperature_2m_min?: number[];
  sunrise?: string[];
  sunset?: string[];
  uv_index_max?: number[];
  precipitation_probability_max?: number[];
  precipitation_sum?: number[];
  wind_speed_10m_max?: number[];
}

export interface WxRawForecast {
  latitude?: number;
  longitude?: number;
  timezone?: string;
  current?: WxRawCurrent;
  hourly?: WxRawHourly;
  daily?: WxRawDaily;
}

/** 空气质量（Open-Meteo Air Quality） */
export interface WxRawAirCurrent {
  time?: string;
  pm2_5?: number;
  pm10?: number;
  european_aqi?: number;
  us_aqi?: number;
}

export interface WxRawAir {
  current?: WxRawAirCurrent;
}

/** 地理编码结果 */
export interface WxGeoItem {
  id?: number;
  name?: string;
  latitude?: number;
  longitude?: number;
  country?: string;
  country_code?: string;
  admin1?: string;
  timezone?: string;
}

export interface WxGeoResponse {
  results?: WxGeoItem[];
}

/** 小时预报（已转换为 UI 直接可用） */
export interface WxHourPoint {
  key: string;
  label: string;
  temp: number;
  pop: number;
  code: number;
  isDay: boolean;
}

/** 逐日预报 */
export interface WxDayPoint {
  key: string;
  weekday: string;
  code: number;
  min: number;
  max: number;
  pop: number;
  precip: number;
  windMax: number;
  uvMax: number;
  /** 是否为已经过去的一天（昨天），UI 上做淡化处理 */
  isPast: boolean;
}

/** 指标区（2 列卡片） */
export interface WxMetrics {
  airTemp: number;
  feelsLike: number;
  humidity: number;
  windSpeed: number;
  windDir: string;
  windGust: number;
  pressure: number;
  visibility: number;
  uvIndex: number;
  uvDesc: string;
  sunrise: string;
  sunset: string;
  precipToday: number;
  aqi: number;
  aqiDesc: string;
  pm25: number;
  cloudCover: number;
}

/** 背景主题 */
export interface WxTheme {
  key: string;
  gradient: string[];
  isDark: boolean;
}

/** 单城市的完整天气快照 */
export interface WxCityWeather {
  city: WxCity;
  temp: number;
  feelsLike: number;
  code: number;
  isDay: boolean;
  desc: string;
  high: number;
  low: number;
  summary: string;
  hours: WxHourPoint[];
  days: WxDayPoint[];
  metrics: WxMetrics;
  theme: WxTheme;
  updatedAt: string;
  timezone: string;
}

/** 页面级加载状态 */
export enum WxLoadState {
  Idle = 0,
  Loading = 1,
  Ready = 2,
  Error = 3
}

/** 城市管理列表里的一张卡片（城市 + 该城市当前天气摘要） */
export interface WxCityCardItem {
  city: WxCity;
  hasData: boolean;
  temp: number;
  desc: string;
  rangeText: string;
  code: number;
  isDay: boolean;
  aqiText: string;
  gradient: string[];
}
