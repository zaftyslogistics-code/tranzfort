# Navigation Architecture Implementation Plan
**Created:** April 17, 2026
**Status:** Planning Phase
**Target:** Professional, Scalable Architecture for 5000 Users

---

## Executive Summary

This document outlines the implementation plan for addressing navigation architecture issues identified in the comprehensive review of 29 screens. The goal is to create a professional, scalable navigation system that can handle 5000 users while maintaining existing UI/UX.

**Key Decisions:**
1. Use **Hybrid Approach** for back arrow - invisible by default with route metadata
2. Add **PopScope** to all screens for back button protection
3. Implement **Route Metadata System** for flexible navigation control
4. Create **Navigation Service** for centralized navigation logic
5. Add **Draft Persistence** for all form screens
6. Implement **Error Logging & Monitoring** for navigation failures

**Total Issues to Fix:** 35 issues (10 high, 19 medium, 6 low)

---

## Phase 1: Critical Infrastructure (Week 1-2)

### 1.1 Route Metadata System

**Objective:** Add metadata to all 37 routes to control navigation behavior

**Files to Modify:**
- `lib/src/core/navigation/app_router.dart`

**Implementation Steps:**

1. Define route metadata types
```dart
enum RouteType { topLevel, nested, modal, standalone }
enum BackBehavior { pop, go, none }
enum NavigationPriority { high, medium, low }

class RouteMetadata {
  final RouteType type;
  final BackBehavior backBehavior;
  final bool showBackArrow;
  final bool requirePopScope;
  final NavigationPriority priority;
  final String? parentRoute;
}
```

2. Add metadata to all routes in app_router.dart
```dart
// Example for nested route
GoRoute(
  path: '/fleet',
  name: 'fleet',
  builder: (context, state) => const TruckerFleetScreen(),
  meta: {
    'type': RouteType.nested,
    'backBehavior': BackBehavior.pop,
    'showBackArrow': false, // Invisible by default
    'requirePopScope': true,
    'priority': NavigationPriority.high,
    'parentRoute': '/trucker-dashboard',
  },
),

// Example for top-level route
GoRoute(
  path: '/trucker-dashboard',
  name: 'truckerDashboard',
  builder: (context, state) => const TruckerDashboardScreen(),
  meta: {
    'type': RouteType.topLevel,
    'backBehavior': BackBehavior.none,
    'showBackArrow': false,
    'requirePopScope': false,
    'priority': NavigationPriority.high,
    'parentRoute': null,
  },
),
```

3. Create route metadata helper
```dart
// lib/src/core/navigation/route_metadata_helper.dart
class RouteMetadataHelper {
  static RouteType? getType(BuildContext context) {
    final meta = GoRouterState.of(context).meta;
    return meta['type'] as RouteType?;
  }

  static bool shouldShowBackArrow(BuildContext context) {
    final meta = GoRouterState.of(context).meta;
    return meta['showBackArrow'] as bool? ?? false;
  }

  static bool requirePopScope(BuildContext context) {
    final meta = GoRouterState.of(context).meta;
    return meta['requirePopScope'] as bool? ?? false;
  }
}
```

**Routes to Update (37 total):**

**Auth Routes (5):**
- `/` (SplashScreen) - TopLevel, NoBackArrow, NoPopScope
- `/auth` (AuthEntryScreen) - TopLevel, NoBackArrow, NoPopScope
- `/auth/password` (EmailPasswordAuthScreen) - TopLevel, NoBackArrow, RequirePopScope (Form)
- `/onboarding` (OnboardingGateScreen) - TopLevel, NoBackArrow, RequirePopScope
- `/onboarding/role` (RoleSelectionScreen) - TopLevel, NoBackArrow, RequirePopScope (Form)
- `/onboarding/profile` (OnboardingProfileCompletionScreen) - TopLevel, NoBackArrow, RequirePopScope (Form)

**Shell Routes (6):**
- `/supplier-dashboard` - TopLevel, NoBackArrow, NoPopScope
- `/trucker-dashboard` - TopLevel, NoBackArrow, NoPopScope
- `/messages` - TopLevel, NoBackArrow, NoPopScope
- `/profile` - TopLevel, NoBackArrow, NoPopScope
- `/settings` - TopLevel, NoBackArrow, NoPopScope
- `/account` - TopLevel, NoBackArrow, NoPopScope

