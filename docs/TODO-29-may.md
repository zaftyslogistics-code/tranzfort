# TODO — 29 May 2026

**Date:** 2026-05-29  
**Updated:** 2026-05-29 (pre-TTS QA sign-off)  
**Status:** Active — pre-TTS baseline **verified** on device; TTS (§C) in progress  
**Priority:** Play Store upload + `main` merge → continue TTS (§C)  
**Working branch:** `feature/play-store-readiness-2026-05-16` (all TTS + readiness work here — no separate TTS branch)  
**Branch baseline:** `main` (play-store readiness merged)  
**Remote Supabase:** `jgtgdfhdtjhidywpautk` (`TranZfort/build-apk.bat`)

**Related docs:** [TASK-completed-29-may.md](./TASK-completed-29-may.md) · [TTS-29-may.md](./TTS-29-may.md) · [TODO-24-april.md](./TODO-24-april.md) (checklist style reference)

---

## Checklist legend

| Mark | Meaning |
|------|---------|
| `[x]` | **Completed** — done and verified (or merged to `main`) |
| `[ ]` | **Pending** — not done yet |

**Rules:** Check boxes only with `[x]` or `[ ]` (lowercase x). Update this file when a task finishes. Details for completed work: [TASK-completed-29-may.md](./TASK-completed-29-may.md).

---

## Progress snapshot

| Track | Done | Pending | Section |
|-------|------|---------|---------|
| Z — Completed 29 May | 68 | 0 | §Z |
| A — Play Store follow-up | 52 | 7 | §A |
| B — Release QA (manual) | 42 | 4 | §B |
| E — Admin app | 9 | 0 | §E |
| R — Release gate | 0 | 3 | §R |
| C — TTS expansion | 56 | 41 | §C |
| D — Localization hygiene | 1 | 11 | §D |
| F — Docs & repo | 1 | 5 | §F |

*B counts exclude TTS-only rows (B-6.3, B-6.8–B-6.10) — covered under §C.*

### Pre-TTS sign-off (team, 2026-05-29)

All work **before §C (TTS expansion)** has been **tested on device and is working**, including verification, trips/loads, notifications, uploads, Admin queue, and §B core flows.

**Still open:** Play Console internal track (§A-5.6–7), merge feature branch → `main` (§R), and remaining §C TTS items.

---

## Z. Completed 29 May (play-store readiness) — all `[x]`

*Do not re-do unless regression found. Use §A/B to verify.*

### Z-1 UI flicker & list loading

- [x] Z-1.1 Supplier trips provider — debounced error display
- [x] Z-1.2 Supplier trips provider — minimum loading / `hasResolvedInitialLoad`
- [x] Z-1.3 Supplier My Loads provider — debounced error display
- [x] Z-1.4 Supplier My Loads provider — minimum loading / `hasResolvedInitialLoad`
- [x] Z-1.5 `supplier_shell_trip_sections.dart` — aligned with provider timing
- [x] Z-1.6 `supplier_shell_my_loads_sections.dart` — aligned with provider timing
- [x] Z-1.7 Trucker trips provider — debounced error + loading stabilization
- [x] Z-1.8 `trucker_trips_screen.dart` — aligned with provider timing
- [x] Z-1.9 `trucker_trip_detail_provider.dart` — minimum loading where applicable
- [x] Z-1.10 Notifications provider — debounced errors + initial load flag
- [x] Z-1.11 `notifications_screen.dart` — aligned with provider behavior
- [x] Z-1.12 Notification provider/screen tests updated
- [x] Z-1.13 `lifecycle_status_constants.dart` — trip/load status consistency
- [x] Z-1.14 Shared widgets touched: `content_cards.dart`, `layout_components.dart`, `marketplace_load_card.dart`

### Z-2 Signup & onboarding

- [x] Z-2.1 Diagnose `user_consents` upsert failure on onboarding
- [x] Z-2.2 Migration `20260529120000_fix_user_consents_unique_for_onboarding.sql` authored
- [x] Z-2.3 Migration pushed to remote Supabase
- [x] Z-2.4 `auth_repository_profile_ops.dart` — city/state/role on profile upsert
- [x] Z-2.5 `auth_repository_profile_ops.dart` — `recordTerms: false` on profile upsert; consent via `record_user_consent`
- [x] Z-2.6 `auth_repository_profile_ops.dart` — safer `get_current_user_profile` parsing
- [x] Z-2.7 Onboarding profile completion flow tested (signup completes)

### Z-3 Trucker verification load failure (`pan_last4`)

- [x] Z-3.1 Identify missing `pan_last4` column vs Flutter select
- [x] Z-3.2 Migration `20260529130000_add_pan_last4_to_profiles.sql` authored
- [x] Z-3.3 Migration pushed to remote
- [x] Z-3.4 `verification_repository_backend.dart` — query/save `pan_last4`
- [x] Z-3.5 `verification_repository_models.dart` — fallback from `pan_number` for last4 display
- [x] Z-3.6 Trucker verification screen loads without “Unable to load verification state”

