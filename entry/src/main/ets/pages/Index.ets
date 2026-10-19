import { WxCity, WxCityWeather, WxTheme, WxCityCardItem } from '../model/WeatherModels';
import { WxCityStore } from '../service/CityStore';
import { wxLoadCityWeather } from '../service/WeatherRepository';
import { wxLocateCity } from '../service/LocationService';
import { wxSaveWidgetSnapshot, wxBuildWidgetSnapshot, wxLoadFormIds,
  wxRecallFormLayout } from '../service/WidgetSnapshot';
import { wxBuildWidgetBinding } from '../service/WidgetBinding';
import { formBindingData, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  wxCacheGetSync,
  wxCacheIsFresh,
  wxCachePrune,
  wxCachePutSync,
  wxCacheReadMany,
  WxCacheEntry,
  WX_CACHE_TTL_MS
} from '../service/WeatherCache';
import { wxTheme } from '../common/WeatherCode';
import { WxCityPage } from '../view/CityPage';
import { WxCitySheet } from '../view/CitySheet';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State cities: WxCity[] = [];
  @State weathers: Array<WxCityWeather | null> = [];
  @State loadingList: boolean[] = [];
  @State errorList: string[] = [];
  @State currentIndex: number = 0;
  @State sheetShown: boolean = false;
  @State booting: boolean = true;
  @State locating: boolean = false;
  @State locateMsg: string = '';
  private swiperController: SwiperController = new SwiperController();
  private started: boolean = false;
  /** 每个城市内存数据的加载时间戳（与 cities 同序），用来判断是否需要刷新 */
  private loadedAt: number[] = [];
  private tickTimer: number = -1;

  aboutToAppear(): void {
    this.bootstrap();
    this.startTick();
  }

  aboutToDisappear(): void {
    if (this.tickTimer >= 0) {
      clearInterval(this.tickTimer);
      this.tickTimer = -1;
    }
  }

  /**
   * 前台每 5 分钟检查一次当前城市是否该刷新。
   * 之前只有 onPageShow 触发，App 一直停在页面里就永远不会更新。
   */
  private startTick(): void {
    if (this.tickTimer >= 0) {
      return;
    }
    this.tickTimer = setInterval(() => {
      this.refreshIfStale(this.currentIndex);
    }, 5 * 60 * 1000);
  }

  /** 从后台回到前台时，只有数据已过期才补一次静默刷新 */
  onPageShow(): void {
    if (!this.started) {
      return;
    }
    this.refreshIfStale(this.currentIndex);
  }

  private async bootstrap(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      await WxCityStore.get().init(context);
    }
    const stored: WxCity[] = await WxCityStore.get().loadCities();

    // 1. 先同步铺本地缓存，进入即有内容，不转圈
    const cachedMap: Map<string, WxCacheEntry> = context !== undefined
      ? wxCacheReadMany(context, stored)
      : new Map<string, WxCacheEntry>();
    const seedWeathers: Array<WxCityWeather | null> = [];
    const seedFlags: boolean[] = [];
    const seedErrors: string[] = [];
    const seedLoadedAt: number[] = [];
    for (let i = 0; i < stored.length; i++) {
      const entry: WxCacheEntry | null = cachedMap.get(stored[i].id) ?? null;
      seedWeathers.push(entry !== null ? entry.weather : null);
      seedFlags.push(false);
      seedErrors.push('');
      seedLoadedAt.push(entry !== null ? entry.savedAt : 0);
    }
    this.cities = stored;
    this.weathers = seedWeathers;
    this.loadingList = seedFlags;
    this.errorList = seedErrors;
    this.loadedAt = seedLoadedAt;
    this.booting = false;
    this.started = true;

    if (context !== undefined) {
      wxCachePrune(context, stored);
    }

    // 2. 把后面几页一起预取，滑过去就不用再等；缓存还新鲜的跳过
    for (let i = 0; i < stored.length; i++) {
      const entry: WxCacheEntry | null = cachedMap.get(stored[i].id) ?? null;
      if (entry !== null && wxCacheIsFresh(entry)) {
        continue;
      }
      const silent: boolean = entry !== null;
      setTimeout(() => {
        this.loadCity(i, silent, false);
      }, i * 120);
    }

    // 3. 启动时无条件同步一次桌面卡片。
    //    上面「缓存新鲜就 continue」意味着 loadCity 不会被调用，
    //    而 pushWidgetUpdate 挂在 loadCity 成功之后 —— 不补这一下，
    //    冷启动时卡片就永远拿不到「当前首页城市」的快照。
    this.syncHomeWidget();
  }

  private currentTheme(): WxTheme {
    if (this.cities.length === 0) {
      return wxTheme(0, true);
    }
    const data: WxCityWeather | null = this.weathers[this.currentIndex] ?? null;
    if (data !== null) {
      return data.theme;
    }
    return wxTheme(0, true);
  }

  private gradientOf(index: number): Array<[ResourceColor, number]> {
    const data: WxCityWeather | null = this.weathers[index] ?? null;
    const theme: WxTheme = data !== null ? data.theme : wxTheme(0, true);
    return [
      [theme.gradient[0], 0.0],
      [theme.gradient[1], 0.52],
      [theme.gradient[2], 1.0]
    ];
  }

  private setFlag(index: number, loading: boolean, error: string): void {
    const nextLoading: boolean[] = this.loadingList.slice();
    const nextError: string[] = this.errorList.slice();
    nextLoading[index] = loading;
    nextError[index] = error;
    this.loadingList = nextLoading;
    this.errorList = nextError;
  }

  /**
   * @param silent 静默刷新：不显示 loading，失败时保留旧数据
   * @param force  忽略缓存强制请求（仅下拉刷新用）
   */
  private async loadCity(index: number, silent: boolean = false, force: boolean = false): Promise<void> {
    if (index < 0 || index >= this.cities.length) {
      return;
    }
    const city: WxCity = this.cities[index];
    const hostContext = this.getUIContext().getHostContext();

    // 缓存还新鲜就不发请求
    if (!force && hostContext !== undefined) {
      const cached: WxCacheEntry | null = wxCacheGetSync(hostContext, city.id);
      if (cached !== null && wxCacheIsFresh(cached)) {
        const nextWeathers: Array<WxCityWeather | null> = this.weathers.slice();
        nextWeathers[index] = cached.weather;
        this.weathers = nextWeathers;
        this.markLoaded(index, cached.savedAt);
        this.setFlag(index, false, '');
        if (index === 0) {
          this.syncWidget(cached.weather);
          this.pushWidgetUpdate();
        }
        return;
      }
    }

    if (!silent) {
      this.setFlag(index, true, '');
    } else {
      this.setFlag(index, false, '');
    }
    try {
      const data: WxCityWeather = await wxLoadCityWeather(city);
      if (hostContext !== undefined) {
        wxCachePutSync(hostContext, data);
      }
      const nextWeathers: Array<WxCityWeather | null> = this.weathers.slice();
      nextWeathers[index] = data;
      this.weathers = nextWeathers;
      this.markLoaded(index, Date.now());
      this.setFlag(index, false, '');
      if (index === 0) {
        this.syncWidget(data);
        this.pushWidgetUpdate();
      }
    } catch (error) {
      const existing: WxCityWeather | null = this.weathers[index] ?? null;
      if (silent && existing !== null) {
        // 静默刷新失败：继续用旧数据，不打扰用户
        this.setFlag(index, false, '');
      } else {
        this.setFlag(index, false, (error as Error).message);
      }
    }
  }

  /** 把当前城市的最新天气写入卡片快照，桌面卡片下次刷新/添加时可直接使用 */
  private syncWidget(data: WxCityWeather): void {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined || hostContext === null) {
      return;
    }
    wxSaveWidgetSnapshot(hostContext, data).catch(() => {
    });
  }

  /**
   * 卡片永远展示首页城市（cities[0]）。
   * 首页没数据时顺手拉一次，避免设置首页后卡片还停留在旧城市的快照上。
   */
  private syncHomeWidget(): void {
    if (this.cities.length === 0) {
      return;
    }
    const data: WxCityWeather | null = this.weathers[0] ?? null;
    if (data !== null) {
      this.syncWidget(data);
      this.pushWidgetUpdate();
    } else {
      this.loadCity(0, true, false);
    }
  }

  /** 首页数据有更新时主动推一次卡片，不用等系统 30 分钟后调度 */
  private pushWidgetUpdate(): void {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined || hostContext === null) {
      return;
    }
    const data: WxCityWeather | null = this.weathers[0] ?? null;
    if (data === null) {
      return;
    }
    const formIds: string[] = wxLoadFormIds(hostContext);
    if (formIds.length === 0) {
      hilog.warn(0x0000, 'HarmonyWeather', 'widget push skipped: no form id recorded');
      return;
    }
    const snapshot = wxBuildWidgetSnapshot(data);
    const day0: string = snapshot.days.length > 0
      ? `${snapshot.days[0].weekday}${snapshot.days[0].min}/${snapshot.days[0].max}` : 'none';
    const hour0: string = snapshot.hours.length > 0
      ? `${snapshot.hours[0].label}${snapshot.hours[0].temp}°` : 'none';
    hilog.info(0x0000, 'HarmonyWeather',
      'widget push city=%{public}s forms=%{public}d days=%{public}d day0=%{public}s hours=%{public}d hour0=%{public}s',
      snapshot.cityName, formIds.length, snapshot.days.length, day0, snapshot.hours.length, hour0);
    for (let i = 0; i < formIds.length; i++) {
      const formId: string = formIds[i];
      const layout: string = wxRecallFormLayout(hostContext, formId);
      formProvider.updateForm(formId,
        formBindingData.createFormBindingData(wxBuildWidgetBinding(snapshot, layout)))
        .catch((error: BusinessError) => {
          hilog.error(0x0000, 'HarmonyWeather', 'widget push failed form=%{public}s: %{public}s',
            formId, error.message);
        });
    }
  }

  private ensureLoaded(index: number): void {
    if (index < 0 || index >= this.cities.length) {
      return;
    }
    const existing: WxCityWeather | null = this.weathers[index] ?? null;
    if (existing === null) {
      this.loadCity(index, false, false);
      return;
    }
    this.refreshIfStale(index);
  }

  /**
   * 按内存里的加载时间判断是否该刷新。
   * 不用 preferences 的 savedAt 做依据 —— 卡片和后台任务是别的进程写缓存，
   * 本进程的 preferences 实例读不到它们的更新，会导致「明明该刷新却一直等」。
   */
  private refreshIfStale(index: number): void {
    if (index < 0 || index >= this.cities.length) {
      return;
    }
    const lastAt: number = this.loadedAt[index] ?? 0;
    const age: number = Date.now() - lastAt;
    // age < 0 说明本机时间被往回改过，同样按过期处理，避免一直不刷新
    if (age < 0 || age >= WX_CACHE_TTL_MS) {
      this.loadCity(index, true, false);
    }
  }

  private markLoaded(index: number, at: number): void {
    if (index < 0 || index >= this.loadedAt.length) {
      return;
    }
    const next: number[] = this.loadedAt.slice();
    next[index] = at;
    this.loadedAt = next;
  }

  private switchCity(index: number): void {
    if (index < 0 || index >= this.cities.length) {
      return;
    }
    this.currentIndex = index;
    this.swiperController.changeIndex(index, false);
    this.ensureLoaded(index);
  }

  private persist(): void {
    WxCityStore.get().saveCities(this.cities);
  }

  /**
   * 按新的城市顺序重排所有平行数组（天气快照 / 加载态 / 错误态），
   * 并让 currentIndex 继续指向原来正在浏览的那个城市。
   */
  private applyCityOrder(nextCities: WxCity[], focusCityId: string = ''): void {
    const currentId: string = focusCityId.length > 0 ? focusCityId : this.currentCityId();
    const weatherById: Map<string, WxCityWeather> = new Map();
    const loadingById: Map<string, boolean> = new Map();
    const errorById: Map<string, string> = new Map();
    const loadedById: Map<string, number> = new Map();
    for (let i = 0; i < this.cities.length; i++) {
      const cityId: string = this.cities[i].id;
      const data: WxCityWeather | null = this.weathers[i] ?? null;
      if (data !== null) {
        weatherById.set(cityId, data);
      }
      loadingById.set(cityId, this.loadingList[i] ?? false);
      errorById.set(cityId, this.errorList[i] ?? '');
      loadedById.set(cityId, this.loadedAt[i] ?? 0);
    }
    const nextWeathers: Array<WxCityWeather | null> = [];
    const nextLoading: boolean[] = [];
    const nextError: string[] = [];
    const nextLoadedAt: number[] = [];
    for (let i = 0; i < nextCities.length; i++) {
      const cityId: string = nextCities[i].id;
      nextWeathers.push(weatherById.get(cityId) ?? null);
      nextLoading.push(loadingById.get(cityId) ?? false);
      nextError.push(errorById.get(cityId) ?? '');
      nextLoadedAt.push(loadedById.get(cityId) ?? 0);
    }
    let foundIndex: number = 0;
    for (let i = 0; i < nextCities.length; i++) {
      if (nextCities[i].id === currentId) {
        foundIndex = i;
        break;
      }
    }
    this.currentIndex = foundIndex;
    this.swiperController.changeIndex(foundIndex, false);

    // 用显式动画包住数组变更，让城市列表重排时卡片有位移过渡而不是瞬移
    this.getUIContext().animateTo({
      duration: 280,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.cities = nextCities;
      this.weathers = nextWeathers;
      this.loadingList = nextLoading;
      this.errorList = nextError;
      this.loadedAt = nextLoadedAt;
    });
    this.persist();
    // 首页可能变了，卡片快照要跟着换城市
    this.syncHomeWidget();
  }

  /** 切换到这个城市，不改动列表顺序 */
  private focusCity(city: WxCity): void {
    const index: number = this.cities.findIndex((item: WxCity): boolean => item.id === city.id);
    if (index < 0) {
      return;
    }
    this.sheetShown = false;
    this.switchCity(index);
  }

  /** 左滑「设为首页」：移到第一位作为启动默认页，当前浏览的城市保持不变 */
  private setHomeCity(city: WxCity): void {
    const index: number = this.cities.findIndex((item: WxCity): boolean => item.id === city.id);
    if (index <= 0) {
      return;
    }
    const next: WxCity[] = this.cities.slice();
    const moved: WxCity[] = next.splice(index, 1);
    if (moved.length === 0) {
      return;
    }
    next.unshift(moved[0]);
    this.applyCityOrder(next);
  }

  /** 长按拖动后的顺序调整 */
  private reorderCities(from: number, to: number): void {
    if (from === to || from < 0 || to < 0 ||
      from >= this.cities.length || to > this.cities.length) {
      return;
    }
    const next: WxCity[] = this.cities.slice();
    const moved: WxCity[] = next.splice(from, 1);
    if (moved.length === 0) {
      return;
    }
    const target: number = Math.min(to, next.length);
    next.splice(target, 0, moved[0]);
    this.applyCityOrder(next);
  }

  private addCity(city: WxCity): void {
    const existing: number = this.cities.findIndex((item: WxCity): boolean => item.id === city.id);
    this.sheetShown = false;
    if (existing >= 0) {
      this.switchCity(existing);
      return;
    }
    const nextCities: WxCity[] = this.cities.slice();
    nextCities.push(city);
    const nextWeathers: Array<WxCityWeather | null> = this.weathers.slice();
    nextWeathers.push(null);
    const nextLoading: boolean[] = this.loadingList.slice();
    nextLoading.push(false);
    const nextError: string[] = this.errorList.slice();
    nextError.push('');
    const nextLoadedAt: number[] = this.loadedAt.slice();
    nextLoadedAt.push(0);
    this.cities = nextCities;
    this.weathers = nextWeathers;
    this.loadingList = nextLoading;
    this.errorList = nextError;
    this.loadedAt = nextLoadedAt;
    this.persist();
    this.switchCity(nextCities.length - 1);
  }

  private removeCity(city: WxCity): void {
    if (this.cities.length <= 1) {
      return;
    }
    const index: number = this.cities.findIndex((item: WxCity): boolean => item.id === city.id);
    if (index < 0) {
      return;
    }
    const next: WxCity[] = this.cities.slice();
    next.splice(index, 1);
    // applyCityOrder 会按 cityId 重新定位当前页；若当前城市被删则落到首位
    this.applyCityOrder(next);
    this.ensureLoaded(this.currentIndex);
  }

  private currentCityId(): string {
    if (this.cities.length === 0) {
      return '';
    }
    const city: WxCity = this.cities[this.currentIndex];
    return city.id;
  }

  /** 组装城市管理页的卡片数据（城市 + 该城市当前的天气摘要） */
  private buildCityCards(): WxCityCardItem[] {
    const cards: WxCityCardItem[] = [];
    const fallback: string[] = wxTheme(0, true).gradient;
    for (let i = 0; i < this.cities.length; i++) {
      const city: WxCity = this.cities[i];
      const data: WxCityWeather | null = this.weathers[i] ?? null;
      if (data === null) {
        cards.push({
          city: city,
          hasData: false,
          temp: 0,
          desc: '',
          rangeText: '',
          code: 0,
          isDay: true,
          aqiText: '',
          gradient: fallback
        });
      } else {
        cards.push({
          city: city,
          hasData: true,
          temp: data.temp,
          desc: data.desc,
          rangeText: `${data.high}°/${data.low}°`,
          code: data.code,
          isDay: data.isDay,
          aqiText: data.metrics.aqi >= 0 ? `空气${data.metrics.aqiDesc}` : '',
          gradient: data.theme.gradient
        });
      }
    }
    return cards;
  }

  private async locate(): Promise<void> {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined || hostContext === null) {
      return;
    }
    if (this.locating) {
      return;
    }
    this.locating = true;
    this.locateMsg = '';
    try {
      const city: WxCity = await wxLocateCity(hostContext as common.UIAbilityContext);
      this.locating = false;
      this.addCity(city);
    } catch (error) {
      this.locating = false;
      this.locateMsg = (error as Error).message;
    }
  }

  @Builder
  bootView() {
    Column({ space: 14 }) {
      LoadingProgress()
        .width(38)
        .height(38)
        .color(Color.White)
      Text('正在启动天气…')
        .fontSize(14)
        .fontColor('#CCFFFFFF')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  citySheet() {
    WxCitySheet({
      cityCards: this.buildCityCards(),
      currentId: this.currentCityId(),
      locating: this.locating,
      locateMsg: this.locateMsg,
      onLocate: () => {
        this.locate();
      },
      onPick: (city: WxCity) => {
        this.focusCity(city);
      },
      onAdd: (city: WxCity) => {
        this.addCity(city);
      },
      onRemove: (city: WxCity) => {
        this.removeCity(city);
      },
      onReorder: (from: number, to: number) => {
        this.reorderCities(from, to);
      },
      onSetHome: (city: WxCity) => {
        this.setHomeCity(city);
      }
    })
  }

  @Builder
  topBar() {
    Row() {
      Button() {
        Image($r('app.media.ic_ui_list'))
          .width(19)
          .height(19)
      }
      .type(ButtonType.Circle)
      .width(38)
      .height(38)
      .backgroundColor('#2EFFFFFF')
      .onClick(() => {
        this.sheetShown = true;
      })

      Blank()

      Button() {
        Image($r('app.media.ic_ui_add'))
          .width(19)
          .height(19)
      }
      .type(ButtonType.Circle)
      .width(38)
      .height(38)
      .backgroundColor('#2EFFFFFF')
      .onClick(() => {
        this.sheetShown = true;
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  pageDots() {
    Row({ space: 6 }) {
      // check-invariants: skip=只画页码圆点，不依赖天气数据
      ForEach(this.cities, (city: WxCity, index: number) => {
        Circle()
          .width(index === this.currentIndex ? 7 : 6)
          .height(index === this.currentIndex ? 7 : 6)
          .fill(index === this.currentIndex ? '#FFFFFF' : '#59FFFFFF')
      }, (city: WxCity) => `dot_${city.id}`)
    }
    .height(24)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#0E2C4E', 0.0], ['#1B4E7E', 0.55], ['#3A7CA8', 1.0]]
        })

      ForEach(this.cities, (city: WxCity, index: number) => {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({ angle: 180, colors: this.gradientOf(index) })
          .opacity(index === this.currentIndex ? 1 : 0)
          .animation({ duration: 480, curve: Curve.EaseInOut })
      }, (city: WxCity, index: number) => `bg_${city.id}_${this.weathers[index]?.theme.key ?? 'none'}`)

      Circle({ width: 300, height: 300 })
        .fill('#12FFFFFF')
        .blur(60)
        .position({ x: -70, y: -80 })
        .hitTestBehavior(HitTestMode.None)

      if (this.booting) {
        this.bootView()
      } else {
        Swiper(this.swiperController) {
          // check-invariants: skip=weather 通过 @Prop 传入，父组件重渲染即更新，不依赖 key
          ForEach(this.cities, (city: WxCity, index: number) => {
            WxCityPage({
              weather: this.weathers[index] ?? null,
              loading: this.loadingList[index] ?? false,
              errorText: this.errorList[index] ?? '',
              pageIndex: index,
              onReload: (target: number): Promise<void> => this.loadCity(target, true, true)
            })
          }, (city: WxCity) => city.id)
        }
        .index(this.currentIndex)
        .indicator(false)
        .loop(false)
        .duration(280)
        .width('100%')
        .height('100%')
        .onChange((index: number) => {
          this.currentIndex = index;
          this.ensureLoaded(index);
        })
      }

      Column() {
        Row()
          .height(44)
        this.topBar()
        Blank()
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)

      Column() {
        Blank()
        if (this.cities.length > 1) {
          this.pageDots()
        }
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 18 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0E2C4E')
    .bindSheet($$this.sheetShown, this.citySheet, {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: '#16232E',
      blurStyle: BlurStyle.Thick,
      onDisappear: () => {
        this.sheetShown = false;
      }
    })
  }
}
