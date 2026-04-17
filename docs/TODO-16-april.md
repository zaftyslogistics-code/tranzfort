# TODO-16-april - Back Navigation Improvements

## Git Fallback Information

### PRIMARY FALLBACK BRANCH (Most Complete Working Version)

**Branch Name:** `feature/codebase-refactoring`
**Commit:** `0587f23`
**Commit Message:** "Fix: Admin login mobile + GPS location district name + onboarding location capture"

### When to Use This Fallback

Use this branch if:
- The project breaks due to dependency conflicts
- Build fails with record_linux/speech_to_text errors
- Supabase configuration issues occur
- App shows "Supabase is not configured" error
- Any critical regression that makes the app unusable

### How to Restore

```bash
# 1. Stash any local changes
git stash

# 2. Checkout the fallback branch
git checkout feature/codebase-refactoring

# 3. Clean and rebuild
cd TranZfort
flutter clean
flutter pub get
flutter build apk --debug

# 4. Run on device
flutter run --debug -d <device_id>
```

### What This Branch Contains

**Dependency Fixes:**
- `flutter_dotenv: ^5.2.1` - Loads .env file automatically
- `dependency_overrides: record_linux: ^1.3.0` - Fixes record_linux compatibility
- `speech_to_text: ^7.0.0` - Fixes Kotlin compilation errors
- `record: ^5.2.1` - Compatible version
- `supabase_flutter: ^2.9.0` - Updated version

**Configuration:**
- `.env` file loading via flutter_dotenv
- Supabase config from environment variables
- No need for --dart-define flags
- Google Maps API key configured
- Firebase messaging configured

**Features:**
- Admin login mobile fixes
- GPS location district name capture
- Onboarding location capture improvements
- Public profiles system
- Reviews system
- Unified feedback RPC
- Verification flow improvements
- Codebase cleanup

### Why This Branch is the Fallback

1. **Latest Working State** - Contains all fixes from April 16, 2026
2. **Dependency Compatibility** - All dependency conflicts resolved
3. **Configuration Complete** - .env loading and Supabase configured
4. **Build Verified** - Successfully builds APK without errors
5. **Feature Complete** - All major features from Sprint 7 and Sprint 8

### Branch History

```
0587f23 (HEAD -> feature/codebase-refactoring, origin/feature/codebase-refactoring)
  Fix: Admin login mobile + GPS location district name + onboarding location capture
3bc5929
  feat: Public profiles, reviews system, and unified feedback RPC
4ab4c81
  feat: Complete verification flow improvements - wizard implementation, draft persistence, localization, typed location errors
912667a
  refactor: codebase cleanup - trucker screens, routing, verification, and shared widgets
b9a9c26
  Stabilize supplier, trucker, and admin verification flows
3cb2bb8
  Initial commit: TranZfort logistics platform
```

### Comparison with Master

**Master Branch (9622144):**
- "feat: complete Sprint 7 and Sprint 8 Phase 1"
- Missing dependency overrides
- No flutter_dotenv
- Build fails with record_linux errors
- Requires --dart-define flags

**feature/codebase-refactoring (0587f23):**
- All dependency fixes in place
- flutter_dotenv configured
- Builds successfully
- No --dart-define flags needed
- Additional features (admin login mobile, GPS location, onboarding)

### Verification Steps After Restore

1. **Check Build:**
   ```bash
   flutter build apk --debug
   ```
   Expected: APK builds successfully at `build/app/outputs/flutter-apk/app-debug.apk`

2. **Check Dependencies:**
   ```bash
   flutter pub get
   ```
   Expected: No errors, shows `record_linux 1.3.0 (overridden)`

3. **Check .env Loading:**
   - Verify `.env` file exists in `TranZfort/` directory
   - Contains SUPABASE_URL and SUPABASE_ANON_KEY

4. **Run on Device:**
   ```bash
   flutter run --debug -d <device_id>
   ```
   Expected: App launches without "Supabase is not configured" error

### Notes

- This branch is the most complete and stable version as of April 17, 2026
- All changes from failed back navigation attempts have been reverted
- No experimental features or incomplete work
- Safe to use as production fallback

---

## Navigation Architecture Review Plan

### Objective

Conduct a comprehensive review of the entire TranZfort user app to understand current navigation implementation, identify all navigation patterns, assess dependencies, and plan for implementing centralized route-based navigation architecture suitable for 5000+ users.

### Review Principles

