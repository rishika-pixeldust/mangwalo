#!/usr/bin/env python3
"""Compose 1920x1080 demo-video slides from the golden app frames."""
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONTS = "/Users/rishika/Documents/development/flutter/bin/cache/artifacts/material_fonts"
GOLD = "tool/demo/goldens"
OUT = "tool/demo/slides"

CREAM = (255, 248, 243)
TERRA = (184, 74, 38)
TERRA_SOFT = (232, 201, 188)
INK = (42, 26, 18)
INK_SOFT = (110, 84, 70)

heading_f = ImageFont.truetype(f"{FONTS}/Roboto-Bold.ttf", 78)
eyebrow_f = ImageFont.truetype(f"{FONTS}/Roboto-Medium.ttf", 30)
bullet_f = ImageFont.truetype(f"{FONTS}/Roboto-Regular.ttf", 36)
small_f = ImageFont.truetype(f"{FONTS}/Roboto-Medium.ttf", 26)
brand_f = ImageFont.truetype(f"{FONTS}/Roboto-Bold.ttf", 130)
tag_f = ImageFont.truetype(f"{FONTS}/Roboto-Light.ttf", 44)


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def shadow_paste(canvas: Image.Image, card: Image.Image, xy):
    x, y = xy
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.rounded_rectangle([x + 10, y + 18, x + card.width + 10, y + card.height + 18],
                         48, fill=(90, 45, 25, 70))
    sh = sh.filter(ImageFilter.GaussianBlur(22))
    canvas.alpha_composite(sh)
    canvas.alpha_composite(card, (x, y))


def phone_card(path: str, height: int, crop=None) -> Image.Image:
    img = Image.open(path)
    if crop:
        img = img.crop(crop)
    w = int(img.width * height / img.height)
    img = img.resize((w, height), Image.LANCZOS)
    img = rounded(img, 44)
    framed = Image.new("RGBA", (w + 12, height + 12), (0, 0, 0, 0))
    fd = ImageDraw.Draw(framed)
    fd.rounded_rectangle([0, 0, w + 11, height + 11], 50, fill=TERRA_SOFT)
    framed.alpha_composite(img, (6, 6))
    return framed


def base_canvas() -> Image.Image:
    c = Image.new("RGBA", (1920, 1080), CREAM + (255,))
    d = ImageDraw.Draw(c)
    d.ellipse([1500, -350, 2350, 500], fill=(247, 228, 219, 255))
    d.ellipse([-260, 760, 420, 1440], fill=(250, 236, 228, 255))
    d.text((110, 1006), "mangwalo.vercel.app", font=small_f, fill=TERRA)
    return c


def spaced(text: str) -> str:
    return " ".join(text)


def text_column(d: ImageDraw.ImageDraw, eyebrow, heading, bullets, top=200):
    d.text((110, top), spaced(eyebrow), font=eyebrow_f, fill=TERRA)
    y = top + 62
    for line in heading:
        d.text((104, y), line, font=heading_f, fill=INK)
        y += 92
    y += 36
    for b in bullets:
        d.ellipse([116, y + 17, 132, y + 33], fill=TERRA)
        d.text((156, y), b, font=bullet_f, fill=INK_SOFT)
        y += 62


def save(c: Image.Image, name: str):
    c.convert("RGB").save(f"{OUT}/{name}.png")
    print("wrote", name)


import os
os.makedirs(OUT, exist_ok=True)

# S0 — intro
c = base_canvas()
d = ImageDraw.Draw(c)
d.text((110, 250), spaced("MAL LAB 1 · FLUTTER & FOUNDATIONS"), font=eyebrow_f, fill=TERRA)
d.text((100, 320), "MangWalo", font=brand_f, fill=TERRA)
d.text((108, 480), "Maang lo — just ask.", font=tag_f, fill=INK)
for i, b in enumerate([
    "Local-first borrow & lend noticeboard",
    "One Mumbai neighborhood per board",
    "Flutter web PWA — everything stays on-device",
    "Live at mangwalo.vercel.app",
]):
    y = 590 + i * 62
    d.ellipse([116, y + 17, 132, y + 33], fill=TERRA)
    d.text((156, y), b, font=bullet_f, fill=INK_SOFT)
