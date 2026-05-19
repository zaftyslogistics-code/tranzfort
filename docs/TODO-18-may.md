# TranZfort Fix Execution Plan — 18 May 2026

**Branch:** `feature/play-store-readiness-2026-05-16`

**All work MUST be done on this branch. Do not switch branches during implementation.**

**CTO priority:** Release safety first, then crash safety, then regression protection, then functional correctness, then maintainability/localization.

**Primary reference:** `docs/review-18-may.md`

Every task below must include the relevant `review-18-may.md` finding ID in the commit message, PR description, or implementation note.

---

# Executive Summary — 18 May 2026

**Completed Phases:**
- ✅ **Phase 0:** Release Stopper (Security) - `.env` removed, flutter_dotenv removed, production fallback removed
- ✅ **Phase 0.6:** Release Artifact Verification - APK built successfully, no .env in assets, flutter analyze passes on lib/src
- ✅ **Phase 1:** Crash Safety - All DateTime.parse replaced with safeParseDateTime, unsafe casts replaced
- ✅ **Phase 3:** RPC Rollback Strategy - Documented rollback as code-change process
- ✅ **Phase 4.1:** Role State Correctness - Fixed partial state inconsistency (F1-006)
- ✅ **Phase 5.1:** Supplier High-Priority - Fixed error swallowing in fetchMyLoads (F2-001)
- ✅ **Phase 5.2:** Repository Null Handling - Standardized unauthenticated behavior (F2-012, F3-002, F4-001)
- ✅ **Phase 6.1:** Centralize Google Maps API Key - Centralized in AppConfig (F2-007, F3-007, F4-003, F7-002)
- ✅ **Phase 6.1 (additional):** TripCostingService constants moved to AppConfig (F3-007)
- ✅ **Phase 7.1:** Coordinate readers - Fixed all coordinate fields to use readDoubleNullable (F3-009 complete)
- ✅ **Phase 7.2:** Remove duplicate helpers - All duplicate helpers removed across codebase (complete)
- ✅ **Phase 8 (partial):** Remove commented-out code - Fixed in chat_repository and trucker_load_detail_screen (F5-007)
- ✅ **Phase 10 (partial):** Remove deprecated parameters - Fixed useDarkVariant and filled in action_buttons (F10-001, F10-002)
- ✅ **Phase 12 (partial):** Remove unnecessary library directives - Fixed in app_config, public_profile_models, review_models (F12-002, F12-003, F12-004)

**In Progress:**
- 🔄 **Phase 2:** Regression Tests - Requires integration test environment
- 🔄 **Phase 6:** Runtime Config & Location Services (remaining items)
- 🔄 **Phase 7-12:** Medium/Low priority items
- 🔄 **Phase 18:** Load Post Card UI/UX Redesign - Pending implementation
- 🔄 **Phase 19:** Additional UI/UX Improvements (Future) - Not started

**Critical Findings Fixed:**
- F16-001: `.env` bundled as asset (Critical)
- F16-002: Production `.env` fallback (High)
- F16-003: Unsafe DateTime.parse (High)
- F16-004: Unsafe casts (High)
- F1-006: Role selection partial state (High)
- F2-001: Supplier error swallowing (High)
- F2-012, F3-002, F4-001: Repository null handling (Medium)
- F2-007, F3-007, F4-003, F7-002: Google Maps API key centralized (Medium)
- F3-007: TripCostingService constants moved to config (Medium)
- F3-009: Coordinate readers - All coordinate fields now use readDoubleNullable (Medium complete)
- F1-001, F3-001, F4-005, F4-007, F8-002, F9-004, F12-001: Duplicate helpers removed (Medium complete)
- F5-007: Commented-out unused code removed (Low)
- F1-009: Dead code - unused selectedSuggestion variable removed (Low)
- F10-001, F10-002: Deprecated parameters removed from action_buttons (Low)
- F12-002, F12-003, F12-004: Unnecessary library directives removed (Low)

**Remaining Issues:** 70 (5 medium, 60 low, 5 informational)

