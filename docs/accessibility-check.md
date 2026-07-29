# Accessibility check — MangWalo

**Tools used:** Flutter semantics debugger, widget tests with `ensureSemantics()`,
browser/OS text scaling, manual keyboard/focus pass, and a scripted WCAG
contrast calculation over the palette (relative-luminance formula) for every
theme the app can render.

## Checklist

| Requirement | Where implemented | How tested | Result |
|---|---|---|---|
| All interactive controls are labeled | Tooltips on icon buttons (settings, edit, delete); labeled form fields; suggestion chips carry action-phrased semantics ("Apply suggested title: …") | Semantics debugger sweep over every screen | ✅ |
| Listing cards are screen-reader friendly | `ListingCard` wraps the card in one `Semantics` node with a composed label (type, title, category, area, lending state, due info, status, sample flag) and excludes child fragments | Widget test asserts the merged label (`test/widget/feed_screen_test.dart`); semantics debugger | ✅ |
| Form errors are visible, not color-only | `TextFormField` errors show message text below the field; privacy warnings show an icon + message + the matched text; due-date and applied-suggestion states pair icons with text | Submit an empty form; type a phone number in the description | ✅ |
| Touch targets ≥ 48×48 | `materialTapTargetSize: padded` app-wide; chips sized via theme padding; primary action buttons `minimumSize: Size.fromHeight(48+)` | Flutter inspector spot checks on chips, icon buttons, FAB | ✅ |
| Text scaling support | No fixed-height text containers; badge rows use `Wrap`; segmented buttons scroll horizontally rather than clip; cards grow intrinsically | Widget test pumps the feed at `TextScaler.linear(2.0)` and asserts zero overflow exceptions | ✅ |
| Contrast in light AND **three** dark themes | The "Velvet Ledger" `ColorScheme`s are hand-mapped, not generated from a seed — a seed could not hold oxblood, blush and gold in the roles this design needs. On-container colour pairs everywhere (never raw hex on raw hex) | Scripted contrast check per variant. Body-on-surface: Warm charcoal **12.7:1**, Wine noir **14.8:1**, True black **16.0:1**. Secondary text ≥ 6.3:1, accent-on-surface ≥ 7.9:1 — all above the 4.5:1 AA threshold | ✅ |
| Dark mode is a choice, not a guess | Three variants (Warm charcoal default, Wine noir, True black) in Settings, because comfort in the dark depends on the room and the panel. The default deliberately has the *lowest* peak contrast of the three — glare, not legibility, is what makes dark mode tiring | Contrast verified per variant as above; light theme left unchanged | ✅ |
| Calendar days state their availability | Each day in the booking calendar announces "12 December, already booked" rather than relying on strike-through and fill colour, and blocked days are not focusable | Semantics labels asserted per cell; manual VoiceOver pass | ✅ |
| AI suggestions announced to assistive tech | `SemanticsService.sendAnnouncement` fires only when the suggestion set materially changes — never per keystroke; each suggestion chip is a labeled, screen-reader-activatable button (`Semantics(button, onTap)`) with its applied state exposed via `selected` | Code review + manual VoiceOver pass on the create form | ✅ |
| Privacy warnings announced to assistive tech | Each warning renders inside `Semantics(liveRegion: true)`, so screen readers speak safety messages the moment they appear (WCAG 4.1.3 Status Messages) | Type a phone number into the description with VoiceOver running | ✅ |
| Meaningful focus order on forms | Form fields laid out in reading order; suggestion panel sits directly below the description field it relates to | Keyboard tab pass through the create form | ✅ |

## Known gaps (honest list)

- No custom keyboard shortcuts; navigation relies on Flutter web's default focus
  traversal.
- The date picker is the stock Material dialog — accessible, but its semantics are
  whatever Material ships.
- `SemanticsService` announcements are polite (non-interrupting); a screen-reader user
  who is mid-sentence may hear them late.
- Tested primarily with the Flutter semantics debugger and macOS VoiceOver in Chrome;
  not yet tested with TalkBack on a physical Android device.
