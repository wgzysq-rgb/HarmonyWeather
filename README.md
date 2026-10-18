# 天气（HarmonyWeather）

一款仿 iOS 天气界面风格的 HarmonyOS 原生天气 App，使用 ArkTS / ArkUI 开发，适配 API 26（HarmonyOS 6.0+）。

## 功能

- **当前天气**：城市名、超大温度、天气现象、最高/最低温
- **每小时预报**：未来 24 小时横向滚动，含天气图标与降水概率
- **每日预报**：昨天（整行淡化到 45% 与今天区分）+ 今天 + 未来 10 天，逐日最低/最高温 + 彩色温度条（蓝→绿→黄→橙渐变）、降水概率
- **指标网格**：空气质量、体感温度、湿度、风、紫外线、日出日落、降水、能见度、气压、云量
- **多城市**：左右滑动翻页切换；城市管理页每个城市是一张**带天气渐变的卡片**（城市名 / 位置 / 天气 / 空气质量 / 大温度 / 高低温），可搜索添加、**长按拖动排序**（拖动时有插入指示线，松手有位移过渡）、**左滑露出两个圆形按钮**（设为首页 / 删除）；列表第一位就是启动默认页，顺序完全由拖动决定
- **定位**：城市面板里「使用当前位置」，申请近似位置权限后自动逆地理编码成城市名
- **动态背景**：背景渐变随天气现象与昼夜切换（晴/多云/阴/雾/雨/暴雨/雷雨/雪），切换城市时平滑淡入
- **毛玻璃卡片**：`backgroundBlurStyle` + 半透明白，贴合 iOS 的层次感
- **下拉刷新**、城市列表本地持久化（preferences）
- **桌面卡片**：2×2 与 4×4 两种尺寸，轻触打开应用，4×4 可手动刷新（见下）

## 桌面卡片（服务卡片）

| 尺寸 | 内容 |
| --- | --- |
| 2×2 | 城市名、温度、天气图标、天气描述、最高/最低温 |
| 2×2 · 多日版 | 双栏：左列「城市 + 当前温度 + 未来四天星期」，右列「天气图标 + 今天高低温 + 未来四天图标与温度」。右列每天是**固定列宽的 Row**（图标 / 低温 / 高温各占固定位置 + 固定行高 18），保证图标竖向对齐。**独立卡片模板**，在桌面添加时显示为「天气 · 多日」 |
| 2×4 | 左侧当前天气（城市/温度/图标/描述/高低温），右侧 5 行日期列表：昨天、今天、明天 + 2 天 |
| 4×4 | 顶部当前天气 + 未来 6 小时 + 4 行日期列表（昨天起），右上角刷新按钮 |

目前注册**两个** form 模板（`WeatherCardDays` / `WeatherCard`），共用同一份 `formBindingData`，只是布局不同；`form_config.json` 的 `forms` 数组**按尺寸从小到大**排列 —— 先是只支持 2×2 的专用模板，再是覆盖 2×2 / 2×4 / 4×4 的通用模板（`isDefault: true`）。

> **2×4 透明时钟卡片（`WeatherCardClock`）已暂时下线**，桌面添加面板不再显示。源码 `widget/pages/WidgetCardClock.ets` 保留，未被 form_config 引用时不会参与编译；恢复只需把对应的 form 条目加回数组。它的实现记录见本节下方，留作备查。

**（已下线的）透明时钟卡片实现记录**：

