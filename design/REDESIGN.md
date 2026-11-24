# GRID Pro v1 — navy, two services

> The full, shared design system (both apps) is documented in
> [`../../DOCUMENTATION/design-system.md`](../../DOCUMENTATION/design-system.md). This file keeps
> the GRID Pro product decisions and history.

GRID Pro v1 does two things: **home cleaning** and **laundry**. Every screen is built around a
provider's real day — take a request, do the job, get paid — and nothing else.

## Direction

The previous charcoal/teal pass copied Wise's language (pill buttons, grey groups, sentence-case
heroes) and read as generic. This version takes its cues from Hubtel's merchant app, which the
team likes, and adapts them rather than copying them:

| From Hubtel | In GRID Pro |
| --- | --- |
| Solid navy buttons, uppercase labels | `PrimaryButton` / `SecondaryButton`: 8px radius, 54px, labels in capitals |
| Tinted product card with a fingerprint motif (Pay Small Small, ABSA) | `ServiceHeroCard`: mint for cleaning, sky for laundry, `CornerArcs` in the corner |
| Blue gradient balance card with a white action | `NavyPanel` + `OnNavyButton` for today's earnings and the balance |
| Bordered transfer cards, outlined status pill, date chips | `JobTile`, `StatusPill`, `DateChip` on the Jobs and Earnings tabs |
| Navy profile header, amber links, white sheet overlapping it | Account tab header with `GridTexture`, initials avatar, amber links |
| Confirmation bottom sheet led by a tinted card | `showConfirmationSheet(header: …)` for pickup, delivery and finishing |
| Tab bar with the selected tab on a soft tile | `MainShell` |

What makes it GRID's own: the four-cell **GRID mark** (three navy cells, one amber), the faint
**grid texture** on every navy surface, and the per-service tints. No stock photography — the
welcome screen shows two real job cards instead.

## Tokens

- Navy `#13294B` (deep `#0B1C37`) for actions and identity; amber `#F4C76A` only on navy.
- Cleaning: tint `#EAF6F0`, badge `#1F7A52`. Laundry: tint `#EAF1FB`, badge `#2F62B5`.
- Plus Jakarta Sans (variable, 200–800, SIL OFL, `assets/fonts/`), chosen for its round, Hubtel-like
  geometry; Inter is the per-glyph fallback. Tabular figures for every amount, slight positive
  tracking at body sizes. Scale in `AppText`. The font's cmap includes ₵ (U+20B5) — checked.
- Radii: 8 controls, 12–16 cards, 22 hero cards and sheets.

## Product shape

    Home      Today's earnings · the most urgent request · up next (with its one action)
    Jobs      Upcoming / Completed, grouped by day
    Earnings  Balance · last 7 / 30 days · activity by day
    Account   Profile header · services & prices · availability · payout account · help

A job has **one** next action at a time, following the API's workflows:

    Cleaning  Scheduled → On the way → Arrived → Cleaning → Done
    Laundry   Pickup scheduled → Picked up → Washing → Ready → Out for delivery → Done

Pickup, delivery and finishing ask first; every other step is one tap. The trade-style inspection
and quote flow is gone.

## Rules

- One solid navy button per screen. Alternatives are outlined.
- Colour never carries meaning alone — every status has a label.
- Money is right-aligned, tabular, and never clipped (`Amount` scales down instead).
- Everything must survive 320×640 at 1.3× text (see `test/redesign_layout_test.dart`).

## Verification

- `flutter analyze`: no issues. `flutter test`: 24 passing.
- Visual review in the browser at 427×764 with sample data: welcome, phone, code, home, request,
  job (cleaning and laundry flows end to end), jobs, earnings, account, payout account,
  availability, application hub and services step.
