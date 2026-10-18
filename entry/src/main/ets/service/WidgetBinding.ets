import { formInfo } from '@kit.FormKit';
import { WxWidgetDay, WxWidgetHour, WxWidgetSnapshot } from './WidgetSnapshot';

/** 传给卡片的绑定数据，字段名必须与各卡片页面的 @LocalStorageProp 逐字一致 */
export interface WxWidgetBinding {
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
  /** small = 2*2，wide = 2*4，large = 4*4 */
  layout: string;
  hours: WxWidgetHour[];
  days: WxWidgetDay[];
}

export function wxDimensionLayout(dimension: number): string {
  if (dimension === formInfo.FormDimension.Dimension_2_4) {
    return 'wide';
  }
  if (dimension === formInfo.FormDimension.Dimension_4_4) {
    return 'large';
  }
  return 'small';
}

export function wxBuildWidgetBinding(snapshot: WxWidgetSnapshot, layout: string): WxWidgetBinding {
  return {
    cityName: snapshot.cityName,
    tempText: snapshot.tempText,
    desc: snapshot.desc,
    rangeText: snapshot.rangeText,
    code: snapshot.code,
    isDay: snapshot.isDay,
    updated: snapshot.updated,
    g0: snapshot.g0,
    g1: snapshot.g1,
    g2: snapshot.g2,
    layout: layout,
    hours: snapshot.hours,
    days: snapshot.days
  };
}

export function wxBuildPlaceholderBinding(layout: string): WxWidgetBinding {
  return {
    cityName: '天气',
    tempText: '--',
    desc: '正在获取天气…',
    rangeText: '',
    code: 0,
    isDay: true,
    updated: '',
    g0: '#2C6FC4',
    g1: '#4E9BD8',
    g2: '#8FC6EA',
    layout: layout,
    hours: [],
    days: []
  };
}
