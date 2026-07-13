# Local AI note — MangWalo listing helper

## Helper type

A **listing helper**: given the free-text description the user is typing, it suggests
a title, a category, condition tags, and a fair lending duration.

The implementation is a **deterministic rule engine** (`RuleBasedListingAi`) — an
expert-system-style pipeline in pure Dart:

```
free text → normalize → tokens + bigrams/trigrams
          → keyword scoring per category (phrase = 3, word = 1, each entry counts once)
          → title from the longest matched token run (+ brand casing, acronyms)
          → condition tags from a phrase table (Hinglish included)
          → duration from a per-category table
```

There is **no ML model, no network call, no hosted API, no randomness, and no clock**
inside the engine. Same input → byte-identical output, verified by a determinism test.

## The boundary

The app only ever sees the `LocalAiService` interface
(`lib/src/features/ai/local_ai_service.dart`):

```dart
abstract interface class LocalAiService {
  Future<ListingSuggestion> suggest(AiSuggestionInput input);
  AiEngineInfo get engineInfo;
}
```

- `Future`-based even though the rule engine is instant, so an on-device model that
  needs isolate/worker offloading fits the same contract with zero call-site changes.
- The contract (doc comment): no network I/O, deterministic per engine version, never
  throws — garbage input returns an empty suggestion.
- The form controller debounces input (450 ms) and uses a monotonic request id, so
  even a slow future model can never clobber newer input.
- `engineInfo` drives the in-app disclosure line ("Suggestions are generated
  on-device and work offline") — swapping engines automatically updates what the
  user is told.

## Fallback behavior

The rule engine is simultaneously the **primary implementation and the permanent
fallback** — there is no degraded mode to design because the baseline already works
offline and instantly. When nothing matches, the helper returns an empty or
low-confidence suggestion and the form simply works manually; suggestions never block
saving. When a real model is added later (change point in
[ADR-0001](adr/0001-local-first-marketplace-slice.md)), `RuleBasedListingAi` remains
the fallback for when the model asset is unavailable or slow.

## Suggestions are consent-based

Suggestions render as labeled chips the user explicitly taps to accept. The helper
**never auto-fills or overwrites** anything the user typed. Applied state is shown
with a check icon plus semantics ("Applied: …"), and new suggestions are announced to
assistive tech only when they materially change.

## Honest limitations

- Keyword dictionaries cover common English + Hinglish household vocabulary
  (~280 entries across 10 categories); typos, other languages, and unusual items fall
  through to the fallback title.
- "Confidence" is a keyword-score bucket, not a calibrated probability.
- The engine reads **only the description field** — never contact or area fields.
  Privacy scanning is a separate security module, deliberately not part of the AI
  feature.
- It is not "AI" in the ML sense, and the docs and UI never pretend otherwise.
