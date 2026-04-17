# Navigation Architecture Review Findings - April 17, 2026

## Review Information

**Date:** April 17, 2026
**Reviewer:** Cascade AI
**Branch:** feature/codebase-refactoring
**Commit:** 0587f23
**Review Plan:** docs/TODO-16-april.md

## Review Progress

- Phase 1: Route Configuration Review - [x] Complete
- Phase 2: Screen-Level Navigation Audit - [ ] Complete
- Phase 3: Shared Components Review - [ ] Complete
- Phase 4: State Management Review - [ ] Complete
- Phase 5: Deep Link & Notification Review - [ ] Complete
- Phase 6: Risk Assessment - [ ] Complete
- Phase 7: Documentation Plan - [ ] Complete
- Phase 8: Review Deliverables - [ ] Complete

---

## Phase 1: Route Configuration Review

### 1.1 GoRouter Configuration Audit

**File:** `lib/src/core/navigation/app_router.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete

---

#### Route Inventory

**Total Routes:** 37 routes

**Route Classification:**

**Standalone Routes (Outside Shell):**
1. `/` (root) - Redirects to /splash
2. `/splash` - SplashScreen (standalone)
3. `/auth` - AuthEntryScreen (standalone)
4. `/auth/password` - EmailPasswordAuthScreen (standalone)
5. `/onboarding` - OnboardingGateScreen (standalone)
6. `/onboarding/role` - RoleSelectionScreen (standalone)
7. `/onboarding/profile` - ProfileCompletionScreen (standalone)
8. `/banned` - AccessRestrictedScreen (standalone)

**Shell Routes (Inside UserAppShell):**
9. `/supplier-dashboard` - SupplierDashboardScreen (topLevel)
10. `/dashboard` - Redirects to /trucker-dashboard
11. `/trucker-dashboard` - TruckerDashboardScreen (topLevel)
12. `/post-load` - PostLoadScreen (subFlow)
13. `/my-loads` - SupplierMyLoadsScreen (topLevel)
14. `/load-detail/:loadId` - SupplierLoadDetailScreen/TruckerLoadDetailScreen (nested)
15. `/route-preview` - TruckerRoutePreviewScreen (nested)
16. `/find-loads` - TruckerFindLoadsScreen (topLevel)
17. `/fleet` - TruckerFleetScreen (topLevel)
18. `/trips` - Redirects based on role
19. `/supplier-trips` - SupplierTripsScreen (topLevel)
20. `/trip-detail/:tripId` - SupplierTripDetailScreen/TruckerTripDetailScreen (nested)
21. `/messages` - MessagesScreen (topLevel)
22. `/account` - AccountScreen (topLevel)
23. `/notifications` - NotificationsScreen (topLevel)
24. `/profile` - ProfileScreen (topLevel)
25. `/verification` - Redirects based on role
26. `/supplier-verification` - VerificationScreen (topLevel)
27. `/trucker-verification` - VerificationScreen (topLevel)
28. `/settings` - SettingsScreen (topLevel)
29. `/support` - SupportScreen (topLevel)
30. `/create-support-ticket` - CreateSupportTicketScreen (modal)
31. `/report-issue` - ReportIssueScreen (modal)
32. `/delete-account` - DeleteAccountScreen (standalone)
33. `/raise-dispute/:tripId` - RaiseDisputeScreen (nested)
34. `/chat/:conversationId` - ChatScreen (nested)
35. `/profile/:userId` - _PublicProfileRouteScreen (nested)

---

#### Issues Found

**Issue 1: Mixed Route Types Without Clear Classification**
- **Severity:** Medium
- **Description:** Routes are not explicitly classified by type (topLevel, nested, modal, standalone, subFlow)
- **Impact:** Difficult to apply consistent navigation policy
- **Location:** All route definitions in app_router.dart
- **Recommendation:** Add route metadata enum to classify each route

**Issue 2: No Parent Route Metadata**
- **Severity:** Medium
- **Description:** Nested routes don't have explicit parent route information
- **Impact:** Hard to determine back navigation target
- **Location:** Routes like `/load-detail/:loadId`, `/trip-detail/:tripId`, `/chat/:conversationId`
- **Recommendation:** Add parentRoute field to route metadata

**Issue 3: Role-Based Route Duplication**
- **Severity:** Low
- **Description:** Separate routes for supplier and trucker (e.g., `/supplier-dashboard` vs `/trucker-dashboard`)
- **Impact:** More routes to maintain, potential confusion
- **Location:** Multiple route definitions
- **Recommendation:** Consider single route with role-based redirect in builder

**Issue 4: Complex Redirect Logic**
- **Severity:** High
- **Description:** Redirect logic is complex and spread across multiple places
- **Impact:** Hard to debug, difficult to predict navigation behavior
- **Location:** app_router_redirect.dart (143 lines of complex conditional logic)
- **Recommendation:** Simplify redirect logic, move to route-level redirects where possible

**Issue 5: No Route Metadata for Back Behavior**
- **Severity:** High
- **Description:** Routes have no metadata defining back button behavior
- **Impact:** No centralized way to control back navigation
- **Location:** All route definitions
- **Recommendation:** Add backAction field to route metadata (popToParent, goToDashboard, exitApp, etc.)

**Issue 6: Inconsistent Page Transitions**
- **Severity:** Low
- **Description:** Some routes use NoTransitionPage, others use default builder
- **Impact:** Inconsistent UX
- **Location:** Mixed usage of pageBuilder vs builder
- **Recommendation:** Standardize page transitions per route type

**Issue 7: No Route Guards/Middleware**
- **Severity:** Medium
- **Description:** No explicit route guards for permission checks
- **Impact:** All permission logic in redirect handler
- **Location:** app_router_redirect.dart
- **Recommendation:** Consider adding route guards for cleaner separation

**Issue 8: Dynamic Screen Selection in Route Builder**
- **Severity:** Medium
- **Description:** Some routes dynamically select screen based on auth state (e.g., load-detail, trip-detail)
- **Impact:** Navigation logic mixed with route definition
- **Location:** Lines 128-137, 186-195 in app_router.dart
- **Recommendation:** Move to separate routes with role-based redirects

---

#### Dependencies Identified

**Route-to-Screen Dependencies:**
- 37 routes map to 35+ screens
- Some routes map to multiple screens based on role (load-detail, trip-detail)
- _PublicProfileRouteScreen is a router-level widget that dispatches to supplier/trucker screens

**Provider Dependencies in Routes:**
- currentAuthStateProvider - Used in multiple route builders and redirects
- publicProfileProvider - Used in _PublicProfileRouteScreen
- mapsLauncherServiceProvider - Used in route-preview route

**Parameter Dependencies:**
- loadId - Required for load-detail route
- tripId - Required for trip-detail and raise-dispute routes
- conversationId - Required for chat route
- userId - Required for public-profile route
- state.extra - Used for route-preview, support, report-issue routes

**Query Parameter Dependencies:**
- returnTo - Used in fleet route (returnTo=verification)

---

#### Route Hierarchy Analysis

**Top-Level Routes (Bottom Navigation):**
- /supplier-dashboard
- /trucker-dashboard
- /my-loads
- /find-loads
- /fleet
- /supplier-trips
- /trips
- /messages
- /account
- /notifications
- /profile
- /supplier-verification
- /trucker-verification
- /settings
- /support

**Nested Routes (Have Parent):**
- /load-detail/:loadId - Parent: /my-loads (supplier) or /find-loads (trucker)
- /trip-detail/:tripId - Parent: /supplier-trips (supplier) or /trips (trucker)
- /chat/:conversationId - Parent: /messages
- /route-preview - Parent: /find-loads
- /raise-dispute/:tripId - Parent: /trip-detail
- /profile/:userId - Parent: Could be any screen (deep link)

**Modal Routes:**
- /create-support-ticket
- /report-issue

**Standalone Routes:**
- /splash
- /auth
- /auth/password
- /onboarding
- /onboarding/role
- /onboarding/profile
- /banned
- /delete-account
- /post-load (subFlow)

**SubFlow Routes:**
- /post-load (multi-step form)
- /onboarding (multi-step wizard)

---

#### Deep Link Handling

**Deep Link Routes:**
- /profile/:userId - Public profile deep link
- All routes are potentially deep-linkable via GoRouter

**Deep Link Issues:**
- No validation of deep link parameters
- No error handling for invalid deep link data
- _PublicProfileRouteScreen handles some errors but not all

---

#### Current Back Behavior (Inferred)

**Top-Level Routes:**
- Likely use system back button with "Press back again to exit" (if implemented)
- No explicit back behavior defined

**Nested Routes:**
- Likely use Navigator.pop() (standard Flutter behavior)
- No explicit parent navigation defined

**Modal Routes:**
- Should dismiss on back button
- No explicit dismissal behavior defined

**Standalone Routes:**
- Auth routes likely redirect on back
- Onboarding routes likely block back or redirect

---

#### Questions Raised

1. **Why are there separate supplier/trucker routes instead of role-based routing?**
   - Design decision or historical artifact?
   - Impact on maintenance complexity

2. **Why is redirect logic so complex?**
   - Can it be simplified?
   - Should some redirects be route-level instead of global?

3. **What is the expected back behavior for each route type?**
   - Not documented anywhere
   - Need to define before implementing centralized navigation

4. **Why does load-detail route dynamically select screen based on role?**
   - Could be separate routes with role-based redirect
   - Current approach mixes navigation logic with route definition

5. **Are there any custom route transitions?**
   - NoTransitionPage used for some routes
   - Inconsistent usage pattern

---

#### Risk Assessment for Centralized Navigation

**High Risk:**
- Complex redirect logic - Changes could break auth flow
- Dynamic screen selection in route builders - Hard to centralize
- No route metadata - Will require significant refactoring

**Medium Risk:**
- Role-based route duplication - May need restructuring
- Provider dependencies in routes - Need to preserve during migration
- Deep link handling - Must ensure continues to work

**Low Risk:**
- Route classification - Can add metadata without breaking
- Parent route relationships - Can add metadata without breaking
- Page transitions - Can standardize without breaking

---

#### 1.2 Route Type Classification

**Review Date:** April 17, 2026
**Review Status:** Complete

---

**Route Classification Table:**

| Route Path | Type | Parent Route | Current Back Behavior | Target Back Behavior | Show Back Arrow? | Priority | Risk Level |
|------------|------|--------------|----------------------|---------------------|-----------------|----------|------------|
| / | standalone | N/A | Redirect to /splash | Redirect to /splash | No | P3 | Low |
| /splash | standalone | N/A | Unknown (likely none) | None | No | P3 | Low |
| /auth | standalone | N/A | Unknown (likely redirect) | Redirect to dashboard | No | P0 | High |
| /auth/password | standalone | N/A | Unknown (likely redirect) | Redirect to dashboard | No | P0 | High |
| /onboarding | subFlow | N/A | Unknown (complex) | Step back or confirm exit | No | P0 | High |
| /onboarding/role | subFlow | /onboarding | Unknown (step back) | Step back to onboarding | Yes | P0 | High |
| /onboarding/profile | subFlow | /onboarding/role | Unknown (step back) | Step back to role | Yes | P0 | High |
| /banned | standalone | N/A | Unknown (likely none) | None | No | P2 | Low |
| /supplier-dashboard | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P0 | High |
| /dashboard | topLevel | N/A | Redirects to trucker-dashboard | Redirect to role-specific dashboard | No | P3 | Low |
| /trucker-dashboard | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P0 | High |
| /post-load | subFlow | N/A | Unknown (complex) | Confirm discard draft | Yes | P0 | High |
| /my-loads | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P0 | High |
| /load-detail/:loadId | nested | /my-loads (supplier) or /find-loads (trucker) | Navigator.pop() | Navigator.pop() | Yes | P0 | Medium |
| /route-preview | nested | /find-loads | Navigator.pop() | Navigator.pop() | Yes | P1 | Low |
| /find-loads | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P0 | High |
| /fleet | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P1 | Low |
| /trips | topLevel | N/A | Redirects based on role | Redirect to role-specific trips | No | P3 | Low |
| /supplier-trips | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P0 | High |
| /trip-detail/:tripId | nested | /supplier-trips (supplier) or /trips (trucker) | Navigator.pop() | Navigator.pop() | Yes | P0 | Medium |
| /messages | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P1 | Medium |
| /account | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P2 | Low |
| /notifications | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P2 | Low |
| /profile | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P2 | Low |
| /verification | topLevel | N/A | Redirects based on role | Redirect to role-specific verification | No | P0 | High |
| /supplier-verification | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P0 | High |
| /trucker-verification | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P0 | High |
| /settings | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P2 | Low |
| /support | topLevel | N/A | System back (exit app?) | Show "Press back again to exit" | No | P2 | Low |
| /create-support-ticket | modal | /support | Dismiss modal | Dismiss modal | Yes | P2 | Low |
| /report-issue | modal | Various | Dismiss modal | Dismiss modal | Yes | P2 | Low |
| /delete-account | standalone | N/A | Unknown (likely none) | None | No | P2 | Medium |
| /raise-dispute/:tripId | nested | /trip-detail | Navigator.pop() | Navigator.pop() | Yes | P1 | Medium |
| /chat/:conversationId | nested | /messages | Navigator.pop() | Navigator.pop() | Yes | P1 | Medium |
| /profile/:userId | nested | Deep link (no parent) | Navigator.pop() | Go to dashboard | Yes | P2 | Low |

---

**Inconsistencies Identified:**

1. **Inconsistent Top-Level Back Behavior**
   - Some top-level routes may have "Press back again to exit" (unknown which)
   - Need to verify actual implementation in screens

2. **Nested Route Parent Ambiguity**
   - load-detail has different parents based on role (my-loads vs find-loads)
   - trip-detail has different parents based on role (supplier-trips vs trips)
   - Need to determine parent dynamically based on navigation context

3. **SubFlow Back Behavior Undefined**
   - onboarding flow has complex back behavior (step back vs exit)
   - post-load may have draft persistence
   - Need to define clear back behavior for multi-step flows

4. **Public Profile Deep Link Parent**
   - /profile/:userId has no clear parent (deep link from anywhere)
   - Should back go to dashboard or previous screen?
   - Need to define policy for deep link back behavior

---

**Priority Classification Summary:**

**P0 (Critical User Flows):**
- Auth routes (auth, auth-password)
- Onboarding routes (onboarding, onboarding-role, onboarding-profile)
- Dashboard routes (supplier-dashboard, trucker-dashboard)
- Load/trip management (my-loads, find-loads, supplier-trips)
- Verification routes (supplier-verification, trucker-verification)
- Detail routes (load-detail, trip-detail)
- Post-load (multi-step form)

**P1 (Important Flows):**
- Messages
- Chat
- Fleet
- Raise dispute
- Route preview

**P2 (Secondary Flows):**
- Account
- Notifications
- Profile
- Settings
- Support
- Create support ticket
- Report issue
- Delete account
- Public profile

**P3 (Nice-to-Have):**
- Splash
- Banned
- Generic dashboard redirect
- Generic trips redirect

---

## Phase 2: Screen-Level Navigation Audit

### 2.1 Shell Screens (Bottom Navigation)

**Files to Review:**
- `lib/src/features/shell/presentation/shell_dashboard_screen.dart`
- `lib/src/features/shell/presentation/shell_messages_screen.dart`
- `lib/src/features/shell/presentation/shell_profile_screen.dart`
- `lib/src/features/shell/presentation/shell_settings_screen.dart`
- `lib/src/features/shell/presentation/user_app_shell.dart`

**Review Status:** In Progress

---

#### 2.1.1 user_app_shell.dart

**File:** `lib/src/features/shell/presentation/user_app_shell.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE
- **Finding:** No PopScope widget in the shell
- **Impact:** System back button uses Flutter's default behavior
- **Risk:** No "Press back again to exit" protection on top-level routes

