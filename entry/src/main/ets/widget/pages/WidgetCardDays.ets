interface WgDayItem {
  weekday: string;
  min: number;
  max: number;
  code: number;
  isPast: boolean;
}

function wgdIcon(code: number, isDay: boolean): Resource {
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
  if (code >= 51 && code <= 57) {
    return $r('app.media.ic_wx_drizzle');
  }
  if (code === 61 || code === 63 || code === 80 || code === 81) {
    return $r('app.media.ic_wx_rain');
  }
  if (code === 65 || code === 66 || code === 67 || code === 82) {
    return $r('app.media.ic_wx_heavy_rain');
  }
  if ((code >= 71 && code <= 77) || code === 85 || code === 86) {
    return $r('app.media.ic_wx_snow');
  }
  if (code >= 95) {
    return $r('app.media.ic_wx_thunder');
  }
  return $r('app.media.ic_wx_cloudy');
}

/** 每一天那行的行高，左右两列共用，保证横向对齐 */
const ROW_HEIGHT: number = 18;
/** 右侧数字列的固定宽度：低温 16 + 高温 24 */
const RIGHT_COL_WIDTH: number = 64;

let storageDays: LocalStorage = new LocalStorage();

/**
 * 2×2 双栏卡片：左侧「城市 + 当前温度 + 未来四天星期」，
 * 右侧「当前天气图标 + 今天高低温 + 未来四天图标与温度」。
 *
 * 右侧每一天是固定列宽的 Row（图标 / 低温 / 高温各占固定位置），
 * 不能靠「整行内容右对齐」——那样不同天的温度位数不一样，图标会左右漂。
 */
@Entry(storageDays)
@Component
struct WidgetCardDays {
  @LocalStorageProp('cityName') cityName: string = '北京';
  @LocalStorageProp('tempText') tempText: string = '--';
  @LocalStorageProp('code') code: number = 0;
  @LocalStorageProp('isDay') isDay: boolean = true;
  @LocalStorageProp('g0') g0: string = '#2C6FC4';
  @LocalStorageProp('g1') g1: string = '#4E9BD8';
  @LocalStorageProp('g2') g2: string = '#8FC6EA';
  @LocalStorageProp('dayTotal') dayTotal: number = 0;
  @LocalStorageProp('dayA') dayA: string = '';
  @LocalStorageProp('dayB') dayB: string = '';
  @LocalStorageProp('dayC') dayC: string = '';
  @LocalStorageProp('dayD') dayD: string = '';
  @LocalStorageProp('dayE') dayE: string = '';
  @LocalStorageProp('dayF') dayF: string = '';
  @LocalStorageProp('dayG') dayG: string = '';
  @LocalStorageProp('dayH') dayH: string = '';

  /** 每项格式：星期|最低|最高|天气码|是否过去 */
  private parseDay(raw: string): WgDayItem | null {
    if (raw.length === 0) {
      return null;
    }
    const parts: string[] = raw.split('|');
    if (parts.length < 5) {
      return null;
    }
    return {
      weekday: parts[0],
      min: Number(parts[1]),
      max: Number(parts[2]),
      code: Number(parts[3]),
      isPast: parts[4] === '1'
    };
  }

  private allDays(): WgDayItem[] {
    const raw: string[] = [this.dayA, this.dayB, this.dayC, this.dayD, this.dayE, this.dayF, this.dayG, this.dayH];
    const result: WgDayItem[] = [];
    const count: number = Math.min(this.dayTotal, raw.length);
    for (let i = 0; i < count; i++) {
      const item: WgDayItem | null = this.parseDay(raw[i]);
      if (item !== null) {
        result.push(item);
      }
    }
    return result;
  }

  /** 今天在 days 里的下标；找不到就当 0 */
  private todayIndex(): number {
    const list: WgDayItem[] = this.allDays();
    for (let i = 0; i < list.length; i++) {
      if (list[i].weekday === '今天') {
        return i;
      }
    }
    return 0;
  }

  /** 明天起的四天，与左列星期一一对应 */
  private futureDays(): WgDayItem[] {
    const list: WgDayItem[] = this.allDays();
    const result: WgDayItem[] = [];
    const start: number = this.todayIndex() + 1;
    for (let i = start; i < list.length && result.length < 4; i++) {
      result.push(list[i]);
    }
    if (result.length === 0) {
      for (let i = 0; i < list.length && result.length < 4; i++) {
        result.push(list[i]);
      }
    }
    return result;
  }

  private todayMax(): number {
    const list: WgDayItem[] = this.allDays();
    const index: number = this.todayIndex();
    return list.length > index ? list[index].max : 0;
  }

  private todayMin(): number {
    const list: WgDayItem[] = this.allDays();
    const index: number = this.todayIndex();
    return list.length > index ? list[index].min : 0;
  }

  build() {
    Row() {
      Column() {
        Text(this.cityName)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.tempText)
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .margin({ top: 1 })

        Blank()

        ForEach(this.futureDays(), (day: WgDayItem) => {
          Text(day.weekday)
            .fontSize(12)
            .fontColor('#E6FFFFFF')
            .height(ROW_HEIGHT)
            .width('100%')
        }, (day: WgDayItem) => `wd_${day.weekday}_${day.min}_${day.max}_${day.code}`)
      }
      .layoutWeight(1)
      .height('100%')
      .alignItems(HorizontalAlign.Start)

      Column() {
        Image(wgdIcon(this.code, this.isDay))
          .width(17)
          .height(17)
          .objectFit(ImageFit.Contain)

        Text(`${this.todayMax()}°`)
          .fontSize(14)
          .fontColor(Color.White)
          .margin({ top: 2 })
        Text(`${this.todayMin()}°`)
          .fontSize(13)
          .fontColor('#CCFFFFFF')

        Blank()

        ForEach(this.futureDays(), (day: WgDayItem) => {
          Row() {
            Image(wgdIcon(day.code, true))
              .width(17)
              .height(17)
              .objectFit(ImageFit.Contain)
            Blank()
            Text(`${day.min}`)
              .fontSize(12)
              .fontColor('#B3FFFFFF')
              .width(16)
              .textAlign(TextAlign.End)
            Text(`${day.max}°`)
              .fontSize(12)
              .fontColor(Color.White)
              .width(24)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(ROW_HEIGHT)
          .alignItems(VerticalAlign.Center)
        }, (day: WgDayItem) => `rd_${day.weekday}_${day.min}_${day.max}_${day.code}`)
      }
      .width(RIGHT_COL_WIDTH)
      .height('100%')
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .alignItems(VerticalAlign.Top)
    .linearGradient({
      angle: 180,
      colors: [[this.g0, 0.0], [this.g1, 0.55], [this.g2, 1.0]]
    })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility'
      });
    })
  }
}
