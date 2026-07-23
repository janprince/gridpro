# GRID Professionals

GRID Professionals is the provider-facing operating system for the managed GRID service network. This Flutter MVP lets a skilled professional apply, complete mocked verification, become job-ready, manage a full job lifecycle, prepare quotes, submit evidence, track earnings and payouts, build a professional profile, and contact support.

> All people, jobs, verification results, badges, payments, payout methods, receipts, uploads, support tickets, and transaction IDs in this repository are sample data. No real verification, customer approval, payment, or payout occurs.

## Toolchain

- Flutter 3.44.4 stable
- Dart 3.12.2
- Material 3
- `flutter_riverpod` for application and workflow state
- `go_router` for auth, shell, and operational routes
- `intl` for Ghana Cedi, date, and time formatting
- `shared_preferences` for mock auth, onboarding, and availability persistence

## Run

```sh
flutter pub get
flutter run
```

Useful verification commands:

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

The welcome screen includes an **Explore the mocked professional app** control for direct access to operational flows. To exercise onboarding, use **Apply to join GRID**. The OTP screen accepts any six digits in this demo.

## Stitch Reference

The implementation was based on Stitch project `2931437422838032211` and its GRID Professionals screens, including:

- Splash & Onboarding, Welcome & Login, Login & Authentication
- Apply: Service Categories
- Jobs Dashboard and New Job Offer
- Active Job Detail and Quote Builder
- Earnings Dashboard and Payment Receipt Confirmation
- Professional Profile
- App Empty States Showcase

The adopted direction is Stitch's forest-green **Premium Utility** system: warm off-white surfaces, charcoal text, restrained teal/mint accents, 20 px mobile margins, 8 px spacing rhythm, rounded cards, low-contrast borders, pill statuses, compact summary metrics, left-accented action cards, and fixed bottom actions. The app reuses that component and layout direction without copying consumer utility-payment screens.

Improvements beyond Stitch include consistent 52–54 px actions, lifecycle-specific primary actions, full-address privacy before acceptance, a hard quote-approval gate before work, clearer evidence messaging, accessible status colors, explicit mocked-data labels, consistent support access, validation, and a unified five-tab provider information architecture. Visual assets are code-native placeholders so the MVP has no remote image dependency.

## Implemented Flows

- Splash, welcome, phone login, OTP, eight-step professional application, verification tracker, and job-ready checklist
- Jobs-first shell with Jobs, Schedule, Earnings, Profile, and Support tabs
- Availability states: available, busy, and offline, plus days, hours, travel radius, emergency, same-day, and vacation controls
- Offer review with general area only, accept confirmation, decline reasons, then full customer details after acceptance
- Journey, arrival, inspection notes/photos, quote draft, quote preview, submission, customer-approval simulation, and approval gate
- Approved work, progress notes/photos, completion evidence, customer-confirmation simulation, payment processing, payout pending, paid, and sample receipt
- Earnings metrics, commission transparency, trend, job-level earnings, payout method placeholder, payout history, and job history
- Professional profile, sample badges, service areas, portfolio, editing, ratings/performance, reviews, and training modules
- Support categories, safety escalation, issue/dispute form, evidence placeholder, and locally recorded mock ticket
- Reusable cards, job cards, status chips, metrics, timeline steps, availability control, upload tiles, empty states, support actions, confirmation sheets, and fixed action bars

## Structure

```text
lib/
  app/                 App root
  core/
    models/            Typed domain models and enums
    routing/           go_router route graph
    theme/             Stitch-derived colors, spacing, radius, theme
    utils/             Currency/date formatting and validation
    widgets/           Reusable UI components
  data/
    mock_data.dart     Ghana-focused fixtures
    repositories/      Replaceable repository contract and mock adapter
  features/
    auth/ onboarding/  Trust and application flows
    jobs/ quote/       Operational lifecycle and commercial workflow
    schedule/ earnings/
    profile/ support/
    main/              Five-tab shell
  state/               Riverpod app/workflow controller and persistence
```

## API Integration Points

`GridRepository` is the replacement boundary for profile, jobs, earnings, payouts, reviews, and training. A production adapter can replace `MockGridRepository` through `gridRepositoryProvider`. Job mutations, quote submission, uploads, verification, payout methods, customer contact, directions, notifications, support chat, WhatsApp, receipt sharing, and support tickets currently remain local UI simulations and should be backed by authenticated services.

Production work should also add secure token storage, backend-authoritative workflow transitions, signed upload URLs, offline retry queues, push notifications, map/navigation SDKs, observability, crash reporting, analytics consent, localization, real accessibility audits, and integration tests against staging APIs.

## Known Limitations

- No live backend, identity verification, customer app handshake, payment processor, payout rail, maps, notifications, or media picker is connected.
- Application form fields beyond the core mocked selections are not persisted as a complete draft.
- Quote editing uses one representative material line; the data model supports multiple materials but dynamic persistence is future work.
- The demo can advance customer approval and payment states locally so the entire lifecycle is reviewable.
- Badges, ratings, receipts, review times, commissions, and earnings are illustrative only.
