# 04: User Entities, Verification & Fleet Trust

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define every form field, validation rule, storage path, screen layout, and state transition for user verification, fleet management, and payout profiles. A junior developer should build the entire trust pipeline from this document.

---

## 1. The Trust Model

In Indian trucking, trust is everything. A supplier will not hand ₹10 Lakhs of steel to an unverified trucker.

- **Rule 1:** A user cannot Post Load (supplier) or Book Load (trucker) until `profiles.verification_status = 'verified'`.
- **Rule 2:** Unverified users CAN browse (see active loads, view dashboards) but all marketplace CTAs are replaced with "Verify to Continue" → navigates to verification screen.
- **Rule 3:** A trucker cannot book a load without at least one truck with `trucks.status = 'verified'`.
- **Rule 4:** A supplier cannot request a Super Load without a `payout_profiles` record with `status = 'verified'` (or at least `'pending'`).

### Trust Signals Visible to Other Users
| Signal | Where Shown | Data Source |
|--------|------------|-------------|
| "Verified Supplier" badge (blue) | Load cards, Chat header, Load detail | `profiles.verification_status = 'verified'` |
| "Verified Trucker" badge (blue) | Booking request card | `profiles.verification_status = 'verified'` |
| Trucker rating (1-5 stars) | Booking request card | `truckers.rating` |
| Truck RC photo | Booking request card (supplier view) | `trucks.rc_photo_url` |
| "Super Load" badge (gold) | Load cards | `loads.is_super_load = true` |
| Trip count | Booking request card | `truckers.completed_trips` |

---

## 2. Supplier Verification (`/supplier-verification`)

### 2.1 Screen Layout
```
┌────────────────────────────────────┐
│ [←] Supplier Verification          │
├────────────────────────────────────┤
│ "Complete your verification to     │
│  start posting loads"              │
│ (bodyMedium, gray)                 │
├────────────────────────────────────┤
│ § Company / Individual Name        │
│ [____________________________]     │
│ (TextFormField, required)          │
├────────────────────────────────────┤
│ § Aadhaar Card                     │
│ ┌────────────┐ ┌────────────┐     │
│ │ [📷 Front] │ │ [📷 Back]  │     │
│ │  or preview │ │  or preview│     │
│ └────────────┘ └────────────┘     │
│ Aadhaar Number: [____________]     │
│ (12 digits, numeric only)          │
├────────────────────────────────────┤
│ § PAN Card                         │
│ ┌────────────────────────────┐     │
│ │ [📷 Upload PAN]            │     │
│ └────────────────────────────┘     │
│ PAN Number: [__________]           │
│ (10 chars, format: ABCDE1234F)     │
├────────────────────────────────────┤
│ § Business Licence (Optional)      │
│ ┌────────────────────────────┐     │
│ │ [📷 Upload Licence]        │     │
│ └────────────────────────────┘     │
│ GST Number: [_______________]      │
│ (15 chars, optional)               │
├────────────────────────────────────┤
│ § Profile Photo                    │
│ ┌────────────────────────────┐     │
│ │ [📷 Upload / Take Selfie]  │     │
│ └────────────────────────────┘     │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │  Submit for Verification     │   │
│ │  (PrimaryButton, full width) │   │
│ └──────────────────────────────┘   │
└────────────────────────────────────┘
```

### 2.2 Form Fields & Validation
| Field | DB Column | Type | Validation | Required? |
|-------|-----------|------|-----------|-----------|
| Company Name | `suppliers.company_name` | Text | Min 2 chars, max 255 | Yes |
| Aadhaar Front Photo | `profiles.aadhaar_front_photo_url` | Image | JPEG/PNG, max 5MB | Yes |
| Aadhaar Back Photo | `profiles.aadhaar_back_photo_url` | Image | JPEG/PNG, max 5MB | Yes |
| Aadhaar Number | `profiles.aadhaar_number` | Text | Exactly 12 digits, numeric | Yes |
| PAN Photo | `profiles.pan_photo_url` | Image | JPEG/PNG, max 5MB | Yes |
| PAN Number | `profiles.pan_number` | Text | Regex: `[A-Z]{5}[0-9]{4}[A-Z]{1}` | Yes |
| Business Licence Photo | `suppliers.business_licence_doc_url` | Image | JPEG/PNG, max 5MB | No |
| GST Number | `suppliers.gst_number` | Text | 15 chars, regex: `\d{2}[A-Z]{5}\d{4}[A-Z]{1}\d[Z]{1}[A-Z\d]{1}` | No |
| Profile Photo | `profiles.avatar_url` | Image | JPEG/PNG, max 2MB | Yes |