**AppBar Configuration:**
- **Status:** Conditional AppBar based on topLevel check (line 40-71)
- **Finding:** AppBar only shown when route is a top-level tab
- **Leading Widget:** None (no back arrow)
- **Actions:** Notifications icon, TTS button, Language toggle, Profile avatar (opens drawer)
- **Impact:** No visible back arrow on top-level routes (as expected)
- **Risk:** None - this is correct for top-level routes

**Custom Back Button Handler:**
- **Status:** NONE
- **Finding:** No custom back button handler
- **Impact:** System back button uses Flutter's default behavior
- **Risk:** On top-level routes, back button may close app without confirmation

**Navigation Pattern:**
- **Bottom Nav:** Uses `context.go(tabs[index].route)` (line 85)
- **Drawer Navigation:** Uses `Navigator.pop()` then `context.go(route)` (lines 342-345)
- **Sign Out:** Uses `Navigator.pop()` if canPop, then `router.go(authPath)` (lines 363-369)
- **Pattern:** Consistent use of context.go() for route changes

**State Management:**
- **Providers Used:**
  - currentProfileProvider - For avatar display
  - currentAuthStateProvider - For auth state
  - shellUnreadNotificationCountProvider - For notification badge
- **Navigation Dependencies:** Providers watch auth state but don't trigger navigation
- **Impact:** No provider-driven navigation in shell

