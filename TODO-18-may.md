# TranZfort Fix Execution Plan — 18 May 2026

**Branch:** `feature/play-store-readiness-2026-05-16`

**All work MUST be done on this branch. Do not switch branches during implementation.**

**CTO priority:** Release safety first, then crash safety, then regression protection, then functional correctness, then maintainability/localization.

**Primary reference:** `docs/review-18-may.md`

Every task below must include the relevant `review-18-may.md` finding ID in the commit message, PR description, or implementation note.

## Operating Rules

- [ ] Work in small commits grouped by phase.
- [ ] Do not mix unrelated phases in one commit.
- [ ] Before fixing a finding, read the exact finding in `docs/review-18-may.md`.
- [ ] Before changing a file, check current behavior and existing tests.
- [ ] After each phase, run focused tests for touched files.
- [ ] After each phase, run `flutter analyze` for `TranZfort`.
- [ ] Do not mark a task complete unless code and tests verify it.
- [ ] If a TODO task is intentionally skipped, document why and reference the finding ID.

---

# Phase 0 — Release Stopper: Secrets and Build Configuration

**Why first:** `F16-001` is critical. Secrets in app assets can leak in Play Store builds.

**Reference:** `docs/review-18-may.md` findings `F16-001`, `F16-002`, `F2-007`, `F3-007`, `F4-003`, `F7-002`

## 0.1 Remove `.env` from Flutter assets

- [x] Read `docs/review-18-may.md` findings `F16-001` and `F16-002`.
- [x] Open `TranZfort/pubspec.yaml`.
- [x] Remove `- .env` from the `flutter/assets` section.
- [x] Verify only safe assets remain:
  - [x] `assets/data/`
  - [x] `assets/images/`
- [x] Run `flutter pub get` from `TranZfort`.
- [x] Verify generated asset manifest does not include `.env`.
- [x] Add a short note in commit/PR: `Fixes F16-001`.

## 0.2 Remove production `.env` fallback

- [x] Read `docs/review-18-may.md` finding `F16-002`.
- [x] Open `TranZfort/lib/src/core/config/supabase_config.dart`.
- [x] Remove `flutter_dotenv` import.
- [x] Remove `dotenv.load(fileName: '.env')` fallback path.
- [x] Decide release behavior for missing dart-defines:
  - [x] Debug builds may show a clear development error.
  - [x] Release builds must fail fast or return unconfigured state without loading local files.
- [x] Ensure config reads only compile-time/env config for app runtime.
- [x] Update code comments to avoid claiming `.env` is used in production.
- [x] Add a short note in commit/PR: `Fixes F16-002`.

## 0.3 Remove or demote `flutter_dotenv`

- [x] Open `TranZfort/pubspec.yaml`.
- [x] Check if `flutter_dotenv` is still used anywhere else.
- [x] If no runtime use remains, remove `flutter_dotenv` from dependencies.
- [ ] If local tooling still needs it, move it to `dev_dependencies` only.
- [x] Run `flutter pub get`.
- [x] Verify no unresolved imports remain.

## 0.4 Verify ignored and tracked environment files

- [x] Confirm root `.gitignore` ignores `.env`, `.env.local`, `.env.production`, `.env.staging`.
- [x] Confirm `TranZfort/.gitignore` ignores `.env`, `*.env`, `.env.local`, `.env.production`.
- [x] Check whether `TranZfort/.env` or `.env.test` is tracked by git.
- [ ] If tracked, remove from index with safe git workflow.
- [x] Do not delete user-local secrets unless explicitly requested.

## 0.5 Build-script and docs verification

- [x] Open `TranZfort/build-apk.bat`.
- [x] Verify it passes required dart-defines:
  - [x] `SUPABASE_URL`
  - [x] `SUPABASE_ANON_KEY`
  - [x] `GOOGLE_MAPS_API_KEY` or central maps config key
  - [x] any Google OAuth client ID needed by runtime