**Supplier Routes (3):**
- `/my-loads` - TopLevel, NoBackArrow, NoPopScope
- `/post-load` - TopLevel, NoBackArrow, RequirePopScope (Form)
- `/supplier-trips` - TopLevel, NoBackArrow, NoPopScope

**Trucker Routes (4):**
- `/find-loads` - TopLevel, NoBackArrow, NoPopScope
- `/fleet` - Nested, NoBackArrow, RequirePopScope (Form)
- `/trips` - TopLevel, NoBackArrow, NoPopScope

**Detail Routes (7):**
- `/supplier-trips/:id` - Nested, NoBackArrow, NoPopScope
- `/loads/:id` - Nested, NoBackArrow, NoPopScope
- `/trips/:id` - Nested, NoBackArrow, NoPopScope
- `/routes/:id` - Nested, NoBackArrow, NoPopScope
- `/profile/:id` - Nested, NoBackArrow, NoPopScope

**Form Routes (4):**
- `/supplier-verification` - Nested, NoBackArrow, RequirePopScope (Form)
- `/trucker-verification` - Nested, NoBackArrow, RequirePopScope (Form)
- `/disputes/:id` - Nested, NoBackArrow, RequirePopScope (Form)

**Modal Routes (2):**
- `/create-support-ticket` - Modal, NoBackArrow, RequirePopScope (Form)
- `/report-issue` - Modal, NoBackArrow, RequirePopScope (Form)

**Special Routes (6):**
- `/notifications` - TopLevel, NoBackArrow, NoPopScope
- `/support` - TopLevel, NoBackArrow, NoPopScope
- `/delete-account` - Nested, NoBackArrow, RequirePopScope (Destructive)
- `/banned` - TopLevel, NoBackArrow, RequirePopScope (Restricted)
- `/chat/:id` - Nested, NoBackArrow, NoPopScope

**Testing:**
- Verify all 37 routes have metadata
- Test route metadata helper functions
- Ensure no breaking changes to existing navigation

---

### 1.2 Update DetailPageScaffold with Route Metadata

**Objective:** Make DetailPageScaffold respect route metadata for back arrow

**Files to Modify:**
- `lib/src/features/shell/presentation/shell_components.dart`

**Implementation Steps:**

1. Import route metadata helper
```dart
import '../../../core/navigation/route_metadata_helper.dart';
```

2. Update DetailPageScaffold AppBar
```dart
AppBar(
  leading: _buildLeadingWidget(context),
  title: Text(title),
  // ... existing code
)

Widget _buildLeadingWidget(BuildContext context) {
  final shouldShowBackArrow = RouteMetadataHelper.shouldShowBackArrow(context);
  
  if (!shouldShowBackArrow) {
    return const SizedBox.shrink(); // Invisible by default
  }
  
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.of(context).pop(),
    tooltip: 'Back',
  );
}
```

3. Add invisible back arrow for nested routes (optional enhancement)
```dart
Widget _buildLeadingWidget(BuildContext context) {
  final shouldShowBackArrow = RouteMetadataHelper.shouldShowBackArrow(context);
  final routeType = RouteMetadataHelper.getType(context);
  
  if (shouldShowBackArrow) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Back',
    );
  }
  
  // Invisible back arrow for nested routes (functional but not visible)
  if (routeType == RouteType.nested) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: const SizedBox(width: 48), // Invisible tap area
    );
  }
  
  return const SizedBox.shrink();
}
```

**Testing:**
- Test DetailPageScaffold with different route types
- Verify invisible back arrow is functional
- Test accessibility with tooltip
- Ensure no breaking changes

---

### 1.3 Add PopScope to Shell Screens

**Objective:** Add "Press back again to exit" protection to shell

**Files to Modify:**
- `lib/src/features/shell/presentation/user_app_shell.dart`

**Implementation Steps:**

1. Add PopScope wrapper
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    
    _handleBackButton(context);
  },
  child: Scaffold(...),
)
```

2. Implement back button handler
```dart
DateTime? _lastBackPress;

