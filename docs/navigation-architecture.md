# Navigation Architecture

## Overview

The TranZfort app uses a comprehensive navigation architecture built on GoRouter with custom enhancements for route metadata, form protection, and monitoring. This document describes the key components and their interactions.

## Core Components

### 1. Route Metadata System

**File:** `lib/src/core/navigation/route_metadata_helper.dart`

The route metadata system provides a centralized registry for route information that drives navigation behavior across the app.

#### Key Features

- **Registry Pattern:** All route metadata is registered in a central location
- **Parameterized Routes:** Supports dynamic routes like `/load-detail/:loadId`
- **Type Safety:** Strongly typed metadata access

#### Metadata Properties

```dart
class RouteMetadata {
  final String type;              // Route type (auth, shell, supplier, trucker, etc.)
  final bool showBackArrow;       // Whether to show back arrow
  final bool requirePopScope;     // Whether PopScope is required
  final String? testId;           // Test identifier for automated testing
}
```

#### Usage Example

```dart
// Get metadata for current route
final metadata = RouteMetadataHelper.getMetadata(route);

// Check if back arrow should be shown
if (metadata.shouldShowBackArrow()) {
  // Show back button
}

// Check if PopScope is required
if (metadata.requirePopScope()) {
  // Add PopScope wrapper
}
```

### 2. Navigation Service

**File:** `lib/src/core/navigation/navigation_service.dart`

The NavigationService wraps GoRouter with logging capabilities and provides high-level navigation methods.

#### Key Methods

- `navigate()` - Navigate to a route
- `push()` - Push route onto stack
- `pop()` - Pop current route
- `replace()` - Replace current route
- `goNamed()` - Navigate to named route with parameters
- `navigateFromDeepLink()` - Navigate from deep link with validation

#### Logging Integration

All navigation operations are automatically logged via MonitoringService:
- Route transitions
- Back button events
- PopScope confirmations
- Navigation errors

#### Example Usage

```dart
final navService = NavigationService.instance;

// Navigate with automatic logging
navService.navigate(context, '/dashboard');

// Navigate from deep link with validation
final success = await navService.navigateFromDeepLink(context, deepLink);
if (!success) {
  navService.showDeepLinkErrorDialog(context, deepLink);
}
```

### 3. Monitoring Service

**File:** `lib/src/core/services/monitoring_service.dart`

The MonitoringService tracks navigation events for debugging and analytics.

#### Event Types

- `routeTransition` - Route changes
- `backButton` - Back button events
- `popScopeConfirmation` - PopScope dialog confirmations
- `error` - Navigation errors

#### Event Filtering

```dart
// Get all events of a specific type
final transitions = MonitoringService.instance.getEventsByType(
  NavigationEventType.routeTransition
);

// Get events for a specific route
final routeEvents = MonitoringService.instance.getEventsByRoute('/dashboard');

// Get events in a time range
final recentEvents = MonitoringService.instance.getEventsInTimeRange(
  DateTime.now().subtract(Duration(hours: 1)),
  DateTime.now(),
);
```

### 4. Form Screen Protection

Form screens use PopScope to prevent accidental data loss when users navigate away with unsaved changes.

#### Protected Screens

1. **EmailPasswordAuthScreen** - Email/password authentication
2. **RoleSelectionScreen** - User role selection
3. **OnboardingProfileCompletionScreen** - Profile completion form
4. **VerificationWizard** - Multi-step verification wizard
5. **PostLoadScreen** - Load posting form (13 fields)
6. **RaiseDisputeScreen** - Dispute submission form

#### Implementation Pattern

```dart
PopScope(
  canPop: !_hasUnsavedChanges(),
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    
    if (_hasUnsavedChanges()) {
      final shouldPop = await _showConfirmationDialog();
      if (shouldPop && mounted) {
        // Reset form and navigate
        _resetForm();
        Navigator.of(context).pop();
      }
    }
  },
  child: Scaffold(...),
)
```