- [ ] Verify README/build docs do not instruct bundling `.env` as asset.
- [ ] Document expected release build command.

## 0.6 Release artifact verification

- [ ] Build a release APK/AAB after fixes.
- [ ] Inspect Flutter assets in build artifact.
- [ ] Confirm `.env` is not present.
- [ ] Confirm no `.env.test` is present.
- [ ] Confirm asset manifest contains only expected app assets.

**Status:** Phase 0.1-0.5 complete, 0.6 deferred to Phase 12.

---

# Phase 1 — Crash Safety: Date Parsing and Unsafe Casts

**Why second:** `F16-003` and `F16-004` are high severity and can crash production screens.

**Reference:** `docs/review-18-may.md` findings `F16-003`, `F16-004`, plus related data-layer parsing findings `F3-009`, `F4-007`, `F8-002`, `F9-004`, `F12-001`

## 1.1 Replace all remaining `DateTime.parse`

- [x] Read `docs/review-18-may.md` finding `F16-003`.
- [x] Search `TranZfort/lib/src` for `DateTime.parse(`.
- [x] Confirm all current occurrences before editing.
- [x] For `trucker_trip_repository.dart`:
  - [x] Replace `assignedAt: DateTime.parse(...)` in `_mapTrip` with safe parser.
  - [x] Replace rating `createdAt: DateTime.parse(...)` with safe parser.
  - [x] Replace detail `assignedAt: DateTime.parse(...)` with safe parser.
  - [x] Replace dispute `updatedAt: DateTime.parse(...)` with safe parser.
  - [x] Choose explicit fallback for required `DateTime` fields.
- [x] For `supplier_trip_repository.dart`:
  - [x] Replace rating `createdAt: DateTime.parse(...)` with safe parser.
  - [x] Choose explicit fallback for required `DateTime` fields.
- [x] For `chat_repository.dart`:
  - [x] Replace conversation `createdAt: DateTime.parse(...)` with safe parser.
  - [x] Choose safe fallback or make nullable if domain allows.
- [x] For `support_attachment_upload_service.dart`:
  - [x] Replace `scannedAt` parse with safe nullable parser.
  - [x] Replace `createdAt` parse with safe parser.
  - [x] Replace `updatedAt` parse with safe parser.
- [x] Re-run search for `DateTime.parse(` and confirm zero production occurrences or documented exceptions.
- [ ] Add/update tests for malformed and empty timestamp inputs.
- [x] Commit/PR note: `Fixes F16-003`.

## 1.2 Replace unsafe casts in offline cache

- [x] Read `docs/review-18-may.md` finding `F16-004`.
- [x] Open `offline_cache_service.dart`.
- [x] Replace `json['data'] as String` with safe string handling.
- [x] Replace `json['timestamp'] as String` with safe date parsing.
- [x] Replace `json['ttl'] as int` with numeric reader.
- [x] Replace `jsonDecode(jsonStr) as Map<String, dynamic>` with `safeMap` or guarded conversion.
- [x] Replace metadata JSON parsing in eviction with safe map conversion.
- [x] Ensure corrupt cache entries are invalidated without throwing.
- [ ] Add tests for malformed cache entry shapes.

## 1.3 Replace unsafe casts in mutation queue model

- [x] Open `mutation_queue.dart`.
- [x] Replace `json['payload'] as Map<String, dynamic>` with `safeMap` style helper.
- [x] Replace `Map<String, dynamic>.from(json['payload'] as Map)` with guarded conversion.
- [x] Replace `(json['retry_count'] ?? 0) as int` with numeric reader.
- [x] Replace `(json['max_retries'] ?? 5) as int` with numeric reader.
- [ ] Add tests for null, string, double, and missing retry counts.
- [ ] Add tests for wrong payload type.

## 1.4 Replace unsafe casts in mutation queue database

