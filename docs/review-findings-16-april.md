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

**Review Status:** [Not Started/In Progress/Complete]

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

**Review Status:** [Not Started/In Progress/Complete]

---

### 2.3 Form Screens (Multi-Step Flows)

**Files to Review:**
- `lib/src/features/verification/presentation/verification_wizard_screen.dart`
- `lib/src/features/auth/presentation/onboarding_profile_completion.dart`
- `lib/src/features/marketplace/presentation/post_load_screen.dart`
- `lib/src/features/support/presentation/raise_dispute_screen.dart`

**Review Status:** [Not Started/In Progress/Complete]

---

### 2.4 Modal Screens

**Review Status:** [Not Started/In Progress/Complete]

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
