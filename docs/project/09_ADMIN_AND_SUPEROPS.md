# 09: Admin App, Queues & Super Ops

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define every admin screen layout, data table column, action flow, RBAC permission, and Super Ops workflow. A junior developer should build the entire Admin Flutter app from this document.

---

## 1. Admin App Architecture

### 1.1 Separate Flutter Project
- Path: `/Admin` (separate from `/TranZfort` user app).
- Same Supabase instance, same database.
- **Auth:** Email + Password only (no Google, no Phone OTP).
- **Role source:** `admin_users.role` column (NOT `profiles.user_role_type`).
- **RLS bypass:** Admin RLS policies check `is_admin()` helper function. Edge Functions use `service_role` key for writes that bypass RLS entirely.

### 1.2 Admin Roles (RBAC)
| Role | `admin_role` | Capabilities |
|------|-------------|-------------|
| **Super Admin** | `super_admin` | Everything + manage admin users + system settings |
| **Ops Admin** | `ops_admin` | Verification queues + Super Ops + user management + support |
| **Support Agent** | `support_agent` | Support tickets only + read-only user profiles |

### 1.3 RBAC Permission Matrix
| Screen | Super Admin | Ops Admin | Support Agent |
|--------|------------|-----------|---------------|
| Dashboard | ✅ | ✅ | ✅ (limited KPIs) |
| Verification Queues | ✅ | ✅ | ❌ |
| User Management | ✅ | ✅ | Read-only |
| Support Tickets | ✅ | ✅ | ✅ |
| Super Ops Console | ✅ | ✅ | ❌ |
| Load Management | ✅ | ✅ | ❌ |
| Admin Management | ✅ | ❌ | ❌ |
| Audit Logs | ✅ | ❌ | ❌ |
| System Settings | ✅ | ❌ | ❌ |

---

## 2. Admin Login (`/login`)

```
┌────────────────────────────────────┐
│          (no AppBar)               │
│                                    │
│     [Admin Logo - 80x80]          │
│     "TranZfort Admin"              │
│                                    │
│  § Email                           │
│  [admin@tranzfort.com________]     │
│                                    │
│  § Password                        │
│  [●●●●●●●●●●________________]     │
│                                    │
│  ┌──────────────────────────────┐  │
│  │      Sign In                 │  │
│  │  (PrimaryButton, full width) │  │
│  └──────────────────────────────┘  │
│                                    │
│  "Forgot Password?"               │
│  (text link → Supabase reset)     │
└────────────────────────────────────┘
```

**Flow:**
1. Admin enters email + password.
2. `Supabase.auth.signInWithPassword(email, password)`.
3. On success → query `admin_users WHERE auth_user_id = auth.uid()`.
4. If no row → "You are not authorized. Contact your administrator." → sign out.
5. If row exists and `is_active = true` → read `role` → navigate to dashboard.
6. If `is_active = false` → "Your account has been deactivated." → sign out.

---

## 3. Dashboard (`/dashboard`)

```
┌────────────────────────────────────────────────────┐
│ Dashboard                          [Admin Name ▼]  │
├────────────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│ │ 1,245│ │  347 │ │   12 │ │    5 │ │    8 │    │
│ │Users │ │Trucks│ │Pend. │ │Open  │ │Super │    │
│ │Active│ │Verif.│ │Verif.│ │Ticket│ │Loads │    │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘    │
│ (KPI cards with counts)                           │
├────────────────────────────────────────────────────┤
│ § SLA Alerts                                       │
│ ┌──────────────────────────────────────────────┐   │
│ │ ⚠ 3 verifications approaching 24h SLA       │   │
│ │ ⚠ 2 support tickets > 48h without response  │   │
│ │ ⚠ 1 super load awaiting dispatch > 6h       │   │
│ └──────────────────────────────────────────────┘   │
├────────────────────────────────────────────────────┤
│ § Recent Activity Feed                             │
│ 10:15 — Rajesh posted 50-truck Coal load           │
│ 10:12 — Suresh uploaded POD for trip #T-234        │
│ 10:08 — New user registered: Ramesh (Trucker)      │
│ 10:05 — Support ticket #S-45 resolved              │
│ (scrollable feed, last 50 events)                  │
├────────────────────────────────────────────────────┤
│ [Verification] [Users] [Support] [Super Ops]       │
│ (Sidebar navigation)                               │
└────────────────────────────────────────────────────┘
```