1. **No Code Changes** - This is a review and planning phase only
2. **Complete Coverage** - Review every screen, widget, and navigation flow
3. **Risk Assessment** - Identify what might break with centralized navigation
4. **Dependency Mapping** - Understand all navigation dependencies
5. **Documentation** - Document findings thoroughly before any implementation

### Phase 1: Route Configuration Review

#### 1.1 GoRouter Configuration Audit

**File:** `lib/src/core/navigation/app_router.dart`

**What to Review:**
- All route definitions (paths, parameters, query params)
- Route hierarchy (parent-child relationships)
- Redirect rules
- Error handling routes
- Initial route configuration
- Deep link handling
- Route guards/middleware (if any)

**Questions to Answer:**
- How many routes exist?
- Which are top-level routes?
- Which are nested routes?
- Which are modal routes?
- What's the route hierarchy?
- How are deep links handled?
- Are there any custom route transitions?

**Expected Issues to Find:**
- Inconsistent route naming
- Missing parent-child relationships
- Unclear route hierarchy
- No route metadata (type, parent, behavior)
- Mixed navigation patterns in routes

**Dependencies to Identify:**
- Which screens use which routes
- Which routes depend on parameters
- Which routes have optional parameters
- Which routes are accessed from multiple places

---

#### 1.2 Route Type Classification

**Action:** Create a spreadsheet/table classifying all routes

**Classification Schema:**
```
Route Path | Type | Parent Route | Current Back Behavior | Target Back Behavior | Show Back Arrow? | Priority
```

**Route Types:**
- `topLevel` - Dashboard, messages, profile, settings
- `nested` - Load detail, trip detail, chat
- `modal` - Dialogs, bottom sheets
- `standalone` - Onboarding, splash, auth
- `subFlow` - Multi-step wizards (verification)

**Priority:**
- `P0` - Critical user flows (load booking, trip management)
- `P1` - Important flows (messaging, profile)
- `P2` - Secondary flows (settings, support)
- `P3` - Nice-to-have (public profiles, reviews)

**Expected Output:**
- Complete route classification table
- Identified inconsistencies in current behavior
- Priority list for migration

---

### Phase 2: Screen-Level Navigation Audit

#### 2.1 Shell Screens (Bottom Navigation)

**Files to Review:**
- `lib/src/features/shell/presentation/shell_dashboard_screen.dart`
- `lib/src/features/shell/presentation/shell_messages_screen.dart`
- `lib/src/features/shell/presentation/shell_profile_screen.dart`
- `lib/src/features/shell/presentation/shell_settings_screen.dart`
- `lib/src/features/shell/presentation/user_app_shell.dart`

**What to Review:**
- PopScope implementation (if any)
- AppBar configuration (leading, actions)
- Custom back button handlers
- Navigation to other shell screens
- Navigation to nested screens
- State management (providers used)
- Lifecycle methods

**Questions to Answer:**
- Do shell screens have PopScope?
- Do they have custom back handlers?
- How do they navigate between shell screens?
- How do they navigate to nested screens?
- What providers do they depend on?
- What happens on system back button?

**Expected Issues to Find:**
- Inconsistent PopScope usage
- Mixed navigation patterns (bottom nav vs back button)
- Custom back handlers that might conflict
- Provider dependencies that assume certain navigation state

**Dependencies to Identify:**
- Which providers are used
- Which providers depend on navigation state
- Which screens navigate to these shell screens
- What state is passed during navigation

---

#### 2.2 Detail Screens (Nested Routes)

**Files to Review:**

**Supplier Detail Screens:**
- `lib/src/features/supplier/presentation/supplier_load_detail_screen.dart`
- `lib/src/features/supplier/presentation/supplier_trip_detail_screen.dart`
- `lib/src/features/supplier/presentation/supplier_public_profile_screen.dart`

**Trucker Detail Screens:**
- `lib/src/features/trucker/presentation/trucker_load_detail_screen.dart`
- `lib/src/features/trucker/presentation/trucker_trip_detail_screen.dart`
- `lib/src/features/trucker/presentation/trucker_public_profile_screen.dart`
- `lib/src/features/trucker/presentation/trucker_route_preview_screen.dart`

**Communication Screens:**
- `lib/src/features/communication/presentation/chat_screen.dart`
- `lib/src/features/communication/presentation/message_list_screen.dart`

**What to Review:**
- PopScope implementation
- AppBar configuration (leading/back arrow)
- Navigation pattern (Navigator.pop vs context.go)
- Parameter passing (route params vs state)
- Data loading (when does it load data?)
- Error handling (what happens on error?)
- State cleanup (when is state disposed?)

