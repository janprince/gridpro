# GRID Pro

The provider-facing app in the GRID ecosystem. Version 1 serves four services — **home
cleaning**, **laundry**, **AC servicing** and **pest control** — for independent professionals
and small businesses in Ghana. GRID sets the price of every job; a provider picks the services
they do, sees what each job earns them, and GRID assigns them work nearby.

The app's most important journey is **onboarding**: taking a new professional from a phone number
to a verified, bookable profile. Everything else in the product depends on getting that right.

> Payments, payouts and verification decisions are handled by GRID operations. This app never
> moves money itself.

## Toolchain

- Flutter 3.44 / Dart 3.12
- Material 3 with a custom GRID theme (light only — there is no dark mode)
- `flutter_riverpod` for app and onboarding state
- `go_router` for routing
- `dio` + `flutter_secure_storage` for the API client and session
- `image_picker` for portfolio and identity capture
- `shared_preferences` for the onboarding draft and local flags
- `intl` for Ghana cedi, date and time formatting

## Running

```sh
flutter pub get
flutter run
```

The app talks to the [GRID API](../Grid.API). Point it at a server with `--dart-define`:

```sh
# Android emulator reaching an API on the host machine (Android default)
flutter run --dart-define=GRID_API_BASE_URL=http://10.0.2.2:8080/api/v1

# iOS simulator / desktop / web use http://127.0.0.1:8080/api/v1 by default

# A physical device on the same network
flutter run --dart-define=GRID_API_BASE_URL=http://192.168.1.20:8080/api/v1

# No backend at all — bundled sample data only
flutter run --dart-define=GRID_USE_API=false
```

With `Otp:DevelopmentMode` on, the OTP code is always **123456**, and `0240000002` signs in as a
seeded, approved provider (Efua Asante) who is online in East Legon.

Verification commands:

```sh
dart format lib test
flutter analyze
flutter test
```

## Onboarding

Onboarding is a **guided wizard with a hub**. A first-time provider walks the ten steps in order;
anyone returning lands on an application overview showing each section's status and can jump
straight to whatever is unfinished.

```
Welcome → phone → OTP
  About you            provider type · your details
  Your work            services · experience · where you work · when you work
  Getting paid         what you earn (read-only) · payout method
  Trust & verification portfolio & qualifications · identity
Review → submit → application status → dashboard
```

**The draft is offline-first.** Every change is written to the device immediately, so entered data
survives route changes, app restarts and no connectivity. Completing a step also pushes that
section to GRID in the background; if the push fails the section is queued and retried on the next
step, on resume, and at submission. Providers work in the field on patchy networks — onboarding
must never block on a request.

**Completeness is server-authoritative.** The review screen shows the app's own validation *and*
`GET /provider-applications/me/readiness`, so what the provider sees matches what submission will
actually accept.

Application status covers the whole lifecycle: under review, more information required,
verification unsuccessful, approved and rejected. `verificationFailed` is derived from a rejected
identity document rather than being a demo-only screen.

## Architecture

```text
lib/
  app/                   App root
  core/
    models/              Domain models, onboarding draft, enums
    routing/             go_router route graph
    theme/               Design tokens (colour, type, spacing, status) and ThemeData
    utils/               Currency/date formatting and validators
    widgets/             Component library, grouped by concern, re-exported by app_widgets.dart
  data/
    api/                 API client, session, repositories, onboarding sync
    country/             Country-agnostic config + Ghana market data and presentation overlay
    repositories/        Repository contract with a mock adapter
  features/
    auth/ onboarding/    Signup, verification and the application flow
    home/                Today: earnings, the most urgent request, the next job
    jobs/                Jobs list, request (accept/decline) and job screens
    earnings/ account/ support/
    main/                Four-tab shell: Home · Jobs · Earnings · Account
  state/                 Riverpod controllers and providers
```

### Design system

Deep navy actions, white working surfaces and one tint per service (mint for cleaning, sky for
laundry), adapted from Hubtel's merchant app. Rationale, tokens and rules are in
[design/REDESIGN.md](design/REDESIGN.md).

Tokens live in `core/theme/app_theme.dart`: colours, service palettes, the `AppText` type scale
(Plus Jakarta Sans with Inter as fallback, tabular figures for money), spacing, radii, control
sizes, and a `StatusKind` enum that pairs every status with an icon or label. Components are grouped
under `core/widgets/` (`layout`, `cards`, `forms`, `feedback`, `onboarding_widgets`, `patterns`,
`branding`) and re-exported through `app_widgets.dart`. Button labels are sentence case, and
widget tests find buttons by that exact copy.

### Catalogue

Which services and coverage areas exist is **decided by the API**, not hardcoded here — the app
reads `GET /service-categories` (top-level rows are services, children are skills; only launched
ones are offered), `GET /service-catalogue` (GRID's package prices and fee, for the earnings
table) and `GET /service-areas`, grouping areas by region for the picker.

`data/country/ghana_presentation.dart` is a presentation overlay keyed by category slug supplying
only what the API has no opinion about: display name, summary and the experience prompt. It is also the allow-list — categories without an entry are not offered in the app.
`data/country/ghana_config.dart` holds market rules — dial code, currency, Mobile Money providers,
banks — and stands in for the catalogue while offline. Launching another market means swapping the
config, not editing widgets.

### API client

`data/api/api_client.dart` attaches the bearer token and a correlation id, unwraps the
`{success, data, error, traceId, timestamp}` envelope, and refreshes an expired access token
exactly once even when several requests fail together — refresh tokens are single-use and rotate,
so parallel refreshes would revoke each other. Failures become `ApiException` carrying the API's
stable `error.code`; callers branch on the code, never the message.

Tokens are held in platform secure storage, never in `shared_preferences`.

## Testing

`flutter test` covers onboarding navigation and validation gating, back-preserves-data,
draft survival across a restart, the OTP error and resend countdown, hub and review state,
double-submit protection, every application-status screen, the first-time dashboard, layout at
320×640 with 1.3× text scale, and the API client's envelope, error, refresh and offline handling.

Widget tests override `apiEnabledProvider` to false, so they need neither a server nor platform
secure storage.

## After approval

Home, Jobs, Earnings, Account and Support read and write through one contract,
`GridRepository`. `ApiGridRepository` talks to GRID; `MockGridRepository` backs "Explore the demo"
and the widget tests. GRID decides which requests a provider sees, what a job pays and which step
comes next (`nextCommand`); the app shows it and sends the step.

There is no push channel, so the tab shell re-reads requests every 30 seconds and whenever the app
comes back to the foreground. `test/live_api_test.dart` drives a real booking through the
repository against a running development API.

## Known limitations

- The provider's base location is the areas chosen in onboarding; the app does not yet send the
  phone's GPS position (the API accepts it).
- Adding a second service, changing areas or changing the payout account goes through support.
- Ratings show "New" until GRID has reviews.

Startup restores saved state with a two-second storage deadline and a two-second server-status
deadline. Catalogue loading runs separately and falls back to bundled Ghana data when unavailable;
it never blocks the splash. Late status responses are discarded after the deadline.