### 2.3 Storage Paths
```
verification-docs/{user_id}/aadhaar_front.jpg
verification-docs/{user_id}/aadhaar_back.jpg
verification-docs/{user_id}/pan.jpg
verification-docs/{user_id}/business_licence.jpg
profile-photos/{user_id}/avatar.jpg
```

### 2.4 Image Upload Rules
1. Pick from gallery OR camera (both options in a bottom sheet).
2. Compress to **1200×1200 max, 85% JPEG quality** before upload.
3. Show preview thumbnail after selection (before submit).
4. Upload to Supabase Storage → get public/signed URL → save URL to DB column.

---

## 3. Trucker Verification (`/trucker-verification`)

### 3.1 Screen Layout
Same structure as Supplier but different fields:

```
┌────────────────────────────────────┐
│ [←] Trucker Verification           │
├────────────────────────────────────┤
│ § Aadhaar Card                     │
│ [Front photo] [Back photo]         │
│ Aadhaar Number: [____________]     │
├────────────────────────────────────┤
│ § PAN Card                         │
│ [PAN photo]                        │
│ PAN Number: [__________]           │
├────────────────────────────────────┤
│ § Driving License                  │
│ [DL Front photo] [DL Back photo]   │
│ DL Number: [________________]      │
├────────────────────────────────────┤
│ § Insurance (Optional)             │
│ [Insurance doc photo]              │
├────────────────────────────────────┤
│ § Permit (Optional)                │
│ [Permit doc photo]                 │
├────────────────────────────────────┤
│ § Profile Photo                    │
│ [Upload / Take Selfie]             │
├────────────────────────────────────┤
│ [Submit for Verification]          │
└────────────────────────────────────┘
```

### 3.2 Form Fields & Validation
| Field | DB Column | Validation | Required? |
|-------|-----------|-----------|-----------|
| Aadhaar Front | `profiles.aadhaar_front_photo_url` | JPEG/PNG, max 5MB | Yes |
| Aadhaar Back | `profiles.aadhaar_back_photo_url` | JPEG/PNG, max 5MB | Yes |
| Aadhaar Number | `profiles.aadhaar_number` | 12 digits | Yes |
| PAN Photo | `profiles.pan_photo_url` | JPEG/PNG, max 5MB | Yes |
| PAN Number | `profiles.pan_number` | `[A-Z]{5}[0-9]{4}[A-Z]{1}` | Yes |
| DL Front | `truckers.dl_front_photo_url` | JPEG/PNG, max 5MB | Yes |
| DL Back | `truckers.dl_back_photo_url` | JPEG/PNG, max 5MB | Yes |
| DL Number | `truckers.dl_number` | Max 20 chars, alphanumeric | Yes |
| Insurance Doc | `truckers.insurance_doc_url` | JPEG/PNG/PDF, max 5MB | No |
| Permit Doc | `truckers.permit_doc_url` | JPEG/PNG/PDF, max 5MB | No |
| Profile Photo | `profiles.avatar_url` | JPEG/PNG, max 2MB | Yes |

### 3.3 Storage Paths
```
verification-docs/{user_id}/aadhaar_front.jpg
verification-docs/{user_id}/aadhaar_back.jpg
verification-docs/{user_id}/pan.jpg
verification-docs/{user_id}/dl_front.jpg
verification-docs/{user_id}/dl_back.jpg
verification-docs/{user_id}/insurance.jpg
verification-docs/{user_id}/permit.jpg
profile-photos/{user_id}/avatar.jpg
```

---

## 4. Verification State Machine & UX

### 4.1 Status Transitions
```
unverified ──→ pending (user submits docs)
                ├──→ verified (admin approves)
                └──→ rejected (admin rejects with reason)
                      └──→ pending (user re-submits fixed docs)
```

