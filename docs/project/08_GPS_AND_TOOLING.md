# 08: GPS, Routing, Notifications & Settings

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define the GPS philosophy, route preview system, trip cost formula, push notification triggers, in-app notification screen, settings screens, and offline city search. A junior developer should build all tooling features from this document.

---

## 1. GPS Philosophy — What We Do NOT Build

- **Rule 1:** NO continuous background tracking. Battery drain + privacy concerns.
- **Rule 2:** NO turn-by-turn voice navigation. We deep-link to Google Maps.
- **Rule 3:** GPS is captured at EXACTLY 4 bounded moments (see 06_BOOKING doc §5).
- **Rule 4:** GPS failure NEVER blocks any trip action. Location is best-effort only.

---

## 2. Route Preview (`/route-preview`)

### 2.1 Screen Layout
```
┌────────────────────────────────────┐
│ [←] Route Preview                  │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ [flutter_map]                │   │
│ │ 🟢 Chandrapur (origin pin)  │   │
│ │ ---- polyline ----           │   │
│ │ 🔴 Mumbai (dest pin)        │   │
│ │ Height: 300px                │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ § Route Info                       │
│ Distance: ~680 km                  │
│ Duration: ~12h (OSRM estimate)     │
├────────────────────────────────────┤
│ § Trip Cost Breakdown              │
│ ┌──────────────────────────────┐   │
│ │ ⛽ Diesel: ₹11,200           │   │
│ │    680 km ÷ 5.2 km/L         │   │
│ │    × ₹85.50/L (Maharashtra)  │   │
│ │                               │   │
│ │ 🛣 Tolls: ₹4,180             │   │
│ │    ~11 plazas × ₹380/plaza   │   │
│ │    (3-axle rate)              │   │
│ │                               │   │
│ │ ─────────────────────────     │   │
│ │ Total Trip Cost: ₹15,380     │   │
│ │ Mileage: 5.2 km/L (loaded)   │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [🗺 Open in Google Maps]          │
│ (PrimaryButton, full width)        │
└────────────────────────────────────┘
```