void _handleBackButton(BuildContext context) {
  final now = DateTime.now();
  
  if (_lastBackPress == null || 
      now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
    _lastBackPress = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Press back again to exit')),
    );
  } else {
    // Allow exit
    SystemNavigator.pop();
  }
}
```

**Testing:**
- Test "Press back again to exit" behavior
- Verify timing works correctly
- Test on Android and iOS

---

## Phase 2: Form Screen Protection (Week 2-3)

### 2.1 Add PopScope to All Form Screens

**Objective:** Prevent data loss on system back button

**Form Screens (6 total):**
1. EmailPasswordAuthScreen
2. RoleSelectionScreen
3. OnboardingProfileCompletionScreen
4. VerificationWizard
5. PostLoadScreen
6. RaiseDisputeScreen

**Implementation Pattern (apply to all 6 screens):**

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    
    _handleBackButton(context);
  },
  child: Scaffold(...),
)

void _handleBackButton(BuildContext context) {
  if (_hasUnsavedChanges()) {
    _showUnsavedChangesDialog(context);
  } else {
    Navigator.of(context).pop();
  }
}

bool _hasUnsavedChanges() {
  // Check if form has unsaved data
  return _emailController.text.isNotEmpty ||
         _passwordController.text.isNotEmpty ||
         _selectedRole != null;
}

void _showUnsavedChangesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unsaved Changes'),
      content: const Text('You have unsaved changes. Do you want to exit?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Exit screen
          },
          child: const Text('Exit'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            // Save draft logic here
          },
          child: const Text('Save Draft'),
        ),
      ],
    ),
  );
}
```

**Files to Modify:**
- `lib/src/features/auth/presentation/auth_screens_email_password.dart`
- `lib/src/features/auth/presentation/onboarding_screens.dart` (RoleSelectionScreen)
- `lib/src/features/auth/presentation/onboarding_profile_completion.dart`
- `lib/src/features/verification/presentation/verification_wizard.dart`
- `lib/src/features/supplier/presentation/post_load_screen.dart`
- `lib/src/features/supplier/presentation/raise_dispute_screen.dart`

**Testing:**
- Test each form screen with unsaved data
- Verify dialog appears on back button
- Test "Exit", "Cancel", and "Save Draft" options
- Ensure no data loss

---

### 2.2 Add Draft Persistence for Form Screens

**Objective:** Save form data locally for recovery

**Implementation Steps:**

1. Create draft persistence service
```dart
// lib/src/core/services/draft_persistence_service.dart
class DraftPersistenceService {
  static const _draftsKey = 'form_drafts';
  
  Future<void> saveDraft(String formId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = prefs.getString(_draftsKey) ?? '{}';
    final draftsMap = jsonDecode(drafts) as Map<String, dynamic>;
    draftsMap[formId] = data;
    await prefs.setString(_draftsKey, jsonEncode(draftsMap));
  }
  
  Future<Map<String, dynamic>?> loadDraft(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = prefs.getString(_draftsKey) ?? '{}';
    final draftsMap = jsonDecode(drafts) as Map<String, dynamic>;
    return draftsMap[formId] as Map<String, dynamic>?;
  }
  
  Future<void> clearDraft(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = prefs.getString(_draftsKey) ?? '{}';
    final draftsMap = jsonDecode(drafts) as Map<String, dynamic>;
    draftsMap.remove(formId);
    await prefs.setString(_draftsKey, jsonEncode(draftsMap));
  }
}
```

2. Add draft save/load to each form screen
```dart
// Example for RoleSelectionScreen
@override
void initState() {
  super.initState();
  _loadDraft();
}

Future<void> _loadDraft() async {
  final draft = await DraftPersistenceService.loadDraft('role_selection');
  if (draft != null) {
    setState(() {
      _selectedRole = draft['role'] as AppUserRole?;
    });
  }
}

Future<void> _saveDraft() async {
  await DraftPersistenceService.saveDraft('role_selection', {
    'role': _selectedRole,
  });
}

@override
void dispose() {
  if (_hasUnsavedChanges()) {
    _saveDraft();
  }
  super.dispose();
}
```

**Files to Modify:**
- Create: `lib/src/core/services/draft_persistence_service.dart`
- Modify: All 6 form screens

**Testing:**
- Test draft save on screen exit
- Test draft load on screen re-entry
- Test draft clear after successful submission
- Verify draft persistence across app restarts

---

## Phase 3: Navigation Service (Week 3-4)