#### Confirmation Dialog

When users try to navigate with unsaved changes:
1. Show confirmation dialog
2. User can cancel, discard changes, or save
3. If discarded: form is reset and navigation proceeds
4. If cancelled: navigation is blocked

### 5. Back Arrow System

The back arrow system automatically shows/hides the back button based on route metadata.

#### Implementation

- **DetailPageScaffold** has optional `showBackArrow` parameter
- Integrates with RouteMetadataHelper for automatic display
- 9 nested/detail routes have back arrows enabled

#### Routes with Back Arrow

- `/fleet`
- `/load-detail/:loadId`
- `/trip-detail/:tripId`
- `/route-preview`
- `/chat/:chatId`
- `/profile/:userId`

### 6. Shell PopScope

The user app shell has a "Press back again to exit" behavior for top-level routes.

#### Implementation

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    
    // Check if on top-level route
    if (_isTopLevelRoute()) {
      // Show "Press back again to exit"
      if (_canExit()) {
        Navigator.of(context).pop();
      }
    }
  },
  child: Scaffold(...),
)
```

### PopScope Implementation Patterns

There are two valid patterns for implementing PopScope in this codebase. Both patterns work correctly; the choice depends on the use case.

#### Pattern 1: State Variable with setState() (Shell Pattern)

**Use Case:** When you need to track timing-based state (e.g., "press back again to exit")

**Example:** Shell PopScope for "Press back again to exit"

```dart
class _UserAppShellState extends ConsumerState<UserAppShell> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final canPop = !topLevel || (_lastBackPressed != null && DateTime.now().difference(_lastBackPressed!) < const Duration(seconds: 2));

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        if (topLevel) {
          final now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) >= const Duration(seconds: 2)) {
            setState(() {  // ← CRITICAL: Must call setState()
              _lastBackPressed = now;
            });
            ScaffoldMessenger.of(context).showSnackBar(...);
          }
        }
      },
      child: Scaffold(...),
    );
  }
}
```

**Key Points:**
- Uses state variable (`_lastBackPressed`) in build method
- **Must call `setState()`** when updating state variable
- Widget rebuilds, recalculating `canPop`
- Used for timing-based logic

---

#### Pattern 2: Method Call (Form Screen Pattern)

**Use Case:** When checking dynamic state (e.g., unsaved changes) that's already tracked elsewhere

**Example:** Form screen PopScope for unsaved changes

```dart
class _MyFormScreenState extends ConsumerState<MyFormScreen> {
  // Form controllers and state tracking...