### 4.2 Dashboard Banners (Both Roles)
| Status | Banner Color | Banner Text | Action |
|--------|-------------|-------------|--------|
| `unverified` | Gray bg | "Complete verification to start [posting/booking] loads." | Tap → verification screen |
| `pending` | Amber bg | "Verification Under Review — We'll notify you when approved." | No action |
| `verified` | Green bg (fades after 24h) | "Verified Account ✓" | No action |
| `rejected` | Red bg | "Verification Failed: {reason}. Tap to re-upload." | Tap → verification screen (pre-filled) |

### 4.3 Marketplace Gating
| Action | Unverified User | Verified User |
|--------|----------------|---------------|
| Browse loads | ✅ Can view all active loads | ✅ |
| View load detail | ✅ | ✅ |
| Book load | ❌ "Verify to Book" button (gray) | ✅ |
| Post load | ❌ "Verify to Post" button (gray) | ✅ |
| Chat | ❌ Cannot initiate chat | ✅ |
| Request Super Load | ❌ | ✅ (also needs payout profile) |

### 4.4 Re-Submission Flow (After Rejection)
1. User taps "Verification Failed" banner → navigates to verification screen.
2. Provider calls `loadExistingData()` → pre-fills all previously submitted fields and photos.
3. User sees which documents were rejected (highlighted with red border + rejection reason).
4. User re-uploads only the rejected documents (other fields remain pre-filled).
5. User taps "Resubmit" → `verification_status` reverts to `pending`.
6. Push notification to user when admin reviews.

### 4.5 Admin Side (Cross-reference 09_ADMIN)
- Admin sees pending verification queue sorted oldest-first.
- Items approaching 24h SLA → amber highlight. Exceeding → red highlight.
- Admin taps user → reviews documents via signed URL viewer.
- Approve → sets `verification_status = 'verified'`, `verified_at = NOW()`.
- Reject → sets `verification_status = 'rejected'`, `verification_rejection_reason = 'reason'`.
- Both actions create an `audit_logs` entry.

---

## 5. Fleet Management (Trucker Only)

### 5.1 My Fleet Screen (`/my-fleet`)
```
┌────────────────────────────────────┐
│ Fleet                   [🔔][👤]  │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ MH 12 AB 1234               │   │
│ │ Tata 407 · Open · 6 Tyres   │   │
│ │ 3.5 Tonnes · [✓ VERIFIED]   │   │
│ │ [RC Photo thumbnail]        │   │
│ └──────────────────────────────┘   │
│ ┌──────────────────────────────┐   │
│ │ MH 14 CD 5678               │   │
│ │ Ashok Leyland 1616 · Open   │   │
│ │ 16 Tonnes · [⏳ PENDING]    │   │
│ │ [RC Photo thumbnail]        │   │
│ └──────────────────────────────┘   │
├────────────────────────────────────┤
│ [+ Add Truck] (PrimaryButton)      │
├────────────────────────────────────┤
│ [Find] [My Trips] [Fleet] [Chat]  │
└────────────────────────────────────┘
```

**Empty State:** `EmptyStateView("No trucks yet", "Add your first truck to start booking loads.", CTA: "Add Truck")`

**Truck Card Contents:**
- Truck number (bold, `titleMedium`)
- Make + Model (from `truck_models` join, or manual entry text)
- Body type · Tyres
- Capacity (tonnes)
- Status badge: `StatusBadge(truck.status)` — `pending` (amber), `verified` (green), `rejected` (red)
- RC photo thumbnail (64×64, rounded)

**Tap Actions:**
- Tap verified truck → no action (view only in V1)
- Tap pending truck → "Waiting for admin verification"
- Tap rejected truck → "Rejected: {reason}. Tap to re-upload RC." → navigate to edit flow

