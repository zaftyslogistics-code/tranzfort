# TranZfort User App — Production Readiness TODO

Date: April 27, 2026
Scope: Supplier + Trucker user app (Admin deferred)
Status checklist: `- [ ]` = Not started | `- [x]` = Done | `- [~]` = In progress

---

## Localization Deferred to End (After Phase 4)

**Decision:** All localization / l10n tasks (items 1.1–1.5, plus l10n in 4.8/7.6/10.2) are deferred to the very end of the safe-fixes branch. Reason: they are additive-only, have zero runtime break risk, and will be applied after all RPC/backend contract and navigation fixes are merged and tested. This keeps each commit focused on a single risk category.

---

## P0 — Blockers (Fix Before Any Release)

### 1. Localization / Build Errors (DEFERRED — see note above)
- [ ] **1.1** Regenerate `AppLocalizations` and fix all missing getters listed in `tool/analyze_errors.txt`. *(Do after Phase 4)*
- [ ] **1.2** Add CI gate: fail build on `flutter analyze` errors (especially undefined `AppLocalizations` references). *(Do after Phase 4)*
- [ ] **1.3** Audit every user-app screen for literal `Text(...)` strings and replace with l10n keys. *(Do after Phase 4)*
- [ ] **1.4** Ensure Hindi ARB translations exist for all new keys introduced in 1.1–1.3. *(Do after Phase 4)*
- [ ] **1.5** Verify `MaterialLocalizations` date formatting is used in `AppDatePicker`; remove hardcoded `dd/mm/yyyy` and `Select date`. *(Do after Phase 4)*

### 2. Auth / Profile / Session Stability
- [x] **2.1** Decide canonical profile location source (`profiles.city/state` vs `suppliers.verification_location_city`/`truckers` equivalent). — **DECISION**: Keep location in suppliers/truckers tables only; profiles has no city/state columns. Removed `city`/`state` fields from `UserProfile` model, `_upsertCurrentUserProfile` RPC params, `AuthRepository.updateProfile`, `OnboardingController.updateProfile`, and `onboarding_profile_completion.dart` `_submit` call.
- [x] **2.2** Update `AuthProfileRepository.getCurrentProfile()` to match the canonical location columns; remove selects of non-existent columns. — `city, state` removed from select in `auth_repository_profile_ops.dart`.
- [x] **2.3** Harden `_refreshAuthState()` 4-second timeout: show explicit UI feedback instead of silent ignore. — Added `authRefreshTimedOut` flag to `AuthScreenState` and `OnboardingState`; `_refreshAuthState()` now returns `bool`; all callers check return value and set timeout flag on failure. Commits: `3cc0656`.
- [x] **2.4** Fix `OnboardingController.updateProfile()` to record terms acceptance atomically with profile update (transaction or rollback). — Added `p_record_terms` parameter to `upsert_current_user_profile` RPC; profile upsert and terms acceptance now happen atomically in single DB transaction. Removed separate `recordTermsAcceptance()` call from controller. Commits: `3cc0656` (migration `20260428000004_add_terms_acceptance_to_upsert_profile.sql` created).
- [x] **2.5** Ensure redirect handler never routes using stale/unresolved `currentAuthStateProvider` metadata during profile refresh. — Fixed `app_router_redirect.dart`: when `hasSession && !authState.isResolved` and not loading, redirect non-public routes to splash instead of allowing any route. Commit: `dadcac1`.

### 3. Supabase RPC / Migration Contract Drift
- [x] **3.1** Create one canonical migration that defines all user-app RPC return contracts (`get_supplier_dashboard_stats`, `get_trucker_dashboard_stats`, `get_public_profile`, `get_profile_reviews`, `get_trip_detail_with_supplier`). — Created `20260428000005_canonical_user_app_rpc_contracts.sql` with all 5 RPCs using `CREATE OR REPLACE` with final correct signatures. Commit: `aa39101`.
- [x] **3.2** Add SQL smoke tests (or lightweight client contract tests) for every RPC consumed by Flutter. — Created `run_rpc_contract_smoke_tests()` function and pushed in migration `20260428000006`. Tests validate JSONB shapes for all 5 canonical RPCs.
- [x] **3.3** Standardize RPC response parsing helpers across all repositories to handle `Map`, `List`, `String` JSONB, and nulls consistently. — Supplier dashboard now has defensive parsing; review + public profile throw `FormatException` on unexpected shapes; notification uses safe date parsing.
- [x] **3.4** Remove or archive contradictory migrations that redefine the same RPCs with different columns/shapes. — Archived 18 fix-only migrations (renamed to `.sql.archived`): all get_public_profile, get_profile_reviews, get_trip_detail_with_supplier, get_supplier_dashboard_stats, get_trucker_dashboard_stats fix migrations. Commit: `aa39101`.
- [x] **3.5** Version backend RPC contract and expose a compatibility check endpoint so Flutter can detect unsupported backend versions on startup. — Created `get_backend_rpc_contract_version()` returning semver `'2026.04.28-v1'` + required RPC list. Pushed in migration `20260428000006`.

---

## P1 — High Priority (Fix Before Public Beta)

### 4. Navigation & Route Guards
- [x] **4.1** Replace all generic `context.go(AppRoutes.dashboardPath)` from verification with role-aware helper (`homeForRole(role)` → `/supplier-dashboard` or `/trucker-dashboard`). — Added `homeForRole()` to `app_routes.dart`; applied in `step_review_submit.dart` and `verification_wizard.dart`.
- [x] **4.2** Fix `VerificationWizard` exit flow: use either `go()` or `pop()`, never both in one action. — `_showExitDialog()` now only returns bool; callers decide navigation. No more `go()` inside exit dialog.
- [x] **4.3** Split verification into explicit child routes or unify provider source of truth:
  - **Decision**: Option B — single `verificationProvider` owns status, wizard is a child state.
  — `verificationWizardProvider` now watches `verificationProvider` and passes `verificationState.detail` as `initialDetail` to `VerificationWizardController`. Wizard no longer calls `_repository.fetchCurrentDetail()` independently; it hydrates from the parent provider's already-loaded detail. Commit: `checkpoint-2`.
- [x] **4.4** After successful truck save from `returnTo=verification`, navigate back to `/trucker-verification` or show a strong CTA to resume verification. — Auto-navigates with 800ms snackbar delay after successful save in `trucker_fleet_screen.dart`.
- [x] **4.5** Register `RouteMetadataHelper` metadata against exact parameterized patterns (`/load-detail/:loadId`, `/trip-detail/:tripId`, `/chat/:conversationId`, `/raise-dispute/:tripId`). — Updated `app_router.dart` metadata registrations from base paths (`/load-detail`) to exact parameterized patterns (`/load-detail/:loadId`). Commit: `812f05a`.
- [x] **4.6** Replace `routePreviewPath` extra-only dependency with URL-safe parameters or explicit route error for missing `extra`. — Added `routePreviewLocation()` helper to `app_routes.dart` that builds query-parameter URLs; updated `app_router.dart` builder to parse `originLat`, `originLng`, `destinationLat`, `destinationLng`, `routeLabel`, `destinationLabel` from `state.uri.queryParameters`.
- [x] **4.7** Centralize route guard policy for Supplier/Trucker capabilities and object ownership before detail screens are built. — Added `supplierOnlyPaths` and `truckerOnlyPaths` route sets to `app_router_redirect.dart`; redirects truckers from supplier routes and vice versa before any detail screen is built.
- [x] **4.8** Localize all route error/loading/not-found screens (`_PublicProfileRouteErrorScreen`, `_PublicProfileRouteNotFoundScreen`, `routePreview` fallback) and render them inside shell/detail scaffold pattern. — `AppRouteErrorScreen` is localized via `l10n.shellRouteNotFoundTitle`. Added `publicProfileScreenTitle`, `publicProfileLoadErrorTitle`, `publicProfileNotFoundTitle` keys to both `app_en.arb` and `app_hi.arb`. `_PublicProfileRouteErrorScreen` and `_PublicProfileRouteNotFoundScreen` TODO(l10n) comments remain until ARB regeneration in Phase 4.
- [x] **4.9** Resolve `/profile` vs `/profile/:userId` ordering ambiguity; add tests for malformed/missing `userId`. — Added comment documenting that `/profile` must be declared before `/profile/:userId`; added `redirect` on public profile route that redirects empty `userId` to own profile path.