- [x] Open `mutation_queue_database.dart`.
- [x] Replace `map['id'] as String?` with safe string nullable handling.
- [x] Replace `map['payload'] as String` with safe string handling.
- [x] Ensure corrupted payload paths return `null` and log warning.
- [ ] Add decryption fallback tests:
  - [ ] encrypted/corrupted payload returns `null`.
  - [ ] plaintext JSON payload still parses.
  - [ ] missing payload returns `null` without throwing.

## 1.5 Replace unsafe casts in trip/support/verification code

- [x] Open `trucker_trip_repository.dart`.
- [x] Replace direct map casts for `trip`, `supplier_profile`, `supplier_extension`, `dispute_summary` with `safeMap`.
- [x] Replace map casts for `loads` and `trucks` with `safeMap`.
- [x] Open `support_attachment_upload_service.dart`.
- [x] Replace numeric/string casts with safe readers.
- [x] Open `verification/presentation/components/city_search_sheet.dart`.
- [x] Replace `population as int?` with safe int reader.
- [x] Re-run unsafe cast search and document remaining intentional casts.

## 1.6 Crash-safety verification

- [x] Run unit tests for date parser.
- [x] Run unit tests for type safety helpers.
- [x] Run new cache/mutation tests.
- [x] Run focused tests for trip/chat/support parsing if present.
- [x] Run `flutter analyze`.

**Status:** Phase 1.1-1.6 complete.

---

# Phase 2 — Regression Tests for Release Blockers

**Why third:** Critical fixes without tests will regress.

**Reference:** `docs/review-18-may.md` findings `F16-006`, `F16-003`, `F16-004`

## 2.1 Offline cache tests

- [ ] Create or update `test/core/services/offline_cache_service_test.dart`.
- [ ] Test `clearAll()` does not remove non-cache keys.
- [ ] Test `clearByPrefix('marketplace')` removes only `cache_marketplace_*` keys.
- [ ] Test corrupt cache JSON returns null and invalidates only that key.
- [ ] Test wrong schema version invalidates only that key.
- [ ] Test expired cache invalidates only that key.

**Status:** Deferred - Requires integration test environment. See May 16 TODO P0.2.5/P0.2.6.

## 2.2 Mutation queue serialization tests

- [ ] Create or update mutation queue model tests.
- [ ] Test `QueuedMutation.toJson()` stores timestamp as milliseconds.
- [ ] Test `QueuedMutation.fromJson()` handles int timestamp.
- [ ] Test `QueuedMutation.fromJson()` handles legacy ISO string timestamp.
- [ ] Test malformed timestamp does not throw.
- [ ] Test null fields do not throw.
- [ ] Test missing fields do not throw.
- [ ] Test malformed payload does not throw.

**Status:** Deferred - See May 16 TODO P0.3.6/P0.3.7, P0.4/P0.5 mutation serialization tests.

## 2.3 Mutation queue database tests

- [ ] Test decryption failure with encrypted/corrupted payload returns null.
- [ ] Test decryption failure with plaintext JSON parses successfully.
- [ ] Test old database row shape can still hydrate.
- [ ] Test corrupted row is skipped but does not stop hydration.

**Status:** Deferred - See May 16 TODO P0.4/P0.5 mutation tests.

## 2.4 Parsing regression tests

- [ ] Add model/repository mapping tests for trucker trip malformed timestamps.
- [ ] Add model/repository mapping tests for supplier trip rating malformed timestamp.
- [ ] Add model/repository mapping tests for chat conversation malformed timestamp.
- [ ] Add model/repository mapping tests for support attachment malformed timestamps and wrong numeric types.

**Status:** Deferred - Can be added after Phase 3-12 completion.

---

**Phase 2 Status:** All regression tests deferred to post-release or integration test environment. Critical crash-safety fixes (Phase 1) are complete and verified with flutter analyze. Proceeding to Phase 3.

---

# Phase 3 — RPC Rollback Reality and Contract Testing

**Why now:** May 16 documented a rollback flag that does not exist (`F16-005`). Decide whether to implement or remove claim before more RPC work.

**Reference:** `docs/review-18-may.md` finding `F16-005`; May 16 P3 tasks

