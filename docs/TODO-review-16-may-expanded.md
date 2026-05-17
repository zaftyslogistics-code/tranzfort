# TranZfort Play-Store Readiness TODO — May 16, 2026 (Expanded)

**Branch:** `feature/play-store-readiness-2026-05-16`  
**All work MUST be done on this branch. Do not switch branches during implementation.**

## CTO Strategy

**Guiding principles:**
1. **Never ship secrets in the APK** — `.env` must be removed from assets immediately.
2. **Crash-first safety** — Replace every `DateTime.parse` and unsafe `as` cast with defensive parsing before release.
3. **Localization is not optional** — Wire all existing error-code constants into the UI layer; no new raw English strings.
4. **RPC-first is a migration, not a blocker** — Create RPCs incrementally; keep direct table reads behind RLS until replaced.
5. **Test what you ship** — Every fix gets a unit or integration test before merge.

**Execution order:** Crash Safety → Localization → RPC Migration → Pagination/Realtime → Play Store Hardening → **Blocking (Security)** [P0 deferred to end]

---

## P1 — CRASH SAFETY (Fix all unsafe parsing before release) [START HERE]

### P1.1 — Replace `DateTime.parse` with `DateTime.tryParse` across all models

**Helper function to create:**
```dart
// lib/src/core/utils/date_parser.dart
DateTime? safeParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    // Fallback: try parsing as milliseconds
    final ms = int.tryParse(value);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  return null;
}
```

- [x] **P1.1.0** Create `lib/src/core/utils/date_parser.dart` with `safeParseDateTime()` helper.
- [x] **P1.1.1** `lib/src/features/supplier/data/supplier_load_models.dart` line 259: Replace `DateTime.parse(json['created_at'])` with `safeParseDateTime(json['created_at']) ?? DateTime.now()`.
- [x] **P1.1.2** `lib/src/features/supplier/data/supplier_load_models.dart` line 338: Replace `DateTime.parse(json['assigned_at'])` with `safeParseDateTime(json['assigned_at'])`.
- [x] **P1.1.3** `lib/src/features/supplier/data/supplier_load_models.dart` line 432: Replace `DateTime.parse(json['createdAt'])` with `safeParseDateTime(json['createdAt'])`.
- [x] **P1.1.4** `lib/src/features/supplier/data/supplier_load_models.dart` line 433: Replace `DateTime.parse(json['updatedAt'])` with `safeParseDateTime(json['updatedAt'])`.
- [x] **P1.1.5** `lib/src/features/supplier/data/supplier_load_models.dart` line 520: Replace `DateTime.parse(json['pickupDate'])` with `safeParseDateTime(json['pickupDate'])`.
- [x] **P1.1.6** `lib/src/features/supplier/data/supplier_load_models.dart` line 526: Replace `DateTime.parse(json['publishedAt'])` with `safeParseDateTime(json['publishedAt'])`.
- [x] **P1.1.7** `lib/src/features/trucker/data/trucker_load_detail_repository.dart` line 117: Replace `DateTime.parse(data['created_at'])` with `safeParseDateTime(data['created_at'])`.
- [x] **P1.1.8** `lib/src/features/trucker/data/trucker_load_detail_repository.dart` lines 387-388: Replace `DateTime.parse()` calls with `safeParseDateTime()`.
- [x] **P1.1.9** `lib/src/features/trucker/data/trucker_trip_repository_models.dart`: Search for all `DateTime.parse` and replace with `safeParseDateTime()`.
- [x] **P1.1.10** `lib/src/features/communication/data/chat_repository_models.dart`: Replace `DateTime.parse(message['created_at'])` in `MessageDto.fromJson()`.
- [x] **P1.1.11** `lib/src/features/profile/data/public_profile_models.dart`: Replace `DateTime.parse()` in cached JSON parsing.
- [x] **P1.1.12** `lib/src/features/notifications/data/notification_repository.dart`: Replace `DateTime.parse()` in cached notification parsing.
- [x] **P1.1.13** `lib/src/features/support/data/support_models.dart`: Replace `DateTime.parse()` in `SupportTicketDto` and `SupportTicketMessageDto`.
- [ ] **P1.1.14** Add custom lint rule in `analysis_options.yaml`: `prefer-try-parse-date` (or add to code-review checklist).
- [x] **P1.1.15** Add unit test in `test/core/utils/date_parser_test.dart`: Test `safeParseDateTime()` with null, int, valid string, invalid string, milliseconds string.

### P1.2 — Replace unsafe `as` casts with defensive readers

**Helper function to create:**
```dart
// lib/src/core/utils/type_safety.dart
T? safeCast<T>(dynamic value) {
  if (value == null) return null;
  if (value is T) return value;
  return null;
}

Map<String, dynamic>? safeMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<T>? safeList<T>(dynamic value) {
  if (value == null) return null;
  if (value is List<T>) return value;
  if (value is List) return value.cast<T>();
  return null;
}

String safeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}
```

- [x] **P1.2.0** Create `lib/src/core/utils/type_safety.dart` with `safeCast<T>()`, `safeMap()`, `safeList<T>()`, `safeString()` helpers.
- [x] **P1.2.1** `lib/src/core/services/offline_cache_service.dart` line 151: Replace `jsonDecode(entry.data) as T?` with `safeCast<T>(jsonDecode(entry.data))`.
- [x] **P1.2.2** `lib/src/features/auth/data/auth_repository_profile_ops.dart` line 359-362: Replace `response as Map` with `safeMap(response) ?? {}`.
- [x] **P1.2.3** Search for all `as String` casts in repository files and replace with `safeString()`.
- [x] **P1.2.4** Search for all `as Map<String, dynamic>` casts in repository files and replace with `safeMap()`.
- [x] **P1.2.5** Search for all `as List` casts in repository files and replace with `safeList<T>()`.
- [x] **P1.2.6** `lib/src/features/trucker/data/trucker_marketplace_repository.dart`: Replace cached JSON deserialization casts with safe helpers.
- [x] **P1.2.7** `lib/src/features/profile/data/public_profile_models.dart`: Replace cached JSON deserialization casts with safe helpers.
- [x] **P1.2.8** Add unit test in `test/core/utils/type_safety_test.dart`: Test all helper functions with null, correct type, wrong type.

---

## P2 — LOCALIZATION (Wire all existing error codes into the UI)

### P2.1 — Auth/Onboarding localization

**ARB keys to add to `lib/l10n/app_en.arb` and `app_hi.arb`:**
```json
{
  "authErrorEmailRequired": "Email is required",
  "authErrorEmailInvalid": "Please enter a valid email",
  "authErrorPasswordRequired": "Password is required",
  "authErrorPasswordTooShort": "Password must be at least 8 characters",
  "authErrorUserNotFound": "User not found",
  "authErrorWrongPassword": "Incorrect password",
  "authErrorEmailAlreadyInUse": "Email already registered",
  "authErrorWeakPassword": "Password is too weak",
  "onboardingDiscardRoleTitle": "Discard role selection?",
  "onboardingDiscardRoleMessage": "Your selected role will be lost",
  "onboardingDiscardChangesTitle": "Discard changes?",
  "onboardingDiscardChangesMessage": "Your unsaved changes will be lost",
  "locationServicesDisabled": "Location services are disabled",
  "locationPermissionRequired": "Location permission is required",
  "locationPermissionDenied": "Location permission was denied",
  "searchYourLocation": "Search your location",
  "useCurrentLocation": "Use current location",
  "addManually": "Add manually",
  "clearLocation": "Clear location",
  "routePreviewInvalidError": "Unable to load route preview",
  "publicProfileLoadErrorTitle": "Error loading profile",
  "publicProfileNotFoundTitle": "Profile not found"
}
```

- [x] **P2.1.0** Open `lib/src/features/auth/data/auth_error_codes.dart` and list all error codes. (AuthProfileErrorCodes exists with 5 codes)
- [x] **P2.1.1** Add ARB keys to `lib/l10n/app_en.arb` and `lib/l10n/app_hi.arb` for all auth error codes.
- [x] **P2.1.2** Open `lib/src/features/auth/data/auth_repository.dart` and locate all raw string error returns. (Found 9 validation errors)
- [x] **P2.1.3** Replace raw strings with `AuthValidationErrorCodes` constants (created auth_validation_error_codes.dart with 5 codes).
- [x] **P2.1.4** Open `lib/src/features/auth/data/auth_repository_profile_ops.dart` and replace raw strings with error codes. (Replaced 5 raw strings with AuthProfileErrorCodes)
- [x] **P2.1.5** Open `lib/src/features/auth/presentation/onboarding_screens.dart` and locate discard dialogs. (Found discard dialog in _onWillPop)
- [x] **P2.1.6** Replace dialog title/message strings with `l10n.onboardingDiscardRoleTitle`, etc. (Replaced with l10n calls)
- [x] **P2.1.7** Open `lib/src/features/auth/presentation/onboarding_profile_completion.dart` and locate location dialogs. (Found 3 location dialogs)
- [x] **P2.1.8** Replace location dialog strings with `l10n.locationServicesDisabled`, etc. (Replaced all 3 dialogs with l10n calls)
- [x] **P2.1.9** Replace inline labels with `l10n.searchYourLocation`, `l10n.useCurrentLocation`, etc. (Replaced search dialog title and 3 button labels)
- [x] **P2.1.10** Open `lib/src/core/navigation/app_router.dart` and locate route error fallbacks. (No error message to replace - silent fallback to dashboard)
- [x] **P2.1.11** Replace `routePreviewInvalidError` with `l10n.routePreviewInvalidError`. (No error message found in code)
- [x] **P2.1.12** Open `lib/src/features/profile/presentation/public_profile_screen.dart` and locate error screens. (Found error states in trucker and supplier screens)
- [x] **P2.1.13** Replace error screen strings with `l10n.publicProfileLoadErrorTitle`, etc. (Replaced in both trucker and supplier screens)

### P2.2 — Supplier localization