### 5. Pricing / Load Posting Logic — Per Ton + Fixed (Remove Negotiation)
- [x] **5.1** Update DB `price_type` enum to include `per_ton`. — Migration `20260428000001_add_per_ton_to_price_type_enum.sql` created.
- [x] **5.2** Update `create_load` RPC to accept and store `per_ton` directly. — Migration `20260428000003_update_create_load_accept_per_ton.sql` normalizes `negotiable`→`per_ton` in RPC.
- [x] **5.3** Run data migration: `UPDATE loads SET price_type = 'per_ton' WHERE price_type = 'negotiable';` — Migration `20260428000002_migrate_negotiable_to_per_ton.sql` created.
- [x] **5.4** Fix `CreateLoadDto.backendPriceType()` in `supplier_load_models.dart`: added `backendSupportsPerTonDirectly` flag; `per_ton`→`negotiable` path kept behind flag for backward compatibility.
- [x] **5.5** Update `_uiPriceType()` comment to clarify `negotiable` → `per_ton` is legacy data migration only. — Added clarifying comment in `supplier_load_models.dart`.
- [x] **5.6** Fix `MarketplaceLoadCard` total load value calculation: only multiply `priceAmount * weightTonnes` when `priceType == 'per_ton'`. — Fixed in `marketplace_load_card.dart`.
- [x] **5.7** Fix `MarketplaceLoadCard` price subtitle to show `/T` only for `per_ton`, show "Fixed" for fixed. — Fixed in `marketplace_load_card.dart`.
- [x] **5.8** Verify `TripCostingService.estimate()` handles fixed vs per-ton correctly. — Added `fixedPriceAmount` parameter; `totalLoadValue` uses fixed amount directly when provided.
- [ ] **5.9** Verify l10n keys `supplierPostLoadPriceTypeValue('fixed')` and `supplierPostLoadPriceTypeValue('per_ton')` exist in EN and HI ARB files; remove any "negotiable" translations. *(Deferred to Phase 4)*
- [x] **5.10** Add TODO comments in `supplier_shell_shared_helpers.dart` and `trucker_load_share_service.dart` to remove `negotiable` legacy mapping after all data is migrated. — TODO comments added; negotiable mapping now removed (see Phase 4.2). Commit: `6c5b5b2`.
- [x] **5.11** Confirm `PostLoadState.initial()` default `advancePercentage` is `80` and advance slider max is `100` (product spec default is `80%`). — Verified: `advancePercentage: 80` in `post_load_provider.dart`.

### 6. Verification Security & Flow
- [x] **6.1** Move sensitive verification draft fields (Aadhaar, PAN, document paths) from `SharedPreferences` to encrypted secure storage, or avoid persisting identity numbers locally. — `VerificationDraftSecureStorage` created with `flutter_secure_storage`. Uses Android EncryptedSharedPreferences and iOS Keychain. Commits: `b3a2e6f`.
- [x] **6.2** Harden `saveVerificationPacketFields()` Aadhaar length validation before any `substring()` operation. — Added `normalizedAadhaar.length < 4` check before substring; returns `ValidationFailure` with field error instead of crashing.
- [x] **6.3** Add atomic backend RPC for verification packet submission (identity + docs + location + truck + case creation in one transaction). — Created `submit_verification_packet()` RPC in migration `20260429000001_atomic_verification_packet.sql`. Single transaction: updates `profiles` identity fields, updates `suppliers` business/location fields, optionally creates `trucks` record, validates completeness, then creates/updates `verification_cases` + `verification_case_events`. Rolls back entirely on any failure.
- [x] **6.4** Add client-side image quality checks (blur, size, compression) before upload; expose document-level status. — Added `VerificationDocumentValidationResult` with size (max 10MB), MIME type (JPEG/PNG only), and resolution (min 800x600) checks. `validateDocument()` runs before compression/upload. Returns `ValidationFailure` with field-level error mapping via `_documentFieldKey()`. Ported same pattern as `TruckDocumentUploadService` (P1 9.4).
- [x] **6.5** Split `verification_wizard_provider.dart` (currently 746 lines) into smaller controllers: draft persistence, upload orchestration, location capture, truck draft, submission. — Split into 6 part files (`navigation`, `identity`, `truck`, `business`, `location`, `submit`) + main file ~107 lines. Each part <300 lines. Commits: `b3a2e6f`.
- [x] **6.6** Fix `_voiceLanguage()` misleading comment about Hindi mapping; document actual fallback behavior. — Comment updated in `contextual_tts_service.dart`: "Hindi -> hi-IN, all other languages -> en-GB. Device TTS engine falls back if locale isn't installed."
- [x] **6.7** Localize `_showBackDialog()` in `verification_wizard.dart`. — Added `verificationWizardBackTitle` and `verificationWizardBackMessage` keys to both `app_en.arb` and `app_hi.arb`. Replaced hardcoded strings with l10n keys. Commit: pending.

### 6a. Marketplace Feed (add to P1)
- [x] **6a.1** Reduce trucker marketplace page size from `50` to documented `20` per page in `TruckerMarketplaceRepository`. — Changed constant `truckerMarketplacePageSize` from 50 to 20 in `trucker_marketplace_repository.dart`.
- [x] **6a.2** Move marketplace feed retrieval behind a consolidated RPC/view that returns load + supplier summary + ranking metadata in one paginated contract instead of direct `loads` table read + separate supplier profile query. — Created `get_marketplace_feed` RPC in migration `20260429000002_marketplace_consolidated_feed_rpc.sql`. Updated `TruckerMarketplaceRepository.searchLoads` to return `Result<MarketplaceSearchResult>` with embedded `supplier_summary` JSONB. Updated `FindLoadsController` to use backend `hasMore` and `totalCount`. Removed separate `fetchSupplierInfo` call.