p1 = phone_card(f"{GOLD}/01_onboarding.png", 860)
p2 = phone_card(f"{GOLD}/02_feed.png", 860)
shadow_paste(c, p1, (1000, 110))
shadow_paste(c, p2, (1450, 110))
save(c, "s0_intro")

# S1 — product thinking
c = base_canvas()
d = ImageDraw.Draw(c)
text_column(d, "01 · PRODUCT THINKING", ["One sharp slice,", "shipped."], [
    "Offers and requests on one noticeboard",
    "My-items view with a lending summary",
    "Return-date tracking — overdue jumps the queue",
    "Borrower names, due badges, status lifecycle",
])
p1 = phone_card(f"{GOLD}/03_myitems.png", 860)
p2 = phone_card(f"{GOLD}/06_detail_lending.png", 860)
shadow_paste(c, p1, (1000, 110))
shadow_paste(c, p2, (1450, 110))
save(c, "s1_product")

# S2 — accessibility
c = base_canvas()
d = ImageDraw.Draw(c)
text_column(d, "02 · ACCESSIBILITY", ["Usable by every", "neighbor."], [
    "One meaningful announcement per card",
    "Errors are icon + text, never color-only",
    "48-pixel touch targets everywhere",
    "Survives 200% text scaling",
])
p1 = phone_card(f"{GOLD}/07_a11y_scale.png", 940)
shadow_paste(c, p1, (1280, 70))
save(c, "s2_a11y")

# S3 — local AI (cropped to description + suggestions)
c = base_canvas()
d = ImageDraw.Draw(c)
text_column(d, "03 · LOCAL AI", ["On-device", "intelligence."], [
    "Deterministic rules engine — no cloud, no keys",
    "Understands Hinglish descriptions",
    "Suggests title, category, tags & duration",
    "Swappable LocalAiService boundary",
])
p1 = phone_card(f"{GOLD}/04_ai_suggestions.png", 940, crop=(0, 400, 1290, 1870))
shadow_paste(c, p1, (1150, 70))
save(c, "s3_ai")

# S4 — security
c = base_canvas()
d = ImageDraw.Draw(c)
text_column(d, "04 · SECURITY", ["Private by", "design."], [
    "Phone & address detection as you type",
    "Landmark-only locations, hard-enforced",
    "Photos re-encoded — EXIF & GPS stripped",
    "One-tap reset of all local data",
])
p1 = phone_card(f"{GOLD}/05_privacy_warning.png", 940, crop=(0, 400, 1290, 1920))
shadow_paste(c, p1, (1090, 70))
p2 = phone_card(f"{GOLD}/08_settings.png", 560)
shadow_paste(c, p2, (1600, 450))
save(c, "s4_security")

# S5 — outro
c = base_canvas()
d = ImageDraw.Draw(c)
d.text((110, 300), spaced("BUILT FOR MAL LAB 1 · GOING LIVE ANYWAY"), font=eyebrow_f, fill=TERRA)
d.text((100, 370), "MangWalo", font=brand_f, fill=TERRA)
d.text((108, 530), "Product thinking · Accessibility · Local AI · Security",
       font=tag_f, fill=INK)
for i, b in enumerate([
    "mangwalo.vercel.app",
    "github.com/rishika-pixeldust/mangwalo",
    "Maang lo — your neighborhood lends a hand.",
]):
    y = 640 + i * 62
    d.ellipse([116, y + 17, 132, y + 33], fill=TERRA)
    d.text((156, y), b, font=bullet_f, fill=INK_SOFT)
p1 = phone_card(f"{GOLD}/02_feed.png", 860)
shadow_paste(c, p1, (1330, 110))
save(c, "s5_outro")