**Lifecycle Methods:**
- **Status:** No special lifecycle handling
- **Finding:** Standard ConsumerWidget pattern
- **Impact:** No navigation state cleanup on dispose

---

#### Issues Found

**Issue 1: No "Press Back Again to Exit" Protection**
- **Severity:** High
- **Description:** No PopScope with "Press back again to exit" toast on top-level routes
- **Impact:** Users can accidentally close the app by pressing back button
- **Location:** Entire user_app_shell.dart
- **Current Behavior:** System back button closes app immediately on top-level routes
- **Recommendation:** Add PopScope with canPop: false and double-press logic on top-level routes

**Issue 2: No Back Button Handling on Top-Level Routes**
- **Severity:** High
- **Description:** System back button has no special handling on dashboard, messages, etc.
- **Impact:** Inconsistent with professional app standards
- **Location:** user_app_shell.dart
- **Recommendation:** Implement centralized back handler for top-level routes

**Issue 3: Drawer Navigation Uses Mixed Pattern**
- **Severity:** Low
- **Description:** Drawer uses Navigator.pop() then context.go() (lines 342-345)
- **Impact:** Could cause issues if navigation stack is not as expected
- **Location:** UserAppDrawerContent._go() method
- **Recommendation:** Consider using context.go() directly (drawer closes automatically)