### Z-4 Supplier verification alignment

- [x] Z-4.1 Review supplier wizard vs trucker (shared repository)
- [x] Z-4.2 Confirm business licence + location paths — no extra schema gap found
- [x] Z-4.3 Supplier verification submit path reviewed

### Z-5 Admin verification pipeline (review)

- [x] Z-5.1 Confirm Admin reads `verification_cases` (not broken queue RPC)
- [x] Z-5.2 Document Suppliers / Truckers / Trucks queue tabs
- [x] Z-5.3 Confirm submit → `submitted` case + profile `pending` intent

### Z-6 Fleet RPCs & `submit_verification_for_review`

- [x] Z-6.1 Identify dropped fleet RPCs from rollback migration
- [x] Z-6.2 Migration `20260529140000_restore_fleet_rpcs_and_fix_verification_submit.sql` authored
- [x] Z-6.3 Restore `add_truck`, `get_trucker_fleet`, related RPCs
- [x] Z-6.4 `add_truck` returns `JSONB {"id": "..."}` for app parser
- [x] Z-6.5 `submit_verification_for_review` — validate last4 + docs (not full PAN/Aadhaar)
- [x] Z-6.6 Submit RPC — supplier licence + verification location rules
- [x] Z-6.7 Submit RPC — trucker ready-truck check
- [x] Z-6.8 Submit RPC — admin notifications + `GRANT authenticated`
- [x] Z-6.9 `supabase db push` — remote up to date
- [x] Z-6.10 `trucker_fleet_repository.dart` — parse Map or UUID from `add_truck`
- [x] Z-6.11 `trucker_fleet_repository.dart` — `get_trucker_fleet` List response shape

### Z-7 Verification document upload UX

- [x] Z-7.1 Add `verification_wizard_upload_feedback.dart` (banners + snackbars)
- [x] Z-7.2 Add `verification_wizard_provider.upload_handlers.dart` unified handling
- [x] Z-7.3 Wire upload feedback to profile photo step
- [x] Z-7.4 Wire upload feedback to identity document steps
- [x] Z-7.5 Wire upload feedback to business licence / GST steps
- [x] Z-7.6 Wire upload feedback to truck RC / photo steps
- [x] Z-7.7 `ImageUploadServiceDefaults.resolveImageMimeType` for null Android mimeType
- [x] Z-7.8 Use MIME helper in verification document upload service
- [x] Z-7.9 Use MIME helper in truck document upload service
- [x] Z-7.10 Cancel picker → user-visible message (not silent fail)
- [x] Z-7.11 `verification_document_upload_service_test.dart` — cancel, mime, storage path

### Z-8 Verification wizard & submit (code fixes)

- [x] Z-8.1 `VerificationDraft` / `TruckDraft` — `clear*` flags in `copyWith`
- [x] Z-8.2 Clear profile photo / identity docs / business docs / RC actually null out paths
- [x] Z-8.3 `verificationWizardProvider` — `ref.read(verificationProvider)` (no wizard reset on parent refresh)
- [x] Z-8.4 Terms checkbox enforced in `validateAll` on submit
- [x] Z-8.5 `isResubmission` set when profile status is `rejected`
- [x] Z-8.6 `isResubmission` updatable via `VerificationWizardState.copyWith`
- [x] Z-8.7 `hasIdentityNumbers` uses `aadhaarLast4` / `panLast4` in `VerificationDetail`
- [x] Z-8.8 `hasTruckComplete` requires `capacityTonnes > 0`
- [x] Z-8.9 Hydrate truck draft from `getMyTrucks()` on wizard load (trucker)
- [x] Z-8.10 Skip `createTruck` when fleet already has ready truck (same number + RC + capacity)
- [x] Z-8.11 Add `verification_wizard_field_errors.dart` repository → wizard key map
- [x] Z-8.12 Map `rc_document_path` and related keys on upload/submit failures
- [x] Z-8.13 Submit save failures show field errors on review step

### Z-9 Git & merge

- [x] Z-9.1 Commit play-store readiness changes to feature branch
- [x] Z-9.2 Push `feature/play-store-readiness-2026-05-16` to origin
- [x] Z-9.3 Merge feature branch into `main` (conflicts resolved — feature side for 8 files)
- [x] Z-9.4 Push `main` to origin
- [x] Z-9.5 Add `docs/TASK-completed-29-may.md` (local)
- [x] Z-9.6 Add `docs/TTS-29-may.md` (local)

---

## A. Play Store readiness — pre-TTS verified `[x]` except §A-5 release

### A-1 Verification & backend (regression & parity)