### 5.2 Add Truck Screen (`/add-truck`)
```
┌────────────────────────────────────┐
│ [←] Add Truck                      │
├────────────────────────────────────┤
│ § Select Make                      │
│ [Tata ▼]                           │
│ (Dropdown, from truck_models)      │
├────────────────────────────────────┤
│ § Select Model                     │
│ [407 ▼]                            │
│ (Dropdown, filtered by make)       │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │ Auto-filled Specs:           │   │
│ │ Body: Open · Axles: 2        │   │
│ │ GVW: 7,490 kg               │   │
│ │ Payload: 3,500 kg            │   │
│ │ Mileage: 8.5 km/L (empty)   │   │
│ │         5.2 km/L (loaded)    │   │
│ └──────────────────────────────┘   │
│ (Card, gray bg, read-only specs)   │
├────────────────────────────────────┤
│ ☐ My truck is not in the list      │
│ (Toggle → reveals manual fields)   │
│ [Body Type ▼] [Tyres ▼]           │
│ [Capacity (tonnes): _____]         │
├────────────────────────────────────┤
│ § Truck Number                     │
│ [MH 12 AB 1234]                   │
│ (TextFormField, uppercase, unique) │
├────────────────────────────────────┤
│ § RC Photo                         │
│ ┌────────────────────────────┐     │
│ │ [📷 Upload RC Document]    │     │
│ │  (or preview thumbnail)    │     │
│ └────────────────────────────┘     │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │  Add Truck                   │   │
│ │  (PrimaryButton, full width) │   │
│ └──────────────────────────────┘   │
└────────────────────────────────────┘
```

### 5.3 Add Truck Form Fields & Validation
| Field | DB Column | Validation | Required? |
|-------|-----------|-----------|-----------|
| Make | `truck_models.make` (via join) | Must be selected from dropdown | Yes (or manual) |
| Model | `truck_models.model` (via join) | Must be selected from dropdown | Yes (or manual) |
| Truck Number | `trucks.truck_number` | Regex: `[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,3}\s?\d{4}`, UNIQUE in DB | Yes |
| Body Type | `trucks.body_type` | Enum: open, container, trailer, tanker, refrigerated | Yes (auto-filled from model or manual) |
| Tyres | `trucks.tyres` | Integer, 4-22 | Yes (auto-filled or manual) |
| Capacity | `trucks.capacity_tonnes` | Decimal, > 0 | Yes (auto-filled or manual) |
| RC Photo | `trucks.rc_photo_url` | JPEG/PNG, max 5MB | Yes |

**Storage Path:** `truck-photos/{truck_id}/rc.jpg`

### 5.4 Add Truck Flow
1. User selects Make → Model dropdown filters.
2. Selecting Model → auto-fills specs from `truck_models` row. Spec card appears.
3. If "My truck is not in the list" toggled → manual fields appear, spec card hides.
4. User enters truck number (auto-uppercased as they type).
5. User uploads RC photo (camera or gallery).
6. Tap "Add Truck" → `addTruckProvider.submitTruck(...)`.
7. Provider: upload RC to Storage → get URL → INSERT into `trucks` table → refresh fleet list.
8. On success → navigate back to My Fleet. New truck appears with `pending` badge.
9. On conflict (duplicate truck number) → Snackbar: "This truck number is already registered."

### 5.5 Truck Status Machine
```
pending ──→ verified (admin approves RC)
  │          └──→ (available for booking)
  └──→ rejected (admin rejects with reason)
         └──→ pending (trucker re-uploads RC)
```

### 5.6 Master Truck Catalog (`truck_models`)
Pre-seeded with **50 Indian commercial vehicles**:
- **Makes:** Tata, Ashok Leyland, Eicher, BharatBenz, Mahindra, SML Isuzu, Force
- **Data per model:** make, model, body_type, axles, gvw_kg, payload_kg, dimensions (L×W×H ft), mileage_empty_kmpl, mileage_loaded_kmpl
- **Catalog Service:** `TruckModelService` with in-memory cache. Methods: `getMakes()`, `getModelsForMake(make)`, `getModelById(id)`.
- **Dynamic Mileage:** `dynamicMileage(loadWeightKg)` interpolates between empty and loaded mileage based on actual load weight vs. payload capacity. Used by `TripCostingService`.

---

## 6. Payout Profiles (Supplier Only)

### 6.1 Screen (`/payout-profile`)
Required before requesting a Super Load.