**Questions to Answer:**
- How do they navigate back?
- Do they use Navigator.pop or context.go?
- What parameters do they receive?
- What state do they maintain?
- What happens on data load failure?
- Do they have custom back handlers?

**Expected Issues to Find:**
- Mixed Navigator.pop and context.go usage
- PopScope conflicts with AppBar back arrow
- State not cleaned up on navigation
- Data loading issues on back navigation
- Inconsistent error handling

**Dependencies to Identify:**
- Which repositories/providers they use
- Which screens navigate to them
- What data they pass/return
- What state they share with parent screens

---

#### 2.3 Form Screens (Multi-Step Flows)

**Files to Review:**
- `lib/src/features/verification/presentation/verification_wizard_screen.dart`
- `lib/src/features/auth/presentation/onboarding_profile_completion.dart`
- `lib/src/features/marketplace/presentation/post_load_screen.dart`
- `lib/src/features/support/presentation/raise_dispute_screen.dart`

**What to Review:**
- Multi-step navigation logic
- Draft persistence (if any)
- Back button behavior (discard draft? confirm?)
- State management across steps
- Validation logic
- Progress tracking
- Exit handling (can user exit mid-flow?)

**Questions to Answer:**
- How do users navigate between steps?
- What happens on back button (go to previous step or exit)?
- Is there draft persistence?
- Is there confirmation on exit?
- How is state shared between steps?
- Can users exit mid-flow?

**Expected Issues to Find:**
- Complex back button logic (step back vs exit)
- Draft persistence conflicts with navigation
- State management complexity
- Inconsistent exit behavior
- Missing confirmation dialogs

**Dependencies to Identify:**
- Draft storage mechanism
- State shared across steps
- Validation logic dependencies
- Parent screen expectations

---

#### 2.4 Modal Screens

**Files to Review:**
- All dialogs and bottom sheets
- Search for `showDialog`, `showModalBottomSheet`
- Custom modal widgets

**What to Review:**
- How modals are shown
- How modals are dismissed
- Back button behavior in modals
- Data passing to/from modals
- State management in modals

**Questions to Answer:**
- How are modals triggered?
- How are modals dismissed?
- What happens on back button in modal?
- Do modals return data?
- Do modals have their own navigation?

**Expected Issues to Find:**
- Inconsistent modal dismissal
- Back button closes app instead of modal
- Data not returned properly
- State leaks from modals

**Dependencies to Identify:**
- Which screens show which modals
- What data is passed to modals
- What data modals return
- How modals affect parent state

---

#### 2.5 Special Screens

**Files to Review:**
- `lib/src/features/auth/presentation/auth_screen.dart`
- `lib/src/features/auth/presentation/delete_account_screen.dart`
- `lib/src/features/notifications/presentation/notifications_screen.dart`
- Public profile screens
- Review screens

**What to Review:**
- Special navigation requirements
- Authentication flow navigation
- Account deletion flow
- Notification navigation (deep links)
- Public profile navigation
- Review submission flow

**Questions to Answer:**
- How does auth flow work?
- What happens after login/logout?
- How does account deletion work?
- How do notifications navigate?
- How do public profiles work?
- How are reviews submitted?

**Expected Issues to Find:**
- Auth navigation complexity
- Account deletion navigation issues
- Notification deep link issues
- Public profile navigation gaps
- Review submission navigation issues

**Dependencies to Identify:**
- Auth state dependencies
- Notification routing
- Deep link handlers
- Review submission flow

---

### Phase 3: Shared Components Review

#### 3.1 Scaffold Components

**Files to Review:**
- `lib/src/features/shell/presentation/shell_components.dart` (DetailPageScaffold, etc.)
- Any shared scaffold widgets

**What to Review:**
- How scaffolds handle navigation
- AppBar configuration in scaffolds
- Back arrow implementation
- PopScope in scaffolds
- Custom navigation logic

**Questions to Answer:**
- Do scaffolds have built-in navigation logic?
- How do scaffolds handle back button?
- Do scaffolds have back arrows?
- Can scaffolds be configured for navigation?

**Expected Issues to Find:**
- Scaffolds with hardcoded navigation
- Scaffolds with conflicting PopScope
- Scaffolds that assume certain navigation patterns

**Dependencies to Identify:**
- Which screens use which scaffolds
- What navigation behavior scaffolds provide
- How to make scaffolds navigation-agnostic

---

#### 3.2 Navigation Widgets

