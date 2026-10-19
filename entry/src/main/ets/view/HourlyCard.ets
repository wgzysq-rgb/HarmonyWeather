import { WxHourPoint } from '../model/WeatherModels';
import { wxIcon } from '../common/WeatherCode';
import { WX_CARD_BG, WX_TEXT_ACCENT, WX_TEXT_TERTIARY } from '../common/WxUi';

/** 逐小时预报卡片：横向滚动，仿 iOS 天气 */
@Component
export struct WxHourlyCard {
  @Prop hours: WxHourPoint[] = [];

  build() {
    Column() {
      Row() {
        Text('每小时预报')
          .fontSize(13)
          .fontColor('#CCFFFFFF')
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('未来 24 小时')
          .fontSize(12)
          .fontColor('#B3FFFFFF')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 4 })

      Divider()
        .strokeWidth(0.5)
        .color('#26FFFFFF')
        .margin({ left: 16, right: 16 })

      Scroll() {
        Row() {
          ForEach(this.hours, (item: WxHourPoint, index: number) => {
            Column() {
              Text(item.label)
                .fontSize(14)
                .fontColor('#E6FFFFFF')
                .fontWeight(item.label === '现在' ? FontWeight.Medium : FontWeight.Regular)

              Image(wxIcon(item.code, item.isDay))
                .width(34)
                .height(34)
                .objectFit(ImageFit.Contain)
                .margin({ top: 10, bottom: 6 })

              Text(item.pop > 0 ? `${item.pop}%` : '·')
                .fontSize(12)
                .fontColor(item.pop > 0 ? WX_TEXT_ACCENT : WX_TEXT_TERTIARY)
                .fontWeight(FontWeight.Medium)
                .height(16)

              Text(`${item.temp}°`)
                .fontSize(19)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 4 })
            }
            .width(64)
            .height(126)
            .justifyContent(FlexAlign.Center)
            .border({
              width: { left: 0.5 },
              color: index === 0 ? '#00FFFFFF' : '#26FFFFFF'
            })
          }, (item: WxHourPoint) => `${item.key}_${item.temp}_${item.code}_${item.pop}`)
        }
        .padding({ left: 4, right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
    }
    .width('100%')
    .backgroundColor(WX_CARD_BG)
    .borderRadius(20)
    .backgroundBlurStyle(BlurStyle.Thin)
    .clip(true)
  }
}
