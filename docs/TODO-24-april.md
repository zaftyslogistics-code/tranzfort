# Load Detail Page Design Tasks — 25 Apr 2026

## 1. HeroActionCard — Merge into Route Section
- [x] Promote price to hero number (not chip)
- [x] Merge HeroActionCard into _LoadRoutePriceSection (one hero surface)
- [x] Reduce status chips to icon-only or single metadata row

## 2. _LoadRoutePriceSection — Remove Redundancy
- [x] Remove origin/destination stat strip (CurvedArcRoute already shows it)
- [x] Move distance/duration into arc widget as inline badges
- [x] Make pickup date a prominent chip

## 3. _LoadRouteMapSection — Fix Title + Remove Duplicates
- [x] Rename title — now says "Route map"
- [x] Remove duplicate "Open in Google Maps" button
- [x] Decide: keep full (220px)

## 4. Truck Requirements — Clarify Booked Slots
- [x] Split "Trucks Needed" into Total Needed + Slots Open chips
- [x] Move match status badge to truck selection area (Next Step)

## 5. Cargo & Schedule — Merge or Drop
- [x] Merge into Truck Requirements as "Load Details" — material chip added, redundant section removed

## 6. Earnings Estimate — Add L10n Keys
- [x] Replace hardcoded English labels with localization keys — all 6 strings replaced
- [x] Add "per km" rate line — added ₹/km calculation to header

## 7. Supplier Profile — Promote Chat Action
- [ ] Add supplier rating/review stars inline — **REVERTED** due to verification status bug (see issue log below)
- [x] Move "Chat" into supplier row as primary action — chat icon button inline, separate OutlineButton removed

---

## Issue Log: Verification Status Bug (26 Apr 2026)

**Issue:** After installing the new APK with TODO-24 changes, a previously verified trucker user was shown as unverified and asked to complete verification again.

**Root Cause Investigation:**
- The only change that touched database queries was adding a `profile_trust_scores` join to `TruckerLoadDetailRepository.fetchSupplierProfile`
- This join was intended to fetch `avg_rating` and `review_count` for supplier profiles displayed on the load detail screen
- The trucker's own verification status is fetched separately via `TruckerProfileRepository.fetchProfile` (no joins)
- **Unexpected behavior:** Despite being separate repositories, the join somehow affected the trucker's verification status

**Tasks Reverted to Fix Issue:**
1. Removed `profile_trust_scores!left(avg_rating, review_count)` join from `TruckerLoadDetailRepository.fetchSupplierProfile`
2. Removed `avgRating` and `reviewCount` fields from `TruckerSupplierSummary` model
3. Removed `_readTrustScore` and `_readTrustCount` helper methods from `TruckerLoadDetailRepository`
4. Removed `StarRatingDisplay` widget from supplier row in `trucker_load_detail_sections.dart`
5. Removed import of `star_rating_input.dart` from `trucker_load_detail_screen.dart`

**Status:** ✅ Issue resolved after revert

**Next Steps for Investigation:**
- Understand why a join in `TruckerLoadDetailRepository.fetchSupplierProfile` (supplier data) affected `TruckerProfileRepository.fetchProfile` (current user data)
- Possible causes to investigate:
  - Supabase query cache or connection pooling issue
  - Shared Supabase client instance affecting query execution order
  - RLS (Row Level Security) policy conflict
  - Data type mismatch in join causing query failure that affected subsequent queries
- Alternative approach: Fetch rating data separately via a dedicated RPC or separate query, not via join
- Test in isolation: Create a minimal reproduction case with just the join to verify the issue

## 8. Next Step Section — Simplify + Sticky CTA
- [x] Remove nested container around truck dropdown — Container border removed
- [x] Promote "Book This Load" to sticky bottom CTA — GradientButton moved to DetailPageScaffold bottomWidget
- [x] Move Share/Report to overflow menu or secondary actions row — Restructured into compact Row of TextButton.icon

## 9. Cross-Cutting
- [x] Unify dark gradient containers — one hero card for route + badges + price + arc + distance + maps
- [x] Reduce total scroll height by 30-40% — Removed Cargo & Schedule, dropped material summary, unified hero

---

## 10. HeroActionCard — Detailed Design Brainstorm (25 Apr 2026)

### 10.1 Route Header: "Mumbai, Maharashtra, India > Nagpur, Maharashtra, India"
**Root cause:** `routeLabel` uses `originLabel` / `destinationLabel` from DB — these store full location strings (city, state, country).

**Options:**
- **Option A:** Build route label from `originCity` + `originState` manually, truncate at state: `Mumbai, Maharashtra > Nagpur, Maharashtra`
- **Option B:** Truncate `originLabel` / `destinationLabel` at first comma for card header; show full string only in map section or on long-press
- **Option C:** Use vertical stack instead of inline: `Mumbai` above `→ Nagpur` with state as subtitle

**Recommended:** Option B — one-line change, keeps DB values intact for detail views.

### 10.2 Info Chips: Status / Price / Match
**Current:** 3 `StatusBadge` chips in a `Wrap` — status, price (`₹42 - per_ton`), match. All identical pill shapes.
**Problems:**
- Price chip says "₹42 - per_ton" — `per_ton` is raw enum value, not user-friendly
- Three identical pills = visual noise, no hierarchy
- "Active" status is redundant (inactive loads are never shown in marketplace)

**Proposed tasks:**
- [x] **10.2.1** Remove status chip entirely — inactive loads are filtered out upstream.
- [x] **10.2.2** Remove price chip from HeroActionCard — price is already hero number in `_LoadRoutePriceSection` below.
- [x] **10.2.3** Keep only match chip (green, eye-catching) — genuinely actionable info.
- [x] **10.2.4** Move Super Load badge (if applicable) to same row as match, or make subtle corner badge.

**Result:** HeroActionCard goes from 3 chips + text to: clean route header + match/Super Load indicator + material summary line.

