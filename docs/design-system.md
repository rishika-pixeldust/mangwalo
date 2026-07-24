# MangWalo Design System — "Velvet Ledger"

> **How to use this doc:** paste the whole thing into any Claude (design or code)
> session **before** asking for new screens, components, or marketing assets.
> It is the single source of truth for how MangWalo looks and feels. Anything
> not specified here should be derived from these tokens — never invented ad hoc.

---

## 0. Paste-ready design brief (TL;DR for a new session)

```
You are designing for MangWalo, a local-first luxury-rental noticeboard —
designer bags, event & party wear, jewellery, watches, sports kits — for one
Mumbai neighborhood at a time.
Design language: "Velvet Ledger" — warm ivory canvas, near-white cards with
28px radii and soft wine-tinted shadows, one oxblood/burgundy accent with
blush containers, wine-black docked bottom nav with a burgundy rounded-square
center action. Typography pairs Playfair Display (serif display: wordmark,
page titles, card titles) with Plus Jakarta Sans (everything else); prices
are ExtraBold sans.
Generous whitespace, big touch targets (>=48px), icon+text for every state
(never color alone), light Hinglish personality in microcopy ("Maang lo!").
No pure black, no pure white, no gradients, no emoji glyphs (use Material
icons). Every screen must work in light AND dark, at 200% text scale.
```

---

## 1. Foundations

### 1.1 Color tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `canvas` | `#F6EFEA` | `#17100D` | Scaffold background |
| `surface` | `#FDF9F6` | `#221715` | Cards, sheets, inputs |
| `surfaceAlt` | `#F0E3DD` | `#2E1F1D` | Pressed/selected fills, meters |
| `ink` | `#2A171C` | `#F4EAE6` | Primary text, icons |
| `inkSoft` | `#8E7A80` | `#AD9599` | Secondary text, captions |
| `accent` | `#7E2231` | `#E8A0AB` | THE oxblood/blush: prices, active nav, eyebrows, highlights |
| `accentSoft` | `#F7DCDE` | `#4A222B` | Accent containers, chips-selected, badges |
| `night` | `#26141A` | `#100B09` | Bottom nav, primary CTA buttons |
| `onNight` | `#F7EFEA` | `#F7EFEA` | Text/icons on `night` |
| `gold` | `#7A5C00` on `#F1E2B0` | `#E9C96B` on `#4A3B0E` | Star ratings, privacy warnings (icon + text) |
| `danger` | `#B3261E` on `#F9DEDC` | `#F2B8B5` on `#4A1F1C` | Overdue, destructive, errors |

Rules: never pure `#000`/`#FFF`; body text contrast ≥ 4.5:1 in both themes;
the oxblood is an **accent**, not a fill for large areas — big surfaces stay ivory.

### 1.2 Typography — Playfair Display + Plus Jakarta Sans (bundled, OFL)

| Role | Weight / size / spacing | Example |
|---|---|---|
| Stat numeral / price | PJS ExtraBold 800 · 24–40 | "₹4,800" |
| Display / page title | Playfair Bold 700 · 26–32 | "Noticeboard" |
| Card title | Playfair SemiBold 600 · 19 | "Chanel Classic Flap bag" |
| Section label / eyebrow | PJS Bold 700 · 10.5–13 · +1.0 tracking, UPPERCASE | "FOR RENT" |
| Body | Regular 400 · 15–16 · 1.45 line height | descriptions |
| Label / chip / nav | Medium 500 · 13–14 | "Tools & Repair" |
| Caption / meta | Regular 400 · 12–13 in `inkSoft` | "02:30 PM · 35% of goal" |

Prices always PJS ExtraBold; units ("/day", "per day") drop to Medium at ~55% size. Serif never renders body text.

### 1.3 Shape

| Element | Radius |
|---|---|
| Cards, sheets, photo containers | **28** |
| Category tiles, thumbnails, FAB square | **20–22** |
| Inputs, small cards | **20** |
| Buttons, chips, search bar | **pill (999)** |
| Bottom nav container | **28 top corners** (docked) |

### 1.4 Elevation & shadows

One soft shadow only: `color: ink @ 8–10% opacity, blur 24–32, offset (0, 10)`.
Never stacked shadows, never hard edges. Dark theme: shadows off, use
`surfaceAlt` hairline borders (`1px, 8% onSurface`) instead.

### 1.5 Spacing & layout

