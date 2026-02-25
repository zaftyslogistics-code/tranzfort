# 06: Booking Engine & Trip Execution

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define every state transition, screen layout, GPS trigger, document upload, rating flow, and payment model from the moment a trucker taps "Book" to the final trip completion and rating. A junior developer should build the entire booking-to-trip lifecycle from this document.

---

## 1. Complete Lifecycle Diagram

```
MARKETPLACE                    BOOKING                         TRIP EXECUTION
───────────                    ───────                         ──────────────
Supplier posts load            Trucker taps "Book Load"        Trip created (stage: at_pickup)
loads.status = 'active'   ──→  book_load RPC fires        ──→  Trucker taps "Start Trip"
                               loads.status = 'booked'         trips.stage = 'in_transit'
                               trucks_booked++                 loads.status = 'in_transit'
                               Push notif → Supplier           GPS Trigger #2
                                    │                               │
                               Supplier reviews                Trucker drives to dest
                               ┌─────┴─────┐                       │
                           [Approve]    [Reject]               Trucker taps "Mark Delivered"
                               │           │                   trips.stage = 'delivered'
                          Trip created   Load reverts               │
                          stage=at_pickup to 'active'          Trucker uploads POD
                          GPS Trigger #1  trucks_booked--      trips.stage = 'pod_uploaded'
                          Push → Trucker  Push → Trucker       Push notif → Supplier
                                                                    │
                                                               Supplier confirms OR
                                                               Auto-complete after 48h
                                                               trips.stage = 'completed'
                                                               loads.status = 'completed'
                                                                    │
                                                               Rating prompt (both sides)
```

---

## 2. The Booking Handshake

### 2.1 Trucker Books (`book_load` RPC)
When trucker taps "Book Load":
1. UI calls `bookLoadProvider.bookLoad(parentLoadId, truckId)`.
2. Provider calls `book_load(p_parent_load_id, p_trucker_id, p_truck_id)` RPC.
3. RPC atomically:
   - Locks Parent Load row with `FOR UPDATE`.
   - Validates: `status = 'active'`, `trucks_booked < trucks_needed`, truck is verified.
   - Creates a **Child Load** with `status = 'pending_approval'`.
   - Increments `trucks_booked` on Parent Load.
   - If `trucks_booked >= trucks_needed` → Parent Load `status = 'booked'`.
4. On success → Snackbar: "Load booked! Waiting for supplier approval."
5. **GPS Trigger #1 (Acceptance):** Capture trucker's current lat/lng → save to `profiles.last_known_lat/lng`.
6. Push notification → Supplier: "New booking request for [Material] [Origin→Dest]".

### 2.2 Supplier Approves (`approve_booking` RPC)
Supplier sees pending Child Load booking in Load Detail (§5.2 of 05_MARKETPLACE) and taps "Approve":
1. UI calls `loadDetailProvider.approveBooking(childLoadId)`.
2. RPC atomically:
   - Creates `trips` row with `load_id = childLoadId`, `trucker_id`, `truck_id`, `stage = 'at_pickup'`.
   - Child Load status becomes `'booked'` (transitions to `'in_transit'` when trucker starts trip).
3. Push notification → Trucker: "Booking approved! Head to pickup."
4. **TTS (Trucker):** "Booking manjoor ho gaya. Pickup ki taraf chalein."

### 2.3 Supplier Rejects (`reject_booking` RPC)
1. RPC:
   - Child Load status becomes `'cancelled'`.
   - Decrements `trucks_booked` on the Parent Load.
   - Sets Parent Load `status = 'active'` (slot freed).
2. Push notification → Trucker: "Booking rejected for [Material] [Origin→Dest]."
3. **TTS (Trucker):** "Booking reject ho gaya. Doosra load dhundein."

---

## 3. Trip Execution — Stage by Stage

### 3.1 Stage: `at_pickup`
**What it means:** Trip created, trucker heading to or at pickup location.

```
┌────────────────────────────────────┐
│ [←] Trip: Coal Chandrapur → Mumbai │
├────────────────────────────────────┤
│ [Route Map - flutter_map]          │
│ (Polyline, origin pin, dest pin,   │
│  trucker current location pin)     │
│ Height: 200px                      │
├────────────────────────────────────┤
│ STATUS: AT PICKUP                  │
│ (amber badge, large)               │
├────────────────────────────────────┤
│ [RichLoadCard summary]             │
├────────────────────────────────────┤
│ § Trip Cost Estimate               │
│ ⛽ Diesel: ₹11,200 · 🛣 Tolls: ₹4K│
│ Total: ₹15,200                     │
├────────────────────────────────────┤
│ § Upload LR (Optional)             │
│ [📷 Upload Lorry Receipt]          │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ 🚀 Start Trip               │   │
│ │ (PrimaryButton, success,     │   │
│ │  full width)                 │   │
│ └──────────────────────────────┘   │
│ [💬 Chat with Supplier]           │
│ [📞 Call Supplier]                │
└────────────────────────────────────┘
```