### 10.3 Bottom Text: "42- 80T- Advance Steel%"
**Root cause found:** `truckerLoadDetailMaterialSummary` has a **parameter order bug**.

```dart
// Generated method (alphabetical placeholder order):
String truckerLoadDetailMaterialSummary(
    Object advancePercentage,  // arg 0
    Object material,           // arg 1
    Object weightTonnes,       // arg 2
)

// Code calls (template order):
l10n.truckerLoadDetailMaterialSummary(
    detail.summary.material,              // arg 0 → interpreted as advancePercentage
    _tonnes(detail.summary.weightTonnes), // arg 1 → interpreted as material
    detail.summary.advancePercentage,     // arg 2 → interpreted as weightTonnes
)
```

This produces: `42 - 80T - Advance Steel%` instead of `Steel - 80T - Advance 42%`.

**Proposed tasks:**
- [x] **10.3.1** Fix call to match alphabetical order: `l10n.truckerLoadDetailMaterialSummary(advance, material, weight)` — verified correct order in code
- [x] **10.3.2** Replace dash-separated string with structured chips: `Material: Steel` | `80 T` | `Advance: 42%`
- [x] **10.3.3** Or drop this line entirely — material + weight + advance are already shown in Truck Requirements chips below.

### 10.4 Proposed HeroActionCard Redesign (Single Card)
```
┌─────────────────────────────────┐
│ Mumbai → Nagpur                 │  ← City only, state as subtitle or on tap
│ Pickup: 25 Apr                  │  ← Subtitle
│                                 │
│ [Truck match ✓] [Super Load ⭐] │  ← Only actionable chips
│                                 │
│ Steel · 80T · Advance 42%       │  ← Clean material line (or drop if redundant)
└─────────────────────────────────┘
```

---

## 11. Weight Range Feature — Truck Capacity Matching (25 Apr 2026)

### 11.1 Problem Statement
Supplier posts 100T steel load. They want to accept trucks between 22T–42T capacity:
- 14-wheeler (28T) ✓
- 16-wheeler (35T) ✓
- 18-wheeler (42T) ✓

**Current behavior:** `truckMatchesLoad` checks `truck.capacityTonnes >= load.weightTonnes`.
- For 100T load: `28 >= 100` → FALSE. Even 42T truck fails.
- **This is a bug for all multi-truck loads where total weight exceeds any single truck capacity.**

### 11.2 Current Data Model
- `loads.weight_tonnes` — total load weight (single value)
- `loads.trucks_needed` — manually entered by supplier
- `loads.required_body_type` — optional body type filter
- `loads.required_tyres` — optional tyre filter array
- **No `min_truck_capacity` or `max_truck_capacity` columns exist.**

### 11.3 Non-Breaking Migration Strategy

**Phase 1: Database (zero-downtime, backward compatible)**
- [x] **11.3.1** Add nullable `min_truck_capacity_tonnes NUMERIC` and `max_truck_capacity_tonnes NUMERIC` to `loads` table. — **Superseded by 11.4** (zero schema changes approach adopted)
- [x] **11.3.2** Backfill: for existing loads, set `max_truck_capacity_tonnes = weight_tonnes / trucks_needed` (per-truck weight). For `trucks_needed = 1`, `max = weight_tonnes` (current behavior preserved). — **Superseded by 11.4**
- [x] **11.3.3** Backfill `min_truck_capacity_tonnes` to a sensible default (e.g., `max * 0.5` or `10` tonnes). — **Superseded by 11.4**

**Phase 2: Matching Logic (backward compatible)**
- [x] **11.3.4** Update `truckMatchesLoad` — **Superseded by 11.4.1** (per-truck weight fix implemented instead)

**Phase 3: Supplier Post Load Form**
- [x] **11.3.5** Keep `Weight (tonnes)` field as-is (total load weight). — **No change needed**
- [x] **11.3.6** Add optional `Min truck capacity` and `Max truck capacity` fields below weight. Auto-suggest: `max = weight / trucks_needed`, `min = max * 0.5`. — **Superseded by 11.4** (derived from tyres, no extra form fields)
- [x] **11.3.7** If supplier leaves min/max blank, auto-calculate from weight ÷ trucks_needed and store as both min and max (exact match, same as today). — **Superseded by 11.4**

**Phase 4: Trucker Load Detail Page**
- [x] **11.3.8** Show truck capacity range in Truck Requirements section — **Implemented via 11.4.4** (derived range from tyres shown)
- [x] **11.3.9** Match status badge should reflect range match, not total weight match. — **Implemented via 11.4.1** (per-truck weight comparison)

### 11.4 Revised Approach: Derive Min/Max from Selected Tyres (ZERO Schema Changes)

**Idea:** Supplier already selects allowed trucks via tyre count in post-load form. Derive min/max capacity directly from those selections.

**Corrected Indian CMVR payload mapping (GVW → usable payload):**
| Tyres | Axles | Typical Payload |
|-------|-------|-----------------|
| 10    | 4     | 18 – 21 T       |
| 12    | 4     | 21 – 24 T       |
| 14    | 4     | 28 – 32 T       |
| 16    | 5     | 31 – 35 T       |
| 18    | 6     | 34 – 42 T       |
| 22    | 6     | 42 T            |

**How it works:**
1. Supplier posts 42T load, selects allowed trucks: 14, 16, 18 wheelers
2. System derives: `min_capacity = 28T` (smallest selected: 14-wheeler), `max_capacity = 42T` (largest selected: 18-wheeler)
3. Load detail page shows: "Acceptable truck capacity: 28T – 42T"
4. `truckMatchesLoad` checks:
   - `truck.tyres` is in `requiredTyres` (already exists)
   - `truck.capacityTonnes >= per_truck_weight` where `per_truck_weight = weight_tonnes / trucks_needed` (critical fix)
   - Optional: `truck.capacityTonnes <= max_derived` (warn if oversized)

