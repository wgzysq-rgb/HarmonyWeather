import { WxCity, WxCityCardItem } from '../model/WeatherModels';
import { wxSearchCities } from '../service/OpenMeteoService';

/** @Builder 按引用传参的载体（单参数对象字面量才能触发刷新） */
interface WxCityCardParam {
  item: WxCityCardItem;
  badge: string;
}

/** 左滑操作区的回调载体 */
interface WxSwipeParam {
  onHome: () => void;
  onDelete: () => void;
}

/** 城市管理半模态：卡片列表 + 搜索添加 + 长按拖动排序 + 左滑管理 */
@Component
export struct WxCitySheet {
  @Prop cityCards: WxCityCardItem[] = [];
  @Prop currentId: string = '';
  @Prop locating: boolean = false;
  @Prop locateMsg: string = '';
  onPick: (city: WxCity) => void = () => {
  };
  onAdd: (city: WxCity) => void = () => {
  };
  onRemove: (city: WxCity) => void = () => {
  };
  onReorder: (from: number, to: number) => void = () => {
  };
  onSetHome: (city: WxCity) => void = () => {
  };
  onLocate: () => void = () => {
  };
  @State keyword: string = '';
  @State results: WxCity[] = [];
  @State searching: boolean = false;
  @State tipText: string = '';
  @State dragName: string = '城市';
  @State dragInsertIndex: number = -1;
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  private handleKeyword(value: string): void {
    this.keyword = value;
    this.tipText = '';
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (value.trim().length === 0) {
      this.results = [];
      this.searching = false;
      return;
    }
    this.timerId = setTimeout(() => {
      this.runSearch();
    }, 450);
  }

  private async runSearch(): Promise<void> {
    const query: string = this.keyword.trim();
    if (query.length === 0) {
      return;
    }
    this.searching = true;
    try {
      const found: WxCity[] = await wxSearchCities(query);
      if (query === this.keyword.trim()) {
        this.results = found;
        this.tipText = found.length === 0 ? '没有找到匹配的城市，换个关键词试试' : '';
      }
    } catch (error) {
      this.results = [];
      this.tipText = (error as Error).message;
    } finally {
      this.searching = false;
    }
  }

  private gradientOf(item: WxCityCardItem): Array<[ResourceColor, number]> {
    const g: string[] = item.gradient;
    const c0: string = g.length > 0 ? g[0] : '#2C6FC4';
    const c1: string = g.length > 1 ? g[1] : '#4E9BD8';
    const c2: string = g.length > 2 ? g[2] : '#8FC6EA';
    return [[c0, 0.0], [c1, 0.55], [c2, 1.0]];
  }

  private regionLine(item: WxCityCardItem): string {
    if (item.city.isLocated) {
      return item.city.region.length > 0 ? `当前位置 · ${item.city.region}` : '当前位置';
    }
    return item.city.region.length > 0 ? item.city.region : '—';
  }

