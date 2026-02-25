# 05: Marketplace & Bulk Loads

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define every screen, field, filter, card layout, and data flow for the marketplace — from posting loads to finding and browsing them. A junior developer should build the entire marketplace from this document.

---

## 1. The Bulk Load Model (Parent/Child)

Suppliers do NOT post 50 individual loads for a 50-truck requirement. They post **1 Parent Load** with `trucks_needed = 50`. The system tracks fulfillment by creating **Child Loads** when a trucker books.

### Key DB Fields (from `loads` table)
| Field | Purpose |
|-------|---------|
| `parent_load_id` | NULL for the Parent Load. Set to the Parent's ID for all Child Loads. |
| `trucks_needed` | Total trucks required (set on Parent Load). |
| `trucks_booked` | Counter incremented by `book_load` RPC on the Parent Load. |
| `assigned_trucker_id` | Set on the Child Load for the specific booking. |
| `assigned_truck_id` | Set on the Child Load for the specific booking. |

### Bulk Load Rules
- A **Parent Load** represents the supplier's overall requirement. It stays `active` until `trucks_booked >= trucks_needed`, then transitions to `booked`.
- When a trucker books, the `book_load` RPC creates a **Child Load** with `status = 'pending_approval'`.
- The supplier approves the **Child Load**, which creates a `trips` record.

---

## 2. Supplier: Post Load Flow (`/post-load`)

### 2.1 Screen Layout — 4-Step Wizard
The form uses a `Stepper` widget with horizontal progress indicator at the top.

#### Step 1: Route
```
┌────────────────────────────────────┐
│ [←] Post Load         Step 1 of 4 │
│ ═══●═══○═══○═══○                   │
├────────────────────────────────────┤
│ § Origin City                      │
│ [Chandrapur, Maharashtra    ▼]    │
│ (Google Places Autocomplete,       │
│  captures lat/lng on select)       │
├────────────────────────────────────┤
│ § Destination City                 │
│ [Mumbai, Maharashtra        ▼]    │
│ (Google Places Autocomplete)       │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ 📍 Chandrapur → Mumbai      │   │
│ │ ~680 km · ~12h (if OSRM ok) │   │
│ │ [Static mini-map polyline]   │   │
│ └──────────────────────────────┘   │
│ (Route preview card, appears       │
│  after both cities selected)       │
├────────────────────────────────────┤
│ [Next: Cargo Details]              │
│ (PrimaryButton, disabled until     │
│  both cities filled)               │
└────────────────────────────────────┘
```

**City Autocomplete Logic:**
- Primary: Google Places API (online, returns lat/lng).
- Fallback: Offline JSON city search (`indian_cities` asset) — returns city/state, no lat/lng.
- If lat/lng available → fetch OSRM route → show distance/duration/polyline preview.
- If lat/lng unavailable → show "Distance unavailable" (cost estimation uses offline defaults).

#### Step 2: Cargo
```
┌────────────────────────────────────┐
│ [←] Post Load         Step 2 of 4 │
│ ═══✓═══●═══○═══○                   │
├────────────────────────────────────┤
│ § Material                         │
│ [Coal ▼]                           │
│ (Dropdown: Coal, Steel, Cement,    │
│  Iron Ore, Limestone, Sand,        │
│  Grain, Rice, Wheat, Sugar,        │
│  Fertilizer, Cotton, Timber,       │
│  Chemicals, Petroleum, Other)      │
├────────────────────────────────────┤
│ § Weight per Truck (Tonnes)        │
│ [25.00]                            │
│ (Decimal input, > 0, max 100)     │
├────────────────────────────────────┤
│ [Next: Vehicle Requirements]       │
└────────────────────────────────────┘
```

#### Step 3: Vehicle Requirements
```
┌────────────────────────────────────┐
│ [←] Post Load         Step 3 of 4 │
│ ═══✓═══✓═══●═══○                   │
├────────────────────────────────────┤
│ § Truck Body Type                  │
│ [Open ▼]                           │
│ (Dropdown: Open, Container,        │
│  Trailer, Tanker, Refrigerated,    │
│  Any)                              │
├────────────────────────────────────┤
│ § Tyres Required                   │
│ [☐ 6] [☑ 10] [☑ 12] [☐ 14]      │
│ [☐ 16] [☐ 18] [☐ 22] [☐ Any]    │
│ (Multi-select chips)               │
├────────────────────────────────────┤
│ [Next: Price & Trucks]             │
└────────────────────────────────────┘
```