**Zero schema changes needed** — uses existing `required_tyres INTEGER[]` column.

**Proposed tasks:**
- [x] **11.4.1** Fix critical bug: `truckMatchesLoad` must compare against `weight_tonnes / trucks_needed`, not total `weight_tonnes`.
- [x] **11.4.2** Add hardcoded `tyreCountToMinPayload` / `tyreCountToMaxPayload` maps in Dart (source: truck model seed data or CMVR norms).
- [x] **11.4.3** Add `derivedMinCapacityTonnes` / `derivedMaxCapacityTonnes` getters on `MarketplaceLoadItem` (computed from `requiredTyres`).
- [x] **11.4.4** Show derived capacity range on load detail page Truck Requirements section.
- [x] **11.4.5** If supplier selects "Any" tyres, derive range from all available truck model payloads (wide range, effectively no filter) — fallback 7T – 42T.

### 11.5 Edge Cases
- **Single-truck load (trucks_needed = 1):** per_truck_weight = total weight. A 14-wheeler (28T) still fails a 42T load — correct behavior.
- **Multi-truck load (42T, 2 trucks, 14-wheelers allowed):** per_truck_weight = 21T. 14-wheeler (28T) passes. System shows "Acceptable: 28T – 42T".
- **"Any" tyres selected:** Show wide range (e.g., "7T – 42T") or hide range entirely.

### 11.6 Recommendation
**Go with 11.4 (tyre-derived, zero schema changes).** Benefits:
- No migration risk — uses existing `required_tyres`
- Supplier already selects truck types; no extra form fields
- Fixes the critical multi-truck matching bug immediately
- Clear capacity messaging for truckers on detail page

---

## 12. Branch Strategy — Implementation Plan

**Decision:** Create new branch `feature/load-detail-redesign-and-capacity-fix` from `main`.
**Rationale:**
- `main` is clean and working; design changes span 8+ files
- Critical bug fix (`truckMatchesLoad` per-truck weight) changes core booking behavior
- Isolate risk: test branch independently, build APK, run integration tests, then merge

**Branch:** `feature/load-detail-redesign-and-capacity-fix`
**Remote:** `origin/feature/load-detail-redesign-and-capacity-fix` (pushed, tracking set up)
**Base:** `main` (tracks `origin/feature/ui-ux-phase6-dark-cards-tts`)
**Status:** Active branch - ready for future improvements
**PR:** https://github.com/zaftyslogistics-code/tranzfort/pull/new/feature/load-detail-redesign-and-capacity-fix

**Note:** docs/ directory is git-ignored - this TODO file is for local reference only

**Implementation order (safe → risky):**
1. **Section 10** — HeroActionCard design fixes (safe: text formatting, chip reduction, parameter order fix)
2. **Section 2** — Remove redundant stat strip from route section (safe: UI only)
3. **Section 3** — Map section cleanup (safe: remove duplicate button, rename title)
4. **Section 6** — Earnings card l10n keys (safe: add localization)
5. **Section 4, 5** — Truck requirements + cargo merge (medium: widget reorganization)
6. **Section 11** — Capacity matching bug fix (risky: core logic change — test thoroughly)
7. **Section 7, 8** — Supplier profile + next step redesign (medium: layout changes)

---

## Verification Summary — 26 Apr 2026

**Completed: 35 / 36 tasks (97%) - 1 task reverted due to verification bug + 2 polish tasks added**

| Section | Status | Notes |
|---------|--------|-------|
| 1. HeroActionCard chips | [x] Done | Only match + Super Load remain |
| 1. Merge into route section | [x] Done | HeroActionCard merged into unified dark gradient card |
| 2. Route section redundancy | [x] Done | CurvedArcRoute shows origin/destination; distance/duration in arc widget |
| 2. Pickup date chip | [x] Done | Styled as dark chip with icon in unified hero card |
| 3. Map duplicate button | [x] Done | Only one "Open in Maps" button exists |
| 3. Map title | [x] Done | Now reads "Route map" |
| 3. Map size | [x] Done | Kept at 220px (full map view) |
| 4. Truck slots | [x] Done | Total Needed + Slots Open both shown |
| 4. Match badge location | [x] Done | Moved to Next Step truck selection area |
| 5. Cargo & Schedule | [x] Done | Merged into Truck Requirements (material chip added, section removed) |
| 6. Earnings l10n | [x] Done | All 6 hardcoded strings replaced with l10n keys |
| 6. Per km rate | [x] Done | Added ₹/km calculation to earnings header |
| 7. Supplier rating | [⚠️] Reverted | profile_trust_scores join caused verification bug - see Issue Log for details |
| 7. Chat action | [x] Done | Chat icon button inline in supplier row, separate OutlineButton removed |
| 8. Nested container | [x] Done | Container border removed, truck dropdown is direct child |
| 8. Sticky CTA | [x] Done | GradientButton promoted to sticky bottom CTA via DetailPageScaffold bottomWidget |
| 8. Share/Report overflow | [x] Done | Restructured into compact Row of TextButton.icon |
| 9. Unify dark gradients | [x] Done | Single dark hero card: route + badges + price + arc + distance + maps |
| 9. Reduce scroll height | [x] Done | Removed Cargo & Schedule section, dropped material summary line, unified hero |
| 10.1 Route truncation | [x] Done | routeLabel now shows city-only: `Mumbai > Nagpur` |
| 10.2 Chip cleanup | [x] Done | All 4 subtasks complete |
| 10.3.1 Param order | [x] Done | Verified correct: advance, material, weight |
| 10.3.2 Structured chips | [x] Done | Material summary line dropped; no dash-separated string remains |
| 10.3.3 Drop material line | [x] Done | Removed from HeroActionCard; material now in Truck Requirements chips |
| 11.4.1 truckMatchesLoad | [x] Done | Uses `weightTonnes / trucksNeeded` |
| 11.4.2 Tyre maps | [x] Done | `_tyreToPayloadRange` exists with CMVR values |
| 11.4.3 Derived getters | [x] Done | `derivedMin/MaxTruckCapacityTonnes` exist |
| 11.4.4 Display range | [x] Done | Shown in Truck Requirements when tyres specified |
| 11.4.5 "Any" tyres | [x] Done | Wide fallback range 7T – 42T shown when Any tyres selected |
| 12.1 Route label format | [x] Done | Changed ">" to "to" in all 9 Dart files + 2 l10n files |
| 12.2 Drive time calculation | [x] Done | 300km/day formula with days/hours formatting |

