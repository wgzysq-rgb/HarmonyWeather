import { WxCityWeather } from '../model/WeatherModels';
import { WxHourlyCard } from './HourlyCard';
import { WxDailyCard } from './DailyCard';
import { WxMetricsGrid } from './MetricsGrid';

/** 单个城市的天气页：顶部大温度 + 小时 + 10 天 + 指标 */
@Component
export struct WxCityPage {
  @Prop weather: WxCityWeather | null = null;
  @Prop loading: boolean = false;
  @Prop errorText: string = '';
  @Prop pageIndex: number = 0;
  onReload: (index: number) => Promise<void> = (index: number) => Promise.resolve();
  @State isRefreshing: boolean = false;

  @Builder
  refreshTip() {
    Row({ space: 8 }) {
      LoadingProgress()
        .width(20)
        .height(20)
        .color(Color.White)
      Text('正在更新…')
        .fontSize(13)
        .fontColor('#CCFFFFFF')
    }
    .height(60)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  loadingView() {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(Color.White)
      Text('正在获取天气数据…')
        .fontSize(15)
        .fontColor('#CCFFFFFF')
    }
    .width('100%')
    .height(520)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  errorView() {
    Column({ space: 14 }) {
      Image($r('app.media.ic_wx_overcast'))
        .width(72)
        .height(72)
        .objectFit(ImageFit.Contain)
        .opacity(0.85)
      Text(this.errorText.length > 0 ? this.errorText : '天气数据获取失败')
        .fontSize(15)
        .fontColor('#E6FFFFFF')
        .textAlign(TextAlign.Center)
        .padding({ left: 40, right: 40 })
      Button('重新加载')
        .fontSize(15)
        .fontColor(Color.White)
        .backgroundColor('#33FFFFFF')
        .borderRadius(20)
        .height(38)
        .padding({ left: 22, right: 22 })
        .onClick(() => {
          this.onReload(this.pageIndex);
        })
    }
    .width('100%')
    .height(520)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  heroView(data: WxCityWeather) {
    Column() {
      Row({ space: 6 }) {
        if (data.city.isLocated) {
          Image($r('app.media.ic_ui_location'))
            .width(15)
            .height(15)
            .fillColor('#E6FFFFFF')
        }
        Text(data.city.name)
          .fontSize(30)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .margin({ top: 6 })

      Row() {
        Text(`${data.temp}`)
          .fontSize(96)
          .fontColor(Color.White)
          .fontWeight(200)
        Text('°')
          .fontSize(60)
          .fontColor(Color.White)
          .fontWeight(200)
          .margin({ top: 8 })
      }
      .alignItems(VerticalAlign.Top)
      .margin({ top: -6 })

      Text(data.desc)
        .fontSize(21)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)

      Text(`最高 ${data.high}°  最低 ${data.low}°`)
        .fontSize(17)
        .fontColor('#E6FFFFFF')
        .margin({ top: 6 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 18 })
  }

  @Builder
  contentView(data: WxCityWeather) {
    Column({ space: 12 }) {
      this.heroView(data)
      WxHourlyCard({ hours: data.hours })
      WxDailyCard({ days: data.days })
      WxMetricsGrid({ metrics: data.metrics })

      Text(`数据来源 Open-Meteo · ${data.updatedAt} 更新`)
        .fontSize(11)
        .fontColor('#80FFFFFF')
        .margin({ top: 10, bottom: 8 })
    }
    .width('100%')
    .padding({ left: 14, right: 14 })
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing, builder: this.refreshTip }) {
      Scroll() {
        Column() {
          if (this.weather === null) {
            if (this.errorText.length > 0) {
              this.errorView()
            } else {
              this.loadingView()
            }
          } else {
            this.contentView(this.weather as WxCityWeather)
          }
        }
        .width('100%')
        .padding({ top: 106, bottom: 96 })
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
    .onRefreshing(() => {
      this.isRefreshing = true;
      this.onReload(this.pageIndex).then(() => {
        this.isRefreshing = false;
      }).catch(() => {
        this.isRefreshing = false;
      });
    })
    .width('100%')
    .height('100%')
  }
}
