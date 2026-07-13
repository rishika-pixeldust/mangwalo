# Demo script — MangWalo (3 minutes)

**Setup before the demo**
- Serve the release build (or `flutter run -d chrome --web-port=8080`).
- Fresh state: Settings → Reset all local data (or a fresh browser profile).
- Window at phone width or let the built-in phone frame do the work.
- Optional: DevTools open on the Network tab, collapsed.

| Time | Beat | Script / action |
|---|---|---|
| 0:00–0:15 | **Onboarding** | "MangWalo — *maang lo*, just ask. A local-first borrow-and-lend noticeboard for one Mumbai neighborhood." Pick **Bandra West**, Get started — the sample noticeboard loads automatically. "That choice and everything else stays on this device." |
| 0:15–0:40 | **Feed + product** | Scroll: offers and requests with category emoji, "Sample" badges on demo data. Point at the top card: "the pressure cooker is **overdue by 5 days** — Sneha borrowed it, and overdue loans sort to the top. The cricket bat is **due in 2 days**." Tap the **Tools & Repair** chip → list narrows; clear it. |
| 0:40–1:20 | **Create with the AI helper** | Tap **New listing**. Type: *"bosch ka drill machine, thoda purana but works fine, weekends only"*. Suggestion chips appear: title "Bosch Drill Machine", Tools & Repair, tags Well-worn + Working, "Lend for 3 days". Tap chips to accept. "This is a deterministic on-device rule engine — Hinglish included, no network, no model — behind a `LocalAiService` interface a real on-device model could replace in one line." |
| 1:20–1:40 | **Security beat** | In the description, append *"call me on 98200 12345"* → amber privacy warning appears with the matched number. Delete it. Then try area = *"flat 402, 400050"* → hard error; replace with *"Near Bandra Talao"*. "Landmarks only — exact addresses and numbers never get stored." |
| 1:40–2:00 | **Save + persistence proof** | Save. The card appears in the feed (below the lent-out items — overdue loans always outrank everything). **Hard-refresh the browser.** Still there. "Hive over IndexedDB, behind a repository interface — the seam where a synced backend plugs in for phase 2." |
| 2:00–2:30 | **Return-date tracking** (personal feature) | Open the new listing → **Mark as lent out** → type a borrower first name, the return date comes pre-filled 3 days out (the AI's suggested duration) → confirm. Badge shows "Due in 3 days" in detail *and* on the feed card. Switch to the **My items** tab: "my whole lending life in one strip — and when a date passes, the item flags itself and jumps the queue." |
| 2:30–2:45 | **Accessibility beat** | Toggle dark mode in Settings (or bump OS text size to 200%): "every card is one merged screen-reader announcement, errors are icon-plus-text, all targets are 48 pixels, and the layout survives double text size." |
| 2:45–3:00 | **Reset + close** | Settings → **Reset all local data** → confirm → back at onboarding. "Full local data control. Docs, ADR, success metrics, and 59 tests are in the repo. That's the slice." |

**Optional beats (insert if ahead of schedule)**
- *Status lifecycle* (at 2:30): on a request card, tap Contacted → Closed → show the
  "Show closed" filter.
- *Offline proof* (at 1:20): DevTools → Network → Offline → type another description —
  suggestions still appear instantly; zero requests in the log.
- *Photo* (at 1:40): "Add a photo" on the create form — downscaled, EXIF stripped,
  stored only on this device.

**Cut rule if running long:** drop the category-filter demo (0:30–0:40) and the
dark-mode half of the accessibility beat.
