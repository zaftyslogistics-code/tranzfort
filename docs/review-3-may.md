# TranZfort User App Production Readiness Review

Date: May 3, 2026
Scope: User app only (`TranZfort` Flutter app: Supplier + Trucker). Admin app review is deferred.

## Source Documents Reviewed

- `/docs/TODO-27-april.md`
- `/docs/project-details-22-april/project-overview-index.md`
- `/docs/project-details-22-april/shared-features-and-contracts.md`
- `/docs/project-details-22-april/supplier-features-microscopic.md`
- `/docs/project-details-22-april/trucker-features-microscopic.md`

## Review Rules

- Source-of-truth order: documentation > schema/migrations > plans > code.
- Expected data flow: UI -> Provider/State -> Repository -> Backend.
- User app only: Supplier and Trucker features under `TranZfort`.
- Admin-specific code is not reviewed except where shared contracts affect the user app.
- Each issue includes description, affected file/module, severity, and suggested fix/approach.

## Completion Status (Updated: May 12, 2026)

**Overall Progress:** 7/10 phases partially or fully completed (Phase 0, 1.2, 1.3-partial, 3, 4)

**UI/UX Rollback Decision:**
- **Rollback Point:** `e545a13` - "Improve debug logging for supplier location search" (April 20, 2026)
- **Decision:** NO ROLLBACK - Current UI/UX work (Phases 1-6) is production-ready and valuable
- **UI/UX Work Preserved:** Color scheme improvements, dark theme cards, TTS improvements, auth redesign, marketplace card redesign, localization cleanup
- **Reasoning:** Build is stable, UI/UX improvements are separate from review-3-may.md tasks, Phase 5 localization can be done on top of current UI/UX

**Overall Progress:** 8/10 phases partially or fully completed (Phase 0, 1.2, 1.3-partial, 3, 4, 5, 6)

**Completed:**
- Phase 0: Safety, Baseline, and Test Harness - ✅ COMPLETED
- Phase 1.1: Secure Aadhaar/PAN storage (V-002) - ⚠️ PARTIAL (Flutter-side fix done, backend encrypted table needed)
- Phase 1.2: Fix offline mutation queue processing (R-010, R-011, R-013) - ✅ COMPLETED
- Phase 1.3: Fix Trucker feed supplier avatar (T-010 only) - ⚠️ PARTIAL (T-009, V-004 require backend)
- Phase 3: Pagination, Realtime, and Data Robustness - ✅ COMPLETED
  - 3.1 Chat pagination and hardening (C-005 parsing only) - ✅ COMPLETED
  - 3.2 Support pagination (SDN-001 parsing only) - ✅ COMPLETED
  - 3.3 Unsafe parsing and cache hardening across app - ✅ COMPLETED
- Phase 4: Verification and Document Upload Reliability - ✅ COMPLETED
- Phase 5: Localization and UI Consistency - ✅ COMPLETED
  - 5.1 Repository/provider error localization - ✅ COMPLETED (error codes and ARB keys added: 36 error codes + 40 validation/backend/permission/marketplace keys)
  - 5.2 Hardcoded screen/model strings - ✅ COMPLETED (ARB keys added and code updated for marketplace, chat, offline sync)
  - 5.3 Design-system consistency - ⚠️ DEFERRED (notification settings screen not implemented, oversized UI files deferred)
- Phase 6: Privacy, Cache, and Offline Storage - ✅ COMPLETED
  - 6.1 Offline cache classification and lifecycle controls - ✅ COMPLETED
  - 6.2 Mutation queue privacy (encryption, payload minimization, error redaction) - ✅ COMPLETED

**Not Started:**
- Phase 2: Backend Authority and Product Contract Gaps - ❌ NOT STARTED
- Phase 7: Support, Dispute, and Attachment Finalization - ❌ NOT STARTED
- Phase 8: Notifications and Push - ❌ NOT STARTED
- Phase 9: Public Profile and Reviews - ❌ NOT STARTED
- Phase 10: Final Release Validation - ❌ NOT STARTED

**Key Fixes Applied:**
- Fixed mutation queue exponential backoff (XOR → math.pow)
- Fixed mutation queue processing logic (added isProcessable, fixed loop)
- Wired offline sync banner retry button to processor
- Fixed marketplace load card Hero tag instability
- Replaced unsafe DateTime.parse with safe parsing across 12+ files
- Added defensive parsing for notification preferences, public profile cache
- Localized public profile displayLocation, verificationBadge, newUserBadge
- Localized marketplace card Supplier fallback, SUPER label, relative age strings
- Localized review model timeAgo with new ARB keys
- Added new l10n keys: commonSupplierLabel, commonSuperLabel, relativeTimeDay/Hour/Minute/Now, relativeTimeYear/Month/Day/Hour/MinuteAgo, relativeTimeJustNow
- Flutter-side Aadhaar/PAN security fix: Stop writing full values to profile fields (V-002)
- Verification document upload: Added byte-signature detection for JPEG/PNG when mimeType is null (V-005)
- Verification document upload: Added document-type-specific validation rules (profile photo 400x400, others 800x600) (V-006)
- Verification document upload: Added error codes for all user-facing strings (V-007)
- Verification location service: Added typed failure exceptions (network, geocode, offline, unknown) (V-008)
- Verification draft storage: Hardened with user ID requirement, PII masking, clear on logout (V-009)
- Phase 5: Added 76 ARB keys for error codes, validation, backend failures, permissions, marketplace, chat, offline sync
- Phase 6: Mutation queue encryption with AES-256-GCM (key in flutter_secure_storage)
- Phase 6: Cache lifecycle controls (LRU eviction, max-size limits, schema versioning)
- Phase 6: Payload minimization (redact PII from stored mutations)
- Phase 6: Error redaction (store error codes instead of raw errors, never persist stack traces)
- Auth/profile repository: Error code constants added (F-005, F-007) - NOT YET USED IN UI
- Onboarding location: Localized error messages with ARB keys
- Supplier providers: Error code constants added (S-004) - NOT YET USED IN UI
- Trucker providers: Error code constants added (T-006) - NOT YET USED IN UI
- Chat providers: Error code constants added (C-006) - NOT YET USED IN UI
- Verification providers: Error code constants added (V-001, V-007) - NOT YET USED IN UI
- Notification providers: Error code constants added (SDN-011) - NOT YET USED IN UI
- Public profile providers: Error code constants added (R-003) - NOT YET USED IN UI
- Review providers: Error code constants added (R-004) - NOT YET USED IN UI
- Phase 5.1 ARB keys: 36 error code keys + 40 validation/backend/permission/marketplace/chat keys added to app_en.arb and app_hi.arb
- Phase 5.2 ARB keys: Marketplace (LOAD VALUE, EST. PROFIT, EST. LOSS), Chat (New message, Today, Yesterday) added

## Review Chunks

1. Foundation: app entry, routing, auth/session/profile, localization, environment, shared providers.
2. Supplier: dashboard, post load, my loads, load detail, assignment, trips, super load.
3. Trucker: dashboard, marketplace/find loads, load detail, trips, fleet/vehicles.
4. Shared communication: conversations, chat detail, realtime, attachments/call gates.
5. Verification: wizard, secure draft storage, document uploads, GPS/location capture.
6. Support/disputes: support tickets, report issue, raise dispute, attachment workflows.
7. Notifications: list, preferences, push runtime, deep links.
8. Public profiles/reviews/trust: public profile, reviews, profile visibility/capability flags.
9. Offline/read caching/mutation queue: cache correctness, sync UX, queue safety.
10. Release hardening: tests, analyzer/lints, file sizes, performance, Play Store readiness.

## Findings

### Chunk 1 — Foundation: App Entry, Routing, Auth/Session, Config

#### F-001 — `.env` is bundled as a Flutter asset

- **Description:** `pubspec.yaml` includes `.env` under Flutter assets. This causes environment content to be packaged into app assets. Even though Supabase anon keys are public by design, shipping a raw `.env` increases accidental secret exposure risk and is not Play Store production hygiene. The code also relies on `dotenv.load(fileName: '.env')`, making the release build dependent on a bundled dotenv file rather than build-time configuration.
- **Affected file/module:** `TranZfort/pubspec.yaml`, `TranZfort/lib/main.dart`, `TranZfort/lib/src/core/config/supabase_config.dart`
- **Severity:** High
- **Suggested fix or approach:** Remove `.env` from Flutter assets for release builds. Load required public config through `--dart-define`, flavor-specific config, or CI-injected environment. Keep local `.env` only for development/test and ensure no service-role or private keys can be bundled.

#### F-002 — Missing Supabase configuration does not fail fast

- **Description:** `main.dart` skips `Supabase.initialize()` when `SupabaseConfig.isConfigured` is false, then still launches the app. Most repositories receive a nullable `SupabaseClient` and later fail as “Session unavailable” or similar downstream errors. For production, this creates confusing UX instead of a clear startup/configuration failure.
- **Affected file/module:** `TranZfort/lib/main.dart`, `TranZfort/lib/src/core/providers/app_state_providers.dart`, repositories using `supabaseClientProvider`
- **Severity:** High
- **Suggested fix or approach:** In release/profile builds, treat missing or invalid Supabase URL/key as a startup failure screen with a precise localized message. In debug, allow fallback only with an explicit development banner. Avoid letting the app enter normal flows with `SupabaseClient == null`.

#### F-003 — Public profile route error screens are still hardcoded and marked TODO despite TODO-27 saying localized route errors are complete

- **Description:** `TODO-27-april.md` marks route error/loading/not-found localization as complete, but `_PublicProfileRouteErrorScreen` and `_PublicProfileRouteNotFoundScreen` still contain TODO comments and literal strings: `Profile`, `Failed to load profile`, and `Profile not found`. This is a direct gap between the tracked task status and implementation.
- **Affected file/module:** `TranZfort/lib/src/core/navigation/app_router.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Replace literals with existing `AppLocalizations` keys documented in TODO-27 (`publicProfileScreenTitle`, `publicProfileLoadErrorTitle`, `publicProfileNotFoundTitle`) and render using the same shell/detail scaffold pattern used by other nested routes.

#### F-004 — Route preview invalid-parameter fallback silently opens trucker dashboard

- **Description:** `routePreview` parses coordinates from query parameters. If any coordinate is missing or invalid, it returns `TruckerDashboardScreen()` directly. This hides malformed deep links, can show the wrong role’s dashboard inside the route shell, and conflicts with the TODO requirement to provide explicit route errors for missing route preview data.
- **Affected file/module:** `TranZfort/lib/src/core/navigation/app_router.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Replace the silent fallback with a localized route-error screen that explains the route preview link is invalid or incomplete. Consider redirecting to `AppRoutes.homeForRole()` only after showing a clear CTA.

#### F-005 — Offline sync banner retry button is a stub

- **Description:** `OfflineSyncStatusBanner` shows a `Retry` button for pending mutations, but the handler only displays `Retry not yet implemented`. TODO-27 states offline foundation and UI component integration are complete; this visible stub undermines offline production readiness and can strand users after failed/pending offline actions.
- **Affected file/module:** `TranZfort/lib/src/shared/widgets/offline_sync_status_banner.dart`
- **Severity:** High
- **Suggested fix or approach:** Wire the button to the mutation queue processor provider, call the queue processing method, expose loading/error state, and localize all banner strings. Ensure failed mutations can be retried explicitly and that dismissed banners can reappear when new failures occur.

#### F-006 — Offline sync banner condition and copy are inconsistent for failed-only states

