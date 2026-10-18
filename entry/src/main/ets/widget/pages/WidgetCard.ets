interface WgHour {
  label: string;
  temp: number;
  code: number;
  isDay: boolean;
}

interface WgDay {
  weekday: string;
  min: number;
  max: number;
  code: number;
  isPast: boolean;
}

function wgIcon(code: number, isDay: boolean): Resource {
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

interface WgDayRowParam {
  day: WgDay;
  /** 4×4 里让每行均分剩余高度，2×4 保持紧凑行高 */
  stretch: boolean;
}

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('cityName') cityName: string = '北京';
  @LocalStorageProp('tempText') tempText: string = '--';
  @LocalStorageProp('desc') desc: string = '正在获取天气';
  @LocalStorageProp('rangeText') rangeText: string = '';
  @LocalStorageProp('code') code: number = 0;
  @LocalStorageProp('isDay') isDay: boolean = true;
  @LocalStorageProp('updated') updated: string = '';
  @LocalStorageProp('g0') g0: string = '#2C6FC4';
  @LocalStorageProp('g1') g1: string = '#4E9BD8';
  @LocalStorageProp('g2') g2: string = '#8FC6EA';
  @LocalStorageProp('layout') layout: string = 'small';
  @LocalStorageProp('dayTotal') dayTotal: number = 0;
  @LocalStorageProp('dayA') dayA: string = '';
  @LocalStorageProp('dayB') dayB: string = '';
  @LocalStorageProp('dayC') dayC: string = '';
  @LocalStorageProp('dayD') dayD: string = '';
  @LocalStorageProp('dayE') dayE: string = '';
  @LocalStorageProp('dayF') dayF: string = '';
  @LocalStorageProp('dayG') dayG: string = '';
  @LocalStorageProp('dayH') dayH: string = '';
  @LocalStorageProp('hourTotal') hourTotal: number = 0;
  @LocalStorageProp('hourA') hourA: string = '';
  @LocalStorageProp('hourB') hourB: string = '';
  @LocalStorageProp('hourC') hourC: string = '';
  @LocalStorageProp('hourD') hourD: string = '';
  @LocalStorageProp('hourE') hourE: string = '';
  @LocalStorageProp('hourF') hourF: string = '';

  /** 每项格式：星期|最低|最高|天气码|是否过去 */
  private parseDay(raw: string): WgDay | null {
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

  /** 每项格式：时标|温度|天气码|是否白天 */
  private parseHour(raw: string): WgHour | null {
    if (raw.length === 0) {
      return null;
    }
    const parts: string[] = raw.split('|');
    if (parts.length < 4) {
      return null;
    }
    return {
      label: parts[0],
      temp: Number(parts[1]),
      code: Number(parts[2]),
      isDay: parts[3] === '1'
    };
  }

  private allDays(): WgDay[] {
    const raw: string[] = [this.dayA, this.dayB, this.dayC, this.dayD, this.dayE, this.dayF, this.dayG, this.dayH];
    const result: WgDay[] = [];
    const count: number = Math.min(this.dayTotal, raw.length);
    for (let i = 0; i < count; i++) {
      const item: WgDay | null = this.parseDay(raw[i]);
      if (item !== null) {
        result.push(item);
      }
    }
    return result;
  }

  private allHours(): WgHour[] {
    const raw: string[] = [this.hourA, this.hourB, this.hourC, this.hourD, this.hourE, this.hourF];
    const result: WgHour[] = [];
    const count: number = Math.min(this.hourTotal, raw.length);
    for (let i = 0; i < count; i++) {
      const item: WgHour | null = this.parseHour(raw[i]);
      if (item !== null) {
        result.push(item);
      }
    }
    return result;
  }

  private dayList(maxCount: number): WgDay[] {
    const all: WgDay[] = this.allDays();
    const result: WgDay[] = [];
    for (let i = 0; i < all.length && i < maxCount; i++) {
      result.push(all[i]);
    }
    return result;
  }

  private hourList(maxCount: number): WgHour[] {
    const all: WgHour[] = this.allHours();
    const result: WgHour[] = [];
    for (let i = 0; i < all.length && i < maxCount; i++) {
      result.push(all[i]);
    }
    return result;
  }

  @Builder
  dayRow($$: WgDayRowParam) {
    Row() {
      Text($$.day.weekday)
        .fontSize(14)
        .fontColor($$.day.isPast ? '#99FFFFFF' : '#E6FFFFFF')
        .width(48)
      // 图标不做透明度：黄白配色的天气图标在半透明下会糊成一团灰点
      Image(wgIcon($$.day.code, true))
        .width(19)
        .height(19)
        .objectFit(ImageFit.Contain)
      Blank()
      Text(`${$$.day.min}°/${$$.day.max}°`)
        .fontSize(14)
        .fontColor($$.day.isPast ? '#99FFFFFF' : Color.White)
    }
    .width('100%')
    .layoutWeight($$.stretch ? 1 : 0)
  }

  build() {
    Column() {
      if (this.layout === 'wide') {
        Row() {
          Column() {
            Text(this.cityName)
              .fontSize(13)
              .fontColor('#E6FFFFFF')
              .maxLines(1)
            Row() {
              Text(this.tempText)
                .fontSize(32)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
              Image(wgIcon(this.code, this.isDay))
                .width(30)
                .height(30)
                .objectFit(ImageFit.Contain)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ top: 2 })

            Blank()

            Text(this.desc)
              .fontSize(12)
              .fontColor(Color.White)
              .maxLines(1)
            Text(this.rangeText)
              .fontSize(10)
              .fontColor('#CCFFFFFF')
              .maxLines(1)
              .margin({ top: 2 })
          }
          .width('44%')
          .height('100%')
          .alignItems(HorizontalAlign.Start)

          Divider()
            .vertical(true)
            .height('86%')
            .strokeWidth(0.5)
            .color('#33FFFFFF')
            .margin({ left: 8, right: 10 })

          Column() {
            ForEach(this.dayList(5), (day: WgDay) => {
              this.dayRow({ day: day, stretch: false })
            }, (day: WgDay) => `wd_${day.weekday}_${day.min}_${day.max}_${day.code}`)
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Center)
      } else if (this.layout === 'large') {
        Row() {
          Column({ space: 2 }) {
            Text(this.cityName)
              .fontSize(14)
              .fontColor('#E6FFFFFF')
              .maxLines(1)
            Text(this.tempText)
              .fontSize(32)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column({ space: 6 }) {
            Image(wgIcon(this.code, this.isDay))
              .width(42)
              .height(42)
              .objectFit(ImageFit.Contain)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Text(this.desc)
          .fontSize(14)
          .fontColor(Color.White)
          .margin({ top: 2 })
          .width('100%')
        Text(this.rangeText)
          .fontSize(13)
          .fontColor('#CCFFFFFF')
          .margin({ top: 4 })
          .width('100%')

        Divider()
          .strokeWidth(0.5)
          .color('#33FFFFFF')
          .margin({ top: 6, bottom: 4 })

        Row() {
          ForEach(this.hourList(6), (item: WgHour) => {
            Column({ space: 4 }) {
              Text(item.label)
                .fontSize(14)
                .fontColor('#D9FFFFFF')
              Image(wgIcon(item.code, item.isDay))
                .width(20)
                .height(20)
                .objectFit(ImageFit.Contain)
              Text(`${item.temp}°`)
                .fontSize(14)
                .fontColor(Color.White)
            }
            .layoutWeight(1)
          }, (item: WgHour) => `hl_${item.label}_${item.temp}_${item.code}`)
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 })

        Divider()
          .strokeWidth(0.5)
          .color('#33FFFFFF')
          .margin({ top: 4, bottom: 2 })

        Column() {
          ForEach(this.dayList(5), (day: WgDay) => {
            this.dayRow({ day: day, stretch: true })
          }, (day: WgDay) => `dl_${day.weekday}_${day.min}_${day.max}_${day.code}`)
        }
        .layoutWeight(1)
        .width('100%')

        Text(this.updated.length > 0 ? `更新于 ${this.updated}` : '轻触打开天气')
          .fontSize(10)
          .fontColor('#99FFFFFF')
          .width('100%')
          .margin({ top: 2 })
      } else {
        Row() {
          Text(this.cityName)
            .fontSize(13)
            .fontColor('#E6FFFFFF')
            .maxLines(1)
          Blank()
        }
        .width('100%')

        Blank()

        Row() {
          Text(this.tempText)
            .fontSize(32)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          Blank()
          Image(wgIcon(this.code, this.isDay))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Blank()

        Text(this.desc)
          .fontSize(12)
          .fontColor(Color.White)
          .maxLines(1)
          .width('100%')
        Text(this.rangeText)
          .fontSize(10)
          .fontColor('#CCFFFFFF')
          .maxLines(1)
          .margin({ top: 2 })
          .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(this.layout === 'small' ? 12 : 14)
    .alignItems(HorizontalAlign.Start)
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
