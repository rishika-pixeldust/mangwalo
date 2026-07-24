# MangWalo — 3-minute demo script

**Setup before the demo**
- Serve the release build (or `flutter run -d chrome --web-port=8080`).
- Fresh state: Settings → Reset all local data (or a fresh browser profile).
- Window at phone width or let the built-in phone frame do the work.
- Optional: DevTools open on the Network tab, collapsed.

| Time | Beat | Script / action |
|---|---|---|
| 0:00–0:15 | **Onboarding** | "MangWalo — *maang lo*. Rent luxury from your locality: designer bags, occasion wear, jewellery, sports kits. Local-first, one Mumbai neighborhood at a time." Pick **Bandra West**, Get started — the sample board loads automatically. "Everything you see stays on this device." |
| 0:15–0:40 | **Feed + product** | Scroll: cover photos, **₹/day price pills**, gold star ratings, For-rent vs Wanted posts. Point at the top card: "the Chanel is **overdue by 5 days** — Kiara has it, and overdue rentals jump the queue. The Sabyasachi lehenga at ₹9,500/day is **due back in 2 days**." Tap the **Designer bags** chip → list narrows; clear it. |
| 0:40–1:20 | **Create with the AI helper** | Tap the **+**. Type: *"sabyasachi lehenga, worn once and dry cleaned, with dupatta"*. Chips appear: title "Sabyasachi Lehenga", Event wear, Like new + Gently used, **₹6,000/day** — "the engine knows Sabyasachi is a premium label, so it doubled the category base" — and "Rent for 3 days — covers the occasion". Tap chips to accept. "Deterministic on-device rules — Hinglish included, no network, no model — behind a `LocalAiService` seam a real on-device model could replace in one line." |
| 1:20–1:40 | **Security beat** | In the description, append *"call me on 98200 12345"* → gold privacy warning appears quoting the number. Delete it. Then try area = *"flat 402, 400050"* → hard error; replace with *"Near Bandra Talao"*. "Landmarks only — exact addresses and numbers never get stored. Photos are re-encoded too, so GPS metadata is stripped." |
| 1:40–2:00 | **Save + persistence proof** | Set rate ₹6,000, deposit ₹20,000, save. The card appears in the feed. **Hard-refresh the browser.** Still there. "Hive over IndexedDB, behind a repository interface — the seam where a synced backend plugs in for phase 2." |
| 2:00–2:30 | **Return-date tracking** (personal feature) | Open the new listing → **Mark as rented out** → renter's first name, return date pre-filled 3 days out (the AI's window) → confirm. "Due in 3 days" shows in detail *and* on the card. Switch to **My items**: "my whole rental book in one strip — and when a date passes, the item flags itself and jumps the queue." |
| 2:30–2:45 | **Reviews + accessibility beat** | Open the Chanel → scroll to **Reviews**: "renters rate the item and the person — 'pristine, and the owner was gracious about my late pickup'." Then: "every card is one merged screen-reader announcement, errors are icon-plus-text, targets are 48 pixels, and the layout survives 200% text size." |
| 2:45–3:00 | **Reset + close** | Settings → **Reset all local data** → confirm → back at onboarding. "Full local data control. Docs, ADR, success metrics, and 73 tests are in the repo. That's the slice." |

**Optional beats (insert if ahead of schedule)**
- *Photo gallery* (at 2:30): swipe the detail gallery — "up to five photos per
  listing, dots and all, previewed before you commit to a rental."
- *Offline proof* (at 1:20): DevTools → Network → Offline → type another
  description — suggestions still appear instantly; zero requests in the log.
- *Status lifecycle* (at 2:30): on a Wanted card, tap Contacted → Closed → show
  the "Show closed" filter.

**Cut rule:** if running long, drop the category-filter demo (0:30–0:40) and
the optional beats — never the AI helper, pricing, or reviews.
