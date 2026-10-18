import { i18n } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0005;
const TAG: string = 'WxCalendarText';

const LUNAR_MONTHS: string[] = ['正月', '二月', '三月', '四月', '五月', '六月',
  '七月', '八月', '九月', '十月', '冬月', '腊月'];
const LUNAR_DAYS: string[] = ['初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
  '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
  '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'];
const WEEK_DAYS: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

export interface WxDateText {
  /** 10月18日周日 */
  dateText: string;
  /** 九月初九，取不到时为空 */
  lunarText: string;
  /** 重阳节，没有节日时为空 */
  festivalText: string;
  /** 00:28 —— 卡片用它做静态显示（卡片里的 TextTimer 无法从指定时间起走） */
  timeText: string;
  /** 当天已过的毫秒数 */
  timeBase: number;
}

function lunarFestival(month: number, day: number): string {
  if (month === 0 && day === 1) {
    return '春节';
  }
  if (month === 0 && day === 15) {
    return '元宵节';
  }
  if (month === 4 && day === 5) {
    return '端午节';
  }
  if (month === 6 && day === 7) {
    return '七夕';
  }
  if (month === 7 && day === 15) {
    return '中秋节';
  }
  if (month === 8 && day === 9) {
    return '重阳节';
  }
  if (month === 11 && day === 8) {
    return '腊八节';
  }
  return '';
}

function solarFestival(month: number, day: number): string {
  if (month === 1 && day === 1) {
    return '元旦';
  }
  if (month === 5 && day === 1) {
    return '劳动节';
  }
  if (month === 10 && day === 1) {
    return '国庆节';
  }
  if (month === 12 && day === 25) {
    return '圣诞节';
  }
  return '';
}

/** 组装桌面时钟卡片需要的日期文案（公历 + 农历 + 节日 + 走时基准） */
export function wxBuildDateText(now: Date): WxDateText {
  const dateText: string = `${now.getMonth() + 1}月${now.getDate()}日${WEEK_DAYS[now.getDay()]}`;
  let lunarText: string = '';
  let festivalText: string = '';

  try {
    const calendar: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'chinese');
    calendar.setTime(now);
    const month: number = calendar.get('month');
    const day: number = calendar.get('date');
    if (month >= 0 && month < 12 && day >= 1 && day <= 30) {
      lunarText = `${LUNAR_MONTHS[month]}${LUNAR_DAYS[day - 1]}`;
      festivalText = lunarFestival(month, day);
    }
  } catch (error) {
    hilog.warn(DOMAIN, TAG, 'lunar calc failed: %{public}s', (error as Error).message);
  }

  if (festivalText.length === 0) {
    festivalText = solarFestival(now.getMonth() + 1, now.getDate());
  }

  const hours: number = now.getHours();
  const minutes: number = now.getMinutes();
  const timeText: string = `${hours < 10 ? '0' : ''}${hours}:${minutes < 10 ? '0' : ''}${minutes}`;
  const timeBase: number = ((hours * 3600 + minutes * 60 + now.getSeconds())) * 1000;
  return {
    dateText: dateText,
    lunarText: lunarText,
    festivalText: festivalText,
    timeText: timeText,
    timeBase: timeBase
  };
}