### 3.1 Create Navigation Service

**Objective:** Centralize navigation logic for consistency and monitoring

**Implementation Steps:**

1. Create navigation service
```dart
// lib/src/core/navigation/navigation_service.dart
class NavigationService {
  static void navigate(BuildContext context, String routeName, {Object? extra}) {
    // Log navigation event
    _logNavigation(routeName);
    
    // Validate route parameters
    _validateRoute(routeName, extra);
    
    // Perform navigation
    context.go(routeName, extra: extra);
  }
  
  static void push(BuildContext context, String routeName, {Object? extra}) {
    _logNavigation(routeName, isPush: true);
    _validateRoute(routeName, extra);
    context.push(routeName, extra: extra);
  }
  
  static void pop(BuildContext context, {Object? result}) {
    _logNavigation('pop', isPop: true);
    Navigator.of(context).pop(result);
  }
  
  static void _logNavigation(String routeName, {bool isPush = false, bool isPop = false}) {
    // Add analytics logging here
    print('Navigation: ${isPop ? "POP" : isPush ? "PUSH" : "GO"} $routeName');
  }
  
  static void _validateRoute(String routeName, Object? extra) {
    // Add route validation logic
    // Log if route doesn't exist
  }
}
```

2. Update all screens to use NavigationService
```dart
// Before
context.go(AppRoutes.profilePath);

// After
NavigationService.navigate(context, AppRoutes.profilePath);
```

**Files to Modify:**
- Create: `lib/src/core/navigation/navigation_service.dart`
- Modify: All 29 screens (replace context.go/context.push with NavigationService)

**Testing:**
- Test navigation through NavigationService
- Verify logging works
- Test route validation
- Ensure no breaking changes

---

### 3.2 Add Navigation Error Handling

**Objective:** Handle navigation failures gracefully

**Implementation Steps:**

1. Add error handling to NavigationService
```dart
static void navigate(BuildContext context, String routeName, {Object? extra}) {
  try {
    _logNavigation(routeName);
    _validateRoute(routeName, extra);
    context.go(routeName, extra: extra);
  } catch (e, stackTrace) {
    _handleNavigationError(context, routeName, e, stackTrace);
  }
}

static void _handleNavigationError(
  BuildContext context,
  String routeName,
  Object error,
  StackTrace stackTrace,
) {
  // Log error to monitoring service
  MonitoringService.logError(
    'Navigation Error',
    error: error,
    stackTrace: stackTrace,
    context: {'route': routeName},
  );
  
  // Show user-friendly error message
  AppSnackbar.show(
    context: context,
    message: 'Navigation failed. Please try again.',
    variant: AppSnackbarVariant.error,
  );
}
```

**Files to Modify:**
- Modify: `lib/src/core/navigation/navigation_service.dart`
- Create: `lib/src/core/services/monitoring_service.dart`

**Testing:**
- Test navigation error scenarios
- Verify error logging
- Test user error messages
- Test with invalid routes

---

## Phase 4: Route Organization (Week 4-5)

### 4.1 Split Routes into Feature Modules

**Objective:** Improve maintainability by organizing routes by feature

**Implementation Steps:**

1. Create feature-based route files
```dart
// lib/src/core/navigation/routes/auth_routes.dart
List<GoRoute> get authRoutes => [
  GoRoute(
    path: '/auth',
    name: 'auth',
    builder: (context, state) => const AuthEntryScreen(),
    meta: {...},
  ),
  GoRoute(
    path: '/auth/password',
    name: 'emailPasswordAuth',
    builder: (context, state) => const EmailPasswordAuthScreen(),
    meta: {...},
  ),
  // ... more auth routes
];

// lib/src/core/navigation/routes/supplier_routes.dart
List<GoRoute> get supplierRoutes => [
  GoRoute(
    path: '/supplier-dashboard',
    name: 'supplierDashboard',
    builder: (context, state) => const SupplierDashboardScreen(),
    meta: {...},
  ),
  // ... more supplier routes
];

// lib/src/core/navigation/routes/trucker_routes.dart
List<GoRoute> get truckerRoutes => [
  GoRoute(
    path: '/trucker-dashboard',
    name: 'truckerDashboard',
    builder: (context, state) => const TruckerDashboardScreen(),
    meta: {...},
  ),
  // ... more trucker routes
];
```

