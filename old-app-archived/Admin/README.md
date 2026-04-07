# TranZfort Admin App

## Required runtime configuration

Admin auth/data calls are enabled only when both Supabase keys are provided at run/build time.

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

If these are missing, login is intentionally disabled and the app shows a setup hint.

## Run (debug)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Build APK (release)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Build App Bundle (release)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Security note

- Never hardcode keys in source files.
- Never commit real secrets to git.
- Use CI/CD secret storage for release pipelines.
