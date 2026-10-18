import math
import struct
import zlib


def write_png(path, width, height, rgba_rows):
    raw = bytearray()
    for row in rgba_rows:
        raw.append(0)
        raw.extend(row)
    compressed = zlib.compress(bytes(raw), 9)

    def chunk(tag, data):
        out = struct.pack('>I', len(data)) + tag + data
        out += struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF)
        return out

    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(png)


def smoothstep(edge0, edge1, x):
    if edge1 == edge0:
        return 0.0
    t = (x - edge0) / (edge1 - edge0)
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def circle_cov(px, py, cx, cy, r, soft=1.5):
    d = math.hypot(px - cx, py - cy)
    return 1.0 - smoothstep(r - soft, r + soft, d)


SIZE = 1024


def build_background():
    rows = []
    top = (16, 46, 92)
    bottom = (58, 145, 214)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        base_r = top[0] + (bottom[0] - top[0]) * t
        base_g = top[1] + (bottom[1] - top[1]) * t
        base_b = top[2] + (bottom[2] - top[2]) * t
        row = bytearray()
        for x in range(SIZE):
            # soft radial highlight at upper-right
            d = math.hypot(x - SIZE * 0.72, y - SIZE * 0.26) / (SIZE * 0.55)
            glow = max(0.0, 1.0 - d) ** 2 * 0.22
            r = int(min(255, base_r + 255 * glow * 0.55))
            g = int(min(255, base_g + 255 * glow * 0.7))
            b = int(min(255, base_b + 255 * glow * 0.9))
            row.extend((r, g, b, 255))
        rows.append(row)
    return rows


def build_foreground():
    # sun behind the cloud
    sun_c = (SIZE * 0.62, SIZE * 0.40)
    sun_r = SIZE * 0.20
    # cloud body: overlapping circles + base slab
    blobs = [
        (SIZE * 0.40, SIZE * 0.60, SIZE * 0.155),
        (SIZE * 0.53, SIZE * 0.545, SIZE * 0.195),
        (SIZE * 0.66, SIZE * 0.615, SIZE * 0.145),
    ]
    slab = (SIZE * 0.30, SIZE * 0.60, SIZE * 0.70, SIZE * 0.755)

    rows = []
    for y in range(SIZE):
        row = bytearray()
        for x in range(SIZE):
            px = x + 0.5
            py = y + 0.5

            sun = circle_cov(px, py, sun_c[0], sun_c[1], sun_r, 2.0)

            cloud = 0.0
            for (cx, cy, r) in blobs:
                cloud = max(cloud, circle_cov(px, py, cx, cy, r, 2.0))
            # rounded slab
            inset = SIZE * 0.09
            if slab[0] - inset <= px <= slab[2] + inset and slab[1] <= py <= slab[3]:
                dx = 0.0
                if px < slab[0]:
                    dx = slab[0] - px
                elif px > slab[2]:
                    dx = px - slab[2]
                dy = 0.0
                if py < slab[1] + inset:
                    dy = slab[1] + inset - py
                elif py > slab[3] - inset:
                    dy = py - (slab[3] - inset)
                d = math.hypot(dx, dy)
                cloud = max(cloud, 1.0 - smoothstep(inset - 2.0, inset + 2.0, d))

            r_acc, g_acc, b_acc, a_acc = 0.0, 0.0, 0.0, 0.0

            if sun > 0.001:
                # sun: warm yellow with a slightly lighter core
                sr, sg, sb = 255, 204, 92
                r_acc = sr * sun
                g_acc = sg * sun
                b_acc = sb * sun
                a_acc = sun

            if cloud > 0.001:
                cr, cg, cb = 255, 255, 255
                # cloud wins where it is opaque, blends at edges
                na = cloud + a_acc * (1 - cloud)
                if na > 0:
                    r_acc = (cr * cloud + r_acc * (1 - cloud))
                    g_acc = (cg * cloud + g_acc * (1 - cloud))
                    b_acc = (cb * cloud + b_acc * (1 - cloud))
                a_acc = na

            row.extend((int(r_acc), int(g_acc), int(b_acc), int(min(255, a_acc * 255))))
        rows.append(row)
    return rows


def compose(back_rows, front_rows):
    rows = []
    for y in range(SIZE):
        brow = back_rows[y]
        frow = front_rows[y]
        row = bytearray()
        for x in range(SIZE):
            i = x * 4
            fa = frow[i + 3] / 255.0
            r = int(frow[i] * fa + brow[i] * (1 - fa))
            g = int(frow[i + 1] * fa + brow[i + 1] * (1 - fa))
            b = int(frow[i + 2] * fa + brow[i + 2] * (1 - fa))
            row.extend((r, g, b, 255))
        rows.append(row)
    return rows


if __name__ == '__main__':
    base = 'C:/Users/wgzys/WorkBuddy/2026-10-17-22-43-23/HarmonyWeather'
    back = build_background()
    front = build_foreground()
    write_png(base + '/AppScope/resources/base/media/background.png', SIZE, SIZE, back)
    write_png(base + '/AppScope/resources/base/media/foreground.png', SIZE, SIZE, front)
    write_png(base + '/entry/src/main/resources/base/media/startIcon.png', SIZE, SIZE, compose(back, front))
    print('icons generated')