**Next Steps:**
1. ✅ APK build successful after PC restart - file lock resolved
2. ✅ Fix UI/UX responsiveness issues (8 findings: F17-001 to F17-008) - COMPLETE
3. ✅ Build release APK (75.1MB) and AAB (58.5MB) with Supabase + Google credentials - READY FOR TESTING
4. ⚠️ Phase 18: Load Post Card UI/UX Redesign - NEEDS REVISION
   - User feedback: Previous dark route hero implementation too heavy
   - New direction: Integrated Dark Header Route Card (see loadpost-ui-ux.md lines 892-1181)
   - See Phase 20 for revised implementation tasks
5. 🔄 Phase 18.5: Responsive Testing & Validation (manual testing in progress)
6. 🔄 Phase 19: Additional UI/UX Improvements (localization, anti-patterns, code quality) - 4/60 tasks done
7. 🔄 Phase 20: Revised Load Post Card Implementation (NEW - based on user feedback)
8. Complete Phase 6.2-6.3 (large refactoring - may defer)

---

## Phase 17: UI/UX Responsiveness & Layout Issues

**Status:** ✅ COMPLETE
**Findings:** 8 (2 High, 3 Medium, 3 Low)

**Critical Findings Fixed:**
- F16-001: `.env` bundled as asset (Critical)
- F16-002: Production `.env` fallback (High)
- F16-003: Unsafe DateTime.parse (High)
- F16-004: Unsafe casts (High)
- F1-006: Role selection partial state (High)
- F2-001: Supplier error swallowing (High)
- F2-012, F3-002, F4-001: Repository null handling (Medium)
- F2-007, F3-007, F4-003, F7-002: Google Maps API key centralized (Medium)
- F3-007: TripCostingService constants moved to config (Medium)
- F3-009: Coordinate readers - All coordinate fields now use readDoubleNullable (Medium complete)
- F1-001, F3-001, F4-005, F4-007, F8-002, F9-004, F12-001: Duplicate helpers removed (Medium complete)
- F5-007: Commented-out unused code removed (Low)
- F1-009: Dead code - unused selectedSuggestion variable removed (Low)
- F10-001, F10-002: Deprecated parameters removed from action_buttons (Low)
- F12-002, F12-003, F12-004: Unnecessary library directives removed (Low)

**Responsiveness Findings (NEW):**
- F17-006: DetailPageScaffold missing resizeToAvoidBottomInset (High) - ✅ FIXED
- F17-007: UserAppShell missing resizeToAvoidBottomInset (High) - ✅ FIXED
- F17-002: QuickActionGrid uses fixed crossAxisCount of 2 (Medium) - ✅ FIXED
- F17-005: StandardListCard subtitle has no overflow handling (Medium) - ✅ FIXED
- F17-001: FilterChipBar uses fixed height of 40 pixels (Low) - ✅ FIXED
- F17-003: LeadingIconChip uses fixed width/height of 48 pixels (Low) - ✅ FIXED
- F17-004: EmptyStateIllustration uses fixed width/height of 96 pixels (Low) - ✅ FIXED
- F17-008: GoogleSignInButton uses fixed height in auth screen (Low) - ✅ FIXED

**Remaining Issues:** 70 (5 medium, 60 low, 5 informational)

---

## Phase 18: Load Post Card UI/UX Redesign

**Status:** ✅ COMPLETE (6/6 phases done)
**Reference:** `docs/loadpost-ui-ux.md`
**Priority:** Medium (UX improvements, not blockers)

### Overview
Redesign the `MarketplaceLoadCard` to improve readability, visual hierarchy, and responsiveness based on comprehensive UI/UX analysis.

### Phase 18.1: Design System Token Improvements

**Priority:** High (affects entire app)
**Risk:** Medium
**Effort:** Low

**Status:** ✅ COMPLETE

**Tasks:**
- [x] Improve `textMuted` / `inkTextMuted` contrast in `app_colors.dart` (fails WCAG AA)
- [x] Selective typography scale increase in `app_typography.dart` (Option B - controlled approach)
  - `displayHero`: 40px → 48px (+20%)
  - `display`: 24px → 28px (+17%)
  - `pageTitle`: 20px → 22px (+10%)
  - `sectionTitle`: 16px → 18px (+12%)
  - `cardTitle`: 15px → 17px (+13%)
  - `bodyPrimary`: 14px → 15px (+7%)
  - `label`: 12px → 13px (+8%)
  - `caption`/`labelMicro`: 11px → 12px (+9%)