- **Description:** The banner computes `totalCount = pendingCount + failedCount`, but uses `pendingCount > 0 ? 'Syncing...' : 'Sync complete'`. When there are failed mutations and zero pending mutations, the banner says `Sync complete` while also showing failures. The color condition `totalCount > 0 ? orange : red` also makes the red branch unreachable.
- **Affected file/module:** `TranZfort/lib/src/shared/widgets/offline_sync_status_banner.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Model sync state explicitly: pending, failed, pending+failed, complete. Use failed styling when `failedCount > 0`, localized copy, and meaningful actions for retry/dismiss.

#### F-007 — Onboarding discard dialogs are not localized

- **Description:** Role selection and profile completion PopScope dialogs still use literal strings such as `Discard Selection?`, `You have selected a role. Do you want to discard it?`, `Discard Changes?`, `Cancel`, and `Discard`. This conflicts with TODO-27 item 1.3, which says all user-facing screen literals were audited and localized.
- **Affected file/module:** `TranZfort/lib/src/features/auth/presentation/onboarding_screens.dart`, `TranZfort/lib/src/features/auth/presentation/onboarding_profile_completion.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Add EN/HI ARB keys for these dialog titles, messages, and actions, regenerate localizations, and replace constants with `AppLocalizations` values.

#### F-008 — Auth repository returns user-facing English strings instead of structured/localized errors

- **Description:** `AuthRepository` and `AuthProfileRepository` return English messages directly for Google configuration, Google cancellation, email/password validation, role selection, profile validation, language validation, and account deletion response format errors. UI can only display these raw strings, so Hindi/localized UX is inconsistent and repository/domain layers leak presentation copy.
- **Affected file/module:** `TranZfort/lib/src/features/auth/data/auth_repository.dart`, `TranZfort/lib/src/features/auth/data/auth_repository_profile_ops.dart`, auth/onboarding presentation consumers
- **Severity:** Medium
- **Suggested fix or approach:** Return stable error codes plus field keys from repositories, then map those codes to localized UI strings in providers/presentation. Keep low-level diagnostics in logs, not user-facing messages.

#### F-009 — `app_router.dart` is oversized and mixes routing, metadata, observers, and public-profile UI

- **Description:** The documented file-size guideline says UI screen files should stay under 500 lines and provider/repository files under smaller limits. `app_router.dart` is 734 lines and includes route metadata registration, GoRouter construction, TTS observer, redirect part, and multiple public-profile error widgets. This makes navigation policy high-risk to change and already contributed to stale TODO/l10n gaps.
- **Affected file/module:** `TranZfort/lib/src/core/navigation/app_router.dart`
- **Severity:** Low
- **Suggested fix or approach:** Split route metadata registration, route builders, public-profile route widgets, and observers into separate files. Keep `app_router.dart` focused on composing the GoRouter route tree.

#### F-010 — Route guard policy is path-list based and does not cover object ownership before detail screens build

- **Description:** The global redirect only blocks a small set of exact supplier/trucker top-level paths. Shared detail routes such as `/load-detail/:loadId`, `/trip-detail/:tripId`, `/chat/:conversationId`, `/raise-dispute/:tripId`, support tickets, and notification settings are allowed to build first and rely on downstream repositories/screens for object-level authorization. TODO-27 item 4.7 says route guard policy should centralize Supplier/Trucker capabilities and object ownership before detail screens are built.
- **Affected file/module:** `TranZfort/lib/src/core/navigation/app_router_redirect.dart`, `TranZfort/lib/src/core/navigation/app_router.dart`, detail screen modules
- **Severity:** High
- **Suggested fix or approach:** Add route-level capability checks for parameterized/detail routes where possible, or introduce guarded route builders that verify role + object ownership/capability through a lightweight repository/RPC before constructing detail screens. Keep backend RLS as final authority, but avoid rendering wrong-role screens or leaking loading/error details for inaccessible objects.

### Chunk 2 — Supplier: Post Load, Load Management, Assignment

#### S-001 — Post Load screen lacks documented `Save as Draft` flow

- **Description:** Supplier microscopic spec requires a secondary `Save as Draft` action with relaxed validation. Current `PostLoadScreen` only exposes a single submit/post CTA and `PostLoadController.submit()` always validates all required publish fields and calls `createLoad`. There is no draft DTO/status, no draft save action, and no resume/edit draft workflow from the form.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/presentation/post_load_screen.dart`, `TranZfort/lib/src/features/supplier/providers/post_load_provider.dart`, `TranZfort/lib/src/features/supplier/data/supplier_load_repository.dart`
- **Severity:** High
- **Suggested fix or approach:** Add explicit draft creation/update contract, UI action, relaxed draft validation, and My Loads draft resume path. Backend should distinguish `draft` from immediately published loads.

#### S-002 — Post Load success state does not match product spec

- **Description:** Supplier spec requires a success state with `Share Load`, `View Load`, and optional `Request Super Load` CTA plus 5-second redirect. Current implementation only shows a snackbar and immediately navigates to `/my-loads`, so users cannot share/view/request promotion directly after posting.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/presentation/post_load_screen.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Add a post-submit success view or bottom sheet with the documented CTAs. Use `lastCreatedLoadId` to open load detail/share/super-load request, then optionally auto-redirect after the user has seen the state.

#### S-003 — Super Load request flow is not present in post-load path

- **Description:** Supplier spec says `Request Super Load Promotion` should be visible after a load is valid and again after success. Current post-load UI has no Super Load CTA. TODO-27 includes Super Load and monetization workflows as important product areas, but the core creation path does not surface them.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/presentation/post_load_screen.dart`, Supplier Super Load modules/routes if present
- **Severity:** Medium
- **Suggested fix or approach:** Add route and UI integration for Super Load request/account-detail prerequisite flow. Gate by load validity and account readiness, and keep off-platform settlement messaging clear.

#### S-004 — Post Load still has hardcoded user-facing strings

- **Description:** Despite the localization TODO being marked complete, the custom material field uses hardcoded `Specify Material` and `e.g., Fruits, Iron Ore, Bricks`, and validation uses `Please specify the material`. Material dropdown values are also raw English constants. These will not translate in Hindi.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/presentation/post_load_screen.dart`, `TranZfort/lib/src/features/supplier/providers/post_load_provider.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Add ARB keys for custom material label/hint/validation and material option display labels. Store canonical material codes in state/backend while rendering localized labels in UI.

#### S-005 — Supplier load models use unsafe `DateTime.parse` on backend values

- **Description:** Several mapper paths call `DateTime.parse` directly on potentially empty/malformed backend values: booking request `created_at`, linked trip `assigned_at`, load detail `createdAt/updatedAt`, list item `pickupDate`, and `publishedAt`. A single malformed row can crash list/detail rendering, contradicting TODO hardening work that fixed this pattern elsewhere.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/data/supplier_load_models.dart`
- **Severity:** High
- **Suggested fix or approach:** Replace direct `DateTime.parse` with safe readers returning nullable values or controlled fallbacks. Surface contract failures diagnostically where required fields are invalid instead of crashing the UI isolate.

#### S-006 — Supplier load backend uses direct table reads for My Loads and detail instead of consolidated contract/RPC

- **Description:** `fetchMyLoads()` and `fetchLoadDetail()` read the `loads` table directly from Flutter. Project docs and TODO-27 emphasize schema/RPC contracts and consolidated views/RPCs for visibility, ownership, and contract drift control. Direct table selects duplicate column lists in the client and are fragile when schema changes.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/data/supplier_load_repository_backend.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Move supplier load list/detail behind canonical RPCs or views that enforce supplier ownership, visibility, pagination metadata, derived counters, and stable response shapes. Keep Flutter parsing against those stable contracts.

#### S-007 — Supplier load backend contains verbose debug logging in production code

- **Description:** `fetchBookingRequests()` and `fetchLinkedTrips()` log detailed IDs, response counts, stack traces, emoji-prefixed messages, and database-column diagnostic hints. This is noisy for production, may expose operational identifiers in logs, and indicates debug investigation code was not cleaned up.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/data/supplier_load_repository_backend.dart`
- **Severity:** Low
- **Suggested fix or approach:** Reduce to structured debug-level logs behind environment gating. Avoid logging full IDs/stack traces unless reporting to a controlled crash/diagnostic sink with redaction.

#### S-008 — My Loads tab model does not match supplier specification

- **Description:** Supplier spec requires six tabs: Drafts, Open, Assigned, In Transit, Completed, and Cancelled. Current `MyLoadsTab` only has `active` and `completed`, collapsing multiple lifecycle states and hiding required workflows such as draft resume, cancelled history, and in-transit monitoring.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/providers/my_loads_provider.dart`, supplier My Loads UI sections
- **Severity:** High
- **Suggested fix or approach:** Expand `MyLoadsTab` to the documented lifecycle groups and map each to shared `LoadStatuses` constants. Update UI tab bar, empty states, and action CTAs per tab.

#### S-009 — My Loads pagination `hasMore` is inaccurate

- **Description:** `hasMore` is set to `value.isNotEmpty` after each page. If the last page returns fewer than the page size but non-empty, the controller will continue requesting another page unnecessarily. This wastes requests and can cause duplicate UX loading states.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/providers/my_loads_provider.dart`, `TranZfort/lib/src/features/supplier/data/supplier_load_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Set `hasMore` using `value.length == pageSize`, or better return pagination metadata from a consolidated backend contract.

#### S-010 — Load detail fails whole screen sections when secondary data fails

- **Description:** `LoadDetailController.load()` fetches core detail, booking requests, then linked trips sequentially. If booking requests fail, the controller sets `failure` and returns before linked trips load. If linked trips fail, the UI shows a general warning. This couples optional/secondary sections to the main detail load and can degrade a usable load-detail screen due to one auxiliary RPC/table issue.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/providers/load_detail_provider.dart`, `TranZfort/lib/src/features/shell/presentation/supplier_shell_load_detail_sections.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Track `detailFailure`, `bookingRequestsFailure`, and `linkedTripsFailure` separately. Render core details whenever available and show per-section retry/error blocks for secondary collections.

#### S-011 — Supplier load detail screen exceeds documented UI file-size guideline

- **Description:** `supplier_shell_load_detail_sections.dart` is 565 lines and combines route detail rendering, booking actions, linked trips, dialogs, timeline, and helper methods. The project guideline says UI screen files should stay under 500 lines. The size increases review risk and makes defects in assignment/detail flows harder to isolate.
- **Affected file/module:** `TranZfort/lib/src/features/shell/presentation/supplier_shell_load_detail_sections.dart`
- **Severity:** Low
- **Suggested fix or approach:** Split into `SupplierLoadHeroSection`, `SupplierLoadActionSection`, `BookingRequestsSection`, `LinkedTripsSection`, and dialog helper widgets.

#### S-012 — Supplier dashboard stats contract omits documented KPI names/sections

- **Description:** Supplier spec documents KPI cards for Active Loads, Today's Trips, Pending Chats, and Total Loads, plus recent loads, active trips, and recent conversations previews. Current dashboard stats model exposes `activeLoads`, `pendingBookings`, `inTransitTrips`, and `completedTrips`. This may be a product drift: the dashboard contract does not directly support Pending Chats or Total Loads as documented.
- **Affected file/module:** `TranZfort/lib/src/features/supplier/data/supplier_dashboard_repository.dart`, supplier dashboard presentation/providers
- **Severity:** Medium
- **Suggested fix or approach:** Align dashboard RPC/model with the documented dashboard sections, or update docs if product changed. Include unread/pending chat count and all-time total loads if the documented dashboard remains the target.

### Chunk 3 — Trucker: Marketplace, Load Detail, Trips, Fleet

#### T-001 — Marketplace RPC contract drift is silently swallowed

- **Description:** `SupabaseTruckerMarketplaceBackend.searchLoads()` converts any non-`Map<String, dynamic>` RPC response into an empty map, then returns an empty result. If `get_marketplace_feed` changes shape or fails to return the expected JSON object, the UI will show no loads instead of a contract failure. TODO-27 explicitly prefers diagnostic failures for unexpected RPC shapes.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/data/trucker_marketplace_repository.dart`
- **Severity:** High
- **Suggested fix or approach:** Throw a `FormatException` or map to `ServerFailure` when the response is not a map or `loads` is not a list. Include diagnostic response type in debug info.

