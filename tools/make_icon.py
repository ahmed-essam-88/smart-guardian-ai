"""Generates the Smart Guardian Egypt icon set.

Concept: a gradient shield (protection) holding a stylized flame (fire-risk
monitoring) carrying circuit traces and nodes (AI / smart infrastructure),
with a subtle pyramid silhouette at the shield base (Egyptian innovation).
Flat, premium, no text.

Outputs:
  android/app/src/main/res/mipmap-*/ic_launcher.png (+ _round, _foreground)
  assets/brand/logo.png             (with background, for splash/about)
  assets/brand/logo_transparent.png (transparent mark)

Run:  python3 tools/make_icon.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

S = 1024
# Brand palette (matches lib/core/theme.dart)
BG_TOP = (11, 29, 50)      # #0B1D32
BG_BOTTOM = (7, 20, 38)    # #071426
CARD = (16, 36, 59)        # #10243B
BLUE = (22, 119, 255)      # #1677FF
CYAN = (0, 212, 255)       # #00D4FF
ORANGE = (249, 115, 22)    # #F97316
ORANGE_HI = (255, 180, 84)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def cubic(p0, p1, p2, p3, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def shield_path(cx, cy, w, h):
    """Classic shield: flat top, chamfered corners, curved sides to a tip."""
    top = cy - h / 2
    chamfer = w * 0.10
    pts = [(cx - w / 2 + chamfer, top), (cx + w / 2 - chamfer, top)]
    # right chamfer
    pts += cubic((cx + w / 2 - chamfer, top), (cx + w / 2, top + h * 0.02),
                 (cx + w / 2, top + h * 0.06), (cx + w / 2, top + h * 0.14), 8)
    # right side to tip
    pts += cubic((cx + w / 2, top + h * 0.14),
                 (cx + w / 2, top + h * 0.52),
                 (cx + w * 0.30, top + h * 0.82),
                 (cx, cy + h / 2), 40)
    # left side back up
    pts += cubic((cx, cy + h / 2),
                 (cx - w * 0.30, top + h * 0.82),
                 (cx - w / 2, top + h * 0.52),
                 (cx - w / 2, top + h * 0.14), 40)
    # left chamfer
    pts += cubic((cx - w / 2, top + h * 0.14), (cx - w / 2, top + h * 0.06),
                 (cx - w / 2, top + h * 0.02), (cx - w / 2 + chamfer, top), 8)
    return pts


def flame_path(cx, cy, w, h):
    """Asymmetric flame with a right-leaning flick and a rounded belly."""
    left_start = (cx - w * 0.44, cy + h * 0.18)
    tip = (cx + w * 0.10, cy - h * 0.54)
    pts = cubic(left_start,
                (cx - w * 0.55, cy - h * 0.10),
                (cx - w * 0.30, cy - h * 0.34),
                tip, 40)
    pts += cubic(tip,
                 (cx + w * 0.34, cy - h * 0.30),
                 (cx + w * 0.52, cy - h * 0.04),
                 (cx + w * 0.40, cy + h * 0.22), 36)
    pts += cubic((cx + w * 0.40, cy + h * 0.22),
                 (cx + w * 0.22, cy + h * 0.50),
                 (cx - w * 0.28, cy + h * 0.48),
                 left_start, 36)
    return pts


def gradient_image(size, c1, c2):
    grad = Image.new("RGBA", (1, size))
    px = grad.load()
    for i in range(size):
        px[0, i] = lerp(c1, c2, i / (size - 1)) + (255,)
    return grad.resize((size, size))


def masked_gradient(size, pts, c1, c2):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.paste(gradient_image(size, c1, c2), (0, 0), mask)
    return img, mask


def draw_mark(size, fg_scale=1.0, with_bg=True):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = size / 2
    cy = size / 2

    if with_bg:
        bg = gradient_image(size, BG_TOP, BG_BOTTOM)
        glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gr = size * 0.33
        ImageDraw.Draw(glow).ellipse(
            [cx - gr, cy - gr * 1.05, cx + gr, cy + gr * 0.95],
            fill=CYAN + (40,))
        glow = glow.filter(ImageFilter.GaussianBlur(size * 0.08))
        bg.alpha_composite(glow)
        img.alpha_composite(bg)

    sw = size * 0.62 * fg_scale
    sh = size * 0.70 * fg_scale

    # Shield: gradient ring via outer-minus-inner masks (uniform stroke).
    outer = shield_path(cx, cy, sw, sh)
    stroke = size * 0.024 * fg_scale
    inner = shield_path(cx, cy, sw - 2 * stroke, sh - 2 * stroke)
    om = Image.new("L", (size, size), 0)
    ImageDraw.Draw(om).polygon(outer, fill=255)
    im = Image.new("L", (size, size), 0)
    ImageDraw.Draw(im).polygon(inner, fill=255)
    ring = Image.eval(om, lambda v: v).point(lambda v: v)
    ring = Image.composite(om, Image.new("L", (size, size), 0), om)
    ring = om.copy()
    ring.paste(0, (0, 0, size, size), im)
    shield_ring = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shield_ring.paste(gradient_image(size, BLUE, CYAN), (0, 0), ring)
    body = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    body.paste(Image.new("RGBA", (size, size), CARD + (255,)), (0, 0), im)
    img.alpha_composite(body)
    img.alpha_composite(shield_ring)

    # Pyramid silhouette inside the shield base.
    d = ImageDraw.Draw(img)
    lw = max(3, int(size * 0.0075 * fg_scale))
    pw, ph = sw * 0.40, sh * 0.13
    pby = cy + sh * 0.33
    pc = lerp(BLUE, CYAN, 0.55)
    d.line([cx - pw / 2, pby, cx, pby - ph], fill=pc, width=lw)
    d.line([cx + pw / 2, pby, cx, pby - ph], fill=pc, width=lw)
    d.line([cx - pw / 2, pby, cx + pw / 2, pby], fill=pc, width=lw)
    d.line([cx, pby - ph, cx + pw * 0.14, pby], fill=pc, width=max(2, lw - 2))

    # Flame with circuit traces clipped to the flame shape.
    fw, fh = sw * 0.52, sh * 0.46
    fcy = cy - sh * 0.09
    fpts = flame_path(cx, fcy, fw, fh)
    flame_img, fmask = masked_gradient(size, fpts, ORANGE_HI, ORANGE)

    circ = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cd = ImageDraw.Draw(circ)
    clw = max(3, int(size * 0.011 * fg_scale))
    nr = max(4, int(size * 0.020 * fg_scale))
    nodes = [(cx - fw * 0.10, fcy + fh * 0.02),
             (cx + fw * 0.13, fcy - fh * 0.14),
             (cx + fw * 0.02, fcy + fh * 0.20)]
    for a, b in [(0, 2), (2, 1)]:
        xa, ya = nodes[a]
        xb, yb = nodes[b]
        cd.line([xa, ya, xa, yb], fill=CYAN + (255,), width=clw)
        cd.line([xa, yb, xb, yb], fill=CYAN + (255,), width=clw)
    for x, y in nodes:
        cd.ellipse([x - nr, y - nr, x + nr, y + nr], fill=CYAN + (255,))
        cd.ellipse([x - nr * 0.45, y - nr * 0.45, x + nr * 0.45, y + nr * 0.45],
                   fill=(0, 0, 0, 0))
    circ.putalpha(Image.composite(circ.getchannel("A"),
                                  Image.new("L", (size, size), 0), fmask))
    img.alpha_composite(flame_img)
    img.alpha_composite(circ)
    # Re-punch node centers as transparent holes for the "chip pin" look.
    d = ImageDraw.Draw(img)
    for x, y in nodes:
        d.ellipse([x - nr * 0.42, y - nr * 0.42, x + nr * 0.42, y + nr * 0.42],
                  fill=BG_BOTTOM + (255,))

    return img


def circle_mask(img):
    size = img.width
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size, size], fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def save(img, path, size=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if size:
        img = img.resize((size, size), Image.LANCZOS)
    img.save(path)


def main():
    full = draw_mark(S, fg_scale=1.0, with_bg=True)
    # Adaptive foreground: mark at 58% so nothing is clipped by the mask.
    fg = draw_mark(S, fg_scale=0.58, with_bg=False)

    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96,
                 "xxhdpi": 144, "xxxhdpi": 192}
    for name, px in densities.items():
        base = os.path.join(ROOT, "android/app/src/main/res", f"mipmap-{name}")
        save(full, os.path.join(base, "ic_launcher.png"), px)
        save(circle_mask(full), os.path.join(base, "ic_launcher_round.png"), px)
        save(fg, os.path.join(base, "ic_launcher_foreground.png"), px)

    brand = os.path.join(ROOT, "assets/brand")
    save(full, os.path.join(brand, "logo.png"), 512)
    save(draw_mark(S, fg_scale=0.92, with_bg=False),
         os.path.join(brand, "logo_transparent.png"), 512)
    print("icon set generated")


if __name__ == "__main__":
    main()