2. Update app_router.dart to use route modules
```dart
final router = GoRouter(
  routes: [
    ...authRoutes,
    ...supplierRoutes,
    ...truckerRoutes,
    ...shellRoutes,
    // ... other route modules
  ],
  // ... existing config
);
```

**Files to Create:**
- `lib/src/core/navigation/routes/auth_routes.dart`
- `lib/src/core/navigation/routes/supplier_routes.dart`
- `lib/src/core/navigation/routes/trucker_routes.dart`
- `lib/src/core/navigation/routes/shell_routes.dart`
- `lib/src/core/navigation/routes/modal_routes.dart`

**Files to Modify:**
- `lib/src/core/navigation/app_router.dart`

**Testing:**
- Test all routes still work after split
- Verify no breaking changes
- Test route imports

---

### 4.2 Simplify Redirect Logic

**Objective:** Reduce complexity of app_router_redirect.dart

**Implementation Steps:**

1. Create route guards
```dart
// lib/src/core/navigation/guards/auth_guard.dart
class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final authState = context.watch(currentAuthStateProvider);
    
    if (!authState.hasSession) {
      return AppRoutes.authPath;
    }
    
    return null; // Allow navigation
  }
}

// lib/src/core/navigation/guards/role_guard.dart
class RoleGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final authState = context.watch(currentAuthStateProvider);
    
    if (authState.role == AppUserRole.unknown) {
      return AppRoutes.onboardingRolePath;
    }
    
    return null;
  }
}

// lib/src/core/navigation/guards/verification_guard.dart
class VerificationGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final profile = context.watch(currentProfileProvider).valueOrNull;
    
    if (profile?.verificationStatus != 'verified') {
      final role = context.watch(currentAuthStateProvider).role;
      return role == AppUserRole.supplier
          ? AppRoutes.supplierVerificationPath
          : AppRoutes.truckerVerificationPath;
    }
    
    return null;
  }
}
```

2. Update app_router.dart to use guards
```dart
redirect: (context, state) {
  final authRedirect = AuthGuard.redirect(context, state);
  if (authRedirect != null) return authRedirect;
  
  final roleRedirect = RoleGuard.redirect(context, state);
  if (roleRedirect != null) return roleRedirect;
  
  final verificationRedirect = VerificationGuard.redirect(context, state);
  if (verificationRedirect != null) return verificationRedirect;
  
  return null;
}
```

**Files to Create:**
- `lib/src/core/navigation/guards/auth_guard.dart`
- `lib/src/core/navigation/guards/role_guard.dart`
- `lib/src/core/navigation/guards/verification_guard.dart`

**Files to Modify:**
- `lib/src/core/navigation/app_router.dart`
- `lib/src/core/navigation/app_router_redirect.dart` (simplify)

**Testing:**
- Test all redirect scenarios
- Verify guard logic
- Test unauthenticated access
- Test role-based redirects
- Test verification redirects

---

## Phase 5: Error Logging & Monitoring (Week 5-6)

### 5.1 Implement Navigation Error Logging

**Objective:** Log all navigation failures for monitoring

**Implementation Steps:**

1. Create monitoring service
```dart
// lib/src/core/services/monitoring_service.dart
class MonitoringService {
  static void logNavigation(String route, Map<String, dynamic> context) {
    // Send to analytics (Firebase Analytics, Mixpanel, etc.)
    // Log to console in development
    if (kDebugMode) {
      print('Navigation: $route - $context');
    }
  }
  
  static void logError(
    String errorType, {
    required Object error,
    required StackTrace stackTrace,
    Map<String, dynamic>? context,
  }) {
    // Send to error tracking (Sentry, Firebase Crashlytics, etc.)
    // Log to console in development
    if (kDebugMode) {
      print('Error: $errorType - $error');
      print(stackTrace);
    }
  }
  
  static void logPerformance(String operation, Duration duration) {
    // Send to performance monitoring
    if (kDebugMode) {
      print('Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }
}
```