**Trucker taps "Start Trip":**
1. Confirmation dialog: "Confirm you have loaded the cargo and are ready to start?"
2. Calls `start_trip` RPC → `trips.stage = 'in_transit'`, `trips.start_time = NOW()`.
3. Updates `loads.status = 'in_transit'`.
4. **GPS Trigger #2 (Trip Start):** Capture lat/lng → save to `trips.last_known_lat/lng`.
5. Push notification → Supplier: "Trucker has started the trip."

### 3.2 Stage: `in_transit`
**What it means:** Trucker is driving with cargo. This is the main tracking stage.

```
┌────────────────────────────────────┐
│ [←] Trip: Coal Chandrapur → Mumbai │
├────────────────────────────────────┤
│ [Route Map with live position]     │
│ (Trucker pin moves along polyline) │
│ ETA: ~8h · 420 km remaining       │
├────────────────────────────────────┤
│ STATUS: IN TRANSIT                 │
│ (primary badge, animated pulse)    │
├────────────────────────────────────┤
│ Started: 28 Feb 2026, 06:30 AM    │
│ Duration so far: 4h 15m            │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ ✅ Mark Delivered            │   │
│ │ (PrimaryButton, success)     │   │
│ └──────────────────────────────┘   │
│ [💬 Chat] [📞 Call]              │
│ [🗺 Open in Google Maps]         │
└────────────────────────────────────┘
```

**GPS during in_transit:** No continuous background tracking in V1. GPS is captured ONLY at bounded trigger moments (see §5).

**Trucker taps "Mark Delivered":**
1. Confirmation: "Confirm cargo has been unloaded at destination?"
2. `trips.stage = 'delivered'`.
3. **GPS Trigger #3 (Delivery):** Capture lat/lng.
4. Push → Supplier: "Cargo delivered. Waiting for POD upload."

### 3.3 Stage: `delivered`
**What it means:** Cargo unloaded, trucker needs to upload Proof of Delivery.

```
┌────────────────────────────────────┐
│ [←] Trip: Coal Chandrapur → Mumbai │
├────────────────────────────────────┤
│ [Route Map showing completed route]│
├────────────────────────────────────┤
│ STATUS: DELIVERED                  │
│ (success badge)                    │
├────────────────────────────────────┤
│ Delivered at: 28 Feb, 02:30 PM     │
│ Total time: 8h 00m                 │
├────────────────────────────────────┤
│ § Upload Proof of Delivery         │
│ "Take a photo of the signed POD"   │
│ ┌──────────────────────────────┐   │
│ │ [📷 Upload POD Photo]        │   │
│ │ (PrimaryButton, full width)  │   │
│ └──────────────────────────────┘   │
│ (Opens camera directly)            │
├────────────────────────────────────┤
│ [💬 Chat] [📞 Call]              │
└────────────────────────────────────┘
```

**Trucker uploads POD:**
1. Camera opens → user takes photo → compress 1200×1200 85%.
2. Upload to `load-documents/{load_id}/pod.jpg`.
3. Save URL to `trips.pod_photo_url` and `loads.pod_photo_url`.
4. `trips.stage = 'pod_uploaded'`.
5. **GPS Trigger #4 (POD):** Final lat/lng capture.
6. Push → Supplier: "POD uploaded. Review and confirm delivery."

### 3.4 Stage: `pod_uploaded`
**What it means:** Trucker has uploaded POD, waiting for supplier confirmation.

**Trucker View:**
```
┌────────────────────────────────────┐
│ STATUS: POD UPLOADED               │
│ (amber badge)                      │
├────────────────────────────────────┤
│ [POD Photo preview - full width]   │
│ "Waiting for supplier to confirm"  │
│ (bodyMedium, gray, center)         │
├────────────────────────────────────┤
│ Auto-complete in: 43h 15m          │
│ (Countdown, if supplier doesn't    │
│  confirm within 48h → auto-done)   │
└────────────────────────────────────┘
```

**Supplier View:**
```
┌────────────────────────────────────┐
│ STATUS: POD UPLOADED               │
├────────────────────────────────────┤
│ [POD Photo preview - tappable      │
│  for full-screen zoom]             │
├────────────────────────────────────┤
│ [✅ Confirm Delivery]              │
│ (PrimaryButton, success)           │
│ [❌ Dispute POD]                   │
│ (OutlineButton, error color)       │
└────────────────────────────────────┘
```