**Files to Review:**
- Search for custom navigation widgets
- Search for back button widgets
- Search for navigation bar widgets

**What to Review:**
- Custom navigation widgets
- Custom back button implementations
- Custom navigation bar implementations

**Questions to Answer:**
- Are there custom navigation widgets?
- How do they handle navigation?
- Can they be made to use central navigation?

**Expected Issues to Find:**
- Custom widgets with hardcoded navigation
- Widgets that can't be configured
- Widgets that bypass central navigation

**Dependencies to Identify:**
- Which screens use custom navigation widgets
- How to make widgets navigation-agnostic

---

### Phase 4: State Management Review

#### 4.1 Provider Dependencies on Navigation

**What to Review:**
- All providers that depend on navigation state
- Providers that trigger navigation
- Providers that listen to navigation changes

**Files to Review:**
- `lib/src/core/providers/` (all providers)
- Feature-specific providers

**Questions to Answer:**
- Which providers depend on navigation state?
- Which providers trigger navigation?
- Which providers listen to navigation changes?
- How do providers handle navigation changes?

**Expected Issues to Find:**
- Providers that assume certain navigation patterns
- Providers that break with centralized navigation
- Providers that need navigation state

**Dependencies to Identify:**
- Provider-navigation coupling
- State that depends on navigation
- Navigation that depends on state

---

#### 4.2 Riverpod Navigation Integration

**What to Review:**
- How Riverpod integrates with navigation
- Use of `ref.watch`, `ref.listen`, `ref.read` with navigation
- Provider scopes and navigation

**Questions to Answer:**
- How does Riverpod interact with GoRouter?
- Are there navigation-specific providers?
- How do providers handle route changes?

**Expected Issues to Find:**
- Providers tightly coupled to navigation
- Navigation logic in providers
- Scope issues with navigation

**Dependencies to Identify:**
- Provider-navigation integration points
- Scope requirements for navigation

---

### Phase 5: Deep Link & Notification Review

#### 5.1 Deep Link Handling

**Files to Review:**
- GoRouter configuration for deep links
- Deep link handlers
- Notification tap handlers

**What to Review:**
- How deep links are handled
- How notification taps navigate
- What state is passed via deep links
- Error handling for invalid deep links

**Questions to Answer:**
- How are deep links processed?
- How do notifications navigate?
- What happens on invalid deep links?
- What state is needed for deep links?

**Expected Issues to Find:**
- Deep links that bypass navigation policy
- Notification navigation issues
- Missing error handling
- State not available for deep links

**Dependencies to Identify:**
- Deep link sources
- Notification sources
- State requirements for deep links

---

#### 5.2 Firebase Messaging Integration

**Files to Review:**
- `lib/src/features/notifications/` (all files)
- Firebase messaging setup

**What to Review:**
- How notifications trigger navigation
- How notification data is passed
- Navigation from background vs foreground

**Questions to Answer:**
- How do notifications navigate?
- What data do notifications pass?
- Is navigation different for background/foreground?

**Expected Issues to Find:**
- Notification navigation bypasses policy
- Data not passed correctly
- Different behavior for background/foreground

**Dependencies to Identify:**
- Notification types
- Navigation targets from notifications
- Data requirements

---

### Phase 6: Risk Assessment

#### 6.1 Breaking Changes Analysis

**What to Identify:**
- Code that will break with centralized navigation
- Screens that can't use centralized navigation
- Features that depend on current navigation patterns
- Third-party integrations that depend on navigation

**Risk Categories:**
- **High Risk** - Core functionality will break
- **Medium Risk** - Secondary functionality will break
- **Low Risk** - Minor issues, easy to fix

**Expected High-Risk Areas:**
- Multi-step wizards with complex back logic
- Draft persistence flows
- Auth flow navigation
- Notification deep links
- Custom navigation widgets

**Expected Medium-Risk Areas:**
- Detail screens with custom back handlers
- Modal dialogs with custom dismissal
- Provider navigation triggers
- State-dependent navigation

**Expected Low-Risk Areas:**
- Simple detail screens
- Shell screens
- Standard modal dialogs

---

#### 6.2 Dependency Impact Analysis

**What to Map:**
- Screen-to-screen navigation dependencies
- Provider-to-navigation dependencies
- Widget-to-navigation dependencies
- External-to-navigation dependencies

**Impact Assessment:**
- Which screens will need refactoring
- Which providers will need refactoring
- Which widgets will need refactoring
- Which external integrations will need refactoring