  bool _hasUnsavedChanges() {
    // Check if any form field differs from initial value
    return _emailController.text != _initialEmail ||
           _passwordController.text != _initialPassword;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges(),  // ← Method call, recalculated each build
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_hasUnsavedChanges()) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(...),
    );
  }
}
```

**Key Points:**
- Uses method call (`_hasUnsavedChanges()`) for `canPop`
- Method is called on each build, no setState needed
- State is tracked in form controllers/providers
- Used for dynamic state checks

---

#### When to Use Each Pattern

| Pattern | Use When | Example |
|---------|----------|---------|
| State Variable | Timing-based logic, need to track previous state | "Press back again to exit", rate limiting |
| Method Call | Dynamic state checks, state already tracked | Unsaved changes, validation state |

**Important:** If using Pattern 1 (state variable), **always call `setState()`** when updating the state variable. Without setState(), the widget won't rebuild and `canPop` won't be recalculated.

---

### Scaffold Choice: DetailPageScaffold vs Custom Scaffold

When implementing screens, choose between `DetailPageScaffold` and custom `Scaffold` based on your requirements.

#### DetailPageScaffold

**Use When:**
- Screen needs a standard back arrow
- AppBar is simple (title, optional actions)
- Back arrow behavior is standard (navigate back)

**Features:**
- Automatically shows back arrow when route metadata has `showBackArrow: true`
- Integrates with RouteMetadataHelper
- Consistent styling across detail screens

**Example:**
```dart
DetailPageScaffold(
  title: 'Load Details',
  body: LoadDetailContent(),
)
```

**Used By:**
- Load detail screens
- Trip detail screens
- Other standard detail screens

---

#### Custom Scaffold

**Use When:**
- Screen has complex AppBar (custom leading, multiple actions)
- Screen has special AppBar behavior (avatar tap, custom navigation)
- Back arrow needs custom placement or styling
- Screen doesn't need a back arrow (top-level routes)

**Features:**
- Full control over AppBar
- Custom leading widget (e.g., avatar, custom button)
- Custom actions and behavior

**Example:**
```dart
Scaffold(
  appBar: AppBar(
    leading: InkWell(
      onTap: () => context.push(AppRoutes.publicProfileLocation(userId)),
      child: AvatarCircle(...),
    ),
    title: Column(...),
    actions: [...],
  ),
  body: Content(),
)
```

**Used By:**
- Chat screen (avatar in leading)
- Route preview screen (custom buttons)
- Public profile screens (avatar, follow button)
- Dashboard screens (no back arrow needed)

---

#### Back Arrow Options with Custom Scaffold

If using custom Scaffold but need a back arrow:

**Option 1: Manual Back Arrow (Simple)**
```dart
AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => Navigator.of(context).pop(),
  ),
  // ...
)
```

**Option 2: Check Metadata (Consistent with system)**
```dart
AppBar(
  leading: RouteMetadataHelper.shouldShowBackArrow(context)
      ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        )
      : null,
  // ...
)
```

**Option 3: System Back Button Only**
- Don't add back arrow to AppBar
- Rely on system back button (Android) or gesture (iOS)
- Works after navigation fixes (Bug #1, #2)
- Zero risk, preserves custom AppBar

**Recommendation:** For screens with complex custom AppBar (chat, route preview, public profile), use Option 3 (system back button only) to preserve existing UI/UX.

---

### Route Metadata: Documentation vs Enforcement

Route metadata in this codebase serves as **documentation and reference**, not runtime enforcement.

#### Current Role of Metadata

**Documentation:**
- Describes route characteristics (type, back arrow requirement, PopScope requirement)
- Provides centralized information about all routes
- Helps developers understand expected behavior

**Reference:**
- DetailPageScaffold uses `showBackArrow` metadata to automatically show/hide back arrow
- Can be queried by tools and tests
- Provides single source of truth for route information

**Not Enforced:**
- Screens can ignore metadata (e.g., custom Scaffold with no back arrow despite `showBackArrow: true`)
- No runtime validation that screens match their metadata
- Metadata is advisory, not mandatory

#### Why Documentation-Only?

**Benefits:**
- Flexibility for complex screens (custom AppBar, special behavior)
- No runtime overhead from enforcement layer
- Simpler architecture (no wrapper components needed)
- Zero risk of breaking existing screens

**Trade-offs:**
- Inconsistent behavior possible if screens ignore metadata
- Requires developer discipline to follow metadata
- Metadata can become outdated if not maintained

#### Best Practices

1. **Keep metadata accurate:** Update metadata when screen behavior changes
2. **Follow metadata when possible:** Use DetailPageScaffold for standard screens
3. **Document deviations:** If screen ignores metadata, add comment explaining why
4. **Review metadata regularly:** Ensure metadata matches actual implementation

#### Future Enhancement: Lint Rules

To improve metadata adherence without runtime enforcement, consider adding custom lint rules:
- Check if screen with `showBackArrow: true` has back arrow
- Check if screen with `requirePopScope: true` has PopScope
- Warn on metadata mismatches

This provides development-time feedback without runtime overhead.

---

## Route Registry

All 33 routes are registered with metadata in `lib/src/core/navigation/app_router.dart`.

### Auth Routes (7)
- `/login`
- `/signup`
- `/forgot-password`
- `/onboarding/role`
- `/onboarding/profile`
- `/verification`
- `/profile-setup`

### Shell Routes (6)
- `/supplier/dashboard`
- `/supplier/my-loads`
- `/supplier/trips`
- `/trucker/marketplace`
- `/trucker/my-trips`
- `/profile`

### Supplier Routes (3)
- `/post-load`
- `/fleet`
- `/trips`

### Trucker Routes (4)
- `/find-loads`
- `/my-trips`
- `/earnings`
- `/profile-setup`

### Detail Routes (6)
- `/load-detail/:loadId`
- `/trip-detail/:tripId`
- `/route-preview`
- `/chat/:chatId`
- `/profile/:userId`
- `/raise-dispute/:tripId`

### Form/Modal Routes (5)
- `/post-load`
- `/verification`
- `/profile-setup`
- `/support`
- `/raise-dispute/:tripId`

### Special Routes (4)
- `/`
- `/login`
- `/onboarding/role`
- `/verification`

## Best Practices

### Adding New Routes

1. **Register route in app_router.dart** with appropriate metadata
2. **Set route type** (auth, shell, supplier, trucker, detail, form, special)
3. **Configure back arrow** for nested/detail routes
4. **Set requirePopScope** for form screens
5. **Add testId** for automated testing

### Adding Form Protection

1. **Convert to StatefulWidget** if not already
2. **Track initial values** of form fields
3. **Implement `_hasUnsavedChanges()`** method
4. **Add `_onWillPop()`** confirmation dialog
5. **Wrap Scaffold with PopScope**
6. **Reset form** on discard confirmation

### Using Navigation Service

1. **Use NavigationService.instance** for all navigation
2. **Automatic logging** happens via MonitoringService
3. **Error handling** is built-in
4. **Deep link validation** available

## Testing

### Test Hooks

The MonitoringService provides test hooks for navigation testing:

```dart
// Clear events before test
MonitoringService.instance.clearEvents();