```
┌────────────────────────────────────┐
│ [←] Payout Profile                 │
├────────────────────────────────────┤
│ "Set up your bank details for      │
│  Super Load payouts"               │
│ (bodyMedium, gray)                 │
├────────────────────────────────────┤
│ § Account Holder Name              │
│ [____________________________]     │
│ (as it appears on bank records)    │
├────────────────────────────────────┤
│ § Bank Account Number              │
│ [____________________________]     │
│ (numeric, 9-18 digits)             │
├────────────────────────────────────┤
│ § Confirm Account Number           │
│ [____________________________]     │
│ (must match above)                 │
├────────────────────────────────────┤
│ § IFSC Code                        │
│ [___________]                      │
│ (11 chars: ABCD0123456)            │
├────────────────────────────────────┤
│ § Bank Name (auto-detected)        │
│ "State Bank of India"              │
│ (read-only, derived from IFSC)     │
├────────────────────────────────────┤
│ ┌──────────────────────────────┐   │
│ │  Save Payout Profile         │   │
│ │  (PrimaryButton, full width) │   │
│ └──────────────────────────────┘   │
└────────────────────────────────────┘
```

### 6.2 Fields & Validation
| Field | DB Column | Validation | Required? |
|-------|-----------|-----------|-----------|
| Account Holder Name | `payout_profiles.account_holder_name` | Min 2 chars, max 255 | Yes |
| Account Number | (NOT stored fully) | 9-18 digits, numeric | Yes |
| Confirm Account Number | (client only) | Must match account number | Yes |
| IFSC Code | `payout_profiles.ifsc_code` | Regex: `[A-Z]{4}0[A-Z0-9]{6}`, 11 chars | Yes |
| Bank Name | `payout_profiles.bank_name` | Auto-detected from IFSC (first 4 chars) | Auto |

### 6.3 Security Rules
- **NEVER store full account number.** Only `account_number_last4` (last 4 digits) is saved to DB.
- In UI after saving: display masked `XXXX-XXXX-XXXX-1234`.
- Full account number is entered by user, validated client-side (two fields must match), but only last 4 digits sent to server.
- **Payout is manual in V1:** TranZfort ops team uses bank details to initiate NEFT/IMPS transfer offline. No payment gateway integration.

### 6.4 Payout Status Machine
```
pending ──→ verified (admin confirms bank details are valid)
  │
  └──→ rejected (admin rejects with reason)
         └──→ pending (user re-submits)
```

---

## 7. Profile Screen (`/profile`)

Accessible from the drawer/settings menu.

```
┌────────────────────────────────────┐
│ [←] My Profile                     │
├────────────────────────────────────┤
│ ┌──────────┐                       │
│ │ [Avatar]  │  Rajesh Kumar        │
│ │  80x80    │  +91 98765 43210     │
│ │           │  rajesh@gmail.com    │
│ └──────────┘  [✓ VERIFIED]        │
├────────────────────────────────────┤
│ § Full Name                        │
│ [Rajesh Kumar________]  [Edit]     │
├────────────────────────────────────┤
│ § Phone Number                     │
│ +91 98765 43210 (read-only)        │
├────────────────────────────────────┤
│ § Email                            │
│ rajesh@gmail.com (read-only)       │
├────────────────────────────────────┤
│ § Role                             │
│ Supplier (read-only, permanent)    │
├────────────────────────────────────┤
│ [Payout Profile →]                 │
│ [Verification Status →]            │
│ [Help & Support →]                 │
│ [Sign Out]                         │
└────────────────────────────────────┘
```

- **Editable:** Full name, avatar.
- **Read-only:** Phone, email, role.
- **Phone/email change:** Not supported in V1 (requires re-verification).

---

## 8. State Management (Riverpod)

| Provider | State | Intents |
|----------|-------|---------|
| `supplierVerificationProvider` | `{isSubmitting, existingDocs, lastError}` | `loadExistingData()`, `submitVerification(fields)` |
| `truckerVerificationProvider` | `{isSubmitting, existingDocs, lastError}` | `loadExistingData()`, `submitVerification(fields)` |
| `fleetProvider` | `AsyncValue<List<Truck>>` | `loadFleet()`, `removeTruck(id)` |
| `truckCatalogProvider` | `AsyncValue<List<TruckModelSpec>>` | (read-only, fetched on build) |
| `addTruckProvider` | `{isSubmitting, lastError}` | `submitTruck(fields, rcImage)` |
| `payoutProfileProvider` | `AsyncValue<PayoutProfile?>` | `loadProfile()`, `saveProfile(fields)` |
| `userProfileProvider` | `AsyncValue<Profile?>` | `loadProfile()`, `updateName(name)`, `updateAvatar(file)` |