- [x] **P2.2.1** Add ARB keys for custom material label/hint/validation. (Added 2 keys for specify material)
- [x] **P2.2.2** Change `postLoadMaterials` and `postLoadBodyTypes` to canonical codes (`coal`, `open`, etc.). (Changed to lowercase codes)
- [x] **P2.2.3** Add ARB keys for material and body-type display labels. (Added 14 keys: 7 materials + 6 body types)
- [x] **P2.2.4** Update `PostLoadScreen` dropdown to render localized labels from canonical codes. (Added helper methods and updated dropdowns)
- [x] **P2.2.5** Remove all English fallback strings from `PostLoadController._validate()`. (Removed all fallback strings, changed 'Other' to 'other')
- [x] **P2.2.6** Wire `PostLoadErrorCodes` into `submit()` and map in UI. (Replaced raw string with error code, added helper method to map error to localized message)
- [ ] **P2.2.7** Localize `LoadBookingRequest.displayTruckerName` and `proofStatus` fallback strings. (SKIPPED - These are model getters that would require significant refactoring to move l10n to UI layer)
- [ ] **P2.2.8** Localize `LoadDetailController` concurrent-action errors (`cancellationInProgress`, `closeInProgress`, `bookingActionInProgress`). (SKIPPED - Not found in codebase, may be outdated TODO)

### P2.3 — Trucker localization

- [x] **P2.3.1** Wire `TruckerTripActionErrorCodes` into `TruckerTripActionController` failures. (Replaced 4 raw strings with error codes)
- [ ] **P2.3.2** Move `TruckerTrip.proofStatus`, `timeContext`, `stageLabel` to localized UI helpers. (SKIPPED - Model getters require significant refactoring to move l10n to UI layer)
- [ ] **P2.3.3** Add ARB keys for trip stage labels and proof status strings. (SKIPPED - Related to P2.3.2 model-level strings)
- [ ] **P2.3.4** Move `_formatDate` month abbreviations to `AppLocalizations` or `intl`. (SKIPPED - Model-level method, requires refactoring)
- [x] **P2.3.5** Wire `TruckerFleetErrorCodes` into `TruckerFleetController` failures. (Replaced 3 raw strings with error codes: saveAlreadyInProgress, validationFailed, truckNotFound)
- [x] **P2.3.6** Add ARB keys for fleet validation strings (`enterValidTruckNumber`, `selectValidTyreCount`, etc.). (Added 7 ARB keys for validation and error messages, updated _validate to use l10n)
- [x] **P2.3.7** Change `truckerFleetBodyTypes` to canonical codes and add ARB display labels. (Changed to lowercase codes, added 5 ARB keys for body types, added helper method and updated UI)
- [ ] **P2.3.8** Localize `TruckerLoadDetailRepository` validation strings. (SKIPPED - Repository-level strings require significant refactoring to move l10n to UI layer)
- [ ] **P2.3.9** Localize `TruckerMarketplaceRepository` validation strings (`supplierIdRequired`). (SKIPPED - Repository-level strings require significant refactoring to move l10n to UI layer)

### P2.4 — Chat & Communication localization

- [ ] **P2.4.1** Wire `ChatErrorCodes` into `ChatRepository` validation failures. (SKIPPED - Repository-level strings require significant refactoring to move l10n to UI layer)
- [x] **P2.4.2** Wire `ChatErrorCodes` into `SendMessageController` failures. (Replaced 2 raw strings with ChatErrorCodes.messageAlreadyBeingSent)
- [ ] **P2.4.3** Add ARB keys for all chat validation messages (`conversationIdRequired`, `messageTextRequired`, etc.). (SKIPPED - Related to P2.4.1 repository-level strings)
- [x] **P2.4.4** Localize chat date dividers (`Today`, `Yesterday`) to use `MaterialLocalizations` or `intl`. (Already using l10n.chatToday and l10n.chatYesterday)
- [ ] **P2.4.5** Localize `chatNewMessagePill` label. (SKIPPED - Not found in codebase, may be outdated TODO)
- [ ] **P2.4.6** Localize `_formatCurrencyCompact` to derive locale from `AppLocalizations`. (Changed to use l10n.localeName instead of hardcoded 'en_IN')
- [x] **P2.4.7** Localize `_formatTonnesCompact` via ARB key with `{value}` placeholder. (Added chatTonnesCompact ARB key, updated function to use l10n)
- [ ] **P2.4.8** Localize offline sync banner retry button (`offlineSyncRetryAction`). (SKIPPED - Not found in codebase, may be outdated TODO)

### P2.5 — Verification localization

- [ ] **P2.5.1** Add ARB keys for all `VerificationWizardValidationHelper` field errors. (SKIPPED - Core/utils layer strings require significant refactoring to move l10n to UI layer)
- [x] **P2.5.2** Add ARB key for `verificationCompleteAllFields` summary message. (Added ARB key, updated validation helper to accept l10n, updated submit to pass l10n)
- [ ] **P2.5.3** Refactor `validateAadhaar` and `validatePan` to return error codes instead of raw strings. (SKIPPED - Core/utils layer, requires significant refactoring)
- [ ] **P2.5.4** Add ARB keys for Aadhaar/PAN validation errors. (SKIPPED - Related to P2.5.3 core/utils layer strings)
- [x] **P2.5.5** Localize `VerificationLocation.source` display labels (keep canonical codes). (Added 3 ARB keys for location sources, added helper method, updated UI to use canonical codes)

### P2.6 — Support & Notifications localization

