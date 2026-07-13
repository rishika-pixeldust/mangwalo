# Success metrics — MangWalo

Each metric is a testable statement with a pass/fail check a reviewer can run.

| # | Area | Metric (testable statement) | How verified |
|---|---|---|---|
| 1 | Product | A first-time user completes onboarding and sees a populated feed in ≤ 30 seconds without instructions | Stopwatch on a fresh browser profile |
| 2 | Activation | Creating a valid listing takes ≤ 90 seconds and ≤ 10 interactions starting from the feed | Count taps during a demo run |
| 3 | Local-first | 100% of created/updated listings survive a hard browser refresh and a full browser close/reopen (5 trials) | Create → refresh → verify; create → quit browser → reopen |
| 4 | Local AI | The listing helper returns useful suggestions for ≥ 8 of the 10 canned test descriptions, in under 100 ms, **with the network disabled** | `flutter test test/ai/` + DevTools offline demo |
| 5 | Accessibility | Every listing card exposes exactly one merged semantics node with a meaningful label; all interactive controls meet 48×48 targets | Widget test (`test/widget/`) + Flutter semantics debugger sweep |
| 6 | Security | Typing any of the 6 canned phone/address patterns into the description triggers a visible warning 100% of the time; the area field rejects them outright | `flutter test test/validation/` + manual demo |
| 7 | Offline | In an open session the app is fully functional with the network disabled: zero outgoing requests after initial asset load (offline *reload* is out of scope — no caching service worker) | DevTools Network tab kept open through a full demo run |
| 8 | Reliability | The complete 3-minute demo script runs twice consecutively with zero crashes or manual resets | Double demo run before Lab 2 |
| 9 | **Project-specific: return-date tracking** | A listing marked lent-out with due date D shows "Due in N days" while D ≥ today and an overdue badge once D < today, in **both** feed and detail, and overdue items sort to the top of the feed | One past-due + one due-soon sample listing at first load; `test/domain/due_info_test.dart` covers the day-boundary math |

## Notes

- Metrics 3, 4, 5, 6, and 9 are additionally locked in by the automated test suite
  (59 tests) — `flutter test` green is a precondition for calling the slice done.
- Metric 1 measured from "Get started" availability, not network load time.