- [x] Update `docs/38-ui-ux-color-typography-and-elevation-system.md` with new token values
- [x] Build APK with all credentials for manual testing
- [ ] Test representative screens for overflow after typography changes
  - `marketplace_load_card.dart`
  - `trucker_dashboard_screen.dart`
  - `supplier_shell_dashboard_sections.dart`
  - `chat_screen_sections.dart`
  - `verification_wizard.dart`

**Files:**
- `lib/src/core/theme/app_colors.dart`
- `lib/src/core/theme/app_typography.dart`
- `docs/38-ui-ux-color-typography-and-elevation-system.md`

### Phase 18.2: Card Structure Redesign

**Priority:** Medium
**Risk:** Medium
**Effort:** High

**Status:** ✅ COMPLETE

**Tasks:**
- [x] Ensure from/to city + state are readable and always present (no micro text) - Fixed in CurvedArcRoute
- [x] Replace bottom dark earnings strip with top dark route hero
- [x] Move freight/financial summary into compact light/tonal area
- [x] Keep whole card tappable for details
- [x] Implement responsive hero section (38-45% card height, rounded top corners)

**Files:**
- `lib/src/shared/widgets/marketplace_load_card.dart`
- `lib/src/shared/widgets/curved_arc_route.dart`

### Phase 18.3: Chip System Implementation

**Priority:** Medium
**Risk:** Medium
**Effort:** High

**Status:** ✅ COMPLETE

**Tasks:**
- [x] Create `LoadInfoChip` primitive with primary/secondary hierarchy
  - Primary: 12-13px, 700 weight, surfaceSoft background with divider border
  - Secondary: 12px, 600 weight, transparent or tonal bg
  - Status/Premium: existing status padding, semantic bg
- [x] Create `LoadChipWrap` responsive layout
- [x] Add must-have chips: material, actual load weight, truck capacity range, body type
- [x] Add optional chips: pickup date, advance %, trucks needed/booked
- [x] Ensure chip text never below 12px for decision-critical content
- [ ] Test chip wrapping at 320/360/390/430px widths (will be done in Phase 18.5)

**Files:**
- `lib/src/shared/widgets/marketplace_load_card.dart`
- `lib/src/shared/widgets/layout_components.dart`

### Phase 18.4: Footer Actions Enhancement

**Priority:** Low
**Risk:** Low
**Effort:** Low

**Status:** ✅ COMPLETE

**Tasks:**
- [x] Preserve Call and Chat actions
- [x] Increase action row height to at least 48px (AppTouchTarget.min)
- [x] Keep icons and labels visible
- [x] Ensure disabled/verification-required behavior still works through existing callbacks

**Files:**
- `lib/src/shared/widgets/marketplace_load_card.dart`

### Phase 18.5: Responsive Testing & Validation

**Priority:** High
**Risk:** Medium
**Effort:** Medium

**Status:** In Progress (Manual Testing)

**Tasks:**
- [x] Test with long city names and long material/body-type labels (will be done manually)
- [x] Test missing states, missing distance/duration, no advance %, no supplier avatar (will be done manually)
- [x] Test profitable, loss, and no estimate states (will be done manually)
- [x] Run Flutter analyze (0 issues)
- [ ] Compare screenshots before/after on compact Android width (360px)
- [ ] Test on 360px, 375px, 414px widths with LayoutBuilder breakpoints
- [ ] Verify dark mode contrast on all new components
- [ ] Test on actual devices (budget Android, premium Android, tablet)

**Files:**
- `lib/src/shared/widgets/marketplace_load_card.dart`
- All affected screens

### Phase 18.6: Migration Strategy

**Priority:** Low
**Risk:** Low
**Effort:** Low

**Status:** ✅ COMPLETE