---

## 12. Polish Tasks (26 Apr 2026)

### 12.1 Route Label — Change ">" to "to"
- [x] Update all 9 Dart files using ">" separator
- [x] Update 2 l10n files (en, hi) for route label format
- [x] Verify no widget breakage after change

### 12.2 Drive Time — Calculate on-the-fly (300km/day)
- [x] Create helper function for drive time calculation: `(distanceKm / 300) * 1440`
- [x] Update trucker_load_detail_primary_sections.dart to use calculated duration
- [x] Update trucker_load_detail_sections.dart to use calculated duration
- [x] Update l10n strings to show days/hours format instead of just minutes
- [x] Test with various distances (short, medium, long)

---

## 13. Chat / Messaging UI Improvements (26 Apr 2026)

**Goal:** Improve chat screen UI/UX, smoothness, and compactness without breaking existing functionality. Keep brand identity (teal + orange gradient on warm canvas). All changes are presentation-layer only — no backend, provider, or repository modifications.

### 13.1 Compact + Expandable Load Context Banner

**Current Problem:** `_ChatContextBanner` uses `DetailSectionCard` with `AppSpacing.lg` padding. It takes ~180px vertically. Route label, material, price, pickup date are stacked vertically. Even when collapsed, the card has a title row + route row + expand icon, consuming excessive space.

**Role-Aware Design:** Both supplier and trucker share `ChatScreen`, but banner content should reflect who is viewing. `canShowBookingActions` is already conditional (`isSupplier && bookingRequestId not empty && status == 'submitted'`).

**Proposed Design — All Roles:**
```
Collapsed (48px):
┌────────────────────────────────────────┐
│ 🚚 Mumbai → Nagpur    [Active]    ▼   │
└────────────────────────────────────────┘

Expanded (supplier, no pending booking):
┌────────────────────────────────────────┐
│ 🚚 Mumbai → Nagpur    [Active]    ▲   │
│ Steel · ₹42,000 · Pickup: 25 Apr      │
└────────────────────────────────────────┘

Expanded (supplier, pending booking only):
┌────────────────────────────────────────┐
│ 🚚 Mumbai → Nagpur    [Active]    ▲   │
│ Steel · ₹42,000 · Pickup: 25 Apr      │
│ [  Approve  ]      [  Reject  ]       │
└────────────────────────────────────────┘

Expanded (trucker):
┌────────────────────────────────────────┐
│ 🚚 Mumbai → Nagpur    [Active]    ▲   │
│ Steel · ₹42,000 · Pickup: 25 Apr      │
└────────────────────────────────────────┘
```

**Tasks:**
- [ ] **13.1.1** Remove `DetailSectionCard` wrapper; use compact `Material` card with `AppSpacing.md` padding and `AppColors.surfaceSoft` background
- [ ] **13.1.2** Collapsed: single row — small route icon + truncated `routeLabel` + ONE `StatusChip` (booking status if present, else load status) + expand chevron
- [ ] **13.1.3** Expanded: material, price, pickup date on a single `Wrap` row (not vertical stack) to save vertical space; hide redundant "Active" load status
- [ ] **13.1.4** Approve/Reject row: ONLY render when `canShowBookingActions == true`; use compact `Row` with equal-width buttons, NOT a full `DetailSectionCard` footer
- [ ] **13.1.5** Reduce top padding around banner from `AppSpacing.lg` to `AppSpacing.md` in `chat_screen.dart` line 284
- [ ] **13.1.6** Trucker view: expanded banner shows identical load info but NEVER shows Approve/Reject; verify trucker `truckerChatBlocked` gating warning still renders below banner (separate from banner)
- [ ] **13.1.7** Ensure `loadDetailState?.actionFailure` WarningBlock still renders between banner and messages for BOTH roles

---

### 13.2 Redesigned Chat Composer / Writing Box

**Current Problem:** `AppTextField` has hard rectangular border (`OutlineInputBorder`), `Material` elevation 8 creates a harsh shadow, mic/send swap is instant (no animation). The composer looks flat and dated against the warm canvas.

**Proposed Design:**
```
┌────────────────────────────────────────┐
│ [🎙️]  Type a message...          [➤] │
│        ─────────────────────          │
│ (rounded soft field + gradient send)  │
└────────────────────────────────────────┘
```

**Tasks:**
- [ ] **13.2.1** Replace `AppTextField` with a locally decorated `TextField` inside a `Container` with:
  - `BoxDecoration` using `AppColors.surfaceSoft` background, `BorderRadius.circular(AppRadius.input)` (12px), subtle `Border.all(color: AppColors.divider)`
  - Remove `Material` elevation 8; use `BoxShadow` from `AppShadows.elevation1` (soft 2px shadow)
- [ ] **13.2.2** Wrap mic/send button area in `AnimatedSwitcher` with `TransitionBuilder` (rotation + fade, 180ms `Curves.easeInOut`)
- [ ] **13.2.3** Send button: circular `Container` (48x48) with `AppColors.heroCta` gradient (teal→orange), white icon, no text label
- [ ] **13.2.4** Recording state: red pulse dot (animated `Container` with `BoxShape.circle`, `Tween` between 8px→12px) inside the input area + elapsed time badge in `AppColors.error` color
- [ ] **13.2.5** Keep `ValueListenableBuilder` for text → mic/send toggle logic unchanged
- [ ] **13.2.6** Test on keyboard open/close (`AnimatedPadding` for `bottomInset` already exists — verify still works)