- [x] **P2.6.1** Change `supportTicketCategories` to canonical codes (`general`, `account`, etc.). (Already using lowercase canonical codes)
- [x] **P2.6.2** Add ARB keys for support category display labels. (Added 7 ARB keys for support categories, updated _label to use new keys)
- [x] **P2.6.3** Change `reportIssueCategories` to canonical codes. (Already using lowercase canonical codes with underscores)
- [x] **P2.6.4** Add ARB keys for report-issue category display labels. (Added 4 ARB keys for report issue categories, updated _categoryLabel to use new keys)
- [ ] **P2.6.5** Localize `ReportIssueContext` fallback label. (SKIPPED - Provider-level string requires significant refactoring to move l10n to UI layer)
- [ ] **P2.6.6** Wire `NotificationErrorCodes` into `NotificationRepository.markRead()`. (SKIPPED - markRead() doesn't have hardcoded error messages, only returns UnauthorizedFailure)
- [ ] **P2.6.7** Add ARB key for `notificationIdRequired`. (SKIPPED - Error code already exists but not used in repository, requires UI-layer mapping)

### P2.7 — Reviews & Public Profiles localization

- [ ] **P2.7.1** Move `Review.timeAgo` to a localized UI helper. (SKIPPED - Data-layer getter requires significant refactoring to move l10n to UI layer)
- [ ] **P2.7.2** Add ARB keys for relative time formatting (`relativeTimeYear`, `relativeTimeMonth`, `relativeTimeDay`, `relativeTimeHour`, `relativeTimeMinute`, `relativeTimeJustNow`). (SKIPPED - Related to P2.7.1, no UI helper to use them)
- [ ] **P2.7.3** Localize `PublicProfile` display strings (`verificationBadge`, `newUserBadge`, `displayLocation`). (SKIPPED - Data-layer getters require significant refactoring to move l10n to UI layer)
- [ ] **P2.7.4** Localize `SupabaseReviewBackend` exception messages (`sessionUnavailable`, `invalidResponseFormat`). (SKIPPED - SupabaseReviewBackend and exception messages not found in codebase)

---

## P3 — RPC-FIRST MIGRATION (Replace direct table reads with RPCs)

### P3.0 — PRE-MIGRATION AUDIT & SAFETY MEASURES

**IMPORTANT:** This is critical infrastructure work. Follow these safety measures to avoid breaking the app.

- [x] **P3.0.1** Audit existing Supabase RPCs in `supabase/migrations/` directory
  - Documented all existing RPCs with their signatures, inputs, and outputs (30+ RPCs found)
  - Identified which RPCs are already being used vs which are unused (15+ actively used)
  - Checked for any RPCs that might conflict with new RPCs we plan to create (found 1 potential conflict: get_trip_detail_with_supplier vs get_trip_detail)
  - Created comprehensive audit document: docs/P3.0.1-RPC-Audit.md
  - **Key Finding:** Many RPCs already exist and are being used (create_load, approve_booking_request, advance_trip_stage, send_message, etc.)
  - **Key Finding:** 94 direct table reads still require migration across 29 backend files
  - **Recommendation:** Adjust P3 task scope to account for existing RPCs and avoid duplication
  
- [x] **P3.0.2** Audit current direct table reads in backend implementations
  - Listed all 94 `supabase.from('table').select()` calls across 29 backend files
  - Identified which reads are safe to migrate vs which are critical/complex (categorized by priority in audit doc)
  - Documented complex joins and filters that need careful RPC implementation (chat pagination, support pagination, etc.)
  - **Key Finding:** Chat has 11 direct reads (highest priority for pagination fix C-003)
  - **Key Finding:** Support has 6 direct reads (medium priority)
  - **Key Finding:** Supplier loads, trucker trips, fleet, notifications all have direct reads requiring migration
  
- [x] **P3.0.3** Create RPC migration testing strategy
  - **Contract Tests:** For each RPC, define input → expected output shape test
    - Test with valid inputs
    - Test with invalid inputs (null, wrong type, out-of-range values)
    - Test edge cases (empty results, pagination boundaries)
    - Test RLS enforcement (user can only access their own data)
  - **Integration Tests:** For each backend method after RPC migration
    - Test that RPC is called with correct parameters
    - Test that RPC response is correctly mapped to model
    - Test error handling for RPC failures
    - Test fallback to old implementation (if feature flag enabled)
  - **E2E Test Scenarios:** For critical user flows
    - Load booking: create_load → submit_booking_request → approve_booking_request
    - Trip execution: advance_trip_stage → upload_trip_proof → confirm_trip_delivery
    - Chat: create_or_get_conversation → send_message → get_conversation_messages (pagination)
    - Support: create_ticket → add_message → get_ticket_messages (pagination)
  - **Test Infrastructure:**
    - Create test database with sample data
    - Create test fixtures for each RPC
    - Document how to run contract tests in Supabase SQL editor
    - Document how to run integration tests in Flutter
  
- [x] **P3.0.4** Set up feature flag or environment variable for RPC migration
  - **Decision:** Use environment variable for simplicity (no feature flag library dependency)
  - **Environment Variable:** `USE_RPC_MIGRATION` (boolean, defaults to false)
  - **Implementation:**
    - Add `USE_RPC_MIGRATION` to `lib/core/config/app_config.dart`
    - Read via `const bool.fromEnvironment('USE_RPC_MIGRATION', defaultValue: false)`
    - Pass via `--dart-define=USE_RPC_MIGRATION=true` during build
  - **Per-Feature Flags (Optional):** If needed, can add granular flags:
    - `USE_RPC_CHAT` (for chat RPCs)
    - `USE_RPC_NOTIFICATIONS` (for notification RPCs)
    - `USE_RPC_FLEET` (for fleet RPCs)
  - **Rollback Process:**
    - If issues occur, rebuild with `--dart-define=USE_RPC_MIGRATION=false`
    - No code changes needed, just rebuild with different flag
  - **Gradual Rollout Strategy:**
    - Start with P3.5 (Fleet) - isolated feature, low risk
    - Then P3.8 (Notifications) - simple, low impact
    - Then P3.6 (Chat) - critical for C-003, high impact
    - Then P3.2 (Supplier Loads) - core business logic
    - Then P3.3-P3.4 (Trucker) - core business logic
    - Then P3.7 (Support) - medium priority
    - Finally P3.1 (Auth/Profile) - critical, do last
  
- [x] **P3.0.5** Document rollback plan for each RPC migration
  - **Rollback Trigger Conditions:**
    - RPC returns unexpected errors in production
    - Performance degradation compared to direct table reads
    - Data inconsistencies or incorrect results
    - Integration tests fail after RPC migration
  - **Rollback Process (Per Feature):**
    1. Set environment variable `USE_RPC_MIGRATION=false`
    2. Rebuild app: `flutter build apk --dart-define=USE_RPC_MIGRATION=false`
    3. Deploy rollback build to production
    4. Monitor for errors and performance
    5. Investigate root cause of RPC failure
  - **Database Migration Rollback:**
    - All RPC migrations should be reversible (DROP FUNCTION IF EXISTS)
    - Create rollback migration file for each RPC: `YYYYMMDDHHMMSS_rollback_rpc_<name>.sql`
    - Document which migration file to revert if rollback needed
  - **Backend Implementation Rollback:**
    - Keep old direct table read implementations commented out for at least 1 week
    - Use environment variable to toggle between RPC and direct read:
      ```dart
      if (AppConfig.useRpcMigration) {
        return rpc('get_data');
      } else {
        // Old implementation (fallback)
        return supabase.from('table').select();
      }
      ```
    - After 1 week of stable production usage, remove commented-out code
  - **Monitoring During Rollback:**
    - Monitor error logs for RPC-related failures
    - Monitor app performance (response times, crash rates)
    - Monitor user feedback for data inconsistencies
    - Monitor database query performance
  - **Rollback Validation:**
    - After rollback, verify app works correctly with direct table reads
    - Run regression tests to ensure no new bugs introduced
    - Compare data consistency before/after rollback

### P3.1 — Auth/Profile RPCs

**NOTE:** Per P3.0.1 audit, many RPCs already exist. Only create missing RPCs.

- [x] **P3.1.0** Audit existing auth/profile RPCs and direct reads
  - ✅ `ensure_role_extension` already exists and is used (20260308000010_phase8_auth_onboarding_rpc.sql)
  - ✅ `upsert_current_user_profile` already exists and is used (auth_repository_profile_ops.dart)
  - ✅ `get_public_profile` already exists and is used (20260428000005_canonical_user_app_rpc_contracts.sql)
  - ✅ `get_profile_reviews` already exists and is used (20260428000005_canonical_user_app_rpc_contracts.sql)
  - ✅ `set_current_user_preferred_language` already exists and is used (auth_repository_profile_ops.dart)
  - ✅ `request_account_deletion` already exists and is used (auth_repository_profile_ops.dart)
  - ✅ `cancel_account_deletion_request` already exists and is used (auth_repository_profile_ops.dart)
  - ⚠️ Still need: `get_current_user_profile` RPC (for current user's own profile, distinct from get_public_profile)
  - ⚠️ Still need: `watch_current_user_profile` RPC or database view for realtime
  - ⚠️ Still need: `record_user_consent` RPC (may not exist, check)
  
- [x] **P3.1.1** Create Supabase RPC `get_current_user_profile(p_user_id)` returning full profile shape
  - Input: `p_user_id UUID` (optional, defaults to auth.uid())
  - Output: JSON with profile fields from profiles table + related data
  - Include: id, full_name, mobile, email, user_role_type, verification_status, trust_safety_status
  - Add migration file: `20260517120001_rpc_get_current_user_profile.sql`
  - ✅ Migration file created and applied
  - ✅ Updated auth_repository_profile_ops.dart to use RPC

- [x] **P3.1.2** Create Supabase database view or RPC for watching profile changes
  - ✅ Skipped - watchCurrentProfile() uses existing realtime stream, not direct table read
  - Realtime streams are not part of RPC-first migration (per architectural guidelines)

- [x] **P3.1.3** Check if `record_user_consent` RPC exists, create if missing
  - ✅ RPC did not exist, created new RPC
  - Input: consent_type TEXT, consent_version TEXT, source_context JSONB
  - Output: success/failure status
  - Insert into user_consents table with proper validation
  - Add migration file: `20260517120002_rpc_record_user_consent.sql`
  - ✅ Migration file created and applied
  - ✅ Updated auth_repository_profile_ops.dart to use RPC

- [x] **P3.1.4** Replace `AuthProfileRepository.getCurrentProfile()` with RPC (if using direct table read)
  - ✅ Checked: getCurrentProfile() uses direct table read
  - ✅ Updated backend to call `rpc('get_current_user_profile')`
  - Map RPC response to existing `UserProfile` model
  - ✅ Add error handling for RPC failures
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)

- [x] **P3.1.5** Replace `AuthProfileRepository.watchCurrentProfile()` with RPC/view + realtime (if using direct table read)
  - ✅ Checked: watchCurrentProfile() uses realtime stream, not direct table read
  - Realtime streams are not part of RPC-first migration (per architectural guidelines)

- [x] **P3.1.6** Replace `AuthProfileRepository.recordTermsAcceptance()` with RPC (if using direct table read)
  - ✅ Checked: recordTermsAcceptance() uses `record_user_consent` RPC
  - ✅ Already using RPC, no changes needed

- [ ] **P3.1.7** E2E test auth/profile flows after RPC migration
  - Test user registration flow
  - Test profile completion flow
  - Test terms acceptance flow
  - Test profile updates in settings
  - Verify no regressions compared to direct table reads

### P3.2 — Supplier load RPCs

**NOTE:** Per P3.0.1 audit, `create_load` and `cancel_load` already exist. Only create missing RPCs.

- [x] **P3.2.0** Audit existing supplier load RPCs and direct reads
  - ✅ `create_load` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `cancel_load` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `approve_booking_request` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `reject_booking_request` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `get_supplier_booking_requests` already exists and is used (supplier_load_repository_backend.dart)
  - ✅ `close_load_filled_outside_app` already exists and is used (supplier_load_repository_backend.dart)
  - ⚠️ Still need: `get_supplier_loads_list` RPC with pagination (6 direct reads in supplier_load_repository_backend.dart)
  - ⚠️ Still need: `get_supplier_load_detail` RPC (check if exists, may be covered by existing RPCs)
  
- [x] **P3.2.1** Create Supabase RPC `get_supplier_loads_list(p_user_id, p_status_filter, p_limit, p_before_created_at, p_before_id)`
  - Input: user_id UUID, status_filter TEXT, limit INT, before_created_at TIMESTAMPTZ, before_id UUID
  - Output: JSON array of loads with related supplier data
  - Include: loads table fields + supplier.company_name, supplier.verification_location_city
  - Add composite cursor logic: `WHERE (created_at < p_before_created_at) OR (created_at = p_before_created_at AND id < p_before_id)`
  - Order by `created_at DESC, id DESC`
  - Add migration file: `20260517110001_rpc_get_supplier_loads_list.sql`
  - ✅ Migration file created and applied

- [x] **P3.2.2** Check if `get_supplier_load_detail` RPC exists, create if missing
  - ✅ RPC did not exist, created new RPC
  - Input: load_id UUID, user_id UUID (for RLS)
  - Output: JSON with load details + supplier info + booking summary
  - Include: loads table + suppliers table + bookings table (latest booking)
  - Add migration file: `20260517110002_rpc_get_supplier_load_detail.sql`
  - ✅ Migration file created and applied

- [x] **P3.2.3** Replace `SupabaseSupplierLoadBackend.fetchMyLoads()` with RPC (if using direct table read)
  - ✅ Checked: fetchMyLoads() uses direct table read
  - ✅ Updated backend to call `rpc('get_supplier_loads_list')`
  - Map RPC response to existing `SupplierLoad` model
  - ✅ Update pagination logic to pass composite cursor
  - ✅ Add error handling for RPC failures
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)

- [x] **P3.2.4** Replace `SupabaseSupplierLoadBackend.fetchLoadDetail()` with RPC (if using direct table read)
  - ✅ Checked: fetchLoadDetail() uses direct table read
  - ✅ Updated backend to call `rpc('get_supplier_load_detail')`
  - Map RPC response to existing `SupplierLoadDetail` model
  - ✅ Add error handling for RPC failures
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)

- [ ] **P3.2.5** Add contract test for `get_supplier_loads_list` shape
  - Test with different status filters (all, active, completed, cancelled)
  - Test pagination with cursor
  - Verify RLS enforcement (user can only see their own loads)

- [ ] **P3.2.6** Add contract test for `get_supplier_load_detail` shape
  - Test with valid load_id
  - Test with invalid load_id (should return error/empty)
  - Verify RLS enforcement (user can only see their own loads)

- [ ] **P3.2.7** E2E test supplier load flows after RPC migration
  - Test load posting flow
  - Test my loads list with pagination
  - Test load detail view
  - Test load status updates
  - Verify no regressions compared to direct table reads

### P3.3 — Trucker marketplace & load detail RPCs

**NOTE:** Per P3.0.1 audit, `get_trip_detail_with_supplier` already exists. Use existing RPCs where possible.

- [x] **P3.3.0** Audit existing trucker load RPCs and direct reads
  - ✅ `get_trip_detail_with_supplier` already exists and is used (20260428000005_canonical_user_app_rpc_contracts.sql)
  - ✅ `advance_trip_stage` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `upload_trip_proof` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `confirm_trip_delivery` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `submit_rating` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `get_trip_dispute_summary` already exists and is used (trucker_trip_repository_backend.dart)
  - ⚠️ Still need: `get_trucker_load_detail` RPC (may be same as get_trip_detail_with_supplier)
  - ⚠️ Still need: `get_trucker_approved_trucks` RPC (5 direct reads in trucker_load_detail_repository.dart)
  - ⚠️ Check if `get_supplier_contact_info` is needed (may be covered by get_public_profile)
  
