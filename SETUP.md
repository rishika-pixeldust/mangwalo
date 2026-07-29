# Setup — running MangWalo

MangWalo runs in two modes. **Local-only** needs nothing but Flutter and is the
default; the **shared noticeboard** adds a Supabase project.

---

## 1. Run it locally (no credentials, no accounts)

```bash
flutter pub get
flutter run -d chrome
```

That is genuinely all. Without `.env` the app runs entirely on-device: the
board, the sample listings, the on-device AI suggestions, the privacy scanner
and the rental tracking all work offline. Only the social features (sign-in,
rental requests, messaging) announce that they need a backend.

To build the release bundle:

```bash
flutter build web --release --no-web-resources-cdn
```

`--no-web-resources-cdn` bundles CanvasKit locally instead of fetching it from
gstatic, which keeps the app fully self-contained and offline-capable.

---

## 2. Enable the shared noticeboard

### 2a. Create the project

Supabase → **New project**. Region **South Asia (Mumbai) `ap-south-1`** keeps
latency low for a Mumbai-first product.

### 2b. Apply the schema

Two ways. **The SQL Editor needs no CLI and no access token** — prefer it.

**Option A — Dashboard (recommended)**

1. Dashboard → **SQL Editor** → **New query**
2. Paste all of [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql) → **Run**
3. Repeat with [`supabase/migrations/0002_requests_and_messages.sql`](supabase/migrations/0002_requests_and_messages.sql)

Both scripts are idempotent — every policy is dropped before it is created and
every table uses `if not exists` — so re-running them is safe and is the normal
way to pick up a schema change.

**Option B — CLI**

Needs an interactive login; `npx supabase link` fails with *"Access token not
provided"* until you do this.

```bash
npx supabase login          # opens a browser
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

### 2c. Turn on email sign-in

Dashboard → **Authentication → Providers → Email** → enable.

Then **Authentication → URL Configuration → Redirect URLs**, add every origin
you will sign in from. A magic link only works for an origin listed here:

```
http://localhost:8795
https://mangwalo.vercel.app
```

### 2d. Point the app at it

```bash
cp .env.example .env
```

Fill in from **Settings → API**:

| Key | Value | Why it is safe |
|---|---|---|
| `SUPABASE_URL` | `https://YOUR_REF.supabase.co` | Public |
| `SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_…` | Public by design — it ships in the web bundle and is guarded by RLS, not secrecy |
| `SUPABASE_AUTH_REDIRECT` | the origin you are running on | Public |

> **Never** put the `service_role` key or an `sb_secret_…` key in `.env`, in any
> Dart source, or anywhere near the web build. They bypass RLS entirely. `.env`
> itself is gitignored; only `.env.example` is committed.

Then build with the config injected at compile time:

```bash
flutter run -d chrome --dart-define-from-file=.env
flutter build web --release --no-web-resources-cdn --dart-define-from-file=.env
```

If either value is missing the app silently falls back to local-only mode
rather than erroring — a half-configured build never shows a broken board.

---

## 3. Photo search (Phase C, optional)

Photo search on "Looking for" listings calls a vision model from a Supabase
Edge Function. The API key is a **server-side secret** and must never reach the
client:

```bash
npx supabase secrets set OPENAI_API_KEY=...
```

Set it in your own shell. Without it, photo search reports that it is
unavailable; nothing else is affected.

---

## 4. Verify

```bash
flutter analyze          # expect: no issues
flutter test             # expect: all tests passed
```

Regenerate the demo assets if you changed the UI or the sample set:

```bash
python3 tool/make_seed_images.py                                      # sample imagery
flutter test tool/demo/capture_screens_test.dart --update-goldens      # demo frames
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Access token not provided` | Supabase CLI is not logged in | Use the SQL Editor (2b, Option A), or `npx supabase login` |
| Magic link opens but does not sign in | Origin missing from Redirect URLs | Add the exact origin in 2c |
| Board works but sign-in says it needs a backend | `.env` missing, or built without `--dart-define-from-file=.env` | See 2d |
| `flutter` not found | SDK is not on `PATH` | Use the full path to the Flutter binary |
| Board is empty after switching locality | Working as designed — the board is locality-scoped | Settings → **Show all localities**, or post the first listing |