### KPI Card Data Sources
| KPI | Query |
|-----|-------|
| Active Users | `COUNT(profiles WHERE is_banned = false)` |
| Verified Trucks | `COUNT(trucks WHERE status = 'verified')` |
| Pending Verifications | `COUNT(profiles WHERE verification_status = 'pending') + COUNT(trucks WHERE status = 'pending')` |
| Open Tickets | `COUNT(support_tickets WHERE status IN ('open', 'in_progress'))` |
| Active Super Loads | `COUNT(loads WHERE is_super_load = true AND super_status NOT IN ('none', 'completed'))` |

### SLA Alerts
| Alert | Threshold | Color |
|-------|-----------|-------|
| Verification approaching SLA | Created > 20h ago, < 24h | Amber |
| Verification exceeding SLA | Created > 24h ago | Red |
| Support ticket stale | Last activity > 48h | Red |
| Super Load awaiting dispatch | `super_status = 'requested'` > 6h | Amber |

---

## 4. Verification Queues (`/verifications`)

### 4.1 Screen Layout
```
┌────────────────────────────────────────────────────┐
│ Verifications                                      │
├────────────────────────────────────────────────────┤
│ [Suppliers (5)] [Truckers (4)] [Trucks (3)]       │
│ (Tab bar with pending counts)                      │
├────────────────────────────────────────────────────┤
│ ┌─────┬──────────┬──────────┬────────┬──────────┐ │
│ │ # │ Name     │ Mobile   │ Subm.  │ SLA     │ │
│ ├─────┼──────────┼──────────┼────────┼──────────┤ │
│ │ 1 │ Rajesh   │ 9876...  │ 22h ago│ 🟡 2h   │ │
│ │ 2 │ Suresh   │ 9765...  │ 18h ago│ 🟢 6h   │ │
│ │ 3 │ Ramesh   │ 9654...  │ 25h ago│ 🔴 -1h  │ │
│ └─────┴──────────┴──────────┴────────┴──────────┘ │
│ (DataTable, sortable by SLA, submission time)      │
│ Tap row → opens verification detail                │
└────────────────────────────────────────────────────┘
```

### 4.2 Table Columns Per Tab
**Suppliers Tab:**
| Column | Data Source |
|--------|-----------|
| Name | `profiles.full_name` |
| Company | `suppliers.company_name` |
| Mobile | `profiles.mobile` |
| Email | `profiles.email` |
| Submitted | `profiles.updated_at` (when status changed to pending) |
| SLA Remaining | `24h - (NOW() - submitted_at)` |

**Truckers Tab:** Same as Suppliers + DL Number (`truckers.dl_number`).

**Trucks Tab:**
| Column | Data Source |
|--------|-----------|
| Truck Number | `trucks.truck_number` |
| Owner | `profiles.full_name` (via `truckers.id → profiles.id`) |
| Body Type | `trucks.body_type` |
| Tyres | `trucks.tyres` |
| Submitted | `trucks.created_at` |
| SLA Remaining | `24h - (NOW() - created_at)` |

