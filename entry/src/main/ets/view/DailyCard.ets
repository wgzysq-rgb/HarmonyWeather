import { WxDayPoint } from '../model/WeatherModels';
import { wxIcon } from '../common/WeatherCode';
import { WX_CARD_BG, WX_PAST_ROW_OPACITY, WX_TEXT_ACCENT, WX_TEXT_TERTIARY } from '../common/WxUi';
/** 10 天预报卡片：低温 / 温度条 / 高温，仿 iOS 天气 */
@Component
export struct WxDailyCard {
  @Prop days: WxDayPoint[] = [];

  private tempFloor(): number {
    let result: number = 1000;
    for (let i = 0; i < this.days.length; i++) {
      if (this.days[i].min < result) {
        result = this.days[i].min;
      }
    }
    return result === 1000 ? 0 : result;
  }

  private tempCeil(): number {
    let result: number = -1000;
    for (let i = 0; i < this.days.length; i++) {
      if (this.days[i].max > result) {
        result = this.days[i].max;
      }
    }
    return result === -1000 ? 0 : result;
  }

  /** 温度条左偏移（相对全区间） */
  private barOffset(day: WxDayPoint): string {
    const floor: number = this.tempFloor();
    const span: number = this.tempCeil() - floor;
    if (span <= 0) {
      return '0%';
    }
    const ratio: number = (day.min - floor) / span;
    return `${Math.round(ratio * 100)}%`;
  }

  /** 温度条宽度（相对全区间，至少 8% 以保证可见） */
  private barWidth(day: WxDayPoint): string {
    const span: number = this.tempCeil() - this.tempFloor();
    let percent: number = 8;
    if (span > 0) {
      percent = Math.max(8, Math.round(((day.max - day.min) / span) * 100));
    }
    const offset: number = Number.parseInt(this.barOffset(day).replace('%', ''));
    if (offset + percent > 100) {
      percent = 100 - offset;
    }
    return `${percent}%`;
  }

  build() {
    Column() {
      Row() {
        Text('每日预报')
          .fontSize(13)
          .fontColor('#CCFFFFFF')
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('最高 / 最低')
          .fontSize(12)
          .fontColor('#B3FFFFFF')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 8 })

      ForEach(this.days, (day: WxDayPoint, index: number) => {
        Column() {
          if (index > 0) {
            Divider()
              .strokeWidth(0.5)
              .color('#26FFFFFF')
              .margin({ left: 16, right: 16 })
          }
          Row() {
            Text(day.weekday)
              .fontSize(15)
              .fontColor(day.isPast ? '#B3FFFFFF' : Color.White)
              .fontWeight(day.weekday === '今天' ? FontWeight.Medium : FontWeight.Regular)
              .width(46)

            Image(wxIcon(day.code, true))
              .width(28)
              .height(28)
              .objectFit(ImageFit.Contain)
              .margin({ left: 4 })

            Text(`${day.pop}%`)
              .fontSize(12)
              .fontColor(day.isPast ? '#80FFFFFF' :
                (day.pop > 0 ? WX_TEXT_ACCENT : WX_TEXT_TERTIARY))
              .fontWeight(FontWeight.Medium)
              .width(38)
              .textAlign(TextAlign.Center)

            Text(`${day.min}°`)
              .fontSize(15)
              .fontColor(day.isPast ? '#99FFFFFF' : '#CCFFFFFF')
              .width(28)
              .textAlign(TextAlign.End)

            Stack({ alignContent: Alignment.Start }) {
              Row()
                .width('100%')
                .height(5)
                .borderRadius(2.5)
                .backgroundColor('#2EFFFFFF')

              Row()
                .width(this.barWidth(day))
                .height(5)
                .borderRadius(2.5)
                .margin({ left: this.barOffset(day) })
                .linearGradient({
                  angle: 90,
                  colors: [['#5AC8F5', 0.0], ['#7ED9A0', 0.35], ['#F5CB5C', 0.7], ['#F58A4B', 1.0]]
                })
            }
            .layoutWeight(1)
            .height(5)
            .margin({ left: 10, right: 10 })
            .opacity(day.isPast ? WX_PAST_ROW_OPACITY : 1)

            Text(`${day.max}°`)
              .fontSize(15)
              .fontColor(day.isPast ? '#B3FFFFFF' : Color.White)
              .width(28)
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }, (day: WxDayPoint) => day.key)

      Row()
        .height(8)
    }
    .width('100%')
    .backgroundColor(WX_CARD_BG)
    .borderRadius(20)
    .backgroundBlurStyle(BlurStyle.Thin)
    .clip(true)
  }
}