- **时间不是实时走时**：`TextTimer` 的 `count` 只在 `isCountDown: true`（倒计时）时生效，正计时需要的 `startTime` 又被标成 `@stagemodelonly`（卡片环境不可用）—— 实测在卡片里只会从 `00:00` 开始往上走。所以时间改由 FormExtensionAbility 算成 `HH:mm` 字符串传入，随 `updateDuration` 刷新（本卡片设为 `1`，即 30 分钟，是系统允许的最短周期）
- **农历**：`i18n.getCalendar('zh-Hans-CN', 'chinese')` 取月/日，再映射成"九月初九"；失败时留空，不影响其他内容
- **节日**：农历节日（春节/元宵/端午/七夕/中秋/重阳/腊八）查表，没有则回退到公历节日（元旦/劳动节/国庆/圣诞）
- **点击**：整卡 `postCardAction({action:'router', abilityName:'EntryAbility'})`，只进天气应用。曾按分区跳系统时钟 / 日历（`startAbility` 打 `com.huawei.hmos.clock` / `com.huawei.hmos.calendar`），设备上返回"暂无可用打开方式"，已移除这条链路
- **完全透明底**：`backgroundColor(Color.Transparent)`，白字靠 `textShadow`（深色、radius 8–12）在浅色壁纸上撑对比度。透明卡片**别用 `#1FFFFFFF` 这类白色半透明** —— 白壁纸下会变成整张纯白卡片、白字完全消失

日期列表里「昨天」统一做淡化处理：文字降到 60% 白、图标 50% 不透明度、整行 80%，和今天/未来拉开层次。

**卡片显示哪个城市**：固定是**首页城市（城市列表第一位）**，不跟随你在 App 里浏览的城市。原来的实现是"谁在看就写谁"，切到上海后卡片就一直停在上海、改了首页也不变。现在快照只在 `index === 0` 时写入；首页发生变化（拖动排序 / 左滑设为首页 / 删除首页）后会立刻 `formProvider.updateForm` 推一次，不用等系统 30 分钟调度。

**数据从哪来**：App 加载首页城市成功后，会把它的天气裁剪成精简快照写入 `preferences`（`wx_settings` / `widget_snapshot`）。卡片在 `onAddForm` 里用 **同步** 方式读这份快照，所以添加到桌面即可出图，再异步拉一次最新数据 `updateForm` 覆盖。从未打开过 App 时会退回城市列表里的第一个城市自己拉一次。

**刷新时机**：
1. 系统定时 —— `form_config.json` 里 `updateDuration: 2`（单位 30 分钟，即每 1 小时）
2. App 内切城市 / 下拉刷新 / 冷启动加载完成时同步写快照
3. 4×4 卡片右上角刷新图标 → `postCardAction({action:'message'})` → `onFormEvent` 立即重拉

**交互**：轻触卡片 → `postCardAction({action:'router', abilityName:'EntryAbility'})` 打开主应用。

相关文件：`entryformability/EntryFormAbility.ets`、`widget/pages/WidgetCard.ets`、`service/WidgetSnapshot.ets`、`resources/base/profile/form_config.json`。卡片页面是独立编译单元（产物 `ets/widgets.abc`），不引用 `view/` 下的组件，只内联了图标映射。

## 数据源

默认接入 **Open-Meteo**，无需申请 Key、免费、支持中文地名：

| 用途 | 接口 |
| --- | --- |
| 天气预报 | `https://api.open-meteo.com/v1/forecast` |
| 城市搜索 | `https://geocoding-api.open-meteo.com/v1/search` |
| 空气质量 | `https://air-quality-api.open-meteo.com/v1/air-quality` |

接口字段已实测校验（`current` / `hourly` / `daily` 全部对齐）。请求带 `past_days=1`，所以 `daily` 序列第 0 项是昨天，共 11 天；`hourly` 则从昨天 00:00 起共 264 条，代码通过 `current.time` 的 `yyyy-MM-ddTHH` 前缀定位到当前小时，不依赖索引偏移。

### 换成自己的 API

只需改 `entry/src/main/ets/service/OpenMeteoService.ets`，上层 `WeatherRepository` 与所有 UI 都不用动：

1. 替换文件顶部的三个 `*_URL` 常量；若用和风天气，把 `key` 拼进 URL，或加到 `http.HttpRequestOptions.header`。
2. 在 `wxFetchForecast` / `wxSearchCities` 里换成对应字段名的解析（返回值仍组装成 `WxRawForecast` / `WxCity[]`）。
3. 天气码不是 WMO 时，在 `common/WeatherCode.ets` 的 `wxDesc` / `wxIcon` / `wxTheme` 里加一层映射。

