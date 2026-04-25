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

---

# Localization Architecture

## Overview

TranZfort uses Flutter's internationalization (intl) package with ARB (Application Resource Bundle) files for localization. The system supports English (`en`) and Hindi (`hi`) with ICU `select` syntax for key consolidation and a CI guardrail to maintain parity and quality.

## Core Components

### 1. ARB Files (Source of Truth)

**Files:**
- `lib/l10n/app_en.arb` - English translations (primary)
- `lib/l10n/app_hi.arb` - Hindi translations

**Key Facts:**
- ARB files are the **source of truth** for all localization
- Never edit generated Dart files directly
- UTF-8 encoding required (Hindi Devanagari characters)
- JSON format with `@<key>` metadata for placeholders/descriptions

**Current Metrics (25 Apr 2026):**
- EN keys: **1,498** (target ≤ 1,500) ✅
- HI keys: **1,498** (parity achieved) ✅
- `app_en.arb` size: **153.7 KB**
- `app_hi.arb` size: **224.1 KB**
- Generated Dart payload: **787.2 KB** (346 + 185 + 256)

### 2. Generated Dart Localization Files

**Files:**
- `lib/src/l10n/app_localizations.dart` - Base class with all getters
- `lib/src/l10n/app_localizations_en.dart` - English implementation
- `lib/src/l10n/app_localizations_hi.dart` - Hindi implementation

**Generation:**
```bash
flutter gen-l10n
```

**Policy:**
- Generated files are **committed to the repo**
- Ensures app builds out-of-the-box for any developer
- Regenerate after any ARB file change
- Do not edit these files directly

### 3. ICU Select Keys

**Purpose:** Consolidate duplicate status/type families into single parameterized keys.

**Example:**
```json
"accountStateValue": "{state, select, deactivated_pending_cleanup {Deactivated pending cleanup} restricted {Restricted} active {Active} unknown {Unknown} other {Unknown}}"
```

**Usage in Dart:**
```dart
String localizedStatus = l10n.accountStateValue('active'); // Returns "Active"
```

**Consolidated Families (60+ keys reduced to 30+ ICU selects):**
- `accountStateValue` — Account states (active, deactivated, restricted, unknown)
- `accountRoleValue` — User roles (supplier, trucker, unknown)
- `supportTicketStatusValue` — Support ticket statuses
- `shellMessagesBookingStatusValue` — Booking request statuses
- `proofStatusValue` — Proof upload statuses (POD, LR, awaiting, submitted)
- `truckerFindLoadsBodyTypeValue` — Truck body types (open, trailer, container, tanker)
- `trustSafetyStatusValue` — Trust/safety statuses (normal, warned, restricted, suspended, banned)
- `notificationFallbackValue` — Notification type fallback
- `tripStageValue` — Trip stages (pending, in_transit, delivered, cancelled)
- `supplierPostLoadPriceTypeValue` — Price types (fixed, per_ton, unknown)

**Common Shared Keys (consolidated duplicated strings):**
- `commonDashboardLabel`, `commonSupportLabel`, `commonCancelAction`
- `commonCompletedLabel`, `commonNotificationsLabel`, `commonActiveLabel`
- `commonProfileLabel`, `commonCompanyNameLabel`, `commonNextStepTitle`
- `commonRetryAction`, `commonChatLabel`, `commonPostLoadAction`
- `commonTakePhotoAction`, `commonAadhaarNumberLabel`, `commonPanNumberLabel`
- `commonOpenInGoogleMapsAction`, `commonBackToSignInAction`
- `commonViewDetailsAction`, `commonDashboardOverviewTitle`, `commonQuickActionsTitle`
- `commonOpenMyLoadsAction`, `commonTripsLabel`, `commonFleetLabel`, `commonSignOutAction`
- `commonCallAction`, `commonReportSpamOrAbuseAction`, `commonUnknownLabel`
- `commonSystemUpdateLabel`, `commonVoiceMessageLabel`, `commonTruckDetailsLabel`
- `commonLoadMoreAction`, `commonOpenSupportAction`, `commonWhatHappensNextTitle`
- `commonCancelDeletionRequestAction`, `commonAttachmentFailureMessage`