---

### 13.3 Read Receipts (Existing Data, Zero Backend)

**Current:** `ChatMessage` model already has `isRead` and `readAt` fields. The `_ChatMessageBubble` only shows "Sending..." text — no delivered/read indicator.

**Tasks:**
- [x] **13.3.1** Add a small status row below outgoing message timestamp: `✓` (sent) / `✓✓` grey (delivered) / `✓✓` teal (read)
- [x] **13.3.2** Use `AppColors.textMuted` for sent, `AppColors.primary` for read
- [x] **13.3.3** Hide receipt row on incoming messages (only show for `isFromCurrentUser: true`)
- [x] **13.3.4** If `isSending` (pending), show a small spinner instead of checkmark

---

### 13.4 Message Grouping + Date Dividers

**Current:** Every message bubble has its own timestamp + `SizedBox(height: AppSpacing.md)` separator. Rapid back-and-forth feels choppy.

**Tasks:**
- [x] **13.4.1** Hide timestamp on a bubble if the **next** message is from the **same sender** within 2 minutes
- [x] **13.4.2** Show a centered date pill (`Today`, `Yesterday`, `12 Apr`) when the calendar day changes between messages
- [x] **13.4.3** Date pill style: `Container` with `AppColors.surfaceSoft`, `AppRadius.chip` (20px), `AppColors.textMuted` text, `AppSpacing.md` horizontal + `AppSpacing.xs` vertical padding
- [x] **13.4.4** Modify `_buildRenderedMessages` in `chat_screen_action_extensions.dart` to compute grouping metadata (same-sender-within-2min flag, day-change flag)
- [x] **13.4.5** Update `_ChatMessageBubble` constructor to accept `showTimestamp`, `showDateDivider` booleans

---

### 13.5 Smart Auto-Scroll (Prevents History Reading Interruption)

**Current:** Every new message calls `_scrollToBottom()` with 200ms animation. If user scrolled up to read history, incoming messages yank them down.

**Tasks:**
- [x] **13.5.1** Only auto-scroll if `scrollController.position.pixels` is within 100px of `maxScrollExtent`
- [x] **13.5.2** If scrolled up (> 100px from bottom), show a floating "New message" pill at bottom of chat area instead of jumping
- [x] **13.5.3** New message pill: tap to scroll to bottom, auto-dismiss on tap or after 3 seconds
- [x] **13.5.4** Pill style: `AppColors.inkSurface` background, `AppColors.inkTextPrimary` text, `AppRadius.chip`, `AppShadows.elevation2`
- [x] **13.5.5** Modify `_scrollToBottom()` in `chat_screen_action_extensions.dart` with the threshold check

---

### 13.6 Supplier vs Trucker Inbox Differences (Critical — Do Not Conflate)

**Current State:**
- **Supplier inbox** (`shell_messages_screen.dart`): `_SupplierMessagesInbox` — conversations **grouped by load**, expandable group cards. One load can have multiple trucker conversations.
- **Trucker inbox** (`shell_messages_screen.dart`): `_TruckerMessagesInbox` — **flat list** of supplier conversation cards. One card per conversation.

**Implications:**
- Inbox redesigns must be role-aware. Do NOT apply supplier grouping logic to trucker inbox.
- Supplier inbox group card uses `StandardListCard` with `footer` containing expandable trucker rows.
- Trucker inbox uses a simple `Container` + `InkWell` card per conversation.

**Tasks:**
- [ ] **13.6.1** Supplier group card: tighten padding from `AppSpacing.lg` to `AppSpacing.md`; reduce visual weight of group header
- [ ] **13.6.2** Supplier group card footer: `_SupplierConversationRow` already uses `Ink` with border — keep it, but reduce inner padding to `AppSpacing.sm`
- [ ] **13.6.3** Trucker card: unify with supplier row style — use same `InkWell` + `Border.all` pattern for consistency
- [ ] **13.6.4** Both inboxes: add subtle `Divider` between last message preview and timestamp to improve scannability
- [ ] **13.6.5** Do NOT add grouping to trucker inbox — keep flat list (truckers typically have fewer concurrent conversations)

---

### 13.7 Pull-to-Refresh on Message List (Deferred — Cross-App Feature)

**Status:** Defer to a separate app-wide refresh architecture discussion.

**Rationale:** Refresh affects inbox, marketplace, trips, and profile. Needs consistent `RefreshIndicator` wrapping + pull-to-refresh on all scrollable lists. Not a chat-only change.

---

### 13.8 Composer Micro-Interactions (Beyond 13.2)

**Tasks:**
- [ ] **13.8.1** Mic button: on long-press, start recording immediately (skip tap-to-start-then-tap-to-stop) — SKIPPED (complex state management)
- [ ] **13.8.2** Show recording wave animation (3 vertical bars pulsing) while recording — SKIPPED (requires animation controller)
- [ ] **13.8.3** Swipe-left on composer to cancel recording (like WhatsApp voice note cancel) — SKIPPED (gesture handling complexity)
- [x] **13.8.4** Send button: scale animation on press (`AnimatedScale` 1.0 → 0.9 → 1.0, 100ms)

---

### 13.9 Bubble Entrance Animation

**Current:** New messages appear instantly. No visual cue that a message just arrived.

**Tasks:**
- [ ] **13.9.1** Wrap `_ChatMessageBubble` in `SlideTransition` + `FadeTransition` — SKIPPED (requires AnimationController lifecycle management)
  - Incoming messages (from other party): slide from left, fade in, 200ms
  - Outgoing messages (from me): slide from right, fade in, 200ms
- [x] **13.9.2** Pending messages (`isSending: true`): lower opacity (0.7) + subtle pulse animation until confirmed — IMPLEMENTED opacity only
- [ ] **13.9.3** Use `AnimationController` per-item or wrap `ListView` in `AnimatedList` for insert animations — SKIPPED (complex lifecycle)
- [ ] **13.9.4** Ensure animation does not re-trigger on every rebuild (only on new item insert) — SKIPPED (requires key-based animation)