> 若接口要求 HTTPS 之外的明文域名，还需在 `module.json5` 里配置网络白名单（当前 Open-Meteo 全为 HTTPS，无需配置）。

## 加载策略（缓存 + 预取 + 后台刷新）

### 本地缓存

- 存储：`preferences` 里 `wx_cache`，每个城市一条（key `c_<cityId>`），值是 `{ savedAt, weather }`
- 有效期：**30 分钟**（`WeatherCache.ets` 的 `WX_CACHE_TTL_MS`，改成 1 小时就是 `60 * 60 * 1000`）
- 城市被删除后，其缓存会在下次启动时由 `wxCachePrune()` 清理

### 启动流程

1. **同步读缓存**（`getPreferencesSync` + `getSync`）—— 不 await、不转圈，第一帧就有内容
2. 缓存缺失或已过期的城市，**并发预取**（每个城市错开 120ms 发起），滑到后几页不用等
3. 缓存还新鲜的直接跳过，一个请求都不发

### 分场景行为

| 场景 | 是否请求网络 |
| --- | --- |
| 冷启动，缓存 < 30 分钟 | 否，直接用缓存 |
| 冷启动，缓存 ≥ 30 分钟 / 无缓存 | 是（静默刷新，有旧数据时不转圈） |
| 滑到某个城市 | 新鲜则不发；过期则静默刷新 |
| **前台驻留** | **每 5 分钟检查一次，超过 30 分钟就静默刷新当前城市** |
| 从后台回到前台 | 当前城市过期才补一次 |
| **下拉刷新** | **强制请求，忽略缓存** |

过期判断用的是**内存里的加载时间戳**（`Index.loadedAt[]`，与 `cities` 同序、随重排一起搬家），不是 `preferences` 里的 `savedAt`。因为卡片和 WorkScheduler 跑在别的进程里，它们写进 `preferences` 的新数据，本进程的 preferences 实例读不到（preferences 是进程内缓存），拿它做判断会出现"该刷新却一直等"的情况。

**时间基准**：天气数据里的时间（`current.time` / `hourly.time` / `daily.time`，以及卡片上的「更新于」）全部来自 Open-Meteo 服务端，跟本机时间无关。本机时间只用在两处：缓存新鲜度判断（`Date.now()` 与 `savedAt` / `loadedAt` 相减）。所以手动改系统时间**不会改变天气数据**，只会影响刷新节奏 —— 往未来调会立刻触发刷新，往回调会让缓存长期不过期；代码里已把「时间差为负」也按过期处理，避免卡死。

静默刷新失败时会保留旧数据、不弹错误，只有"一片空白 + 请求失败"才显示错误页。

### 后台定时刷新

用 **WorkScheduler 延迟任务**（`WeatherWorkAbility`，type `workScheduler`）：`repeatCycleTime = 30 分钟`，`isPersisted = true`，网络条件 `NETWORK_TYPE_ANY`。任务唤醒后把城市列表里最多 6 个城市的天气重新拉一遍写进缓存，App 下次打开就直接命中。

卡片刷新（`EntryFormAbility`）拉到新数据时也会顺手写一份 App 缓存，两条链路共用一份数据。

> **关于「准点」的实话**：鸿蒙上第三方 App 没有常驻后台定时器的能力（长时任务只对音视频/导航等特定类型开放）。WorkScheduler 的 `repeatCycleTime` 下限是 20 分钟，而且系统会按电量、使用频率、待机分组做**合并与延后调度**，长期不打开的 App 可能几小时才跑一次。所以"每 30 分钟一定刷新"做不到，实际是"最快 30 分钟一次，具体由系统决定"。真正实时的数据只能靠打开 App 后的下拉刷新。

## 发布（GitHub Actions）

`.github/workflows/release.yml`：推送 `v*` 标签、或在 Actions 页面手动触发时，自动创建 Release 并附上 `dist/` 里的 HAP。