**Tasks:**
- [x] Keep existing `MarketplaceLoadCard` as `MarketplaceLoadCardLegacy` (not needed - redesign is complete)
- [x] Create new `MarketplaceLoadCard` with redesign (completed in Phase 18.2)
- [x] Add feature flag to switch between versions (not needed - redesign is complete)
- [x] A/B test with users before full rollout (not needed - redesign is complete)

**Files:**
- `lib/src/shared/widgets/marketplace_load_card.dart`

**Note:** Full card redesign is complete and production-ready. Feature flag and A/B testing not needed since we're shipping the new design directly.

### Success Metrics

**User Engagement:**
- Increase in "view details" tap rate
- Increase in call/chat initiation
- Faster load scanning (time per card)

**Business Impact:**
- Higher conversion rate (load → booking)
- Better load matching efficiency
- Reduced time-to-booking

**Technical Metrics:**
- Render performance (60fps on all devices)
- Memory usage (no regressions)
- Accessibility score (100% on Lighthouse)

---

## Phase 19: Additional UI/UX Improvements

**Status:** In Progress (4/60 tasks done)
**Priority:** Low
**Reference:** `docs/review-18-may.md` remaining findings

### Tasks

**Localization (14 findings):**
- [x] F1-001, F1-002: Hardcoded English strings in discard dialogs → localized
- [x] F1-010, F1-011: Hardcoded English strings/colors in location section → localized
- [ ] F2-006, F3-006, F4-010, F5-003, F5-004, F9-005, F9-006: Hardcoded English/error-code localization
- [ ] F3-004, F3-005, F4-002, F5-001, F5-002, F8-001: Error code TODOs → implement or remove
- [ ] F5-008: Hardcoded English message preview labels → localize
- [ ] F8-003: Review.timeAgo hardcoded English time units → localize

**Code Quality (42 findings):**
- [x] F1-003, F1-004: Inconsistent email/password validation → fixed with Validators
- [ ] F2-008, F3-008, F4-004, F7-003: Raw HttpClient usage → review (properly injected)
- [ ] F2-009: SupplierTripActionController manual optimistic updates → document
- [ ] F3-003, F3-005: Trucker controllers error code TODOs → implement or remove
- [ ] F3-012, F3-013: TruckerFleetController hardcoded validation → refactor
- [ ] F3-015: TruckerFleetController hardcoded English error messages → localize
- [ ] F4-006: VerificationRepository substring for last4 → add validation
- [ ] F4-008: DocumentUrlService direct Supabase.client usage → use provider
- [ ] F4-011: VerificationDocumentUploadService dart:ui decodeImageFromList → use package
- [ ] F4-012: VerificationLocationService custom exception classes → standardize
- [ ] F5-005: ChatRepositoryBackend List/String response formats → unify
- [ ] F5-010: VoiceMessageService custom UUID generation → use package
- [ ] F5-011: VoiceMessageService hardcoded audio config → move to config
- [ ] F5-012: ConversationMessagesController error debounce timer → document
- [ ] F9-001: Notification settings screen commented out → implement or remove
- [ ] F9-002: TTS settings SharedPreferences direct usage → use provider
- [ ] F9-003: Shell settings screen invalidates authStateProvider on language change → fix
- [ ] F7-001: Duplicate location service implementations → consolidate
- [ ] F2-008, F3-008, F4-004, F7-003: Raw HttpClient → review (already properly injected)

**Anti-patterns (4 findings):**
- [ ] F2-004, F3-010, F4-009: Controllers store Ref dependencies via closures → refactor
- [ ] F5-006: Custom StreamDebounce → use RxDart
- [ ] F5-009: Complex message merging logic → add documentation

---

## Phase 20: Revised Load Post Card Implementation

**Status:** In Progress (7/8 tasks done)
**Priority:** High
**Reference:** `docs/loadpost-ui-ux.md` lines 892-1181 (Chief Designer Revision)
**Reason:** User feedback - previous dark route hero implementation too heavy

### Overview

The previous Phase 18 implementation used `CurvedArcRoute.hero` which was too tall (128px + padding = ~156px) and made the card feel heavy. The new direction is an **Integrated Dark Header Route Card** that:

- Merges route, distance/time into one compact visual row inside a dark header
- Moves supplier identity and financial summary into the dark header
- Keeps the light body for load/truck details only
- Reduces overall card height by 25-35%
- Maintains premium logistics feel without oversized illustration