**Supplier confirms:**
1. `trips.stage = 'completed'`, `trips.end_time = NOW()`.
2. `loads.status = 'completed'`, `loads.completed_at = NOW()`.
3. Increment `truckers.completed_trips`.
4. Push → Trucker: "Trip completed! Rate your experience."

**Auto-complete (pg_cron):** If supplier doesn't confirm within **48 hours**, `auto_complete_delivered_trips()` sets `stage = 'completed'` automatically.

### 3.5 Stage: `completed`
**What it means:** Trip fully done. Both parties can rate.

```
┌────────────────────────────────────┐
│ STATUS: COMPLETED ✓                │
│ (green badge)                      │
├────────────────────────────────────┤
│ Trip Summary:                      │
│ Duration: 8h 00m                   │
│ Distance: ~680 km                  │
│ Started: 28 Feb 06:30 AM           │
│ Completed: 28 Feb 02:30 PM         │
├────────────────────────────────────┤
│ [POD Photo thumbnail]              │
│ [LR Photo thumbnail] (if uploaded) │
├────────────────────────────────────┤
│ § Rate this [Supplier/Trucker]     │
│ [★ ★ ★ ★ ☆] (1-5 star selector)  │
│ [Optional comment: __________]     │
│ [Submit Rating]                    │
│ (Only shown if not yet rated)      │
└────────────────────────────────────┘
```

---

## 4. My Trips Screen (Trucker) (`/my-trips`)

```
┌────────────────────────────────────┐
│ My Trips                [🔔][👤]  │
├────────────────────────────────────┤
│ [Active (2)] [Completed (15)]     │
│ (Tab bar)                          │
├────────────────────────────────────┤
│ Active Tab:                        │
│ ┌──────────────────────────────┐   │
│ │ Coal: Chandrapur → Mumbai    │   │
│ │ 25T · MH 12 AB 1234         │   │
│ │ [IN TRANSIT] (primary badge) │   │
│ │ Started 4h ago               │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ Steel: Jamshedpur → Kolkata  │   │
│ │ 10T · MH 14 CD 5678         │   │
│ │ [AT PICKUP] (amber badge)    │   │
│ │ Approved 2h ago              │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [Find] [My Trips] [Fleet] [Chat]  │
└────────────────────────────────────┘
```

**Trip Card Data:**
- Route (origin → destination)
- Cargo weight + assigned truck number
- Stage badge (color-coded)
- Time context ("Started 4h ago", "Delivered 1h ago", "Completed 28 Feb")

**Tap → Trip Detail Screen** (per-stage layouts in §3 above).

**Active tab:** Shows trips with `stage IN ('at_pickup', 'in_transit', 'delivered', 'pod_uploaded')`.
**Completed tab:** Shows trips with `stage = 'completed'`.

**Empty State:** `EmptyStateView("No trips yet", "Book a load to start your first trip.", CTA: "Find Loads")`

---

## 5. GPS Bounded Triggers

GPS is captured at EXACTLY 4 moments during a trip. No continuous background tracking in V1.

| Trigger # | Moment | What's Captured | Where Stored |
|-----------|--------|----------------|-------------|
| 1 | **Booking accepted** (trucker taps "Book") | Trucker's current location | `profiles.last_known_lat/lng` |
| 2 | **Trip started** (trucker taps "Start Trip") | Pickup confirmation point | `trips.last_known_lat/lng` |
| 3 | **Marked delivered** (trucker taps "Mark Delivered") | Delivery location | `trips.last_known_lat/lng` |
| 4 | **POD uploaded** (trucker uploads POD) | Final location | `trips.last_known_lat/lng` |

### GPS Capture Implementation
```dart
Future<LatLng?> captureCurrentLocation() async {
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    return null; // Graceful fallback — trip continues without GPS
  }
  final pos = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 10),
  );
  return LatLng(pos.latitude, pos.longitude);
}
```

**Rule:** GPS failure NEVER blocks a trip action. If GPS times out or is denied, the trip stage still advances — location just remains null.

---

## 6. Document Uploads

| Document | When | Required? | Storage Path | Max Size |
|----------|------|-----------|-------------|----------|
| LR (Lorry Receipt) | `at_pickup` stage | No | `load-documents/{load_id}/lr.jpg` | 5MB |
| POD (Proof of Delivery) | `delivered` stage | Yes | `load-documents/{load_id}/pod.jpg` | 5MB |

### Upload Flow
1. User taps upload button → bottom sheet: "Camera" or "Gallery".
2. Image captured/selected → compressed to 1200×1200, 85% JPEG.
3. Upload to Supabase Storage → get URL.
4. Save URL to `trips.lr_photo_url` / `trips.pod_photo_url` AND `loads.lr_photo_url` / `loads.pod_photo_url`.
5. Show thumbnail preview on trip card.