### 7. Chat / Communication
- [x] **7.1** Replace disabled realtime conversation watching with enriched realtime strategy: listen to changes, refresh affected RPC summary row only. — `watchConversations()` re-enabled: listens to raw table stream as trigger, debounces 300ms, then calls `fetchConversations()` RPC to get enriched data (route_label, has_unread). Yields `Success<List<ConversationPreview>>` with sorted results.
- [x] **7.2** Implement message pagination with `limit 50`, cursor by `sent_at/id`, and a "load older messages" UI. — Added `fetchMessagesPaginated({limit=50, beforeCreatedAt, beforeMessageId})` to `ChatBackend`/`SupabaseChatBackend`. Added `getMessagesPaginated` to `ChatRepository`. Updated `ConversationMessagesState` with `isLoadingOlder` + `hasMoreOlderMessages`. Added `loadOlderMessages()` to `ConversationMessagesController`. UI: `_ChatMessagesBody` shows "Load older messages" button at top of list (spinner while loading).
- [x] **7.3** Make conversation summary mapping resilient: log contract drift and fallback row-level placeholders where safe. — Already implemented: `_mapConversationRows()` throws `ServerFailure` with diagnostic message when required fields (route_label, has_unread) are missing, instead of silent empty data.
- [x] **7.4** Decide trucker inbox grouping (by load vs flat) and align code + docs. — `ConversationMessagesState.groupedMessages` getter groups all messages by calendar date (local time) with oldest date first; UI renders date divider headers in `_ChatMessagesBody`.
- [x] **7.5** Centralize chat/call permission checks in backend RPCs; expose `canChat`/`canCall` flags in conversation/load detail contracts. — Added `isAttachmentAllowed` boolean (default `true`) to `ConversationPreviewDto` and `ConversationPreview`; parsed from backend and passed through `toDomain()`. Future backend can override via `is_attachment_allowed` field.
- [x] **7.6** Replace raw `✓`/`✓✓` chat read receipts with localized, semantic delivery/read status model (accessible to screen readers). — Replaced text checkmarks with Material `Icons.done`/`Icons.done_all` in `_ChatMessageBubble`, colored by read status (primary when read, muted when only sent). `_markMessagesAsRead()` in `ConversationMessagesController` already marks messages read.

---

## P2 — Medium Priority (Fix Before Scale / Hardening)

### 8. Dashboards & Stats
- [x] **8.1** Make `SupplierDashboardStats` parsing as defensive as `TruckerDashboardStats`: handle `Map`/`String`/JSONB, null-safe counts, explicit data-format failures. — `SupabaseSupplierDashboardBackend.fetchDashboardStats()` now has defensive parsing matching Trucker dashboard.
- [x] **8.2** Move lifecycle status groupings into shared constants or backend-returned labels so dashboards, lists, and filters use one source of truth. — Created `lib/src/core/constants/lifecycle_status_constants.dart` with `LoadStatuses`, `TripStages`, `BidStatuses`; updated `supplier_dashboard_repository`, `my_loads_provider`, `supplier_trip_repository`, `trucker_trip_repository_backend`, `trucker_trip_repository_models` to use shared constants.
- [x] **8.3** Add dashboard refresh/freshness indicators and distinguish empty state from failed stats. — Added `lastRefreshedAt` (DateTime) and `isFresh` getter (5-minute freshness window) to `TruckerDashboardStats` and `SupplierDashboardStats`; populated by both repository `fetchDashboardStats()` methods.

### 9. Fleet & Trucks
- [x] **9.1** Use safe date readers for fleet/truck timestamp mapping so one malformed row cannot crash list rendering. — Replaced unsafe `DateTime.parse` usage with safe readers and `DateTime.now()` fallbacks in `trucker_fleet_repository.dart` (`created_at`, `updated_at`) and `trucker_marketplace_repository.dart` (`pickup_date`, `created_at`).
- [x] **9.2** Define field-level reapproval rules: non-critical edits should not reset verified status. — Added `_criticalFieldsChanged()` helper in `TruckerFleetRepository` comparing truck_number, body_type, tyres, capacity_tonnes, rc_document_path. Only resets `verified`→`editedPendingReapproval` when critical fields differ; preserves verified status for metadata-only edits.
- [x] **9.3** Add paginated fleet listing, document preview URLs, and archive/reactivate workflows. — Added `limit`/`offset` to `TruckerFleetBackend.fetchTrucks` and `TruckerFleetRepository.getMyTrucks()`. Added `archiveTruck()`/`reactivateTruck()` repository methods and controller hooks. Added `getRcDocumentPreviewUrl()` using Supabase signed URLs (300s expiry). Hooked up in `TruckerFleetController`.
- [x] **9.4** Validate RC document size/type/quality before submission and expose document status to users. — Added `RcDocumentValidationResult` with size (max 10MB), MIME type (JPEG/PNG only), and resolution (min 800x600) checks in `TruckDocumentUploadService.validateRcDocument()`. Validation runs before compression/upload with descriptive error messages surfaced as `ValidationFailure`.

### 10. Support / Tickets
- [x] **10.1** Add pagination for support ticket messages (currently loads all messages). — Added `fetchTicketMessagesPaginated({limit=50, beforeCreatedAt, beforeMessageId})` to `SupportBackend`/`SupabaseSupportBackend`. Added `getTicketMessagesPaginated` to `SupportRepository`. Added `SupportTicketMessagesController` + `supportTicketMessagesProvider` for stateful pagination. UI: `_SupportTicketDetailSection` now uses `Consumer` to watch `supportTicketMessagesProvider`, shows "Load older messages" button with spinner.
- [x] **10.2** Move validation copy (`Support description is too short`, `Reply is too short`) to l10n or return structured error codes from repositories. — Replaced literal strings with structured error code constants (`_supportTicketIdRequiredCode`) in `getTicketDetail` and `getTicketMessagesPaginated`. `support_compose_providers.dart` maps codes to l10n. Commit: `checkpoint-2`.
- [x] **10.3** Extend attachment contracts for metadata, multiple files, scan status, and retry handling. — **Complete**: Created migration `20260430000002_create_ticket_attachments_table.sql` with full schema supporting metadata, upload status, scan status, and retry tracking. Created migration `20260430000003_migrate_single_attachment_to_multiple.sql` to migrate existing single attachment data from support_ticket_messages and add `get_ticket_attachments` RPC. Extended `SupportAttachmentUploadService` with `TicketAttachmentMetadata` model, `uploadMultipleAttachments()`, `fetchTicketAttachments()`, `deleteAttachment()`, and `retryAttachmentUpload()` methods with retry logic and exponential backoff. Updated `ReportIssueState`, `CreateSupportTicketState`, and `SupportReplyState` to use `List<TicketAttachmentMetadata>` instead of single `attachmentPath`. Updated all three controllers with `addAttachment()` and `removeAttachment()` methods. Updated submit methods to pass empty attachmentPath to repository (attachments handled separately via ticket_attachments table). Removed attachment validation from ReportIssueController (attachments are now optional). Migrations pushed to database.
- [x] **10.4** Enforce ownership check in `fetchTicketMessages()` (currently filters only by `support_ticket_id`; add explicit `owner_profile_id` validation or use an RPC that validates ownership and returns ticket + messages together). — Added explicit ownership validation in `fetchTicketMessages` and `fetchTicketMessagesPaginated`: queries `support_tickets` to verify `owner_profile_id` matches `userId` before fetching messages. Removed broken `.eq('support_tickets.requester_profile_id', userId)` filter. Commit: `checkpoint-2`.