### 4.3 Verification Detail Screen (`/verification/:id`)
```
┌────────────────────────────────────────────────────┐
│ [←] Verify: Rajesh Kumar (Supplier)                │
├────────────────────────────────────────────────────┤
│ § Profile Info                                     │
│ Name: Rajesh Kumar                                 │
│ Company: Rajesh Industries                         │
│ Mobile: +91 98765 43210                            │
│ Email: rajesh@gmail.com                            │
│ Registered: 27 Feb 2026                            │
├────────────────────────────────────────────────────┤
│ § Aadhaar Card                                     │
│ Number: 1234 5678 9012                             │
│ ┌───────────────┐ ┌───────────────┐               │
│ │ [Front Image]  │ │ [Back Image]  │               │
│ │ (zoomable)     │ │ (zoomable)    │               │
│ └───────────────┘ └───────────────┘               │
├────────────────────────────────────────────────────┤
│ § PAN Card                                         │
│ Number: ABCDE1234F                                 │
│ ┌───────────────┐                                  │
│ │ [PAN Image]    │                                  │
│ └───────────────┘                                  │
├────────────────────────────────────────────────────┤
│ § Business Licence                                 │
│ GST: 27ABCDE1234F1Z5                              │
│ ┌───────────────┐                                  │
│ │ [Licence Image]│                                  │
│ └───────────────┘                                  │
├────────────────────────────────────────────────────┤
│ § Profile Photo                                    │
│ ┌───────────────┐                                  │
│ │ [Selfie]       │                                  │
│ └───────────────┘                                  │
├────────────────────────────────────────────────────┤
│ ┌──────────────────┐ ┌──────────────────┐          │
│ │ ✅ Approve       │ │ ❌ Reject         │          │
│ │ (success button) │ │ (error button)   │          │
│ └──────────────────┘ └──────────────────┘          │
│                                                     │
│ Rejection Reason (required if rejecting):           │
│ [Blurry Aadhaar image, please re-upload_________]  │
└────────────────────────────────────────────────────┘
```

**Image Viewer:** All document images are loaded via Supabase Storage signed URLs. Tapping an image opens a full-screen zoomable viewer.

**Approve Action:**
1. `UPDATE profiles SET verification_status = 'verified', verified_at = NOW()`.
2. INSERT into `audit_logs` with action = 'verify_user', admin_id, old/new values.
3. Push notification → user.
4. Return to queue (auto-refreshes).

**Reject Action:**
1. Rejection reason is mandatory (min 10 characters).
2. `UPDATE profiles SET verification_status = 'rejected', verification_rejection_reason = '{reason}'`.
3. INSERT into `audit_logs`.
4. Push notification → user with reason.

---

## 5. User Management (`/users`)

### 5.1 User List
```
┌────────────────────────────────────────────────────┐
│ User Management           [Search: ___________]    │
├────────────────────────────────────────────────────┤
│ [All] [Suppliers] [Truckers] [Banned]             │
├────────────────────────────────────────────────────┤
│ ┌────┬──────────┬──────┬──────────┬───────┬──────┐│
│ │ #  │ Name     │ Role │ Mobile   │ Status│ Loads││
│ ├────┼──────────┼──────┼──────────┼───────┼──────┤│
│ │ 1  │ Rajesh   │ Sup. │ 9876... │ ✅    │ 47   ││
│ │ 2  │ Suresh   │ Trk. │ 9765... │ ⏳    │ 12   ││
│ │ 3  │ Banned   │ Trk. │ 9654... │ 🚫    │ 3    ││
│ └────┴──────────┴──────┴──────────┴───────┴──────┘│
│ Page: [< 1 2 3 ... 25 >] (50 per page)           │
└────────────────────────────────────────────────────┘
```

**Search:** Searches across `full_name`, `mobile`, `email`.
**Filter tabs:** All, Suppliers only, Truckers only, Banned only.

