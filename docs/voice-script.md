# Voice-over script — MangWalo demo

Seven segments, one per slide. Record each as a **separate file** and drop them
in `tool/demo/audio/` as `s0`…`s6` (`.aiff`, `.wav`, `.mp3` or `.m4a` all work),
then assemble:

```bash
MANGWALO_NARRATION=external ./tool/demo/build_video.sh
```

Each slide's on-screen duration is taken from **your** audio file, so the video
re-times itself around the voice-over — there is no manual syncing, and a
segment that runs long simply holds its slide longer.

Direction: warm, conversational Indian English. Confident but unhurried — this
is a product walkthrough, not an advert. Let the em-dashes breathe.

| # | Slide | Segment | Words | ~Time @145wpm | App frames shown |
|---|---|---|---|---|---|
| 0 | `s0_intro` | Intro — what MangWalo is | 71 | 29s | 01_onboarding, 02_feed |
| 1 | `s0b_tour` | How it works — the tour, locality, profile | 112 | 46s | 10_tutorial, 11_profile |
| 2 | `s1_product` | 01 · Product Thinking | 78 | 32s | 03_myitems, 06_detail_lending |
| 3 | `s2_a11y` | 02 · Accessibility | 77 | 32s | 07_a11y_scale |
| 4 | `s3_ai` | 03 · Local AI | 85 | 35s | 04_ai_suggestions |
| 5 | `s4_security` | 04 · Security | 97 | 40s | 05_privacy_warning, 08_settings |
| 6 | `s5_outro` | Outro — recap and links | 44 | 18s | — |

**Total: 7 segments, ~3.9 minutes** (564 words).

---

## Segment 0 — Intro — what MangWalo is

*Slide `s0_intro` · 71 words · ~29s*

Meet MangWalo.

Maang lo — just ask!

A local-first noticeboard where neighbors in one Mumbai locality rent luxury
from each other — a Chanel flap bag, a Sabyasachi lehenga, a full cricket kit.

Every listing carries a daily rate, a photo gallery, and reviews.

Built in Flutter for M A L Lab One, and live at mangwalo dot vercel dot app.

No account, no server — everything stays on your device.


## Segment 1 — How it works — the tour, locality, profile

*Slide `s0b_tour` · 112 words · ~46s*

So how do you use it?

On your very first visit, a five-step tour walks you around the real board —
search, filters, posting, requests, your account — and you can replay it any
time from the How It Works menu.

The board is scoped to your locality: switch from Bandra West to Powai and the
listings genuinely change, with one tap to browse every locality at once.

Filter by category, then narrow again by sub-category.

And your profile shows what neighbors have said about you, and what of yours
is currently out on loan — because reputation is what makes a stranger willing
to hand over a four thousand rupee bag.


## Segment 2 — 01 · Product Thinking

*Slide `s1_product` · 78 words · ~32s*

First, product thinking.

The niche is deliberately sharp: designer bags, event and party wear,
jewellery, watches, and sports kits — priced per day, right on the card, and
only from your locality.

Renters leave star reviews that speak to the item and the person.

And the personal feature — return date tracking — means every rented piece
remembers who has it, and when it is due.

Overdue rentals flag themselves, and jump to the top of the board.


## Segment 3 — 02 · Accessibility

*Slide `s2_a11y` · 77 words · ~32s*

Second, accessibility.

Every listing card is one single, meaningful screen reader announcement — not
five fragments.

Errors pair icons with text, never color alone.

Every touch target is at least forty eight pixels.

And the layout survives two hundred percent text scaling — what you see here
is the feed at nearly double size, with nothing broken.

Dark mode is a choice, not a guess: three palettes, every one contrast-checked
to W C A G double A.


## Segment 4 — 03 · Local AI

*Slide `s3_ai` · 85 words · ~35s*

Third, local A I.

Type — sabyasachi lehenga, worn once and dry cleaned — and the on-device
helper suggests a title, a category, condition tags, a rental window, and a
rate: six thousand rupees a day, because it knows Sabyasachi is a premium
label and doubles the base.

It is a deterministic rules engine that understands Hinglish, needs no cloud
and no A P I keys, and works fully offline — behind a swappable Local A I
Service boundary, ready for a real on-device model.


## Segment 5 — 04 · Security

*Slide `s4_security` · 97 words · ~40s*

Fourth, security.

MangWalo practices data minimization.

Type a phone number, or a flat number, and it warns you instantly — showing
the exact text it found.

The landmark field hard-rejects addresses.

Every gallery photo is re-encoded on the device, stripping location metadata
before it is stored.

The strongest move was deletion: the free-text contact note — the field most
likely to carry a phone number — was removed from the app entirely, and old
values are dropped rather than migrated.

Renter names are first names only.

And one tap in settings resets every byte of local data.


## Segment 6 — Outro — recap and links

*Slide `s5_outro` · 44 words · ~18s*

That is MangWalo.

Product thinking.

Accessibility.

Local A I.

And security.

One hundred and seven passing tests, a clean analyzer, and a deployed build
you can open right now.

Try it at mangwalo dot vercel dot app.

Maang lo — luxury, from your locality!

