# 12: Engineering Standards (Maintainability Rules)

**Status:** WORKING
**Audience:** All Developers
**Objective:** Standardize code style and module boundaries so the codebase stays consistent and easy to maintain.

---

## 1. Architecture (Non-negotiable)

Follow `00_CORE_ARCHITECTURE.md` strictly.

- UI must not import `supabase_flutter`.
- UI must not own network state.
- Providers own async state and realtime subscriptions.
- Repositories return `Result<T>`.

---

## 2. Directory Ownership (Option A)

### 2.1 Core

- `lib/src/core/repositories/`
  - Repositories (data access contracts + implementations)
  - No widget imports
  - All Supabase access contained here

- `lib/src/core/services/`
  - Pure utilities/services (storage, location, costing, OSRM)
  - Should not contain feature-specific state

- `lib/src/core/models/`
  - Shared domain models (Freezed + JSON)

- `lib/src/core/error/`
  - `Result<T>` and failure taxonomy

### 2.2 Features

Each feature owns:

- `features/<feature>/presentation/`
- `features/<feature>/providers/`
- Optional `features/<feature>/data/` for feature-local mappers/adapters

---

## 3. Riverpod Conventions

- Provider name: `xxxProvider`
- Notifier name: `XxxNotifier`
- Provider state shape must include (where relevant):
  - `isLoading` / `isSubmitting`
  - `lastError` (as `AppFailureType?` or mapped UI message)
- Widgets:
  - read state via `ref.watch()`
  - call intents via `ref.read(xxxProvider.notifier)`

---

## 4. Error Handling

- Repositories must catch raw exceptions and map to `AppFailureType`.
- UI must never show raw exceptions.
- Do not use `e.toString()` for user-facing messages.

---

## 5. Models

- Prefer Freezed models for domain entities.
- JSON mapping must live in model files.
- Keep DB column names consistent with schema doc (`02_DATABASE_SCHEMA_AND_RLS.md`).

---

## 6. Async + Realtime

- Realtime subscriptions must be provider-owned.
- Ensure proper cleanup on dispose.
- Do not create channels in widgets.

---

## 7. Localization

- User-facing strings must be localized as per `00_CORE_ARCHITECTURE.md`.
- Any text passed to TTS must be emoji-stripped.

---

## 8. Formatting & Linting

- Format: `dart format .`
- Analyze: `flutter analyze`
- No new lints should be introduced without documenting why.

---

## 9. Definition of Done (Engineering)

For each merged PR:

- `flutter analyze` has 0 errors
- `python scripts/check_layer_boundaries.py` passes
- Feature-level manual testing notes recorded in the PR