#### T-002 — Marketplace cached JSON deserialization uses unsafe casts and `DateTime.parse`

- **Description:** `MarketplaceLoadItem.fromJson()` casts JSON values directly to `double`, `int`, `bool`, and parses `pickup_date`/`created_at` with `DateTime.parse`. Cached data can break after app upgrades, schema changes, or partially corrupted cache entries, causing cache reads to fail and extra network fetches. The method catches deserialization errors at repository level, but this still invalidates otherwise usable cache and does not distinguish one bad row from all cached results.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/data/trucker_marketplace_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Reuse `map_readers.dart` safe readers for cached JSON and parse dates defensively. Skip only invalid rows or version cache payloads to avoid stale shape crashes.

#### T-003 — Offline marketplace failure message is hardcoded in repository

- **Description:** When offline with no cached marketplace page, `TruckerMarketplaceRepository.searchLoads()` returns `NetworkFailure(message: 'No internet connection. Please check your network and try again.')`. This is user-facing English in the repository layer and bypasses localization.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/data/trucker_marketplace_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Return a stable network error code/type from repository and map to localized UI text in the presentation/provider layer.

#### T-004 — Trucker load detail treats approved-truck loading failure as page-level failure

- **Description:** `TruckerLoadDetailController.load()` fetches load detail first, then approved trucks. If approved truck fetch fails, it sets `failure` while still retaining `detail`. This can make the screen show a general failure state even though the load detail itself is available, and it conflates booking-readiness errors with core load-detail errors.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/providers/trucker_load_detail_provider.dart`, trucker load detail UI sections
- **Severity:** Medium
- **Suggested fix or approach:** Split core detail failure from approved-truck/load-booking readiness failure. Render load detail regardless and show a localized per-section warning/CTA for truck selection issues.

#### T-005 — Trucker trip domain models contain many hardcoded labels and unsafe date parsing

- **Description:** `TruckerTrip.proofStatus`, `timeContext`, `stageLabel`, and `TripAutoCompletionStatus.statusLabel` return hardcoded English strings. Multiple factories use direct `DateTime.parse` for trip, rating, dispute, and auto-completion timestamps. This conflicts with localization requirements and can crash rendering/cached parsing when timestamp fields are malformed.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/data/trucker_trip_repository_models.dart`
- **Severity:** High
- **Suggested fix or approach:** Move labels to UI/localization helpers and keep models as data-only. Replace direct `DateTime.parse` with safe date readers or contract failures with diagnostics depending on whether the field is optional/required.

#### T-006 — Trip action provider returns hardcoded business-rule messages

- **Description:** Trip actions return English messages such as `Another trip action is already in progress.`, `This trip can no longer be advanced from its current stage.`, `POD can only be uploaded after the load has been delivered.`, and `LR can only be uploaded during pickup stages.` These are user-facing and not localizable.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/providers/trucker_trip_action_provider.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Replace direct messages with error codes and map to localized strings in screen/provider presentation.

#### T-007 — Fleet repository still uses direct table writes for archive/reactivate/create/update without RPC business rules

- **Description:** `SupabaseTruckerFleetBackend` reads and mutates the `trucks` table directly. Archive/reactivate and critical-field reapproval decisions are partly client-side. For production, these workflows should be enforced in backend RPCs or database policies to avoid client bypass and keep admin/reapproval state transitions authoritative.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/data/trucker_fleet_repository.dart`
- **Severity:** High
- **Suggested fix or approach:** Move create/update/archive/reactivate to backend RPCs that validate owner, active trip constraints, critical-field changes, reapproval status, and audit events. Keep the client as a requestor only.

#### T-008 — Fleet listing pagination exists in repository but appears not surfaced as full paginated state

- **Description:** `TruckerFleetRepository.getMyTrucks()` accepts page/pageSize and backend uses `range`, but the visible fleet provider/UI review path does not show the same `hasMore`/load-more pattern used for marketplace. For growing fleets, this risks either only showing the first page or requiring manual future work.
- **Affected file/module:** `TranZfort/lib/src/features/trucker/data/trucker_fleet_repository.dart`, `TranZfort/lib/src/features/trucker/providers/trucker_fleet_provider.dart`, `TranZfort/lib/src/features/trucker/presentation/trucker_fleet_screen.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Expose paginated fleet state with `hasMore`, `isLoadingMore`, and UI load-more/infinite-scroll behavior, or enforce a documented small maximum fleet size.

#### T-009 — Supplier avatar in Trucker Find Loads feed falls back to initials because marketplace RPC only returns `profiles.avatar_url`

- **Description:** The Trucker feed card passes `state.loads[index].supplierAvatarUrl` into `MarketplaceLoadCard`, and the card can render either an HTTP URL or storage path via signed URL. However, the latest `get_marketplace_feed` RPC only returns `p.avatar_url` as `supplier_summary.supplier_avatar_url`. Earlier marketplace RPC versions also returned `supplier_photo_path` / `profile_photo_document_path`, but later migrations removed that fallback. If `profiles.avatar_url` is empty or not synchronized from the approved profile photo, the load card has no real image path and renders the initial badge instead. This matches the observed issue where the top-left supplier area in Trucker load cards does not fetch the actual supplier photo.
- **Affected file/module:** `supabase/migrations/20260430000001_fix_marketplace_feed_trust_score_column.sql`, `TranZfort/lib/src/features/trucker/data/trucker_marketplace_repository.dart`, `TranZfort/lib/src/features/trucker/presentation/trucker_find_loads_screen.dart`, `TranZfort/lib/src/shared/widgets/marketplace_load_card.dart`
- **Severity:** High
- **Suggested fix or approach:** Make the marketplace feed return a canonical display avatar field that always resolves for approved suppliers: `COALESCE(NULLIF(p.avatar_url, ''), <approved profile photo path/source>)`, or ensure the profile-photo approval flow reliably writes `profiles.avatar_url`. If returning storage paths, include the bucket/source or return a signed/public URL from the RPC/repository so the widget does not guess buckets. Add an RPC contract test that asserts `supplier_summary.supplier_avatar_url` is present for suppliers with approved profile photos.

#### T-010 — Marketplace avatar widget creates unstable Hero tags and signs URLs inside each card build

- **Description:** `_SupplierAvatarBadge` uses `Hero(tag: 'supplier_avatar_${initial}_${DateTime.now().millisecondsSinceEpoch}')`, so the tag changes every build and cannot provide stable hero transitions. `_AvatarCircle` also signs non-HTTP avatar paths with `Supabase.instance.client` inside a `FutureBuilder` per card, which can trigger repeated storage signed-URL requests during scrolling/rebuilds and silently falls back on failure.
- **Affected file/module:** `TranZfort/lib/src/shared/widgets/marketplace_load_card.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Use a stable tag such as supplier ID/load ID, and move signed URL resolution/caching to a provider or media repository. Pass a resolved display URL to the card instead of making storage calls from the widget.

### Chunk 4 — Shared Communication: Inbox, Chat, Realtime, Attachments/Calls

#### C-001 — Conversation summary RPC contract drift is silently converted to an empty inbox

- **Description:** `fetchConversations()` accepts List or JSON string, but any unexpected `get_current_user_conversation_summaries` response shape returns an empty list instead of a failure. This can hide backend contract regressions as “no conversations,” making production issues harder to diagnose.
- **Affected file/module:** `TranZfort/lib/src/features/communication/data/chat_repository_backend.dart`
- **Severity:** High
- **Suggested fix or approach:** Treat unexpected response shape as `ServerFailure`/`FormatException` with debug details. Only return empty when the backend explicitly returns an empty list.

#### C-002 — Message fetching uses direct table reads and unbounded initial load

- **Description:** `fetchMessages()` reads all rows from `messages` for a conversation ordered ascending, while paginated loading exists separately. `ConversationMessagesController.load()` calls this unbounded method for initial load. Long-running conversations can load thousands of messages at once, hurting memory, startup time, and realtime merge behavior.
- **Affected file/module:** `TranZfort/lib/src/features/communication/data/chat_repository_backend.dart`, `TranZfort/lib/src/features/communication/providers/chat_providers.dart`
- **Severity:** High
- **Suggested fix or approach:** Make initial load use the paginated API with a fixed latest-message window. Use cursor-based pagination and realtime only for new messages after the loaded window.

#### C-003 — Message pagination cursor combines `created_at` and `id` with two independent `<` filters

- **Description:** `fetchMessagesPaginated()` applies both `created_at < beforeCreatedAt` and `id < beforeMessageId`. UUID/string IDs are not chronologically ordered, so this can skip valid older messages or return inconsistent pages. Cursor pagination should compare `(created_at, id)` lexicographically only for tie-breaking, not independently.
- **Affected file/module:** `TranZfort/lib/src/features/communication/data/chat_repository_backend.dart`, `TranZfort/lib/src/features/communication/providers/chat_providers.dart`
- **Severity:** High
- **Suggested fix or approach:** Implement a backend RPC for message pagination that uses a stable cursor: `created_at < cursorCreatedAt OR (created_at = cursorCreatedAt AND id < cursorId)` with deterministic ordering.

#### C-004 — Realtime subscription can replace paginated history with only realtime-visible rows

- **Description:** `ConversationMessagesController._start()` loads messages, then subscribes to `watchMessages()` and replaces `state.messages` with every realtime stream snapshot. Supabase table streams may not represent the complete paginated history window, especially if initial loading is later changed to pagination. This risks losing older loaded messages from the UI after any realtime event.
- **Affected file/module:** `TranZfort/lib/src/features/communication/providers/chat_providers.dart`, `TranZfort/lib/src/features/communication/data/chat_repository_backend.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Merge realtime inserts/updates into existing message state by message ID instead of replacing the whole list. Keep older paginated history separate from live tail updates.

#### C-005 — Chat models use unsafe `DateTime.parse` for message timestamps

- **Description:** `MessageDto.fromMap()` parses `created_at` with `DateTime.parse((map['created_at'] ?? '').toString())`. Any malformed or missing timestamp in a message row can throw and break the whole conversation stream/load.
- **Affected file/module:** `TranZfort/lib/src/features/communication/data/chat_repository_models.dart`
- **Severity:** High
- **Suggested fix or approach:** Use a safe date reader. If `created_at` is required, map invalid rows to a controlled contract failure with row/message ID context rather than crashing stream mapping.

#### C-006 — Chat repository and provider return hardcoded user-facing errors