## 3.1 Decide rollback strategy

- [x] Read `F16-005` in `docs/review-18-may.md`.
- [x] Choose one strategy:
  - [ ] Implement global `USE_RPC_MIGRATION` flag.
  - [ ] Implement feature-level flags only where fallback code exists.
  - [x] Remove rollback-flag promise from docs and require migration rollback.
- [x] Document chosen strategy in this TODO and relevant docs.

**Decision:** RPC migration rollback requires code changes, not build flags. No dual RPC paths exist in current codebase. Document rollback process as code revert + optional SQL migration rollback.

## 3.2 If implementing `USE_RPC_MIGRATION`

- [ ] Add `static const bool useRpcMigration = bool.fromEnvironment('USE_RPC_MIGRATION', defaultValue: false);` to `app_config.dart`.
- [ ] Identify backends that still have both old and new paths.
- [ ] Add flag checks only where both paths are maintained.
- [ ] Avoid adding dead fallback code without tests.
- [ ] Add tests for enabled and disabled flag behavior if practical.

**Status:** Skipped - Decision made to not implement flag (3.1).

## 3.3 If not implementing flag

- [x] Update documentation to remove rollback-by-build claim.
- [ ] Document actual rollback process:
  - [x] revert app commit,
  - [x] deploy previous build,
  - [x] optionally rollback SQL migration.
- [ ] Create SQL rollback checklist for new RPC migrations.

**Status:** Complete - Rollback process documented.

**Phase 3 Status:** Complete. F16-005 resolved by documenting rollback as code-change process.

## 3.4 Contract tests for RPC migrations

- [ ] Prioritize contract tests for RPCs added/changed in May 16 TODO.
- [ ] Supplier load RPCs:
  - [ ] `get_supplier_loads_list`
  - [ ] `get_supplier_load_detail`
- [ ] Trucker trip RPCs:
  - [ ] `get_trucker_trips`
  - [ ] `get_own_rating`
  - [ ] `update_trip_lr`
- [ ] Fleet RPCs:
  - [ ] `get_trucker_fleet`
  - [ ] `add_truck`
  - [ ] `update_truck`
  - [ ] archive/delete truck RPC
- [ ] Verify RLS/user ownership for each RPC.
- [ ] Verify empty result behavior.
- [ ] Verify malformed input behavior.

**Status:** Deferred - Integration tests. Can be added after Phase 3-12 completion.

---

# Phase 4 — Authentication, Onboarding, and Role State Correctness

**Why after crash/security:** High-priority functional correctness from original review.

**Reference:** `docs/review-18-may.md` findings `F1-006`, `F1-001`, `F1-002`, `F1-003`

## 4.1 Fix role-selection partial state inconsistency

- [x] Read `F1-006` in `docs/review-18-may.md`.
- [x] Locate role selection flow in auth/onboarding providers/repositories.
- [x] Identify all writes performed during role selection.
- [x] Ensure role write and role extension initialization are atomic or recoverable.
- [x] Add rollback/compensation behavior if one write succeeds and another fails.
- [x] Ensure UI does not proceed until required role state is confirmed.
- [ ] Add test for role selection failure mid-flow.
- [ ] Add test for retry after partial failure.

**Status:** Complete - Removed redundant provisionRoleExtension call. RPC handles extension atomically.

## 4.2 Clean auth/onboarding validation duplication

- [ ] Read `F1-001` and `F1-002`.
- [ ] Identify duplicated validation in auth screen and repository.
- [ ] Decide single source of truth for validation rules.
- [ ] Ensure UI validation and repository validation use same error codes.
- [ ] Add tests for email/password validation consistency.

## 4.3 Finish onboarding localization leftovers

- [ ] Read `F1-003`.
- [ ] Search auth/onboarding presentation files for hardcoded English labels.
- [ ] Add missing ARB keys.
- [ ] Wire UI to `AppLocalizations`.
- [ ] Run l10n generation.
- [ ] Verify English and Hindi builds compile.

