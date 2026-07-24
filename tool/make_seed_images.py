#!/usr/bin/env python3
"""Generate the bundled sample-listing imagery (assets/seed/*.jpg).

Elegant abstract placeholders — soft duotone gradients in the Velvet Ledger
palette with a serif monogram and a hairline frame. Clearly illustrative,
no real product photography, tiny footprint.
"""
import os

from PIL import Image, ImageDraw, ImageFont

W, H = 720, 900
FONT = "assets/fonts/PlayfairDisplay-SemiBold.ttf"
OUT = "assets/seed"

# (name, monogram, top RGB, bottom RGB, ink RGB)
CARDS = [
    ("bag_chanel", "C", (61, 17, 26), (154, 63, 79), (247, 220, 222)),
    ("bag_lv", "L", (88, 48, 34), (189, 132, 96), (246, 233, 220)),
    ("lehenga", "S", (122, 22, 44), (219, 112, 134), (255, 236, 238)),
    ("gown", "G", (44, 20, 52), (137, 84, 155), (243, 228, 248)),
    ("sherwani", "M", (24, 34, 56), (98, 118, 160), (228, 235, 248)),
    ("party_dress", "N", (105, 16, 62), (206, 78, 128), (255, 230, 240)),
    ("cricket_kit", "K", (18, 52, 42), (86, 140, 116), (224, 242, 234)),
    ("golf_set", "P", (46, 58, 26), (128, 148, 88), (238, 244, 222)),
    ("jewellery", "J", (94, 62, 12), (196, 152, 62), (252, 240, 212)),
    ("watch", "R", (30, 28, 32), (110, 104, 116), (236, 232, 240)),
    ("clutch", "A", (96, 30, 22), (198, 110, 84), (252, 232, 222)),
]


def make(name, letter, top, bottom, ink):
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        # Ease the blend so the top tone holds longer — feels richer.
        t = t * t * (3 - 2 * t)
        for x in range(W):
            # Gentle diagonal bias.
            tx = min(1.0, max(0.0, t + (x / W - 0.5) * 0.12))
            px[x, y] = tuple(
                round(a + (b - a) * tx) for a, b in zip(top, bottom))

    d = ImageDraw.Draw(img, "RGBA")
    # Hairline frame.
    d.rectangle([28, 28, W - 28, H - 28], outline=(*ink, 140), width=2)
    d.rectangle([36, 36, W - 36, H - 36], outline=(*ink, 60), width=1)
    # Monogram.
    mono = ImageFont.truetype(FONT, 380)
    bbox = d.textbbox((0, 0), letter, font=mono)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((W - tw) / 2 - bbox[0], (H - th) / 2 - bbox[1] - 30), letter,
           font=mono, fill=(*ink, 200))
    # Caption.
    cap = ImageFont.truetype(FONT, 34)
    text = "MANGWALO"
    bbox = d.textbbox((0, 0), text, font=cap)
    d.text(((W - (bbox[2] - bbox[0])) / 2, H - 110), text, font=cap,
           fill=(*ink, 170))

    img.save(f"{OUT}/{name}.jpg", "JPEG", quality=80)
    print(name, os.path.getsize(f"{OUT}/{name}.jpg") // 1024, "KB")


os.makedirs(OUT, exist_ok=True)
for card in CARDS:
    make(*card)
