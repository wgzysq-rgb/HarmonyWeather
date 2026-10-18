# -*- coding: utf-8 -*-
"""生成天气 App 所需的 SVGu 图标资源（纯静态形状，规避 ArkUI 对滤镜/渐变的支持差异）。"""
import os

OUT = 'C:/Users/wgzys/WorkBuddy/2026-10-17-22-43-23/HarmonyWeather/entry/src/main/resources/base/media'

W_SUN = '#FFCF4A'
W_SUN_CORE = '#FFC02E'
W_MOON = '#E9EFF8'
W_CLOUD = '#FFFFFF'
W_CLOUD_BACK = '#C9D6E2'
W_RAIN = '#6FB8FF'
W_RAIN_DEEP = '#4A9BF0'
W_SNOW = '#EAF3FF'
W_BOLT = '#FFD84D'


def svg(body, w=100, h=100):
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
        f'{body}\n</svg>\n'
    )


def sun(cx, cy, r, ray_len, ray_w, ray_gap=True):
    parts = []
    n = 8
    import math
    for i in range(n):
        a = math.radians(i * 45)
        x1 = cx + math.cos(a) * (r + ray_len * 0.45)
        y1 = cy + math.sin(a) * (r + ray_len * 0.45)
        x2 = cx + math.cos(a) * (r + ray_len)
        y2 = cy + math.sin(a) * (r + ray_len)
        parts.append(
            f'  <line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{W_SUN}" stroke-width="{ray_w}" stroke-linecap="round"/>'
        )
    parts.append(f'  <circle cx="{cx}" cy="{cy}" r="{r}" fill="{W_SUN_CORE}"/>')
    return '\n'.join(parts)


def moon(cx, cy, scale):
    # C 形月牙：外弧与内弧都用二次贝塞尔，两端收尖
    x0 = cx - 14 * scale
    x1 = cx + 14 * scale
    ytop = cy - 38 * scale
    ybot = cy + 38 * scale
    body = (
        f'  <path d="M {x1:.1f} {ytop:.1f} '
        f'Q {x0 - 16 * scale:.1f} {cy - 26 * scale:.1f} {x0 - 16 * scale:.1f} {cy:.1f} '
        f'Q {x0 - 16 * scale:.1f} {cy + 26 * scale:.1f} {x1:.1f} {ybot:.1f} '
        f'Q {cx - 2 * scale:.1f} {cy + 16 * scale:.1f} {cx - 2 * scale:.1f} {cy:.1f} '
        f'Q {cx - 2 * scale:.1f} {cy - 16 * scale:.1f} {x1:.1f} {ytop:.1f} Z" '
        f'fill="{W_MOON}"/>'
    )
    return body


def cloud(dx=0.0, dy=0.0, s=1.0, color=W_CLOUD):
    def X(v):
        return 50 + (v - 50) * s + dx

    def Y(v):
        return 50 + (v - 50) * s + dy

    def R(v):
        return v * s

    return '\n'.join([
        f'  <circle cx="{X(40):.1f}" cy="{Y(64):.1f}" r="{R(15):.1f}" fill="{color}"/>',
        f'  <circle cx="{X(57):.1f}" cy="{Y(56):.1f}" r="{R(18):.1f}" fill="{color}"/>',
        f'  <circle cx="{X(72):.1f}" cy="{Y(65):.1f}" r="{R(13):.1f}" fill="{color}"/>',
        f'  <rect x="{X(28):.1f}" y="{Y(63):.1f}" width="{R(52):.1f}" height="{R(17):.1f}" '
        f'rx="{R(8.5):.1f}" fill="{color}"/>',
    ])


def rain_drops(count, y0, length, color=W_RAIN, spread=46, cx=52, width=5.0, slant=3.0):
    parts = []
    step = spread / (count - 1) if count > 1 else 0
    for i in range(count):
        x = cx - spread / 2 + i * step
        parts.append(
            f'  <line x1="{x:.1f}" y1="{y0}" x2="{x - slant:.1f}" y2="{y0 + length}" '
            f'stroke="{color}" stroke-width="{width}" stroke-linecap="round"/>'
        )
    return '\n'.join(parts)


