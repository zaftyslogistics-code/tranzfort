# Tasks Completed - 25 Feb

## Sprint 5: Marketplace - IMPLEMENTATION COMPLETE (Manual DoD Pending)

### Completed Scope
- Added **Post Load (4-step wizard)** with provider-owned state:
  - Route selection with city autocomplete and offline fallback
  - Cargo details, vehicle requirements, price/scale controls
  - Form validation and submit flow through repository
- Added **Find Loads** screen with:
  - Origin/destination/material/truck/sort filters
  - Infinite scroll pagination (`50/page`)
  - Reset + refresh behavior via provider state
- Added **RichLoadCard** widget with:
  - Route/cargo/price/advance/trip-cost rendering
  - Super-load badge and relative time display
  - Chat + Book actions (with current sprint-appropriate behavior)
- Added **My Loads (supplier)** screen:
  - Active/Completed tabs
  - Progress indicators and status badges
  - Deactivate action for active loads
- Added **Load Detail** views:
  - Trucker: trip cost + booking action
  - Supplier: pending approval, approve/reject actions, grouped child load sections
- Added **TripCostingService integration** on card/detail workflows.

### Architecture & Layering Work
- Introduced `LoadRepository` under core repositories for marketplace data/RPC access.
- Added `CitySearchService` (Google Places key-driven online mode + offline fallback list).
- Added `MapsConfig` for environment key management.
- Extended app router with Sprint 5 routes:
  - `/post-load`
  - `/find-loads`
  - `/my-loads`
  - `/load-detail/:loadId`

### Automated Validation
- `dart format test` -> PASS
- `flutter test` -> PASS (`00:03 +6: All tests passed`)
- `flutter analyze` -> PASS (No issues found)
- `python ..\scripts\check_layer_boundaries.py` -> PASS

### Tests Added
- `test/core/services/trip_costing_service_test.dart`
  - estimate success path
  - missing-distance failure path
  - fallback defaults path
- `test/core/services/city_search_service_test.dart`
  - offline fallback city suggestions
  - short-query empty result

### Documentation Sync
- `docs/project/TODO_SPRINT_05.md`: all Sprint 5 task checkboxes marked complete.
- `docs/project/TODO_MASTER.md`: current focus and gate checks synchronized.

### Remaining for Sprint 5 DoD Closure (Manual)
- Verify supplier can post load and trucker can discover it in-app.
- Verify filters + infinite scroll end-to-end in running app.
- Verify RichLoadCard visual hierarchy against spec on device.

## Manual Testing Note - 26 Feb (Auth First Real Device Run)

- Google sign-in was tested on connected Android device.
- Positive result: Supabase `auth.users` created a new user for the selected Gmail account.
- Observed behavior: app briefly refreshes and returns to the auth screen (no visible error).
- Interpretation: authentication is succeeding at backend/session level; post-login UX/navigation needs follow-up validation and improvement.

## Sprint 6: Booking Engine & Trips - PHASE 1 (In Progress)

### Completed Scope (Phase 1)
- Implemented trucker-side booking handshake UX in Find Loads:
  - No verified truck -> "Add Truck" prompt
  - Single verified truck -> booking confirmation dialog
  - Multiple verified trucks -> truck selection bottom sheet with match indicators
- Added trip data APIs in repository:
  - `getMyTrips(...)`
  - `getTripDetail(...)`
  - `startTrip(...)`
- Added trip feature scaffolding:
  - `trips_providers.dart`
  - `my_trips_screen.dart`
  - `trip_detail_screen.dart`
- Wired new routes:
  - `/my-trips`
  - `/trip-detail/:tripId`

### GPS Trigger Work
- Added `LocationService.captureCurrentLocation()` using Geolocator.
- Integrated GPS into `startTrip` action.
- Behavior follows rule: GPS capture failure does NOT block action (falls back to null lat/lng).

### Validation
- `flutter analyze` -> PASS
- `python ..\\scripts\\check_layer_boundaries.py` -> PASS

## Sprint 8: Tooling & Polish - PHASE 1 (In Progress)

### Completed Scope (Phase 1)
- **Settings & Preferences:**
  - Implemented `SettingsScreen` with toggles for TTS Muting and Push Notifications.
  - Added account deletion flow (`data_deletion_requested_at`).
  - Implemented local persistence using `SharedPreferences`.
- **Notifications & FCM:**
  - Added `firebase_core` and `firebase_messaging` dependencies.
  - Implemented `FcmTokenNotifier` to request permissions and sync `fcm_token` to the user's `profiles` record.
  - Built `NotificationsScreen` with DB integration (`NotificationRepository`) for read/unread state and deep linking to relevant items.
- **Route Preview:**
  - Integrated `flutter_map` and OSRM for dynamic route polyline rendering between Origin and Destination.
  - Created Haversine fallback logic for direct-line connections when OSRM fails.
  - Wired "Start Navigation in Google Maps" via `url_launcher` intents.
  - Embedded `RoutePreviewScreen` navigation inside `LoadDetailScreen`.

### Validation
- `flutter analyze` -> PASS
- `python ..\\scripts\\check_layer_boundaries.py` -> PASS