**Issue 4: Sign Out Navigation Has Conditional Pop**
- **Severity:** Medium
- **Description:** Sign out uses Navigator.pop() if canPop, then router.go() (lines 363-369)
- **Impact:** Could leave unexpected screens in stack
- **Location:** UserAppDrawerContent._signOut() method
- **Recommendation:** Use router.go() directly, let GoRouter handle stack

---

#### Dependencies Identified

**Provider Dependencies:**
- currentProfileProvider - Read for avatar display
- currentAuthStateProvider - Read for auth state and avatar
- shellUnreadNotificationCountProvider - Watch for notification badge

**Navigation Dependencies:**
- GoRouter - Used for all navigation (context.go())
- Navigator - Used for drawer close and sign out

**State Dependencies:**
- currentLocation parameter - Determines current tab
- role parameter - Determines which tabs to show
- Associated routes in _ShellTab - Determines tab selection for nested routes

---

#### Current Back Behavior

**Top-Level Routes (Dashboard, Messages, etc.):**
- **System Back Button:** Closes app immediately (Flutter default)
- **No Confirmation:** No "Press back again to exit" toast
- **No Visible Back Arrow:** Correct (AppBar has no leading widget)

**Nested Routes (Load Detail, Chat, etc.):**
- **System Back Button:** Navigator.pop() (Flutter default)
- **Behavior:** Returns to previous screen in navigation stack
- **AppBar:** Shown by shell (topLevel = false)

**Drawer Navigation:**
- **Drawer Close:** Navigator.pop()
- **Route Change:** context.go()
- **Pattern:** Two-step navigation

---

#### Questions Raised

1. **Why is there no "Press back again to exit" protection?**
   - Was this intentionally omitted?
   - Should it be added for professional app standards?

2. **Why does drawer use Navigator.pop() before context.go()?**
   - Is this necessary or can context.go() handle drawer close?
   - Could this cause navigation stack issues?

3. **Why does sign out check Navigator.canPop()?**
   - What scenarios require this check?
   - Could router.go() handle this automatically?

