#!/usr/bin/env python3
"""Generate the bundled sample-listing imagery (assets/seed/*.jpg).

Elegant, clearly-illustrative placeholders in the Velvet Ledger palette — NOT
real product photography. Each item gets FOUR distinct "angles" so a listing's
swipe gallery feels full:

  {name}.jpg    atelier cover  — serif monogram, icon chip, hairline frame
  {name}_2.jpg  icon study     — soft radial spotlight, large category glyph
  {name}_3.jpg  editorial      — moody vertical wash, gold rule + label
  {name}_4.jpg  tonal          — faint glyph watermark, corner accents

The cover keeps the bare {name}.jpg filename so existing references (the intro
carousel heroes, the demo _mine() item) keep resolving. Category glyphs are the
same Material icons the app shows (CategoryIcon in category_avatar.dart).

Run:  python3 tool/make_seed_images.py
"""
import os

from PIL import (Image, ImageChops, ImageDraw, ImageFont, ImageOps)

W, H = 720, 900
OUT = "assets/seed"

SERIF = "assets/fonts/PlayfairDisplay-SemiBold.ttf"
SERIF_BOLD = "assets/fonts/PlayfairDisplay-Bold.ttf"
SANS = "assets/fonts/PlusJakartaSans-SemiBold.ttf"
ICON_FONT = ("/Users/rishika/Documents/development/flutter/bin/cache/"
             "artifacts/material_fonts/MaterialIcons-Regular.otf")

GOLD = (201, 162, 80)

# Material icon codepoints — must match CategoryIcon in category_avatar.dart.
ICON = {
    "designerBags": 0xF37D,   # shopping_bag_outlined
    "eventWear": 0xEF4C,      # checkroom_outlined
    "partyWear": 0xEF38,      # celebration_outlined
    "sportsKits": 0xF3D6,     # sports_tennis_outlined
    "jewellery": 0xF05E7,     # diamond_outlined
    "watches": 0xF4B2,        # watch_outlined
    "accessories": 0xF3F6,    # style_outlined
}

# (name, monogram, category, LABEL, deep RGB, mid RGB, ink RGB, accent RGB)
ITEMS = [
    ("bag_chanel", "C", "designerBags", "CHANEL",
     (46, 12, 20), (150, 58, 74), (247, 224, 226), (222, 176, 150)),
    ("bag_lv", "L", "designerBags", "LOUIS VUITTON",
     (74, 44, 28), (184, 132, 92), (248, 236, 222), (216, 182, 132)),
    ("lehenga", "S", "eventWear", "SABYASACHI",
     (104, 16, 40), (212, 96, 120), (255, 232, 236), (230, 182, 152)),
    ("gown", "G", "partyWear", "EMERALD GOWN",
     (40, 18, 52), (132, 80, 150), (242, 228, 248), (198, 172, 212)),
    ("sherwani", "M", "eventWear", "BANDHGALA",
     (20, 30, 54), (92, 112, 156), (228, 235, 248), (172, 188, 216)),
    ("cricket_kit", "K", "sportsKits", "SG CRICKET",
     (16, 48, 40), (80, 134, 110), (224, 242, 234), (152, 198, 172)),
    ("golf_set", "P", "sportsKits", "CALLAWAY",
     (40, 52, 24), (120, 142, 82), (238, 244, 222), (188, 202, 152)),
    ("jewellery", "J", "jewellery", "KUNDAN",
     (78, 52, 10), (190, 148, 58), (252, 240, 212), (228, 198, 122)),
    ("watch", "R", "watches", "OMEGA",
     (26, 26, 30), (104, 100, 112), (236, 232, 240), (182, 178, 188)),
    ("clutch", "A", "accessories", "POTLI · CLUTCH",
     (84, 26, 20), (190, 104, 78), (252, 232, 222), (222, 170, 142)),
    ("party_dress", "N", "partyWear", "SHIMMER DRESS",
     (96, 14, 58), (202, 74, 124), (255, 230, 240), (230, 162, 192)),
    ("pashmina", "P", "accessories", "PASHMINA",
     (120, 96, 74), (206, 182, 156), (250, 242, 232), (222, 202, 174)),
    ("jhumka", "V", "jewellery", "POLKI JHUMKA",
     (84, 20, 16), (196, 120, 66), (252, 236, 214), (230, 192, 122)),
]

# --- gradient masks (built once; item-independent) ---------------------------
_MASKS = {}


def mask(kind):
    if kind in _MASKS:
        return _MASKS[kind]
    if kind == "v":
        base = Image.new("L", (1, 256))
        for i in range(256):
            base.putpixel((0, i), i)
        m = base.resize((W, H))
    elif kind in ("d", "d2"):
        s = 256
        base = Image.new("L", (s, s))
        px = base.load()
        for y in range(s):
            for x in range(s):
                xx = x if kind == "d" else (s - 1 - x)
                px[x, y] = int((xx + y) / (2 * (s - 1)) * 255)
        m = base.resize((W, H))
    elif kind == "r":
        m = Image.radial_gradient("L").resize((W, H))  # center 0, edge 255
    else:
        raise ValueError(kind)
    _MASKS[kind] = m
    return m


def wash(a, b, kind):
    """Two-tone gradient: mask 0 -> a, 255 -> b."""
    return Image.composite(
        Image.new("RGB", (W, H), b), Image.new("RGB", (W, H), a), mask(kind))


def vignette(img, strength=0.5):
    inv = ImageOps.invert(mask("r"))  # center 255, edge 0
    inv = inv.point(lambda v: int(255 * (1 - strength) + v * strength))
    return ImageChops.multiply(img, Image.merge("RGB", (inv, inv, inv)))


