# EduGain — client

The EduGain app: a Flutter client that ships as a **Telegram Mini App**, not as
a store app. It runs inside Telegram's in-app browser, signs in with the
`initData` Telegram hands it, and talks to two backend services over HTTPS.

There are `android/`, `ios/` and `windows/` folders because Flutter creates
them. **Nothing is shipped from them today** — the web build is the product.

---

## What it does

| Area | Where |
|---|---|
| AI speaking — voice conversation, adaptive difficulty | `lib/features/speaking/` |
| 1:1 peer calls (WebRTC) | `lib/features/peer/` |
| Group voice rooms (LiveKit) | `lib/features/group/` |
| Course path, lessons, exercises | `lib/features/course/` |
| Vocabulary & grammar games, live quiz | `lib/features/games/`, `lib/features/vocabulary/` |
| XP, streak, leaderboard | `lib/features/gamification/` |
| Accounts, profile, billing | `lib/features/auth/`, `lib/features/profile/` |

Three languages throughout — `en`, `ru`, `uz` — via `gen-l10n`. **`app_en.arb`
is the template**: placeholder metadata (`@key`) belongs there, not in the
others.

## Layout

Feature-first. Inside a feature:

```
data/          HTTP, platform channels, browser APIs. The messy edge.
domain/        models and pure logic. No Flutter, no I/O — this is what tests bite on.
application/   Riverpod providers and controllers.
presentation/  widgets and screens.
```

`lib/core/` is what every feature shares: the API client, the router, the
design system, Telegram interop.

## Running it

```bash
flutter pub get
flutter test          # ~509 tests, all offline
flutter analyze
```

### The web build

The one that ships. **Every flag below is load-bearing:**

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=/api/v1 \
  --base-href=/app/ \
  --pwa-strategy=none \
  --no-tree-shake-icons
cp tool/sw_tombstone.js build/web/flutter_service_worker.js
```

* `--pwa-strategy=none` — `web/index.html` carries a script that unregisters any
  service worker it finds and reloads. Ship a worker and the page reloads every
  three seconds, forever, and the app never reaches its first API call. This
  took production down for real learners once.
* `cp tool/sw_tombstone.js …` — the build writes an *empty* worker, which leaves
  devices that cached an older build pinned to it. The tombstone is a worker
  whose only job is to uninstall its predecessor. Read its header before
  deleting it.
* `--no-tree-shake-icons` — shaking drops icons that ARE referenced, and they
  render as empty circles on the device while the build log looks healthy.
* `--base-href=/app/` — where it is served.

### Developing against the real API

The API sends **no CORS headers** — the app is served from the same origin as
the API in production, so it never needed them. A local `flutter run -d chrome`
therefore cannot call it directly; the browser blocks it.

Run a small reverse proxy locally that serves the Flutter dev output at `/` and
forwards `/api/` to `https://64-226-109-240.sslip.io`, then everything is
same-origin again and `API_BASE_URL=/api/v1` works unchanged.

(If a CORS allowance for a dev origin would be easier, ask — it is a small
server-side change.)

### Signing in outside Telegram

Outside Telegram there is no `initData`, so the normal sign-in cannot run.
For development, get a token from the documented sandbox endpoint and put it
where `TokenStorage` reads from:

```
POST https://64-226-109-240.sslip.io/api/v1/auth/docs-token
Header:  X-Docs-Secret: <the documentation secret>
```

The secret is **not in this repository** and is sent to you separately — see
[docs/ACCESS.md](docs/ACCESS.md) for where to keep it.

It returns a real JWT pair for a sandbox learner — real quotas, real data,
separate from anybody using the app.

## The API

Both services on one page, live:

**https://64-226-109-240.sslip.io/app/api-docs.html**

Raw specs: `/api/ai/openapi.json` (AI service) and `/api/v1/schema` (accounts,
billing, course, games). Both are generated from the running code, so they
cannot drift from what the server actually accepts.

To make **Try it out** work, open `POST /api/v1/auth/docs-token`, put the
documentation secret in the `X-Docs-Secret` field, and paste the `access_token`
it returns into **Authorize** at the top of the page. Every route below then
becomes callable.

**The envelope is the same everywhere:**

```json
{ "data": { ... } }
{ "error": { "code": "...", "message": "...", "details": { } } }
```

Switch on `code`, never on `message` — the message is written for people and is
translated.

**Tokens.** `access_token` lasts 60 minutes, `refresh_token` 30 days. A refresh
token is **single-use**: spending one returns a whole new pair and blacklists
the old, so the client must store both halves every time. On `401`, refresh once
and retry the request; if that also fails, sign in again. `lib/core/api/api_client.dart`
already implements exactly this.

## Testing

Tests carry the reasoning. Many of them exist because something specific went
wrong in production, and the header comment says what — those are worth reading
before changing the code they cover, especially around the microphone
(`going_deaf_test.dart`, `mic_stall_recovery_test.dart`,
`speech_deadlock_test.dart`, `sample_rate_probe_test.dart`).

Golden/screenshot tests are tagged and skipped by default:

```bash
flutter test --tags shot --run-skipped --update-goldens
```

## Things that will bite

* **`dio` does not stream on web.** It hands over the whole response body at
  once, so any reasoning about server-sent events arriving progressively is
  wrong in the browser. This is why the tutor's audio is fetched per sentence
  rather than read off the reply stream.
* **The Telegram WebView has no `speechSynthesis`.** Device text-to-speech works
  on desktop browsers and does not exist inside Telegram on Android, which is
  why speech is fetched from the server there.
* **A capture that delivers silence is not a healthy capture.** A muted track
  keeps delivering buffers of zeros forever and every flag keeps saying
  "listening". See `capture_health.dart`.