#### A-1.1 Resubmit-after-reject (trucker)

- [x] A-1.1.1 Admin: reject trucker verification with reason
- [x] A-1.1.2 App: open verification — status shows rejected; `isResubmission` true
- [x] A-1.1.3 Re-enter / confirm Aadhaar (12 digit) and PAN
- [x] A-1.1.4 Re-upload or confirm identity documents if required
- [x] A-1.1.5 Truck step shows fleet-hydrated truck (RC + capacity) where applicable
- [x] A-1.1.6 Accept terms on review step
- [x] A-1.1.7 Submit — no duplicate truck row for same `truck_number`
- [x] A-1.1.8 Profile → `pending`; new case in Admin queue
- [x] A-1.1.9 Persisted wizard draft cleared after successful submit

#### A-1.2 Resubmit-after-reject (supplier)

- [x] A-1.2.1 Admin: reject supplier verification
- [x] A-1.2.2 Resubmit with business licence + location + terms
- [x] A-1.2.3 Admin Suppliers tab shows new submitted case

#### A-1.3 Admin queue spot-check

- [x] A-1.3.1 Trucker submit → case under **Truckers** tab
- [x] A-1.3.2 Trucker submit → truck case under **Trucks** tab (if separate)
- [x] A-1.3.3 Supplier submit → case under **Suppliers** tab
- [x] A-1.3.4 Open case detail — documents visible / paths resolve

#### A-1.4 RPC vs wizard parity (deferred v1 — not blocking release)

- [x] A-1.4.1 Document decision: require `company_name` in `submit_verification_for_review` — **deferred v1**
- [ ] A-1.4.2 If yes: add SQL validation + clear error message
- [ ] A-1.4.3 If yes: map RPC error key → wizard `companyName` field
- [x] A-1.4.4 Document decision: require `profile_photo_document_path` in submit RPC — **deferred v1**
- [ ] A-1.4.5 If yes: add SQL validation for profile photo path
- [ ] A-1.4.6 If yes: map RPC error → wizard `profilePhoto` field
- [ ] A-1.4.7 Re-test submit with missing company name / photo (should block server-side)

#### A-1.5 Truck photo (optional field — deferred v1)

- [x] A-1.5.1 Product: keep optional UI-only vs persist on truck record — **UI-only for v1**
- [ ] A-1.5.2 If persist: extend `add_truck` / update truck RPC with `truck_photo_document_path`
- [ ] A-1.5.3 If persist: migration if new column needed
- [x] A-1.5.4 If UI-only: document orphan storage cleanup policy — see CTO plan §Sprint 2
- [ ] A-1.5.5 Update wizard copy (“optional” vs “saved”)

#### A-1.6 Profile photo quality step (post-v1 polish)

- [ ] A-1.6.1 Remove fake “quality passed” indicators **or**
- [ ] A-1.6.2 Implement real checks (blur/size) with honest pass/fail copy
- [ ] A-1.6.3 L10n keys for any new quality messages (EN + HI)

#### A-1.7 Automated tests (verification)

- [x] A-1.7.1 Test: `VerificationDraft.copyWith(clearProfilePhoto: true)` clears path
- [x] A-1.7.2 Test: terms not accepted → submit validation fails
- [x] A-1.7.3 Test: `mapRepositoryFieldKeyToWizard` for `rc_document_path`
- [x] A-1.7.4 Test: `fleetHasReadyTruckForDraft` (skip duplicate `createTruck` predicate)
- [x] A-1.7.5 Test: `isVerificationResubmission` for rejected status

### A-2 Trips & loads (post-merge smoke)

#### A-2.1 Supplier My Loads

- [x] A-2.1.1 Cold open tab — loading skeleton, no flicker to error
- [x] A-2.1.2 Populated list — cards show route, material, status
- [x] A-2.1.3 Empty state — correct copy and CTA
- [x] A-2.1.4 Pull-to-refresh or retry after airplane mode
- [x] A-2.1.5 Tap card → load detail opens

#### A-2.2 Supplier Trips

- [x] A-2.2.1 Cold open tab — stable loading
- [x] A-2.2.2 Trip card stage label matches backend stage
- [x] A-2.2.3 Tap trip → trip detail loads
- [x] A-2.2.4 Empty / error states correct

#### A-2.3 Trucker Trips

- [x] A-2.3.1 Cold open tab — stable loading
- [x] A-2.3.2 Progress bar + stage chip match trip state
- [x] A-2.3.3 Trip detail — await RPC (no regression from merge)
- [x] A-2.3.4 POD/LR section visible when applicable

#### A-2.4 Lifecycle labels

- [x] A-2.4.1 Compare `lifecycle_status_constants` to API stages for loads
- [x] A-2.4.2 Compare constants to trip stages (supplier + trucker)
- [x] A-2.4.3 Fix any mismatched localized label (EN + HI)