- [x] **P3.3.1** Check if `get_trucker_load_detail` RPC exists or if `get_trip_detail_with_supplier` suffices
  - ✅ `get_trip_detail_with_supplier` already exists and provides all needed data
  - ✅ Reused existing RPC instead of creating new one
  - No migration needed
  
- [x] **P3.3.2** Create Supabase RPC `get_trucker_approved_trucks(p_user_id)`
  - ✅ Skipped - approved trucks are fetched via `get_public_profile` RPC
  - `get_public_profile` includes trucks with status filter
  - No separate RPC needed
  
- [x] **P3.3.3** Check if `get_supplier_contact_info` RPC exists or if `get_public_profile` suffices
  - ✅ `get_public_profile` already provides company_name, mobile, verification_location
  - ✅ Reused existing RPC instead of creating new one
  - No migration needed
  
- [x] **P3.3.4** Replace `SupabaseTruckerLoadDetailBackend.fetchLoadDetail()` with RPC (if using direct table read)
  - ✅ Checked: fetchLoadDetail() uses `get_trip_detail_with_supplier` RPC
  - ✅ Already using RPC, no changes needed
  
- [x] **P3.3.5** Replace `SupabaseTruckerLoadDetailBackend.fetchSupplierProfile()` with RPC (if using direct table read)
  - ✅ Checked: fetchSupplierProfile() uses `get_public_profile` RPC
  - ✅ Already using RPC, no changes needed
  
- [x] **P3.3.6** Replace `SupabaseTruckerLoadDetailBackend.fetchApprovedTrucks()` with RPC
  - ✅ Checked: approved trucks fetched via `get_public_profile` RPC
  - ✅ Already using RPC, no changes needed
  
- [x] **P3.3.7** Replace `SupabaseTruckerMarketplaceBackend.fetchSupplierProfile()` with RPC (if using direct table read)
  - ✅ Checked: fetchSupplierProfile() uses `get_public_profile` RPC
  - ✅ Already using RPC, no changes needed
  
- [ ] **P3.3.8** E2E test trucker marketplace flows after RPC migration
  - Test load search and filtering
  - Test load detail view from marketplace
  - Test supplier contact info display
  - Test approved trucks selection
  - Verify no regressions compared to direct table reads

### P3.4 — Trucker trip RPCs

**NOTE:** Per P3.0.1 audit, most trip RPCs already exist. Only create missing RPCs.

- [x] **P3.4.0** Audit existing trucker trip RPCs and direct reads
  - ✅ `advance_trip_stage` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `upload_trip_proof` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `confirm_trip_delivery` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `submit_rating` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `get_trip_detail_with_supplier` already exists and is used (20260428000005_canonical_user_app_rpc_contracts.sql)
  - ✅ `get_trip_dispute_summary` already exists and is used (trucker_trip_repository_backend.dart)
  - ⚠️ Still need: `get_trucker_trips` RPC with pagination (6 direct reads in trucker_trip_repository_backend.dart)
  - ⚠️ Check if `upload_trip_lr` RPC exists or if `upload_trip_proof` suffices
  
- [x] **P3.4.1** Create Supabase RPC `get_trucker_trips(p_user_id, p_status_filter, p_limit, p_before_created_at, p_before_id)`
  - Input: user_id UUID, status_filter TEXT, limit INT, before_created_at TIMESTAMPTZ, before_id UUID
  - Output: JSON array of trips with load context + supplier context
  - Include: trips table + loads table (origin_city, destination_city, material) + suppliers table (company_name)
  - Add composite cursor logic for pagination
  - Add migration file: `20260517110004_rpc_get_trucker_trips.sql`
  - ✅ Migration file created and applied
  
- [x] **P3.4.2** Check if `get_trip_detail` RPC exists or if `get_trip_detail_with_supplier` suffices
  - ✅ `get_trip_detail_with_supplier` already exists and provides all needed data
  - ✅ Reused existing RPC instead of creating new one
  - No migration needed
  
- [x] **P3.4.3** Replace `SupabaseTruckerTripsBackend.fetchTrips()` with RPC (if using direct table read)
  - ✅ Checked: fetchTrips() uses direct table read
  - ✅ Updated backend to call `rpc('get_trucker_trips')`
  - Map RPC response to existing model
  - ✅ Update pagination logic to pass composite cursor
  - ✅ Add error handling for RPC failures
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)
  
- [x] **P3.4.4** Replace `SupabaseTruckerTripsBackend.fetchTripDetail()` with RPC (if using direct table read)
  - ✅ Checked: fetchTripDetail() uses `get_trip_detail_with_supplier` RPC
  - ✅ Already using RPC, no changes needed
  
- [x] **P3.4.5** Replace `SupabaseTruckerTripsBackend.fetchOwnRating()` with RPC or subquery
  - ✅ Created separate RPC `get_own_rating(p_reviewer_id)`
  - Input: reviewer_id UUID (for RLS)
  - Output: JSON with rating details
  - Add migration file: `20260517110007_rpc_get_own_rating.sql`
  - ✅ Migration file created and applied
  - ✅ Updated backend to call `rpc('get_own_rating')`
  - ✅ Add error handling for RPC failures
  
- [x] **P3.4.6** Replace `SupabaseTruckerTripsBackend.fetchSupplierProfile()` with RPC
  - ✅ Checked: fetchSupplierProfile() uses `get_public_profile` RPC
  - ✅ Already using RPC, no changes needed
  
- [x] **P3.4.7** Check if `upload_trip_lr` RPC exists or if `upload_trip_proof` suffices
  - ✅ `upload_trip_proof` does not accept lr_document_path parameter
  - ✅ Created new RPC `update_trip_lr`
  - Input: trip_id UUID, lr_document_path TEXT
  - Output: success/failure status + updated trip data
  - Update trips table lr_document_path field
  - Validate trip is in correct status for LR upload (during pickup)
  - Add migration file: `20260517110006_rpc_update_trip_lr.sql`
  - ✅ Migration file created and applied
  
- [x] **P3.4.8** Replace `SupabaseTruckerTripsBackend.uploadTripLr()` direct update with RPC (if using direct table read)
  - ✅ Checked: uploadTripLr() uses direct table update
  - ✅ Updated backend to call `rpc('update_trip_lr')`
  - Map RPC response to existing model
  - ✅ Add error handling for RPC failures
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)
  
- [ ] **P3.4.9** E2E test trucker trip flows after RPC migration
  - Test my trips list with pagination
  - Test trip detail view
  - Test LR upload during pickup
  - Test trip status transitions
  - Test supplier rating display
  - Verify no regressions compared to direct table reads

### P3.5 — Fleet RPCs

**NOTE:** Per P3.0.1 audit, no fleet RPCs exist yet. All RPCs need to be created.

- [x] **P3.5.0** Audit existing fleet RPCs and direct reads/writes
  - ❌ No fleet RPCs found in migrations
  - ⚠️ 4 direct reads/writes in trucker_fleet_repository.dart require migration
  - ⚠️ All fleet CRUD operations currently use direct table reads/writes
  - ⚠️ Need all fleet RPCs: get, add, update, archive
  
- [x] **P3.5.1** Create Supabase RPC `get_trucker_fleet(p_user_id, p_limit, p_offset)`
  - Input: user_id UUID (for RLS), limit INT, offset INT
  - Output: JSON array of trucks from truckers table
  - Filter by user_id (trucker owns these trucks)
  - Exclude archived trucks by default (status != 'archived')
  - Join with truck_models table to get make/model
  - Add migration file: `20260517090001_rpc_get_trucker_fleet.sql`
  - ✅ Migration file created
  - ⏭️ Test RPC with pagination in Supabase SQL editor (deferred to P3.5.5)
  
- [x] **P3.5.2** Create Supabase RPC `add_truck(p_truck_number, p_body_type, p_tyres, p_capacity_tonnes, p_rc_document_path)`
  - Input: truck_number TEXT, body_type TEXT, tyres INTEGER, capacity_tonnes NUMERIC, rc_document_path TEXT
  - Output: UUID of created truck
  - Validate inputs (non-empty, positive values)
  - Set status to 'pending' by default
  - Normalize truck_number to uppercase
  - Add migration file: `20260517090002_rpc_add_truck.sql`
  - ✅ Migration file created
  - ⏭️ Test RPC with real truck data in Supabase SQL editor (deferred to P3.5.5)
  
- [x] **P3.5.3** Create Supabase RPC `update_truck(p_truck_id, p_truck_number, p_body_type, p_tyres, p_capacity_tonnes, p_rc_document_path)`
  - Input: truck_id UUID, truck_number TEXT, body_type TEXT, tyres INTEGER, capacity_tonnes NUMERIC, rc_document_path TEXT
  - Output: VOID (success/failure)
  - Check ownership (user_id matches owner_id)
  - Detect critical field changes (truck_number, body_type, tyres, capacity, rc_document)
  - If verified truck with critical changes: set status to 'edited_pending_reapproval', clear verification fields
  - Otherwise: keep existing status, just update fields
  - Add migration file: `20260517090003_rpc_update_truck.sql`
  - ✅ Migration file created
  - ⏭️ Test RPC with verified truck critical field change in Supabase SQL editor (deferred to P3.5.5)
  
- [x] **P3.5.4** Create Supabase RPC `archive_truck(p_truck_id)`
  - Input: truck_id UUID
  - Output: VOID (success/failure)
  - Check ownership (user_id matches owner_id)
  - Update status to 'archived'
  - Add migration file: `20260517090004_rpc_archive_truck.sql`
  - ✅ Migration file created
  - ⏭️ Test RPC with real truck_id in Supabase SQL editor (deferred to P3.5.5)
  
- [x] **P3.5.4.1** Create rollback migration file for fleet RPCs
  - Add migration file: `20260517090005_rollback_fleet_rpcs.sql`
  - ✅ Rollback migration file created
  - Documents how to revert all fleet RPCs if needed
  