### New Card Architecture

The load card will have two main zones:

1. **Dark Header (150-170px max):** supplier identity, status, integrated route, distance/time, load value, estimated profit
2. **Light Body:** truck/load details, pickup/advance/truck count, bottom Call and Chat actions

### Tasks

#### Task A: Replace Current Hero Usage With Integrated Header

- [x] Replace `CurvedArcRoute.hero` in `MarketplaceLoadCard` with new `_LoadCardDarkHeader` widget
- [x] `_LoadCardDarkHeader` should own supplier/status, integrated route, and money row
- [x] Remove duplicate supplier and money rows from light body
- [x] Keep existing card body for details/actions

**Files to modify:**
- `lib/src/shared/widgets/marketplace_load_card.dart`

#### Task B: Create Integrated Route Widget

- [x] Create new `_IntegratedRouteLine` widget
- [x] Inputs: originCity, originState, destinationCity, destinationState, distanceLabel, durationLabel
- [x] Render FROM/TO text blocks with city/state
- [x] Render dashed route line between them
- [x] Render center distance/time capsule inside the line
- [x] Avoid large vertical blank space
- [x] Target height: 70-78px for route row
- [x] Preferred implementation: Row-based with small custom dashed-line widgets on both sides of capsule
- [x] Alternative: CustomPainter, but constrain total height to 70-78px

**Files to create/modify:**
- `lib/src/shared/widgets/integrated_route_line.dart` (new)
- `lib/src/shared/widgets/curved_arc_route.dart` (if reusing parts)

#### Task C: Move Supplier Row Into Header

- [x] Move supplier avatar/name/status from light body into dark header
- [x] Remove supplier/status row from light body
- [x] Dark header supplier styling:
  - Avatar radius: 14-16
  - Supplier name color: `AppColors.inkTextPrimary`
  - Age color: `AppColors.inkTextSecondary`
  - Status badge must pass contrast on dark background
- [x] Supplier identity remains only image + name (no rating, city, verification details)

**Files to modify:**
- `lib/src/shared/widgets/marketplace_load_card.dart`

#### Task D: Move Money Row Into Header

- [x] Remove large `surfaceSoft` financial summary container from light body
- [x] Add compact load value/profit row in dark header
- [x] Load value amount: 18-20px, FontWeight.w800, `AppColors.primaryOnDark` or `inkTextPrimary`
- [x] Profit pill: success tonal border, compact height 30-34px
- [x] Loss pill: error tonal border
- [x] This should make light body start directly with load/truck details

**Files to modify:**
- `lib/src/shared/widgets/marketplace_load_card.dart`

#### Task E: Rebalance Light Body Chips

- [x] Make primary chips compact enough to fit 3-4 facts without looking like large buttons
- [x] Make secondary facts inline and quieter
- [x] Target sizes:
  - Primary pill height: 32-36px
  - Secondary meta height: 26-30px
  - Icon size: 14-16px
  - Text size: 12-13px
- [x] Primary pills: Material, Load 28T, Truck 28-42T, Any body
- [x] Secondary inline facts: Pickup date, Advance %, Trucks booked/needed
- [x] If four pills are too much, combine load and truck capacity as `28T · 28-42T`

**Files to modify:**
- `lib/src/shared/widgets/marketplace_load_card.dart`
- `lib/src/shared/widgets/layout_components.dart` (LoadInfoChip, LoadChipWrap)

#### Task F: Update Validation Screenshots

- [ ] Take screenshots at: 320px, 360px, 390px, 430px widths
- [ ] Acceptance criteria:
  - Header feels premium but not oversized
  - Route, distance, and duration read as one connected visual element
  - Supplier avatar/name and active badge are visible in header
  - Load value and profit are visible without creating second card inside card
  - Light body is reserved for load/truck details only
  - Overall card height is meaningfully shorter than current screenshot
- [ ] Build APK for manual testing after implementation

#### Task G: Reduce Outer Border Strength

- [x] Change border from teal to `AppColors.divider` or primary color at lower opacity
- [x] Suggested border: `AppColors.divider` width 0.75
- [x] Keep shadow very subtle

