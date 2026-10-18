import { WxTheme } from '../model/WeatherModels';

/**
 * WMO 天气码 → 中文描述 / 图标 / 背景主题。
 * 参考 Open-Meteo 文档的 WMO Weather interpretation codes。
 */

export function wxDesc(code: number): string {
  if (code === 0) {
    return '晴';
  }
  if (code === 1) {
    return '晴间少云';
  }
  if (code === 2) {
    return '局部多云';
  }
  if (code === 3) {
    return '阴';
  }
  if (code === 45 || code === 48) {
    return '雾';
  }
  if (code === 51 || code === 53 || code === 55) {
    return '毛毛雨';
  }
  if (code === 56 || code === 57) {
    return '冻毛毛雨';
  }
  if (code === 61) {
    return '小雨';
  }
  if (code === 63) {
    return '中雨';
  }
  if (code === 65) {
    return '大雨';
  }
  if (code === 66 || code === 67) {
    return '冻雨';
  }
  if (code === 71) {
    return '小雪';
  }
  if (code === 73) {
    return '中雪';
  }
  if (code === 75) {
    return '大雪';
  }
  if (code === 77) {
    return '雪粒';
  }
  if (code === 80) {
    return '小阵雨';
  }
  if (code === 81) {
    return '阵雨';
  }
  if (code === 82) {
    return '强阵雨';
  }
  if (code === 85) {
    return '小阵雪';
  }
  if (code === 86) {
    return '阵雪';
  }
  if (code === 95) {
    return '雷阵雨';
  }
  if (code === 96 || code === 99) {
    return '雷阵雨伴冰雹';
  }
  return '多云';
}

export function wxIcon(code: number, isDay: boolean): Resource {
  if (code === 0) {
    return isDay ? $r('app.media.ic_wx_sun') : $r('app.media.ic_wx_moon');
  }
  if (code === 1 || code === 2) {
    return isDay ? $r('app.media.ic_wx_partly_day') : $r('app.media.ic_wx_partly_night');
  }
  if (code === 3) {
    return $r('app.media.ic_wx_overcast');
  }
  if (code === 45 || code === 48) {
    return $r('app.media.ic_wx_fog');
  }
  if (code === 51 || code === 53 || code === 55 || code === 56 || code === 57) {
    return $r('app.media.ic_wx_drizzle');
  }
  if (code === 61 || code === 63 || code === 80 || code === 81) {
    return $r('app.media.ic_wx_rain');
  }
  if (code === 65 || code === 66 || code === 67 || code === 82) {
    return $r('app.media.ic_wx_heavy_rain');
  }
  if (code === 71 || code === 73 || code === 75 || code === 77 || code === 85 || code === 86) {
    return $r('app.media.ic_wx_snow');
  }
  if (code === 95 || code === 96 || code === 99) {
    return $r('app.media.ic_wx_thunder');
  }
  return $r('app.media.ic_wx_cloudy');
}

function wxThemeByKey(key: string, isDark: boolean): WxTheme {
  const theme: WxTheme = { key: key, gradient: [], isDark: isDark };
  if (key === 'clear_day') {
    theme.gradient = ['#2C6FC4', '#4E9BD8', '#8FC6EA'];
  } else if (key === 'clear_night') {
    theme.gradient = ['#080F26', '#141F44', '#2A3A66'];
    theme.isDark = true;
  } else if (key === 'partly_day') {
    theme.gradient = ['#33689C', '#5B93BD', '#9CC3D8'];
  } else if (key === 'partly_night') {
    theme.gradient = ['#0D1529', '#1C2947', '#334566'];
    theme.isDark = true;
  } else if (key === 'cloudy') {
    theme.gradient = ['#4E6376', '#728597', '#9CABBA'];
  } else if (key === 'overcast') {
    theme.gradient = ['#3F4C57', '#5C6A76', '#83909B'];
  } else if (key === 'fog') {
    theme.gradient = ['#525B64', '#717A83', '#98A1A8'];
  } else if (key === 'rain') {
    theme.gradient = ['#28394A', '#3E5566', '#62798A'];
    theme.isDark = true;
  } else if (key === 'heavy_rain') {
    theme.gradient = ['#1A242E', '#2A3A46', '#425663'];
    theme.isDark = true;
  } else if (key === 'thunder') {
    theme.gradient = ['#151724', '#262A3D', '#3E4459'];
    theme.isDark = true;
  } else if (key === 'snow') {
    theme.gradient = ['#41566C', '#6F8499', '#AFC0D0'];
  } else {
    theme.gradient = ['#3B6E96', '#5E90B5', '#94BBD3'];
  }
  return theme;
}

export function wxTheme(code: number, isDay: boolean): WxTheme {
  let key = 'cloudy';
  if (code === 0) {
    key = isDay ? 'clear_day' : 'clear_night';
  } else if (code === 1 || code === 2) {
    key = isDay ? 'partly_day' : 'partly_night';
  } else if (code === 3) {
    key = 'overcast';
  } else if (code === 45 || code === 48) {
    key = 'fog';
  } else if (code >= 51 && code <= 57) {
    key = 'rain';
  } else if (code === 61 || code === 63) {
    key = 'rain';
  } else if (code >= 65 && code <= 67) {
    key = 'heavy_rain';
  } else if (code === 80 || code === 81) {
    key = 'rain';
  } else if (code === 82) {
    key = 'heavy_rain';
  } else if ((code >= 71 && code <= 77) || code === 85 || code === 86) {
    key = 'snow';
  } else if (code >= 95) {
    key = 'thunder';
  }
  return wxThemeByKey(key, !isDay);
}

/** 风向角度 → 中文方位 */
export function wxWindDir(deg: number): string {
  const dirs: string[] = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
  let idx = Math.round(deg / 45) % 8;
  if (idx < 0) {
    idx = 0;
  }
  return dirs[idx] + '风';
}

/** 紫外线指数描述（沿用 WHO 分级） */
export function wxUvDesc(uv: number): string {
  if (uv < 3) {
    return '低';
  }
  if (uv < 6) {
    return '中等';
  }
  if (uv < 8) {
    return '高';
  }
  if (uv < 11) {
    return '很高';
  }
  return '极高';
}

/** AQI 描述（欧洲 AQI 分级） */
export function wxAqiDesc(aqi: number): string {
  if (aqi <= 20) {
    return '优';
  }
  if (aqi <= 40) {
    return '良';
  }
  if (aqi <= 60) {
    return '中等';
  }
  if (aqi <= 80) {
    return '较差';
  }
  if (aqi <= 100) {
    return '差';
  }
  return '极差';
}

/** AQI 对应的强调色 */
export function wxAqiColor(aqi: number): string {
  if (aqi <= 20) {
    return '#5BD48A';
  }
  if (aqi <= 40) {
    return '#A8D95B';
  }
  if (aqi <= 60) {
    return '#F2C94C';
  }
  if (aqi <= 80) {
    return '#F2994A';
  }
  if (aqi <= 100) {
    return '#EB5757';
  }
  return '#B23A3A';
}
