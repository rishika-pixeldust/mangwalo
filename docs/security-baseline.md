# Security baseline — MangWalo

## Data model & trust boundary

Everything lives on-device (Hive CE over IndexedDB). There is no network I/O after
asset load, no account, and no telemetry. The relevant "attacker" is therefore not a
network adversary but **data leakage through careless input** (a user publishing
their own phone number or exact address into a listing that could later be shared or
synced) and **stale personal data** accumulating on a shared device.

## Threat / mitigation table

| Threat | Vector | Mitigation | Where in code |
|---|---|---|---|
| Exact home address disclosure | User types flat/wing/floor/PIN into description or area | Deterministic `PrivacyScanner`: strong signals (unit numbers, Mumbai PINs, phone numbers) warn alone; weak signals (wing-unit shorthand, floor, society vocabulary) warn in combination. The **area field hard-rejects** address patterns and digit-heavy input — landmark only | `lib/src/core/validation/privacy_scanner.dart`, `validators.dart` |
| Phone number in free text | User types a number into the description | Inline warning with the matched text shown, steering contact info to the structured contact field | same |
| Precise live location exposure | — | No geolocation permission is requested anywhere; location is a free-text landmark | (absence by design) |
| Oversized / malformed input | Paste bombs, control characters | Length-capped validators + `sanitize()` (trim, collapse whitespace, strip control chars) applied in the form layer **and again in the repository** — defense in depth | `sanitizer.dart`, `hive_listing_repository.dart` |
| Corrupted stored rows | Schema drift, partial writes | Versioned, tolerant JSON codec: missing keys get defaults, undecodable rows are skipped (never crash the feed), invariant violations are repaired on load | `listing_codec.dart` |
| Stale personal data on device | Shared/family device | **Reset all local data** (confirm dialog) wipes listings, settings, and in-memory filter state, returning to onboarding; sample data removable separately | `settings_controller.dart` |
| Over-collection of borrower identity | Lending flow | Borrower field is a single optional **first name only** (30 chars), stored locally, cleared automatically on return | `lend_out_dialog.dart`, `listing.dart` |
| Photo metadata leakage | Item photos | Photos are decoded and re-encoded as JPEG on-device (EXIF — including GPS — is stripped by re-encoding), downscaled, and never leave local storage | `core/images.dart` |
| Secret leakage in the repo | API keys, tokens | None exist — the app makes no network calls. `.gitignore` blocks `*.env`, `*.pem`, `*.key` belt-and-braces. `grep -riE "api_key|secret|password" lib/` returns nothing | repo-wide |
| Sample data mistaken for real people | Demo listings | Every sample row is flagged `isDemo`, badged "Sample" in the UI, uses initials + common surnames, and contains **no digits** in contact fields | `seed_data.dart` |

## What we deliberately do NOT protect against

- **Device theft / local forensics** — data is not encrypted at rest; IndexedDB is
  readable by anyone with the unlocked device or browser profile. Acceptable for a
  noticeboard whose content is semi-public by nature; noted as future work
  (encrypted Hive box) if sensitive fields are ever added.
- **Other code on the same origin** — standard browser same-origin rules apply;
  deploying on a dedicated origin (Vercel) keeps the storage namespace isolated.
- **A malicious user lying in listings** — moderation is a phase-2 (shared backend)
  concern; in a single-device slice you can only mislead yourself.