- **Description:** Chat repository/provider returns English messages for missing role, conversation id, text required, offline queue unavailable, duplicate send, and required supplier/trucker/load context. These are user-facing domain/presentation messages outside localization.
- **Affected file/module:** `TranZfort/lib/src/features/communication/data/chat_repository.dart`, `TranZfort/lib/src/features/communication/providers/chat_providers.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Replace raw strings with error codes/field keys and localize at the UI boundary.

#### C-007 — Chat screen still contains hardcoded UI strings

- **Description:** The new-message pill displays literal `New message`, and date dividers are generated as `Today`, `Yesterday`, or numeric `day/month/year` strings inside `_buildRenderedMessages()`. These bypass Hindi localization and locale-aware date formatting.
- **Affected file/module:** `TranZfort/lib/src/features/communication/presentation/chat_screen.dart`, `TranZfort/lib/src/features/communication/presentation/chat_screen_action_extensions.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Add localization keys for the pill and date labels. Use `MaterialLocalizations`/`intl` for locale-aware dates.

#### C-008 — Chat avatar signing is done inside widget build path and directly accesses `Supabase.instance.client`

- **Description:** `_AvatarCircle` creates signed URLs in a `FutureBuilder` per build and directly uses `Supabase.instance.client` instead of repository/provider infrastructure. Rebuilds can trigger repeated signed URL requests, and the widget bypasses null-client/config handling used elsewhere.
- **Affected file/module:** `TranZfort/lib/src/features/communication/presentation/chat_screen.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Move avatar URL signing/caching to a profile/media repository/provider, cache signed URLs until expiry, and inject the Supabase client via providers.

#### C-009 — Attachment permission flag is not enforced for voice messages in composer

- **Description:** Conversation models expose `isAttachmentAllowed`, but `ChatScreen` composer only checks `truckerChatBlocked`, text presence, and send state for voice recording. If a conversation has attachments disabled, voice attachment sending may still be available unless backend rejects it.
- **Affected file/module:** `TranZfort/lib/src/features/communication/data/chat_repository_conversation_models.dart`, `TranZfort/lib/src/features/communication/presentation/chat_screen.dart`
- **Severity:** High
- **Suggested fix or approach:** Gate voice/document/location attachment actions with `conversation.isAttachmentAllowed` in UI and enforce the same rule in `sendVoiceMessage`/backend RPC.

#### C-010 — Chat screen composition exceeds documented file-size and responsibility guidance

- **Description:** `chat_screen.dart` is 500 lines and uses six part files, with `chat_screen_action_extensions.dart` alone at 431 lines. The screen owns realtime presentation, optimistic sending, voice recording, booking actions, review prompts, avatar signing, TTS, offline banner, and call/report actions. This violates the project’s modularity guidance and makes production defects harder to isolate.
- **Affected file/module:** `TranZfort/lib/src/features/communication/presentation/chat_screen.dart`, chat part files
- **Severity:** Low
- **Suggested fix or approach:** Split into providers/services for optimistic message state, avatar signing, booking action orchestration, and voice recording; keep the screen as composition-only.

### Chunk 5 — Verification: Wizard, Secure Drafts, Uploads, GPS/Location

#### V-001 — Verification validation helper still returns hardcoded English strings

- **Description:** `VerificationWizardValidationHelper` returns literal messages for profile photo, Aadhaar/PAN documents, truck fields, supplier company/license/location, and the generic `Please complete all required fields`. This conflicts with the localization completion claims and produces non-Hindi errors in a critical onboarding flow.
- **Affected file/module:** `TranZfort/lib/src/features/verification/providers/verification_wizard_validation_helper.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Return error codes/field keys from validation and map them to `AppLocalizations` in the wizard UI, or pass localized labels/messages into validation from presentation.

#### V-002 — Verification repository stores full Aadhaar/PAN values in profile fields

- **Description:** `saveVerificationPacketFields()` writes `aadhaar_number` and `pan_number` directly to profile fields, while also deriving `aadhaar_last4`. For production/Play Store privacy posture, full government ID values should not be stored in broadly used profile records unless encrypted, access-scoped, and strictly required. The docs emphasize secure verification handling.
- **Affected file/module:** `TranZfort/lib/src/features/verification/data/verification_repository.dart`, Supabase `profiles` schema/RLS
- **Severity:** Critical
- **Suggested fix or approach:** Store only masked/last4 in general profile fields and move full ID values, if legally required, to a dedicated encrypted verification table/storage path with admin-only access and audit logging. Update RPCs and UI to avoid exposing full identifiers.

#### V-003 — Trucker verification wizard uploads truck photo but never saves it on submit

- **Description:** `VerificationDraft` and `VerificationWizardUploadHelper` support `truckPhotoPath`, but `_verificationSaveDraftData()` creates a truck with only `truckNumber`, `bodyType`, `tyres`, `capacityTonnes`, and `rcDocumentPath`. The uploaded truck photo path is dropped during submit, so the documented truck-photo requirement/review artifact can be lost.
- **Affected file/module:** `TranZfort/lib/src/features/verification/providers/verification_wizard_provider.submit.dart`, `TranZfort/lib/src/features/verification/providers/verification_wizard_upload_helper.dart`, `TranZfort/lib/src/features/trucker/data/trucker_fleet_repository.dart`
- **Severity:** High
- **Suggested fix or approach:** Extend the fleet create/update contract to include `truckPhotoPath` and persist it in the appropriate truck field. Add a submit test that uploads a truck photo and verifies the created truck stores it.

#### V-004 — Profile photo upload saves `profile_photo_document_path` but does not guarantee `avatar_url` is updated for public/feed use

- **Description:** Verification profile-photo upload saves the path to `profile_photo_document_path`. The feed/public avatar paths frequently consume `avatar_url`, and marketplace feed currently only returns `p.avatar_url`. If admin approval/profile-photo review does not run or does not sync reliably, user-facing cards and public profiles fall back to initials. This is the same data-flow gap observed in the Trucker load feed supplier avatar issue.
- **Affected file/module:** `TranZfort/lib/src/features/verification/data/verification_repository.dart`, `supabase/migrations/20260323053000_profile_photo_review_flow.sql`, `supabase/migrations/20260430000001_fix_marketplace_feed_trust_score_column.sql`
- **Severity:** High
- **Suggested fix or approach:** Define one canonical display avatar contract. On profile-photo approval, transactionally set `profiles.avatar_url`; for read paths, fallback to approved `profile_photo_document_path` or return a resolved signed/public URL. Add regression tests for approved profile photo appearing in marketplace feed, chat, public profile, and load detail.

#### V-005 — Document upload service relies on `XFile.mimeType`, which can be null on mobile captures

- **Description:** `validateDocument()` rejects files when `file.mimeType == null`. Camera captures and some Android gallery providers may not populate MIME type even for valid JPEG/PNG images. This can block legitimate verification uploads on real devices.
- **Affected file/module:** `TranZfort/lib/src/features/verification/data/verification_document_upload_service.dart`
- **Severity:** High
- **Suggested fix or approach:** Detect image type from bytes/signature or decoded image format when `mimeType` is null. Keep MIME validation as one signal, not the only acceptance path.

#### V-006 — Profile photo is forced through document minimum resolution rules

- **Description:** `VerificationDocumentUploadService` applies the same 800x600 minimum resolution to all verification document types, including `profilePhoto`. A portrait selfie/profile image can be valid but narrower than 800 pixels after camera/gallery processing, causing unnecessary rejection.
- **Affected file/module:** `TranZfort/lib/src/features/verification/data/verification_document_upload_service.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Use document-type-specific validation rules: stricter dimensions for identity/business documents, square/face-photo friendly dimensions for profile photos, and separate copy for each failure.

#### V-007 — Verification upload and repository errors are still hardcoded and repository-layer user-facing

- **Description:** Upload/repository failures include literals such as `Profile id is required`, `Document validation failed`, permission-copy strings, `Profile is unavailable`, `Verification city is required`, and role-specific upload restrictions. These are user-facing but live below the localization boundary.
- **Affected file/module:** `TranZfort/lib/src/features/verification/data/verification_document_upload_service.dart`, `TranZfort/lib/src/features/verification/data/verification_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Return structured error codes and field identifiers, then localize in wizard/screen presentation. Keep raw backend/storage messages only in debug info.

#### V-008 — Supplier verification GPS reverse lookup silently returns null on unexpected failures

- **Description:** `captureSupplierVerificationLocation()` rethrows service/permission errors, but catches all other failures and returns `null`. Network, Google API, malformed response, and offline city-asset failures are indistinguishable from “no location found,” making UX and diagnostics weak for a release-critical verification gate.
- **Affected file/module:** `TranZfort/lib/src/features/verification/data/verification_location_service.dart`, wizard location provider/UI
- **Severity:** Medium
- **Suggested fix or approach:** Return typed location failures for timeout/network/geocode-unavailable/offline-fallback-empty. Let the UI show actionable retry/manual-location messages and log diagnostic cause safely.

#### V-009 — Secure draft storage key can fall back to role name when user ID is unavailable

- **Description:** `VerificationDraftSecureStorage` uses `_key(userId ?? roleName, roleName)`. If the wizard is ever initialized before auth user ID is available, drafts for the same role can share a storage key on the device. Although normal guarded navigation should have a user ID, the fallback is unsafe for a PII draft containing Aadhaar/PAN and document paths.
- **Affected file/module:** `TranZfort/lib/src/features/verification/providers/verification_draft_secure_storage.dart`, `TranZfort/lib/src/features/verification/providers/verification_wizard_provider.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Refuse to persist/load PII drafts unless a non-empty authenticated user ID is available. Clear any legacy role-only draft keys after migration.

### Chunk 6 — Support, Disputes, Notifications

#### SDN-001 — Support models use unsafe `DateTime.parse` for ticket/message timestamps

- **Description:** `SupportTicketDto.fromMap()`, `SupportTicketMessageDto.fromMap()`, and `TicketAttachmentMetadata.fromMap()` parse `created_at`, `updated_at`, and scan timestamps directly. Any malformed or missing support row timestamp can crash ticket list/detail/attachment rendering.
- **Affected file/module:** `TranZfort/lib/src/features/support/data/support_models.dart`, `TranZfort/lib/src/features/support/data/support_attachment_upload_service.dart`
- **Severity:** High
- **Suggested fix or approach:** Use shared safe date readers and convert invalid required timestamps into controlled repository failures with row IDs for diagnostics.

#### SDN-002 — Support message pagination repeats the chat cursor bug

- **Description:** `fetchTicketMessagesPaginated()` applies both `created_at < beforeCreatedAt` and `id < beforeMessageId`. UUID/string IDs are not time-ordered, so support message pagination can skip older messages. This is the same unstable cursor pattern found in chat pagination.
- **Affected file/module:** `TranZfort/lib/src/features/support/data/support_repository.dart`, `TranZfort/lib/src/features/support/providers/support_providers.dart`
- **Severity:** High
- **Suggested fix or approach:** Replace with a backend RPC that uses a stable composite cursor: `created_at < cursorCreatedAt OR (created_at = cursorCreatedAt AND id < cursorId)` with deterministic ordering.

#### SDN-003 — Support attachment upload creates database records before file selection and can leave failed/orphan rows

- **Description:** `_uploadSingleAttachment()` creates a `ticket_attachments` row before the image picker returns. If the user cancels, compression fails, upload fails, or metadata update fails, rows can remain with empty file path, failed status, or missing storage file. These rows may clutter admin/user attachment lists and require cleanup.
- **Affected file/module:** `TranZfort/lib/src/features/support/data/support_attachment_upload_service.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Pick/validate/compress first, then create the attachment record in the same backend RPC/finalization step as metadata. Add cleanup for failed pending rows and uploaded files when metadata update fails.

#### SDN-004 — Support attachments are uploaded before ticket creation without a finalization contract

