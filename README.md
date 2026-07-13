# MangWalo

> **Maang lo** — just ask for it. A local-first noticeboard to **borrow and lend everyday
> things within one Mumbai neighborhood**, with an on-device AI listing helper.
> Built for **MAL Lab 1: Flutter & Foundations**.

Your neighbor owns the drill you need twice a year. You own the pressure cooker they
need for one festival week. MangWalo is the noticeboard in between — offers ("I can
lend") and requests ("I need"), scoped to a single neighborhood, stored entirely on
your device.

## Feature tour

- **Onboarding** — pick your neighborhood once (single-neighborhood scope); a
  clearly-marked sample noticeboard loads automatically so the first feed is never
  empty (removable in Settings).
- **Feed** — browse offers and requests with category emoji and optional item photos;
  filter by type and category; search titles, descriptions, and landmarks; overdue
  loans float to the top.
- **My items view** — a Noticeboard / My-items split with a lending summary strip
  ("You've lent 2 items · 1 overdue") for managing what you've put on the board.
- **Create with an on-device AI helper** — describe the item ("bosch ka drill machine,
  thoda purana but works fine") and a deterministic rule engine suggests a title,
  category, condition tags, and a fair lending duration. Suggestions are chips you tap
  to accept — nothing is ever auto-filled.
- **Privacy guardrails** — typing a phone number or an exact address into free text
  triggers a visible warning; the area field hard-enforces landmark-only locations.
- **Status lifecycle** — saved → contacted → closed, independent of the item's
  lending state (available → lent out → returned).
- **Return-date tracking** *(the personal product feature)* — mark an item lent out
  with a borrower first name and an expected return date; the feed and detail views
  show "Due in N days" and overdue badges, with overdue items sorted first.
- **Photos on listings** — attach an item photo; it is downscaled, re-encoded, and
  stored only on the device.
- **Full local data control** — load/remove sample data, and "Reset all local data"
  wipes everything.

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44 (stable) / Dart 3.12 — web target, phone-frame layout on desktop |
| State | Riverpod 3 |
| Persistence | Hive CE (IndexedDB on web) behind a `ListingRepository` interface |
| Local AI | Deterministic rule engine behind a `LocalAiService` interface — no model, no network, no hosted APIs |
| Design | Material 3, warm terracotta theme, light + dark |

## Getting started

Prerequisites: [Flutter](https://docs.flutter.dev/get-started/install) 3.44+ with web
support and Chrome.

```sh
flutter pub get

# Run in debug (fixed port keeps IndexedDB data stable across relaunches)
flutter run -d chrome --web-port=8080

# Tests (59 tests: AI engine, validators, due-date math, codec, Hive repo, widgets)
flutter test

# Static analysis
flutter analyze

# Production build (CanvasKit bundled locally — no CDN dependency)
flutter build web --release --no-web-resources-cdn   # output in build/web
```

## Architecture at a glance

```
UI (screens, widgets)
  │  watches
Riverpod providers (feed filter, suggestions, settings)
  │  reads through interfaces
  ├── ListingRepository ──► HiveListingRepository (JSON codec → Hive CE / IndexedDB)
  │                         InMemoryListingRepository (tests + storage fallback)
  └── LocalAiService  ──► RuleBasedListingAi (deterministic, offline)
```

- Feature-first layout under `lib/src/features/` with `domain / data / application / ui`
  boundaries; Hive is imported only by the `data/` layer and the `main.dart`
  bootstrap that opens the boxes and injects the repositories.
- The two seams — storage and AI — are the recorded **change points**: a synced
  backend (phase 2) and an on-device model can each be swapped in one line.
- Decisions and alternatives: see the ADR below.

## Documentation

| Doc | What it covers |
|---|---|
| [Product slice](docs/product-slice.md) | Problem, target user, in/out of scope |
| [Success metrics](docs/success-metrics.md) | Testable pass/fail metrics, incl. the return-date metric |
| [Accessibility check](docs/accessibility-check.md) | Checklist with how-tested evidence |
| [Security baseline](docs/security-baseline.md) | Threat/mitigation table, data minimization |
| [Local AI note](docs/local-ai-note.md) | Helper type, boundary, fallback, honest limitations |
| [ADR-0001](docs/adr/0001-local-first-marketplace-slice.md) | Local-first architecture decision record |
| [Demo script](docs/demo-script.md) | Timed 3-minute demo walkthrough |

## Non-goals & honesty notes

- **No backend, no accounts, no sync** — this slice is deliberately single-device.
  Listings are visible only on the device that created them; a synced backend is the
  documented phase-2 change point behind `ListingRepository`.
- **The "AI" is a deterministic rule engine** — keyword dictionaries tuned to the
  Mumbai borrow-lend domain (Hinglish included), not a machine-learning model. That is
  exactly what makes it private, offline, and predictable; the `LocalAiService`
  interface is where a real on-device model would plug in.
- **Sample data is fake** — every sample listing is flagged, uses initials + common
  surnames, and contains no real contact details.