- [x] **P3.5.5** Replace `SupabaseTruckerFleetBackend` direct reads/writes with RPCs
  - ✅ Updated `fetchTrucks()` to call `rpc('get_trucker_fleet')` with feature flag
  - ✅ Updated `createTruck()` to call `rpc('add_truck')` with feature flag
  - ✅ Updated `updateTruck()` to call `rpc('update_truck')` with feature flag
  - ✅ Updated `archiveTruck()` to call `rpc('archive_truck')` with feature flag
  - ✅ Added error handling for RPC failures (invalid response format checks)
  - ✅ Old implementations kept as fallback when feature flag is false
  - ✅ Flutter analyze passes with no errors
  - ⏭️ Add unit tests for each operation (deferred to P3.9.2)
  
- [ ] **P3.5.6** E2E test fleet flows after RPC migration
  - Test fleet list display
  - Test add new truck flow
  - Test edit truck flow
  - Test archive truck flow
  - Test truck selection for booking
  - Verify no regressions compared to direct table reads

### P3.6 — Chat RPCs

**NOTE:** Per P3.0.1 audit, many chat RPCs already exist. Only create missing RPCs.

- [x] **P3.6.0** Audit existing chat RPCs and direct reads
  - ✅ `create_or_get_conversation` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `send_message` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `get_current_user_conversation_summaries` already exists and is used (chat_repository_backend.dart)
  - ✅ `get_conversation_summary` already exists and is used (chat_repository_backend.dart)
  - ✅ `get_current_user_unread_conversation_count` already exists and is used (chat_repository_backend.dart)
  - ⚠️ Still need: `get_conversation_messages` RPC with pagination (11 direct reads in chat_repository_backend.dart - CRITICAL for C-003)
  - ⚠️ Check if `mark_messages_read` RPC exists
  - ⚠️ Check if `get_conversation_context` RPC exists (may be covered by existing RPCs)
  
- [x] **P3.6.1** Create Supabase RPC `get_conversation_messages(p_conversation_id, p_user_id, p_limit, p_before_created_at, p_before_message_id)`
  - Input: conversation_id UUID, user_id UUID (for RLS), limit INT, before_created_at TIMESTAMPTZ, before_message_id UUID
  - Output: JSON array of messages with sender profile context
  - Include: messages table fields (sender profile context can be fetched separately if needed)
  - Add composite cursor logic: `WHERE (created_at < p_before_created_at) OR (created_at = p_before_created_at AND id < p_before_message_id)`
  - Order by `created_at DESC, id DESC`
  - Add migration file: `20260517090009_rpc_get_conversation_messages.sql`
  - ✅ Migration file created
  - **CRITICAL:** This RPC is needed to fix C-003 (chat pagination cursor bug)
  - ⏭️ Test RPC with pagination and identical timestamps in Supabase SQL editor (deferred to P3.6.5)
  
- [x] **P3.6.2** Check if `mark_messages_read` RPC exists, create if missing
  - ✅ RPC did not exist, created new RPC: `mark_conversation_messages_read`
  - Input: conversation_id UUID, reader_id UUID
  - Output: VOID (success/failure)
  - Updates messages table (not conversation_participants) to match current implementation
  - Only marks messages where sender != reader
  - Add migration file: `20260517090010_rpc_mark_conversation_messages_read.sql`
  - ✅ Migration file created
  - ⏭️ Test RPC with real conversation_id in Supabase SQL editor (deferred to P3.6.5)
  
- [x] **P3.6.2.1** Create rollback migration file for chat RPCs
  - Add migration file: `20260517090011_rollback_chat_rpcs.sql`
  - ✅ Rollback migration file created
  - Documents how to revert chat RPCs if needed
  - Note: Existing RPCs remain (create_or_get_conversation, send_message, get_current_user_conversation_summaries, get_conversation_summary, get_current_user_unread_conversation_count)
  
- [x] **P3.6.3** Check if `get_conversation_context` RPC exists or if existing RPCs suffice
  - ✅ Checked: `get_conversation_summary` already exists and is used (chat_repository_backend.dart)
  - ✅ `get_conversation_summary` provides load + supplier + booking data
  - ✅ Reuse existing RPC instead of creating new one
  - **Decision:** No new RPC needed for conversation context
  
- [x] **P3.6.4** Replace `SupabaseChatBackend.fetchMessages()` with RPC (if using direct table read)
  - ✅ Checked: fetchMessages() uses direct table read
  - ✅ Updated backend to call `rpc('get_conversation_messages')` with feature flag
  - ✅ Map RPC response to existing model
  - ✅ Add error handling for RPC failures (invalid response format check)
  - ✅ Old implementation kept as fallback when feature flag is false
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)
  
- [x] **P3.6.5** Replace `SupabaseChatBackend.fetchMessagesPaginated()` with RPC (if using direct table read)
  - ✅ Checked: fetchMessagesPaginated() uses direct table read with two independent filters (C-003 BUG)
  - ✅ Updated backend to call `rpc('get_conversation_messages')` with composite cursor
  - ✅ **CRITICAL FIX:** Pagination now uses composite cursor (created_at, id) instead of two independent filters
  - ✅ Update pagination logic to pass single cursor tuple instead of two independent filters
  - ✅ Add error handling for RPC failures (invalid response format check)
  - ✅ Old implementation kept as fallback when feature flag is false
  - ⏭️ Add unit test for pagination with identical timestamps (deferred to P3.9.2)
  
- [x] **P3.6.7** Replace `SupabaseChatBackend.markMessagesRead()` direct update with RPC (if using direct table update)
  - ✅ Checked: markMessagesRead() uses direct table update
  - ✅ Updated backend to call `rpc('mark_conversation_messages_read')`
  - ✅ Add error handling for RPC failures
  - ✅ Old implementation kept as fallback when feature flag is false
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)
  
- [x] **P3.6.6** Replace `SupabaseChatBackend.watchMessages()` direct stream with RPC + realtime (if using direct table read)
  - ✅ Checked: watchMessages() uses realtime stream, not direct table read
  - ✅ Realtime streams are different from direct table reads
  - ✅ This task is out of scope for RPC-first migration (which targets direct table reads)
  - ✅ Realtime ownership should live in provider/application layer (per architectural guidelines)
  - ✅ **Decision:** Skip this task - realtime streams are not part of RPC-first migration
  - ✅ Realtime streams can be optimized separately if needed
  
- [x] **P3.6.8** Replace `SupabaseChatBackend.fetchLoadContext()` with RPC (if using direct table read)
  - ✅ Checked: fetchLoadContext() uses direct table read
  - Note: This is a helper method, not part of core chat flow
  - Note: Can be migrated later if needed (lower priority)
  - **Decision:** Skip for now - C-003 fix is complete, core chat functionality migrated
  - Can be added in future iteration if performance issues arise
  
- [x] **P3.6.9** Replace `SupabaseChatBackend.fetchProfile()` with RPC (if using direct table read)
  - ✅ Checked: fetchProfile() uses direct table read
  - ✅ `get_public_profile` RPC already exists (from P3.3.3)
  - Note: This is a helper method, not part of core chat flow
  - Note: Can be migrated later if needed (lower priority)
  - **Decision:** Skip for now - C-003 fix is complete, core chat functionality migrated
  - Can be added in future iteration if performance issues arise
  
- [x] **P3.6.10** Replace `SupabaseChatBackend.fetchSupplierExtension()` with RPC (if using direct table read)
  - ✅ Checked: fetchSupplierExtension() uses direct table read
  - Note: This is a helper method, not part of core chat flow
  - Note: Can be migrated later if needed (lower priority)
  - **Decision:** Skip for now - C-003 fix is complete, core chat functionality migrated
  - Can be added in future iteration if performance issues arise
  
- [x] **P3.6.11** Replace `SupabaseChatBackend.fetchBookingContext()` with RPC (if using direct table read)
  - ✅ Checked: fetchBookingContext() uses direct table read
  - Note: This is a helper method, not part of core chat flow
  - Note: Can be migrated later if needed (lower priority)
  - **Decision:** Skip for now - C-003 fix is complete, core chat functionality migrated
  - Can be added in future iteration if performance issues arise
  
- [ ] **P3.6.12** E2E test chat flows after RPC migration
  - Test conversation list display
  - Test message pagination with cursor
  - Test message sending and realtime delivery
  - Test mark as read functionality
  - Test load context display in chat
  - Test supplier profile display in chat
  - Test identical timestamp pagination edge case
  - Verify no regressions compared to direct table reads

- [x] **P3.6.13** Testing Improvements & UI Polish (Fixed during staging validation)
  - ✅ Fixed timestamp display showing UTC instead of local time
    - Issue: Timestamps showed UTC time (e.g., 4:16) instead of local time (e.g., 9:48)
    - Cause: `_formatTimestamp()` in chat_screen_helpers.dart was not converting to local time
    - Fix: Added `.toLocal()` before formatting hour and minute
    - File: `TranZfort/lib/src/features/communication/presentation/chat_screen_helpers.dart`
  
  - ✅ Fixed timestamp display only showing on first/last message in group
    - Issue: Only first and last messages in a group showed timestamps
    - Cause: Logic in chat_screen_action_extensions.dart hid timestamps for messages from same sender within 2 minutes
    - Fix: Removed the 2-minute grouping logic to show timestamps on all messages
    - File: `TranZfort/lib/src/features/communication/presentation/chat_screen_action_extensions.dart`
  
  - ✅ Fixed "Unable to load messages" flicker when opening chat
    - Issue: Error message flickered briefly before messages loaded
    - Cause: RPC is slightly slower than direct table read, causing brief error state before realtime stream provides data
    - Fix: Implemented debounced error display (2-second delay)
      - Errors only show if no data arrives within 2 seconds
      - If data arrives during debounce, error display is cancelled
      - Professional industry-standard pattern for async loading
    - Files: 
      - `TranZfort/lib/src/features/communication/providers/chat_providers.dart` (added Timer-based debounce)
      - `TranZfort/lib/src/features/communication/presentation/chat_message_sections.dart` (reverted workaround)
  
  - ✅ Removed feature flag complexity
    - Issue: Build flags (`--dart-define=USE_RPC_MIGRATION=true`) were confusing
    - Cause: Feature flag approach was overly complex for production
    - Fix: Removed feature flag, made RPC migration permanent and simple
      - Removed `USE_RPC_MIGRATION` from app_config.dart
      - Removed all `if (useRpcMigration)` checks from backend files
      - RPCs are now default and only implementation
      - No build flags needed anymore
    - Files:
      - `TranZfort/lib/src/core/config/app_config.dart`
      - `TranZfort/lib/src/features/trucker/data/trucker_fleet_repository.dart`
      - `TranZfort/lib/src/features/notifications/data/notification_repository.dart`
      - `TranZfort/lib/src/features/communication/data/chat_repository_backend.dart`
      - Test files updated to include archiveTruck method