### A-3 Notifications & uploads (device QA)

- [x] A-3.1 Notifications: slow network — no error flash before data
- [x] A-3.2 Notifications: mark read / open item — list stable
- [x] A-3.3 Verification: camera capture → success snackbar + path set
- [x] A-3.4 Verification: gallery pick → success snackbar
- [x] A-3.5 Verification: cancel picker → info message (not silent)
- [x] A-3.6 Verification: invalid file type → field error shown
- [x] A-3.7 Test on low-RAM Android device (representative OEM)

### A-4 Database (remote confirmation)

- [x] A-4.1 Run migration list against **staging/production** project (not only dev)
- [x] A-4.2 Confirm applied: `20260529120000_fix_user_consents_unique_for_onboarding.sql`
- [x] A-4.3 Confirm applied: `20260529130000_add_pan_last4_to_profiles.sql`
- [x] A-4.4 Confirm applied: `20260529140000_restore_fleet_rpcs_and_fix_verification_submit.sql`
- [x] A-4.5 SQL: `\df submit_verification_for_review` or dashboard equivalent exists
- [x] A-4.6 SQL: `add_truck`, `get_trucker_fleet` exist
- [x] A-4.7 SQL: `profiles.pan_last4` column exists
- [x] A-4.8 SQL: unique constraint on `user_consents` (profile + consent type) exists

### A-5 Build & release — **open (Play Store + merge)**

- [ ] A-5.1 `git pull origin main` on build machine (before final merge)
- [x] A-5.2 Run `TranZfort\build-apk.bat` — release APK succeeds
- [x] A-5.3 Install APK on physical device (uninstall old test build if needed)
- [x] A-5.4 Smoke: cold start → login → shell (trucker **and** supplier accounts)
- [ ] A-5.5 Tag release candidate commit (optional)
- [ ] A-5.6 Upload to Play Console internal testing track
- [ ] A-5.7 Add release notes (verification fix, onboarding, flicker)

---

## B. Release QA checklist (manual) — pre-TTS verified `[x]` except TTS rows

### B.0 Session-confirmed (pre-checked)

- [x] B-0.1 Signup / onboarding completes (team confirmed)
- [x] B-0.2 Trucker verification loads and submits (team confirmed)
- [x] B-0.3 Supplier verification path reviewed (team confirmed)
- [x] B-0.4 Document uploads show feedback (team confirmed)

### B.1 Auth & onboarding

- [x] B-1.1 Supplier: email/password signup end-to-end
- [x] B-1.2 Supplier: role selection + profile fields saved
- [x] B-1.3 Trucker: signup end-to-end
- [x] B-1.4 Google sign-in (if enabled on build)
- [x] B-1.5 Toggle UI language EN → HI — labels update
- [x] B-1.6 Toggle UI language HI → EN — labels update
- [x] B-1.7 Terms consent row exists in DB for new user (`user_consents`)
- [x] B-1.8 Logout → login again — profile restored

### B.2 Verification — trucker

- [x] B-2.1 Open verification from blocked/home state
- [x] B-2.2 Step 1 profile photo — upload + clear + re-upload
- [x] B-2.3 Step 2 Aadhaar number validation (12 digit)
- [x] B-2.4 Step 2 PAN format validation
- [x] B-2.5 Step 2 front/back/PAN images upload
- [x] B-2.6 Step 3 truck number, body, tyres, capacity
- [x] B-2.7 Step 3 RC document upload
- [x] B-2.8 Cannot proceed without capacity > 0
- [x] B-2.9 Review: terms unchecked → cannot submit
- [x] B-2.10 Submit → pending UI
- [x] B-2.11 Admin sees trucker + truck cases

### B.3 Verification — supplier

- [x] B-3.1 Company name + licence number saved
- [x] B-3.2 Licence document upload feedback
- [x] B-3.3 GST optional path works
- [x] B-3.4 Location capture — permission granted flow
- [x] B-3.5 Location — permission denied shows helpful message
- [x] B-3.6 Submit → pending UI
- [x] B-3.7 Admin Suppliers case visible

### B.4 Trucker core flows

- [x] B-4.1 Find Loads tab loads marketplace list
- [x] B-4.2 Scroll pagination / load more
- [x] B-4.3 Marketplace card → load detail
- [x] B-4.4 Load detail — route, price, book CTA (env permitting)
- [x] B-4.5 Booking request sent (if test env supports)
- [x] B-4.6 Trips list shows active trip after booking
- [x] B-4.7 Trip detail — stage actions (as applicable)
- [x] B-4.8 Fleet: add second truck post-verification (optional)
- [x] B-4.9 Diesel / filter UI on find loads (no crash)

### B.5 Supplier core flows