4. **Are there any edge cases where associatedRoutes logic fails?**
   - What if a route matches multiple tabs?
   - What if a route doesn't match any tab?

---

#### Risk Assessment for Centralized Navigation

**High Risk:**
- Adding PopScope to shell - Could break existing navigation flows
- Changing drawer navigation pattern - Could break drawer functionality
- Changing sign out navigation - Could break auth flow

**Medium Risk:**
- Adding "Press back again to exit" - Could conflict with existing behavior
- Modifying associatedRoutes logic - Could break tab selection

**Low Risk:**
- Adding back arrow to nested routes (handled by shell)
- Standardizing navigation pattern - Should improve consistency

---

#### Recommendations

1. **Add PopScope to user_app_shell.dart**
   - Implement only on top-level routes (topLevel = true)
   - Add "Press back again to exit" toast
   - Use 2-second timeout for double-press

2. **Simplify Drawer Navigation**
   - Remove Navigator.pop() from _go() method
   - Use context.go() directly (drawer closes automatically)
   - Test to ensure drawer closes properly

3. **Simplify Sign Out Navigation**
   - Remove Navigator.canPop() check
   - Use router.go() directly
   - Let GoRouter handle navigation stack

4. **Document associatedRoutes Logic**
   - Add comments explaining the matching logic
   - Document edge cases
   - Consider moving to separate utility class

---

#### 2.1.2 shell_messages_screen.dart

**File:** `lib/src/features/shell/presentation/shell_messages_screen.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE
- **Finding:** No PopScope widget
- **Impact:** System back button uses Flutter's default behavior

**AppBar Configuration:**
- **Status:** Uses DetailPageScaffold (from shell_components.dart)
- **Finding:** DetailPageScaffold has AppBar with NO leading widget (no back arrow)
- **Actions:** TTS button, Language toggle
- **Impact:** No visible back arrow (correct for top-level route)

**Custom Back Button Handler:**
- **Status:** NONE
- **Finding:** No custom back button handler
- **Impact:** System back button uses Flutter's default behavior

**Navigation Pattern:**
- **Empty State Action:** Uses `context.go()` to navigate to my-loads or find-loads (line 94)
- **Chat Navigation:** Uses `context.go()` to navigate to chat (line 215, 336)
- **Public Profile:** Uses `context.push()` for public profile (line 229, 343)
- **Pattern:** Consistent use of context.go() for navigation

**State Management:**
- **Providers Used:**
  - currentAuthStateProvider - For auth state
  - inboxProvider - For conversation list
- **Navigation Dependencies:** None

**Lifecycle Methods:**
- **Status:** ConsumerStatefulWidget with local state (_expandedLoadIds)
- **Finding:** No navigation state cleanup on dispose

---

#### Issues Found

**Issue 1: No Back Button Handling**
- **Severity:** Medium (inherits from shell)
- **Description:** No PopScope or custom back handler
- **Impact:** System back button closes app immediately
- **Location:** Entire shell_messages_screen.dart
- **Recommendation:** Rely on shell-level PopScope implementation

**Issue 2: Mixed Navigation Pattern**
- **Severity:** Low
- **Description:** Uses context.push() for public profile (line 229, 343)
- **Impact:** Inconsistent with rest of app (mostly context.go())
- **Location:** Avatar onTap handlers
- **Recommendation:** Consider using context.go() for consistency

---

#### Dependencies Identified

**Provider Dependencies:**
- currentAuthStateProvider - Read for auth state
- inboxProvider - Watch for conversation list

**Navigation Dependencies:**
- GoRouter - Used for all navigation
- Navigator - None

---

#### Current Back Behavior

- **System Back Button:** Closes app immediately (Flutter default)
- **No Confirmation:** No "Press back again to exit" toast
- **No Visible Back Arrow:** Correct (DetailPageScaffold has no leading widget)

---

#### 2.1.3 shell_profile_screen.dart

**File:** `lib/src/features/shell/presentation/shell_profile_screen.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE
- **Finding:** No PopScope widget
- **Impact:** System back button uses Flutter's default behavior

**AppBar Configuration:**
- **Status:** Uses DetailPageScaffold (from shell_components.dart)
- **Finding:** DetailPageScaffold has AppBar with NO leading widget (no back arrow)
- **Actions:** TTS button, Language toggle
- **Impact:** No visible back arrow (correct for top-level route)

**Custom Back Button Handler:**
- **Status:** NONE
- **Finding:** No custom back button handler
- **Impact:** System back button uses Flutter's default behavior

**Navigation Pattern:**
- **Support Navigation:** Uses `context.go()` to navigate to support (line 85, 161, 176, 192, 206)
- **Fleet Navigation:** Uses `context.go()` to navigate to fleet (line 119)
- **Delete Account:** Uses `context.go()` to navigate to delete-account (line 126)
- **Pattern:** Consistent use of context.go() for navigation

**State Management:**
- **Providers Used:**
  - currentAuthStateProvider - For auth state
  - currentProfileProvider - For profile data
  - appLocaleProvider - For language
  - contextualTtsServiceProvider - For TTS
- **Navigation Dependencies:** None

**Lifecycle Methods:**
- **Status:** ConsumerWidget
- **Finding:** No navigation state cleanup on dispose

