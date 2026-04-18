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