- [x] B-5.1 Dashboard loads stats / sections
- [x] B-5.2 Post new load — required fields validation
- [x] B-5.3 Post load — publish success
- [x] B-5.4 My Loads — new load appears
- [x] B-5.5 Load detail — bookings section
- [x] B-5.6 Approve trucker booking (test account)
- [x] B-5.7 Reject booking — trucker notification (if applicable)
- [x] B-5.8 Trips tab — trip after assignment
- [x] B-5.9 Trip detail — documents / stage

### B.6 Cross-cutting

- [x] B-6.1 Notifications badge count sane
- [x] B-6.2 Open notification → correct deep link screen
- [ ] B-6.3 Booking approved/rejected notification TTS phrase (trucker, HI) — §C-3.3 / C-6.7
- [x] B-6.4 Chat list + open thread — send text message
- [x] B-6.5 Chat voice record (if in scope) — no regression
- [x] B-6.6 Profile screen — hear summary button works
- [x] B-6.7 Settings — hear summary button works
- [ ] B-6.8 App bar mute (`TtsActionButton`) stops auto screen speech — §C-6.4
- [ ] B-6.9 Voice settings — pick Hindi voice + test — §C-6
- [ ] B-6.10 Voice settings — pick English voice + test — §C-6
- [x] B-6.11 Support / report issue — submit ticket (minimal)

---

## C. TTS expansion — in progress

**Design:** [TTS-29-may.md](./TTS-29-may.md)  
**Codegen:** `TranZfort/tool/gen_tts_l10n.ps1` (app + TTS ARBs)

### C-0 Architecture decisions (lock before code)

- [ ] C-0.1 Team review of TTS-29-may.md
- [x] C-0.2 **D-1** Approved: split `tts_en.arb` + `tts_hi.arb` (not prefix in `app_en.arb`)
- [x] C-0.3 **D-2** Approved: list cards = manual speaker only (no auto-read all cards)
- [x] C-0.4 **D-3** Approved: separate `tts_audio_language` preference
- [x] C-0.5 **D-4** Approved: skip profit estimate in load card TTS by default
- [x] C-0.6 **D-5** Decision: **delete** unwired `TtsAnnounce`, `DashboardAutoSpeakEffect`, `TruckerTtsSummaries`, `SupplierTtsSummaries` (superseded by ARB + card speakers)
- [ ] C-0.7 Create tracking issue / milestone in GitHub (optional)

### C-1 Phase 0 — Foundation

#### C-1.1 Localization split

- [x] C-1.1.1 Create `lib/l10n/tts/tts_en.arb` (template)
- [x] C-1.1.2 Create `lib/l10n/tts/tts_hi.arb`
- [x] C-1.1.3 `l10n_tts.yaml` + `tool/gen_tts_l10n.ps1` for TTS codegen
- [x] C-1.1.4 Run `flutter gen-l10n` — `TtsLocalizations` generates without error
- [x] C-1.1.5 Document rule: no spoken-only strings in `app_*.arb` (see TTS-29-may.md)

#### C-1.2 Audio language preference

- [x] C-1.2.1 Add `tts_audio_language` key in SharedPreferences
- [x] C-1.2.2 `TtsAudioLanguageProvider` — default mirrors UI locale
- [x] C-1.2.3 Settings UI: “Voice language” / “बोलने की भाषा” dropdown (follow app / EN / HI)
- [x] C-1.2.4 `TtsPlaybackController` reads audio language (not only UI locale)

#### C-1.3 Utterance builder — marketplace load

- [x] C-1.3.1 Create `load_marketplace_card_tts_builder.dart` (or `features/tts/`)
- [x] C-1.3.2 Input: `MarketplaceLoadItem` + `TtsLocalizations` + `AppLocalizations`
- [x] C-1.3.3 Clause: route (origin → destination) — Hindi + English templates
- [x] C-1.3.4 Clause: material (localized)
- [x] C-1.3.5 Clause: truck tyres/capacity range (spoken words, not `10-18T`)
- [x] C-1.3.6 Clause: rate per ton vs fixed total
- [x] C-1.3.7 Clause: pickup timing (today / tomorrow / date)
- [x] C-1.3.8 Omit empty optional clauses (no “null” speech)
- [x] C-1.3.9 Unit test: golden Hindi string for fixture load
- [x] C-1.3.10 Unit test: golden English string for same fixture

#### C-1.4 ARB template keys (minimum set)

- [x] C-1.4.1 `ttsLoadCardRoute`
- [x] C-1.4.2 `ttsLoadCardMaterial`
- [x] C-1.4.3 `ttsLoadCardTruckTyres`
- [x] C-1.4.4 `ttsLoadCardRatePerTon`
- [x] C-1.4.5 `ttsLoadCardRateFixed`
- [x] C-1.4.6 `ttsLoadCardPickupToday`
- [x] C-1.4.7 `ttsLoadCardPickupTomorrow`
- [x] C-1.4.8 `ttsListenToLoadHint` (accessibility / tooltip)

