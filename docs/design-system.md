# MangWalo Design System — "Warm Ledger"

> **How to use this doc:** paste the whole thing into any Claude (design or code)
> session **before** asking for new screens, components, or marketing assets.
> It is the single source of truth for how MangWalo looks and feels. Anything
> not specified here should be derived from these tokens — never invented ad hoc.

---

## 0. Paste-ready design brief (TL;DR for a new session)

```
You are designing for MangWalo, a local-first neighborhood borrow-&-lend app.
Design language: "Warm Ledger" — warm cream canvas, near-white cards with
28px radii and soft brown-tinted shadows, one vibrant peach-orange accent,
charcoal ink, and a dark charcoal docked bottom nav with an orange
rounded-square center action. Typography is Plus Jakarta Sans: ExtraBold for
big stat numerals, Bold for headings, Medium for labels, Regular for body.
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
| `canvas` | `#F3EEE6` | `#171310` | Scaffold background |
| `surface` | `#FBF9F4` | `#221D18` | Cards, sheets, inputs |
| `surfaceAlt` | `#EFE8DD` | `#2B241E` | Pressed/selected fills, meters |
| `ink` | `#201B16` | `#F4EEE7` | Primary text, icons |
| `inkSoft` | `#8A8178` | `#A99E93` | Secondary text, captions |
| `accent` | `#F2793C` | `#F58B55` | THE orange: progress, active nav, highlights, small labels |
| `accentSoft` | `#FCE4D5` | `#4A2E1E` | Accent containers, chips-selected, badges |
| `night` | `#211D19` | `#100D0B` | Bottom nav, primary CTA buttons |
| `onNight` | `#F7F2EB` | `#F7F2EB` | Text/icons on `night` |
| `warn` | `#8A6D00` on `#F2E3AC` | `#F0D77B` on `#4A3E12` | Privacy warnings (icon + text) |
| `danger` | `#B3261E` on `#F9DEDC` | `#F2B8B5` on `#4A1F1C` | Overdue, destructive, errors |

Rules: never pure `#000`/`#FFF`; body text contrast ≥ 4.5:1 in both themes;
the orange is an **accent**, not a fill for large areas — big surfaces stay cream.

### 1.2 Typography — Plus Jakarta Sans (bundled, OFL)

| Role | Weight / size / spacing | Example |
|---|---|---|
| Stat numeral | ExtraBold 800 · 40–56 | "1250 kcal" → "3 items out" |
| Display / page title | Bold 700 · 28–32 | "Noticeboard" |
| Card title | Bold 700 · 18 | "Yonex Badminton Racket" |
| Section label / eyebrow | SemiBold 600 · 13 · +0.8 tracking, UPPERCASE optional | "TRENDING NEAR YOU" |
| Body | Regular 400 · 15–16 · 1.45 line height | descriptions |
| Label / chip / nav | Medium 500 · 13–14 | "Tools & Repair" |
| Caption / meta | Regular 400 · 12–13 in `inkSoft` | "02:30 PM · 35% of goal" |

Numerals in stats always ExtraBold; units ("kcal", "days") drop to Medium at ~55% size.

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

**Listing card ("meal card")** — `surface`, radius 28, padding 16. Row: 56px
rounded thumbnail (photo or category tile) → title Bold 18 + meta caption →
right column: **bold value** (e.g. "Due in 3d") + small orange caption
("35% of goal" slot). Chips/badges row above if stateful. Whole card = ONE
merged semantics node, button, with a composed label.

**Category tile chip** — white rounded-20 tile, icon + Medium 13 label below/beside;
selected = `accentSoft` fill + `accent` icon. Horizontal scroll row.

**Search bar** — pill, `surface` fill, leading search icon, hint in `inkSoft`.

**Primary CTA** — full-width pill, `night` fill, `onNight` Medium 16 text,
height 56. Secondary: pill outline on surface. Destructive: `danger` text button.

**Segmented meter** ("Easy ●●●○○") — 5 rounded 8×18 pills, active `accent`.

**Bottom nav** — docked `night` container, top radius 28, 5 slots: 4 icon
destinations (active = `accent` icon in `accent @ 18%` rounded-square) +
center **orange rounded-square FAB (radius 20–22)** for the primary action.
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
- Don't fill large areas with the accent orange; don't use more than one accent.
- No second typeface. No shadow stacking. No color-only affordances.
- Don't invent new radii/spacing — compose from the tokens above.
