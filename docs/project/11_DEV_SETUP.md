# 11: Development Setup (Local & Environment)

**Status:** WORKING
**Audience:** All Developers
**Objective:** Ensure any developer can run the User App and Admin App locally with consistent versions and configuration.

---

## 1. Toolchain

- Flutter: **stable channel** (pin exact version per team decision)
- Dart: comes with Flutter
- Android Studio: latest stable (for SDK + emulator)
- Java: use the version required by your Flutter/Android Gradle plugin

---

## 2. Repositories / Apps

- **User App:** `TranZfort/` (Flutter)
- **Admin App:** `Admin/` (Flutter)
- **Backend:** Supabase (Postgres + Auth + Storage + Realtime + Edge Functions)

---

## 3. Supabase Configuration (User App)

### 3.1 Required runtime values

The app must read Supabase URL and anon key from `--dart-define`.

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### 3.2 Example run (Android)

Run from the app folder (example):

- `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

**Rule:** never commit keys in source control.

---

## 4. Supabase Configuration (Admin App)

Admin app uses the same Supabase project.

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

**Note:** Admin privileged operations should use Edge Functions / server-side logic. The Admin Flutter app should not embed a service role key.

---

## 5. Firebase Cloud Messaging (FCM)

Used in Sprint 8.

- Android: add `google-services.json` to each app’s Android module when enabling FCM.
- Do not commit production keys; store per-environment.

---

## 6. Storage Buckets

Create buckets before testing uploads:

- `verification-docs`
- `truck-photos`
- `profile-photos`
- `load-documents`
- `voice-messages`

---

## 7. Required Android Permissions (high-level)

- Location: for bounded GPS triggers
- Camera + Photos: for document uploads
- Microphone: for voice messages / STT
- Notifications: push notifications

---

## 8. Sanity Checks

- App launches to `/splash`
- `flutter analyze` has **0 errors**
- Supabase session can be created (Google or OTP)
- `python scripts/check_layer_boundaries.py` passes
