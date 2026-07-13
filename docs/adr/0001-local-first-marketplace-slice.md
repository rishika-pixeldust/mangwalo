# ADR-0001: Local-first marketplace slice

- **Status:** Accepted
- **Date:** 2026-07-13
- **Context:** MAL Lab 1 homework; MangWalo is also intended to go live as a real
  product, so this slice must be production-quality and evolvable.

## Context

We need the first usable slice of a hyperlocal borrow-and-lend marketplace for one
Mumbai neighborhood, demoable in 3 minutes, with visible architecture boundaries,
working accessibility and security, and a local AI helper that must function without
any hosted API. The slice ships as a Flutter web app (installable PWA) but must stay
compilable to Android/iOS from the same codebase.

## Decision

Build a **local-first, single-device** app:

1. **All data on-device.** Listings and settings persist in Hive CE (IndexedDB on
   web) as versioned JSON blobs behind repository interfaces
   (`ListingRepository`, `SettingsRepository`). No backend, no accounts, no network
   I/O after asset load.
2. **Hand-written JSON codec, no codegen.** A `schemaVersion` field plus tolerant
   decoding (defaults for missing keys, skip undecodable rows, repair invariant
   violations) makes schema evolution and the future sync migration cheap.
3. **Riverpod dependency graph.** Repositories and the AI service are injected as
   providers, overridden at bootstrap — the same seams serve tests (in-memory
   doubles) and the runtime storage-failure fallback.
4. **Deterministic on-device AI behind `LocalAiService`.** The rule engine is both
   the primary implementation and the permanent fallback; the interface contract
   (async, no network, never throws) is what makes a future model swap safe.
5. **Privacy by structure.** Location is landmark-level free text (validated), the
   contact field is a preset channel + short note, and a deterministic privacy
   scanner warns on phone/address patterns in free text.

## Alternatives considered

| Alternative | Why rejected (for this slice) |
|---|---|
| Firebase/Supabase backend from day one | Violates the homework's local-first constraint; drags in auth, moderation, and PII handling before the product loop is proven. It is the *planned phase 2*, not the starting point. |
| `shared_preferences` + one JSON blob | No per-row writes or watching; whole-list rewrites on every edit; weakest architecture story. |
| `drift`/sqlite (WASM on web) | Real queries and types, but meaningful web setup friction (worker + WASM assets) for a dataset of tens of rows. Hive CE + a codec delivers the same boundary with less risk. |
| Hive TypeAdapters (codegen) | `build_runner` + typeId registry for one small entity; the dynamic-map pitfalls on web outweigh the type safety. |
| Hosted LLM for the listing helper | Needs a network and an API key — both explicitly banned; also leaks listing text off-device. |
| `go_router` | Five screens, one stack, no deep links. Plain `Navigator` with route helpers keeps the swap mechanical if URLs are ever needed. |

## Consequences

**Positive**
- Fully offline, private by default, zero infrastructure, instant interactions.
- Every layer is independently testable (59 tests, no mocking framework).
- UI, storage, product logic, and AI can each change without touching the others.

**Negative / accepted trade-offs**
- Listings are only visible on the device that created them — ironic for a
  marketplace, and accepted consciously: the sharing loop is phase 2.
- No backup: clearing browser data deletes the noticeboard (mitigated by the
  explicit reset control and, later, sync).
- IndexedDB is origin-scoped: during development a fixed `--web-port` keeps data
  stable across relaunches.

## Change points (recorded for phase 2+)

1. **Shared feed / sync** — implement `SyncedListingRepository` (e.g. Supabase +
   local cache) against the existing interface; the versioned codec doubles as the
   wire format migration path. This is the primary planned change.
2. **Real on-device model** — implement `LocalAiService` with a quantized model;
   keep `RuleBasedListingAi` as the fallback via a timeout decorator.
3. **Neighborhood list** — today a const; becomes remote config/data when multiple
   neighborhoods onboard.
4. **Status model** — `InteractionStatus` grows into a negotiation workflow
   (requested → agreed → handed over) once two real users exist.
5. **Encryption at rest** — encrypted Hive box if fields ever become sensitive.