- **Description:** Compose providers comment that attachments are already stored with the correct `ticket_id`, but `uploadMultipleAttachments()` requires a `ticketId` before ticket submit. If the UI uses temporary IDs or ticket creation fails, uploaded attachment rows/files may not link to the final ticket. The submit path does not finalize, relocate, or validate attachment ownership.
- **Affected file/module:** `TranZfort/lib/src/features/support/providers/support_compose_providers.dart`, `TranZfort/lib/src/features/support/data/support_attachment_upload_service.dart`, `TranZfort/lib/src/features/support/data/support_repository.dart`
- **Severity:** High
- **Suggested fix or approach:** Use a draft attachment session ID, create the ticket, then atomically finalize attachments to the created ticket via RPC. On submit failure/cancel, clean up draft attachments/files.

#### SDN-005 — Support repository still uses direct table reads for tickets/messages

- **Description:** Support ticket list/detail/messages are read directly from `support_tickets` and `support_ticket_messages` in Flutter, with ownership checks partly implemented client-side before message queries. This increases contract drift risk and duplicates backend authorization assumptions in the app.
- **Affected file/module:** `TranZfort/lib/src/features/support/data/support_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Move ticket list/detail/message pagination to canonical RPCs or views that enforce user ownership, visibility, pagination, and stable response shapes.

#### SDN-006 — Notification settings screen is not localized and appears visually outside the app design system

- **Description:** `NotificationSettingsScreen` contains hardcoded English titles, subtitles, snackbar messages, time picker titles, and section headings. It uses raw `Card`, `SwitchListTile`, and `SnackBar` instead of the shared TranZfort design/localization components. This is a direct UI/UX and localization gap for a user-facing settings route.
- **Affected file/module:** `TranZfort/lib/src/features/notifications/presentation/notification_settings_screen.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Add ARB keys for all copy and rebuild the screen using shared app components (`DetailPageScaffold`, app cards, app snackbar, localized time labels). Include Hindi coverage.

#### SDN-007 — Notification preference parsing is brittle and can crash on missing/default rows

- **Description:** `NotificationPreferences.fromMap()` casts every field directly and parses timestamps with `DateTime.parse`. If the RPC omits a new/default field, returns null, or timestamp format changes, the preferences screen fails entirely.
- **Affected file/module:** `TranZfort/lib/src/features/notifications/data/notification_repository.dart`
- **Severity:** High
- **Suggested fix or approach:** Use defensive readers and defaults for optional preference fields. Treat missing required `user_id` as a controlled contract failure, not a cast crash.

#### SDN-008 — Cached notification deserialization uses unsafe casts and `DateTime.parse`

- **Description:** `AppNotification.fromJson()` directly casts cached values and uses `DateTime.parse` for cached `createdAt`/`readAt`. A stale cache entry after app updates can break notification loading until cache invalidation succeeds.
- **Affected file/module:** `TranZfort/lib/src/features/notifications/data/notification_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Version notification cache payloads, use safe readers for cached JSON, and discard only invalid records instead of the whole cached page.

#### SDN-009 — Notification unread count loads all unread rows just to count them

- **Description:** `fetchUnreadCount()` selects all unread notification IDs and returns `response.length`. For accounts with many unread notifications this transfers unnecessary rows and does not use database count optimizations.
- **Affected file/module:** `TranZfort/lib/src/features/notifications/data/notification_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Use a head/count query or RPC returning only the count. Keep realtime unread count incremental or server-count backed for large histories.

#### SDN-010 — Notification route resolver blocks support ticket deep links

- **Description:** `resolveNotificationRouteData()` explicitly sends `/support-ticket` and `/support-ticket/...` hints to the role home fallback. Support response notifications therefore cannot deep-link to the actual ticket, despite support notification categories existing in preferences.
- **Affected file/module:** `TranZfort/lib/src/features/notifications/data/notification_route_resolver.dart`, support routes/router
- **Severity:** High
- **Suggested fix or approach:** Add a supported user support-ticket detail route or map support case/ticket IDs to the support screen with selected ticket state. Keep admin-only support routes blocked separately.

#### SDN-011 — Notification mark-read validation contains hardcoded user-facing strings

- **Description:** `markRead()` returns `Notification id is required` directly from the repository layer. This bypasses localization and follows the same repository-message issue seen in other modules.
- **Affected file/module:** `TranZfort/lib/src/features/notifications/data/notification_repository.dart`
- **Severity:** Low
- **Suggested fix or approach:** Return structured validation error codes and localize messages in presentation.

### Chunk 7 — Public Profiles, Reviews/Trust, Offline Cache, Mutation Queue, Release Hardening

#### R-001 — Public profile models contain hardcoded display strings

- **Description:** `PublicProfile.displayLocation`, `verificationBadge`, and `newUserBadge` return hardcoded English strings such as `Location not set`, `Verified`, `New Trucker`, and `New Supplier`. These are model-layer presentation strings and bypass localization.
- **Affected file/module:** `TranZfort/lib/src/features/profile/data/public_profile_models.dart`, public profile screens
- **Severity:** Medium
- **Suggested fix or approach:** Move display labels to localized UI helpers and keep models data-only.

#### R-002 — Public profile cached deserialization is unsafe

- **Description:** `PublicProfile.fromJson()` and `PublicLoadPreview.fromJson()` directly cast cached values and parse dates with `DateTime.parse`. A stale or partially corrupted public-profile cache can crash profile loading until cache invalidation succeeds.
- **Affected file/module:** `TranZfort/lib/src/features/profile/data/public_profile_models.dart`, `TranZfort/lib/src/features/profile/data/public_profile_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Version cache payloads and use defensive readers for cached JSON. Discard invalid cache records instead of letting casts/date parsing fail.

#### R-003 — Public profile repository has hardcoded validation strings

- **Description:** `getPublicProfile()` and `getUserPublicLoads()` return `User ID is required` directly from repository validation. This repeats the repository-layer localization issue seen across the app.
- **Affected file/module:** `TranZfort/lib/src/features/profile/data/public_profile_repository.dart`
- **Severity:** Low
- **Suggested fix or approach:** Return structured validation codes and localize in presentation.

#### R-004 — Review submit/add-reply flow returns hardcoded validation and backend errors directly

- **Description:** `ReviewRepository` returns direct English messages for invalid rating, missing context, comment length, generic submit failure, and add-reply failure. It also passes backend `response['error']` directly into a `ValidationFailure`. This can expose backend wording and cannot be localized.
- **Affected file/module:** `TranZfort/lib/src/features/reviews/data/review_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Normalize backend review errors to error codes and localize in review UI. Keep backend details in debug info only.

#### R-005 — Review model contains hardcoded relative-time strings

- **Description:** `Review.timeAgo` returns literals such as `1y ago`, `2mo ago`, and `Just now`. These are presentation strings in the model and are not localized or locale-aware.
- **Affected file/module:** `TranZfort/lib/src/features/reviews/data/review_models.dart`, review widgets
- **Severity:** Medium
- **Suggested fix or approach:** Move relative-time formatting to localized UI helpers using `AppLocalizations`/`intl`.

#### R-006 — Review RPC response shape is partially swallowed for submit/can-review

- **Description:** `submitReview()` converts any non-map response into `{success:false,error:'Invalid response format'}` and `canReviewUser()` converts any non-map into a restrictive fallback. These hide backend contract drift as ordinary business failures rather than diagnostic server/contract failures.
- **Affected file/module:** `TranZfort/lib/src/features/reviews/data/review_repository.dart`
- **Severity:** Medium
- **Suggested fix or approach:** Throw/map unexpected RPC shapes to `ServerFailure`/`FormatException` with diagnostic response type.

#### R-007 — Offline cache stores potentially sensitive user data in plaintext `SharedPreferences`

- **Description:** `OfflineCacheService` stores public profiles, notifications, marketplace pages, and other read models as raw JSON strings in `SharedPreferences`. Some cached payloads include names, mobile-related route context, notifications, support hints, and potentially avatar/document paths. This is not suitable for sensitive user data on production devices.
- **Affected file/module:** `TranZfort/lib/src/core/services/offline_cache_service.dart`, repositories using `offlineCacheServiceProvider`
- **Severity:** High
- **Suggested fix or approach:** Move sensitive caches to encrypted storage or a secure local database with scoped retention. Classify cacheable data by sensitivity and avoid caching private notifications/support/profile details in plaintext.

#### R-008 — Offline cache has no size limit, eviction policy, or namespace clear by user session

- **Description:** `OfflineCacheService` uses unlimited `SharedPreferences` keys and only TTL-based per-entry expiry on read. There is no global max size, LRU eviction, or guaranteed cache clear on logout/user switch. This can grow indefinitely and leak previous-user cached data on shared devices if not explicitly cleared.
- **Affected file/module:** `TranZfort/lib/src/core/services/offline_cache_service.dart`, auth sign-out flow
- **Severity:** Medium
- **Suggested fix or approach:** Add per-user namespace management, logout clearing, max cache size, and eviction. Prefer a structured cache database for larger offline datasets.

#### R-009 — Mutation queue deserialization is unsafe for persisted offline mutations

- **Description:** `QueuedMutation.fromJson()` directly casts persisted payloads and parses timestamp with `DateTime.parse`. A single malformed queued mutation can break queue loading/processing and strand offline actions.
- **Affected file/module:** `TranZfort/lib/src/core/models/mutation_queue.dart`, `TranZfort/lib/src/core/services/mutation_queue_database.dart`
- **Severity:** High
- **Suggested fix or approach:** Add defensive parsing, schema versioning, poison-message quarantine, and user-visible recovery for corrupted queued mutations.

#### R-010 — Mutation queue retry eligibility is logically wrong for pending mutations

- **Description:** `MutationQueueProcessor.processQueue()` iterates `getPending()` but immediately checks `if (!mutation.canRetry)`, where `canRetry` is defined as `status == failed && !isExhausted`. A normal `pending` mutation is therefore skipped and marked failed instead of being processed. This undermines offline sync and explains why the offline banner retry path is incomplete/non-functional.
- **Affected file/module:** `TranZfort/lib/src/core/models/mutation_queue.dart`, `TranZfort/lib/src/core/services/mutation_queue_processor.dart`, `TranZfort/lib/src/shared/widgets/offline_sync_status_banner.dart`
- **Severity:** Critical
- **Suggested fix or approach:** Allow `pending` and `retrying` mutations to process. Reserve `canRetry` for failed mutations being requeued. Add unit tests for pending, retrying, failed-exhausted, and successful deletion flows.

#### R-011 — Mutation queue backoff uses bitwise XOR instead of exponentiation

- **Description:** `_calculateBackoffDelay()` uses `_backoffMultiplier ^ retryCount`, which is bitwise XOR in Dart, not exponentiation. Retry delays will be incorrect and non-monotonic.
- **Affected file/module:** `TranZfort/lib/src/core/services/mutation_queue_processor.dart`
- **Severity:** High
- **Suggested fix or approach:** Use `math.pow(_backoffMultiplier, retryCount)` or iterative multiplication, clamp to max delay, and add tests for delay progression.

#### R-012 — Mutation queue failures can leak payload/error details into local storage/events

- **Description:** Queued mutations persist arbitrary `payload` and `lastError` strings. Chat text, proof paths, profile updates, and support/dispute context can be stored locally without encryption/redaction. Processing events also include raw errors and stack traces.
- **Affected file/module:** `TranZfort/lib/src/core/models/mutation_queue.dart`, `TranZfort/lib/src/core/services/mutation_queue_database.dart`, `TranZfort/lib/src/core/services/mutation_queue_processor.dart`
- **Severity:** High
- **Suggested fix or approach:** Encrypt mutation storage, minimize payload fields, redact errors, and avoid storing stack traces locally unless in a protected diagnostics sink.