def grain(img, amount=0.045):
    n = Image.effect_noise((W, H), 18).convert("L")
    return Image.blend(img, Image.merge("RGB", (n, n, n)), amount)


def darker(c, f=0.72):
    return tuple(int(v * f) for v in c)


def lighter(c, f=0.22):
    return tuple(int(v + (255 - v) * f) for v in c)


# --- text / glyph helpers ----------------------------------------------------
def font(path, size):
    return ImageFont.truetype(path, size)


def glyph(d, cp, fnt, center, fill):
    ch = chr(cp)
    bb = d.textbbox((0, 0), ch, font=fnt)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    d.text((center[0] - tw / 2 - bb[0], center[1] - th / 2 - bb[1]),
           ch, font=fnt, fill=fill)


def mono(d, letter, fnt, center, ink, shadow=(0, 0, 0, 70)):
    bb = d.textbbox((0, 0), letter, font=fnt)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    x = center[0] - tw / 2 - bb[0]
    y = center[1] - th / 2 - bb[1]
    d.text((x + 5, y + 8), letter, font=fnt, fill=shadow)
    d.text((x, y), letter, font=fnt, fill=ink)


def spaced(d, center_x, y, text, fnt, fill, tracking):
    ws = [d.textlength(c, font=fnt) for c in text]
    total = sum(ws) + tracking * (len(text) - 1)
    x = center_x - total / 2
    for c, w in zip(text, ws):
        d.text((x, y), c, font=fnt, fill=fill)
        x += w + tracking
    return total


# --- the four frame templates ------------------------------------------------
def frame_cover(deep, mid, ink, accent, letter, cp, label):
    img = grain(vignette(wash(deep, mid, "d"), 0.42))
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([28, 28, W - 28, H - 28], outline=(*ink, 150), width=2)
    d.rectangle([37, 37, W - 37, H - 37], outline=(*ink, 55), width=1)
    mono(d, letter, font(SERIF, 380), (W / 2, H / 2 - 34), (*ink, 235))
    # icon chip, top-left
    cx, cy, r = 92, 92, 46
    d.ellipse([cx - r, cy - r, cx + r, cy + r],
              fill=(*darker(deep, 0.7), 210), outline=(*ink, 120), width=2)
    glyph(d, cp, font(ICON_FONT, 46), (cx, cy), (*ink, 230))
    spaced(d, W / 2, H - 108, "MANGWALO", font(SERIF, 33), (*ink, 180), 6)
    return img


def frame_icon(deep, mid, ink, accent, letter, cp, label):
    img = grain(vignette(wash(lighter(mid, 0.12), darker(deep, 0.85), "r"),
                         0.5))
    d = ImageDraw.Draw(img, "RGBA")
    ring = 226
    d.ellipse([W / 2 - ring, H / 2 - 70 - ring, W / 2 + ring, H / 2 - 70 + ring],
              outline=(*accent, 90), width=2)
    glyph(d, cp, font(ICON_FONT, 340), (W / 2, H / 2 - 70), (*ink, 235))
    spaced(d, W / 2, H / 2 + 232, label, font(SANS, 38), (*ink, 225), 8)
    spaced(d, W / 2, 70, "MANGWALO", font(SERIF, 24), (*ink, 130), 5)
    return img


def frame_editorial(deep, mid, ink, accent, letter, cp, label):
    img = grain(vignette(wash(lighter(mid, 0.06), darker(deep, 0.82), "v"),
                         0.46))
    d = ImageDraw.Draw(img, "RGBA")
    mono(d, letter, font(SERIF_BOLD, 300), (W / 2, H / 2 - 60), (*ink, 235))
    # gold rule + label, lower third
    ry = H - 214
    d.line([120, ry, W - 120, ry], fill=(*accent, 200), width=2)
    spaced(d, W / 2, ry + 34, label, font(SANS, 34), (*ink, 230), 7)
    glyph(d, cp, font(ICON_FONT, 58), (W - 96, 96), (*ink, 150))
    return img


def frame_tonal(deep, mid, ink, accent, letter, cp, label):
    img = grain(vignette(wash(darker(deep, 0.9), mid, "d2"), 0.54))
    d = ImageDraw.Draw(img, "RGBA")
    glyph(d, cp, font(ICON_FONT, 500), (W - 150, H - 210), (*ink, 34))
    mono(d, letter, font(SERIF, 210), (232, 268), (*ink, 230))
    # corner hairlines
    d.line([W - 150, 60, W - 60, 60], fill=(*accent, 200), width=2)
    d.line([W - 60, 60, W - 60, 150], fill=(*accent, 200), width=2)
    d.line([60, H - 60, 150, H - 60], fill=(*accent, 200), width=2)
    d.line([60, H - 150, 60, H - 60], fill=(*accent, 200), width=2)
    spaced(d, W / 2, H - 96, "SAMPLE · MANGWALO",
           font(SANS, 22), (*ink, 150), 4)
    return img


FRAMES = [
    ("", frame_cover),        # {name}.jpg
    ("_2", frame_icon),
    ("_3", frame_editorial),
    ("_4", frame_tonal),
]


def save(img, name):
    path = f"{OUT}/{name}.jpg"
    img.convert("RGB").save(path, "JPEG", quality=82, optimize=True)
    return os.path.getsize(path)


def main():
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for name, letter, cat, label, deep, mid, ink, accent in ITEMS:
        cp = ICON[cat]
        for suffix, builder in FRAMES:
            img = builder(deep, mid, ink, accent, letter, cp, label)
            total += save(img, f"{name}{suffix}")
        print(f"{name}: 4 frames")
    print(f"{len(ITEMS)} items x 4 = {len(ITEMS) * 4} images, "
          f"{total // 1024} KB total")


if __name__ == "__main__":
    main()
