"""Generates the Smart Guardian AI icon set (shield + flame + circuit)."""
import os, math
from PIL import Image, ImageDraw, ImageFilter

S = 1024
NAVY = (5, 9, 20)
BLUE = (45, 156, 255)
CYAN = (53, 224, 255)
ORANGE = (255, 138, 45)

def shield_points(cx, cy, w, h):
    pts = []
    top = cy - h / 2
    for i in range(0, 21):
        t = i / 20
        pts.append((cx - w / 2 + w * t, top + (8 * math.sin(t * math.pi)) * -1 + 40 * abs(t - .5) * 0))
    # right side down to the tip
    for i in range(1, 31):
        t = i / 30
        x = cx + (w / 2) * (1 - t ** 2.2)
        y = top + h * 0.45 + h * 0.55 * t
        pts.append((x, y))
    for i in range(1, 31):
        t = i / 30
        x = cx - (w / 2) * t ** 2.2 * 0 
    # left side back up
    left = []
    for i in range(30, 0, -1):
        t = i / 30
        x = cx - (w / 2) * (1 - t ** 2.2)
        y = top + h * 0.45 + h * 0.55 * t
        left.append((x, y))
    pts = [(cx - w / 2, top), (cx + w / 2, top)] + \
          [(cx + (w / 2) * (1 - (i / 30) ** 2.2), top + h * 0.45 + h * 0.55 * (i / 30)) for i in range(0, 31)] + \
          [(cx - (w / 2) * (1 - (i / 30) ** 2.2), top + h * 0.45 + h * 0.55 * (i / 30)) for i in range(30, -1, -1)]
    return pts

def flame(d, cx, cy, sc, fill):
    pts = []
    # simple teardrop flame outline
    for i in range(0, 61):
        t = i / 60
        a = t * 2 * math.pi
        r = 1 - 0.0
        x = math.sin(a) * (1 - math.cos(a)) * 0.62
        y = -(math.cos(a) * 0.9 + 0.1) 
        pts.append((cx + x * sc, cy + (y + 0.0) * sc))
    d.polygon(pts, fill=fill)

def draw_foreground(size=S, with_bg=False):
    img = Image.new('RGBA', (S, S), NAVY + (255,) if with_bg else (0, 0, 0, 0))
    glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = S / 2, S / 2 + 10
    sp = shield_points(cx, cy, 460, 560)
    gd.polygon(sp, fill=BLUE + (140,))
    glow = glow.filter(ImageFilter.GaussianBlur(34))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img)
    d.polygon(sp, fill=(10, 20, 42, 255))
    d.line(sp + [sp[0]], fill=BLUE + (255,), width=16, joint='curve')
    # inner outline
    inner = shield_points(cx, cy + 4, 392, 484)
    d.line(inner + [inner[0]], fill=CYAN + (110,), width=4, joint='curve')
    # circuit traces
    tr = CYAN + (230,)
    for (x1, y1, x2, y2, x3, y3) in [
        (cx - 150, cy - 150, cx - 150, cy - 70, cx - 90, cy - 20),
        (cx + 150, cy - 150, cx + 150, cy - 70, cx + 90, cy - 20),
        (cx - 120, cy + 120, cx - 120, cy + 60, cx - 70, cy + 20),
        (cx + 120, cy + 120, cx + 120, cy + 60, cx + 70, cy + 20),
    ]:
        d.line([(x1, y1), (x2, y2), (x3, y3)], fill=tr, width=8)
        d.ellipse([x1 - 14, y1 - 14, x1 + 14, y1 + 14], outline=tr, width=6, fill=NAVY + (255,))
    # flame
    flame(d, cx, cy + 40, 170, ORANGE + (255,))
    flame(d, cx, cy + 70, 95, (255, 205, 120, 255))
    return img

def save(img, path, px):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((px, px), Image.LANCZOS).save(path)

if __name__ == '__main__':
    root = 'android/app/src/main/res'
    full = draw_foreground(with_bg=True)
    fg = draw_foreground(with_bg=False)
    # adaptive foreground needs safe zone: shrink content to ~62%
    canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    small = fg.resize((int(S * 0.66), int(S * 0.66)), Image.LANCZOS)
    canvas.paste(small, ((S - small.width) // 2, (S - small.height) // 2), small)
    legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    adaptive = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
    for k, px in legacy.items():
        save(full, f'{root}/mipmap-{k}/ic_launcher.png', px)
        # round legacy icon
        r = full.resize((px, px), Image.LANCZOS)
        m = Image.new('L', (px, px), 0)
        ImageDraw.Draw(m).ellipse([0, 0, px - 1, px - 1], fill=255)
        r.putalpha(m)
        r.save(f'{root}/mipmap-{k}/ic_launcher_round.png')
    for k, px in adaptive.items():
        save(canvas, f'{root}/mipmap-{k}/ic_launcher_foreground.png', px)
    os.makedirs(f'{root}/mipmap-anydpi-v26', exist_ok=True)
    os.makedirs(f'{root}/values', exist_ok=True)
    open(f'{root}/values/ic_launcher_background.xml', 'w').write(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#050914</color>\n</resources>\n')
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@color/ic_launcher_background"/>\n'
           '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
    open(f'{root}/mipmap-anydpi-v26/ic_launcher.xml', 'w').write(xml)
    open(f'{root}/mipmap-anydpi-v26/ic_launcher_round.xml', 'w').write(xml)
    # splash / in-app logo
    os.makedirs('assets/brand', exist_ok=True)
    full.resize((512, 512), Image.LANCZOS).save('assets/brand/logo.png')
    fg.resize((512, 512), Image.LANCZOS).save('assets/brand/logo_transparent.png')
    full.save('/tmp/icon_preview.png')
    print('icons done')