  /** 城市卡片：天气渐变底 + 左文右温，对齐参考图 */
  @Builder
  cityCard($$: WxCityCardParam) {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({ angle: 160, colors: this.gradientOf($$.item) })

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#1F0D1A2B')

      Row() {
        Column({ space: 5 }) {
          Row({ space: 6 }) {
            Text($$.item.city.name)
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .flexShrink(1)
            if ($$.item.city.isLocated) {
              Image($r('app.media.ic_ui_pin_filled'))
                .width(16)
                .height(16)
            }
            if ($$.badge.length > 0) {
              Text($$.badge)
                .fontSize(10)
                .fontColor('#E6FFFFFF')
                .backgroundColor('#2EFFFFFF')
                .borderRadius(5)
                .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            }
          }
          .alignItems(VerticalAlign.Center)

          Text(this.regionLine($$.item))
            .fontSize(13)
            .fontColor('#B8FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 10 }) {
            Text($$.item.hasData ? $$.item.desc : '正在获取…')
              .fontSize(13)
              .fontColor('#E6FFFFFF')
            if ($$.item.aqiText.length > 0) {
              Text($$.item.aqiText)
                .fontSize(13)
                .fontColor('#E6FFFFFF')
            }
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 1 }) {
          Text($$.item.hasData ? `${$$.item.temp}°` : '--°')
            .fontSize(40)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          Text($$.item.hasData ? $$.item.rangeText : '')
            .fontSize(14)
            .fontColor('#CCFFFFFF')
        }
        .alignItems(HorizontalAlign.End)
        .margin({ left: 10 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(108)
    .borderRadius(22)
    .clip(true)
  }

  /** 左滑露出的两个圆形操作按钮 */
  @Builder
  swipeButtons($$: WxSwipeParam) {
    Row({ space: 12 }) {
      Column() {
        Image($r('app.media.ic_ui_home_filled'))
          .width(24)
          .height(24)
      }
      .width(58)
      .height(58)
      .borderRadius(29)
      .backgroundColor('#4C5F76')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        $$.onHome();
      })

      Column() {
        Image($r('app.media.ic_ui_trash_filled'))
          .width(23)
          .height(23)
      }
      .width(58)
      .height(58)
      .borderRadius(29)
      .backgroundColor('#F01F1F')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        $$.onDelete();
      })
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 22, right: 10 })
  }

  /** 长按拖动时跟随手指的浮层（不能叫 dragPreview，会和组件通用属性重名） */
  @Builder
  dragOverlay() {
    Row() {
      Text(this.dragName)
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .padding({ left: 18, right: 18, top: 12, bottom: 12 })
    .backgroundColor('#2B3B4A')
    .borderRadius(14)
    .scale({ x: 1.04, y: 1.04 })
    .shadow({ radius: 24, color: '#59000000', offsetX: 0, offsetY: 10 })
  }

  /** 搜索结果行 */
  @Builder
  resultRow(city: WxCity) {
    Row() {
      Column({ space: 3 }) {
        Text(city.name)
          .fontSize(16)
          .fontColor(Color.White)
        Text(city.region.length > 0 ? city.region : '—')
          .fontSize(12)
          .fontColor('#80FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_ui_add'))
        .width(18)
        .height(18)
        .fillColor('#CCFFFFFF')
    }
    .width('100%')
    .height(54)
    .padding({ left: 18, right: 18 })
  }

  build() {
    Column() {
      Row() {
        Text('城市')
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.cityCards.length} 个城市`)
          .fontSize(12)
          .fontColor('#99FFFFFF')
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 6, bottom: 12 })

      Search({ value: this.keyword, placeholder: '搜索城市，例如「杭州」' })
        .width('100%')
        .height(40)
        .backgroundColor('#26FFFFFF')
        .placeholderColor('#80FFFFFF')
        .fontColor(Color.White)
        .placeholderFont({ size: 14 })
        .textFont({ size: 15 })
        .caretStyle({ color: '#FFFFFF', width: 2 })
        .margin({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.handleKeyword(value);
        })
        .onSubmit((value: string) => {
          this.keyword = value;
          this.runSearch();
        })

      Row() {
        Image($r('app.media.ic_ui_location'))
          .width(17)
          .height(17)
          .fillColor('#CCFFFFFF')
        Text('使用当前位置')
          .fontSize(14)
          .fontColor('#E6FFFFFF')
          .margin({ left: 8 })
        Blank()
      }
      .width('100%')
      .height(44)
      .padding({ left: 20, right: 20 })
      .margin({ top: 4 })
      .onClick(() => {
        this.onLocate();
      })

      if (this.locating) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color('#CCFFFFFF')
          Text('正在定位…')
            .fontSize(13)
            .fontColor('#99FFFFFF')
        }
        .width('100%')
        .padding({ left: 20, top: 6, bottom: 2 })
      }

      if (this.locateMsg.length > 0) {
        Text(this.locateMsg)
          .fontSize(12)
          .fontColor('#FFB4A8')
          .width('100%')
          .padding({ left: 20, right: 20, top: 6, bottom: 2 })
      }

      if (this.searching) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color('#CCFFFFFF')
          Text('正在搜索…')
            .fontSize(13)
            .fontColor('#99FFFFFF')
        }
        .width('100%')
        .padding({ left: 20, top: 10, bottom: 6 })
      }

      if (this.tipText.length > 0) {
        Text(this.tipText)
          .fontSize(13)
          .fontColor('#99FFFFFF')
          .width('100%')
          .padding({ left: 20, right: 20, top: 10, bottom: 6 })
      }

      if (this.results.length > 0) {
        List() {
          // check-invariants: skip=搜索结果只显示城市名与行政区别名，不含天气数据
          ForEach(this.results, (city: WxCity) => {
            ListItem() {
              this.resultRow(city)
            }
            .onClick(() => {
              this.onAdd(city);
            })
          }, (city: WxCity) => `search_${city.id}`)
        }
        .width('100%')
        .height(Math.min(this.results.length, 4) * 54)
        .scrollBar(BarState.Off)
        .margin({ top: 2 })
      }

      Row() {
        Text('已添加')
          .fontSize(12)
          .fontColor('#80FFFFFF')
        Blank()
        Text('长按拖动排序 · 左滑管理')
          .fontSize(11)
          .fontColor('#66FFFFFF')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 8 })

      List({ space: 12 }) {
        ForEach(this.cityCards, (item: WxCityCardItem, index: number) => {
          ListItem() {
            Stack({ alignContent: Alignment.Top }) {
              this.cityCard({
                item: item,
                badge: index === 0 ? '首页' : (item.city.id === this.currentId ? '当前' : '')
              })
              if (this.dragInsertIndex === index) {
                Row()
                  .width('100%')
                  .height(3)
                  .backgroundColor('#E6FFFFFF')
                  .borderRadius(2)
                  .offset({ y: -7 })
              }
            }
            .width('100%')
          }
          .swipeAction({
            end: this.swipeButtons({
              onHome: () => {
                this.onSetHome(item.city);
              },
              onDelete: () => {
                this.onRemove(item.city);
              }
            }),
            edgeEffect: SwipeEdgeEffect.Spring
          })
          .onClick(() => {
            this.onPick(item.city);
          })
        }, (item: WxCityCardItem) => `city_${item.city.id}_${item.temp}_${item.code}_${item.rangeText}`)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 12, right: 12 })
      .scrollBar(BarState.Off)
      .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
        if (itemIndex >= 0 && itemIndex < this.cityCards.length) {
          this.dragName = this.cityCards[itemIndex].city.name;
        }
        this.dragInsertIndex = -1;
        return this.dragOverlay();
      })
      .onItemDragMove((event: ItemDragInfo, itemIndex: number, insertIndex: number) => {
        if (insertIndex !== this.dragInsertIndex) {
          this.dragInsertIndex = insertIndex;
        }
      })
      .onItemDragLeave((event: ItemDragInfo, itemIndex: number) => {
        if (this.dragInsertIndex !== -1) {
          this.dragInsertIndex = -1;
        }
      })
      .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
        this.dragInsertIndex = -1;
        if (!isSuccess || insertIndex < 0 || insertIndex > this.cityCards.length) {
          return;
        }
        if (itemIndex !== insertIndex) {
          this.onReorder(itemIndex, insertIndex);
        }
      })

      Row()
        .height(20)
    }
    .width('100%')
    .height('100%')
  }
}
