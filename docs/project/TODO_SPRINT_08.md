# TODO - Sprint 8: Tooling & Polish

## Scope
Route preview, notifications, settings, final polish.

## Tasks
- [x] Route preview with flutter_map + OSRM + fallback
- [x] Deep link to Google Maps
- [x] FCM setup + token storage
- [x] In-app notifications screen
- [x] Settings screen + toggles
- [x] Delete account flow
- [ ] Push notification triggers

## Definition of Done
- [ ] Notifications received + deep linking works
- [x] Settings persisted

## Progress Notes (26 Feb, Phase 1)
- Implemented `RoutePreviewScreen` with `flutter_map` and OSRM routing API integration. Added Haversine direct-line fallback.
- Configured deep linking to Google Maps from Route Preview.
- Initialized Firebase and created `FcmTokenNotifier` to fetch and store device FCM token into the user profile.
- Built `NotificationsScreen` with UI for read/unread state mapping to DB.
- Implemented `SettingsScreen` with TTS toggle, Push Notification toggle, and Account Deletion logic.