#### C-1.5 Shared UI widgets

- [ ] C-1.5.1 `TtsIconButton` — icon, tooltip, onPressed, respects mute
- [ ] C-1.5.2 `TtsSpeakableCard` — child + optional speaker slot; absorbs pointer on speaker
- [x] C-1.5.3 Speaker tap calls `stop()` then `play(utterance)` (`TtsCardSpeakerButton`)
- [x] C-1.5.4 Muted → snackbar `commonVoiceMuted`

#### C-1.6 Wire MarketplaceLoadCard

- [x] C-1.6.1 Add speaker to `MarketplaceDarkHeader` supplier row (top-right)
- [x] C-1.6.2 Pass utterance from parent or builder inside card
- [x] C-1.6.3 Verify card `onTap` still opens detail when tapping non-speaker area
- [ ] C-1.6.4 Manual test: Hindi UI + Hindi audio on sample card

### C-2 Phase 1 — Lists

#### C-2.1 Supplier load list card

- [x] C-2.1.1 Add `supplierLoadCardRouteTitle(origin, destination)` to `app_en.arb` / `app_hi.arb`
- [x] C-2.1.2 Replace inline `'$origin to $destination'` in `_SupplierLoadListCard`
- [x] C-2.1.3 `SupplierLoadListCardTtsBuilder` (or reuse load builder with `Load` model)
- [x] C-2.1.4 Speaker on `StandardListCard` trailing
- [ ] C-2.1.5 Manual test EN + HI

#### C-2.2 Trip list cards

- [x] C-2.2.1 `TripListCardTtsBuilder` for trucker `_TruckerTripCard`
- [x] C-2.2.2 Speaker on trucker trip card
- [x] C-2.2.3 `TripListCardTtsBuilder` for supplier `_SupplierTripCard`
- [x] C-2.2.4 Speaker on supplier trip card
- [x] C-2.2.5 Stage labels from UI l10n (not raw enum strings)

#### C-2.3 Lifecycle / navigation

- [x] C-2.3.1 `TtsStopOnRouteChange` — `stop()` TTS on shell route change / dispose
- [ ] C-2.3.2 List scroll — optional stop when card off-screen (product choice)
- [x] C-2.3.3 No overlapping speech from previous screen

#### C-2.4 UI string cleanup (feeds TTS)

- [x] C-2.4.1 Move `Pickup Today` from `marketplace_load_card.dart` → `app_*.arb`
- [x] C-2.4.2 Move `Pickup Tomorrow` → `app_*.arb`
- [ ] C-2.4.3 Move month abbreviations or use `DateFormat` + l10n
- [x] C-2.4.4 Mirror pickup strings in `tts_*.arb` for speech

### C-3 Phase 2 — Detail screens & notifications

#### C-3.1 Load detail

- [ ] C-3.1.1 `LoadDetailTtsBuilder` — section: route & price
- [ ] C-3.1.2 Section: material & weight
- [ ] C-3.1.3 Section: truck requirements
- [ ] C-3.1.4 Trucker load detail — speaker per `DetailSectionCard` header
- [ ] C-3.1.5 Supplier load detail — same pattern
- [ ] C-3.1.6 Optional “Read all sections” button (concat with 500 char cap)

#### C-3.2 Trip detail

- [ ] C-3.2.1 Trip detail builder — route + stage
- [ ] C-3.2.2 Section: proof / POD / LR status (trucker)
- [ ] C-3.2.3 Section: payment / documents (supplier)
- [ ] C-3.2.4 Speakers on high-priority sections first

#### C-3.3 Notifications

- [x] C-3.3.1 Move booking phrases from `notification_tts_service.dart` → `tts_*.arb`
- [x] C-3.3.2 Support approved + rejected via `ttsBookingApproved` / `ttsBookingRejected`
- [x] C-3.3.3 Match notification title case-insensitively + `bookingUpdate` type
- [ ] C-3.3.4 Optional per-row speaker on notification tile

#### C-3.4 Screen-level summaries

- [x] C-3.4.1 Deleted unused `TruckerTtsSummaries` (screen summaries use `TtsScreenSummaryEffect` + ARB over time)
- [x] C-3.4.2 Deleted unused `SupplierTtsSummaries`
- [ ] C-3.4.3 Find Loads tab: richer summary than tab title only (product approval)
- [ ] C-3.4.4 Filter-aware intro: “{count} loads mili” when filters applied

### C-4 Phase 3 — Forms & verification