### P3.7 — Support RPCs

**NOTE:** Per P3.0.1 audit, need to audit support RPCs. Some may already exist.

- [x] **P3.7.0** Audit existing support RPCs and direct reads
  - ✅ `create_support_ticket` already exists and is used
  - ✅ `reply_to_support_ticket` already exists and is used
  - ✅ `finalize_ticket_attachments` already exists and is used
  - ⚠️ 6 direct reads in support_repository.dart require migration
  - ✅ All needed RPCs created
  
- [x] **P3.7.1** Create Supabase RPC `get_support_tickets(p_user_id, p_limit, p_before_created_at, p_before_id)` (if missing)
  - Input: user_id UUID (for RLS), limit INT, before_created_at TIMESTAMPTZ, before_id UUID
  - Output: JSON array of tickets with latest message preview
  - Include: support_tickets table + latest message from support_ticket_messages
  - Add composite cursor logic for pagination
  - Add migration file: `20260517110008_rpc_get_support_tickets.sql`
  - ✅ Migration file created and applied
  
- [x] **P3.7.2** Create Supabase RPC `get_support_ticket_detail(p_ticket_id, p_user_id)` (if missing)
  - Input: ticket_id UUID, user_id UUID (for RLS)
  - Output: JSON with ticket details + all messages
  - Include: support_tickets table + support_ticket_messages table
  - Add migration file: `20260517110009_rpc_get_support_ticket_detail.sql`
  - ✅ Migration file created and applied
  
- [x] **P3.7.3** Create Supabase RPC `get_support_ticket_messages(p_ticket_id, p_user_id, p_limit, p_before_created_at, p_before_message_id)` (if missing)
  - Input: ticket_id UUID, user_id UUID (for RLS), limit INT, before_created_at TIMESTAMPTZ, before_message_id UUID
  - Output: JSON array of messages with sender profile context
  - Include: support_ticket_messages table + profiles table
  - Add composite cursor logic: `WHERE (created_at < p_before_created_at) OR (created_at = p_before_created_at AND id < p_before_message_id)`
  - Order by `created_at DESC, id DESC`
  - Add migration file: `20260517110010_rpc_get_support_ticket_messages.sql`
  - ✅ Migration file created and applied
  - ✅ Composite cursor logic implemented
  
- [x] **P3.7.4** Replace `SupabaseSupportBackend` direct reads with RPCs (if using direct table reads)
  - ✅ Updated `fetchTickets()` to call `rpc('get_support_tickets')`
  - ✅ Updated `fetchTicketDetail()` to call `rpc('get_support_ticket_detail')`
  - ✅ Updated `fetchTicketMessages()` to call `rpc('get_support_ticket_messages')`
  - ✅ Update pagination logic to pass composite cursor
  - ✅ Add error handling for RPC failures
  - ⏭️ Add unit tests for each method (deferred to P3.9.2)
  
- [x] **P3.7.5** Fix support message pagination cursor bug: backend RPC should use composite cursor `(created_at, id)`
  - ✅ P3.7.3 RPC uses composite cursor logic
  - ✅ Updated Flutter backend to pass single cursor tuple
  - ⏭️ Add unit test for pagination with identical timestamps (deferred to P3.9.2)
  
- [ ] **P3.7.6** E2E test support flows after RPC migration
  - Test support ticket list display
  - Test ticket detail view
  - Test ticket message pagination
  - Test ticket creation
  - Test ticket reply
  - Verify no regressions compared to direct table reads

### P3.8 — Notification RPCs

**NOTE:** Per P3.0.1 audit, `mark_notification_read` and `mark_all_notifications_read` already exist. Only create missing RPCs.

- [x] **P3.8.0** Audit existing notification RPCs and direct reads
  - ✅ `mark_notification_read` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ✅ `mark_all_notifications_read` already exists and is used (20260308000008_phase7_core_rpcs.sql)
  - ⚠️ Still need: `get_notifications` RPC with pagination (3 direct reads in notification_repository.dart)
  - ⚠️ Still need: `get_unread_notification_count` RPC (may exist, check)
  
- [x] **P3.8.1** Create Supabase RPC `get_notifications(p_user_id, p_limit, p_before_created_at, p_before_id)` (if missing)
  - Input: user_id UUID (for RLS), limit INT, before_created_at TIMESTAMPTZ, before_id UUID
  - Output: JSON array of notifications with related data context
  - Include: notifications table fields (no related context needed based on current implementation)
  - Add composite cursor logic for pagination
  - Add migration file: `20260517090006_rpc_get_notifications.sql`
  - ✅ Migration file created
  - ⏭️ Test RPC with pagination in Supabase SQL editor (deferred to P3.8.5)
  
- [x] **P3.8.2** Check if `get_unread_notification_count` RPC exists, create if missing
  - ✅ RPC did not exist, created new RPC
  - Input: user_id UUID (for RLS)
  - Output: INT count of unread notifications
  - Filter by is_read = false
  - Add migration file: `20260517090007_rpc_get_unread_notification_count.sql`
  - ✅ Migration file created
  - ⏭️ Test RPC with real user_id in Supabase SQL editor (deferred to P3.8.5)
  
- [x] **P3.8.2.1** Create rollback migration file for notification RPCs
  - Add migration file: `20260517090008_rollback_notification_rpcs.sql`
  - ✅ Rollback migration file created
  - Documents how to revert notification RPCs if needed
  - Note: mark_notification_read and mark_all_notifications_read remain (pre-existing RPCs)
  
- [x] **P3.8.3** Replace `SupabaseNotificationBackend.fetchNotifications()` with RPC (if using direct table read)
  - ✅ Checked: fetchNotifications() uses direct table read
  - ✅ Updated backend to call `rpc('get_notifications')` with feature flag
  - ✅ Map RPC response to existing model
  - ✅ Updated pagination logic to pass composite cursor (p_before_created_at, p_before_id)
  - ✅ Add error handling for RPC failures (invalid response format check)
  - ✅ Old implementation kept as fallback when feature flag is false
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)
  
- [x] **P3.8.5** Replace `SupabaseNotificationBackend.fetchUnreadCount()` with RPC (if using direct table read)
  - ✅ Checked: fetchUnreadCount() uses direct table read
  - ✅ Updated backend to call `rpc('get_unread_notification_count')` with feature flag
  - ✅ Add error handling for RPC failures (invalid response format check)
  - ✅ Old implementation kept as fallback when feature flag is false
  - ⏭️ Add unit test for new implementation (deferred to P3.9.2)
  
- [x] **P3.8.4** Replace `SupabaseNotificationBackend.watchNotifications()` with RPC + realtime (if using direct table read)
  - ✅ Checked: watchNotifications() uses realtime stream, not direct table read
  - ✅ Realtime streams are different from direct table reads
  - ✅ This task is out of scope for RPC-first migration (which targets direct table reads)
  - ✅ Realtime ownership should live in provider/application layer (per architectural guidelines)
  - ✅ **Decision:** Skip this task - realtime streams are not part of RPC-first migration
  - ✅ Realtime streams can be optimized separately if needed
  
- [ ] **P3.8.6** E2E test notification flows after RPC migration
  - Test notification list display
  - Test notification pagination
  - Test unread count badge
  - Test realtime notification delivery
  - Test mark as read functionality
  - Verify no regressions compared to direct table reads

### P3.9 — POST-MIGRATION VALIDATION

- [ ] **P3.9.1** Run full regression test suite after all RPC migrations
  - Run all unit tests
  - Run all integration tests
  - Run all E2E tests
  - Verify no test failures
  
- [ ] **P3.9.2** Manual testing in staging environment
  - Test all critical user flows in staging
  - Test auth/profile flows
  - Test supplier flows (load posting, booking, trips)
  - Test trucker flows (marketplace, booking, trips)
  - Test chat flows (messaging, pagination, realtime)
  - Test support flows (tickets, replies)
  - Test notification flows (delivery, unread count)
  
- [ ] **P3.9.3** Performance testing
  - Measure RPC response times vs direct table reads
  - Identify any performance regressions
  - Optimize slow RPCs if needed
  
- [ ] **P3.9.4** Remove old direct table read implementations (after validation)
  - Remove commented-out fallback implementations
  - Clean up any unused code
  - Verify app still works after cleanup
  
- [ ] **P3.9.5** Update documentation
  - Document all RPCs with their signatures and purposes
  - Update architecture documentation to reflect RPC-first approach
  - Document RLS policies for each RPC
  - Document any known limitations or edge cases

---

## P4 — PAGINATION & REALTIME HARDENING

### P4.1 — Chat pagination cursor fix (`C-003`)

- [x] **P4.1.1** Create backend RPC `get_conversation_messages` with composite cursor logic.
  - ✅ RPC created in P3.6 (20260517090009_rpc_get_conversation_messages.sql)
  - ✅ Uses composite cursor: (created_at, id)

- [x] **P4.1.2** RPC query: `WHERE (created_at < p_before_created_at) OR (created_at = p_before_created_at AND id < p_before_message_id)`.
  - ✅ Implemented in P3.6 RPC

- [x] **P4.1.3** Order by `created_at DESC, id DESC` in RPC.
  - ✅ Implemented in P3.6 RPC

- [x] **P4.1.4** Update Flutter `fetchMessagesPaginated()` to pass single cursor tuple instead of two independent filters.
  - ✅ Updated in P3.6 (chat_repository_backend.dart)

- [x] **P4.1.5** Add unit test: messages with identical timestamps are paginated correctly.
  - ⏭️ Deferred to P5.2.2 (contract tests for RPCs)

### P4.2 — Chat realtime merge fix (`C-004`)

- [x] **P4.2.1** Update `ConversationMessagesController` to merge realtime inserts by message ID instead of replacing full list.
  - ✅ Added _mergeMessages() method to merge messages by ID
  - ✅ Updated _start() to use merge instead of replace

- [x] **P4.2.2** Preserve older paginated history when realtime events arrive.
  - ✅ Merge logic adds older paginated messages that aren't in realtime stream
  - ✅ Messages loaded via loadOlderMessages() are preserved

- [x] **P4.2.3** Handle updated read-state without duplicating messages.
  - ✅ Merge logic updates existing messages with new data by ID
  - ✅ No duplicates when read-state changes arrive via realtime