### 5.2 User Detail (`/user/:userId`)
```
┌────────────────────────────────────────────────────┐
│ [←] Rajesh Kumar (Supplier)                        │
├────────────────────────────────────────────────────┤
│ § Profile                                          │
│ [Avatar] Rajesh Kumar                              │
│ +91 98765 43210 · rajesh@gmail.com                 │
│ Role: Supplier · Verification: ✅ Verified         │
│ Registered: 15 Jan 2026 · Last Login: 2h ago       │
├────────────────────────────────────────────────────┤
│ § Stats                                            │
│ Loads Posted: 47 · Active: 5 · Completed: 42      │
│ Total Revenue: ₹28,50,000                          │
├────────────────────────────────────────────────────┤
│ § Verification Documents                           │
│ [View Aadhaar] [View PAN] [View Business Licence]  │
│ (opens signed URL in viewer)                       │
├────────────────────────────────────────────────────┤
│ § Recent Loads                                     │
│ (last 10 loads with status badges)                 │
├────────────────────────────────────────────────────┤
│ § Actions                                          │
│ [Ban User] (red, confirmation dialog)              │
│ [Reset Verification] (amber, re-queues)            │
│ [View Audit Log] (shows all admin actions on user) │
└────────────────────────────────────────────────────┘
```

**For Truckers, also shows:**
- Fleet: list of trucks with status badges.
- Rating: current aggregate + number of ratings.
- Completed trips count.
- Super Trucker status.

### 5.3 Ban/Unban Flow
1. Admin taps "Ban User" → confirmation dialog: "Ban Rajesh Kumar? They will be logged out and cannot access the app."
2. Mandatory ban reason text field.
3. `UPDATE profiles SET is_banned = true, ban_reason = '{reason}'`.
4. INSERT into `audit_logs`.
5. User's next app open → BanCheckWrapper kicks in → forced sign out.

**Unban:** Same flow, sets `is_banned = false`, `ban_reason = NULL`.

---

## 6. Support Tickets (`/support`)

### 6.1 Ticket Queue
```
┌────────────────────────────────────────────────────┐
│ Support Tickets          [Search: ___________]     │
├────────────────────────────────────────────────────┤
│ [Open (8)] [In Progress (3)] [Resolved (45)]      │
├────────────────────────────────────────────────────┤
│ ┌────┬──────────┬─────────┬────────┬──────┬──────┐│
│ │ #  │ Subject  │ User    │Priority│ Age  │Assign││
│ ├────┼──────────┼─────────┼────────┼──────┼──────┤│
│ │ 45 │ Payment  │ Rajesh  │ 🔴 High│ 3d   │ —    ││
│ │ 44 │ Truck RC │ Suresh  │ 🟡 Med │ 1d   │ Amit ││
│ │ 43 │ Login    │ Ramesh  │ 🟢 Low │ 4h   │ —    ││
│ └────┴──────────┴─────────┴────────┴──────┴──────┘│
└────────────────────────────────────────────────────┘
```

### 6.2 Ticket Detail (`/support/:ticketId`)
```
┌────────────────────────────────────────────────────┐
│ [←] Ticket #45: Payment not received               │
├────────────────────────────────────────────────────┤
│ User: Rajesh Kumar (Supplier)                      │
│ Priority: 🔴 High · Status: Open                   │
│ Created: 25 Feb 2026 · Assigned: —                 │
├────────────────────────────────────────────────────┤
│ § Conversation                                     │
│ [Rajesh] "I completed the trip 3 days ago but      │
│ haven't received my payment yet."                  │
│ 25 Feb, 10:00 AM                                   │
│                                                     │
│ [Admin: Amit] "Checking with finance team."        │
│ 26 Feb, 02:30 PM                                   │
│                                                     │
│ [Rajesh] "Any update?"                             │
│ 27 Feb, 09:00 AM                                   │
├────────────────────────────────────────────────────┤
│ § Admin Reply                                      │
│ [____________________________________]             │
│ [Canned Responses ▼]                               │
│ [Send Reply] (PrimaryButton)                       │
├────────────────────────────────────────────────────┤
│ § Actions                                          │
│ [Assign to Me] [Change Priority ▼]                 │
│ [Mark Resolved] (requires resolution notes)        │
└────────────────────────────────────────────────────┘
```

**Canned Responses (Dropdown):**
- "Your payment is being processed and will reflect within 24 hours."
- "Please re-upload the required documents for verification."
- "We have escalated this to our operations team."
- "Your issue has been resolved. Please let us know if you need further help."