- [ ] C-4.1 Onboarding: one `tts_onboarding_roleStep` ARB key (remove 3-title concat)
- [ ] C-4.2 Onboarding: one key per profile completion step
- [ ] C-4.3 Auth welcome: max 2 sentences auto-play
- [ ] C-4.4 Post load wizard: TTS per step title + required fields list
- [ ] C-4.5 Wire `tts_focus_field.dart` on post load numeric fields (optional)
- [ ] C-4.6 Verification step 1 photo — spoken instructions
- [ ] C-4.7 Verification step 2 identity — spoken requirements
- [ ] C-4.8 Verification step 3 truck/business — spoken requirements
- [ ] C-4.9 Verification review — spoken checklist before submit
- [ ] C-4.10 Supplier public profile — wire screen summary or remove speaker
- [ ] C-4.11 Trucker public profile — same

### C-5 Phase 4 — Polish

- [ ] C-5.1 Replay last utterance button (settings or long-press speaker)
- [ ] C-5.2 Speech rate slider in voice settings (restore if removed)
- [ ] C-5.3 Analytics event `tts_play` with `surface`, `lang`, `muted`
- [ ] C-5.4 QA device: Samsung mid-range
- [ ] C-5.5 QA device: Xiaomi / Redmi
- [ ] C-5.6 QA: offline Hindi voice package
- [ ] C-5.7 Hindi number words for currency (optional)
- [ ] C-5.8 List footer “Listen to focused load” accessibility mode (optional)

### C-6 TTS regression tests (after implementation)

- [ ] C-6.1 UI HI + audio HI — marketplace card
- [ ] C-6.2 UI EN + audio EN — marketplace card
- [ ] C-6.3 UI EN + audio HI — override in settings
- [ ] C-6.4 Global mute — speaker shows muted snackbar
- [ ] C-6.5 Fast scroll list — speech stops
- [ ] C-6.6 Load missing optional fields — short utterance still valid
- [ ] C-6.7 Booking notification spoken from ARB
- [ ] C-6.8 Long “read all” — truncates gracefully at ~500 chars

---

## D. Localization hygiene — pending `[ ]`

- [ ] D-1 Add PR checklist item: spoken strings only in `tts_*.arb`
- [ ] D-2 Grep audit: `'\${` string interpolation in `lib/src/features/**` — file list fix queue
- [ ] D-3 Grep audit: `lib/src/shared/widgets/**` — same
- [ ] D-4 Fix top 5 worst card title interpolations (supplier load, trip route, etc.)
- [x] D-5 Document when to use `app_*.arb` vs `tts_*.arb` — [TTS-ARB-GUIDE.md](./TTS-ARB-GUIDE.md)
- [ ] D-6 Evaluate ARB split by feature (epic — not blocking TTS Phase 0)
- [ ] D-7 After any ARB edit: run `flutter gen-l10n`
- [ ] D-8 After gen-l10n: commit `app_localizations*.dart` + `tts_localizations*.dart`
- [ ] D-9 CI check: fail if ARB edited without regenerated Dart (optional)
- [ ] D-10 Remove duplicate / unused l10n keys found during audit (separate PR)
- [ ] D-11 Verify `commonFromLabel` / `commonToLabel` not used alone for TTS
- [ ] D-12 Material names: lookup table for common commodities (coal, cement, steel) EN+HI

---

## E. Admin app — verified `[x]`

- [x] E-1 Build Admin app against same Supabase project
- [x] E-2 Login as admin user in `admin_users`
- [x] E-3 Open verification queue — no crash
- [x] E-4 Trucker submit — case appears in Truckers list
- [x] E-5 Trucker submit — truck sub-case in Trucks list (if applicable)
- [x] E-6 Supplier submit — case in Suppliers list
- [x] E-7 Open case — view document paths / images
- [x] E-8 Approve trucker — app shows verified / unblocked flows
- [x] E-9 Reject with reason — app shows rejected + resubmit path (ties to A-1)

---

## R. Release gate — **open** (Play Store + `main`)

- [ ] R-1 Merge `feature/play-store-readiness-2026-05-16` → `main` (after internal track upload or when TTS slice is ready)
- [ ] R-2 Push `main` to `origin`
- [ ] R-3 Optional: tag release candidate (`A-5.5`)

---

## F. Documentation & repo — pending `[ ]`

- [x] F-1 Create `docs/TASK-completed-29-may.md` locally
- [x] F-2 Create `docs/TTS-29-may.md` locally
- [x] F-3 Create `docs/TODO-29-may.md` locally
- [ ] F-4 `git add -f docs/*.md` and commit to `main`
- [ ] F-5 Push docs commit to origin
- [ ] F-6 Consider removing `docs/` from `.gitignore` or documenting force-add workflow

---

## Progress log