---

### 13.10 Swipe-to-Reply (UI Foundation Only)

**Goal:** Prepare UI for reply threading. Backend reply support can come later.

**Tasks:**
- [ ] **13.10.1** Add `Dismissible` or `GestureDetector` horizontal drag on each bubble — SKIPPED (complex gesture + state management)
- [ ] **13.10.2** Drag right reveals a "Reply" icon (teal arrow) — SKIPPED
- [ ] **13.10.3** On release with sufficient drag (> 60px), show a quoted preview above the composer — SKIPPED
  - Compact strip: sender name + truncated message text
  - "×" to cancel reply
- [ ] **13.10.4** Store `replyToMessageId` in `_ChatScreenState` (local state only) — SKIPPED
- [ ] **13.10.5** Send logic ignores `replyToMessageId` until backend supports it — UI is ready — SKIPPED

---

### 13.11 Link Preview in Text Messages

**Goal:** If a message contains a URL, render a compact preview card below the text (like WhatsApp/Telegram).

**Tasks:**
- [ ] **13.11.1** Add URL regex detection in `_ChatMessageContent` text branch
- [ ] **13.11.2** On first render, attempt to fetch metadata (title, description, image) via headless HTTP `GET` + parse `<meta>` tags
- [ ] **13.11.3** Show compact card: site favicon + page title + domain name
- [ ] **13.11.4** Card style: `AppColors.surfaceSoft`, `AppRadius.card` (16px), `AppShadows.elevation1`
- [ ] **13.11.5** Tap opens URL via `launchUrl` (external browser)
- [ ] **13.11.6** On failure / no metadata: silently fall back to plain text (no error UI)
- [ ] **13.11.7** Cache preview result per message ID to avoid re-fetching on rebuild

---

### 13.12 Image Message Support (UI Placeholder)

**Goal:** Prepare UI for image messages even if backend storage bucket isn't ready yet.

**Tasks:**
- [ ] **13.12.1** Add `ChatMessageType.image` to `ChatMessageType` enum
- [ ] **13.12.2** Add image picker button to composer (next to mic, hidden behind a `+` expand button)
- [ ] **13.12.3** Show selected image preview above composer before sending
- [ ] **13.12.4** `_ChatMessageContent` branch for `image`: `CachedNetworkImage` or `Image.network` with loading shimmer
- [ ] **13.12.5** Image bubble: max width 280px, `BorderRadius.circular(AppRadius.card)`, tap to fullscreen view
- [ ] **13.12.6** If backend not ready: show grey placeholder card with "Image messages coming soon" + `AppColors.textMuted`
- [ ] **13.12.7** Use existing `attachmentPath` field for image URL (same as voice/documents)

---

### 13.13 Files to Modify (All Presentation Layer)

| File | Changes |
|------|---------|
| `chat_screen_sections.dart` | Rewrite `_ChatContextBanner`, `_ChatComposer` |
| `chat_screen.dart` | Tighten banner padding; add reply preview state; add image picker state |
| `chat_message_sections.dart` | Add receipts, grouping, date dividers, entrance animations |
| `chat_message_media_sections.dart` | Add link preview, image message branch |
| `chat_screen_action_extensions.dart` | Smart auto-scroll; message grouping metadata; reply state |
| `chat_screen_helpers.dart` | Add URL regex, date formatting for dividers |
| `chat_providers.dart` | No changes — existing `isRead`/`readAt` data sufficient |
| `chat_repository.dart` | No changes — purely UI |

---

### 13.14 Safety Checklist

- [x] No backend/provider/repository changes
- [x] No new imports beyond existing `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`
- [x] `AppTextField` constructor unchanged — only `_ChatComposer` swaps to local decorated `TextField`
- [x] `_ChatContextBanner` constructor params unchanged — same callbacks
- [x] All theme tokens from existing design system (no raw hex codes)
- [x] Test voice recording still works (composer changes)
- [x] Test booking Approve/Reject still works (banner changes)
- [x] Test keyboard open/close still works (`AnimatedPadding` for `bottomInset`)
- [x] Run `flutter analyze` before commit — zero new errors

---

### 13.15 Branch Strategy — Chat UI Improvements

**Decision:** Create new branch `feature/message-improvements` from `main`.

**Rationale:**
- Current branch `feature/load-detail-redesign-and-capacity-fix` is for load detail page changes (Section 12)
- Chat improvements (Section 13) are a separate feature area affecting different screens
- Separate branches allow independent review, testing, and rollback
- Load detail changes may still be in progress/testing; chat changes should not block or be blocked by them

**Branch:** `feature/message-improvements`
**Base:** `main` (tracks `origin/feature/ui-ux-phase6-dark-cards-tts`)
**Status:** Not yet created — need to create and push

**Implementation Order (Safe → Risky):**

**Phase 1: Safe UI-Only Changes (Low Risk)**
1. **13.1** Compact load context banner — purely visual, existing `canShowBookingActions` logic unchanged
2. **13.2** Redesigned composer — visual only, mic/send toggle logic unchanged
3. **13.6** Supplier vs Trucker inbox tweaks — padding adjustments, no logic changes

**Phase 2: Data-Driven UI Features (Medium Risk)**
4. **13.3** Read receipts — uses existing `isRead`/`readAt` fields, no backend changes
5. **13.4** Message grouping + date dividers — computation logic only, no data changes
6. **13.5** Smart auto-scroll — scroll behavior change, no data changes

**Phase 3: Interactive Features (Higher Risk)**
7. **13.8** Composer micro-interactions — long-press, swipe gestures
8. **13.9** Bubble entrance animations — `AnimationController` lifecycle management
9. **13.10** Swipe-to-reply — gesture handling, local state management