2. Integrate with NavigationService
```dart
static void navigate(BuildContext context, String routeName, {Object? extra}) {
  final startTime = DateTime.now();
  
  try {
    _logNavigation(routeName);
    _validateRoute(routeName, extra);
    context.go(routeName, extra: extra);
    
    final duration = DateTime.now().difference(startTime);
    MonitoringService.logPerformance('navigate', duration);
  } catch (e, stackTrace) {
    MonitoringService.logError(
      'Navigation Error',
      error: e,
      stackTrace: stackTrace,
      context: {'route': routeName},
    );
    _handleNavigationError(context, routeName, e, stackTrace);
  }
}
```

**Files to Create:**
- `lib/src/core/services/monitoring_service.dart`

**Files to Modify:**
- `lib/src/core/navigation/navigation_service.dart`

**Testing:**
- Test error logging in development
- Verify performance logging
- Test with monitoring service integration
- Verify no performance impact

---

### 5.2 Add Deep Link Validation

**Objective:** Validate deep link parameters before navigation

**Implementation Steps:**

1. Create deep link validator
```dart
// lib/src/core/navigation/deep_link_validator.dart
class DeepLinkValidator {
  static ValidationResult validate(String route, Map<String, dynamic> params) {
    // Validate route exists
    if (!_routeExists(route)) {
      return ValidationResult.failure('Route does not exist');
    }
    
    // Validate required parameters
    final requiredParams = _getRequiredParams(route);
    for (final param in requiredParams) {
      if (!params.containsKey(param)) {
        return ValidationResult.failure('Missing required parameter: $param');
      }
    }
    
    // Validate parameter types
    for (final entry in params.entries) {
      if (!_validateParamType(entry.key, entry.value)) {
        return ValidationResult.failure('Invalid parameter type for ${entry.key}');
      }
    }
    
    return ValidationResult.success();
  }
  
  static bool _routeExists(String route) {
    // Check if route exists in router
    return true; // Implement actual check
  }
  
  static List<String> _getRequiredParams(String route) {
    // Return required parameters for route
    return [];
  }
  
  static bool _validateParamType(String key, dynamic value) {
    // Validate parameter type
    return true; // Implement actual validation
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  ValidationResult.success() : isValid = true, errorMessage = null;
  ValidationResult.failure(this.errorMessage) : isValid = false;
}
```

2. Integrate with NavigationService
```dart
static void navigate(BuildContext context, String routeName, {Object? extra}) {
  if (extra is Map<String, dynamic>) {
    final validation = DeepLinkValidator.validate(routeName, extra);
    if (!validation.isValid) {
      MonitoringService.logError(
        'Deep Link Validation Error',
        error: Exception(validation.errorMessage),
        stackTrace: StackTrace.current,
        context: {'route': routeName},
      );
      _handleValidationError(context, validation.errorMessage!);
      return;
    }
  }
  
  // ... rest of navigation logic
}
```

**Files to Create:**
- `lib/src/core/navigation/deep_link_validator.dart`

**Files to Modify:**
- `lib/src/core/navigation/navigation_service.dart`

**Testing:**
- Test deep link validation
- Test with invalid routes
- Test with missing parameters
- Test with invalid parameter types

---

## Phase 6: E2E Testing Infrastructure (Week 6-7)

### 6.1 Create E2E Testing Framework (Deferred to Post-Launch)

**Objective:** Prepare infrastructure for E2E testing when app is launched

**Implementation Steps:**

1. Add E2E testing dependencies (deferred)
```yaml
# pubspec.yaml (add later after launch)
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
  test: ^1.24.0
```

2. Create E2E test structure (placeholder)
```dart
// integration_test/navigation_e2e_test.dart (deferred)
void main() {
  // Placeholder for E2E tests
  // Will implement after app launch
}
```

3. Create test helpers (placeholder)
```dart
// test/helpers/navigation_test_helpers.dart (deferred)
class NavigationTestHelpers {
  // Placeholder for E2E test helpers
}
```

**Files to Create (Placeholder):**
- `integration_test/navigation_e2e_test.dart` (deferred)
- `test/helpers/navigation_test_helpers.dart` (deferred)

**Files to Modify (Later):**
- `pubspec.yaml` (deferred)

**Status:** DEFERRED - Will implement after app launch

---

### 6.2 Add Navigation Test Hooks

**Objective:** Add hooks for future E2E testing without breaking existing code

**Implementation Steps:**