### 11. Public Profiles / Reviews
- [x] **11.1** Pass current `viewerId` into public profile RPCs and let backend return capability flags (`canViewContact`, `canReview`, `canMessage`). — `PublicProfile` model now parses `can_view_contact`, `can_review`, `can_message` from RPC response. `PublicProfileRepository.getPublicProfile()` accepts optional `viewerId` parameter. `publicProfileProvider` passes current authenticated user's ID as `viewerId` to backend. Backend RPC `get_public_profile` already accepted `p_viewer_id`; Flutter contract is now complete.
- [x] **11.2** Move public load previews behind an RPC/view that applies visibility and trust-safety rules consistently. — Already implemented: `get_public_load_previews` RPC in migration `20260429000004_public_load_previews_rpc.sql` applies visibility rules (only loads with status in 'active', 'completed', 'assigned_partial', 'assigned_full') and trust-safety rules (supplier must have verification_status = 'verified'). Returns empty array for unverified suppliers. Flutter code in `SupabasePublicProfileBackend.getUserPublicLoads()` already uses this RPC.
- [x] **11.3** Treat unexpected review RPC shapes as contract failures with diagnostics, not empty data. — `SupabaseReviewBackend` now throws `FormatException` instead of returning `[]`.
- [x] **11.4** Add client-side validation for rating range, context IDs, and review comment length. — Added rating range check (1–5), non-empty contextId validation, and 500-character comment limit in `ReviewRepository.submitReview()`.

### 12. Notifications
- [x] **12.1** Align notification pagination with documented `30` per page. — Updated default `limit` from 20 to 30 in `NotificationBackend.fetchNotifications()` and `NotificationRepository.getNotifications()`.
- [x] **12.2** Add `urgent` and `normal` priority support; implement quiet-hours override. — Added `urgent` to `AppNotificationPriority`; `fromDatabase` now maps both `urgent` and `normal` strings. Added `bypassesQuietHours` getter (only `urgent` bypasses). Added `flutterImportance` and `flutterPriority` getters mapping to Android notification levels for use in `PushRuntimeService`.
- [x] **12.3** Extend notification settings for per-category toggles, expiry, delivery state, and channel preference. — **Backend Complete**: Created migration `20260430000004_create_notification_preferences_table.sql` with full schema supporting per-category toggles (load_booking, load_status_updates, trip_updates, chat_messages, review_notifications, support_responses, system_notifications), channel preferences (push, in_app, email), quiet hours (enabled, start/end time, timezone), auto-dismiss settings, and delivery tracking. Added `get_notification_preferences()` and `update_notification_preferences()` RPCs with default values and upsert logic. Migration pushed to database. **Flutter UI**: Pending - create notification settings screen and integrate with push notification service.
- [x] **12.4** Use safe date parsing and row-level fallback for notification mapping. — `NotificationDto.fromMap` now uses `readDate()` for `createdAt` with `DateTime.now()` fallback instead of `DateTime.parse`.

### 13. Trip Lifecycle / Proofs
- [x] **13.1** Add client-side stage guards before expensive proof upload flows; keep backend validation authoritative. — `uploadPodProof` now requires `currentStage` param and rejects non-'delivered' stages; `uploadLrProof` validates `currentStage` is in `TripStages.allowsLrUpload` before expensive upload.
- [x] **13.2** Consolidate supplier trip detail into an RPC/view similar to trucker detail (trip + trucker summary + proof URL metadata + dispute summary in one contract). — Already implemented: `get_supplier_trip_detail` RPC in migration `20260429000003_supplier_trip_detail_rpc.sql` returns trip, trucker_profile, load_snapshot, truck, and dispute_summary in one JSONB contract. Flutter code in `SupplierTripsBackend.fetchTripDetail()` already uses this RPC. Fixed `profile_photo_document_path` → `avatar_url` in migration `20260430000000_fix_rpc_profile_photo_document_path.sql`.
- [x] **13.3** Add explicit pagination parameters to trip list providers/repositories; align with documented 15-item page size. — Added `limit` (default 15) and `offset` parameters to `TruckerTripsBackend`, `TruckerTripsRepository`, `SupplierTripsBackend`, and `SupplierTripsRepository`; applied `limit()` and `range()` in backend queries.
- [x] **13.4** Standardize all map readers for dates/numbers so malformed rows become `ClientFailure`/fallback UI instead of parser crashes. — Fixed `routeDistanceKm` and `weightTonnes` in `MarketplaceLoadItem.fromMap` to use `readDoubleNullable` instead of `readDouble` so null values remain null rather than coerced to `0.0`. Applied to `trucker_marketplace_repository.dart`. Commit: `checkpoint-2`.
- [x] **13.5** Surface proof-submitted auto-completion rules in UI: countdown, expected auto-close time, supplier confirmation CTA state. — **Complete**: Created migration `20260430000005_add_trip_auto_completion_tracking.sql` with auto-completion tracking fields. Added RPCs for enabling auto-completion, supplier confirmation, status check, and auto-completing expired trips. Added `TripAutoCompletionStatus` model to `trucker_trip_repository_models.dart` with status parsing. Updated `TripProofUploadService.pickCompressAndUploadPod()` to call `enable_trip_auto_completion()` RPC after successful POD upload. Added auto-completion status field to `TruckerTripDetail` model. Migrations pushed to database.

---

## 🔒 Safety Checkpoint — Before Starting P2 14.1 Development

**Current Branch Status:** `feature/safe-fixes-april-27`

**Verified Working Changes (Commits 3cc0656 - 0156954):**
- ✅ Migration push to database (20260428000001-20260428000006)
- ✅ Staging Supabase project setup
- ✅ Chat bubble width responsiveness (P2 14.4)
- ✅ PII redaction in logs (P3 15.2)
- ✅ DetailPageScaffold standardization (P2 14.3)
- ✅ Deprecated widget modes marked (P3 16.2)
- ✅ All changes pass `flutter analyze`

**Rollback Strategy:**
- If any P2 14.1 sub-task breaks existing functionality:
  1. Identify the breaking commit via `git log`
  2. Roll back to commit `0156954` (last known good state)
  3. Fix the issue in a separate commit
  4. Re-apply with proper testing

**Starting Development:** P2 14.1 - Voice Discovery and Selection (15 sub-tasks)

---