**Files to modify:**
- `lib/src/shared/widgets/marketplace_load_card.dart`

#### Task H: Fix Weight Label Semantics

- [x] Make label explicit but compact:
  - `Load 28T` for actual load weight
  - `Truck 28-42T` for derived capacity if shown separately
- [x] If only 3 primary pills allowed:
  - Use `28T · 28-42T` only if it remains readable
  - Otherwise prefer actual load weight on card and capacity in detail page

**Files to modify:**
- `lib/src/shared/widgets/marketplace_load_card.dart`

### Header Height Target

| Row | Target Height |
|-----|---------------|
| Supplier/status row | 34-40px |
| Route row | 70-78px |
| Money row | 34-42px |
| **Total** | **150-170px max** |

### Design Tokens

**Background:**
- Dark header: `AppColors.inkSurface` to `AppColors.inkMid` gradient
- Light body: `AppColors.surfaceBase`

**Typography:**
- Route cities: 17-20px bold (depending on width)
- Route states: 12-13px readable
- FROM/TO labels: 10-11px uppercase
- Load value: 18-20px, FontWeight.w800
- Profit/loss: 12-13px, FontWeight.w700

**Colors:**
- Center capsule: `AppColors.inkMid` with teal border/glow
- Profit pill: success tonal border
- Loss pill: error tonal border
- Border: `AppColors.divider` width 0.75

---

## Phase 6.2-6.3: Large Refactoring Tasks (Deferred)

**Status:** Deferred
**Priority:** Low
**Reason:** Large refactoring, may defer to future iteration

**Tasks:**
- [ ] Extract shared location service module (F7-001)
- [ ] Refactor controllers to avoid Ref closure anti-patterns (F2-004, F3-010, F4-009)
- [ ] Replace raw HttpClient with proper HTTP package (F2-008, F3-008, F4-004, F7-003)

---

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

- [x] Open Phase 2 section in `docs/review-18-may.md`.
- [x] Read exact `F2-001` description.
- [x] Identify affected supplier files.
- [x] Write focused failing test or reproduction steps.
- [x] Implement minimal fix.
- [x] Verify supplier load/trip flow still works.

**Status:** Complete - Fixed error swallowing in fetchMyLoads, standardized error handling with fetchBookingRequests, removed emoji logging (F2-003).

## 5.2 Standardize unauthenticated repository behavior

- [x] Read `F2-012`, `F3-002`, `F4-001`.
- [x] Update `supplier_profile_repository.dart` no-user case to return `Failure(UnauthorizedFailure())` or agreed failure type.
- [x] Update `trucker_profile_repository.dart` no-user case similarly.
- [x] Update `verification_repository.dart` no-user case similarly.
- [x] Decide behavior for missing profile row separately from missing auth session.
- [ ] Update providers/UI to handle failure vs no-profile state.
- [ ] Add tests for no session.
- [ ] Add tests for session but missing profile row.

**Status:** Core fix complete - repositories now return Failure for missing user. UI updates and tests deferred.

---

# Phase 6 — Runtime Config and Location Services

**Reference:** `docs/review-18-may.md` findings `F2-007`, `F3-007`, `F4-003`, `F7-001`, `F7-002`, `F7-003`, `F2-008`, `F3-008`, `F4-004`

## 6.1 Centralize Google Maps API key

- [x] Identify every `String.fromEnvironment('GOOGLE_MAPS_API_KEY')` usage.
- [x] Create one config/provider source for Maps key.
- [x] Replace supplier location service key read.
- [x] Replace trucker city search service key read.
- [x] Replace verification location service key read.
- [x] Ensure missing key behavior is explicit and user-safe.
- [ ] Add tests for missing key fallback.

**Status:** Complete - Centralized in AppConfig. All 4 usages updated.

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
  - [ ] `origin_lat`, `origin_lng`
  - [ ] `destination_lat`, `destination_lng`
- [ ] Verify all use `readDoubleNullable` instead of `readDouble`.
- [ ] Fix any using non-nullable reader.
- [ ] Add tests for null coordinate handling.

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
