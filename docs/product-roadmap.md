# Roadmap to a sellable product

MangWalo today is a well-built product *slice*. What separates it from a
business is not polish — it is the machinery that makes a stranger willing to
hand over a ₹2-lakh bag. This document records the decisions taken, the build
order, and the things deliberately not being built.

## Decisions

| Decision | Choice |
|---|---|
| What "for sale" means | A real marketplace — users pay to rent, platform takes a cut |
| Operations | Peer-to-peer; the platform never takes custody |
| Damage disputes | Mandatory in-app condition capture at handover and return |
| Counterfeits | Proof of purchase required for any listing naming a luxury brand |
| Deposit | Collected up front with rent, refunded on confirmed return |
| Revenue | 15–20% commission from the owner's payout |
| Booking | Request to book; owner approves within 24h |
| Discovery | Radius-based ("within 8 km"), replacing hard locality boundaries |
| Verification | Full KYC on both sides, enforced **just-in-time** before a first transaction |
| Sequencing | Trust layer first, then booking, then money |

### Two decisions worth revisiting later

**Peer-to-peer with no custody** is the cheapest model and it is what "from
your locality" promises. It also means you adjudicate damage having never seen
the item. Condition capture is the mitigation, not a cure — if disputes exceed
roughly 5% of rentals, revisit the hybrid model (platform inspection above a
value threshold).

**Full KYC on both sides** is a strong supply-side signal and the right instinct
for luxury. Its cost is signup friction on an empty marketplace, which is why it
is enforced just-in-time below. If first-transaction completion runs below ~40%,
the renter-side ID requirement is the first thing to relax (phone-only under
₹2,000/day).

---

## Phase 1 — Trust layer

Nothing here transacts. The goal is that an owner believes it is safe to list.

**Identity**
- Phone OTP for every account (floor).
- Government ID verification via DigiLocker or Aadhaar offline eKYC, plus PAN
  for owners (needed regardless, since payouts require it).
- Enforced **just-in-time**: browsing is open; verification is required before
  publishing a first listing or confirming a first booking. Everyone who
  transacts is verified — the wall simply is not in front of an empty board.
- Verified badge on profiles and listings.

**Condition capture** — the core dispute mechanism
- A rental has two photo sets: handover and return.
- Both parties photograph together, in-app, server-timestamped. Each confirms
  the other's set before the item changes hands.
- Reuse the existing pipeline: `core/images.dart` already downscales and strips
  EXIF, and Storage upload already namespaces by user id.
- Server timestamps only — never trust a client clock in evidence.
- Store sets immutably, like `messages`: evidence must not be editable after
  a claim is opened.

**Reputation**
- Extend the existing `reviews` table with a completed-rental requirement, so a
  review can only follow a real transaction.
- Separate item rating from counterparty rating; both already exist in the
  copy, not yet in the schema.
- Surface response rate and completed-rental count on profiles.

**Proof of purchase**
- Any listing whose title or brand field matches the premium-brand list
  (`keyword_rules.dart` already has ~46 of them) requires a receipt,
  authenticity card or serial photo before going live.
- Reviewed once per listing, not per rental.
- Stored privately — this is not a public bucket.

**Moderation**
- Report button on every listing and profile.
- Admin view: reported items, unverified listings awaiting proof, dispute queue.
- Takedown that preserves the row for the record rather than hard-deleting.

## Phase 2 — Booking

This is the largest functional gap: today an item is `available` or `lentOut`
with one `dueDate`. Real rental is a date range.

- `availability` table: per-listing blocked date ranges, with an exclusion
  constraint so double-booking is impossible **at the database level**, not
  merely discouraged in the UI. Postgres `daterange` + `EXCLUDE USING gist`.
- Request → approve → confirmed → in-progress → returned → closed. The existing
  `rental_requests` table already carries `start_date`, `end_date` and `status`.
- Auto-decline after 24h of owner silence; nudge on low response rate.
- Calendar UI on the listing; date picker that cannot select blocked ranges.
- Retire the binary `lendingState` in favour of derived state from bookings.
  Keep the invariant discipline the current domain has.

## Phase 3 — Money

Confirm every specific below with a CA and your payment aggregator before
launch. Treat this section as a checklist, not as advice.

- Payment aggregator with marketplace split and payouts (Razorpay Route,
  Cashfree Easy Split or equivalent).
- Rent + deposit collected together at booking confirmation.
- Deposit refunded on confirmed return, against a **published SLA** — a slow
  refund is the fastest way to lose a renter. Instrument the median.
- Owner payout after the return window closes, minus commission.
- Commission is a service supply: 18% GST applies. Marketplace TCS under
  s.52 CGST may also apply to facilitated supplies — verify.
- Deposit deduction flow: owner claims → renter responds → evidence from
  condition capture → resolution. Publish the schedule up front.
- Invoicing for both sides.

Later, once there is loss history: replace self-funded risk with a real
insurance partner and an optional protection fee. No underwriter will write
P2P luxury cover before you can show volume and claims data.

## Phase 4 — Growth

- Radius discovery: geocode listings, replace the locality filter with
  distance. Keep "your locality" as a saved filter, not the model.
- Notifications: in-app inbox with the bell badge (already stubbed), plus
  email for booking requests and returns. Web push needs a server and only
  fires when the tab is open — it is not the primary channel.
- Availability-driven search: "free on 12–15 December" is the query that
  matters for wedding season.
- Wishlists and saved searches.
- Seasonal merchandising — wedding season is the demand peak for this catalogue.

## Not building

- **Platform-managed logistics** (pickup, inspection, cleaning). It solves
  damage and hygiene properly, and it is how Flyrobe and Rent the Runway
  operate — but it makes you a logistics company and destroys the hyperlocal
  cost advantage. Revisit only if disputes prove the P2P model unworkable.
- **In-house counterfeit authentication.** Requires custody. Proof of purchase
  shifts liability to the lister instead.
- **Server-side AI.** The on-device rule engine is a genuine differentiator and
  costs nothing per call. Photo search via a hosted model was scoped and
  dropped: it would weaken the local-AI claim for a marginal feature.
- **Native apps.** The PWA installs. Revisit when push notifications or camera
  fidelity actually block a revenue path.

## Legal and compliance

Not optional once real money and real identity documents are involved.

- **DPDP Act 2023.** Collecting government IDs makes you a Data Fiduciary:
  consent notice, purpose limitation, retention limits, breach reporting, and a
  grievance officer. This is the single biggest compliance change from
  Phase B onward, because data now leaves the device.
- Rental agreement / T&Cs covering damage, loss, late return and liability caps.
- GST registration; commission invoicing; TCS position confirmed.
- KYC/AML obligations inherited from the payment aggregator.
- Consumer protection: refund and cancellation policy, published.
- Insurance: broker conversation early, even though cover comes later.

## What to measure

- Listing → first booking request (supply activation)
- Request → approval rate, and owner response time
- Approval → completed rental
- Dispute rate per 100 rentals — the number that decides whether P2P holds
- Deposit refund median time
- Repeat rental rate per renter
- Verification funnel completion, split by side