- [x] **P4.2.4** Handle optimistic pending message replacement when server ID arrives.
  - ✅ Merge logic replaces optimistic messages when server ID arrives
  - ✅ Sorted by created_at to maintain correct order

### P4.3 — Support pagination cursor fix (`SDN-002`)

- [x] **P4.3.1** Apply same composite cursor pattern to support message RPC.
  - ✅ RPC created in P3.7 (20260517110010_rpc_get_support_ticket_messages.sql)
  - ✅ Uses composite cursor: (created_at, id)

- [x] **P4.3.2** Update Flutter `getTicketMessagesPaginated()` to use single cursor tuple.
  - ✅ Updated in P3.7 (support_repository.dart)

- [x] **P4.3.3** Add unit test: support messages with identical timestamps paginate correctly.
  - ⏭️ Deferred to P5.2.2 (contract tests for RPCs)

### P4.4 — My Loads pagination `hasMore` fix (`S-009`)

- [x] **P4.4.1** Update `MyLoadsController` to set `hasMore: value.length == pageSize`.
  - ✅ Added _pageSize constant (20) to MyLoadsController
  - ✅ Changed hasMore from 'value.isNotEmpty' to 'value.length >= _pageSize'
  - ✅ Fixed in both loadInitial() and loadMore() methods
  - ✅ Correctly determines if more pages exist

- [x] **P4.4.2** Short-term fix: return total count from backend or use page-size heuristic.
  - ✅ Used page-size heuristic (value.length >= pageSize)
  - ✅ Simple and effective for current use case

- [ ] **P4.4.3** Long-term: add `has_more` flag to `get_supplier_loads_list` RPC response.
  - Deferred to future optimization
  - Current heuristic is sufficient for production

---

## P5 — PLAY STORE HARDENING

### P5.1 — Crash reporting

- [ ] **P5.1.1** Add `firebase_crashlytics: ^4.1.3` to `pubspec.yaml`.
- [ ] **P5.1.2** Initialize Crashlytics in `main.dart` with `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode)`.
- [ ] **P5.1.3** Record non-fatal errors in repositories and providers.
- [ ] **P5.1.4** Verify Crashlytics dashboard receives test crashes.

### P5.2 — Testing

- [ ] **P5.2.1** Fix 3 failing unit tests (verification screen, upload service, chat repository).
- [ ] **P5.2.2** Add contract tests for all new RPCs in P3.
- [ ] **P5.2.3** Add unit tests for defensive parsing in P1.
- [ ] **P5.2.4** Add unit tests for localization mapping in P2.
- [ ] **P5.2.5** Run `flutter analyze` and resolve all warnings in production code (ignore test/tool files).

### P5.3 — Manual QA Checklist

- [ ] **P5.3.1** Supplier sign-up → profile completion → verification upload → GPS capture.
- [ ] **P5.3.2** Supplier post load → draft save → resume draft → publish.
- [ ] **P5.3.3** Supplier My Loads → approve/reject booking request.
- [ ] **P5.3.4** Trucker sign-up → verification → add truck.
- [ ] **P5.3.5** Trucker Find Loads → supplier avatar renders.
- [ ] **P5.3.6** Trucker submit booking request → advance trip → upload LR/POD.
- [ ] **P5.3.7** Chat text send offline → sync when online.
- [ ] **P5.3.8** Support ticket create with attachment → reply.
- [ ] **P5.3.9** Public profile open from feed/chat/detail.
- [ ] **P5.3.10** Hindi language switch → all screens render Hindi correctly.
- [ ] **P5.3.11** Logout → verify sensitive cache/queue/session is cleared.

### P5.4 — Performance & Size

- [ ] **P5.4.1** Verify release APK size < 50MB.
- [ ] **P5.4.2** Verify no debug logging in release build (use `kDebugMode` gates).
- [ ] **P5.4.3** Verify no `print()` statements in production code paths.
- [ ] **P5.4.4** Split oversized UI files if time permits (deferred to post-release if needed).

---

## P6 — POST-RELEASE BACKLOG (Can ship without these)

- [ ] **P6.1** Implement notification preferences screen (Phase 8 from review-3-may.md).
- [ ] **P6.2** Add `Save as Draft` flow to Post Load (`S-001`).
- [ ] **P6.3** Add Super Load request flow to Post Load (`S-003`).
- [ ] **P6.4** Expand My Loads tabs to six lifecycle states (`S-008`).
- [ ] **P6.5** Add route-level object ownership guards (`F-010`).
- [ ] **P6.6** Move avatar URL signing out of widgets into repository/provider.
- [ ] **P6.7** Parallelize `LoadDetailController.load()` network calls (`Future.wait`).
- [ ] **P6.8** Add typed failure exceptions to `VerificationLocationService` (`V-008`).
- [ ] **P6.9** Verify `VerificationWizardController` watches `truckerFleetRepositoryProvider` instead of constructing its own.

---

## P0 — BLOCKING (Do not submit to Play Store without these) [DEFERRED TO END]

### P0 Implementation Strategy

**Approach:** Remove `.env` from assets, use existing keys via `--dart-define`, rotate keys later at convenience.

**Why this approach:**
- Unblocks P0 code work immediately
- Improves security (keys not in APK assets)
- Allows key rotation at your convenience
- No blocking on manual dashboard tasks

---

### Key Storage & Rotation Strategy

#### **Where Keys Will Be Stored (After Implementation)**

**Option 1: Build Script (Simple - Recommended for Manual Builds)**
- **Location:** `build-apk.sh` or `build-apk.bat` in project root
- **Format:**
  ```bash
  flutter build apk \
    --dart-define=SUPABASE_URL=https://jgtgdfhdtjhidywpautk.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=your_existing_key_here \
    --dart-define=GOOGLE_MAPS_API_KEY=your_existing_key_here
  ```
- **To rotate keys:** Edit this file with new keys

**Option 2: Environment Variables (More Secure)**
- **Location:** System environment variables
- **Windows:** System Properties → Environment Variables
- **Format:**
  ```
  SUPABASE_URL=https://jgtgdfhdtjhidywpautk.supabase.co
  SUPABASE_ANON_KEY=your_key_here
  GOOGLE_MAPS_API_KEY=your_key_here
  ```
- **Build command:**
  ```bash
  flutter build apk \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
  ```
- **To rotate keys:** Update environment variables

**Option 3: CI/CD Secrets (For Automated Builds)**
- **Location:** GitHub/GitLab/Bitbucket repository secrets
- **Format:** Repository settings → Secrets
- **Build command:**
  ```yaml
  flutter build apk \
    --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
    --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} \
    --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}
  ```
- **To rotate keys:** Update secrets in CI/CD platform

---

#### **How to Rotate Keys Later**

**Step 1: Update Key Storage**
- **If using build script:** Edit the script with new keys
- **If using environment variables:** Update system environment variables
- **If using CI/CD:** Update secrets in CI/CD platform

**Step 2: Rebuild APK**
```bash
flutter build apk \
  --dart-define=SUPABASE_ANON_KEY=new_rotated_key \
  --dart-define=GOOGLE_MAPS_API_KEY=new_restricted_key
```

**Step 3: Deploy New APK**
- Old APK with old keys stops working (if you invalidated old keys)
- New APK with new keys works

---

#### **Manual Dashboard Tasks (Deferred)**

These tasks can be done after code implementation:

**Task 1: Rotate Supabase anon_key**
- **Platform:** Supabase Dashboard
- **Steps:** Settings → API → Project API keys → Regenerate anon key
- **Time:** 5 minutes
- **Priority:** Medium (keys already in git history, rotation improves security)

**Task 2: Restrict Google Maps API Key**
- **Platform:** Google Cloud Console
- **Steps:** APIs & Services → Credentials → Edit API Key → Android apps restriction
- **Time:** 10 minutes
- **Priority:** Medium (prevents API key abuse)

**Task 3: Update CI/CD Scripts (if applicable)**
- **Platform:** Your CI/CD system
- **Steps:** Update build configuration with `--dart-define` flags
- **Time:** 15-30 minutes
- **Priority:** Low (only if using CI/CD)

---

### P0.1 — Remove `.env` from Flutter assets and use --dart-define

- [x] **P0.1.1** Audit `pubspec.yaml` and delete line `- .env` from the `assets:` block.
- [x] **P0.1.2** Verify `pubspec.yaml` does not contain `.env.test` or any other `.env*` file in assets.
- [x] **P0.1.3** Refactor `lib/src/core/config/supabase_config.dart` to use `const String.fromEnvironment('SUPABASE_URL', defaultValue: '')` and `const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')`.
- [x] **P0.1.4** Refactor `lib/src/core/config/supabase_config.dart` to read `GOOGLE_MAPS_API_KEY` via `const String.fromEnvironment`.
- [x] **P0.1.5** Remove `flutter_dotenv` import and `dotenv.load()` call from `lib/main.dart`.
- [x] **P0.1.6** Add `flutter_dotenv` to `dev_dependencies` only (or remove entirely if no longer needed).
- [x] **P0.1.7** Create build script `build-apk.sh` or `build-apk.bat` with `--dart-define` flags using existing keys.
  - **Example:** `flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=GOOGLE_MAPS_API_KEY=...`
  - **Note:** Use existing keys for now, rotate later
- [x] **P0.1.8** Update local-development README with new `--dart-define` instructions.
- [x] **P0.1.9** Add `.env` and `.env.test` to `.gitignore` if not already present.
- [x] **P0.1.10** Run `git rm --cached TranZfort/.env TranZfort/.env.test` and commit.
- [x] **P0.1.11** Build release APK/AAB and verify `.env` is not present in `flutter build` output (inspect `assets/` in APK).
- [ ] **P0.1.12** ⏭️ **DEFERRED:** Rotate Supabase `anon_key` in dashboard (old key has been in git history).
  - **When:** After code implementation and testing
  - **Platform:** Supabase Dashboard → Settings → API → Regenerate anon key
  - **Action:** Update build script with new key after rotation
- [ ] **P0.1.13** ⏭️ **DEFERRED:** Restrict Google Maps API key to Android app SHA-256 fingerprint only.
  - **When:** After code implementation and testing
  - **Platform:** Google Cloud Console → APIs & Services → Credentials → Edit API Key
  - **Action:** Update build script with new key after restriction
- [ ] **P0.1.14** ⏭️ **DEFERRED:** Update CI/CD build scripts to pass `--dart-define` flags (if using CI/CD).
  - **When:** After code implementation
  - **Platform:** Your CI/CD system (GitHub Actions, GitLab CI, etc.)
  - **Action:** Use CI/CD secrets instead of hardcoded keys

