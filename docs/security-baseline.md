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
| Contact details leaking into listings | Free-text "contact note" | **The field no longer exists.** The contact-channel picker and its free-text note were removed outright — the note was the field most likely to carry a phone number, and in-app messaging replaces both. Legacy values are dropped on read, never migrated | `listing_codec.dart` (v3), `listing_form_screen.dart` |
| Free-text sub-category abuse | "Others" category label | Capped at 30 chars and sanitised in the form **and again** in the codec and repository | `validators.dart`, `listing_codec.dart`, `hive_listing_repository.dart` |
| Photo metadata leakage | Item photos | Photos are decoded and re-encoded as JPEG on-device (EXIF — including GPS — is stripped by re-encoding), downscaled, and never leave local storage | `core/images.dart` |
| Secret leakage in the repo | API keys, tokens | None exist — the app makes no network calls. `.gitignore` blocks `*.env`, `*.pem`, `*.key` belt-and-braces. `grep -riE "api_key|secret|password" lib/` returns nothing | repo-wide |
| Sample data mistaken for real people | Demo listings | Every sample row is flagged `isDemo`, badged "Sample" in the UI, uses initials + common surnames, and contains **no digits** in contact fields | `seed_data.dart` |

## Trust layer (marketplace phase)

Once money and identity documents are involved the threat model changes: the
operator becomes a **Data Fiduciary** under India's DPDP Act 2023, and the most
sensitive data in the product is no longer a listing but a government ID.

| Threat | Vector | Mitigation | Where |
|---|---|---|---|
| Identity-document leak | KYC storage | The document is **never stored**. `verifications` holds only a status, a timestamp and an opaque provider reference, plus a low-entropy masked hint. A full dump of the table exposes no Aadhaar or PAN number | `0004_trust_layer.sql` |
| Self-declared verification | Client writing its own trust status | Client INSERT on `verifications` is denied outright; only the server (KYC webhook, service_role) may write. The public `user_trust` view exposes verified-or-not and nothing else | same |
| Transacting unverified | Skipping KYC | `may_transact()` gates the first transaction on each side — phone + government ID to rent, plus PAN to list, since payouts require it. Enforced just-in-time, so browsing stays open and the wall sits where the value is | same |
| Damage dispute with no evidence | Platform never sees the item | Both parties capture photos at handover and return and confirm each other's set. Photos, notes and phase are **immutable once written** (enforced by trigger, not convention), sealed sets reject all further writes, and deletion is denied. Timestamps are server-side — a client clock is not evidence | same |
| Counterfeit goods | Fake luxury item listed | Branded listings require a receipt or authenticity card, reviewed once. Liability shifts to the lister; `listing_authenticity` exposes only an approved/pending badge | same |
| Receipt / evidence exposure | Documents in a public bucket | Separate **private** `evidence` bucket (public read denied, per-user folders, write-once — no update or delete policy). Listing photos stay in the public bucket; receipts and condition photos never do | same |
| Retaliatory report editing | Reporter rewriting history | `reports` are insert-only for clients; no update, no retraction | same |

## What we deliberately do NOT protect against

- **Casual snooping on a shared device** — there is no app lock. An optional
  4–6 digit PIN (salted SHA-256) existed and was **removed**: it guarded a
  device, not an account, and once real authentication lands it would have been
  a second, weaker credential to explain and maintain. A shared-device user
  should use the browser profile / OS lock instead.
- **Device theft / local forensics** — data is not encrypted at rest; IndexedDB is
  readable by anyone with the unlocked device or browser profile. Acceptable for a
  noticeboard whose content is semi-public by nature; noted as future work
  (encrypted Hive box) if sensitive fields are ever added.
- **Other code on the same origin** — standard browser same-origin rules apply;
  deploying on a dedicated origin (Vercel) keeps the storage namespace isolated.
- **A malicious user lying in listings** — moderation is a phase-2 (shared backend)
  concern; in a single-device slice you can only mislead yourself.