1. Add test hooks to NavigationService
```dart
class NavigationService {
  static NavigationTestHook? _testHook;
  
  static void setTestHook(NavigationTestHook hook) {
    _testHook = hook;
  }
  
  static void navigate(BuildContext context, String routeName, {Object? extra}) {
    _testHook?.beforeNavigate(routeName, extra);
    
    // ... navigation logic
    
    _testHook?.afterNavigate(routeName, true);
  }
}

abstract class NavigationTestHook {
  void beforeNavigate(String route, Object? extra);
  void afterNavigate(String route, bool success);
}
```

2. Add route metadata for testing
```dart
// In route metadata
meta: {
  'type': RouteType.nested,
  'backBehavior': BackBehavior.pop,
  'showBackArrow': false,
  'requirePopScope': true,
  'priority': NavigationPriority.high,
  'parentRoute': '/trucker-dashboard',
  'testId': 'fleet_screen', // For E2E testing
}
```

**Files to Modify:**
- `lib/src/core/navigation/navigation_service.dart`
- `lib/src/core/navigation/app_router.dart` (add testId to routes)

**Testing:**
- Verify test hooks don't affect production code
- Test with test hook set
- Ensure hooks are null in production

---

## Phase 7: Documentation (Week 7)

### 7.1 Create Navigation Architecture Document

**Objective:** Document navigation architecture for future developers

**Implementation Steps:**

1. Create navigation architecture document
```markdown
# Navigation Architecture Documentation

## Overview
This document describes the navigation architecture of the TranZfort user app.

## Route Metadata System
All routes have metadata that controls navigation behavior:
- type: topLevel, nested, modal, standalone
- backBehavior: pop, go, none
- showBackArrow: true/false
- requirePopScope: true/false
- priority: high, medium, low
- parentRoute: parent route name

## Navigation Service
All navigation should go through NavigationService for consistency and monitoring.

## Form Screen Protection
All form screens have PopScope to prevent data loss.

## Route Organization
Routes are organized by feature in separate files.

## Error Handling
All navigation errors are logged and handled gracefully.

## Testing
E2E testing infrastructure is prepared for future implementation.
```

**Files to Create:**
- `docs/navigation-architecture.md`

---

### 7.2 Create Contributor Guide

**Objective:** Guide for adding new routes and screens

**Implementation Steps:**

1. Create contributor guide
```markdown
# Adding New Routes and Screens

## Step 1: Define Route Metadata
Add route metadata to the appropriate route file.

## Step 2: Create Screen
Create the screen with proper navigation patterns.

## Step 3: Add PopScope if Form Screen
If the screen is a form, add PopScope for data protection.

## Step 4: Use NavigationService
Use NavigationService for all navigation calls.

## Step 5: Add Error Handling
Handle navigation errors appropriately.

## Step 6: Add Test Hooks
Add test hooks for future E2E testing.

## Step 7: Update Documentation
Update this document with the new route.
```

**Files to Create:**
- `docs/navigation-contributor-guide.md`

---

## Phase 8: Testing & Validation (Week 8)

### 8.1 Unit Tests

**Objective:** Test navigation components in isolation

**Tests to Write:**

1. Route metadata helper tests
```dart
// test/core/navigation/route_metadata_helper_test.dart
void main() {
  test('should return correct route type', () {
    // Test route type detection
  });
  
  test('should return correct showBackArrow value', () {
    // Test back arrow visibility
  });
  
  test('should return correct requirePopScope value', () {
    // Test PopScope requirement
  });
}
```

2. Navigation service tests
```dart
// test/core/navigation/navigation_service_test.dart
void main() {
  test('should log navigation event', () {
    // Test navigation logging
  });
  
  test('should validate route parameters', () {
    // Test route validation
  });
  
  test('should handle navigation errors', () {
    // Test error handling
  });
}
```

3. Deep link validator tests
```dart
// test/core/navigation/deep_link_validator_test.dart
void main() {
  test('should validate existing route', () {
    // Test route existence validation
  });
  
  test('should reject missing required parameters', () {
    // Test parameter validation
  });
  
  test('should reject invalid parameter types', () {
    // Test type validation
  });
}
```

**Files to Create:**
- `test/core/navigation/route_metadata_helper_test.dart`
- `test/core/navigation/navigation_service_test.dart`
- `test/core/navigation/deep_link_validator_test.dart`

---

### 8.2 Integration Tests