**Migration Effort Estimation:**
- **Screens** - Count of screens needing changes
- **Providers** - Count of providers needing changes
- **Widgets** - Count of widgets needing changes
- **Tests** - Count of tests needing updates

---

### Phase 7: Documentation Plan

#### 7.1 Current State Documentation

**What to Document:**
- Complete route inventory
- Current navigation patterns
- Screen-by-screen navigation behavior
- Provider-navigation dependencies
- Known navigation issues
- Workarounds currently in place

**Documentation Format:**
- Route inventory table
- Navigation flow diagrams
- Screen navigation matrix
- Dependency diagrams
- Issue log

---

#### 7.2 Target State Documentation

**What to Document:**
- New route configuration schema
- Navigation policy rules
- Route classification table
- Centralized handler design
- Migration strategy
- Testing strategy

**Documentation Format:**
- Route config schema
- Navigation policy document
- Migration plan
- Testing plan
- Rollback plan

---

### Phase 8: Review Deliverables

#### 8.1 Route Classification Matrix

**Deliverable:** Complete table of all routes with:
- Route path
- Route type (topLevel, nested, modal, standalone, subFlow)
- Parent route
- Current back behavior
- Target back behavior
- Show back arrow?
- Priority (P0, P1, P2, P3)
- Risk level (High, Medium, Low)
- Estimated effort

---

#### 8.2 Screen Navigation Audit Report

**Deliverable:** Screen-by-screen report including:
- Screen name and file path
- Current navigation implementation
- PopScope usage
- AppBar configuration
- Navigation pattern (pop vs go)
- Provider dependencies
- Issues identified
- Required changes
- Risk level
- Estimated effort

---

#### 8.3 Dependency Map

**Deliverable:** Visual/text map showing:
- Screen-to-screen navigation dependencies
- Provider-to-navigation dependencies
- Widget-to-navigation dependencies
- External integration dependencies
- Circular dependencies (if any)

---

#### 8.4 Risk Assessment Report

**Deliverable:** Risk analysis including:
- High-risk areas with mitigation strategies
- Medium-risk areas with mitigation strategies
- Low-risk areas
- Breaking changes inventory
- Migration effort estimate
- Rollback strategy

---

#### 8.5 Implementation Plan

**Deliverable:** Phased implementation plan:
- Phase 1: Route configuration setup
- Phase 2: Centralized handler implementation
- Phase 3: Screen migration (by priority)
- Phase 4: Provider migration
- Phase 5: Testing
- Phase 6: Documentation
- Phase 7: Rollout

Each phase includes:
- Scope
- Tasks
- Dependencies
- Effort estimate
- Success criteria
- Rollback criteria

---

### Review Timeline Estimate

**Phase 1: Route Configuration Review** - 2-3 hours
**Phase 2: Screen-Level Navigation Audit** - 8-12 hours
**Phase 3: Shared Components Review** - 2-3 hours
**Phase 4: State Management Review** - 3-4 hours
**Phase 5: Deep Link & Notification Review** - 2-3 hours
**Phase 6: Risk Assessment** - 2-3 hours
**Phase 7: Documentation Plan** - 1-2 hours
**Phase 8: Review Deliverables** - 4-6 hours

**Total Estimated Time:** 24-36 hours

---

### Review Execution Strategy

#### Option A: Sequential Review
- Complete each phase before moving to next
- Pros: Thorough, less context switching
- Cons: Longer timeline

#### Option B: Parallel Review
- Review multiple phases simultaneously
- Pros: Faster
- Cons: More context switching, potential overlap

**Recommended:** Option A (Sequential) for thoroughness

---

### Review Notes & Log

**Date:** [To be filled during review]
**Reviewer:** [To be filled]
**Branch:** feature/codebase-refactoring
**Commit:** 0587f23

**Review Progress:**
- Phase 1: [ ] Complete
- Phase 2: [ ] Complete
- Phase 3: [ ] Complete
- Phase 4: [ ] Complete
- Phase 5: [ ] Complete
- Phase 6: [ ] Complete
- Phase 7: [ ] Complete
- Phase 8: [ ] Complete

**Issues Found:** [To be logged during review]
**Decisions Made:** [To be logged during review]
**Questions Raised:** [To be logged during review]

---

### Next Steps After Review

1. **Review findings with team**
2. **Get approval for implementation plan**
3. **Create detailed implementation tickets**
4. **Set up testing strategy**
5. **Begin Phase 1 implementation**
6. **Continuous testing during migration**
7. **Rollout with monitoring**