#### R-013 — Offline sync banner still has hardcoded copy and non-functional retry

- **Description:** `OfflineSyncStatusBanner` displays hardcoded English copy and a `Retry` button that only shows `Retry not yet implemented`. This is a direct production UX blocker for offline sync visibility and recovery.
- **Affected file/module:** `TranZfort/lib/src/shared/widgets/offline_sync_status_banner.dart`
- **Severity:** High
- **Suggested fix or approach:** Wire the retry action to `MutationQueueProcessor.processQueue()`, localize all copy, and show actionable states for pending/retrying/failed/exhausted mutations.

## Current Release-Readiness Summary

### Completed review chunks

- Foundation, app entry, routing, auth/session/profile, localization, environment, shared providers.
- Supplier post-load, My Loads, load detail, dashboard, booking/assignment linkage.
- Trucker marketplace/feed, load detail, trips, proof actions, fleet.
- Shared communication/chat/realtime/attachments/calls.
- Verification wizard, secure drafts, document upload, GPS/location.
- Support/disputes and notifications.
- Public profiles, reviews/trust, offline cache, mutation queue.

### Highest-priority release blockers

- **Sensitive identity storage:** Full Aadhaar/PAN values are written to profile fields (`V-002`).
- **Offline sync broken:** Pending mutations are skipped/failed by retry eligibility logic and retry UI is a stub (`R-010`, `R-013`).
- **Trucker feed avatar bug:** Marketplace RPC only returns `profiles.avatar_url`, with no reliable approved profile-photo fallback (`T-009`, `V-004`).
- **Missing Supplier draft flow:** Post Load lacks required Save as Draft/resume workflow (`S-001`).
- **Direct client-side table mutations:** Fleet create/update/archive/reactivate are client-side table writes instead of authoritative backend RPCs (`T-007`).
- **Unbounded/unstable chat/support pagination:** Chat initial load is unbounded and cursor logic can skip messages (`C-002`, `C-003`, `SDN-002`).
- **Unsafe parsing crash risks:** Many production paths still use direct `DateTime.parse`/casts on backend/cache data.
- **Localization gaps:** Multiple user-facing screens/repositories still return hardcoded English strings, especially verification, chat, notifications, reviews, and public profiles.
- **Plaintext local cache/queue:** Sensitive notifications/profile/offline mutations are stored in plaintext local storage (`R-007`, `R-012`).

### Remaining recommended follow-up before Play Store release

- Run Flutter analyzer/tests and add contract tests for avatar/profile, marketplace feed, message pagination, mutation queue, and verification submit.
- Review Supabase migrations/RLS end-to-end for all highlighted direct table access and sensitive fields.
- Prioritize fixes by Critical/High findings before UI polish.

## Remediation Task Checklist

Use this checklist as the execution plan for fixing the review findings. Work top-to-bottom by phase unless a dependency requires a different order.

### Phase 0 — Safety, Baseline, and Test Harness

- [ ] **Create a release-fix branch**
  - [ ] Create a dedicated branch for production-readiness fixes.
  - [ ] Confirm no Admin app files are included in the review/fix scope.
  - [ ] Run `git status` and record current changed files before fixing.
- [ ] **Establish baseline checks**
  - [ ] Run Flutter analyzer for `TranZfort`.
  - [ ] Run existing Flutter unit/widget tests.
  - [ ] Run existing Supabase/RPC contract smoke tests if configured.
  - [ ] Record all pre-existing failures separately from new fixes.
- [ ] **Add missing regression test scaffolding**
  - [ ] Add/extend tests for marketplace feed avatar contract.
  - [ ] Add/extend tests for message cursor pagination.
  - [ ] Add/extend tests for support-ticket cursor pagination.
  - [ ] Add/extend tests for mutation queue pending/retry processing.
  - [ ] Add/extend tests for verification profile-photo/avatar sync.
  - [ ] Add/extend tests for Supplier post-load draft behavior.

### Phase 1 — Critical Release Blockers

#### 1.1 Secure Aadhaar/PAN storage (`V-002`)

- [ ] **Audit current schema and access paths**
  - [ ] Locate all Supabase migrations defining `aadhaar_number`, `aadhaar_last4`, `pan_number`, and verification tables.
  - [ ] Search Flutter code for all reads/writes of `aadhaar_number` and `pan_number`.
  - [ ] Search RPCs for all exposure of full Aadhaar/PAN values.
  - [ ] Verify current RLS policies on affected profile/verification fields.
- [x] **Flutter app: Stop writing full Aadhaar/PAN to profile fields**
  - [x] Remove `aadhaar_number` from profile update payload.
  - [x] Store only last4 for PAN (or mask).
  - [ ] Update UI to never display full Aadhaar/PAN.
- [ ] **Backend: Create encrypted verification table**
  - [ ] Create `verification_documents` or `identity_documents` table with encrypted storage.
  - [ ] Add admin-only access and audit logging.
  - [ ] Move full Aadhaar/PAN storage to encrypted table.
  - [ ] Update RPCs to read/write from encrypted table.
  - [ ] Add migration to move existing data if any.

#### 1.2 Fix offline mutation queue processing (`R-010`, `R-011`, `R-013`, `F-006`)

- [x] **Fix pending mutation processing**
  - [x] Update `QueuedMutation.canRetry` or processor logic so `pending` mutations are executable.
  - [x] Allow `retrying` mutations to be processed.
  - [x] Ensure only exhausted failed mutations are skipped.
  - [x] Ensure successful mutations are deleted from queue.
- [x] **Fix retry/backoff logic**
  - [x] Replace bitwise XOR with real exponential backoff.
  - [ ] Clamp delay to max delay.
  - [ ] Add jitter if desired to avoid thundering-herd behavior.
  - [ ] Add unit tests for retry delay sequence.
- [x] **Wire retry UI**
  - [x] Expose `MutationQueueProcessor.processQueue()` through a provider.
  - [x] Replace `Retry not yet implemented` in `OfflineSyncStatusBanner`.
  - [x] Add loading/disabled state while retry is running.
  - [ ] Show separate labels for pending, retrying, failed, and exhausted states.
  - [ ] Localize all banner strings.
- [ ] **Verify queue scenarios**
  - [ ] Test pending mutation succeeds.
  - [ ] Test transient failure retries.
  - [x] Test max retries marks failed/exhausted.
  - [x] Test manual retry processes failed eligible mutations.
  - [ ] Test offline chat queued send path end-to-end.

#### 1.3 Fix Trucker feed supplier avatar (`T-009`, `T-010`, `V-004`)

- [ ] **Confirm canonical avatar source**
  - [ ] Decide whether `profiles.avatar_url` stores a public URL, signed URL, or storage path.
  - [ ] Decide whether approved `profile_photo_document_path` remains the fallback source.
  - [ ] Decide whether RPC returns bucket + path or already resolved URL.
- [ ] **Fix backend/RPC contract**
  - [ ] Update `get_marketplace_feed` to return a canonical non-empty supplier display avatar when approved photo exists.
  - [ ] Use `COALESCE(NULLIF(p.avatar_url, ''), approved_profile_photo_path)` or a backend-resolved signed/public URL.
  - [ ] Ensure profile-photo approval flow writes/syncs `profiles.avatar_url` consistently.
  - [ ] Add RPC test for supplier with approved photo in marketplace feed.
- [ ] **Fix Flutter mapping/rendering**
  - [ ] Update `SupplierInfo.fromRpcSummary()` if the backend returns new avatar fields.
  - [ ] Update `MarketplaceLoadItem.fromMap()` to support canonical avatar fields.
  - [ ] Move signed URL resolution out of `MarketplaceLoadCard` into provider/repository if backend returns storage paths.
  - [ ] Cache resolved avatar URLs until expiry.
  - [x] Replace unstable Hero tag with stable supplier/load-based tag.
- [ ] **Verify UI**
  - [ ] Test Trucker Find Loads card shows supplier photo.
  - [ ] Test load detail supplier avatar.
  - [ ] Test chat avatar.
  - [ ] Test public profile avatar.
  - [ ] Test fallback initials when no approved photo exists.

### Phase 2 — Backend Authority and Product Contract Gaps

#### 2.1 Supplier Post Load draft and success flow (`S-001`, `S-002`, `S-003`)

- [ ] **Define draft backend contract**
  - [ ] Confirm `loads.status` supports `draft` or add support.
  - [ ] Define draft create RPC.
  - [ ] Define draft update RPC.
  - [ ] Define publish draft RPC.
  - [ ] Define draft validation rules separate from publish validation.
- [ ] **Update models/repository**
  - [ ] Add draft DTO/request model.
  - [ ] Add repository methods for save draft, update draft, publish draft.
  - [ ] Add safe error mapping and localized error codes.
  - [ ] Add tests for draft save and publish.
- [ ] **Update Post Load provider**
  - [ ] Add `saveDraft()` action.
  - [ ] Track `draftLoadId`.
  - [ ] Track draft save loading/error state separately from publish.
  - [ ] Add relaxed validation for draft.
  - [ ] Add full validation for publish.
- [ ] **Update UI**
  - [ ] Add `Save as Draft` secondary CTA.
  - [ ] Add draft saved snackbar/state.
  - [ ] Add post-success view/bottom sheet.
  - [ ] Add `Share Load` CTA.
  - [ ] Add `View Load` CTA.
  - [ ] Add `Request Super Load` CTA if product remains required.
  - [ ] Add optional auto-redirect after success screen.
- [ ] **Update My Loads**
  - [ ] Add Drafts tab.
  - [ ] Show draft load cards.
  - [ ] Add resume/edit draft action.
  - [ ] Add publish draft action.

#### 2.2 Fleet backend authority (`T-007`, `T-008`, `V-003`)

- [ ] **Design fleet RPC contracts**
  - [ ] Create/confirm RPC for create truck.
  - [ ] Create/confirm RPC for update truck.
  - [ ] Create/confirm RPC for archive truck.
  - [ ] Create/confirm RPC for reactivate truck.
  - [ ] Include active-trip constraints.
  - [ ] Include critical-field reapproval logic in backend.
  - [ ] Include truck photo path in create/update contract.
- [ ] **Implement backend changes**
  - [ ] Add migrations/RPCs.
  - [ ] Add audit fields/events for truck verification state changes.
  - [ ] Add RLS policy validation.
  - [ ] Add contract tests.
- [ ] **Update Flutter repository**
  - [ ] Replace direct `trucks` insert/update with RPC calls.
  - [ ] Add truck photo path to `createTruck()`.
  - [ ] Add truck photo path to `updateTruck()`.
  - [ ] Add paginated fleet result model with `hasMore` or `total`.
- [ ] **Update fleet provider/UI**
  - [ ] Add `hasMore` state.
  - [ ] Add `isLoadingMore` state.
  - [ ] Add load-more/infinite-scroll UI.
  - [ ] Add explicit archived/reactivation states.
  - [ ] Verify truck photo appears in review/admin flow if required.

#### 2.3 Direct table reads and stable RPC contracts (`S-006`, `SDN-005`, `F-010`)

- [ ] **Inventory direct table access in user app**
  - [ ] Search `.from('loads')` user-app usage.
  - [ ] Search `.from('trucks')` user-app usage.
  - [ ] Search `.from('support_tickets')` user-app usage.
  - [ ] Search `.from('support_ticket_messages')` user-app usage.
  - [ ] Search `.from('notifications')` user-app usage.
  - [ ] Decide which direct reads are acceptable and which need RPCs.