**Objective:** Test navigation flows end-to-end (manual for now)

**Manual Test Plan:**

1. Test all 37 routes
   - Navigate to each route
   - Verify route loads correctly
   - Test back button behavior

2. Test form screens
   - Navigate to each form screen
   - Enter data
   - Press system back button
   - Verify confirmation dialog appears
   - Test "Exit", "Cancel", "Save Draft" options

3. Test deep links
   - Test valid deep links
   - Test invalid deep links
   - Test deep links with missing parameters
   - Test deep links with invalid parameters

4. Test error scenarios
   - Test navigation to non-existent route
   - Test navigation with invalid parameters
   - Test navigation during loading state

5. Test back button behavior
   - Test "Press back again to exit" on shell
   - Test back button on nested routes
   - Test back button on form screens
   - Test back button on modal routes

---

### 8.3 Performance Testing

**Objective:** Ensure navigation performance is acceptable

**Tests to Run:**

1. Navigation timing
   - Measure time to navigate to each route
   - Target: < 500ms for all routes

2. PopScope overhead
   - Measure performance impact of PopScope
   - Target: < 50ms overhead

3. Navigation service overhead
   - Measure performance impact of NavigationService
   - Target: < 50ms overhead

---

## Summary

### Phases Completed: 8

### Files to Create: 15
1. `lib/src/core/navigation/route_metadata_helper.dart`
2. `lib/src/core/navigation/navigation_service.dart`
3. `lib/src/core/services/draft_persistence_service.dart`
4. `lib/src/core/services/monitoring_service.dart`
5. `lib/src/core/navigation/deep_link_validator.dart`
6. `lib/src/core/navigation/routes/auth_routes.dart`
7. `lib/src/core/navigation/routes/supplier_routes.dart`
8. `lib/src/core/navigation/routes/trucker_routes.dart`
9. `lib/src/core/navigation/routes/shell_routes.dart`
10. `lib/src/core/navigation/routes/modal_routes.dart`
11. `lib/src/core/navigation/guards/auth_guard.dart`
12. `lib/src/core/navigation/guards/role_guard.dart`
13. `lib/src/core/navigation/guards/verification_guard.dart`
14. `docs/navigation-architecture.md`
15. `docs/navigation-contributor-guide.md`

### Files to Modify: 35
1. `lib/src/core/navigation/app_router.dart` (add metadata to 37 routes)
2. `lib/src/features/shell/presentation/shell_components.dart` (DetailPageScaffold)
3. `lib/src/features/shell/presentation/user_app_shell.dart` (PopScope)
4. `lib/src/features/auth/presentation/auth_screens_email_password.dart` (PopScope)
5. `lib/src/features/auth/presentation/onboarding_screens.dart` (PopScope)
6. `lib/src/features/auth/presentation/onboarding_profile_completion.dart` (PopScope)
7. `lib/src/features/verification/presentation/verification_wizard.dart` (PopScope)
8. `lib/src/features/supplier/presentation/post_load_screen.dart` (PopScope)
9. `lib/src/features/supplier/presentation/raise_dispute_screen.dart` (PopScope)
10. `lib/src/core/navigation/app_router_redirect.dart` (simplify)
11. All 29 screens (replace context.go with NavigationService)

### Deferred Items: 2
1. E2E testing implementation (deferred to post-launch)
2. E2E test dependencies (deferred to post-launch)

### Timeline: 8 weeks

### Risk Mitigation:
- No breaking changes to existing UI/UX
- Invisible back arrow preserves current design
- Gradual rollout with route metadata
- Comprehensive testing before each phase
- Rollback plan ready

### Success Criteria:
- All 35 issues resolved
- No breaking changes to existing functionality
- Navigation performance < 500ms
- Form data protection implemented
- Error logging and monitoring in place
- Documentation complete
- E2E testing infrastructure ready for future

---

## Next Steps

1. Review this plan with team
2. Get approval for implementation
3. Start Phase 1 (Critical Infrastructure)
4. Complete phases sequentially
5. Test thoroughly after each phase
6. Deploy to production after Phase 8
7. Monitor for 1 week after deployment
8. Gather feedback from users
9. Iterate based on feedback
10. Scale to 5000 users with confidence

---

**Status:** Ready for Implementation
**Last Updated:** April 17, 2026