### 2.2 Map Implementation
- **Library:** `flutter_map` with OpenStreetMap tiles (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
- **Polyline:** Decoded from OSRM route response. Color: `primaryBlue`, width: 4px.
- **Markers:** Green circle pin (origin), Red circle pin (destination).
- **Bounds:** Auto-fit map to show full route with 50px padding.
- **No user interaction needed:** Map is static, non-draggable in V1 (to keep it simple). Just shows the route.

### 2.3 OSRM Integration
```
GET https://router.project-osrm.org/route/v1/driving/{originLng},{originLat};{destLng},{destLat}?overview=full&geometries=polyline
```
- Returns: `distance` (meters), `duration` (seconds), `geometry` (encoded polyline).
- **Offline Fallback:** If OSRM fails or lat/lng unavailable → Haversine straight-line distance:
  ```
  haversineKm = 2 × R × asin(sqrt(sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlng/2)))
  ```
  Multiply by 1.3 for road factor.

---

## 3. Trip Cost Engine (USP)

### 3.1 Complete Formula
```
dieselCost = (distanceKm / dynamicMileage) × dieselPricePerLitre
tollCost = numberOfPlazas × tollRatePerPlaza
totalTripCost = dieselCost + tollCost
```

### 3.2 Dynamic Mileage
Interpolates between empty and loaded mileage based on actual load weight:
```dart
double dynamicMileage(double loadWeightKg, TruckModelSpec spec) {
  if (spec.payloadKg == null || spec.payloadKg == 0) return spec.mileageEmptyKmpl ?? 2.5;
  final loadRatio = (loadWeightKg / spec.payloadKg).clamp(0.0, 1.0);
  return spec.mileageEmptyKmpl - (loadRatio * (spec.mileageEmptyKmpl - spec.mileageLoadedKmpl));
}
```
- If no truck model selected → default 2.5 km/L (heavy truck assumption).

### 3.3 Diesel Price Lookup
- Source: `diesel_prices` table, keyed by `state`.
- Lookup order: origin state → if not found → default ₹90/L.
- Pre-seeded with 34 Indian states.
- Updated manually via admin or API (out of scope for V1).

### 3.4 Toll Estimation
```dart
int numberOfPlazas(double distanceKm) => (distanceKm / 60).round().clamp(0, 50);

double tollRatePerPlaza(int axles) {
  switch (axles) {
    case 2: return 115.0;   // Light commercial
    case 3: return 190.0;   // Medium
    case 4: return 280.0;   // Heavy (most common)
    case 5: return 380.0;   // Multi-axle
    case 6: return 475.0;   // Oversized
    default: return 280.0;  // Default to 4-axle
  }
}
```
- Axle count from `truck_models.axles` or default 4.
- This is a rough estimate — actual tolls vary by highway.

### 3.5 Where Trip Cost Appears
| Location | Data Available | Display |
|----------|---------------|---------|
| `RichLoadCard` (Find Loads) | distance_km from load row | "⛽ Est. Cost: ₹15,380" |
| Load Detail screen | distance_km + truck specs if trucker has trucks | Full breakdown card |
| Route Preview screen | All data | Detailed breakdown |
| Chat map_card | distance_km from load | Single line summary |

### 3.6 When Cost Cannot Be Calculated
- If `distance_km` is null (no OSRM data, no lat/lng) → show "Trip cost unavailable" in gray.
- If trucker has no trucks → use default 2.5 km/L, 4-axle.
- Always show something — offline defaults (₹90/L, 2.5 km/L) ensure cost is always estimable when distance is known.

---

## 4. Deep Linking to Google Maps

### 4.1 Navigation Button
On trip screens when `stage = 'in_transit'`:
```
[🗺 Navigate with Google Maps]
(PrimaryButton, full width)
```

### 4.2 URL Construction
```dart
final url = 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving';
await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
```

### 4.3 Fallback
- If Google Maps not installed → opens in browser.
- If no lat/lng for destination → show "Navigation unavailable. Open Google Maps manually."

---

## 5. Push Notifications (FCM)

### 5.1 Architecture
```
App Event → Edge Function → FCM API → User's Device
```
- FCM token stored in `profiles.push_token`.
- Token refreshed on every app launch → `UPDATE profiles SET push_token = ? WHERE id = auth.uid()`.

### 5.2 Complete Notification Triggers
| # | Event | Recipient | Title | Body | Deep Link |
|---|-------|-----------|-------|------|-----------|
| 1 | Trucker books load | Supplier | "New Booking Request" | "{name} wants to book your {material} load" | `/load-detail/{loadId}` |
| 2 | Supplier approves | Trucker | "Booking Approved!" | "Head to pickup for {material} {origin}→{dest}" | `/trip-detail/{tripId}` |
| 3 | Supplier rejects | Trucker | "Booking Rejected" | "Your booking for {material} was not approved" | `/find-loads` |
| 4 | Trucker starts trip | Supplier | "Trip Started" | "{name} has started the trip to {dest}" | `/load-detail/{loadId}` |
| 5 | Trucker marks delivered | Supplier | "Cargo Delivered" | "{name} has delivered at {dest}" | `/load-detail/{loadId}` |
| 6 | POD uploaded | Supplier | "POD Uploaded" | "Review proof of delivery for {material}" | `/load-detail/{loadId}` |
| 7 | Supplier confirms delivery | Trucker | "Trip Completed!" | "Rate your experience" | `/trip-detail/{tripId}` |
| 8 | Auto-complete 48h | Both | "Trip Auto-Completed" | "Trip completed automatically" | `/trip-detail/{tripId}` |
| 9 | Admin verifies user | User | "Account Verified" | "You can now use all TranZfort features" | `/profile` |
| 10 | Admin rejects verification | User | "Verification Update" | "Please re-upload your documents" | `/supplier-verification` or `/trucker-verification` |
| 11 | Admin verifies truck | Trucker | "Truck Verified" | "{truckNumber} has been approved" | `/my-fleet` |
| 12 | New chat message | Recipient | "New Message" | "{name}: {preview}" | `/chat/{conversationId}` |
| 13 | Super Load status change | Supplier | "Super Load Update" | "Your super load is now {status}" | `/load-detail/{loadId}` |
| 14 | Support ticket reply | User | "Support Reply" | "Your ticket has a new response" | `/support-ticket/{ticketId}` |

### 5.3 Notification Data Payload
```json
{
  "title": "Booking Approved!",
  "body": "Head to pickup for Coal Chandrapur→Mumbai",
  "data": {
    "type": "booking_approved",
    "load_id": "uuid-here",
    "trip_id": "uuid-here",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

### 5.4 In-App Handling
1. App receives FCM message → parse `data.type`.
2. If app is in foreground → show in-app banner (Snackbar or overlay).
3. If app is in background → show system notification.
4. Tap notification → deep-link to relevant screen using `data.load_id`/`data.trip_id`.

---

## 6. In-App Notifications Screen (`/notifications`)

```
┌────────────────────────────────────┐
│ Notifications           [Mark All] │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ 🔵 Booking Approved!        │   │
│ │ Head to pickup for Coal...   │   │
│ │ 5 min ago                    │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ Account Verified              │   │
│ │ You can now post loads.       │   │
│ │ 2h ago                        │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ New Message from Suresh       │   │
│ │ "Haan bhai, kal aa raha"     │   │
│ │ 3h ago                        │   │
│ └──────────────────────────────┘   │
└────────────────────────────────────┘
```

- **Data Source:** `notifications` table, `WHERE user_id = auth.uid() ORDER BY created_at DESC`.
- **Unread:** Blue dot on left side. Tapping marks as read.
- **"Mark All Read":** Button in AppBar → `UPDATE notifications SET is_read = true WHERE user_id = auth.uid()`.
- **Deep Link:** Tapping a notification navigates using `data` JSONB payload.
- **Empty State:** `EmptyStateView("No notifications yet", "You'll see updates about your loads and trips here.")`

---

## 7. Offline City Search

### 7.1 Asset: `indian_cities` JSON
- Bundled in `assets/data/` as JSON array.
- ~7,000 Indian cities with `name`, `state`, `lat`, `lng`.
- Loaded into memory on app start → indexed by `name_lower`.

### 7.2 Search Implementation
```dart
List<City> searchCities(String query) {
  final q = query.toLowerCase().trim();
  if (q.length < 2) return [];
  return cities.where((c) => c.nameLower.contains(q)).take(20).toList();
}
```

### 7.3 Where Used
| Feature | Autocomplete Source |
|---------|-------------------|
| Post Load (Supplier) | Google Places API (primary) → Offline JSON (fallback) |
| Find Loads filters (Trucker) | Offline JSON only (no Google Places for truckers) |
| Bot slot-filling (city extraction) | Offline JSON + Levenshtein fuzzy matching |

---

## 8. Settings Screen (`/settings`)

```
┌────────────────────────────────────┐
│ [←] Settings                       │
├────────────────────────────────────┤
│ § General                          │
│ Language          [English ▼]      │
│ (only English in V1)               │
├────────────────────────────────────┤
│ § Voice & Bot                      │
│ TTS Mute          [toggle off]     │
│ (Mutes all auto-speak)             │
├────────────────────────────────────┤
│ § Notifications                    │
│ Push Notifications [toggle on]     │
│ (Master toggle)                    │
├────────────────────────────────────┤
│ § Account                          │
│ [My Profile →]                     │
│ [Verification Status →]            │
│ [Payout Profile →] (supplier only) │
├────────────────────────────────────┤
│ § Support                          │
│ [Help & Support →]                 │
│ [Privacy Policy →]                 │
│ [Terms of Service →]               │
├────────────────────────────────────┤
│ § Data                             │
│ App Version: 1.0.0                 │
│ [Delete Account]                   │
│ (red text, confirmation dialog)    │
├────────────────────────────────────┤
│ [Sign Out]                         │
│ (OutlineButton, red)               │
└────────────────────────────────────┘
```

### 8.1 Settings Storage
| Setting | Storage | Default |
|---------|---------|---------|
| TTS Mute | `SharedPreferences('tts_muted')` | `false` |
| Push Notifications | `SharedPreferences('push_enabled')` | `true` |
| Language | `profiles.preferred_language` | `'en'` |

### 8.2 Delete Account
1. User taps "Delete Account" → confirmation dialog: "This will permanently delete your account and all data. This cannot be undone."
2. Tap "Delete" → sets `profiles.data_deletion_requested_at = NOW()`.
3. Sign out user → navigate to `/auth`.
4. Admin processes deletion request within 30 days (DPDP compliance).
5. Edge Function or manual process: delete user from `auth.users` → cascade deletes all related records.

### 8.3 Sign Out
1. `Supabase.auth.signOut()`.
2. `invalidateAllUserProviders()`.
3. Clear `SharedPreferences` (except `has_seen_splash`).
4. Navigate to `/auth`.

---

## 9. State Management (Riverpod)

| Provider | State | Intents |
|----------|-------|---------|
| `routePreviewProvider(loadId)` | `AsyncValue<RoutePreviewData>` | `loadRoute()` |
| `tripCostingProvider` | `TripCostingService` (singleton) | `estimate(distanceKm, weightTonnes, truckSpec, originState)` |
| `notificationsProvider` | `AsyncValue<List<AppNotification>>` | `loadNotifications()`, `markRead(id)`, `markAllRead()` |
| `settingsProvider` | `{ttsMuted, pushEnabled, language}` | `toggleTts()`, `togglePush()`, `setLanguage(lang)` |
| `fcmTokenProvider` | `String?` | `refreshToken()` |