#### Step 4: Price & Scale
```
┌────────────────────────────────────┐
│ [←] Post Load         Step 4 of 4 │
│ ═══✓═══✓═══✓═══●                   │
├────────────────────────────────────┤
│ § Total Price (₹)                  │
│ [62500]                            │
│ (Numeric input, > 0)              │
├────────────────────────────────────┤
│ § Price Type                       │
│ (○) Fixed  (●) Negotiable         │
├────────────────────────────────────┤
│ § Advance Percentage               │
│ [80] %                             │
│ (Slider 0-100, default 80)        │
│ "Advance: ₹50,000 · Balance:      │
│  ₹12,500 on delivery"             │
├────────────────────────────────────┤
│ § Pickup Date                      │
│ [Tomorrow, 28 Feb 2026 ▼]        │
│ (Date picker, min: today)          │
├────────────────────────────────────┤
│ § How many trucks do you need?     │
│ [1] [5] [10] [25] [Custom: __]   │
│ (Chip selector, default: 1)       │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ REVIEW SUMMARY               │   │
│ │ Chandrapur → Mumbai          │   │
│ │ Coal · 25T · Open 10/12 Tyre│   │
│ │ ₹62,500 · 80% Advance       │   │
│ │ 50 Trucks · Pickup: 28 Feb  │   │
│ │ [Route map preview]          │   │
│ │ Est. Trip Cost: ₹15,200     │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [Post Load]                        │
│ (PrimaryButton, full width)        │
└────────────────────────────────────┘
```

### 2.2 Form Fields & Validation Summary
| Field | DB Column | Validation | Required? |
|-------|-----------|-----------|-----------|
| Origin City | `loads.origin_city` + `origin_state` | Min 2 chars, from autocomplete | Yes |
| Destination City | `loads.dest_city` + `dest_state` | Min 2 chars, from autocomplete | Yes |
| Origin Lat/Lng | `loads.origin_lat` + `origin_lng` | Auto from Google Places (nullable) | Auto |
| Dest Lat/Lng | `loads.dest_lat` + `dest_lng` | Auto (nullable) | Auto |
| Material | `loads.material` | Must select from dropdown | Yes |
| Weight | `loads.weight_tonnes` | Decimal, > 0, ≤ 100 | Yes |
| Body Type | `loads.required_truck_type` | Enum or NULL (Any) | No |
| Tyres | `loads.required_tyres` | Array of ints or empty (Any) | No |
| Price | `loads.price` | Decimal, > 0 | Yes |
| Price Type | `loads.price_type` | `fixed` or `negotiable` | Yes |
| Advance % | `loads.advance_percentage` | Int 0-100 | Yes |
| Pickup Date | `loads.pickup_date` | Date, ≥ today | Yes |
| Trucks Needed | `loads.trucks_needed` | Int, ≥ 1 | Yes |

### 2.3 On Submit (DB Actions)
1. INSERT into `loads` with all fields above.
2. If lat/lng available → OSRM fetch → store `distance_km`, `duration_hours`, `route_polyline`.
3. `status = 'active'`, `trucks_booked = 0`.
4. Increment `suppliers.total_loads_posted` and `active_loads_count`.
5. Push notification to relevant truckers (if FCM deployed).

### 2.4 Bot Post Load (Alternative — 5 Questions)
Supplier opens bot → says "Post load" or "Load dalna hai":
1. Bot asks: **Origin?** → "Chandrapur"
2. Bot asks: **Destination?** → "Mumbai"
3. Bot asks: **Material?** → "Coal"
4. Bot asks: **Weight?** → "25 ton"
5. Bot asks: **Price?** → "62500"
6. Bot shows summary with **smart defaults**: price_type=negotiable, advance=80%, truck_type=Any, tyres=Any, pickup_date=tomorrow, trucks_needed=1.
7. Supplier confirms → load posted.
8. Optional: "More Options" to edit defaults before confirming.

---

## 3. Trucker: Find Loads (`/find-loads`)

This is the trucker's **primary home screen** (not a dashboard).