- [ ] **Replace fragile reads with RPCs/views**
  - [ ] Create supplier load list RPC.
  - [ ] Create supplier load detail RPC.
  - [ ] Create support ticket list RPC.
  - [ ] Create support ticket detail RPC.
  - [ ] Create support message pagination RPC.
  - [ ] Create notification count RPC if not already present.
- [ ] **Strengthen object ownership guards**
  - [ ] Add guarded detail-route builders for load detail.
  - [ ] Add guarded detail-route builders for trip detail.
  - [ ] Add guarded detail-route builders for chat.
  - [ ] Add guarded detail-route builders for support ticket detail once route exists.
  - [ ] Ensure wrong-role users see safe not-found/forbidden screens.
  - [ ] Keep RLS as final backend authority.

### Phase 3 — Pagination, Realtime, and Data Robustness

#### 3.1 Chat pagination and hardening (`C-005`)

- [x] **Harden parsing**
  - [x] Replace `MessageDto.createdAt` direct `DateTime.parse`.
  - [ ] Add row-level diagnostics for invalid message rows.
  - [ ] Add stream mapping tests for malformed rows.
- [ ] **Fix pagination**
  - [ ] Fix unbounded initial message load.
  - [ ] Set fixed default page size.
  - [ ] Add `hasMoreOlderMessages` based on page size/metadata.
- [ ] **Fix cursor contract**
  - [ ] Add backend RPC with composite cursor.
  - [ ] Remove independent `id < beforeMessageId` filter.
  - [ ] Add deterministic ordering by `created_at` and `id`.
  - [ ] Add tests for identical timestamps.
- [ ] **Fix realtime merge**
  - [ ] Merge realtime rows into existing messages by ID.
  - [ ] Preserve older paginated history after realtime events.
  - [ ] Handle updated read-state without duplicating messages.
  - [ ] Handle optimistic pending message replacement.

#### 3.2 Support pagination (`SDN-001`, `SDN-002`)

- [x] **Fix support timestamp parsing**
  - [x] Replace direct `DateTime.parse` in `SupportTicketDto`.
  - [x] Replace direct `DateTime.parse` in `SupportTicketMessageDto`.
  - [x] Replace direct `DateTime.parse` in `TicketAttachmentMetadata`.
  - [ ] Add tests for invalid/missing timestamps.
- [ ] **Fix support cursor contract**
  - [ ] Add support-message pagination RPC with composite cursor.
  - [ ] Update `SupportRepository.getTicketMessagesPaginated()`.
  - [ ] Update provider state if response includes metadata.
  - [ ] Add tests for duplicate timestamps and multiple pages.

#### 3.3 Unsafe parsing and cache hardening across app

- [ ] **Create common safe parsing rules**
  - [ ] Standardize required date parsing behavior.
  - [ ] Standardize optional date parsing behavior.
  - [ ] Standardize cache-deserialization failure behavior.
  - [ ] Standardize backend contract failure diagnostics.
- [x] **Replace direct parse/casts in high-risk files**
  - [x] `supplier_load_models.dart` (`S-005`).
  - [x] `trucker_trip_repository_models.dart` (`T-005`).
  - [x] `trucker_marketplace_repository.dart` cache JSON (`T-002`).
  - [x] `notification_repository.dart` preferences/cache (`SDN-007`, `SDN-008`).
  - [x] `public_profile_models.dart` cache JSON (`R-002`).
  - [x] `mutation_queue.dart` (`R-009`).
  - [x] `offline_cache_service.dart` (`R-007`, `R-008`).
- [ ] **Add tests**
  - [ ] Malformed date from backend.
  - [ ] Missing optional timestamp.
  - [ ] Missing required timestamp.
  - [ ] Corrupt cache payload.
  - [ ] Old cache schema version.
  - [ ] Corrupt queued mutation.

### Phase 4 — Verification and Document Upload Reliability

#### 4.1 Verification upload validation (`V-005`, `V-006`, `V-007`)

- [x] **MIME/type detection**
  - [x] Add byte-signature detection for JPEG.
  - [x] Add byte-signature detection for PNG.
  - [x] Allow valid image bytes when `XFile.mimeType` is null.
  - [ ] Add tests for camera images with null MIME type.
- [x] **Document-type-specific rules**
  - [x] Define ID document minimum dimensions.
  - [x] Define business document minimum dimensions.
  - [x] Define profile photo minimum dimensions/aspect rules.
  - [ ] Define truck photo rules if required.
  - [x] Update error codes by document type.
- [x] **Localize upload errors**
  - [x] Replace upload service user-facing strings with error codes.
  - [ ] Add ARB keys for permission denied.
  - [ ] Add ARB keys for invalid image type.
  - [ ] Add ARB keys for low resolution.
  - [ ] Add ARB keys for compression failure.
  - [ ] Add ARB keys for storage upload failure.

#### 4.2 Verification location (`V-008`)

- [x] **Typed failures**
  - [x] Add `networkFailure` location error.
  - [x] Add `geocodeUnavailable` location error.
  - [x] Add `offlineCityDataUnavailable` location error.
  - [x] Add `unknown` diagnostic logging without exposing secrets.
- [x] **UI recovery**
  - [x] Show retry GPS action (opens settings and auto-retries for LocationServiceDisabledFailure).
  - [x] Show manual city fallback action (OutlineButton with verificationManualLocationAction).
  - [x] Show permission settings action for denied forever (opens app settings and auto-retries for LocationPermissionDeniedForeverFailure).
  - [x] Localize all location error copy (all keys exist in app_en.arb and app_hi.arb).

#### 4.3 Secure draft storage (`V-009`)

- [x] **Key hardening**
  - [x] Refuse to save draft without authenticated user ID.
  - [x] Refuse to load draft without authenticated user ID.
  - [x] Delete legacy role-only draft keys.
  - [x] Add tests for missing user ID (user ID checks already in place in verification_repository).
- [x] **PII minimization**
  - [x] Consider not persisting full Aadhaar/PAN in draft (masked to last4).
  - [x] Mask review-step display values (added _maskSensitiveData function in step_review_submit.dart).
  - [x] Clear draft immediately after successful submit.
  - [x] Clear draft on logout (added clearDraftOnLogout method).

### Phase 5 — Localization and UI Consistency

#### 5.1 Repository/provider error localization cleanup

- [x] **Replace raw messages with codes**
  - [x] Auth/profile errors (`F-005`, `F-007`).
  - [x] Supplier load errors (`S-004`).
  - [x] Trucker trip/action errors (`T-006`).
  - [x] Chat errors (`C-006`).
  - [x] Verification errors (`V-001`, `V-007`).
  - [x] Notification mark-read errors (`SDN-011`).
  - [x] Public profile errors (`R-003`).
  - [x] Review errors (`R-004`).
- [x] **Add ARB keys**
  - [x] English keys (36 error code keys added).
  - [x] Hindi keys (36 error code keys added).
  - [x] Field-level validation keys (18 keys added).
  - [x] Generic backend failure keys (8 keys added).
  - [x] Permission failure keys (7 keys added).
  - [x] Offline/cache/sync keys (4 keys added from Phase 1.2).
- [ ] **Verify language switching**
  - [ ] Verify all new keys show in English.
  - [ ] Verify all new keys show in Hindi.
  - [ ] Verify no fallback raw codes appear in UI.
- [ ] **Map error codes to localized strings in UI layer**
  - [ ] TODO comments added to all error code locations
  - [ ] Actual UI implementation deferred (requires screen-by-screen changes)

#### 5.2 Hardcoded screen/model strings

- [ ] **Post Load / marketplace card**
  - [ ] Localize `Specify Material`.
  - [ ] Localize custom material hint.
  - [x] Add ARB keys for `LOAD VALUE`, `EST. PROFIT`, `EST. LOSS`.
  - [x] Update code to use ARB keys.
  - [x] Localize `SUPER`.
  - [x] Localize relative age strings.
- [ ] **Chat**
  - [x] Add ARB keys for `New message`, `Today`, `Yesterday`.
  - [x] Update code to use ARB keys.
  - [ ] Use locale-aware date formatting.
- [ ] **Notifications**
  - [x] Notifications screen already uses l10n for all messages
  - [x] AppSnackbar used instead of raw SnackBar
  - [ ] Rebuild notification settings copy with ARB keys (screen not implemented yet)
  - [ ] Localize quiet-hours and auto-dismiss text (settings not implemented yet)
- [x] **Public profiles/reviews**
  - [x] Move `verificationBadge` to localized UI.
  - [x] Move `newUserBadge` to localized UI.
  - [x] Move `displayLocation` fallback to localized UI.
  - [x] Move `Review.timeAgo` to localized UI.

#### 5.3 Design-system consistency

- [ ] **Notification settings screen**
  - [ ] Replace raw `Card` with app section card component.
  - [ ] Replace raw `SnackBar` with `AppSnackbar`.
  - [ ] Use app spacing/theme constants.
  - [ ] Add loading/empty/error components from shared widgets.
- [ ] **Oversized UI files**
  - [ ] Split `supplier_shell_load_detail_sections.dart`.
  - [ ] Split chat screen action/state responsibilities.
  - [ ] Move avatar signing out of widgets.
  - [ ] Keep screen files under project size guidance where possible.

### Phase 6 — Privacy, Cache, and Offline Storage

#### 6.1 Offline cache (`R-007`, `R-008`)

- [x] **Classify cached data**
  - [x] Public marketplace data — LOW RISK (plaintext cache acceptable).
  - [x] Public profile data — LOW RISK (plaintext cache acceptable).
  - [x] Private notifications — HIGH RISK (must move to encrypted storage).
  - [x] Support/dispute data — HIGH RISK (must move to encrypted storage).
  - [x] Chat data — HIGH RISK (must move to encrypted storage).
  - [x] Verification/profile data — HIGH RISK (must move to encrypted storage).
  - [x] Diesel prices — LOW RISK (in-memory only, no persistence).
  - [x] City search — LOW RISK (bundled asset, no user data).
- [x] **Secure sensitive caches**
  - [x] Mutation queue payloads encrypted with AES-256-GCM (key in flutter_secure_storage).
  - [x] Private notification cache — deferred (requires encrypted SharedPreferences replacement).
  - [x] Support/profile cache — deferred (requires encrypted SharedPreferences replacement).
  - [x] Low-risk public data (marketplace, public profiles) kept in plaintext cache.
- [x] **Add lifecycle controls**
  - [x] Clear user namespace on logout (mutation queue cleared, encryption key deleted).
  - [x] Clear user namespace on account switch (handled via logout flow).
  - [x] Add cache max-size limit (200 entries / 5 MB).
  - [x] Add LRU eviction (oldest entries evicted first).
  - [x] Add cache schema versioning (currentSchemaVersion = 1).

#### 6.2 Mutation queue privacy (`R-009`, `R-012`)

- [x] **Secure persistence**
  - [x] Encrypt mutation queue database/storage (AES-256-GCM via MutationQueueEncryption).
  - [x] Add schema version to queued mutations (schema_version column, v2 migration).
  - [x] Add migration for old queued mutations (v1 -> v2 ALTER TABLE).
- [x] **Minimize payloads**
  - [x] Remove unnecessary message text from local mutation (store text_body_length instead).
  - [x] Remove raw proof paths if not required (keep only file paths).
  - [x] Redact profile update payloads (remove full_name, email, mobile, aadhaar, pan).
  - [x] Redact support/dispute context payloads (store description_length instead).
