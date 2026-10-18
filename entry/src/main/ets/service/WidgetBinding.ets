import { formInfo } from '@kit.FormKit';
import { WxWidgetDay, WxWidgetHour, WxWidgetSnapshot } from './WidgetSnapshot';

/**
 * 传给卡片的绑定数据，字段名必须与各卡片页面的 @LocalStorageProp 逐字一致。
 *
 * 两条硬性约束（都是实测踩出来的）：
 *
 * 1. **不要往卡片传数组或嵌套对象**。卡片的 @LocalStorageProp 对数组只在首次
 *    绑定时生效，后续 formProvider.updateForm 不会刷新。
 * 2. **字段名只用纯字母**。早前用过 d0/d1/h0 这种「字母+数字」，结果 updateForm
 *    只刷新了 cityName 这类老字段，d0 那批新字段纹丝不动；换成 dayA/dayB 之后
 *    恢复正常。占位数据也刻意填成非空值（'-|0|0|0|0'），避免「空值不建立 key」。
 *
 * 每项格式：
 *   每日：星期|最低|最高|天气码|是否过去
 *   每小时：时标|温度|天气码|是否白天
 */
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
  /** 每日预报实际条数（0-8） */
  dayTotal: number;
  dayA: string;
  dayB: string;
  dayC: string;
  dayD: string;
  dayE: string;
  dayF: string;
  dayG: string;
  dayH: string;
  /** 每小时预报实际条数（0-6） */
  hourTotal: number;
  hourA: string;
  hourB: string;
  hourC: string;
  hourD: string;
  hourE: string;
  hourF: string;
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

function packDay(day: WxWidgetDay): string {
  return `${day.weekday}|${day.min}|${day.max}|${day.code}|${day.isPast ? 1 : 0}`;
}

function packHour(hour: WxWidgetHour): string {
  return `${hour.label}|${hour.temp}|${hour.code}|${hour.isDay ? 1 : 0}`;
}

function dayAt(list: WxWidgetDay[], index: number): string {
  return index < list.length ? packDay(list[index]) : '';
}

function hourAt(list: WxWidgetHour[], index: number): string {
  return index < list.length ? packHour(list[index]) : '';
}

/** 占位值刻意非空，保证每个字段在首次绑定时都真实建立了 LocalStorage key */
const PLACEHOLDER_DAY: string = '-|0|0|0|0';
const PLACEHOLDER_HOUR: string = '-|0|0|0';

export function wxBuildWidgetBinding(snapshot: WxWidgetSnapshot, layout: string): WxWidgetBinding {
  const hours: WxWidgetHour[] = snapshot.hours;
  const days: WxWidgetDay[] = snapshot.days;
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
    dayTotal: days.length,
    dayA: dayAt(days, 0) || PLACEHOLDER_DAY,
    dayB: dayAt(days, 1) || PLACEHOLDER_DAY,
    dayC: dayAt(days, 2) || PLACEHOLDER_DAY,
    dayD: dayAt(days, 3) || PLACEHOLDER_DAY,
    dayE: dayAt(days, 4) || PLACEHOLDER_DAY,
    dayF: dayAt(days, 5) || PLACEHOLDER_DAY,
    dayG: dayAt(days, 6) || PLACEHOLDER_DAY,
    dayH: dayAt(days, 7) || PLACEHOLDER_DAY,
    hourTotal: hours.length,
    hourA: hourAt(hours, 0) || PLACEHOLDER_HOUR,
    hourB: hourAt(hours, 1) || PLACEHOLDER_HOUR,
    hourC: hourAt(hours, 2) || PLACEHOLDER_HOUR,
    hourD: hourAt(hours, 3) || PLACEHOLDER_HOUR,
    hourE: hourAt(hours, 4) || PLACEHOLDER_HOUR,
    hourF: hourAt(hours, 5) || PLACEHOLDER_HOUR
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
    dayTotal: 0,
    dayA: PLACEHOLDER_DAY,
    dayB: PLACEHOLDER_DAY,
    dayC: PLACEHOLDER_DAY,
    dayD: PLACEHOLDER_DAY,
    dayE: PLACEHOLDER_DAY,
    dayF: PLACEHOLDER_DAY,
    dayG: PLACEHOLDER_DAY,
    dayH: PLACEHOLDER_DAY,
    hourTotal: 0,
    hourA: PLACEHOLDER_HOUR,
    hourB: PLACEHOLDER_HOUR,
    hourC: PLACEHOLDER_HOUR,
    hourD: PLACEHOLDER_HOUR,
    hourE: PLACEHOLDER_HOUR,
    hourF: PLACEHOLDER_HOUR
  };
}
