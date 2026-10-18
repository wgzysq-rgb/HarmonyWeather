import { WxMetrics } from '../model/WeatherModels';
import { wxAqiColor } from '../common/WeatherCode';
import { WX_CARD_BG } from '../common/WxUi';

interface WxMetricEntry {
  id: string;
  title: string;
  value: string;
  unit: string;
  sub: string;
  icon: Resource;
  accent: string;
}

function wxVisibilityText(km: number): string {
  if (km >= 20) {
    return '视野通透';
  }
  if (km >= 10) {
    return '视野清晰';
  }
  if (km >= 4) {
    return '略有薄雾';
  }
  if (km >= 1) {
    return '能见度较低';
  }
  return '能见度很差';
}

/** 指标网格：2 列半透明毛玻璃卡片 */
@Component
export struct WxMetricsGrid {
  @Prop metrics: WxMetrics = {
    airTemp: 0,
    feelsLike: 0,
    humidity: 0,
    windSpeed: 0,
    windDir: '',
    windGust: 0,
    pressure: 0,
    visibility: 0,
    uvIndex: 0,
    uvDesc: '',
    sunrise: '--:--',
    sunset: '--:--',
    precipToday: 0,
    aqi: -1,
    aqiDesc: '',
    pm25: 0,
    cloudCover: 0
  };

  private feelsText(): string {
    const diff: number = this.metrics.feelsLike - this.metrics.airTemp;
    if (diff >= 2) {
      return '体感偏热';
    }
    if (diff <= -2) {
      return '体感偏凉';
    }
    return '与气温接近';
  }

  private entries(): WxMetricEntry[] {
    const m: WxMetrics = this.metrics;
    const list: WxMetricEntry[] = [];

    if (m.aqi >= 0) {
      list.push({
        id: 'aqi',
        title: '空气质量',
        value: `${m.aqi}`,
        unit: '',
        sub: `${m.aqiDesc} · PM2.5 ${m.pm25}`,
        icon: $r('app.media.ic_m_aqi'),
        accent: wxAqiColor(m.aqi)
      });
    }
    list.push({
      id: 'feels',
      title: '体感温度',
      value: `${m.feelsLike}°`,
      unit: '',
      sub: this.feelsText(),
      icon: $r('app.media.ic_m_feels'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'humidity',
      title: '湿度',
      value: `${m.humidity}`,
      unit: '%',
      sub: '相对湿度',
      icon: $r('app.media.ic_m_humidity'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'wind',
      title: '风',
      value: `${m.windSpeed}`,
      unit: 'km/h',
      sub: `${m.windDir} · 阵风 ${m.windGust}`,
      icon: $r('app.media.ic_m_wind'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'uv',
      title: '紫外线指数',
      value: `${m.uvIndex}`,
      unit: '',
      sub: `${m.uvDesc}`,
      icon: $r('app.media.ic_m_uv'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'sun',
      title: '日出日落',
      value: `${m.sunrise}`,
      unit: '',
      sub: `日落 ${m.sunset}`,
      icon: $r('app.media.ic_m_sunrise'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'precip',
      title: '降水',
      value: `${m.precipToday}`,
      unit: 'mm',
      sub: '今日累计',
      icon: $r('app.media.ic_m_rain'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'visibility',
      title: '能见度',
      value: `${m.visibility}`,
      unit: 'km',
      sub: wxVisibilityText(m.visibility),
      icon: $r('app.media.ic_m_visibility'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'pressure',
      title: '气压',
      value: `${m.pressure}`,
      unit: 'hPa',
      sub: '海平面气压',
      icon: $r('app.media.ic_m_pressure'),
      accent: '#FFFFFF'
    });
    list.push({
      id: 'cloud',
      title: '云量',
      value: `${m.cloudCover}`,
      unit: '%',
      sub: m.cloudCover > 70 ? '天空阴沉' : (m.cloudCover > 30 ? '云量适中' : '天空晴朗'),
      icon: $r('app.media.ic_m_sunset'),
      accent: '#FFFFFF'
    });
    return list;
  }

  private gridHeight(): number {
    const rows: number = Math.ceil(this.entries().length / 2);
    return rows * 112 + (rows - 1) * 12;
  }

  build() {
    Column() {
      Grid() {
        ForEach(this.entries(), (entry: WxMetricEntry) => {
          GridItem() {
            Column({ space: 6 }) {
              Row({ space: 6 }) {
                Image(entry.icon)
                  .width(15)
                  .height(15)
                  .fillColor('#B3FFFFFF')
                  .objectFit(ImageFit.Contain)
                Text(entry.title)
                  .fontSize(12)
                  .fontColor('#B3FFFFFF')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')

              Row() {
                Text(entry.value)
                  .fontSize(28)
                  .fontColor(entry.accent)
                  .fontWeight(FontWeight.Medium)
                Text(entry.unit)
                  .fontSize(14)
                  .fontColor('#CCFFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .margin({ left: 2, bottom: 4 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Bottom)

              Text(entry.sub)
                .fontSize(12)
                .fontColor('#99FFFFFF')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .height('100%')
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Start)
            .backgroundColor(WX_CARD_BG)
            .borderRadius(20)
            .backgroundBlurStyle(BlurStyle.Thin)
          }
          .height(112)
        }, (entry: WxMetricEntry) => entry.id)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .height(this.gridHeight())
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }
}