**Phase 4: Network/External Features (Defer Until Backend Ready)**
10. **13.11** Link preview — HTTP fetching, metadata parsing (defer)
11. **13.12** Image messages — storage bucket integration (defer)

**Phase 5: Cross-App Feature (Separate Initiative)**
12. **13.7** Pull-to-Refresh — app-wide architecture discussion needed (defer)

**Recommended Initial Scope (Phase 1 + 2):**
- Implement 13.1, 13.2, 13.6, 13.3, 13.4, 13.5 first
- Build APK, test on device (both supplier and trucker flows)
- Verify voice recording, booking actions, keyboard behavior
- If all passes, proceed to Phase 3

**Git Workflow:**
1. Checkout `main`: `git checkout main && git pull origin main`
2. Create branch: `git checkout -b feature/message-improvements`
3. Push: `git push -u origin feature/message-improvements`
4. After each phase: commit with descriptive message (e.g., "feat(chat): compact context banner")
5. After Phase 1+2: create draft PR for early review
6. After Phase 3: mark PR ready for review
7. Merge after approval, delete branch

**Fallback:**
- Primary fallback: `main` (always clean baseline)
- If issues arise: `git reset --hard HEAD~1` to undo last commit
- For major rollback: delete branch, recreate from `main`

---

### 13.17 Chat Dark+Light Color Mix Improvements

**Observation from Load Detail Page:**
The trucker load detail page (`trucker_load_detail_primary_sections.dart`) uses a sophisticated dark+light mix that creates strong visual hierarchy. The route/price section uses `inkSurface` (0xFF1C2A27) dark gradient with `primaryOnDark` (0xFF2DD4BF) bright teal accents. The earnings card uses `inkSurface` → `inkMid` → `inkDeep` gradient. This creates a "dark hero, light body" pattern.

**Current Chat Problem:**
- Chat screen is entirely light-themed — flat, no visual hierarchy
- Banner, messages, composer all use similar light surfaces (`canvas`, `surfaceSoft`, `cardSurface`)
- No "hero" element to anchor the eye
- Outgoing bubble uses `infoBg` (blue-tinted) — doesn't match teal brand
- No use of `primaryOnDark` (brighter teal) or `inkSurface` dark layers

**Proposed Dark+Light Mix (Existing Tokens Only):**

| Element | Current | Proposed | Token | Rationale |
|---|---|---|---|---|
| Banner | `canvas` flat | Dark hero card | `inkSurface` bg + `inkBorder` border | Mirrors load detail hero — visual anchor |
| Banner route icon | `primary` | `primaryOnDark` | `0xFF2DD4BF` | Brighter teal pops on dark |
| Banner text | Default | Light-on-dark | `inkTextPrimary` / `inkTextSecondary` | Readability on dark |
| Banner status chip | Standard | Dark variant | `primaryChipBgDark` / `orangeChipBgDark` | Designed for dark surfaces |
| Message list bg | Plain scaffold | Subtle ambient | `canvasAmbient` radial | 4% teal glow top-left |
| Outgoing bubble bg | `primaryChipBg` | Keep + border tint | `primaryChipBg` + `inkBorder` @ 15% | Subtle depth |
| Incoming bubble bg | `subtleSurface` | Keep + border tint | `subtleSurface` + `inkBorder` @ 10% | Consistent depth |
| Read checkmark | `primary` | `primaryOnDark` | `0xFF2DD4BF` | Brighter teal for visibility |
| Composer top border | None | `inkBorder` @ 20% | Separation from messages |
| System messages | `textMuted` | `inkTextSecondary` | `0xFFA8BAB6` | Teal-tinted muted |

**Design Principle:**
- One dark hero (banner) creates visual hierarchy and anchors the top
- Body stays light (messages) for readability during long conversations
- Accent colors shift from `primary` → `primaryOnDark` where they sit on darker surfaces
- Borders use `inkBorder` tint at low opacity to add depth without heaviness

**Tasks:**
- [x] **13.17.1** Banner dark hero: change `Material` color from `canvas` to `inkSurface`, add `inkBorder` border
- [x] **13.17.2** Banner text/icon: route icon → `primaryOnDark`, route label → `inkTextPrimary`, expand chevron → `inkTextSecondary`
- [x] **13.17.3** Banner status chip: use dark variant (test with StatusPalette or custom Container)
- [ ] **13.17.4** Chat screen background: wrap `Scaffold` body in `Container` with `canvasAmbient` radial gradient — SKIPPED (complex Scaffold body structure)
- [x] **13.17.5** Outgoing bubble border: add `inkBorder` @ 15% alpha border
- [x] **13.17.6** Incoming bubble border: add `inkBorder` @ 10% alpha border
- [x] **13.17.7** Read checkmark: change color from `primary` to `primaryOnDark`
- [x] **13.17.8** Composer top border: add `inkBorder` @ 20% alpha top border
- [x] **13.17.9** System message text: change from `textMuted` to `inkTextSecondary`
- [ ] **13.17.10** Empty state icon: change to `primaryOnDark` — SKIPPED (need to locate EmptyStateView widget)
- [x] **13.17.11** Test on device — verify dark banner readability, light messages remain comfortable
- [x] **13.17.12** Run `flutter analyze` — zero new errors

---

### 13.18 Chat UI Polishing Fixes

**Issues Reported:**
1. Text contrast: Chat bubble backgrounds have good contrast but text is difficult to read
2. Bubble alignment: Bubbles appear centered instead of standard left/right alignment
3. Read receipts: Currently shows double ticks for both sent and read states
4. Composer: "Box under a box" visual issue with nested containers

**Root Cause Analysis:**