---

#### Issues Found

**Issue 1: No Back Button Handling**
- **Severity:** Medium (inherits from shell)
- **Description:** No PopScope or custom back handler
- **Impact:** System back button closes app immediately
- **Location:** Entire shell_profile_screen.dart
- **Recommendation:** Rely on shell-level PopScope implementation

---

#### Dependencies Identified

**Provider Dependencies:**
- currentAuthStateProvider - Read for auth state
- currentProfileProvider - Watch for profile data
- appLocaleProvider - Watch for language
- contextualTtsServiceProvider - Read for TTS

**Navigation Dependencies:**
- GoRouter - Used for all navigation
- Navigator - None

---

#### Current Back Behavior

- **System Back Button:** Closes app immediately (Flutter default)
- **No Confirmation:** No "Press back again to exit" toast
- **No Visible Back Arrow:** Correct (DetailPageScaffold has no leading widget)

---

#### 2.1.4 shell_settings_screen.dart

**File:** `lib/src/features/shell/presentation/shell_settings_screen.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE
- **Finding:** No PopScope widget
- **Impact:** System back button uses Flutter's default behavior

**AppBar Configuration:**
- **Status:** Uses DetailPageScaffold (from shell_components.dart)
- **Finding:** DetailPageScaffold has AppBar with NO leading widget (no back arrow)
- **Actions:** TTS button, Language toggle
- **Impact:** No visible back arrow (correct for top-level route)

**Custom Back Button Handler:**
- **Status:** NONE
- **Finding:** No custom back button handler
- **Impact:** System back button uses Flutter's default behavior

**Navigation Pattern:**
- **Profile Navigation:** Uses `context.go()` to navigate to profile (line 120)
- **Notifications Navigation:** Uses `context.go()` to navigate to notifications (line 125)
- **Support Navigation:** Uses `context.go()` to navigate to support (line 130)
- **Delete Account:** Uses `context.go()` to navigate to delete-account (line 135)
- **Pattern:** Consistent use of context.go() for navigation

**State Management:**
- **Providers Used:**
  - currentProfileProvider - For profile data
  - appLocaleProvider - For language
  - contextualTtsServiceProvider - For TTS
  - pushPermissionSnapshotProvider - For push notification status
  - pushRuntimeIssuesProvider - For push runtime issues
- **Navigation Dependencies:** None

**Lifecycle Methods:**
- **Status:** ConsumerWidget
- **Finding:** No navigation state cleanup on dispose

---

#### Issues Found

**Issue 1: No Back Button Handling**
- **Severity:** Medium (inherits from shell)
- **Description:** No PopScope or custom back handler
- **Impact:** System back button closes app immediately
- **Location:** Entire shell_settings_screen.dart
- **Recommendation:** Rely on shell-level PopScope implementation

---

#### Dependencies Identified

**Provider Dependencies:**
- currentProfileProvider - Watch for profile data
- appLocaleProvider - Watch for language
- contextualTtsServiceProvider - Read for TTS
- pushPermissionSnapshotProvider - Watch for push notification status
- pushRuntimeIssuesProvider - Watch for push runtime issues

**Navigation Dependencies:**
- GoRouter - Used for all navigation
- Navigator - None

---

#### Current Back Behavior

- **System Back Button:** Closes app immediately (Flutter default)
- **No Confirmation:** No "Press back again to exit" toast
- **No Visible Back Arrow:** Correct (DetailPageScaffold has no leading widget)

---

#### 2.1.5 shell_components.dart (DetailPageScaffold)

**File:** `lib/src/features/shell/presentation/shell_components.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE
- **Finding:** No PopScope widget in DetailPageScaffold
- **Impact:** Screens using DetailPageScaffold have no back button handling

**AppBar Configuration:**
- **Status:** DetailPageScaffold has AppBar (lines 27-33)
- **Finding:** AppBar has NO leading widget (no back arrow)
- **Actions:** TTS button, Language toggle
- **Impact:** No visible back arrow
- **Used By:** shell_profile_screen, shell_settings_screen

**Custom Back Button Handler:**
- **Status:** NONE
- **Finding:** No custom back button handler
- **Impact:** System back button uses Flutter's default behavior

**Navigation Pattern:**
- **Status:** No navigation logic in DetailPageScaffold
- **Finding:** Pure UI component, no navigation
- **Impact:** Navigation handled by parent screens

---

#### Issues Found

**Issue 1: No Back Arrow in AppBar**
- **Severity:** Low
- **Description:** DetailPageScaffold has no leading widget in AppBar
- **Impact:** No visible back arrow (may be correct for top-level routes, but used by profile/settings which are also top-level)
- **Location:** DetailPageScaffold build method (lines 27-33)
- **Recommendation:** This is correct for top-level routes, no change needed

**Issue 2: No PopScope in DetailPageScaffold**
- **Severity:** Low
- **Description:** No PopScope widget
- **Impact:** Screens using DetailPageScaffold have no back button handling
- **Location:** DetailPageScaffold
- **Recommendation:** Keep PopScope at shell level, not in DetailPageScaffold

---

#### Dependencies Identified

**Navigation Dependencies:**
- None - Pure UI component

---

#### Current Back Behavior