// Navigate
navService.navigate(context, '/dashboard');

// Verify navigation occurred
final events = MonitoringService.instance.getEventsByType(
  NavigationEventType.routeTransition
);
assert(events.length == 1);
assert(events.first.data['toRoute'] == '/dashboard');
```

### Route Metadata Testing

```dart
// Verify metadata is set correctly
final metadata = RouteMetadataHelper.getMetadata('/dashboard');
assert(metadata.type == 'shell');
assert(metadata.showBackArrow == false);
assert(metadata.requirePopScope == false);
```

## Error Handling

### Navigation Errors

All navigation errors are logged via MonitoringService:
- Invalid route paths
- Deep link validation failures
- Navigation exceptions

### Error Recovery

- Deep link errors show user-friendly dialog
- Form changes are preserved on navigation errors
- MonitoringService captures stack traces for debugging

## Performance Considerations

- **MonitoringService:** Minimal overhead, only in debug mode
- **Route Metadata:** O(1) lookup via registry pattern
- **PopScope:** No performance impact, only on back navigation
- **Navigation Service:** Thin wrapper around GoRouter

## Future Enhancements

- [ ] Add navigation analytics integration
- [ ] Implement navigation history
- [ ] Add deep link handling from external sources
- [ ] Implement custom route transitions
- [ ] Add navigation performance monitoring

## Related Files

- `lib/src/core/navigation/route_metadata_helper.dart` - Route metadata registry
- `lib/src/core/navigation/app_router.dart` - GoRouter configuration with metadata
- `lib/src/core/navigation/navigation_service.dart` - Navigation service with logging
- `lib/src/core/services/monitoring_service.dart` - Navigation event tracking
- `lib/src/features/shell/presentation/user_app_shell.dart` - Shell PopScope implementation
- `lib/src/features/shell/presentation/shell_components.dart` - DetailPageScaffold with back arrow