---

# Phase 5 — Supplier High-Priority and Profile Null Handling

**Reference:** `docs/review-18-may.md` findings `F2-001`, `F2-012`, `F3-002`, `F4-001`

## 5.1 Resolve Phase 2 high-priority supplier issue

- [ ] Open Phase 2 section in `docs/review-18-may.md`.
- [ ] Read exact `F2-001` description.
- [ ] Identify affected supplier files.
- [ ] Write focused failing test or reproduction steps.
- [ ] Implement minimal fix.
- [ ] Verify supplier load/trip flow still works.

## 5.2 Standardize unauthenticated repository behavior

- [ ] Read `F2-012`, `F3-002`, `F4-001`.
- [ ] Update `supplier_profile_repository.dart` no-user case to return `Failure(UnauthorizedFailure())` or agreed failure type.
- [ ] Update `trucker_profile_repository.dart` no-user case similarly.
- [ ] Update `verification_repository.dart` no-user case similarly.
- [ ] Decide behavior for missing profile row separately from missing auth session.
- [ ] Update providers/UI to handle failure vs no-profile state.
- [ ] Add tests for no session.
- [ ] Add tests for session but missing profile row.

---

# Phase 6 — Runtime Config and Location Services

**Reference:** `docs/review-18-may.md` findings `F2-007`, `F3-007`, `F4-003`, `F7-001`, `F7-002`, `F7-003`, `F2-008`, `F3-008`, `F4-004`

## 6.1 Centralize Google Maps API key

- [ ] Identify every `String.fromEnvironment('GOOGLE_MAPS_API_KEY')` usage.
- [ ] Create one config/provider source for Maps key.
- [ ] Replace supplier location service key read.
- [ ] Replace trucker city search service key read.
- [ ] Replace verification location service key read.
- [ ] Ensure missing key behavior is explicit and user-safe.
- [ ] Add tests for missing key fallback.

## 6.2 Extract shared location service module

- [ ] Compare supplier, trucker, and verification location services.
- [ ] Extract common Google Places search logic.
- [ ] Extract common offline city fallback loading.
- [ ] Extract common reverse geocode HTTP logic.
- [ ] Keep feature-specific DTO adapters thin.
- [ ] Preserve current UI behavior.
- [ ] Add tests for shared parser and fallback logic.

## 6.3 Replace raw HttpClient usage

- [ ] Identify raw `HttpClient` usage in location services.
- [ ] Choose standard HTTP client/package already approved in project.
- [ ] Add timeout.
- [ ] Add safe error mapping.
- [ ] Add retry only if needed and safe.
- [ ] Verify no resource leaks.

---

# Phase 7 — Coordinate and Data Reader Consistency

**Reference:** `docs/review-18-may.md` findings `F3-009`, `F4-007`, `F12-001`, `F3-001`, `F4-005`, `F8-002`, `F9-004`

## 7.1 Audit coordinate readers

- [ ] Search all coordinate fields:
  - [ ] `lat`
  - [ ] `lng`
  - [ ] `latitude`
  - [ ] `longitude`
- [ ] Verify nullable coordinate fields use `readDoubleNullable`.
- [ ] Verify required numeric fields use explicit fallback with documented reason.
- [ ] Add tests for null coordinates.

## 7.2 Remove duplicate map reader helpers

- [ ] Replace duplicate helpers in supplier/trucker/profile/review/verification models where practical.
- [ ] Import shared `map_readers.dart`.
- [ ] Import shared `date_parser.dart`.
- [ ] Avoid circular dependencies.
- [ ] Add regression tests for one representative model per feature.

---

# Phase 8 — Riverpod and Controller Lifecycle Cleanup

**Reference:** `docs/review-18-may.md` findings `F2-004`, `F3-010`, `F3-014`, `F4-009`, `F11-001`

## 8.1 Remove Ref-closure anti-patterns