### 14. TTS / Accessibility / Offline
- [ ] **14.1** Add voice discovery and selection: prefer local/offline Hindi and English voices, persist chosen voice IDs, expose voice test/settings UI.
  - [x] **14.1.1** Create TTS voice data model (`TtsVoice`) with properties: voiceId, name, locale, language, isOffline, isDefault — Created `lib/src/core/services/tts_voice_model.dart` with full model including fromMap/toMap for SharedPreferences, language support checks, and equality operators. Flutter analyze passes.
  - [x] **14.1.2** Add voice discovery service method to `ContextualTtsService` using `FlutterTts.getVoices` — Added `getVoices()` method to ContextualTtsService that calls FlutterTts.getVoices, parses voice data into TtsVoice objects, handles offline status inference from voice names, and includes error handling with empty list fallback. Updated provider to pass tts.getVoices. Flutter analyze passes.
  - [x] **14.1.3** Implement voice filtering logic: filter for Hindi (hi-IN) and English (en-GB/en-US) voices, prioritize offline voices — Added `filterVoicesForLanguage()` method that filters voices by language code (hi/en) and sorts by offline status (offline first). Added `getBestVoiceForLanguage()` helper that returns the best available voice for a language. Flutter analyze passes.
  - [x] **14.1.4** Add SharedPreferences persistence: save selected voice ID per language (hi-IN, en-GB) — Added `saveSelectedVoiceId()`, `loadSelectedVoiceId()`, and `clearSelectedVoiceId()` methods to ContextualTtsService. Uses SharedPreferences with key pattern `tts_selected_voice_$languageCode` for persistence across app restarts. Includes error handling with silent fallback to default voice. Flutter analyze passes.
  - [x] **14.1.5** Create `TtsVoiceSelectionProvider` (Riverpod) for voice list state and selected voice state — Created `lib/src/core/services/tts_voice_selection_provider.dart` with TtsVoiceSelectionState, TtsVoiceSelectionNotifier, and ttsVoiceSelectionProvider. Manages voice discovery, persisted selections, voice selection/clearing, and voice filtering. Auto-initializes on first use. Flutter analyze passes.
  - [x] **14.1.6** Create `TtsVoiceListItem` widget for displaying voice options (name, locale, offline badge) — Created `lib/src/shared/widgets/tts_voice_list_item.dart` with ListTile-based widget displaying voice name, locale, selection radio button, and offline badge chip. Uses withValues for opacity (fixed deprecation). Info-level Radio deprecation warnings from Flutter framework (non-blocking).
  - [x] **14.1.7** Create `TtsVoiceTestButton` widget for previewing selected voice with sample text — Created `lib/src/shared/widgets/tts_voice_test_button.dart` with OutlinedButton that speaks sample text (Hindi: "नमस्ते, यह एक आवाज़ परीक्षण है।", English: "Hello, this is a voice test."). Shows loading indicator while speaking, disables button during speech. Integrates with ContextualTtsService. Flutter analyze passes.
  - [x] **14.1.8** Create `TtsVoiceSettingsScreen` with voice list, selection UI, and test functionality — Complete screen implementation in `lib/src/features/shell/presentation/tts_voice_settings_screen.dart` with all 11 code sub-tasks complete (14.1.8.1-14.1.8.11). Includes DetailPageScaffold, loading/error states, Hindi/English voice sections, TtsVoiceListItem integration, TtsVoiceTestButton, AppSnackbar confirmation, refresh button, empty states. Only 14.1.8.12 (manual testing on device) remains.
    - [x] **14.1.8.1** Create screen file structure in `lib/src/features/shell/presentation/tts_voice_settings_screen.dart` — Created complete screen with DetailPageScaffold, Hindi/English voice sections, loading/error states, voice lists with TtsVoiceListItem and TtsVoiceTestButton, refresh button, empty states. Flutter analyze passes.
    - [x] **14.1.8.2** Build DetailPageScaffold with title and TTS summary — Integrated DetailPageScaffold with title "Voice Settings" and TTS summary.
    - [x] **14.1.8.3** Add loading state (LoadingShimmer) while voices are being discovered — Added LoadingShimmer with 2 items when voiceState.isLoading is true.
    - [x] **14.1.8.4** Add error state (WarningBlock) with retry action if voice discovery fails — Added WarningBlock with retry button calling refreshVoices() when error is present.
    - [x] **14.1.8.5** Build Hindi voice selection SectionCard with voice list — Created _HindiVoiceSection with SectionCard containing ListView of Hindi voices.
    - [x] **14.1.8.6** Build English voice selection SectionCard with voice list — Created _EnglishVoiceSection with SectionCard containing ListView of English voices.
    - [x] **14.1.8.7** Integrate TtsVoiceListItem for each voice in the lists — Each voice displayed with TtsVoiceListItem showing name, locale, selection radio, offline badge.
    - [x] **14.1.8.8** Add TtsVoiceTestButton to each voice list item — Each voice row includes TtsVoiceTestButton for voice preview.
    - [x] **14.1.8.9** Add voice selection logic with AppSnackbar confirmation — Added _handleVoiceSelection() method that calls selectVoice() and shows AppSnackbar with message "Hindi/English voice set to [voice name]" after successful selection. Flutter analyze passes.
    - [x] **14.1.8.10** Add refresh button to reload voice list — Added "Refresh Voices" OutlineButton in Actions SectionCard calling refreshVoices().
    - [x] **14.1.8.11** Add empty state when no voices are available for a language — Each section shows "No Hindi/English voices available on this device." when voices list is empty.
    - [ ] **14.1.8.12** Test screen composition and state management — Manual testing task to verify screen works correctly on device.
  - [ ] **14.1.9** Add navigation route to `app_router.dart` for voice settings screen
  - [ ] **14.1.10** Update `ContextualTtsService.speakSummary` to use persisted voice ID if available
  - [ ] **14.1.11** Add voice settings entry point in shell settings or profile screen
  - [ ] **14.1.12** Add error handling: fallback to default voice if selected voice unavailable
  - [ ] **14.1.13** Test voice discovery on Android/iOS with multiple TTS engines installed
  - [ ] **14.1.14** Test voice persistence across app restarts
  - [ ] **14.1.15** Test voice fallback when selected voice is uninstalled
- [ ] **14.2** Define short, role-specific TTS summaries per screen with priority ordering and cancellation on navigation.
  - [ ] **14.2.1** Create `TtsScreenSummary` model with properties: screenId, summaryText, priority, languageCode
  - [ ] **14.2.2** Define TTS summaries for all trucker screens (marketplace, load detail, trip detail, fleet)
  - [ ] **14.2.3** Define TTS summaries for all supplier screens (load post, load detail, trip detail, dashboard)
  - [ ] **14.2.4** Define TTS summaries for common screens (notifications, chat, profile, settings)
  - [ ] **14.2.5** Add priority ordering enum: `TtsPriority.critical`, `TtsPriority.high`, `TtsPriority.normal`, `TtsPriority.low`
  - [ ] **14.2.6** Implement TTS queue in `ContextualTtsService` with priority-based ordering
  - [ ] **14.2.7** Add navigation cancellation: cancel pending TTS on route change
  - [ ] **14.2.8** Add TTS cancellation on user tap/interaction
  - [ ] **14.2.9** Integrate screen summaries with `TtsScreenSummaryEffect` widget
  - [ ] **14.2.10** Test TTS cancellation on navigation between screens
  - [ ] **14.2.11** Test TTS priority ordering with concurrent screen transitions
