/**
 * 内容卡片的统一视觉参数。
 *
 * 卡片底色不要用白色半透明（`#26FFFFFF` 这类）—— 晴天主题的背景本身就是浅蓝，
 * 白磨砂叠上去之后卡片几乎发白，白字直接糊在背景里看不清。
 * 用深色半透明压暗卡片，白字在任何主题下都能读。
 */

/** 内容卡片底色：35% 黑。白字对比度约 4.0:1（原来白色磨砂只有 1.8:1） */
export const WX_CARD_BG: string = '#59000000';

/** 卡片内次级说明文字（浅灰白） */
export const WX_TEXT_SECONDARY: string = '#D9FFFFFF';

/** 卡片内更弱的辅助文字 */
export const WX_TEXT_TERTIARY: string = '#99FFFFFF';

/** 降水概率这类带强调色的小字 */
export const WX_TEXT_ACCENT: string = '#CCE8FF';

/** 已有数据的行 */
export const WX_TEXT_PRIMARY: string = '#FFFFFFFF';

/**
 * 昨天行温度条的透明度。
 * 注意：不要对整行做 opacity —— 天气图标是多个圆/矩形拼出来的 SVG，
 * 半透明合成会把拼接处的抗锯齿缝隙放大成灰点，看着像图标上沾了脏东西。
 * 昨天的淡化靠文字颜色（#B3FFFFFF / #99FFFFFF）来做。
 */
export const WX_PAST_ROW_OPACITY: number = 0.45;