- **System Back Button:** Uses Flutter's default behavior
- **No Visible Back Arrow:** Correct for top-level routes

---

#### Shell Screens Summary

**Common Pattern:**
- All shell screens (messages, profile, settings) use DetailPageScaffold
- DetailPageScaffold has AppBar with NO leading widget
- No PopScope in any shell screen
- No custom back button handlers
- All use context.go() for navigation
- System back button closes app immediately (Flutter default)

**Key Finding:**
- Shell screens rely on user_app_shell.dart for back button handling
- user_app_shell.dart has NO PopScope implementation
- Therefore, NO back button protection on ANY shell screen

**Risk Assessment:**
- **High Risk:** Adding PopScope to shell screens individually could break navigation
- **Recommended:** Add PopScope at user_app_shell.dart level only

---

### 2.2 Detail Screens (Nested Routes)

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

**Review Status:** In Progress

---

#### 2.2.1 supplier_trip_detail_screen.dart

**File:** `lib/src/features/supplier/presentation/supplier_trip_detail_screen.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete (partial - first 100 lines)

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE (in first 100 lines)
- **Finding:** No PopScope widget
- **Impact:** System back button uses Flutter's default behavior (Navigator.pop())

**AppBar Configuration:**
- **Status:** Uses DetailPageScaffold (from shell_components.dart)
- **Finding:** DetailPageScaffold has AppBar with NO leading widget (no back arrow)
- **Actions:** TTS button, Language toggle
- **Impact:** No visible back arrow on detail screen

**Custom Back Button Handler:**
- **Status:** NONE (in first 100 lines)
- **Finding:** No custom back button handler
- **Impact:** System back button uses Navigator.pop() (Flutter default for nested routes)

**Navigation Pattern:**
- **Empty State Action:** Uses `context.go()` to navigate to supplier-trips (line 47)
- **Pattern:** Uses context.go() for navigation

**State Management:**
- **Providers Used:**
  - supplierTripDetailProvider - For trip detail data
- **Navigation Dependencies:** None

---

#### Issues Found

**Issue 1: No Visible Back Arrow**
- **Severity:** Medium
- **Description:** DetailPageScaffold has no leading widget (no back arrow)
- **Impact:** Users cannot see back button, must use system back button
- **Location:** DetailPageScaffold (shell_components.dart)
- **Recommendation:** Add leading widget with back arrow to DetailPageScaffold for nested routes

**Issue 2: No PopScope**
- **Severity:** Low
- **Description:** No PopScope widget
- **Impact:** System back button uses Navigator.pop() (correct for nested routes)
- **Location:** supplier_trip_detail_screen.dart
- **Recommendation:** No change needed - Navigator.pop() is correct for nested routes

---

#### Current Back Behavior

- **System Back Button:** Navigator.pop() (Flutter default for nested routes)
- **Behavior:** Returns to previous screen (supplier-trips)
- **No Visible Back Arrow:** Issue - should have back arrow

---

#### 2.2.2 trucker_load_detail_screen.dart

**File:** `lib/src/features/trucker/presentation/trucker_load_detail_screen.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete (partial - first 100 lines)

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE (in first 100 lines)
- **Finding:** No PopScope widget
- **Impact:** System back button uses Flutter's default behavior (Navigator.pop())

**AppBar Configuration:**
- **Status:** Uses DetailPageScaffold (from shell_components.dart)
- **Finding:** DetailPageScaffold has AppBar with NO leading widget (no back arrow)
- **Actions:** TTS button, Language toggle
- **Impact:** No visible back arrow on detail screen

**Custom Back Button Handler:**
- **Status:** NONE (in first 100 lines)
- **Finding:** No custom back button handler
- **Impact:** System back button uses Navigator.pop() (Flutter default for nested routes)

**Navigation Pattern:**
- **Status:** No navigation in first 100 lines
- **Finding:** Uses DetailPageScaffold
- **Pattern:** Likely uses context.go() for navigation (in other parts)

**State Management:**
- **Providers Used:**
  - truckerLoadDetailProvider - For load detail data
  - truckerProfileProvider - For profile data
  - dieselPriceMapProvider - For diesel prices
  - tripCostingServiceProvider - For trip costing
  - truckerLoadShareServiceProvider - For load sharing
- **Navigation Dependencies:** None

---

#### Issues Found

**Issue 1: No Visible Back Arrow**
- **Severity:** Medium
- **Description:** DetailPageScaffold has no leading widget (no back arrow)
- **Impact:** Users cannot see back button, must use system back button
- **Location:** DetailPageScaffold (shell_components.dart)
- **Recommendation:** Add leading widget with back arrow to DetailPageScaffold for nested routes

**Issue 2: No PopScope**
- **Severity:** Low
- **Description:** No PopScope widget
- **Impact:** System back button uses Navigator.pop() (correct for nested routes)
- **Location:** trucker_load_detail_screen.dart
- **Recommendation:** No change needed - Navigator.pop() is correct for nested routes

---

#### Current Back Behavior

- **System Back Button:** Navigator.pop() (Flutter default for nested routes)
- **Behavior:** Returns to previous screen (find-loads)
- **No Visible Back Arrow:** Issue - should have back arrow

---

#### 2.2.3 trucker_trip_detail_screen.dart

