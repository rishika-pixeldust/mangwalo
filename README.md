# MangWalo — rent luxury from your locality

*Maang lo* — just ask. A hyperlocal noticeboard where neighbours in one Mumbai
locality rent luxury to each other: designer bags, event and party wear,
jewellery, watches and sports kits. Every listing carries a ₹/day rate, a photo
gallery, and reviews that speak to the item **and** the person.

Built for **MAL Lab 1: Flutter & Foundations**, and deployed as a real
installable PWA.

| | |
|---|---|
| 🌐 **Live** | **https://mangwalo.vercel.app** |
| 🎬 **Demo video** | [`docs/media/mangwalo-demo.mp4`](docs/media/mangwalo-demo.mp4) — narrated walkthrough of every required part |
| 🏷️ **Graded submission** | tag `lab1-submission` — the last fully local-first commit |
| 📄 **Voice script** | [`docs/voice-script.md`](docs/voice-script.md) |

Your neighbour owns the Chanel your reception outfit deserves. You own the
cricket kit their corporate weekend needs. MangWalo is the noticeboard in
between — "For rent" offers and "Wanted" requests, scoped to one locality.

---

## The six required parts, and where to find each

| # | Part | Implementation | Doc |
|---|---|---|---|
| **01** | **Product loop** | Browse one locality's board → open a listing → mark it **saved / contacted / closed** (`InteractionStatus`) → create a listing with title, category, description, landmark area and **contact preference**. Own feature: **return-date tracking** — overdue rentals badge themselves and sort to the top of the board | [`product-slice.md`](docs/product-slice.md) |
| **02** | **Accessibility** | One merged semantics node per card; labelled controls throughout; errors are icon + text, never colour alone; 48 px targets app-wide; survives 200% text scale; contrast measured for light + **three** dark themes | [`accessibility-check.md`](docs/accessibility-check.md) |
| **03** | **Security & privacy** | `PrivacyScanner` warns on phone numbers and addresses as you type; the area field **hard-rejects** them; sanitise-then-validate at the form *and* the repository; EXIF/GPS stripped from every photo on-device; one-tap reset of all local data; no secrets in the repo | [`security-baseline.md`](docs/security-baseline.md) |
| **04** | **Local AI** | Deterministic rule engine behind `LocalAiService`, suggesting title, category, sub-category, condition tags, rental window and ₹/day rate. Understands Hinglish, needs no model and no API key, and works with the network disabled | [`local-ai-note.md`](docs/local-ai-note.md) |
| **05** | **Architecture** | Feature-first `lib/src/`, one-way dependencies, local storage behind `ListingRepository`. That seam is the recorded change point — and it has since actually been used, swapping in a synced backend without the UI noticing | [`adr/0001-…`](docs/adr/0001-local-first-marketplace-slice.md) |
| **06** | **Documentation** | All six docs, plus a metrics table where every row is a check a reviewer can run | [`success-metrics.md`](docs/success-metrics.md) |

**Also here:** [`sample-data.md`](docs/sample-data.md) explains what the demo
board proves, [`design-system.md`](docs/design-system.md) documents the Velvet
Ledger palette and type, and [`product-roadmap.md`](docs/product-roadmap.md)
covers what a commercial version would still need.

---

## Setup and run

### Requirements

- **Flutter 3.44+** — check with `flutter --version`. If Flutter isn't on your
  `PATH`, use the full path to the binary.
- Chrome, for `-d chrome`.

### Run it — no credentials needed

```bash
flutter pub get
flutter run -d chrome
```

That is genuinely all. With no `.env` the app runs **entirely on-device**: the
board, the sample listings, on-device AI suggestions, the privacy scanner and
return-date tracking all work with no account and no network.

### Build the release bundle

```bash
flutter build web --release --no-web-resources-cdn
```

`--no-web-resources-cdn` bundles CanvasKit locally rather than fetching it from
gstatic, which keeps the app self-contained and offline-capable.

### Optional: the shared noticeboard

The app also runs against a Supabase backend — accounts, a shared board, and
bookings with double-booking made impossible at the database level. It is
**opt-in at build time** and fails closed to local-only mode, so a clone without
credentials still works.

The full walkthrough (project creation, migrations, redirect URLs, keys) is in
**[`SETUP.md`](SETUP.md)**.

```bash
cp .env.example .env        # then fill in your own values
flutter run -d chrome --dart-define-from-file=.env
```

> `.env` is gitignored. Only *public* values belong in it — the project URL and
> the **publishable** key, both of which ship inside the web bundle and are
> guarded by Row Level Security. Never the `service_role` or `sb_secret_…` key.

### Verify

```bash
flutter analyze     # expect: No issues found!
flutter test        # expect: All tests passed!   (153 tests)
```

### Regenerate the demo assets

```bash
python3 tool/make_seed_images.py                                    # sample imagery
flutter test tool/demo/capture_screens_test.dart --update-goldens    # app frames
./tool/demo/build_video.sh                                          # narrated video
```

The video takes its narration from any source — see
[`voice-script.md`](docs/voice-script.md) for the script and timings:

```bash
MANGWALO_VOICE="Rishi (Enhanced)" ./tool/demo/build_video.sh   # a better local voice
MANGWALO_NARRATION=external       ./tool/demo/build_video.sh   # your own recordings
MANGWALO_NARRATION=none           ./tool/demo/build_video.sh   # silent cut
```

---

## How it is put together

```
lib/src/
  core/          clock, money, validation (sanitizer, validators, privacy
                 scanner), images (downscale + EXIF strip), shared widgets, config
  theme/         Velvet Ledger — hand-mapped ColorSchemes, three dark variants
  features/
    listings/    domain (Listing, FeedFilter, DueInfo, DateRange)
                 data   (ListingRepository ← Hive | Supabase | in-memory)
                 application (Riverpod providers, form + suggestion controllers)
                 ui     (board, detail, form, cards, gallery)
    ai/          LocalAiService boundary + deterministic rule engine
    bookings/    date-range booking domain, source, availability calendar
    auth/        session state over Supabase auth
    settings/    preferences, profile, locality, themes
    onboarding/  concept intro + replayable coach-mark tour
supabase/migrations/   schema, RLS policies, storage buckets
docs/                  the six required docs, plus design and roadmap
tool/demo/             golden capture → slides → narrated video
```

**Dependency rule:** `ui → application → domain ← data`. Nothing outside
`*/data/` knows that Hive or Supabase exists — which is exactly what let the
storage layer be swapped for a synced backend with no change to the UI.

## Stack

Flutter web · Riverpod 3 · Hive CE (local) · Supabase (optional shared board) ·
deterministic on-device AI · no codegen · Playfair Display + Plus Jakarta Sans,
both bundled so nothing is fetched at runtime.