**Actions:**
- **Assign to Me:** Sets `assigned_to = current_admin_id`.
- **Change Priority:** Dropdown (Low, Medium, High, Urgent).
- **Mark Resolved:** Required `resolution_notes` text field → sets `status = 'resolved'`, `resolved_at = NOW()`, `resolved_by = admin_id`.
- **Send Reply:** INSERT into `support_ticket_messages` with `sender_role = 'admin'`. Push notification → user.

---

## 7. Super Ops Console (`/super-ops`)

### 7.1 Screen Layout — 4 Tabs
```
┌────────────────────────────────────────────────────┐
│ Super Ops Console                                  │
├────────────────────────────────────────────────────┤
│ [Requests (3)] [Dispatch (2)] [POD Review (1)]    │
│ [Completed (47)]                                   │
├────────────────────────────────────────────────────┤
│ (Tab content below)                                │
└────────────────────────────────────────────────────┘
```

### 7.2 Requests Tab (`super_status = 'requested'`)
```
┌────┬──────────────┬──────────┬─────────┬──────┬──────┐
│ #  │ Route        │ Material │ Price   │ Trks │ Age  │
├────┼──────────────┼──────────┼─────────┼──────┼──────┤
│ 1  │ Chnd → Mum   │ Coal     │ ₹62.5K  │ 50   │ 2h   │
│ 2  │ Jam → Kol    │ Steel    │ ₹45K    │ 10   │ 5h   │
└────┴──────────────┴──────────┴─────────┴──────┴──────┘
```

**Tap row → Request Detail:**
- Load details (route, cargo, price, trucks needed).
- Supplier info (name, company, verification status, payout profile status).
- **Actions:**
  - `[Accept Request]` → `super_status = 'processing'`. Admin takes ownership.
  - `[Reject Request]` → `super_status = 'none'`, `is_super_load = false`. Notify supplier.

### 7.3 Dispatch Tab (`super_status = 'processing'`)
Admin must assign a trusted trucker to the load.

```
┌────────────────────────────────────────────────────┐
│ [←] Dispatch: Coal Chandrapur → Mumbai             │
├────────────────────────────────────────────────────┤
│ § Load Details                                     │
│ Coal · 25T · ₹62,500 · 50 trucks · Open body      │
├────────────────────────────────────────────────────┤
│ § Find Trucker                                     │
│ Search: [Suresh___________] [🔍]                   │
│ (Search by name, phone, or truck number)           │
├────────────────────────────────────────────────────┤
│ § Search Results                                   │
│ ┌──────────────────────────────────────────────┐   │
│ │ Suresh Kumar · ⭐ 4.5 · 23 trips            │   │
│ │ Trucks:                                      │   │
│ │ ○ MH 12 AB 1234 · Tata 407 · Open · AVAIL   │   │
│ │ ○ MH 12 CD 5678 · Eicher · Open · ON TRIP   │   │
│ │ [Select MH 12 AB 1234]                       │   │
│ └──────────────────────────────────────────────┘   │
├────────────────────────────────────────────────────┤
│ Selected: Suresh Kumar · MH 12 AB 1234             │
│ [🚀 Force Assign]                                  │
│ (PrimaryButton, success, full width)               │
└────────────────────────────────────────────────────┘
```

**Force Assign Flow:**
1. Admin selects a verified trucker + available truck.
2. Taps "Force Assign".
3. **Calls `admin_force_assign_super_load` RPC:**
   - Creates a **Child Load** assigned to the trucker.
   - Creates a `trips` record (`stage = 'at_pickup'`).
   - Increments `trucks_booked` on the Parent Load and sets `super_status = 'assigned'`.
4. Push notification → Trucker: "You have been assigned a Super Load! Details: [material] [route]."
5. Push notification → Supplier: "Trucker assigned to your Super Load."