**File:** `lib/src/features/trucker/presentation/trucker_trip_detail_screen.dart`

**Review Date:** April 17, 2026
**Review Status:** Complete (full file - 73 lines)

---

#### Navigation Implementation Analysis

**PopScope Implementation:**
- **Status:** NONE
- **Finding:** No PopScope widget
- **Impact:** System back button uses Flutter's default behavior (Navigator.pop())

**AppBar Configuration:**
- **Status:** Uses DetailPageScaffold (from shell_components.dart)
- **Finding:** DetailPageScaffold has AppBar with NO leading widget (no back arrow)
- **Actions:** TTS button, Language toggle
- **Impact:** No visible back arrow on detail screen

**Custom Back Button Handler:**
- **Status:** NONE
- **Finding:** No custom back button handler
- **Impact:** System back button uses Navigator.pop() (Flutter default for nested routes)

**Navigation Pattern:**
- **Empty State Action:** Uses `context.go()` to navigate to trips (line 57)
- **Pattern:** Uses context.go() for navigation

**State Management:**
- **Providers Used:**
  - truckerTripDetailProvider - For trip detail data
- **Navigation Dependencies:** None

---

#### Issues Found

**Issue 1: No Visible Back Arrow**
- **Severity:** Medium
- **Description:** DetailPageScaffold has no leading widget (no back arrow)
- **Impact:** Users cannot see back button, must use system back button
- **Location:** DetailPageScaffold (shell_components.dart)
- **Recommendation:** Add leading widget with back arrow to DetailPageScaffold for nested routes

**Issue 2: No PopScope**
- **Severity:** Low
- **Description:** No PopScope widget
- **Impact:** System back button uses Navigator.pop() (correct for nested routes)
- **Location:** trucker_trip_detail_screen.dart
- **Recommendation:** No change needed - Navigator.pop() is correct for nested routes

---

#### Current Back Behavior

- **System Back Button:** Navigator.pop() (Flutter default for nested routes)
- **Behavior:** Returns to previous screen (trips)
- **No Visible Back Arrow:** Issue - should have back arrow

---

#### Detail Screens Summary (First 3 Screens)

**Common Pattern:**
- All detail screens use DetailPageScaffold
- DetailPageScaffold has AppBar with NO leading widget (no back arrow)
- No PopScope in any detail screen
- No custom back button handlers
- All use context.go() for navigation
- System back button uses Navigator.pop() (Flutter default for nested routes)

**Key Finding:**
- Detail screens have NO visible back arrow
- System back button works correctly (Navigator.pop())
- DetailPageScaffold is used by both top-level (profile/settings) and nested (detail) routes
- DetailPageScaffold has no way to distinguish between top-level and nested routes

**Risk Assessment:**
- **High Risk:** Adding leading widget to DetailPageScaffold would add back arrow to profile/settings (incorrect)
- **Medium Risk:** Detail screens need visible back arrow but currently don't have one
- **Recommended:** Create separate scaffold for detail screens with back arrow, or add configurable leading widget to DetailPageScaffold

---

### 2.3 Form Screens (Multi-Step Flows)

**Files to Review:**
- `lib/src/features/verification/presentation/verification_wizard_screen.dart`
- `lib/src/features/auth/presentation/onboarding_profile_completion.dart`
- `lib/src/features/marketplace/presentation/post_load_screen.dart`
- `lib/src/features/support/presentation/raise_dispute_screen.dart`

**Review Status:** Not Started

---

### 2.4 Modal Screens

**Review Status:** Not Started

---

### 2.5 Special Screens

**Files to Review:**
- `lib/src/features/auth/presentation/auth_screen.dart`
- `lib/src/features/auth/presentation/delete_account_screen.dart`
- `lib/src/features/notifications/presentation/notifications_screen.dart`
- Public profile screens
- Review screens

**Review Status:** [Not Started/In Progress/Complete]

---

## Phase 3: Shared Components Review

### 3.1 Scaffold Components

**Files to Review:**
- `lib/src/features/shell/presentation/shell_components.dart`

**Review Status:** [Not Started/In Progress/Complete]

---

### 3.2 Navigation Widgets

**Review Status:** [Not Started/In Progress/Complete]

---

## Phase 4: State Management Review

### 4.1 Provider Dependencies on Navigation

**Review Status:** [Not Started/In Progress/Complete]

---

### 4.2 Riverpod Navigation Integration

**Review Status:** [Not Started/In Progress/Complete]

---

## Phase 5: Deep Link & Notification Review

### 5.1 Deep Link Handling

**Review Status:** [Not Started/In Progress/Complete]

---

### 5.2 Firebase Messaging Integration

**Review Status:** [Not Started/In Progress/Complete]

---

## Phase 6: Risk Assessment

**Review Status:** [Not Started/In Progress/Complete]

---

## Phase 7: Documentation Plan

**Review Status:** [Not Started/In Progress/Complete]

---

## Phase 8: Review Deliverables

**Review Status:** [Not Started/In Progress/Complete]

---

## Summary of Issues Found

[To be filled during review]

---

## Summary of Dependencies Identified

[To be filled during review]

---

## Risk Assessment Summary

[To be filled during review]

---

## Recommendations

[To be filled during review]
