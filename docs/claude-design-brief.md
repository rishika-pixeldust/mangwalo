# MangWalo — Complete Design Brief for Claude

> **Purpose:** paste this ENTIRE file into a Claude (design, Figma, or code)
> session before asking it to design anything for MangWalo — a single screen,
> the whole app, marketing assets, or an App Store listing. It contains the
> product context, information architecture, every screen with its states,
> and the full "Warm Ledger" design system. Nothing else is needed.

---

## 1. Product context (read before designing)

**MangWalo** ("maang lo" — *just ask*) is a **local-first borrow & lend
noticeboard for one Mumbai neighborhood at a time**. Residents post **offers**
("I can lend a drill") and **requests** ("I need a ladder for one afternoon"),
browse the board, and track lending with return dates. Everything lives
on-device: no account, no server, no tracking. An on-device deterministic AI
helper drafts listings from free text (Hinglish welcome).

- **Audience:** residents of housing-society-dense Mumbai neighborhoods
  (Bandra West, Powai, …). Mixed ages, mixed tech comfort, phones first.
- **Personality:** a warm, trustworthy neighborhood noticeboard. Professional
  microcopy with light Hinglish accents at emotional moments only ("Maang lo!",
  "your padosi will thank you") — never in errors or destructive dialogs.
- **Four non-negotiable product pillars** (it's graded and shipped on these):
  1. **Product thinking** — one sharp slice; return-date tracking is the
     hero feature (who borrowed what, due when, overdue-first sorting).
  2. **Accessibility** — screen-reader-first cards, icon+text states,
     48px targets, 200% text-scale safe, both themes.
  3. **Local AI** — on-device suggestions, visibly disclosed
     ("generated on-device · works offline"), never auto-applies.
  4. **Security/privacy** — data minimization: landmark-only locations,
     phone/address detection warnings, EXIF-stripped photos, one-tap reset.

**Tech reality (design within it):** Flutter (Material 3) web PWA at 430px
logical width, also Android-ready. Material Symbols only — **no emoji glyphs**
(they fetch remote fonts and break offline). Photos are user-supplied,
square-croppable thumbnails.

## 2. Information architecture

```
Onboarding (first launch only)
Home shell — dark docked bottom nav:
├── Board        (all listings in the neighborhood)
├── My items     (only mine + lending hero card)
├── [ + ]        (center orange square → New listing)
└── Settings     (neighborhood, theme, sample data, reset, about)
Pushed routes: Listing detail · New/Edit listing form · Lend-out dialog
```

## 3. Screens & states (design every listed state)

**Onboarding** — brand mark + "Maang lo — just ask." · neighborhood radio
tiles (8 fixed options) · note that sample listings auto-load · `night` CTA
"Get started" (disabled until selection).

**Board (feed)** — page title + "‹neighborhood› · maang lo, just ask" caption ·
search pill · type filter (All / Offers / Requests) · category chip row
(11 categories) · listing cards. States: loaded · empty-fresh ("Your
noticeboard is waiting" + load samples) · empty-filtered ("No matches" +
clear filters) · storage-failure banner (error container, icon + text).

**Listing card** — thumbnail (photo or category tile) · orange OFFER/REQUEST
eyebrow · Bold title · 1–2 line description · category + landmark meta row ·
right-hand bold due column when lent ("3d / until return", "7d / overdue" in
danger, "Today") · pill badges only for sample/status/lending state. The whole
card is ONE semantics node.

**My items** — same layout as Board plus a **hero stat card** above the list:
ExtraBold "N of M items out", caption "all on track" (accent) or "2 overdue ·
1 on track" (danger), and a 10-segment rounded meter (danger → accent →
surface-alt). Empty state: "Nothing of yours here yet — …your padosi will
thank you."

**Listing detail** — optional photo hero (radius 28) · badge row · Bold title +
full description · condition tag chips · info card (category, landmark,
neighborhood, contact, posted, borrowed-by, return-by) · status segmented
control (Saved / Contacted / Closed) · lending actions: `night` CTA "Mark as
lent out" ⇄ "Mark as returned" + outline "Update lending details" · edit /
delete in the top bar (delete confirms).