**Normalization Pattern:**
```dart
String _localizedAccountState(AppLocalizations l10n, String value) {
  return l10n.accountStateValue(value.trim().toLowerCase());
}
```

### 4. CI Guardrail

**File:** `tool/verify_l10n.dart`

**Purpose:** Prevent localization degradation by checking:
1. Unused EN keys (no Dart references under `lib/`)
2. Missing HI keys (present in EN but not in HI)
3. Unallowlisted identical EN/HI values (untranslated strings)
4. Hardcoded UI strings (English literals in Dart files)

**Allowlist Files:**
- `tool/l10n_allowlist.txt` — Keys allowed to have identical EN/HI values (brand names, format strings, technical terms)
- `tool/hardcoded_strings_allowlist.txt` — Hardcoded strings allowed in Dart (test files, whitelisted screens)

**Run Locally:**
```bash
dart tool/verify_l10n.dart
```

**CI Integration:**
- File: `.github/workflows/l10n-guardrail.yml`
- Runs on every PR and push to `main` / `develop`
- Fails build if guardrail detects violations

**Current Status:** Passes clean (1498 EN keys, 84 allowlisted identical EN/HI values, zero unallowlisted violations)

### 5. Workflow: Adding New Localization Keys

**Step 1: Add to EN ARB**
```json
{
  "myNewKey": "My new English text",
  "@myNewKey": {
    "description": "Context for translators"
  }
}
```

**Step 2: Add to HI ARB**
```json
{
  "myNewKey": "मेरा नया हिंदी पाठ",
  "@myNewKey": {
    "description": "Context for translators"
  }
}
```

**Step 3: Regenerate Dart files**
```bash
flutter gen-l10n
```

**Step 4: Use in Dart code**
```dart
final l10n = AppLocalizations.of(context);
Text(l10n.myNewKey)
```

**Step 5: Verify guardrail**
```bash
dart tool/verify_l10n.dart
```

**Step 6: Commit**
- Commit ARB files + generated Dart files
- CI guardrail will verify on push

## Key Consolidation Strategy

### When to Use ICU Select

**Use ICU `select` when:**
- Multiple keys represent the same concept with different values (e.g., status enums)
- Values map 1:1 to an enum or database field
- Keys follow a naming pattern like `familyNameVariant` (e.g., `accountStateActive`, `accountStateDeactivated`)

**Example:**
```dart
// Before (4 separate keys)
switch (status) {
  case 'active': return l10n.accountStateActive;
  case 'deactivated': return l10n.accountStateDeactivated;
  case 'restricted': return l10n.accountStateRestricted;
  default: return l10n.accountStateUnknown;
}

// After (1 ICU select key)
return l10n.accountStateValue(status.toLowerCase());
```

### When to Use Common Keys

**Use shared `common*` keys when:**
- The same string appears in multiple contexts (e.g., "Dashboard" appears in 3+ screens)
- The string is a generic UI element (button labels, common actions)
- No contextual variation is needed

**Example:**
```dart
// Before (3 separate keys)
l10n.supplierDashboardLabel
l10n.truckerDashboardLabel
l10n.profileDashboardLabel

// After (1 common key)
l10n.commonDashboardLabel
```

### When NOT to Consolidate

**Keep separate keys when:**
- Strings have different meanings despite identical English text
- Context matters for translation (e.g., "Submit" on a form vs "Submit" in a chat)
- Key takes parameters that differ by context
- Future divergence is likely

## Metadata Descriptions

**Policy:** Strip `@metadata` `description` fields on mechanical keys (plain nouns, button labels). Keep descriptions only where the key takes parameters or is ambiguous without context.

**Examples:**
- Keep description: `"priceValue": "{price, select, fixed {...}}"` — parameterized
- Strip description: `"dashboardLabel": "Dashboard"` — plain noun

**Impact:** Commit `be1487e` stripped 1578 descriptions, kept 141. Significant ARB + generated Dart payload reduction.

## Language Toggle

**Files:** `lib/src/core/providers/app_locale_providers.dart`

**Supported Languages:**
- English (`en`) — default voice: `en-GB` (UK English)
- Hindi (`hi`) — default voice: `hi-IN` (Hindi)