```bash
# 1. 本地构建
hvigorw assembleHap --mode module -p product=default --no-daemon
cp entry/build/default/outputs/default/entry-default-unsigned.hap dist/

# 2. 提交产物并打标签
git add dist && git commit -m "build: v1.0.0"
git tag v1.0.0
git push origin main --tags
```

> **为什么 workflow 不编译**：GitHub 的 runner 上没有 HarmonyOS SDK（DevEco Studio 及命令行工具都要用华为账号登录才能下载），所以自动构建 HAP 做不到。workflow 只负责把 `dist/` 里已提交的 HAP 作为附件发到 Release，源码构建仍在本地完成。

## 运行

本项目已用 DevEco Studio 自带的 hvigor 完整编译通过（`BUILD SUCCESSFUL`，0 error）。

```bash
# 命令行编译（任选）
hvigorw assembleHap --mode module -p product=default --no-daemon
```

**在 DevEco Studio 里跑起来：**

1. DevEco Studio (26.0+) → `File > Open` 打开本目录 `HarmonyWeather`
2. `File > Project Structure > Project > Signing Configs`，勾选 **Automatically generate signature**（登录华为账号，自动生成调试证书）
3. 连接真机或启动模拟器 → 点 Run

当前仓库不内置签名配置（`signingConfigs` 为空），命令行构建直接产出**未签名 HAP**，签名由使用方自行处理：

- 工程根目录：`HarmonyWeather-unsigned.hap`（每次构建后复制的一份，方便直接取用）
- 构建原始位置：`entry/build/default/outputs/default/entry-default-unsigned.hap`

签名可用 DevEco 的 `Automatically generate signature`，或用 `hap-sign-tool` 配自己的 p12 / p7b / cer。

## 目录结构

```
entry/src/main/ets/
├── entryability/EntryAbility.ets     沉浸式窗口（背景铺满、状态栏白色文字）+ 注册后台任务
├── entryformability/EntryFormAbility.ets  桌面卡片生命周期（onAddForm/onUpdateForm/onFormEvent）
├── workability/WeatherWorkAbility.ets     后台延迟任务：定时刷新天气缓存
├── pages/Index.ets                   主页面：背景层 + Swiper 多城市 + 顶部按钮 + 页码点 + 城市面板
├── widget/pages/WidgetCard.ets       卡片 UI（独立编译单元，2×2 / 2×4 / 4×4 三套布局）
├── widget/pages/WidgetCardDays.ets   2×2 双栏卡片 UI（独立编译单元）
├── widget/pages/WidgetCardClock.ets  2×4 透明时钟卡片 UI（已下线，源码保留）
├── model/WeatherModels.ets           全部数据结构（Wx 前缀，避免 interface 重名）
├── common/WeatherCode.ets            WMO 天气码 → 文案 / 图标 / 背景主题
├── service/
│   ├── OpenMeteoService.ets          HTTP 请求与原始响应解析
│   ├── WeatherRepository.ets         原始响应 → UI 快照（小时序列定位、指标整理）
│   ├── CityStore.ets                 城市列表持久化（preferences）
│   ├── WeatherCache.ets              天气本地缓存（30 分钟 TTL）与过期判断
│   ├── BackgroundRefresh.ets         WorkScheduler 延迟任务的注册 / 注销
│   ├── CalendarText.ets              公历 / 农历 / 节日文案 + 走时基准
│   ├── WidgetSnapshot.ets            卡片快照的裁剪 / 读写 / 尺寸记忆
│   └── LocationService.ets           定位 + 逆地理编码
└── view/
    ├── CityPage.ets                  单城市整页（含加载/错误/下拉刷新）
    ├── HourlyCard.ets                每小时卡片
    ├── DailyCard.ets                 10 天卡片（温度条）
    ├── MetricsGrid.ets               指标 2 列网格
    └── CitySheet.ets                 城市管理半模态
```

图标全部是自绘 SVG（`tools/make_weather_icons.py` 生成，28 个），无位图资源依赖。

## 实现要点