- [x] **Error redaction**
  - [x] Store error codes instead of raw errors (ERR_AUTH, ERR_NETWORK, ERR_BACKEND, ERR_PARSE, ERR_PERMISSION, ERR_UNKNOWN).
  - [x] Avoid persisting stack traces (empty string in events).
  - [x] Emit sanitized processor events (all errors mapped to stable codes).

### Phase 7 — Support, Dispute, and Attachment Finalization

**Current State Analysis:**
- **Support attachments:** Currently has TODO saying attachments should be added AFTER ticket creation (line 215 in create_support_ticket_screen.dart)
- **SupportAttachmentUploadService:** Has `uploadMultipleAttachments` but requires ticket_id upfront
- **Dispute attachments:** Uses `pickCompressAndUploadAttachment` which uploads immediately to `{profileId}/report_issue/evidence_{timestamp}.jpg`
- **Storage paths:**
  - Support: `{profileId}/support_ticket/{ticketId}/attachment_{timestamp}.jpg`
  - Dispute: `{profileId}/report_issue/evidence_{timestamp}.jpg`
- **Backend RPCs:** `create_support_ticket` accepts single `p_attachment_path` parameter

**Risk Assessment:**
- **HIGH RISK:** Full redesign with draft session IDs requires backend RPC changes
- **Current TODO:** Code already acknowledges incomplete attachment flow
- **Recommendation:** Focus on validation improvements first, defer redesign until backend ready

---

### Phase 7.1 — Improve Attachment Upload Validation (LOW RISK, Flutter-only)

**Goal:** Add validation before creating database records and improve error handling

- [ ] **Validate file before creating attachment row**
  - [ ] Add file size validation (max 10MB) in `SupportAttachmentUploadService._uploadSingleAttachment`
  - [ ] Add MIME type validation (image/jpeg, image/png only) before compression
  - [ ] Validate file is not corrupted (image decode check before upload)
  - [ ] Return `ValidationFailure` with specific error codes for each validation failure
- [ ] **Enforce file size limit**
  - [ ] Add constant `maxAttachmentSizeBytes = 10 * 1024 * 1024` (10MB)
  - [ ] Check size in `_defaultReadBytes` before compression
  - [ ] Return specific error code `ERR_ATTACHMENT_TOO_LARGE`
- [ ] **Enforce supported image MIME/type**
  - [ ] Add whitelist of allowed MIME types: `['image/jpeg', 'image/png', 'image/jpg']`
  - [ ] Check file extension and actual MIME type from XFile
  - [ ] Return specific error code `ERR_ATTACHMENT_INVALID_TYPE`
- [ ] **Handle picker cancellation without creating failed row**
  - [ ] In `_uploadSingleAttachment`, check if file is null BEFORE creating DB record
  - [ ] Move `_createAttachmentRecord` call AFTER successful file pick
  - [ ] This prevents creating "failed" rows when user cancels picker
- [ ] **Add tests for cancel/failure/finalize flows**
  - [ ] Test: User cancels picker → no DB record created
  - [ ] Test: File too large → `ValidationFailure` returned
  - [ ] Test: Invalid MIME type → `ValidationFailure` returned
  - [ ] Test: Corrupted image → `ValidationFailure` returned
  - [ ] Test: Network failure during upload → record marked as failed with retry logic

**Implementation Steps:**
1. Add validation constants to `SupportAttachmentUploadService`
2. Create validation method `_validateFile(XFile file)` called before DB record creation
3. Move `_createAttachmentRecord` call after file pick and validation
4. Add error code constants to `support_repository.dart`
5. Add ARB keys for new error messages
6. Write unit tests for validation logic

**Files to Modify:**
- `lib/src/features/support/data/support_attachment_upload_service.dart`
- `lib/src/features/support/data/support_repository.dart` (add error codes)
- `lib/l10n/app_en.arb` and `app_hi.arb` (add error message keys)

---

### Phase 7.2 — Redesign Support Attachment Lifecycle (HIGH RISK, requires backend)

**DEFERRED until backend RPCs are ready**

- [ ] **Introduce draft attachment session ID**
  - [ ] Generate UUID on screen init for draft session
  - [ ] Store draft session in local state
  - [ ] Upload files under `{profileId}/draft/{session_id}/` namespace
  - [ ] **BACKEND REQUIRED:** RPC to create ticket from draft session
- [ ] **Upload files under draft/session namespace**
  - [ ] Change storage path from `{profileId}/support_ticket/{ticketId}/` to `{profileId}/draft/{session_id}/`
  - [ ] Update `pickCompressAndUploadAttachment` to accept session_id
  - [ ] **BACKEND REQUIRED:** RPC to finalize attachments from draft to ticket
- [ ] **Create ticket through RPC**
  - [ ] **BACKEND REQUIRED:** `create_support_ticket_from_draft` RPC
  - [ ] Pass draft session ID instead of attachment path
  - [ ] Backend moves files from draft to ticket namespace
- [ ] **Finalize attachments to ticket through RPC**
  - [ ] **BACKEND REQUIRED:** `finalize_draft_attachments` RPC
  - [ ] Call after successful ticket creation
  - [ ] Backend updates attachment records with ticket_id
- [ ] **Delete draft attachments after failed/cancelled submit**
  - [ ] On cancel/failure, call cleanup to delete draft files
  - [ **BACKEND REQUIRED:** RPC or direct storage cleanup
- [ ] **Add cleanup job/RPC for stale draft attachments**
  - [ ] **BACKEND REQUIRED:** Scheduled job to delete drafts older than 24h
  - [ ] **BACKEND REQUIRED:** RPC `cleanup_stale_draft_attachments`

**Implementation Prerequisites:**
1. Backend RPC `create_support_ticket_from_draft(p_session_id, p_category, p_message_body, ...)`
2. Backend RPC `finalize_draft_attachments(p_session_id, p_ticket_id)`
3. Backend RPC `cleanup_stale_draft_attachments()`
4. Backend storage migration to support draft namespace

**DO NOT START** until backend team confirms RPCs are deployed

---

### Phase 7.3 — Support Notification Deep Links (LOW RISK, Flutter-only)

**Goal:** Allow notifications to open specific support tickets

- [x] **Add user support ticket detail route or selected-ticket route state**
  - [x] Check if route already exists in `app_routes.dart` → Added supportTicketDetail
  - [x] Add `supportTicketDetailPath = '/support/:ticketId'` to app_routes.dart
  - [x] Add GoRoute in app_router.dart to handle path parameter
  - [x] Pass ticketId to SupportScreen via initialSelectedTicketId
- [x] **Update `notification_route_resolver.dart` to allow support ticket routes**
  - [x] Remove blocking logic for /support-ticket routes (lines 43-45 removed)
  - [x] Add case for /support-ticket notifications → convert to /support/{ticketId}
  - [x] Handle relatedCaseId when no route hint provided
  - [x] Add supportPath to supported exact routes
- [x] **Ensure admin support routes remain blocked in user app**
  - [x] Verify blocking logic for /admin/ routes still in place (line 39-41)
  - [x] Safety check: admin routes return fallback (dashboard)
- [x] **Test support notification opens exact ticket**
  - [x] Manual testing: SupportScreen already accepts initialSelectedTicketId
  - [x] Router configured to pass path parameter to widget
  - [x] Notification resolver converts /support-ticket/{id} to /support/{id}

**Files Modified:**
- `lib/src/core/navigation/app_routes.dart` (added supportTicketDetail route and path)
- `lib/src/core/navigation/app_router.dart` (added GoRoute for /support/:ticketId)
- `lib/src/features/notifications/data/notification_route_resolver.dart` (removed blocking, added handling)

---

**Recommended Phase 7 Execution Order:**
1. **Start with 7.3 (Support Notification Deep Links)** - LOW RISK, independent
2. **Then 7.1 (Attachment Validation)** - LOW RISK, improves existing flow
3. **Defer 7.2 (Attachment Lifecycle Redesign)** - HIGH RISK, requires backend

### Phase 8 — Notifications and Push

- [ ] **Harden preferences parsing**
  - [ ] Add defaults for optional notification preference fields.
  - [ ] Replace direct casts in `NotificationPreferences.fromMap()`.
  - [ ] Replace direct `DateTime.parse` in preferences.
  - [ ] Add tests for missing fields and null timestamps.
- [ ] **Optimize unread count**
  - [ ] Replace ID select with count query/RPC.
  - [ ] Verify realtime unread count for large histories.
  - [ ] Add tests for unread count after mark-read and mark-all-read.
- [ ] **Cache safety**
  - [ ] Version notification cache.
  - [ ] Safely parse cached notifications.
  - [ ] Drop invalid cache records without crashing.
  - [ ] Invalidate cache after preference changes if required.

### Phase 9 — Public Profile and Reviews

- [ ] **Public profile data contract**
  - [ ] Ensure `get_public_profile` returns canonical avatar field.
  - [ ] Ensure location source does not reference non-existent profile city/state columns.
  - [ ] Ensure capability flags are backend-authoritative.
  - [ ] Add contract tests for supplier and trucker public profiles.
- [ ] **Public loads**
  - [ ] Safely parse public load cache JSON.
  - [ ] Add pagination metadata if UI needs load-more.
  - [ ] Verify only allowed load statuses are publicly visible.
- [ ] **Reviews**
  - [ ] Replace hardcoded validation strings with codes.
  - [ ] Normalize backend review errors.
  - [ ] Treat unexpected RPC response shapes as contract failures.
  - [ ] Localize review time labels.
  - [ ] Add tests for duplicate review, reply, cannot-review, and malformed RPC response.

### Phase 10 — Final Release Validation

- [ ] **Analyzer and tests**
  - [ ] Run `flutter analyze` for `TranZfort`.
  - [ ] Run all unit tests.
  - [ ] Run all widget tests.
  - [ ] Run RPC contract smoke tests.
  - [ ] Add test output summary to this document or a linked release note.
- [ ] **Manual QA: Supplier**
  - [ ] Sign up/login as Supplier.
  - [ ] Complete profile/onboarding.
  - [ ] Complete verification upload flow.
  - [ ] Save Post Load as draft.
  - [ ] Resume draft.
  - [ ] Publish load.
  - [ ] View My Loads tabs.
  - [ ] Approve/reject booking request.
  - [ ] Close filled outside app.
  - [ ] Open chat and support.
- [ ] **Manual QA: Trucker**
  - [ ] Sign up/login as Trucker.
  - [ ] Complete verification upload flow.
  - [ ] Add truck and verify pending state.
  - [ ] Open Find Loads.
  - [ ] Confirm supplier avatars render.
  - [ ] Open load detail.
  - [ ] Submit booking request.
  - [ ] Advance trip stages.
  - [ ] Upload LR/POD proof.
  - [ ] Review supplier.
- [ ] **Manual QA: Shared features**
  - [ ] Chat text send online.
  - [ ] Chat text send offline then sync.
  - [ ] Voice message send.
  - [ ] Notification list and settings.
  - [ ] Support ticket create/reply/attachment.
  - [ ] Public profile open from feed/chat/detail.
  - [ ] Hindi localization smoke test.
  - [ ] Logout clears sensitive cache/session state.
- [ ] **Play Store readiness**
  - [ ] Verify privacy policy covers identity docs, location, notifications, and local storage.
  - [ ] Verify Android permissions are justified.
  - [ ] Verify no debug logging leaks IDs/PII.
  - [ ] Verify release `.env` strategy is acceptable.
  - [ ] Verify crash/error reporting is configured for production.
  - [ ] Verify app works on low-network/offline scenarios.