**Language Switching:**
- `LanguageToggleAction` widget on auth + onboarding screens
- Persists to SharedPreferences
- Triggers MaterialApp rebuild (no data loss)
- No "language lock" — can switch mid-onboarding

**TTS Voice Mapping:**
- `en` → `en-GB` (UK English, not US)
- `hi` → `hi-IN` (Hindi India)

## TTS Integration

**File:** `lib/src/core/services/contextual_tts_service.dart`

**Mute Toggle:**
- `TtsActionButton` widget provides mute/unmute toggle
- Persists `tts_muted` flag to SharedPreferences
- Default state: unmuted
- Auto-play respects muted state (no replay on unmute)

**Auto-Play:**
- `TtsScreenSummaryEffect` auto-plays screen summary on mount
- Short-circuits when `tts_muted == true`
- Every screen routes through `ContextualTtsService.speakSummary`

## Testing

### Manual Testing Checklist
- [ ] Fresh install → English UK voice speaks on auth
- [ ] Tap mute icon → voice stops, next screen stays silent
- [ ] Tap again → next screen speaks
- [ ] `अ` / `A` swaps locale instantly on auth without wiping form state
- [ ] Verify all ICU select keys render correctly for all enum values
- [ ] Verify Hindi parity (no English strings in Hindi build)

### Guardrail Testing
```bash
# Run guardrail locally
dart tool/verify_l10n.dart

# Should pass with:
# - 0 unused EN keys
# - 0 missing HI keys
# - 0 unallowlisted identical EN/HI values
# - 0 unallowlisted hardcoded strings
```

## Performance Considerations

- **ARB file size:** 153.7 KB (EN) + 224.1 KB (HI) = 377.8 KB total
- **Generated Dart:** 787.2 KB (346 + 185 + 256)
- **ICU select overhead:** Negligible (runtime string interpolation)
- **Guardrail runtime:** Fast (pattern matching over Dart files)
- **CI guardrail:** Runs in ~10-15 seconds on GitHub Actions

## Migration History

**Phase 1 (Delete dead keys)** — Shipped 24 Apr 2026
- Removed 212 unused EN keys
- Removed 155 matching HI keys
- Reduced ARB size by 45 KB (EN) + 24 KB (HI)

**Phase 2 (Wire hardcoded strings)** — Shipped 24 Apr 2026
- Added 48 new keys and wired them in 10 files
- Free Hindi coverage without new translations

**Phase 3 (Hindi parity)** — Shipped 25 Apr 2026
- Translated 280 genuine untranslated strings
- Added 106 missing HI keys
- Achieved EN/HI parity at 1498/1498 keys

**Phase 4 (Key consolidation)** — Shipped 25 Apr 2026
- Collapsed 60+ status/type families into ICU select keys
- Reduced key count from 1733 to 1498 (-235 keys)
- Stripped 1578 metadata descriptions

**Phase 5 (CI guardrail)** — Shipped 25 Apr 2026
- Created `tool/verify_l10n.dart` script
- Added `.github/workflows/l10n-guardrail.yml`
- Guardrail passes clean with zero violations

## Related Files

- `lib/l10n/app_en.arb` - English translations (source of truth)
- `lib/l10n/app_hi.arb` - Hindi translations (source of truth)
- `lib/src/l10n/app_localizations.dart` - Generated base class
- `lib/src/l10n/app_localizations_en.dart` - Generated English implementation
- `lib/src/l10n/app_localizations_hi.dart` - Generated Hindi implementation
- `tool/verify_l10n.dart` - CI guardrail script
- `tool/l10n_allowlist.txt` - Allowlist for identical EN/HI values
- `tool/hardcoded_strings_allowlist.txt` - Allowlist for hardcoded UI strings
- `.github/workflows/l10n-guardrail.yml` - CI workflow
- `lib/src/core/providers/app_locale_providers.dart` - Locale state management
- `lib/src/core/services/contextual_tts_service.dart` - TTS service with voice mapping
- `lib/src/shared/widgets/tts_action_button.dart` - Mute/unmute toggle
- `lib/src/core/widgets/tts_screen_summary_effect.dart` - Auto-play TTS effect
- `docs/TODO-23-april.md` - Localization cleanup project checklist