- 状态管理统一用 **V1**（`@State` / `@Prop` / `@Builder`），未混用 V2 装饰器
- `@Builder` 需要随参数刷新的地方（城市列表行）用**单参数对象字面量**传递
- 所有 `ForEach` 显式提供业务 key（城市 id / 时间字符串），不用索引
- 温度条用百分比宽度 + 百分比左偏移在 `Stack` 内定位，避免大量 `layoutWeight` 嵌套
- 小时数据按 `current.time` 的 `yyyy-MM-ddTHH` 与 `hourly.time` 前缀匹配定位起始下标，不依赖时区换算
- **内容卡片底色用 35% 黑（`#59000000`），不是白色磨砂**：白磨砂（`#26FFFFFF`）叠在晴天那种浅蓝背景上时，白字对比度只有 **1.8:1**，"昨天/今天/明天"几乎糊进背景；换成 35% 黑后约 **4.0:1**。实测各档位：20% 黑 2.8、30% 黑 3.5、35% 黑 4.0、40% 黑 4.6。相关色值集中在 `common/WxUi.ets`（`WX_CARD_BG` / `WX_TEXT_*` / `WX_PAST_ROW_OPACITY`），以后调色只改这一个文件
- **降水概率 0% 也要占位显示**：`Text(day.pop > 0 ? '6%' : '')` 会让 0% 的那天整块空掉，看着像漏渲染；改成始终输出 `${pop}%`，0% 用 `WX_TEXT_TERTIARY` 淡色，既对齐又不抢注意力
- **天气图标上那些"小点点"**：云朵是「多个圆 + 一个圆角矩形」拼出来的 SVG，缩到 28px 显示再叠半透明，拼接处的亚像素缝隙会透出背景色，看着像图标沾了脏东西；`ic_wx_overcast` / `ic_wx_fog` 还多一层 `#C9D6E2` 灰云，在深色卡片上直接变成一团灰点。三处一起改：① 所有云朵图形加同色 `stroke-width="1.5"` 把缝隙盖住；② 灰云提亮到 `#DDE7F1`；③ **昨天行不再对整行做 opacity**，淡化改用文字颜色（`#B3FFFFFF` / `#99FFFFFF`），温度条单独 0.45
- **城市顺序即 `cities` 数组顺序**，整份持久化，可以自由拖动。点列表项只切换浏览、不动顺序；只有左滑「设为首页」才会把它挪到第一位
- 列表第一位 = 启动默认页。正在浏览的那张卡片用「当前」小徽标标出，和第一位的「首页」徽标区分
- 拖动时 `onItemDragMove` 会在目标位置画一条 3vp 白色指示线；松手后 `applyCityOrder()` 在 `animateTo(280ms, FastOutSlowIn)` 里换数组，尝试让卡片位移过渡而不是瞬移
- 增删 / 调序后统一走 `applyCityOrder()`：以 `cityId` 为键重排 `weathers` / `loadingList` / `errorList` 三个平行数组，再按 `cityId` 重新定位 `currentIndex`，避免"删掉前面的城市后当前页跳到别人身上"

## 已知限制

- 编译残留 6 条 `geoLocationManager` 的 syscap 提示（"not supported on all devices"），已在代码中用 `canIUse('SystemCapability.Location.Location.Core')` 兜底，无定位能力的设备会提示手动搜索城市
- 2in1（PC 形态）未纳入 `deviceTypes`，界面按竖屏手机 / 平板设计
- 空气质量卡片依赖 Open-Meteo 空气接口，请求失败时自动隐藏该卡片，不影响主天气展示
- **卡片布局未在真机核对**：4×4 / 2×4 各机型栅格高度略有差异，内容按 320×320、320×156 估算。若 4×4 底部「更新于」被挤掉，把 `WidgetCard.ets` 里 `hourList(6)` 改成 4 或 `dayList(4)` 改成 3；2×4 同理把 `dayList(5)` 调小即可
- 卡片刷新受系统配额限制（免费卡片每天刷新次数有限），`updateDuration: 2` 已按 1 小时一次配置，不要改成更频繁