### 3.1 Screen Layout
```
┌────────────────────────────────────┐
│ Find Loads              [🔔][👤]  │
├────────────────────────────────────┤
│ ┌────────────┐ ┌────────────┐     │
│ │ From:      │ │ To:        │     │
│ │ [Any    ▼] │ │ [Any    ▼] │     │
│ └────────────┘ └────────────┘     │
│ ┌────────────┐ ┌────────────┐     │
│ │ Material:  │ │ Truck:     │     │
│ │ [Any    ▼] │ │ [Any    ▼] │     │
│ └────────────┘ └────────────┘     │
│ [🔍 Search]  [Reset Filters]      │
├────────────────────────────────────┤
│ "245 loads" [Sort: Newest ▼]      │
├────────────────────────────────────┤
│ [RichLoadCard]                     │
│ [RichLoadCard]                     │
│ [RichLoadCard]                     │
│ ... (infinite scroll, 50/page)     │
│ [Loading spinner at bottom]        │
├────────────────────────────────────┤
│ [Find] [My Trips] [Fleet] [Chat]  │
└────────────────────────────────────┘
  [🤖 Bot] (FAB, amber)
```

### 3.2 Filter Logic
| Filter | DB Query | Default |
|--------|----------|---------|
| Origin | `WHERE origin_city ILIKE '%{input}%'` | Any (no filter) |
| Destination | `WHERE dest_city ILIKE '%{input}%'` | Any (no filter) |
| Material | `WHERE material = '{selected}'` | Any |
| Truck Type | `WHERE required_truck_type = '{selected}' OR required_truck_type IS NULL` | Any |