---

## 7. Rating Flow

After trip completes, both parties are prompted to rate each other.

### 7.1 Rating Prompt
- **When:** On first visit to completed trip detail, show rating section.
- **Who rates whom:**
  - Supplier rates Trucker (score → updates `truckers.rating` aggregate via trigger).
  - Trucker rates Supplier (stored in `ratings` table, no aggregate in V1).
- **UI:** 5-star selector + optional comment text field.
- **DB:** `INSERT INTO ratings (load_id, reviewer_id, reviewee_id, reviewer_role, score, comment)`.
- **Constraint:** One rating per reviewer per load (UNIQUE on `load_id, reviewer_id`).

### 7.2 Rating Impact
- Trucker's aggregate rating is auto-updated via `trg_update_trucker_rating` trigger.
- Rating shown on trucker's booking request card (visible to suppliers).
- No minimum rating requirement in V1 (no deactivation for low ratings).

---

## 8. Super Loads — TranZfort Guaranteed

### 8.1 How Super Loads Differ
| Aspect | Regular Load | Super Load |
|--------|-------------|-----------|
| Assignment | Supplier approves trucker | Admin assigns trucker |
| Payment | Direct supplier↔trucker | Supplier → TranZfort → Trucker |
| Tracking | Supplier monitors | Admin + Supplier monitor |
| Badge | None | Gold `[⭐ Super Load]` everywhere |
| Payout | Direct negotiation | Advance at pickup, balance at POD |

### 8.2 Super Status Lifecycle
```
none ──→ requested (supplier taps "Make Super" on active load)
          ──→ processing (ops admin picks up from queue)
              ──→ assigned (ops admin assigns trucker + truck)
                  ──→ in_transit (trucker starts trip)
                      ──→ pod_uploaded (trucker uploads POD)
                          ──→ completed (ops admin confirms + marks payout)
```

### 8.3 Supplier Request Flow
1. On active load detail: "Make Super" button.
2. Requires `payout_profiles.status IN ('pending', 'verified')`.
3. Sets `loads.is_super_load = true`, `loads.super_status = 'requested'`.
4. Push notification → Admin team.

### 8.4 Admin Ops Flow (see 09_ADMIN for screens)
1. Admin sees Super Load queue sorted by urgency.
2. Admin reviews load, assigns a verified trucker from pool.
3. `super_status = 'assigned'`, trip created.
4. Admin monitors trip stages.
5. On `pod_uploaded` → admin verifies POD → marks payout → `super_status = 'completed'`.

---

## 9. Push Notifications During Trip

| Event | Recipient | Title | Body |
|-------|-----------|-------|------|
| Trucker books | Supplier | "New Booking Request" | "{trucker_name} wants to book {material} load" |
| Supplier approves | Trucker | "Booking Approved!" | "Head to pickup for {material} {origin}→{dest}" |
| Supplier rejects | Trucker | "Booking Rejected" | "Your booking for {material} was not approved" |
| Trucker starts trip | Supplier | "Trip Started" | "{trucker_name} has started the trip" |
| Trucker marks delivered | Supplier | "Cargo Delivered" | "{trucker_name} has delivered at {dest}" |
| POD uploaded | Supplier | "POD Uploaded" | "Review proof of delivery" |
| Supplier confirms | Trucker | "Trip Completed!" | "Rate your experience" |
| Auto-complete 48h | Both | "Trip Auto-Completed" | "Trip completed automatically" |

---

## 10. State Management (Riverpod)

| Provider | State | Intents |
|----------|-------|---------|
| `bookLoadProvider` | `{isBooking, lastError}` | `bookLoad(loadId, truckId)` |
| `loadDetailProvider(id)` | `AsyncValue<LoadDetail>` | `approveBooking()`, `rejectBooking()` |
| `truckerMyTripsProvider` | `AsyncValue<List<Trip>>` | `loadActiveTrips()`, `loadCompletedTrips()` |
| `tripDetailProvider(id)` | `AsyncValue<TripDetail>` | `loadTripDetail()` |
| `tripActionProvider(id)` | `{isUpdating, lastError}` | `startTrip()`, `markDelivered()`, `uploadPod(image)`, `confirmDelivery()` |
| `ratingProvider` | `{isSubmitting, hasRated}` | `submitRating(loadId, score, comment)` |

### Error Handling Rule
If a stage transition fails (network error during POD upload, RPC timeout):
1. Provider catches error → maps to `AppFailureType`.
2. UI shows Snackbar with mapped message.
3. **Local state does NOT advance.** The button remains available for retry.
4. No optimistic UI updates for trip stage transitions — always wait for server confirmation.