def snowflake(cx, cy, r, w=4.0, color=W_SNOW):
    import math
    parts = []
    for i in range(3):
        a = math.radians(i * 60)
        x1 = cx - math.cos(a) * r
        y1 = cy - math.sin(a) * r
        x2 = cx + math.cos(a) * r
        y2 = cy + math.sin(a) * r
        parts.append(
            f'  <line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>'
        )
    return '\n'.join(parts)


def bolt(cx, cy, s=1.0):
    pts = [(58, 44), (44, 68), (55, 68), (48, 90), (70, 60), (58, 60), (66, 44)]
    d = ' '.join([f'{cx + (p[0] - 57) * s:.1f},{cy + (p[1] - 66) * s:.1f}' for p in pts])
    return f'  <polygon points="{d}" fill="{W_BOLT}"/>'


files = {}

files['ic_wx_sun'] = svg(sun(50, 50, 21, 15, 6.0))
files['ic_wx_moon'] = svg(moon(52, 50, 1.0))
files['ic_wx_partly_day'] = svg(
    sun(36, 34, 14, 11, 5.0) + '\n' + cloud(dx=6, dy=8, s=0.92)
)
files['ic_wx_partly_night'] = svg(
    moon(34, 36, 0.62) + '\n' + cloud(dx=6, dy=10, s=0.9)
)
files['ic_wx_cloudy'] = svg(cloud(s=1.0))
files['ic_wx_overcast'] = svg(
    cloud(dx=8, dy=-12, s=0.72, color=W_CLOUD_BACK) + '\n' + cloud(dx=-6, dy=8, s=0.86)
)
files['ic_wx_fog'] = svg(
    cloud(dy=-8, s=0.82) + '\n' +
    '\n'.join([
        f'  <line x1="{x}" y1="80" x2="{x + w}" y2="80" stroke="{W_CLOUD_BACK}" stroke-width="6" stroke-linecap="round"/>'
        for x, w in [(28, 26), (58, 18), (32, 34)]
    ])
)
files['ic_wx_drizzle'] = svg(
    cloud(dy=-4, s=0.86) + '\n' + rain_drops(3, 82, 7, spread=34, cx=50, width=4.5)
)
files['ic_wx_rain'] = svg(
    cloud(dy=-6, s=0.88) + '\n' + rain_drops(4, 80, 12, spread=42, cx=52)
)
files['ic_wx_heavy_rain'] = svg(
    cloud(dy=-8, s=0.9) + '\n' +
    rain_drops(3, 78, 13, spread=34, cx=44, width=5.5) + '\n' +
    rain_drops(2, 86, 12, spread=14, cx=62, color=W_RAIN_DEEP, width=5.5)
)
files['ic_wx_thunder'] = svg(
    cloud(dy=-8, s=0.88) + '\n' + bolt(52, 82, 0.86)
)
files['ic_wx_snow'] = svg(
    cloud(dy=-8, s=0.88) + '\n' +
    snowflake(38, 86, 6, 4.0) + '\n' + snowflake(56, 90, 6, 4.0) + '\n' + snowflake(70, 84, 5, 3.6)
)

# ---------- 功能图标（24 viewBox，白色描边） ----------
def ui(body, w=24, h=24):
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
        f'{body}\n</svg>\n'
    )


files['ic_ui_search'] = ui(
    '  <circle cx="11" cy="11" r="6.4" fill="none" stroke="#FFFFFF" stroke-width="2"/>'
    '<line x1="15.8" y1="15.8" x2="20.5" y2="20.5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
)
files['ic_ui_add'] = ui(
    '<line x1="12" y1="5.5" x2="12" y2="18.5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
    '<line x1="5.5" y1="12" x2="18.5" y2="12" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
)
files['ic_ui_list'] = ui(
    '<circle cx="5" cy="7" r="1.7" fill="#FFFFFF"/>'
    '<circle cx="5" cy="12" r="1.7" fill="#FFFFFF"/>'
    '<circle cx="5" cy="17" r="1.7" fill="#FFFFFF"/>'
    '<line x1="9.5" y1="7" x2="20" y2="7" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
    '<line x1="9.5" y1="12" x2="20" y2="12" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
    '<line x1="9.5" y1="17" x2="20" y2="17" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
)
files['ic_ui_close'] = ui(
    '<line x1="6.5" y1="6.5" x2="17.5" y2="17.5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
    '<line x1="17.5" y1="6.5" x2="6.5" y2="17.5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
)
files['ic_ui_location'] = ui(
    '  <path d="M12 3.2c-3.7 0-6.7 2.9-6.7 6.5 0 4.6 6.7 11.1 6.7 11.1s6.7-6.5 6.7-11.1c0-3.6-3-6.5-6.7-6.5z" '
    'fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linejoin="round"/>'
    '<circle cx="12" cy="9.7" r="2.5" fill="none" stroke="#FFFFFF" stroke-width="1.9"/>'
)
files['ic_ui_trash'] = ui(
    '<path d="M5 7h14" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'
    '<path d="M9.2 7V5.4h5.6V7" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linejoin="round"/>'
    '<path d="M7 7l1 12.2h8L17 7" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linejoin="round"/>'
)