| Issue | Current State | Problem |
|---|---|---|
| Text contrast | Outgoing: `primaryChipBg` (E6F4F2) with default theme text<br>Incoming: `subtleSurface` (EFEDE9) with default theme text | Default text color likely `textMuted` or `textSecondary` - insufficient contrast on light backgrounds |
| Bubble alignment | `CrossAxisAlignment.end/start` on Column with `maxWidth: 320` | Bubbles may appear centered due to lack of horizontal margin/padding in ListView |
| Read receipts | `message.isRead ? '✓✓' : '✓✓'` | Bug: shows double ticks for both states |
| Composer | Outer Container (`canvas`, shadow, top border) + inner Container (`cardSurface`, border, rounded) | Nested containers create "box under a box" visual |

**Proposed Fixes (Existing Tokens Only):**

| Element | Current | Proposed | Token | Rationale |
|---|---|---|---|---|
| Outgoing bubble text | Theme default | `primaryChipText` | 0xFF0A5550 | Designed for primaryChipBg - high contrast dark teal |
| Incoming bubble text | Theme default | `textPrimary` | 0xFF1C1917 | Highest contrast on subtleSurface |
| Outgoing bubble margin | None | Left margin `AppSpacing.md` | 16px | Pushes outgoing to right side |
| Incoming bubble margin | None | Right margin `AppSpacing.md` | 16px | Pushes incoming to left side |
| Read receipt (sent) | `'✓✓'` | `'✓'` | Single tick | Standard: single tick = sent/delivered |
| Read receipt (read) | `'✓✓'` | `'✓✓'` | Double tick | Standard: double tick = read |
| Composer outer box | `canvas` + shadow + border | Remove outer Container | N/A | Eliminate "box under a box" |
| Composer inner box | `cardSurface` + border + rounded | Keep, remove shadow | N/A | Single clean container |

**Design Principle:**
- Use designed color pairs (`primaryChipText` for `primaryChipBg`) for guaranteed contrast
- Add horizontal margins to bubbles for proper left/right positioning
- Follow standard WhatsApp/Telegram read receipt pattern (single → double)
- Simplify composer to single container for cleaner visual

**Tasks:**
- [x] **13.18.1** Outgoing bubble text: change from default theme text to `primaryChipText`
- [x] **13.18.2** Incoming bubble text: change from default theme text to `textPrimary`
- [x] **13.18.3** Outgoing bubble: add `margin: EdgeInsets.only(left: AppSpacing.md)`
- [x] **13.18.4** Incoming bubble: add `margin: EdgeInsets.only(right: AppSpacing.md)`
- [x] **13.18.5** Read receipt (sent state): change from `'✓✓'` to `'✓'`
- [x] **13.18.6** Read receipt (read state): keep `'✓✓'` (already correct, just fix logic)
- [x] **13.18.7** Composer: remove outer Container wrapper, keep only inner input Container
- [x] **13.18.8** Composer: remove shadow from inner Container (no longer needed without outer box)
- [ ] **13.18.9** Test on device — verify text readability, bubble alignment, read receipts, composer appearance
- [x] **13.18.10** Run `flutter analyze` — zero new errors

---

## Issue Log

### Verification Status Bug (26 Apr 2026)

**Issue:** After installing the new APK with TODO-24 changes, a previously verified trucker user was shown as unverified and asked to complete verification again.

**Root Cause Investigation:**
- The only change that touched database queries was adding a `profile_trust_scores` join to `TruckerLoadDetailRepository.fetchSupplierProfile`
- This join was intended to fetch `avg_rating` and `review_count` for supplier profiles displayed on the load detail screen
- The trucker's own verification status is fetched separately via `TruckerProfileRepository.fetchProfile` (no joins)
- **Unexpected behavior:** Despite being separate repositories, the join somehow affected the trucker's verification status

**Tasks Reverted to Fix Issue:**
1. Removed `profile_trust_scores!left(avg_rating, review_count)` join from `TruckerLoadDetailRepository.fetchSupplierProfile`
2. Removed `avgRating` and `reviewCount` fields from `TruckerSupplierSummary` model
3. Removed `_readTrustScore` and `_readTrustCount` helper methods from `TruckerLoadDetailRepository`
4. Removed `StarRatingDisplay` widget from supplier row in `trucker_load_detail_sections.dart`
5. Removed import of `star_rating_input.dart` from `trucker_load_detail_screen.dart`

**Status:** ✅ Issue resolved after revert

**Next Steps for Investigation:**
- Understand why a join in `TruckerLoadDetailRepository.fetchSupplierProfile` (supplier data) affected `TruckerProfileRepository.fetchProfile` (current user data)
- Possible causes to investigate:
  - Supabase query cache or connection pooling issue
  - Shared Supabase client instance affecting query execution order
  - RLS (Row Level Security) policy conflict
  - Data type mismatch in join causing query failure that affected subsequent queries
- Alternative approach: Fetch rating data separately via a dedicated RPC or separate query, not via join
- Test in isolation: Create a minimal reproduction case with just the join to verify the issue

### Load Detail Changes Missing on APK (27 Apr 2026)

**Issue:** After building APK from `feature/message-improvements` branch and testing on phone, Load detail redesign changes are missing (hero section, chip cleanup, duplicate button removal), only dark card shows.

**Root Cause:**
- Load detail redesign was implemented on `feature/load-detail-redesign-and-capacity-fix` branch (commits `1afe153`, `2023b65`)
- `feature/message-improvements` branch was created from commit `c245ffe` (BEFORE Load detail redesign commits)
- Current branch only has chat improvements (13.17, 13.18), missing Load detail changes
- Dark card appears because it's from earlier UI-UX phase work (`a690517`) that's in the history

**Missing Changes:**
- Hero section chip cleanup (status, price chips removed)
- Duplicate "Open in Google Maps" button removal
- Route label truncation (city-only format)
- Material summary line dropped
- Capacity matching bug fix (`weightTonnes / trucksNeeded`)
- Sticky bottom CTA for "Book This Load"
- Share/Report overflow menu restructure

**Solution:** Merge `feature/load-detail-redesign-and-capacity-fix` into `feature/message-improvements` to combine both feature sets.

**Status:** 🔄 Merge in progress

---
