# TranZfort (Flutter)

Marketplace app for suppliers and truckers. **Branch:** `v1-launch`.

## Repo layout

| Path | Purpose |
|------|---------|
| `TranZfort/` | Main Flutter app (this package) |
| `Admin/` | Admin Flutter app |
| `supabase/migrations/` | **Source of truth** for database schema |
| `website/public/` | Privacy + Terms HTML for P0-11 |
| `backend/` | Legacy snapshots only — do not apply; use `supabase db push` |

`old-app-archived/` is excluded from git (see root `.gitignore`).

## Android IDs

- **applicationId** `com.tranzfort.app` — Play Store / Firebase
- **namespace** `com.tranzfort.tranzfort` — Kotlin `MainActivity` package (intentional split; documented in `android/app/build.gradle.kts`)

## Supabase

From repo root: `supabase db push`

## Admin secrets

Use `--dart-define` / CI secrets for Admin Supabase keys. Do not commit `.env`. See `Admin/README.md`.

## Tests

```bash
cd TranZfort
flutter test test/core/utils/sensitive_identifier_display_test.dart
# CI core smoke — see .github/workflows/flutter-test.yml
```