# ---------- 指标图标（白色描边） ----------
files['ic_m_uv'] = ui(sun(12, 12, 4.4, 4.2, 1.8).replace(W_SUN, '#FFFFFF').replace(W_SUN_CORE, '#FFFFFF'))
files['ic_m_wind'] = ui(
    '<path d="M3 9h9.5a2.6 2.6 0 1 0-2.6-2.6" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M3 13.5h13a2.6 2.6 0 1 1-2.6 2.6" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M3 18h6.5" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
)
files['ic_m_humidity'] = ui(
    '<path d="M12 3.5s5.6 6.2 5.6 9.6A5.6 5.6 0 0 1 6.4 13.1C6.4 9.7 12 3.5 12 3.5z" '
    'fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linejoin="round"/>'
)
files['ic_m_visibility'] = ui(
    '<path d="M2.5 12s3.8-5.6 9.5-5.6S21.5 12 21.5 12s-3.8 5.6-9.5 5.6S2.5 12 2.5 12z" '
    'fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linejoin="round"/>'
    '<circle cx="12" cy="12" r="2.9" fill="none" stroke="#FFFFFF" stroke-width="1.9"/>'
)
files['ic_m_pressure'] = ui(
    '<path d="M4 17a8 8 0 1 1 16 0" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<line x1="12" y1="17" x2="15.6" y2="11.4" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<circle cx="12" cy="17" r="1.5" fill="#FFFFFF"/>'
)
files['ic_m_sunrise'] = ui(
    '<line x1="2.5" y1="19" x2="21.5" y2="19" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M6.5 19a5.5 5.5 0 0 1 11 0" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<line x1="12" y1="3" x2="12" y2="6" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<line x1="4.6" y1="7.2" x2="6.4" y2="9" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<line x1="19.4" y1="7.2" x2="17.6" y2="9" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
)
files['ic_m_sunset'] = ui(
    '<line x1="2.5" y1="19" x2="21.5" y2="19" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M6.5 19a5.5 5.5 0 0 1 11 0" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M12 3v6" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M9.4 6.6L12 9.4l2.6-2.8" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>'
)
files['ic_m_feels'] = ui(
    '<path d="M10 4.6a2 2 0 0 1 4 0v9.2a4 4 0 1 1-4 0V4.6z" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linejoin="round"/>'
    '<circle cx="12" cy="17.4" r="1.9" fill="#FFFFFF"/>'
)
files['ic_m_rain'] = ui(
    '<path d="M7 13.5a3.6 3.6 0 0 1 .3-7.2 5 5 0 0 1 9.4 1.2 3 3 0 0 1-.4 6h-9z" '
    'fill="none" stroke="#FFFFFF" stroke-width="1.8" stroke-linejoin="round"/>'
    '<line x1="9" y1="16.5" x2="8" y2="20" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<line x1="13" y1="16.5" x2="12" y2="20" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<line x1="17" y1="16.5" x2="16" y2="20" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
)
files['ic_m_aqi'] = ui(
    '<path d="M4 15.5h8.5a2.4 2.4 0 1 0-2.4-2.4" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M4 19.5h13a2.4 2.4 0 1 1-2.4 2.4" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
    '<path d="M4 11.5h5" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round"/>'
)

os.makedirs(OUT, exist_ok=True)
for name, content in files.items():
    with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8') as f:
        f.write(content)
print('generated', len(files), 'icons')