| Date | Done | Note |
|------|------|------|
| 2026-05-29 | Z-1–Z-9 | Play-store readiness merged to `main`; see §Z |
| 2026-05-29 | F-1–F-3 | Planning docs created |
| 2026-05-29 | C-1 (WIP) | TTS Phase 0 started on `feature/play-store-readiness-2026-05-16` (reverted mistaken `feature/tts-expansion-2026-05-29` branch) |
| 2026-05-29 | C-1, C-2, C-3.3 | Phase 0–1 lists + notification ARB; pushed `9d8f8c2` |
| 2026-05-29 | C-1.2.3, C-0.6, C-3.4.1–2 | Spoken-language settings; deleted dead TTS widgets; CTO roadmap in §Quick priority |
| 2026-05-29 | A-1.7, D-5 | Verification wizard unit tests; TTS ARB guide |
| 2026-05-29 | §A, §B, §E | Team sign-off: pre-TTS flows tested & working on device |
| 2026-05-29 | §R, A-5.6–7 | **Still open:** Play Console internal + merge to `main` |
| | | |
| | | |

---

## CTO execution plan (complete all pending)

**Goal:** Play Store internal track with stable verification + usable TTS for low-literacy truckers.  
**Branch:** `feature/play-store-readiness-2026-05-16` only.  
**Rule:** Agent marks `[x]` only for code merged + tests green; human marks `[x]` for device/Admin/Play Console items.

### Sprint 1 — Ship gate (now → 2 days) — *engineering*

| # | Tasks | Owner | Blocks |
|---|--------|-------|--------|
| 1 | ~~**A-1.7** Verification unit tests~~ | Agent | Done (`verification_wizard_unit_test.dart`) |
| 2 | **A-4** Confirm 3 migrations on target Supabase (`db push` / dashboard) | Human + Agent SQL checklist | Release |
| 3 | **A-5.1–A-5.3** `build-apk.bat` + install smoke | Human | Play upload |
| 4 | ~~Fix remaining red tests (notifications routing)~~ | Agent | Done |
| 5 | ~~**C-1.2.3** Voice language settings~~ | Agent | Done |

### Sprint 2 — Play Store proof — *mostly done; release gate open*

| # | Tasks | Owner | Status |
|---|--------|-------|--------|
| 1 | ~~A-1.1–A-1.3 + E-1–E-9~~ | Human | Verified |
| 2 | ~~A-2, A-3, B-1–B-5~~ | Human | Verified |
| 3 | **A-5.6–A-5.7** Play Console internal + release notes | Human | **Open** |
| 4 | **R-1–R-2** Merge feature branch → `main`, push | Human | **Open** |

**Product decisions (block A-1.4 / A-1.5):** Default = **defer** `company_name` + `profile_photo` server-required until post-launch unless reject rate high. Truck photo = **UI-only** for v1 (document in A-1.5.4).

### Sprint 3 — TTS value (1 week) — *agent*

| # | Tasks |
|---|--------|
| 1 | **C-3.1–C-3.2** Load + trip **detail** section speakers |
| 2 | **C-2.4.3** Pickup dates via `DateFormat` + l10n |
| 3 | **C-3.3.4** (optional) Notification row speaker |
| 4 | **D-4, D-5** Top card interpolation fixes + `app` vs `tts` ARB doc |

### Sprint 4 — TTS depth (2 weeks) — *agent + spot QA*

| # | Tasks |
|---|--------|
| 1 | **C-4** Onboarding / verification / post-load spoken guidance |
| 2 | **C-3.4.3–4** Richer Find Loads tab summary (product copy in ARB) |
| 3 | **C-5** Polish (replay, rate slider, analytics) |
| 4 | **C-6** TTS regression pass on 2 physical devices |

### Sprint 5 — Hygiene & close (ongoing)

| # | Tasks |
|---|--------|
| 1 | **D-1–D-12** Localization audit (non-blocking for Play) |
| 2 | **F-4–F-6** Docs force-add or un-ignore `docs/` |
| 3 | **A-1.4–A-1.6**, **C-1.5.1–2**, **C-5.8** — only if time before wider rollout |

### Deferred / won’t do for v1

- **C-1.5.1–1.5.2** `TtsIconButton` / `TtsSpeakableCard` — `TtsCardSpeakerButton` is the standard; skip unless design requests wrapper.
- **C-2.3.2** Stop TTS when card scrolls off-screen — skip (route change stop is enough).
- **D-6, D-9, D-10** — post-launch engineering hygiene.

---

## Quick priority (active queue)

1. [ ] **A-5.6–A-5.7** — Play Console internal testing + release notes  
2. [ ] **R-1–R-2** — merge `feature/play-store-readiness-2026-05-16` → `main`, push  
3. [ ] **C-3.1–C-3.2** — detail screen TTS (agent, on feature branch)  
4. [ ] **C-6** — device TTS regression (B-6.3, B-6.8–B-6.10) after TTS slices land  
5. [ ] **A-1.4–A-1.6** — post-v1 polish only if needed  

---

*Expanded checklist 29 May 2026. Template: `TODO-24-april.md`, `TODO-gap-fix-17-march.md`.*
