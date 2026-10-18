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
  @LocalStorageProp('hours') hours: WgHour[] = [];
  @LocalStorageProp('days') days: WgDay[] = [];

  private dayList(maxCount: number): WgDay[] {
    const result: WgDay[] = [];
    for (let i = 0; i < this.days.length && i < maxCount; i++) {
      result.push(this.days[i]);
    }
    return result;
  }

  private hourList(maxCount: number): WgHour[] {
    const result: WgHour[] = [];
    for (let i = 0; i < this.hours.length && i < maxCount; i++) {
      result.push(this.hours[i]);
    }
    return result;
  }

  @Builder
  dayRow($$: WgDayRowParam) {
    Row() {
      Text($$.day.weekday)
        .fontSize(13)
        .fontColor($$.day.isPast ? '#99FFFFFF' : '#E6FFFFFF')
        .width(42)
      Image(wgIcon($$.day.code, true))
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
        .opacity($$.day.isPast ? 0.6 : 1)
      Blank()
      Text(`${$$.day.min}°/${$$.day.max}°`)
        .fontSize(13)
        .fontColor($$.day.isPast ? '#99FFFFFF' : Color.White)
    }
    .width('100%')
    .height(19)
    .opacity($$.day.isPast ? 0.85 : 1)
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
              this.dayRow({ day: day })
            }, (day: WgDay) => `wd_${day.weekday}`)
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
              .fontSize(15)
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
            Image($r('app.media.ic_ui_refresh'))
              .width(15)
              .height(15)
              .fillColor('#B3FFFFFF')
              .onClick(() => {
                postCardAction(this, {
                  action: 'message',
                  params: { msg: 'refresh' }
                });
              })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row({ space: 8 }) {
          Text(this.desc)
            .fontSize(13)
            .fontColor(Color.White)
          Text(this.rangeText)
            .fontSize(12)
            .fontColor('#B3FFFFFF')
        }
        .width('100%')
        .margin({ top: 2 })

        Divider()
          .strokeWidth(0.5)
          .color('#33FFFFFF')
          .margin({ top: 6, bottom: 4 })

        Row() {
          ForEach(this.hourList(6), (item: WgHour) => {
            Column({ space: 2 }) {
              Text(item.label)
                .fontSize(11)
                .fontColor('#D9FFFFFF')
              Image(wgIcon(item.code, item.isDay))
                .width(19)
                .height(19)
                .objectFit(ImageFit.Contain)
              Text(`${item.temp}°`)
                .fontSize(12)
                .fontColor(Color.White)
            }
            .layoutWeight(1)
          }, (item: WgHour) => `hl_${item.label}`)
        }
        .width('100%')

        Divider()
          .strokeWidth(0.5)
          .color('#33FFFFFF')
          .margin({ top: 5, bottom: 3 })

        ForEach(this.dayList(6), (day: WgDay) => {
          this.dayRow({ day: day })
        }, (day: WgDay) => `dl_${day.weekday}`)

        Blank()

        Text(this.updated.length > 0 ? `更新于 ${this.updated}` : '轻触打开天气')
          .fontSize(10)
          .fontColor('#99FFFFFF')
          .width('100%')
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