### 7.4 POD Review Tab (`super_status = 'pod_uploaded'`)
```
┌────────────────────────────────────────────────────┐
│ [←] POD Review: Coal Chandrapur → Mumbai           │
├────────────────────────────────────────────────────┤
│ § Load Summary                                     │
│ Coal · 25T · ₹62,500 · Suresh Kumar               │
├────────────────────────────────────────────────────┤
│ § POD Document                                     │
│ ┌──────────────────────────────────────────────┐   │
│ │ [POD Photo - full width, zoomable]           │   │
│ └──────────────────────────────────────────────┘   │
├────────────────────────────────────────────────────┤
│ § LR Document (if uploaded)                        │
│ ┌──────────────────────────────────────────────┐   │
│ │ [LR Photo - full width, zoomable]            │   │
│ └──────────────────────────────────────────────┘   │
├────────────────────────────────────────────────────┤
│ § Payout Info                                      │
│ Supplier: Rajesh Industries                        │
│ Bank: SBI · XXXX-1234 · IFSC: SBIN0001234         │
│ Total: ₹62,500 · Advance Paid: ₹50,000            │
│ Balance Due: ₹12,500                               │
├────────────────────────────────────────────────────┤
│ [✅ Confirm & Mark Payout]  [❌ Dispute POD]       │
└────────────────────────────────────────────────────┘
```

**Confirm & Mark Payout:**
1. `super_status = 'completed'`, `trips.stage = 'completed'`, `loads.status = 'completed'`.
2. INSERT into `audit_logs` with payout details.
3. Push notification → both parties.
4. **Payout is manual in V1:** Admin initiates NEFT/IMPS transfer offline using saved bank details.

### 7.5 Post on Behalf (`/super-ops/post-on-behalf`)
Admins can post a load for a supplier who called by phone:
1. Search/select supplier from dropdown.
2. Fill the standard 4-step Post Load wizard.
3. `loads.assigned_by = admin_id` to track admin-posted loads.
4. Load appears in supplier's My Loads as normal.

---

## 8. Load Management (`/loads`)

### 8.1 All Loads View
```
┌────────────────────────────────────────────────────┐
│ Load Management           [Search: ___________]    │
├────────────────────────────────────────────────────┤
│ [Active] [Booked] [In Transit] [Completed] [All]  │
├────────────────────────────────────────────────────┤
│ ┌───┬──────────────┬──────┬───────┬──────┬───────┐│
│ │ # │ Route        │ Mat. │ Price │Trucks│Status ││
│ ├───┼──────────────┼──────┼───────┼──────┼───────┤│
│ │ 1 │ Chnd → Mum   │ Coal │ 62.5K │ 12/50│Active ││
│ │ 2 │ Jam → Kol    │Steel │ 45K   │ 1/1  │Booked ││
│ └───┴──────────────┴──────┴───────┴──────┴───────┘│
└────────────────────────────────────────────────────┘
```

**Admin can:** View any load detail, see booking history, cancel loads (with reason).

---

## 9. Admin Management (`/admin-management`) — Super Admin Only

### 9.1 Admin List
```
┌────────────────────────────────────────────────────┐
│ Admin Management                   [+ Invite New]  │
├────────────────────────────────────────────────────┤
│ ┌───┬──────────┬──────────────┬───────────┬──────┐│
│ │ # │ Name     │ Email        │ Role      │Active││
│ ├───┼──────────┼──────────────┼───────────┼──────┤│
│ │ 1 │ Amit     │ amit@tz.com  │SuperAdmin │ ✅   ││
│ │ 2 │ Priya    │ priya@tz.com │Ops Admin  │ ✅   ││
│ │ 3 │ Ravi     │ ravi@tz.com  │Support    │ ❌   ││
│ └───┴──────────┴──────────────┴───────────┴──────┘│
└────────────────────────────────────────────────────┘
```

### 9.2 Invite New Admin
1. Super Admin taps "+ Invite New".
2. Form: Full Name, Email, Role (dropdown: ops_admin, support_agent).
3. Calls `admin-promote-invite` Edge Function.
4. Edge Function: creates `auth.users` row with email + generated password → inserts `admin_users` row → sends invite email with temporary password.
5. New admin logs in, changes password on first use.

