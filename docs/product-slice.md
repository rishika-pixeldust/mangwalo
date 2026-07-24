# Product slice — MangWalo

## Problem

Dense Mumbai neighborhoods are full of rarely-used things — drills, ladders, pressure
cookers, festival decorations, exam guides — and full of people who need exactly those
things for a day or a week. Today this matching happens in building WhatsApp groups,
where posts scroll away within hours, there is no way to browse what's available, and
people routinely over-share phone numbers and flat numbers in public group chats.

## Target user

A resident of one housing-society-dense Mumbai neighborhood (e.g. Bandra West) who
wants a lightweight way to discover what neighbors can lend, offer their own items,
and keep track of what is currently lent out — on their phone, without creating an
account or publishing their address.

## The slice (in scope)

- Browse a single neighborhood's luxury board: **For rent** and **Wanted** posts
  across seven categories (designer bags, event wear, party wear, sports kits,
  jewellery, watches, accessories), with a **Noticeboard / My-items split** and a
  lending summary for your own items
- **₹/day pricing on every card** (budget on Wanted posts) plus an optional
  refundable deposit on the detail page
- Filter by type and category, search by text, hide/show closed listings
- Create and edit listings: title, description, category, condition tags,
  landmark-level area, contact channel + note, and **up to five photos** with a
  swipeable preview gallery (downscaled, EXIF-stripped, stored on-device only)
- On-device listing helper: suggested title, category, condition tags, rental
  window, and **₹/day rate** (premium brands double the base) from the free-text
  description (deterministic, offline)
- Status lifecycle per listing: **saved → contacted → closed**
- Item lifecycle: **available → lent out (with expected return date and borrower
  first name) → returned**
- **Return-date tracking** *(personal product feature)*: due/overdue badges in feed
  and detail, overdue-first sorting, AI-suggested window prefills the date picker
- **Reviews**: 5-star + text feedback per listing covering the item and the person;
  aggregate rating on every card
- Three-page concept intro on first launch (skippable); local profile (first
  name) with an optional salted-hash app PIN that locks the app on launch
- First-launch neighborhood picker; auto-loaded (and removable) sample data; full
  local data reset

## Explicitly out of scope (this slice)

| Cut | Why |
|---|---|
| Accounts / auth | No server, no identity needed for a single-device slice |
| Chat / messaging | Contact channel field covers the handoff; chat needs a backend |
| Payments / deposits | Trust mechanics come after sharing works at all |
| Multi-device sync / shared feed | Phase 2 — the `ListingRepository` seam is built for it |
| Real geolocation / maps | Landmark text is safer and sufficient at neighborhood scale |
| Notifications | Meaningless without background services; due badges cover the need |

## Why local-first

- **Privacy**: addresses, contact notes, and lending history never leave the device.
- **Speed & resilience**: there is no backend to be slow or down — once loaded, the
  app makes zero network requests and every feature (including the AI helper) works
  with the network disabled. (Offline *reload* — full PWA asset caching — is
  documented future work, not claimed.)
- **Honest scope**: a real shared marketplace needs moderation, identity, and sync —
  each a project of its own. This slice proves the product loop and the architecture
  seams first. See [ADR-0001](adr/0001-local-first-marketplace-slice.md).