**New/Edit listing form** — type toggle (I can lend / I need) · description
(multiline, drives AI) · **Suggestions panel**: sparkle chips for title,
category, condition tags, duration + disclosure line "Suggestions are
generated on-device and work offline. Nothing you type leaves this device."
Chips apply on tap, never auto-overwrite, show applied state with a check ·
title, category dropdown, landmark field ("Landmark only — never an exact
address"), contact-via dropdown + optional note ("Stored only on this
device.") · photo picker ("Downscaled and stored only on this device.") ·
`night` CTA "Add to noticeboard". States: pristine · suggestions present ·
**privacy warning** (warn container, shield icon, quotes the matched text,
non-blocking) · validation errors (helper text under fields) · edit mode
(prefilled, re-scanned).

**Lend-out dialog** — borrower first-name field (optional, "First name is
enough", "Stored only on this device.") · return-by date button pre-filled
with the AI-suggested duration · Cancel / "Mark lent out".

**Settings** — neighborhood dropdown · appearance (Light / Auto / Dark) ·
"Remove sample listings" / "Load sample listings" · **"Reset all local data"**
(danger, confirm dialog: "This cannot be undone") · About card (tagline, AI
engine disclosure, "Built for MAL Lab 1").

---

## 4. Design system — "Warm Ledger"

### 4.1 One-paragraph brief

Warm cream canvas, near-white cards with 28px radii and soft brown-tinted
shadows, ONE vibrant peach-orange accent, charcoal ink, and a dark charcoal
docked bottom nav with an orange rounded-square center action. Typography is
**Plus Jakarta Sans**: ExtraBold stat numerals, Bold headings, Medium labels,
Regular body. Generous whitespace, ≥48px targets, icon+text for every state
(never color alone). No pure black/white, no gradients, no emoji glyphs, no
second typeface, no second accent.

### 4.2 Color tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `canvas` | `#F3EEE6` | `#171310` | Screen background |
| `surface` | `#FBF9F4` | `#221D18` | Cards, sheets, inputs |
| `surfaceAlt` | `#EFE8DD` | `#2B241E` | Selected fills, meters, subtle chips |
| `ink` | `#201B16` | `#F4EEE7` | Primary text & icons |
| `inkSoft` | `#8A8178` | `#A99E93` | Secondary text, captions |
| `accent` | `#F2793C` | `#F58B55` | Progress, active nav, eyebrows, highlights |
| `accentSoft` | `#FCE4D5` | `#4A2E1E` | Accent containers, selected chips |
| `night` | `#211D19` | `#100D0B` | Bottom nav, primary CTA pills |
| `onNight` | `#F7F2EB` | `#F7F2EB` | Content on `night` |
| `warn` | `#4A3E12` on `#F2E3AC` | `#F6EAC0` on `#4A3E12` | Privacy warnings |
| `danger` | `#B3261E` / `#F9DEDC` | `#F2B8B5` / `#4A1F1C` | Overdue, destructive |

Body-text contrast ≥ 4.5:1 both themes. Accent is never a large-area fill.

### 4.3 Typography — Plus Jakarta Sans (OFL, bundled)

| Role | Spec |
|---|---|
| Stat numeral | ExtraBold 800 · 34–56 (units drop to Medium at ~55%) |
| Page title | ExtraBold 800 · 24–28 |
| Card title | Bold 700 · 17–18 · line-height 1.15 |
| Eyebrow | Bold 700 · 10.5–13 · +0.8 tracking · UPPERCASE · accent color |
| Body | Regular 400 · 15–16 · line-height 1.45 |
| Label / chip / nav | Medium–SemiBold · 13–14 |
| Caption / meta | Regular 400 · 12–13 · `inkSoft` |

### 4.4 Shape · elevation · spacing

Radii: cards/dialogs/photos **28** · tiles/thumbnails/FAB square **20–22** ·
inputs **20** · buttons/chips/search **pill** · nav top corners **28**.
Shadow (light only): ink @ 8–10%, blur 24–32, offset (0,10), never stacked;
dark theme uses 1px `surfaceAlt`-tone hairline borders instead.
Spacing: 4px grid · screen gutter 20 · card padding 16–20 · card gap 14 ·
touch targets ≥ 48×48. Phone canvas 430px, centered frame on desktop.

### 4.5 Component recipes

- **Top bar:** no Material AppBar on tabs — Bold page title + caption line,
  optional 44px `surface` rounded-square icon badge on the right.
- **Stat hero card:** `surface` 28 · big numeral + caption · segmented meter
  (10 rounded segments: danger → accent → surfaceAlt).
- **Listing card:** thumbnail 56 (photo radius 18 or `accentSoft` category
  tile) · eyebrow + title + description · right bold value column
  (accent, or danger when attention) · meta icons row · badge pills.
- **Category tile:** `accentSoft` rounded-20 square + accent-dark icon.
- **Primary CTA:** full-width pill, `night`/`onNight`, height 56.
  Secondary: outline pill. Destructive: danger text/outline.
- **Bottom nav:** docked `night` slab, top radius 28 · icon+label items
  (active = accent icon in accent@18% rounded chip) · center 58px orange
  rounded-square (radius 20) for the ONE primary action.
- **Badges:** pill, icon + text — state `surfaceAlt`, due-soon `accentSoft`,
  overdue danger container, sample `surfaceAlt`.
- **Privacy warning:** warn container, radius 16, shield icon, quotes the
  matched text, `liveRegion: true`.
- **Dialogs / date picker:** `surface`, radius 28, pill actions.

### 4.6 Accessibility contract (non-negotiable)

1. Every control: label + ≥48px target. 2. Cards = one merged, meaningful
announcement. 3. State never by color alone (icon + text). 4. Safety/status
messages announce via live regions. 5. Both themes, 200% text scale, no
horizontal overflow.

### 4.7 Don'ts

No gradients · no glassmorphism · no pure `#000`/`#FFF` · no emoji glyphs ·
no second typeface or accent · no large orange fills · no invented
radii/spacing · no color-only affordances · no Hinglish in errors.

---

## 5. How to use this brief

- "Design screen X" → find it in §3, build it with §4 tokens, cover every
  listed state, respect §4.6.
- "Design a new feature" → keep the IA of §2; the new surface must earn its
  place without adding a second accent or nav pattern.
- Reference implementation lives at
  github.com/rishika-pixeldust/mangwalo (Flutter, `lib/src/theme/app_theme.dart`
  is the token source of truth) and mangwalo.vercel.app.