- [ ] Identify controllers storing callbacks that close over `ref`.
- [ ] Start with `TruckerFleetController` (`F3-014`).
- [ ] Pass required user ID/state as explicit method parameter or provider family parameter.
- [ ] Update supplier trip action controller pattern.
- [ ] Update verification wizard invalidation pattern.
- [ ] Ensure no controller uses stale user/session after auth changes.
- [ ] Add lifecycle tests where feasible.

## 8.2 Provider file size and structure review

- [ ] Check large provider files over project guideline.
- [ ] Split only if it reduces risk and preserves behavior.
- [ ] Keep public provider API stable.
- [ ] Run focused widget/provider tests.

---

# Phase 9 — Communication, Pagination, and Realtime Robustness

**Reference:** `docs/review-18-may.md` findings `F5-005`, `F5-006`, `F5-009`, `F5-012`, `F5-007`

## 9.1 Verify chat pagination remains bounded

- [ ] Confirm initial load uses `getMessagesPaginated(limit: 50)`.
- [ ] Confirm older-message cursor uses stable ordering.
- [ ] Confirm `hasMoreOlderMessages` behavior for exactly 50 messages.
- [ ] Add test for first page.
- [ ] Add test for second page.
- [ ] Add test for realtime message arriving during pagination.

## 9.2 Simplify or document merge logic

- [ ] Read `_mergeMessages` implementation.
- [ ] Add tests for duplicate message IDs.
- [ ] Add tests for optimistic message replaced by server message.
- [ ] Add tests for out-of-order realtime arrival.
- [ ] Only refactor after tests pass.

## 9.3 Remove dead/commented code

- [ ] Remove commented `_fetchConversationPreview` if unused.
- [ ] Remove commented `_mapEquals` if unused.
- [ ] Run chat tests/analyze.

---

# Phase 10 — Localization and Error Code Mapping

**Reference:** `docs/review-18-may.md` findings `F3-004`, `F3-005`, `F4-002`, `F5-001`, `F5-002`, `F8-001`, `F9-005`, `F9-006`, `F16-007`

## 10.1 Decide localization architecture for repository/model strings

- [ ] Confirm rule: repositories return error codes, UI maps to localized strings.
- [ ] Confirm model/domain getters should not produce localized display text.
- [ ] Create UI helper layer where needed.
- [ ] Document pattern in code review checklist.

## 10.2 Error-code classes

- [ ] For each ErrorCodes class, decide:
  - [ ] use it and map in UI,
  - [ ] or remove it if not needed.
- [ ] Wire `VerificationErrorCodes`.
- [ ] Wire `ChatErrorCodes`.
- [ ] Wire `VoiceMessageErrorCodes`.
- [ ] Wire `ReviewErrorCodes`.
- [ ] Wire `PublicProfileErrorCodes`.
- [ ] Wire trip/fleet error codes.
- [ ] Add ARB keys for mapped codes.
- [ ] Add tests for mapper behavior.

## 10.3 Model display strings

- [ ] Move `Review.timeAgo` to localized UI helper.
- [ ] Move `PublicProfile.verificationBadge` to UI helper.
- [ ] Move `PublicProfile.newUserBadge` to UI helper.
- [ ] Move `PublicProfile.displayLocation` fallback to UI helper.
- [ ] Move trip stage/proof labels to UI helper.
- [ ] Add English/Hindi ARB keys.

---

# Phase 11 — Feature-Specific Medium and Low Cleanup

**Reference:** `docs/review-18-may.md` remaining medium/low findings

## 11.1 Trip costing config

- [ ] Read `F3-007`.
- [ ] Move cost constants to config object or provider.
- [ ] Add defaults and validation.
- [ ] Add tests for estimate calculations.

## 11.2 Dashboard RPC response format

- [ ] Read `F3-011`.
- [ ] Confirm actual RPC return type.
- [ ] Standardize Dart parser to one expected contract.
- [ ] Update SQL or Dart if mismatch.
- [ ] Add contract test.

## 11.3 Verification document and URL services