4px base grid. Screen gutter **20**. Card padding **16–20**. Gap between cards
**14**. Section header → content gap **12**. Phone canvas 430 logical px,
centered max-width frame on desktop. Touch targets ≥ **48×48** always.

### 1.6 Iconography & imagery

Material Symbols (outlined) only — no emoji glyphs (they fetch remote fonts on
web and break offline). Item photos: rounded 20–22, `cover` fit, 52–64px as
card thumbnails, full-width ~220px heroes on detail. Category fallback tile:
`accentSoft` square + accent icon.

### 1.7 Motion & feel

Fast and calm: 200–250ms `easeOutCubic` for push/fade; no bouncing. Ken-Burns
style slow zoom acceptable for marketing only. Respect reduced-motion.

### 1.8 Voice

Professional microcopy with light Hinglish warmth at emotional moments only
(empty states, onboarding, success): "Maang lo — just ask.", "your padosi
will thank you." Never in errors, warnings, or destructive dialogs.

---

## 2. Component recipes

**Top bar** — no Material AppBar. Row: 44px white rounded-square icon button ·
centered Bold 18 title · 44px icon button (bell/settings). Transparent on canvas.

**Stat hero card** — `surface`, radius 28, padding 20. Big ExtraBold numeral +
`inkSoft` caption; optional segmented arc/meter: 10–12 rounded segments
(active `accent`, rest `surfaceAlt`), round caps.

**Listing card** — `surface`, radius 28. With photos: full-width 172px cover
(first photo), `night @ 82%` **₹/day price pill** overlaid bottom-left, photo
count chip top-right; below: FOR RENT/WANTED eyebrow → Playfair title 19 →
gold star row ("4.7 · 3 reviews") → category+landmark meta → badge pills.
Without photos: 56px `accentSoft` category tile left, bold ₹ price column
right ("₹1,200 / /day budget" on Wanted). Whole card = ONE merged semantics
node, button, with a composed label incl. price and rating.

**Category tile chip** — white rounded-20 tile, icon + Medium 13 label below/beside;
selected = `accentSoft` fill + `accent` icon. Horizontal scroll row.

**Search bar** — pill, `surface` fill, leading search icon, hint in `inkSoft`.

**Primary CTA** — full-width pill, `night` fill, `onNight` Medium 16 text,
height 56. Secondary: pill outline on surface. Destructive: `danger` text button.

**Segmented meter** — 10 rounded segments, `danger` → `accent` → `surfaceAlt`.

**Review tile** — `surface` radius 24: gold StarRow → body text → "— Name ·
date" caption. "Add a review" opens a bottom sheet: 5 tappable stars
(each a labeled semantics button), text, optional first name.

**Photo gallery (detail)** — 300px PageView, radius 28, dot indicators
(active dot stretches to 18px); each page announces "Photo N of M".

**Price block (detail)** — `surface` radius 24: ₹ rate ExtraBold 28+ in
`accent` + "per day", refundable deposit right-aligned.

**Bottom nav** — docked `night` container, top radius 28, 5 slots: 4 icon
destinations (active = `accent` icon in `accent @ 18%` rounded-square) +
center **burgundy rounded-square FAB (radius 20–22)**, half-docked over the
bar's top edge, for the primary action.
Labels optional; if omitted, semantics labels are mandatory.

**Badges** — pill, icon + text: state (`surfaceAlt`/ink), due-soon
(`accentSoft`/accent), overdue (`danger` container), sample (`surfaceAlt`).

**Privacy warning** — `warn` container, radius 16, shield icon + body text +
quoted match. Always `liveRegion: true`.

**Onboarding/hero** — full-bleed imagery or big canvas headline (Bold 30–34,
two lines), floating info tags (white pill, tiny shadow), page dots, `night` CTA.

---

## 3. Accessibility contract (non-negotiable)

1. Every interactive control: visible label or semantics label, ≥48px target.
2. Cards merge into one meaningful announcement; no fragment spam.
3. State never by color alone — pair icon + text (overdue = warning icon + "Overdue by N days").
4. Status/safety messages announce via live regions.
5. Both themes, 200% text scale, no horizontal overflow.

## 4. Don'ts

- No gradients, no glassmorphism, no pure black/white, no emoji as UI glyphs.
- Don't fill large areas with the accent oxblood; gold is only for stars/warnings.
- No third typeface (serif = display only). No shadow stacking. No color-only affordances.
- Don't invent new radii/spacing — compose from the tokens above.