### 9.3 Deactivate Admin
- Toggle `is_active = false` → admin can no longer log in.
- Cannot deactivate yourself or the last super admin.

---

## 10. Audit Logs (`/audit-logs`) — Super Admin Only

```
┌────────────────────────────────────────────────────┐
│ Audit Logs               [Filter: ___________]     │
├────────────────────────────────────────────────────┤
│ ┌──────────┬──────┬──────────┬──────────┬────────┐│
│ │ Timestamp│Admin │ Action   │ Entity   │ Detail ││
│ ├──────────┼──────┼──────────┼──────────┼────────┤│
│ │ 10:15 AM │ Amit │ verify   │ profile  │ Rajesh ││
│ │ 10:12 AM │ Priya│ ban_user │ profile  │ Ramesh ││
│ │ 10:08 AM │ Amit │ assign   │ load     │ #L-123 ││
│ └──────────┴──────┴──────────┴──────────┴────────┘│
│ Page: [< 1 2 3 ... >]                             │
└────────────────────────────────────────────────────┘
```

**Filterable by:** Admin name, Action type, Entity type, Date range.

**Every admin action must create an audit log entry.** This includes:
- Verify/reject user
- Verify/reject truck
- Ban/unban user
- Assign super load
- Resolve support ticket
- Change admin roles
- Post load on behalf

---

## 11. Admin Navigation

### 11.1 Sidebar (Desktop-Feel Layout)
```
┌──────────────────┐
│ [TranZfort Admin] │
│                    │
│ 📊 Dashboard      │
│ ✅ Verifications  │
│ 👥 Users          │
│ 📦 Loads          │
│ 🎫 Support        │
│ ⭐ Super Ops      │
│ ───────────       │
│ 👨‍💼 Admin Mgmt    │  ← Super Admin only
│ 📋 Audit Logs     │  ← Super Admin only
│ ⚙ Settings        │  ← Super Admin only
│ ───────────       │
│ [Sign Out]         │
└──────────────────┘
```

### 11.2 Design Philosophy
- **Dense data tables:** Admin app prioritizes information density over aesthetics.
- **No TTS, no bot:** Admin app has no voice features.
- **Desktop-first:** Designed for tablet/desktop use (sidebar navigation, wide tables).
- **Color scheme:** Same design tokens as user app but with a darker header bar (`#1A1A2E`).

---

## 12. State Management (Riverpod)

| Provider | State | Intents |
|----------|-------|---------|
| `adminAuthProvider` | `{isLoading, adminUser, role}` | `signIn(email, password)`, `signOut()` |
| `dashboardKpiProvider` | `AsyncValue<DashboardKpis>` | `loadKpis()` |
| `verificationQueueProvider(tab)` | `AsyncValue<List<PendingItem>>` | `loadQueue()`, `approve(id)`, `reject(id, reason)` |
| `userListProvider` | `AsyncValue<List<UserSummary>>` | `search(query)`, `filter(role)`, `loadPage(n)` |
| `userDetailProvider(id)` | `AsyncValue<UserDetail>` | `loadDetail()`, `ban(reason)`, `unban()`, `resetVerification()` |
| `supportQueueProvider(status)` | `AsyncValue<List<Ticket>>` | `loadQueue()`, `assignToMe(id)`, `resolve(id, notes)` |
| `ticketDetailProvider(id)` | `AsyncValue<TicketDetail>` | `loadDetail()`, `sendReply(text)`, `changePriority(p)` |
| `superOpsProvider(tab)` | `AsyncValue<List<SuperLoad>>` | `loadQueue()`, `acceptRequest(id)`, `forceAssign(id, truckerId, truckId)`, `confirmPod(id)` |
| `adminManagementProvider` | `AsyncValue<List<AdminUser>>` | `loadAdmins()`, `inviteNew(name, email, role)`, `deactivate(id)` |
| `auditLogProvider` | `AsyncValue<List<AuditLog>>` | `loadLogs(filters)`, `loadPage(n)` |