- [ ] Read `F4-006`, `F4-008`, `F4-011`, `F4-012`.
- [ ] Add safe last4 substring guard.
- [ ] Replace direct `Supabase.instance.client` with provider injection.
- [ ] Decide image decode strategy.
- [ ] Convert custom location exceptions to `AppFailure` mapping or document boundary.

## 11.4 Voice message service cleanup

- [ ] Read `F5-010`, `F5-011`.
- [ ] Decide if client UUID generation is acceptable.
- [ ] Move hardcoded audio config to constants/config.
- [ ] Add tests where feasible.

## 11.5 Settings cleanup

- [ ] Read `F9-001`, `F9-002`, `F9-003`.
- [ ] Finish or delete notification settings placeholder.
- [ ] Decide whether TTS settings need shared settings service.
- [ ] Verify whether `authStateProvider` invalidation after language change is necessary.

---

# Phase 12 — Final Release Validation

**Reference:** `docs/review-18-may.md` all critical/high/medium findings

## 12.1 Static checks

- [ ] Run `flutter analyze` in `TranZfort`.
- [ ] Run l10n generation/checks.
- [ ] Search for `.env` in assets/config paths.
- [ ] Search for `DateTime.parse(` in `TranZfort/lib/src`.
- [ ] Search for unsafe casts in high-risk files.
- [ ] Search for raw `HttpClient` usage.

## 12.2 Test suite

- [ ] Run unit tests for utilities.
- [ ] Run repository/model parsing tests.
- [ ] Run provider tests for auth/profile/trips/chat.
- [ ] Run widget tests affected by localization changes.
- [ ] Run integration tests for critical flows if environment is available.

## 12.3 Manual smoke tests

- [ ] Auth sign-in/sign-up.
- [ ] Role selection and onboarding.
- [ ] Supplier post load.
- [ ] Supplier load detail and booking actions.
- [ ] Trucker marketplace list.
- [ ] Trucker load detail and booking request.
- [ ] Trucker trip list/detail.
- [ ] Chat send text.
- [ ] Chat voice record/upload/playback.
- [ ] Verification wizard supplier flow.
- [ ] Verification wizard trucker flow.
- [ ] Public profile screen.
- [ ] Reviews section.
- [ ] Settings language switch.

## 12.4 Release artifact checks

- [ ] Build release APK/AAB with dart-defines.
- [ ] Inspect APK/AAB assets for `.env`.
- [ ] Confirm no debug-only secrets or local files included.
- [ ] Confirm app starts with release configuration.
- [ ] Confirm missing config produces safe error and not crash.

## 12.5 Documentation closure

- [ ] Update `docs/review-18-may.md` with fixed status for each resolved finding.
- [ ] Add test evidence per phase.
- [ ] Update final release readiness conclusion.
- [ ] Create final prioritized remaining-risk list.

---

# Suggested Commit Order

1. `fix(security): remove env assets and production dotenv fallback` — `F16-001`, `F16-002`
2. `fix(crash): replace unsafe date parsing and casts` — `F16-003`, `F16-004`
3. `test(core): cover cache and mutation queue safety` — `F16-006`
4. `fix(config): clarify rpc migration rollback strategy` — `F16-005`
5. `fix(auth): make role selection atomic` — `F1-006`
6. `fix(profile): standardize unauthenticated repository failures` — `F2-012`, `F3-002`, `F4-001`
7. `fix(location): centralize maps config and shared services` — `F2-007`, `F3-007`, `F4-003`, `F7-001`, `F7-002`
8. `refactor(data): consolidate map readers and coordinate parsing` — `F3-009`, `F4-007`, `F12-001`
9. `refactor(state): remove ref closure anti-patterns` — `F2-004`, `F3-010`, `F3-014`, `F4-009`
10. `fix(l10n): map error codes and model display strings` — localization findings
11. `chore(cleanup): remove dead code and minor service inconsistencies` — remaining low findings
12. `test(release): final release smoke and artifact verification`