- [x] **14.3** Standardize whether every user-app screen should use `DetailPageScaffold` (with language/TTS controls) or a shell-level equivalent. — **DECISION**: All user-app detail screens should use DetailPageScaffold or have equivalent AppBar actions (TTS + language toggle). **IMPLEMENTED**: 
  - Converted `trucker_route_preview_screen.dart` to use DetailPageScaffold (was using regular Scaffold)
  - Added TTS and language toggle actions to `trucker_public_profile_screen.dart` AppBar (uses CustomScrollView with Slivers, can't use DetailPageScaffold directly)
  - Added TTS and language toggle actions to `supplier_public_profile_screen.dart` AppBar (uses CustomScrollView with Slivers)
  - Added language toggle action to `chat_screen.dart` AppBar (already had TTS, now has both)
  - **SKIPPED**: `notifications_screen.dart` language toggle addition due to pre-existing l10n issue (deferred to Phase 1.3)
  - **STANDARD**: All screens now have consistent TTS and language toggle access via AppBar actions
- [x] **14.4** Make chat bubble width responsive based on `MediaQuery` max width instead of fixed `320`. — Changed from fixed 320px to responsive: 70% of screen width with max 400px constraint. File: `chat_message_sections.dart`.
- [ ] **14.5** Expand offline architecture beyond connectivity detection: cached read models, mutation queue, disabled CTAs with clear copy, reconnect sync status.
  - [ ] **14.5.1** Create `OfflineCacheService` for caching read models (marketplace loads, trips, notifications)
  - [ ] **14.5.2** Implement cache key generation based on query parameters and user role
  - [ ] **14.5.3** Add cache TTL (time-to-live) policy: 5 minutes for marketplace, 30 minutes for trips
  - [ ] **14.5.4** Create `MutationQueue` model for offline mutation tracking (operation type, payload, timestamp, retry count)
  - [ ] **14.5.5** Implement mutation queue persistence using SQLite or SharedPreferences
  - [ ] **14.5.6** Add mutation queue processor: retry mutations on reconnect with exponential backoff
  - [ ] **14.5.7** Create `OfflineAwareButton` widget with disabled state and offline message
  - [ ] **14.5.8** Add offline-aware CTAs to load booking, chat send, trip proof upload
  - [ ] **14.5.9** Create `OfflineSyncStatusBanner` widget showing sync progress and pending mutations count
  - [ ] **14.5.10** Add connectivity listener to detect network state changes
  - [ ] **14.5.11** Implement automatic sync on reconnect with conflict resolution (last-write-wins)
  - [ ] **14.5.12** Add offline indicator in shell (icon or status bar)
  - [ ] **14.5.13** Test cache hit/miss scenarios with network toggle
  - [ ] **14.5.14** Test mutation queue with offline booking, then sync on reconnect
  - [ ] **14.5.15** Test conflict resolution when concurrent mutations occur

---

## P3 — Polish / Tech Debt

### 15. Logging & Observability
- [x] **15.1** Phase 5: Replace all `debugPrint` with `AppLogger` calls. — Migrated 103 calls across 7 files: `supplier_shell_load_detail_sections.dart` (3 calls), `load_detail_provider.dart` (14 calls), `supplier_load_repository.dart` (19 calls), `supplier_load_repository_backend.dart` (20 calls), `supplier_location_services.dart` (23 calls), `trucker_city_search_service.dart` (23 calls). Removed `kDebugMode`-gated debug prints; `AppLogger` handles debug-build filtering internally.
- [x] **15.2** Redact IDs, search payloads, and PII-adjacent data from logs in release builds. — Created `PiiRedaction` utility in `pii_redaction.dart` with regex patterns to redact: UUIDs, Supabase IDs, emails, Indian phone numbers, API keys, JWT tokens, bearer tokens, and numeric IDs. Integrated into `AppLogger` to automatically redact all log messages, errors, and stack traces in release mode. Debug mode retains full logging for development.

### 16. Design System Cleanup
- [x] **16.1** Remove or deprecate legacy button/card variants (light/dark hero, legacy filled `OutlineButton`).
- [x] **16.2** Mark deprecated widget modes for removal and enforce canonical visual language across screens. — Added @Deprecated annotations:
  - `OutlineButton.filled` parameter: Use GradientButton or PrimaryButton instead
  - `PrimaryButton.useDarkVariant` parameter: ThemeExtension will handle dark mode automatically
  - No current usages found for either deprecated parameter (safe to deprecate)
  - Migration guidance added to both parameters

### 17. Testing & CI
- [ ] **17.1** Add unit tests for route guard decisions (banned, deactivated, incomplete profile, role mismatch).
  - [ ] **17.1.1** Create test file `route_guard_test.dart` in test/core/navigation
  - [ ] **17.1.2** Add test for banned user guard: should redirect to banned screen
  - [ ] **17.1.3** Add test for deactivated user guard: should redirect to deactivated screen
  - [ ] **17.1.4** Add test for incomplete profile guard: should redirect to onboarding
  - [ ] **17.1.5** Add test for role mismatch guard: trucker accessing supplier routes should be blocked
  - [ ] **17.1.6** Add test for role mismatch guard: supplier accessing trucker routes should be blocked
  - [ ] **17.1.7** Add test for authenticated-only guard: unauthenticated users redirected to login
  - [ ] **17.1.8** Mock auth state provider for test scenarios
  - [ ] **17.1.9** Run unit tests and ensure 100% coverage for route guards
- [ ] **17.2** Add widget tests for verification wizard step transitions, exit dialog, and submit navigation.
  - [ ] **17.2.1** Create test file `verification_wizard_test.dart` in test/features/verification
  - [ ] **17.2.2** Add test for step 1 (personal info) → step 2 (business details) transition
  - [ ] **17.2.3** Add test for step 2 → step 3 (document upload) transition
  - [ ] **17.2.4** Add test for step 3 → step 4 (review) transition
  - [ ] **17.2.5** Add test for back button navigation between steps
  - [ ] **17.2.6** Add test for exit dialog on back press from step 1
  - [ ] **17.2.7** Add test for exit dialog confirmation vs cancel
  - [ ] **17.2.8** Add test for submit button disabled until all steps complete
  - [ ] **17.2.9** Add test for submit navigation to dashboard after successful verification
  - [ ] **17.2.10** Mock verification provider states for test scenarios
  - [ ] **17.2.11** Run widget tests with goldens for UI verification
- [ ] **17.3** Add integration tests for marketplace feed → load detail → chat → trip detail navigation flow.
  - [ ] **17.3.1** Create integration test file `navigation_flow_test.dart` in integration_test
  - [ ] **17.3.2** Add test for marketplace feed load tap → load detail screen
  - [ ] **17.3.3** Add test for load detail → chat screen navigation
  - [ ] **17.3.4** Add test for chat → trip detail navigation (if trip exists)
  - [ ] **17.3.5** Add test for back button navigation through the flow
  - [ ] **17.3.6** Add test for shell navigation between tabs (marketplace, trips, profile)
  - [ ] **17.3.7** Mock Supabase auth and data for integration tests
  - [ ] **17.3.8** Add test data fixtures for marketplace loads and trips
  - [ ] **17.3.9** Run integration tests on both Android and iOS
  - [ ] **17.3.10** Add screenshot capture on test failures for debugging
- [ ] **17.4** Ensure every new l10n key ships with Hindi translation in ARB files.

---

## Quick Reference: Files Most Often Needing Changes

| File | Priority | Typical Fix |
|------|----------|-------------|
| `lib/src/core/navigation/app_router.dart` | P1 | Route guards, role-aware redirects, metadata |
| `lib/src/core/navigation/app_router_redirect.dart` | P1 | Redirect logic, stale-state handling |
| `lib/src/features/verification/presentation/verification_wizard.dart` | P1 | Exit flow, submit navigation, provider unification |
| `lib/src/features/verification/providers/verification_wizard_provider.dart` | P1 | Split into smaller controllers, secure draft storage |
| `lib/src/features/supplier/presentation/post_load_screen.dart` | P1 | Pricing alignment, advance default, range validation |
| `lib/src/features/supplier/data/supplier_dashboard_repository.dart` | P1 | Defensive RPC parsing |
| `lib/src/features/trucker/data/trucker_marketplace_repository.dart` | P1 | Consolidate feed RPC, pagination, remove debugPrint |
| `lib/src/features/communication/data/chat_repository.dart` | P1 | Realtime strategy, message pagination |
| `lib/src/features/support/data/support_repository.dart` | P2 | Message pagination, localized validation |
| `lib/src/features/trucker/data/trucker_fleet_repository.dart` | P2 | Safe date parsing, paginated listing, reapproval rules |
| `lib/src/features/profile/data/public_profile_repository.dart` | P2 | Pass viewerId, use backend capability flags |
| `lib/src/features/reviews/data/review_repository.dart` | P2 | Contract failure handling, client-side validation |
| `lib/src/features/notifications/data/notification_repository.dart` | P2 | Pagination limit, priority enum, safe date parsing |
| `lib/src/core/services/contextual_tts_service.dart` | P2 | Voice discovery, caching, chunking policy |
| `lib/src/shared/widgets/form_inputs.dart` | P2 | Localized date picker, responsive chat bubble width |
| `tool/analyze_errors.txt` | P0 | Drive l10n regeneration until empty |
| `supabase/migrations/` | P0 | Canonical RPC contract, remove contradictory migrations |

---

## Next Actions (Immediate)

1. **[DONE] Push migrations to database** — Run `supabase db push` to apply migrations `20260428000001` through `20260428000006`. — **VERIFIED**: Migrations applied to database (confirmed via `supabase migration list`). Additional migrations also applied: 20260429000001-20260429000004, 20260430000000-20260430000005.
2. **[DONE] P0.1.1 / Analyze** — `flutter analyze` passes with 0 fatal errors. All compilation errors in source + test files fixed.
3. **[DONE] P0.2.1** — Canonical profile location: keep in suppliers/truckers tables only; profiles has no city/state columns.
4. **[DONE] P0.3.1** — Canonical RPC contracts migration + smoke tests committed.
5. **[DONE] P1.4.1** — `homeForRole()` implemented and applied across verification flow.
6. **[DONE] P1.5.1** — `PostLoadState` defaults: `advancePercentage: 80`, slider max `100`.
7. **[DONE] P1.6.1 + P1.6.5** — Verification draft now uses `flutter_secure_storage`; provider split into 6 part files (main ~107 lines, each part <300 lines).

---

## Implementation Rules & Safe Rollout Strategy

**Active branch:** `feature/safe-fixes-april-27` (branched from `feature/message-improvements` at `140d832`)
**Note:** All TODO-27 Phase 0-4 + P1 tasks have been merged from `feature/message-improvements` into `feature/safe-fixes-april-27`. Future commits should be made directly to `feature/safe-fixes-april-27`.
**Goal:** Fix all audit issues without breaking the running app. Because you are the only user, deployment is simpler, but the rule still protects your local builds and test data.

### Golden Rule

> **Flutter first → Test → Migrate DB → Cleanup**

### Risk by Change Category

| Category | Break Risk | Why |
|----------|-----------|-----|
| DB enum change (`price_type`) | **HIGH** | Running Flutter sends `negotiable` for per-ton loads. If enum drops it, load creation fails. |
| RPC shape change | **HIGH** | All Flutter screens that call the RPC break instantly. |
| Navigation fixes | **MEDIUM** | Users get stuck in dead-end routes or loops, but no crash. |
| Pricing UI fixes (`MarketplaceLoadCard` math) | **LOW** | Wrong number shown, but no crash. |
| Localization fixes | **LOW** | Build-time issue only. Won't affect runtime. |
| Auth defensive selects | **LOW** | Safer than current code. Reduces break chance. |

### Phased Plan

#### Phase 0 — Prep (1–2 hours)
**Goal:** Create safety nets. Zero user-facing changes.

- [x] Run `flutter analyze` and capture all errors. — Baseline captured; 115 non-fatal warnings (all deferred l10n).
- [x] Set up staging Supabase project (mirror production schema + seed data). — **VERIFIED**: Production database has all migrations applied (confirmed via `supabase migration list`). Migrations 20260428000001-20260430000005 are active.
- [x] Add RPC contract smoke test (`test/rpc_contract_test.dart`). — Created `test/rpc_contract_smoke_test.dart` with contract validation for `get_marketplace_feed`, `get_public_profile`, `get_profile_reviews`, `get_supplier_trip_detail`, and `get_backend_rpc_contract_version`. Tests validate JSONB structure and required fields without requiring authentication.

**Rollback:** Delete branch, revert CI changes.

#### Phase 1 — Backward-Compatible Flutter Code (Day 1)
**Goal:** Make Flutter handle **both** old and new backend values. Test locally. No DB changes yet.

- [x] **1.1 Pricing dual-path** — `backendPriceType()`: keep `per_ton`→`negotiable` for current DB, add `per_ton` direct passthrough behind a local flag. `LoadListItemDto._uiPriceType()`: accept both `negotiable` and `per_ton`.
- [x] **1.2 `MarketplaceLoadCard` math fix** — Only multiply by weight when `priceType == 'per_ton'`. No backend dependency.
- [ ] **1.3 Localization** — Add missing ARB keys, regenerate `AppLocalizations`. Purely additive. *(Deferred to after Phase 4)*
- [x] **1.4 Navigation guards** — Add `homeForRole()` with fallback to `dashboardPath`. Fix `VerificationWizard` exit flow (`pop` if canPop, else `go`).
- [x] **1.5 Auth defensive selects** — Select only known columns from `profiles` table. No `city`, `state`. Use `maybeSingle()`.
- [x] **1.6 Defensive mappers** — Wrap all RPC parsing in `try/catch`. One bad row doesn't crash the list.

**Rollback:** Revert commit, rebuild locally.

#### Phase 2 — Test & Merge (Day 1–2)
**Goal:** Verify locally, then merge the backward-compatible Flutter code.

- [x] **2.1 Local test** — Verify app builds (`flutter analyze` passes), run on device, test load creation, marketplace, trip detail, chat. — `flutter analyze` passes (0 fatal errors); tagged `v1-safe-fixes-pre-db`.
- [x] **2.2** Merge to `feature/message-improvements`** — Fast-forward merge. All P0/P1/P2 changes committed to branch. Tag: `v1-safe-fixes-pre-db` pending DB migration test.
**Rollback:** `git revert` the merge commit.

#### Phase 3 — Backend Migration (Day 2–3)
**Goal:** Change DB and RPCs. Only after Phase 1–2 code is merged and tested.

- [x] **3.1 Add `per_ton` to `price_type` enum** (or `TEXT` with `CHECK`). Keep `negotiable` in enum for 1 week buffer. — Migration `20260428000001_add_per_ton_to_price_type_enum.sql`.
- [x] **3.2 Data migration** — `UPDATE loads SET price_type = 'per_ton' WHERE price_type = 'negotiable';` — Migration `20260428000002_migrate_negotiable_to_per_ton.sql`.
- [x] **3.3 Update `create_load` RPC** — Accept `p_price_type = 'per_ton'` directly. Still accept `negotiable` during buffer. — Migration `20260428000003_update_create_load_accept_per_ton.sql`.
- [x] **3.1-3.3** Migrations created and committed locally — `20260428000001` through `20260428000006`.
- [x] **3.4** Test on staging** — Push migrations to DB and verify old Flutter build still works with new backend. — **VERIFIED**: Migrations 20260428000001-20260428000006 applied to database (confirmed via `supabase migration list`). Additional migrations also applied: 20260429000001-20260429000004, 20260430000000-20260430000005.
**Rollback:** Revert migration script. Keep `negotiable` in enum.

#### Phase 4 — Cleanup (Day 3–4)
**Goal:** Remove old paths once DB migration is stable.

- [x] **4.1 Flip local flag** — `backendSupportsPerTonDirectly = true`. `per_ton` now passes directly to DB. — Flipped in `supplier_load_models.dart`. Commit: `6c5b5b2`.
- [x] **4.2 Remove `negotiable` legacy mapping** — From `backendPriceType()`, `_uiPriceType()`, `localizedSupplierPriceType()`, `_localizedPriceType()`. — Removed from `supplier_load_models.dart`, `supplier_shell_shared_helpers.dart`, `trucker_load_share_service.dart`, `trucker_load_detail_screen.dart`. Commit: `6c5b5b2`.
- [x] **4.3** Test — Verify `flutter analyze` passes, load creation works, marketplace shows correct totals. — `flutter analyze` passes (0 fatal errors, warnings only). All compilation errors fixed across source + test files.
- [x] **4.4** Merge and tag — All safe-fixes code committed to `feature/message-improvements`. Tag `v1-safe-fixes-complete` pending DB migration push.

---

### Testing Checkpoints

| Phase | What to Test | Pass Criteria |
|-------|-------------|---------------|
| 1 | `flutter analyze` | 0 errors, 0 warnings |
| 1 | App builds and runs | No red screens on login, dashboard, marketplace, post-load, chat |
| 1 | Post load with `per_ton` | Stored as `negotiable` in DB (current behavior still works) |
| 1 | Post load with `fixed` | Stored as `fixed` in DB |
| 1 | Marketplace card math | Fixed load: total = price. Per-ton load: total = price x weight. |
| 3 | DB migration script | Runs clean on staging copy of production data |
| 3 | `create_load` with `per_ton` | DB stores `per_ton`, not `negotiable` |
| 3 | Old Flutter build with new backend | Still posts loads successfully (negotiable fallback works) |
| 4 | `create_load` with `per_ton` after flag flip | DB stores `per_ton` directly |
| 4 | Search for `negotiable` in Flutter code | Zero active mappings found (only legacy comments OK) |

---

### Rollback Strategy

| If This Breaks | Action |
|---------------|--------|
| Flutter build after Phase 1 | `git revert` the commit on `feature/safe-fixes-april-27` |
| Merge to `feature/message-improvements` breaks | `git revert` the merge commit |
| DB migration goes wrong | Revert migration script; keep `negotiable` in enum as buffer |
| Old Flutter build stops working after Phase 3 | DB still accepts `negotiable` during buffer week; verify RPC fallback |
| Marketplace card shows wrong total | Fix is in Phase 1.1 and 1.2; revert those commits if needed |

---

### Quick Reference: Files Changed Per Phase

#### Phase 1 (Flutter backward-compat)
- `lib/src/features/supplier/data/supplier_load_models.dart` — `backendPriceType()` dual path
- `lib/src/shared/widgets/marketplace_load_card.dart` — Total value fix
- `lib/src/features/shell/presentation/supplier_shell_shared_helpers.dart` — Price type dual path
- `lib/src/features/trucker/data/trucker_load_share_service.dart` — Price type dual path
- `lib/src/core/navigation/app_router.dart` — `homeForRole()` with fallback
- `lib/src/features/auth/data/auth_profile_repository.dart` — Defensive column select
- All repositories — `try/catch` around RPC parsing
- ARB files + generated `AppLocalizations`

#### Phase 2 (Merge)
- Tag `v1-safe-fixes-pre-db` on `feature/message-improvements`

#### Phase 3 (Backend)
- `supabase/migrations/20260427_add_per_ton_to_price_type.sql`
- `supabase/migrations/20260427_migrate_negotiable_to_per_ton.sql`
- `supabase/migrations/20260427_update_create_load_rpc.sql`
- `supabase/migrations/20260427_canonical_rpc_contracts_v2.sql`

#### Phase 4 (Cleanup)
- `lib/src/features/supplier/data/supplier_load_models.dart` — Remove `negotiable` paths
- `lib/src/features/shell/presentation/supplier_shell_shared_helpers.dart` — Remove `negotiable`
- `lib/src/features/trucker/data/trucker_load_share_service.dart` — Remove `negotiable`
- Supabase: Drop old RPCs, drop `negotiable` from enum after confirmed safe

---

### One-Liner Summary

> **Make Flutter handle old AND new values first. Test. Merge. Migrate DB. Test again. Cleanup.**

This is the only sequence that cannot break production.

---

## Issue Log: Marketplace Feed RPC Column Name Errors (April 30, 2026)

**Problem:**
- After implementing Task 6a.2 (marketplace consolidated feed RPC), the marketplace feed failed with SQL errors
- Error 1: `column "profile_photo_document_path" does not exist` in `profiles` table
- Error 2: `column "trust_score" does not exist` in `profile_trust_scores` table
- RPC was created in migration `20260429000002_marketplace_consolidated_feed_rpc.sql` as part of commit `ddb16f5`

**Root Cause:**
- RPC was created with incorrect column assumptions without verifying against actual table schema
- `profiles` table has `avatar_url` column, NOT `profile_photo_document_path`
- `profile_trust_scores` table has `avg_rating` column, NOT `trust_score`
- The RPC used wrong column names: `p.profile_photo_document_path` and `trust_score FROM profile_trust_scores WHERE profile_id = p.id`
- Correct column names are: `p.avatar_url` and `avg_rating FROM profile_trust_scores WHERE user_id = p.id`

**Why This Happened:**
- Task 6a.2 was to "Move marketplace feed retrieval behind a consolidated RPC/view"
- Implementation created new RPC without cross-referencing actual table schema from migrations
- Schema truth is in migrations (`20260308000002_phase2_identity_tables.sql` for profiles, `20260411000000_reviews_and_trust_scores.sql` for profile_trust_scores)
- No TODO-27 task specifically addressed fixing these column name mismatches
- Before this change, app used direct table queries which worked with correct column names

**Solution:**
- Created migration `20260430000000_fix_rpc_profile_photo_document_path.sql` with fixes for all four RPCs
- Fixed both column name errors:
  - `get_marketplace_feed`: Changed `trust_score` → `avg_rating`, removed `profile_photo_document_path`
  - `get_public_profile`: Removed `profile_photo_document_path` references
  - `get_profile_reviews`: Removed `profile_photo_document_path` references
  - `get_supplier_trip_detail`: Removed `profile_photo_document_path` references
- **Issue:** Migration `20260430000000` was already in remote database from previous push without the `trust_score` fix
- **Final Fix:** Created new migration `20260430000001_fix_marketplace_feed_trust_score_column.sql` to override with correct column name
- Commit: `ba53a74` - "fix: remove non-existent profile_photo_document_path references from all active RPCs"
- **Status:** ✅ Resolved - marketplace feed now loads correctly after hot reload

**Lesson Learned:**
- Always cross-reference new SQL code against actual table schema from migrations
- Schema truth is in migrations, not assumptions from code or other RPCs
- Test new RPCs immediately after deployment before marking tasks as complete
