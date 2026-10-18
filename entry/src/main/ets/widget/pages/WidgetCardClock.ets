function wgcIcon(code: number, isDay: boolean): Resource {
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

let storageClock: LocalStorage = new LocalStorage();

/**
 * 透明时钟卡片（2×4）：大号时间 + 公历/农历/节日 + 天气，整卡点击进天气应用。
 *
 * 这里没有用 TextTimer 做走时：它的 count 只在倒计时模式生效，
 * 正计时需要的 startTime 又被标成 @stagemodelonly（卡片不可用），
 * 在卡片里只会从 00:00 开始。所以时间由 FormExtensionAbility 算好传入，
 * 随卡片的 updateDuration 刷新。
 */
@Entry(storageClock)
@Component
struct WidgetCardClock {
  @LocalStorageProp('timeText') timeText: string = '--:--';
  @LocalStorageProp('dateText') dateText: string = '';
  @LocalStorageProp('lunarText') lunarText: string = '';
  @LocalStorageProp('festivalText') festivalText: string = '';
  @LocalStorageProp('tempText') tempText: string = '--';
  @LocalStorageProp('code') code: number = 0;
  @LocalStorageProp('isDay') isDay: boolean = true;

  build() {
    Column() {
      Text(this.timeText)
        .fontSize(56)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textShadow({ radius: 12, color: '#8C000000', offsetX: 0, offsetY: 2 })

      Row({ space: 7 }) {
        Text(this.dateText)
          .fontSize(12)
          .fontColor('#F2FFFFFF')
          .textShadow({ radius: 8, color: '#8C000000', offsetX: 0, offsetY: 1 })
        if (this.lunarText.length > 0) {
          Text(this.lunarText)
            .fontSize(12)
            .fontColor('#F2FFFFFF')
            .textShadow({ radius: 8, color: '#8C000000', offsetX: 0, offsetY: 1 })
        }
        if (this.festivalText.length > 0) {
          Text(this.festivalText)
            .fontSize(12)
            .fontColor('#F2FFFFFF')
            .textShadow({ radius: 8, color: '#8C000000', offsetX: 0, offsetY: 1 })
        }

        Text('|')
          .fontSize(12)
          .fontColor('#B3FFFFFF')

        Row({ space: 3 }) {
          Image(wgcIcon(this.code, this.isDay))
            .width(14)
            .height(14)
            .objectFit(ImageFit.Contain)
          Text(this.tempText)
            .fontSize(12)
            .fontColor('#F2FFFFFF')
            .textShadow({ radius: 8, color: '#8C000000', offsetX: 0, offsetY: 1 })
        }
      }
      .margin({ top: 6 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility'
      });
    })
  }
}