**Filter Rules:**
- Changing any filter resets `currentPage = 1` and triggers a fresh search.
- City filters use **offline JSON city search** (not Google Places — that's supplier-only).
- Sort options: Newest (default), Price High→Low, Price Low→High, Pickup Date.
- Result count shown: "245 loads found".
- Pagination: 50 loads per page, infinite scroll with spinner at bottom.

### 3.3 Truck Match Badge
If the trucker has verified trucks, the card shows which of their trucks match the load requirements:
- Green badge: "✓ Tata 407 matches" (body type + tyre count match).
- No badge if no match (card still shown, trucker can still book with any verified truck).

### 3.4 Empty State
`EmptyStateView("No loads found", "Try changing your filters or check back later.")`

---

## 4. The Rich Load Card (`RichLoadCard`)

The most important UI widget in the entire app. Used on Find Loads, My Loads, Load Detail header, and Chat map card.

### 4.1 Complete Data Hierarchy
```
┌────────────────────────────────────┐
│ [⭐ SUPER LOAD] [🛡 VERIFIED]  2h │
│ (gold pill)    (blue pill)  (gray) │
├────────────────────────────────────┤
│ 🟢 Chandrapur, MH                 │
│  │                    ≈ 680 km     │
│ 🔴 Mumbai, MH                     │
│                 [faded polyline bg]│
├────────────────────────────────────┤
│ ⛏ Coal · ⚖ 25T · 🚛 Open 10/12T │
│ 📅 Pickup: 28 Feb                 │
├────────────────────────────────────┤
│ ₹2,500/T    Total: ₹62,500       │
│ (bodyMedium)  (headlineMedium,    │
│               bold, primary)       │
│ Advance: 80% (₹50,000)            │
│ ⛽ Est. Trip Cost: ₹15,200        │
│ (bodySmall, success color — USP)   │
├────────────────────────────────────┤
│ [💬 Chat]      [⚡ Book Load]     │
│ (OutlineButton) (PrimaryButton,   │
│                  success color)    │
│ 50 trucks needed · 12 booked      │
│ (bodySmall, gray — bulk only)      │
└────────────────────────────────────┘
```

### 4.2 Card Data Fields
| Section | Field | Source | Fallback |
|---------|-------|--------|----------|
| Badge: Super | `loads.is_super_load` | Gold pill | Hidden |
| Badge: Verified | `profiles.verification_status` (via join on supplier) | Blue pill | Hidden |
| Badge: Time | `loads.created_at` | TimeAgo format | "Just now" |
| Route: Origin | `loads.origin_city`, `origin_state` | — | Required |
| Route: Dest | `loads.dest_city`, `dest_state` | — | Required |
| Route: Distance | `loads.distance_km` | OSRM | "—" if null |
| Cargo: Material | `loads.material` | — | Required |
| Cargo: Weight | `loads.weight_tonnes` | — | Required |
| Cargo: Truck | `loads.required_truck_type` | Enum name | "Any" if null |
| Cargo: Tyres | `loads.required_tyres` | Array joined | "Any" if empty |
| Cargo: Pickup | `loads.pickup_date` | Date format | Required |
| Price: Rate | Computed: `price / weight_tonnes` | — | Show total only |
| Price: Total | `loads.price` | — | Required |
| Price: Advance | `loads.advance_percentage` | — | "—" if null |
| Cost: Trip Est | `TripCostingService.estimate()` | Offline defaults | Always shown |
| Bulk: Progress | `trucks_booked / trucks_needed` | — | Hidden if `trucks_needed = 1` |

### 4.3 Trip Cost Estimate (USP Calculation)
This is calculated **client-side** using `TripCostingService`:
```
dieselCost = distance_km / dynamicMileage(loadWeight, truckMileage) × dieselPrice
tollCost = numberOfPlazas(distance_km) × tollRatePerPlaza(axleCount)
totalTripCost = dieselCost + tollCost
```
- `dynamicMileage()`: Interpolates between empty/loaded based on `weight_tonnes` vs. truck `payload_kg`.
- `dieselPrice`: From `diesel_prices` table (origin state) or ₹90/L default.
- `numberOfPlazas`: ~1 per 60km of distance.
- `tollRatePerPlaza`: Based on axle count (2-axle: ₹115, 3-axle: ₹190, etc.).
- **If distance_km is null** (no OSRM data): Show "Trip cost unavailable" in gray.
- **Offline defaults always work:** ₹90/L diesel, 2.5 km/L mileage.

---

## 5. Load Detail Screen (`/load-detail/:loadId`)

### 5.1 Trucker View
```
┌────────────────────────────────────┐
│ [←] Coal: Chandrapur → Mumbai      │
├────────────────────────────────────┤
│ [Route Map Preview - flutter_map]  │
│ (Static polyline, origin/dest pins)│
│ Height: 200px                      │
├────────────────────────────────────┤
│ [Full RichLoadCard content]        │
│ (without action row)               │
├────────────────────────────────────┤
│ § Trip Cost Breakdown              │
│ ┌──────────────────────────────┐   │
│ │ ⛽ Diesel: ₹11,200 (~680km) │   │
│ │ 🛣 Tolls: ₹4,000 (~11 plazas)│  │
│ │ ─────────────────────────     │   │
│ │ Total: ₹15,200               │   │
│ │ Mileage: 5.2 km/L (loaded)   │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ § Supplier Info                    │
│ ┌──────────────────────────────┐   │
│ │ [Avatar] Rajesh Industries   │   │
│ │ [✓ VERIFIED] · ⭐ 4.5 (23)  │   │
│ │ Member since Jan 2026        │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [💬 Chat with Supplier]           │
│ (OutlineButton, full width)        │
│ [⚡ Book This Load]               │
│ (PrimaryButton, success, full w.)  │
│ [🗺 Open in Google Maps]          │
│ (Text button, gray)               │
└────────────────────────────────────┘
```

### 5.2 Supplier View (Own Load Detail)
```
┌────────────────────────────────────┐
│ [←] Coal: Chandrapur → Mumbai      │
├────────────────────────────────────┤
│ [Route Map Preview]                │
│ [Load Info Summary]                │
├────────────────────────────────────┤
│ § Fulfillment: 12 / 50 trucks     │
│ [████████░░░░░░░░░] 24%           │
│ (Progress bar, primary color)      │
├────────────────────────────────────┤
│ § Pending Approval (3)             │
│ ┌──────────────────────────────┐   │
│ │ Suresh · MH 12 AB 1234      │   │
│ │ Tata 407 · Open · 6T         │   │
│ │ [RC thumb] [Approve] [Reject]│   │
│ └──────────────────────────────┘   │
│ (repeat for each pending booking)  │
├────────────────────────────────────┤
│ § In Transit (5)                   │
│ [Trip card with status + location] │
├────────────────────────────────────┤
│ § Delivered (4)                    │
│ [Trip card with POD thumbnail]     │
├────────────────────────────────────┤
│ [Edit Load] [Deactivate Load]      │
│ [Make Super] (if not already)      │
└────────────────────────────────────┘
```

---

## 6. Supplier: My Loads (`/my-loads`)

### 6.1 Screen Layout
```
┌────────────────────────────────────┐
│ My Loads                [🔔][👤]  │
├────────────────────────────────────┤
│ [Active (5)] [Completed (47)]     │
│ (Tab bar)                          │
├────────────────────────────────────┤
│ Active Tab:                        │
│ ┌──────────────────────────────┐   │
│ │ Coal: Chandrapur → Mumbai    │   │
│ │ 25T · ₹62,500 · Open        │   │
│ │ [████░░░░░] 12/50 trucks     │   │
│ │ [FULFILLING] (amber badge)   │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ Steel: Jamshedpur → Kolkata  │   │
│ │ 10T · ₹45,000 · Container   │   │
│ │ 0/1 trucks                   │   │
│ │ [WAITING] (gray badge)       │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [Home] [My Loads] [Super] [Chat]   │
└────────────────────────────────────┘
```

### 6.2 Load Card (Supplier Version)
Simpler than `RichLoadCard` — focused on fulfillment progress:
- Route (origin → destination)
- Cargo summary (material · weight · truck type)
- Price
- **Progress bar:** `trucks_booked / trucks_needed`
- **Status Badge:**
  - `trucks_booked == 0`: "WAITING" (gray)
  - `0 < trucks_booked < trucks_needed`: "FULFILLING" (amber)
  - `trucks_booked >= trucks_needed`: "FULLY BOOKED" (green)
  - `status == 'in_transit'`: "IN TRANSIT" (amber)
  - `status == 'completed'`: "COMPLETED" (green)
  - `status == 'cancelled'`: "CANCELLED" (gray)

### 6.3 Completed Tab
Shows loads with `status IN ('completed', 'cancelled', 'expired')`.

### 6.4 Load Actions
| Action | When Available | What It Does |
|--------|---------------|-------------|
| Tap card | Always | Navigate to Load Detail |
| Edit Load | `status = 'active'` only | Navigate to edit form (same 4-step wizard, pre-filled) |
| Deactivate | `status = 'active'` only | Confirmation dialog → `status = 'cancelled'` |
| Make Super | `status = 'active'`, not already super | Navigate to Super Load Request screen |

---

## 7. Booking Flow (Trucker Side)

When trucker taps "Book This Load" on a load card or detail screen:

### 7.1 Single Truck
If trucker has exactly 1 verified truck:
1. Auto-select that truck.
2. Confirmation bottom sheet: "Book [Material] load from [Origin] to [Dest] with [Truck Number]?"
3. Tap "Confirm" → call `book_load` RPC.
4. GPS captured (bounded trigger #1: acceptance).

### 7.2 Multiple Trucks
If trucker has 2+ verified trucks:
1. Bottom sheet: "Select a truck for this load"
2. List of verified trucks with match badges (green if body/tyres match).
3. Trucker taps one → confirmation.
4. Call `book_load` RPC + GPS capture.

### 7.3 No Verified Trucks
- Show dialog: "You need a verified truck to book loads. Add a truck now?"
- CTA: "Add Truck" → navigate to `/add-truck`.

### 7.4 Post-Booking
- On success → Snackbar: "Load booked! Waiting for supplier approval."
- Push notification sent to supplier.
- Load card shows updated `trucks_booked` count.
- Trucker sees the load in My Trips with `pending_approval` status.

### 7.5 Error States
| Error | Message |
|-------|---------|
| Load no longer active | "This load is no longer available." |
| Load fully booked | "All trucks for this load have been booked." |
| Already booked | "You've already booked this load." |
| Truck not verified | "Your truck is pending verification." |
| Network error | "Please check your internet connection." |

---

## 8. State Management (Riverpod)

| Provider | State | Intents |
|----------|-------|---------|
| `postLoadProvider` | `{isSubmitting, currentStep, formData, lastError}` | `nextStep()`, `prevStep()`, `submitLoad()` |
| `findLoadsProvider` | `{isSearching, isLoadingMore, results, currentPage, hasMorePages, filters, myTrucks}` | `search(filters)`, `loadMore()`, `resetFilters()`, `loadMyTrucks()` |
| `myLoadsProvider` | `AsyncValue<List<Load>>` | `loadActiveLoads()`, `loadCompletedLoads()`, `deactivateLoad(id)` |
| `loadDetailProvider(id)` | `AsyncValue<LoadDetail>` | `loadDetail()`, `approveBooking(loadId)`, `rejectBooking(loadId)` |
| `bookLoadProvider` | `{isBooking, lastError}` | `bookLoad(loadId, truckId)` |
| `bookLoadProvider` | `{isBooking, lastError}` | `bookLoad(loadId, truckId)` |
