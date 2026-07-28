# Sample data — what the demo board is, and why

MangWalo seeds a small, clearly-flagged sample board on first launch so the
noticeboard is never an empty screen. This document explains exactly what that
data is, why each row exists, and how to get rid of it.

## It is illustrative, not real

| Aspect | What it actually is |
|---|---|
| Listings | 15 fictional rows, generated in [`seed_data.dart`](../lib/src/features/listings/data/seed_data.dart) |
| Imagery | Generated art — a category glyph, a serif monogram and a gradient. **No product photography.** Produced by [`tool/make_seed_images.py`](../tool/make_seed_images.py), 13 items × 4 "angles" = 52 files |
| People | First names / initials + common surnames. No real person, no digits anywhere |
| Brands | Real luxury brand *names* appear in titles because that is how a renter would search ("Chanel Classic Flap"). Nothing implies affiliation, and no brand imagery is used |
| Flagging | Every row carries `isDemo: true`, renders a **"Sample"** badge, and is excluded from nothing except your trust |
| Removal | Settings → **Hide sample listings**. One tap, reversible, and it never touches listings you created |

Sample ids are deterministic (`sample-1` … `sample-15`), which is what makes
seeding idempotent: re-seeding overwrites the same rows instead of piling up
duplicates. `AppConstants.seedVersion` is bumped whenever the set changes so
existing installs pick up the refreshed rows in place.

## Why these 15 rows

The set is chosen so that **every state the UI can render is visible without
touching anything**. That matters for a demo, and it matters more for catching
regressions — if a badge or empty state breaks, the sample board shows it.

### Coverage matrix

| What it proves | Which sample carries it |
|---|---|
| **Overdue** badge + overdue-first sorting | Chanel Classic Flap bag — due 5 days ago, rented by Kiara |
| **Due soon** badge | Sabyasachi bridal lehenga — due in 2 days, rented by Meher |
| **Returned** state | Omega Seamaster — returned yesterday |
| **Available** state | most rows |
| `ListingType.request` ("Wanted") + budget pricing | "Need: golf half set…", "Need: cocktail dress…" |
| `InteractionStatus.contacted` | Emerald sequin gown |
| `InteractionStatus.closed` (hidden until "Show closed") | "Need: cocktail dress for New Year's Eve" |
| **Multi-photo gallery** (3–4 photos, swipeable) | every offer |
| Multiple reviews + aggregate rating | Chanel (3 reviews, 4.7), SG cricket kit (3 reviews) |
| A single review | Emerald gown, Callaway set, Pashmina |
| **No reviews yet** | the two requests |
| All 7 categories | bags ×2, event wear ×2, party wear ×2, sports ×2, jewellery ×2, watches ×1, accessories ×2 |
| Sub-categories | Shoulder bag, Tote, Lehenga, Bandhgala, Cricket, Golf, Kundan, Jhumkas, Potli, Pashmina, Automatic, Shimmer dress |
| Price range | ₹500/day (pashmina) → ₹9,500/day (bridal lehenga) |
| Deposit range | ₹1,500 → ₹40,000, plus rows with **no** deposit |
| Hinglish in descriptions | lehenga, bandhgala, kundan, potli, jhumka, maang tikka |

Due dates are computed **relative to now**, not hard-coded — so the overdue and
due-soon badges demonstrate correctly whenever the app is opened, not just on
the day the data was written.

## Reviews say two things at once

Reviews deliberately mix feedback on the *item* and on the *person*, because
that is what a renter actually needs to know before handing over ₹4,800/day:

> "Bag was pristine — dust bag, card, everything. And the owner was so gracious
> about my late evening pickup."

Item condition and counterparty behaviour in one line. One review also
mentions a flaw the owner disclosed up front, so the set doesn't read as
uniformly glowing.

## Privacy properties

Sample rows are held to the same rules as real ones, so they can never teach
bad habits or trip the privacy scanner:

- Locations are **landmarks only** ("Near Carter Road promenade"), never addresses
- **No digits** in any name or free-text field
- Borrower fields hold a **first name only**
- No phone numbers, no email addresses, no unit numbers

## Regenerating

```bash
python3 tool/make_seed_images.py
```

Writes all 52 JPEGs into `assets/seed/`. Cover files keep the bare name
(`bag_chanel.jpg`) because the intro carousel and the demo harness reference
them directly; the extra angles are `_2`, `_3`, `_4`.