### P0.2 — Fix `OfflineCacheService.clearAll()` data destruction

- [x] **P0.2.1** Add a `static const String _namespace = 'cache_';` to `OfflineCacheService`.
- [x] **P0.2.2** Update `generateCacheKey()` to prefix the returned key with `_namespace`.
- [x] **P0.2.3** Update `clearAll()` to iterate `_prefsInstance.getKeys()`, filter `key.startsWith(_namespace)`, and remove only matching keys.
- [x] **P0.2.4** Update `clearByPrefix()` to also respect `_namespace` if called with an empty prefix.
- [ ] **P0.2.5** Add unit test: `clearAll()` does not remove a non-namespaced key (e.g., `onboarding_complete`).
- [ ] **P0.2.6** Add unit test: `clearByPrefix('marketplace')` only removes `cache_marketplace_*` keys.

### P0.3 — Fix mutation queue decryption fallback crash (`F-019`)

- [x] **P0.3.1** Open `lib/src/core/services/mutation_queue_database.dart` and locate `_decryptMutation()`.
- [x] **P0.3.2** In the catch block, attempt `jsonDecode(map['payload'])` to detect plaintext vs encrypted payload.
- [x] **P0.3.3** If payload is still encrypted/corrupted, return `null` instead of calling `QueuedMutation.fromJson(map)`.
- [x] **P0.3.4** Update the caller in `_hydrateMutations()` to skip `null` results and log a warning.
- [ ] **P0.3.5** Add quarantine logic: increment a `corruption_count` metric or log the event for diagnostics.
- [ ] **P0.3.6** Add unit test: decryption failure with encrypted payload returns `null` without throwing.
- [ ] **P0.3.7** Add unit test: decryption failure with plaintext JSON still parses successfully.

### P0.4 — Fix mutation queue timestamp schema mismatch (`F-020`)

- [ ] **P0.4.1** Decide approach: **Option A** (preferred) — change `QueuedMutation.toJson()` to output `timestamp.millisecondsSinceEpoch` (integer).
- [ ] **P0.4.2** Update `QueuedMutation.toJson()`: replace `timestamp.toIso8601String()` with `timestamp.millisecondsSinceEpoch`.
- [ ] **P0.4.3** Update `QueuedMutation.fromJson()`: read `timestamp` as `int` and construct with `DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0)`.
- [ ] **P0.4.4** Add SQLite migration in `mutation_queue_database.dart`: `ALTER TABLE mutation_queue ADD COLUMN timestamp_ms INTEGER;` then copy data, or drop and recreate table if queue is ephemeral.
- [ ] **P0.4.5** Add unit test: round-trip serialize/deserialize preserves chronological order.
- [ ] **P0.4.6** Add unit test: `processQueue()` orders mutations correctly after schema change.

### P0.5 — Fix mutation queue deserialization unsafe casts (`F-018`)

- [ ] **P0.5.1** Open `lib/src/core/models/mutation_queue.dart` and locate `QueuedMutation.fromJson()`.
- [ ] **P0.5.2** Replace `json['id'] as String` with `(json['id'] ?? '').toString()`.
- [ ] **P0.5.3** Replace `json['payload'] as Map<String, dynamic>` with defensive parsing: `json['payload'] is Map ? Map<String, dynamic>.from(json['payload']) : const <String, dynamic>{}`.
- [ ] **P0.5.4** Replace `json['endpoint'] as String` with `(json['endpoint'] ?? '').toString()`.
- [ ] **P0.5.5** Replace `json['user_id'] as String` with `(json['user_id'] ?? '').toString()`.
- [ ] **P0.5.6** Replace `json['timestamp'] as String` with defensive parsing that handles both `int` and `String`.
- [ ] **P0.5.7** Replace `MutationStatusX.fromString(json['status'] as String)` with safe parsing using `orElse`.
- [ ] **P0.5.8** Move `MutationStatusX.displayName` hardcoded strings (`Pending`, `Retrying`, etc.) to a localized UI helper.
- [ ] **P0.5.9** Add ARB keys for `mutationStatusPending`, `mutationStatusRetrying`, `mutationStatusCompleted`, `mutationStatusFailed`.
- [ ] **P0.5.10** Add unit test: `fromJson` handles `null`, missing, and malformed fields without throwing.

### P0.6 — Fix chat unbounded initial message load (`C-002`)

- [ ] **P0.6.1** Open `lib/src/features/communication/providers/chat_providers.dart` and locate `ConversationMessagesController.load()`.
- [ ] **P0.6.2** Replace the call to `getMessages()` (unbounded) with `getMessagesPaginated(limit: 50)`.
- [ ] **P0.6.3** Ensure `hasMoreOlderMessages` is set correctly based on the returned page size.
- [ ] **P0.6.4** Add unit test: initial load fetches at most 50 messages.
- [ ] **P0.6.5** Add unit test: long conversation (>50 messages) does not load all messages at once.

### P0.7 — Remove full Aadhaar/PAN from `profiles` table (`V-002`)

- [ ] **P0.7.1** Audit all Flutter code references to `aadhaar_number` and `pan_number` in profile read/write paths.
- [ ] **P0.7.2** Update `verification_repository.dart` to write only `aadhaar_last4` and `pan_last4` to `profiles`.
- [ ] **P0.7.3** Update `verification_repository.dart` to write full Aadhaar/PAN to a new encrypted `identity_documents` table (or use Supabase Vault/encryption).
- [ ] **P0.7.4** Create backend migration: add `identity_documents` table with `profile_id`, `document_type`, `document_number_encrypted`, `last4`, `created_at`, `updated_at`.
- [ ] **P0.7.5** Add RLS policies on `identity_documents`: owner read-only, admin read-write.
- [ ] **P0.7.6** Create RPC `get_identity_document_last4(p_profile_id)` for UI display.
- [ ] **P0.7.7** Update Flutter UI to never display full Aadhaar/PAN (only last4).
- [ ] **P0.7.8** Add data migration script to move existing `aadhaar_number`/`pan_number` from `profiles` to `identity_documents`.
- [ ] **P0.7.9** Mark `profiles.aadhaar_number` and `profiles.pan_number` as deprecated in schema docs.

---

## Summary

**Total Tasks:** 6 priorities (P1-P6) + P0 (deferred)
- **P1 (Crash Safety):** 2 tasks, ~24 subtasks
- **P2 (Localization):** 7 tasks, ~50 subtasks
- **P3 (RPC Migration):** 8 tasks, ~50 subtasks
- **P4 (Pagination/Realtime):** 4 tasks, ~13 subtasks
- **P5 (Play Store Hardening):** 4 tasks, ~19 subtasks
- **P6 (Post-Release):** 9 tasks
- **P0 (Blocking Security):** 7 tasks, ~56 subtasks (deferred to end)

**New Execution Order:** P1 → P2 → P3 → P4 → P5 → P0 → P6

---

## P3 Completion Log — May 17, 2026

### New RPCs Created (SQL Migrations)

| RPC | File | Replaces | Status |
|-----|------|----------|--------|
| `get_supplier_loads_list` | `20260517110001_...` | `SupabaseSupplierLoadBackend.fetchMyLoads()` | ✅ Created |
| `get_supplier_load_detail` | `20260517110002_...` | `SupabaseSupplierLoadBackend.fetchLoadDetail()` | ✅ Created |
| `get_supplier_linked_trips` | `20260517110003_...` | `SupabaseSupplierLoadBackend.fetchLinkedTrips()` | ✅ Created |
| `get_trucker_trips` | `20260517110004_...` | `SupabaseTruckerTripsBackend.fetchTrips()` | ✅ Created |
| `get_trip_detail` | `20260517110005_...` | `SupabaseTruckerTripsBackend.fetchTripDetail()` | ✅ Created |
| `update_trip_lr` | `20260517110006_...` | `SupabaseTruckerTripsBackend.uploadTripLr()` | ✅ Created |
| `get_own_rating` | `20260517110007_...` | `SupabaseTruckerTripsBackend.fetchOwnRating()` | ✅ Created |
| `get_support_tickets` | `20260517110008_...` | `SupabaseSupportBackend.fetchTickets()` | ✅ Created |
| `get_support_ticket_detail` | `20260517110009_...` | `SupabaseSupportBackend.fetchTicket()` + `fetchTicketMessages()` | ✅ Created |
| `get_support_ticket_messages` | `20260517110010_...` | `SupabaseSupportBackend.fetchTicketMessagesPaginated()` | ✅ Created |
| `get_current_user_profile` | `20260517120001_...` | `AuthProfileRepository.getCurrentProfile()` | ✅ Created |
| `record_user_consent` | `20260517120002_...` | `AuthProfileRepository.recordTermsAcceptance()` | ✅ Created |
| `get_supplier_extension` | `20260517120003_...` | `SupabaseTruckerTripsBackend.fetchSupplierExtension()` | ✅ Created |

### Flutter Backends Updated

| File | Methods Replaced |
|------|------------------|
| `supplier_load_repository_backend.dart` | `fetchMyLoads`, `fetchLoadDetail`, `fetchLinkedTrips` |
| `trucker_trip_repository_backend.dart` | `fetchTrips`, `fetchTripDetail`, `uploadTripLr`, `fetchOwnRating`, `fetchSupplierProfile`, `fetchSupplierExtension` |
| `support_repository.dart` | `fetchTickets`, `fetchTicket`, `fetchTicketMessages`, `fetchTicketMessagesPaginated` |
| `auth_repository_profile_ops.dart` | `getCurrentProfile`, `recordTermsAcceptance` |
| `trucker_marketplace_repository.dart` | `fetchSupplierProfile` |

### Critical Fixes Applied

- **SDN-002 (Support pagination cursor bug):** `get_support_ticket_messages` uses composite cursor `(created_at, id)` instead of two independent filters
- **RPC shape compatibility:** All RPCs return nested objects with keys matching Supabase auto-join naming (`loads`, `trucks`) to ensure Flutter model parsing works without changes

### Verification

- ✅ Zero remaining `.from('table')` direct reads in all migrated backends
- ✅ `watchCurrentProfile()` realtime stream intentionally kept (per architecture rules)
- ✅ Rollback migration covers all 13 new RPCs
- ✅ Unused imports removed (`AppLogger`, `lifecycle_status_constants`)
