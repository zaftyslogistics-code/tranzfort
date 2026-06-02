# LOADPOST-2-JUNE — Fresh Restart Blueprint (Design-Safe, Scale-Ready)

**Date:** 2 June 2026  
**Status:** Planning baseline (fresh start)  
**Branch intent:** `v1-launch` compatible rollout with no UI breakage

---

## 1) Why restart from scratch

We are restarting LOADPOST with one strict priority:

- Keep current load post flow clean and familiar.
- Add Indian-standard truck/category/material taxonomy without breaking layout.
- Build data and API foundations first, then progressive UI upgrades.
- Ensure performance for large catalogs (800+ materials) and growth traffic.

This document replaces prior implementation attempts as the new working source for planning and execution.

---

## 2) Product decisions locked on 2 June

1. **No "Other" material option.**
2. **Material must be selected from master table only** (fixed names/codes).
3. **Material selection UX = typeahead input + suggestions**, not long dropdown.
4. **Existing Post Load screen structure remains** (Route -> Cargo -> Vehicle -> Pricing -> Listing -> Review).
5. **Vehicle requirements move to state-aware selector** (summary chip/tile + drawer/sheet editor), not long fixed chip rows.
6. **Backend is catalog-driven** (no hardcoded UI constants).
7. **Scalability is mandatory** (indexed search, debounce, cache, limited result windows).
8. **Notation lock:** use **`W` for wheels** and **`T` for tons** everywhere.
9. **Find Loads layout continuity:** keep current compact pinned filter structure; extend with extra chips/data + state-aware drawers only.
10. **No major visual restructuring** for Post Load, Find Loads, or Add Truck in phase-1.

### 2.1 Notation lock (global copy + data display rule)

This rule applies to Post Load, Find Loads, Fleet, Load Detail, cards, filters, TTS, share text, and admin screens.

- Wheels/wheeler count: `6W`, `10W`, `12W`, `16W`, `18W`, `22W`.
- Tonnage: `7 T`, `28 T`, `36-40 T`.
- Never use `T` for tyre/wheel labels.
- Avoid mixed/ambiguous labels like `12T` when it means wheels.
- Summary format example: `Open • Full+Half • 16W,18W • 28 T cargo`.

---

## 3) Scope (Phase-1 vs Later)

### Phase-1 (must ship first)

- Material catalog table + API search.
- Remove material "other" path.
- Cargo material typeahead in current Cargo Details section.
- Vehicle category/config catalog tables.
- Vehicle summary tile + edit drawer in current Vehicle Requirements section.
- Backward-compatible write path to existing fields (for safe migration window).

### Phase-2 (after stability)

- Full-screen pickers where needed.
- Advanced grouped material browsing.
- Optional ranking/personalization for frequent materials.
- Full matching migration to configuration-first enforcement.

---

## 4) Backend and table design (fresh)

## 4.1 Materials

### `material_groups`

- `code` (PK, text)
- `name_en` (text)
- `name_hi` (text, nullable)
- `sort_order` (int)
- `is_active` (bool default true)

### `materials`

- `code` (PK, text, stable slug)
- `name_en` (text, required)
- `name_hi` (text, nullable)
- `group_code` (FK -> `material_groups.code`, nullable in phase-1)
- `keywords` (text[] default '{}')
- `search_vector` (tsvector generated/indexed)
- `popularity_score` (int default 0)
- `is_active` (bool default true)
- `created_at`, `updated_at`

### `loads` additions

- `material_code` (FK -> `materials.code`, required for new posts)
- Keep existing `material` text for legacy display/search bridge during migration.

---

## 4.2 Vehicle catalogs

### `vehicle_categories`

- `code` (PK)
- `name_en`, `name_hi`
- `sort_order`
- `is_active`
- `ui_mode` (ex: `model`, `length_ton`, `ton_tyre`, `ton_only`)

### `vehicle_body_styles`

- `code` (PK)
- `name_en`, `name_hi`
- `is_active`

### `vehicle_category_body_styles`

- `category_code` (FK)
- `body_style_code` (FK)
- composite PK (`category_code`, `body_style_code`)

### `vehicle_configurations`

- `code` (PK)
- `category_code` (FK)
- `label_en`, `label_hi`
- `tyres` (int, nullable)
- `length_ft` (int, nullable)
- `passing_ton_min` (numeric, nullable)
- `passing_ton_max` (numeric, nullable)
- `is_active`
- `sort_order`

### `loads` additions (vehicle)

- `required_vehicle_category_code` (text)
- `required_body_style_codes` (text[])
- `required_configuration_codes` (text[])

Keep legacy `required_body_type` and `required_tyres` until compatibility sunset.

---

## 4.3 Performance indexes (must-have)

- `materials`:
  - btree on `is_active`
  - btree on `lower(name_en)`
  - gin/trgm on `name_en`
  - gin on `keywords`
  - gin on `search_vector`
- `vehicle_configurations`:
  - btree on `category_code`, `is_active`
- `loads`:
  - btree on `material_code`
  - gin on `required_configuration_codes`

---

## 5) API contracts (phase-1)

### 5.1 Material search RPC

`search_materials(p_query text, p_limit int default 15)`

Rules:

- min query length: 2
- exact prefix ranks highest
- then word prefix
- then keyword matches
- only active materials

Response:

- `code`
- `name_en`
- `name_hi`
- `group_code` (optional)

### 5.2 Vehicle catalog RPC

`get_vehicle_catalog()`

Returns:

- categories
- body styles by category
- configurations by category

### 5.3 Create load RPC extension

Accept:

- `p_material_code`
- `p_required_vehicle_category_code`
- `p_required_body_style_codes`
- `p_required_configuration_codes`

Compatibility:

- continue dual-write mapping to legacy fields until old readers are retired.

### 5.4 Related RPCs that must be updated (not optional)

The restart is not only Post Load. These read/write paths must be aligned with the new material and vehicle model:

- marketplace feed RPC (`get_marketplace_feed` family)
- trucker load detail RPC (`get_trucker_load_detail`)
- supplier load list/detail RPCs
- repost clone RPC (`clone_load_for_repost`)
- booking guard RPC (`truck_matches_load_requirements`)
- booking submit RPC (`submit_booking_request`)
- truck create/update RPCs for fleet and verification

---

## 6) UI-UX replan (keep current clean flow)

We retain current section order and cards. Only inputs evolve.

### 6.0 Visual continuity rule (important)

For this restart, use the current production layout pattern as baseline:

- keep pinned filter architecture on Find Loads
- keep compact cards and section card rhythm
- keep existing spacing and header hierarchy
- add capability through chips/data/drawers, not through large new layout blocks

In short: **same layout shell, richer controls**.

## 6.1 Cargo Details (new material UX)

Replace dropdown with:

- **Material input field** (`AppTextField` style, same card)
- **Live suggestion list** below field
- **Selected material chip/tile** after selection

Behavior:

- Typing `plas` shows relevant items:
  - Plastic
  - Plastic Product
  - Plastic Granules / Dana
  - Plastic Scrap
- Tap selection locks `material_code`.
- Clear icon resets selection.
- No free-text submission allowed.

Validation:

- submit only when `material_code != null`

---

## 6.2 Vehicle Requirements (state-aware selector)

Replace fixed body dropdown + tyre chip row with:

- **Summary tile/chip** inside same section:
  - Example: `Open • Full+Half • 16W,18W`
- **Edit button** -> opens drawer/bottom sheet:
  1. select category
  2. select body styles (if applicable)
  3. select configurations
  4. done -> summary updates

This keeps the screen visually compact while supporting large catalogs.

## 6.3 Find Loads filter (must be touched in same program)

Find Loads cannot remain on old body/tyre-only assumptions if Post Load shifts to catalog data.

Target:

- Keep existing compact dark pinned filter layout.
- Replace hardcoded truck chips with category-aware filter summary.
- Keep default as `Any` (no category filter selected initially).
- Add "Edit truck filter" action that opens same selector model as post load.
- Apply filters via explicit action (`Show loads`) to reduce refetch churn.
- Keep quick compact chips for small/common sets; when option set is large, open drawer instead of expanding inline chips.
- Keep current pinned behavior style:
  - row remains compact and scroll-safe
  - default selected state remains clearly visible (`Any`)
  - no oversized pinned container growth for large datasets

Drawer behavior (Find Loads):

- Tap category/config summary chip -> open drawer.
- Drawer handles large lists with search + grouped sections + multi-select.
- Closing drawer updates a single summary row in pinned filter.
- Pinned area height stays compact (avoid large vertical expansion in feed header).

Chips/data extension rule:

- Existing chip row stays.
- Add only necessary chips (category/body/config/ton summary).
- Large selection sets collapse into summary chip (`+N more` pattern).
- Use drawer for full editing of long option sets.

Filter summary examples:

- `Any`
- `Open • 16W`
- `Container • 32 ft • 20-24 T`

## 6.4 Trucker add/edit truck flow (must be touched)

Fleet add/edit must be upgraded or booking matching will drift.

Target truck input model:

- category (required)
- body style (required when category requires)
- configuration code (required)
- passing ton (`T`) numeric (required)

UI strategy:

- keep current add/edit layout style
- replace static dropdown/chips with the same state-aware selector pattern
- show read-only summary tile after selection
- if options are many, open selector drawer/screen from compact tile (do not force long inline chip rows)
- keep form visually clean by rendering only selected highlights in-card; full selection experience lives in drawer
- preserve existing compact form rhythm and field order where possible

## 6.5 Trucker truck details and load details (must be touched)

Wherever truck/load requirements are displayed, show the same normalized format:

- category
- body style (if applicable)
- configuration(s)
- cargo ton (`T`)
- passing ton (`T`) where relevant

Avoid old ambiguous rendering.

---

## 7) Sample UI layout (for design + engineering)

```text
---------------------------------------------------------
POST LOAD
---------------------------------------------------------
[Route & Timing Card]
  Origin city / exact location
  Destination city / exact location
  Pickup date

[Cargo Details Card]
  Material *
  [ Text box: "Type material (e.g. Plastic)"      ]
  [suggestions]
   - Plastic
   - Plastic Product
   - Plastic Granules / Dana
   - Plastic Scrap
  Selected: [ Plastic Granules / Dana  x ]

  Cargo weight (tonnes) *
  [ 28 ]

[Vehicle Requirements Card]
  Truck preference *
  [ Open • Full+Half • 16W,18W ]   [Edit]
  (Edit opens drawer)

  Trucks needed *
  [1] [5] [10] [25]  + input box

[Pricing & Schedule Card]
  price + type + advance

[Listing Duration Card]

[Review Summary Card]
  Route
  Material (fixed from master)
  Cargo weight
  Vehicle summary
  Price
---------------------------------------------------------
```

### Drawer sample (Vehicle edit)

```text
--------------------------------
Truck Preference
--------------------------------
Category
 ( ) Open
 ( ) Container
 ( ) Trailer
 ...

Body style (if category=open)
 [x] Half body
 [x] Full body

Configurations
 [x] 16W
 [x] 18W
 [ ] 22W

             [Cancel] [Done]
--------------------------------
```

### Find Loads filter sample (compact + drawer)

```text
---------------------------------------------------------
FIND LOADS (Pinned Filter Band - Dark)
---------------------------------------------------------
[ All ] [ Super ]

Truck filter: [ Any ] [Open] [Container] ...    [Edit]
Route: [Origin] -> [Destination]

[Show loads]
---------------------------------------------------------

When selected:
Truck filter: [ Open ] [16W] [36-40 T] [ +2 ]  [Edit]
Summary line (optional): Open • Full+Half • 16W,18W • 36-40 T
```

```text
--------------------------------
Drawer: Edit Truck Filter
--------------------------------
Category
 ( ) Any
 ( ) Open
 ( ) Container
 ( ) Trailer
 ...

Body style (if applicable)
 [x] Full body
 [x] Half body

Configurations / Wheelers
 [x] 16W
 [x] 18W
 [ ] 22W

Passing range (optional)
 [ ] 31-35 T
 [x] 36-40 T

             [Reset] [Apply]
--------------------------------
```

### Trucker add truck flow sample (compact + drawer)

```text
---------------------------------------------------------
ADD TRUCK
---------------------------------------------------------
[Vehicle Identity Card]
  Registration number
  Brand/model

[Truck Classification Card]
  Truck type *
  [ Open • Full body • 16W • 33-35 T ]   [Edit]
  (Edit opens drawer for full selection)

  Passing capacity (T) *
  [ 34 ]

[Submit]
---------------------------------------------------------
```

```text
--------------------------------
Drawer: Select Truck Type
--------------------------------
Step 1: Category
  Open / Container / Trailer / Tanker / ...

Step 2: Body style
  Full body / Half body / Flat bed / ...

Step 3: Configuration
  14W / 16W / 18W / 22W
  (or length-based list by category)

Step 4: Suggested passing bands
  31-35 T / 36-40 T / ...

            [Back] [Done]
--------------------------------
```

### Pinned filter continuity checklist

- [ ] Keep default `Any` as selected when no truck filter applied.
- [ ] Keep pinned band compact; no large persistent grids.
- [ ] Add extra chips only for selected/high-value states.
- [ ] Use drawer for heavy selection edits.
- [ ] Keep `Show loads` apply flow and avoid refetch on every micro-change.

---

## 8) Scalability and latency targets

- Material suggestions visible under 250 ms p95.
- Debounce: 250 ms.
- Default limit: 12 suggestions.
- Client cache:
  - cache by query prefix
  - TTL 10 minutes
- No full 800+ list render in UI.
- All search server-side + indexed.

Additional platform-scale requirements:

- Find Loads filter changes must not trigger unbounded refetch loops.
- Vehicle catalog API responses should be cacheable (ETag/version).
- Matching queries should rely on indexed code arrays, not broad text `ILIKE`.
- Keep payloads compact (codes over long labels in RPC response, labels resolved client-side from catalog map where possible).

---

## 9) Migration plan (safe rollout)

1. Add new tables + seed data.
2. Add read/search RPCs.
3. Add new load columns.
4. Update app UI for material typeahead and vehicle summary selector.
5. Dual-write old+new fields.
6. Observe production metrics/errors.
7. Remove legacy fields only after stable adoption.

## 9.1 Cross-feature rollout order (critical)

1. Materials + vehicle catalog tables and seeds.
2. Post Load writes new fields (dual-write old fields).
3. Find Loads reads new fields with fallback to old fields.
4. Fleet add/edit writes new truck fields.
5. Booking match moves to configuration-aware logic.
6. Load detail/cards/TTS/share/admin updated to new labels and notation.
7. Sunset legacy fields.

Do not switch matching to new-only before fleet update UI is live.

---

## 10) Related feature impact map (careful review)

This section defines what else must be touched beyond Post Load.

| Surface | Why impacted | Must change |
|--------|--------------|-------------|
| Find Loads pinned filter | Consumes vehicle requirement model | category/config-aware filter + summary + show-loads apply |
| Find Loads cards | displays material/body/tyre/ton labels | render from catalog + enforce W/T notation |
| Trucker load detail | shows requirements and drives booking | show new requirement model + mismatch reasons |
| Supplier load detail | displays posted requirements | same requirement summary format |
| Repost flow | clones existing load fields | clone new material/vehicle fields too |
| Trucker fleet add/edit | source of truck capability for match | enforce category/config/passing fields |
| Verification truck step | also collects truck data | align with fleet schema and selector |
| Booking match engine | gatekeeper of booking correctness | config-aware matching + passing >= cargo rule |
| Share text | externalized requirement copy | W/T safe labels only |
| TTS builders | spoken representation of requirements | speak wheeler list with W semantics, tons separately |
| Admin load management | ops/support visibility | show friendly labels from catalog codes |

---

## 11) Canonical matching rules (new baseline)

Booking and availability should converge on these rules:

1. category match (`truck.category == load.required_category`, when set)
2. body style match (if load requires styles)
3. configuration overlap (`truck.configuration_code` in load required configurations)
4. passing ton check (`truck.passing_tonnes >= load.cargo_weight_tonnes`)

Compatibility window:

- when legacy loads exist, fallback mapping from old fields is allowed.
- once backfill completes, remove fallback.

---

## 12) Implementation checklist

### Backend

- [ ] Create `material_groups`, `materials` tables.
- [ ] Seed 800+ materials (without "other").
- [ ] Add search indexes and `search_materials` RPC.
- [ ] Create vehicle catalog tables + seeds.
- [ ] Extend `create_load` and feed/detail RPCs.
- [ ] Add compatibility mapping to legacy fields.
- [ ] Update matching RPCs and booking submit flow.
- [ ] Update truck create/update RPCs for fleet and verification.

### Flutter

- [ ] Build `MaterialTypeaheadField`.
- [ ] Integrate in Cargo Details card (replace dropdown).
- [ ] Add `materialCode` in `PostLoadState`.
- [ ] Remove "other" path from provider, validation, submit DTO.
- [ ] Build `VehicleRequirementSummaryTile`.
- [ ] Build `VehicleRequirementDrawer`.
- [ ] Integrate into Vehicle Requirements section.
- [ ] Update review summary strings.
- [ ] Update Find Loads filter UI and summary behavior.
- [ ] Update trucker fleet add/edit and verification truck forms.
- [ ] Update load cards and load detail sections for new labels.
- [ ] Update share and TTS builders with W/T lock.

### QA

- [ ] Search test: `plas`, `coal`, `steel`, typo cases.
- [ ] Verify submit fails when material text typed but no suggestion selected.
- [ ] Verify large list does not lag on low-end Android.
- [ ] Verify vehicle summary updates after drawer changes.
- [ ] Verify no layout regressions across common device widths.
- [ ] Verify Find Loads filter defaults to `Any` and applies correctly.
- [ ] Verify fleet truck can be added/edited and matched to loads correctly.
- [ ] Verify booking rejection reasons are clear when config/capacity mismatch.
- [ ] Verify no `12T` style wheel labels anywhere in UI/TTS/share/admin.

---

## 13) Immediate code hygiene note (current known issue)

Current code has an "Other"/"other" case mismatch path in material handling.  
Until full typeahead migration is complete, normalize all checks to lowercase `'other'` in provider logic to avoid inconsistent behavior.

---

## 14) Success criteria for this restart

- UX stays simple and familiar.
- Material input handles very large list fast.
- No free-text drift in posted data.
- Vehicle selection scales without chip clutter.
- Backend and UI both catalog-driven.
- Zero design regressions in core Post Load flow.
- Find Loads, fleet, details, booking, cards, TTS, share, and admin all stay consistent with new model.
- W/T notation is consistent platform-wide.

---

## 15) Do/Don't UI guardrails (hard constraints)

These are non-negotiable implementation guardrails for design continuity.

### Do

- Keep current compact visual shell on Post Load, Find Loads, and Add Truck.
- Keep Find Loads pinned filter compact and scroll-safe.
- Keep `Any` default selected state clear when no truck filters are active.
- Add capability through:
  - additional chips for selected state
  - concise summary line
  - state-aware drawer/sheet for heavy selection
- Use drawer for long lists (vehicle categories/configs/material-related filters).
- Keep summary text short and scannable (example: `Open • 16W • 36-40 T`).
- Use global notation lock consistently: wheels as `W`, tons as `T`.

### Don't

- Do not replace pinned chip bar with persistent 3x3 or grid-heavy header blocks.
- Do not let pinned filter height grow based on long option sets.
- Do not render full long lists inline in cards.
- Do not show ambiguous tyre labels like `12T` when it means wheels.
- Do not trigger full feed refetch on every micro-toggle when drawer editing is open.
- Do not introduce separate visual paradigms across Post Load, Find Loads, and Add Truck selectors.

### Pinned header safety limits

- Default pinned truck-filter height stays compact.
- Expanded state may add one summary line only.
- Any deeper selection must move into drawer with explicit `Apply`.

---

## 16) File-by-file execution checklist (exact repo targets)

This checklist is intended for direct implementation with minimal ambiguity.

### 16.1 Flutter — Post Load (supplier)

- [ ] `TranZfort/lib/src/features/supplier/presentation/post_load_screen.dart`
  - replace material dropdown with typeahead + suggestion list
  - keep section/card layout unchanged
  - integrate vehicle summary tile + drawer trigger
- [ ] `TranZfort/lib/src/features/supplier/providers/post_load_provider.dart`
  - add `materialCode` state
  - remove free-text "other" path fully
  - wire selected material validation
  - maintain dual-write compatibility fields during migration window
- [ ] `TranZfort/lib/src/shared/widgets/vehicle_requirement_selector.dart`
  - refactor to support state-aware drawer mode
  - keep compact summary rendering path
- [ ] `TranZfort/lib/src/features/supplier/data/supplier_load_models.dart`
  - include `material_code` and new vehicle requirement codes in DTO params
- [ ] `TranZfort/lib/src/features/supplier/data/supplier_load_repository.dart`
  - pass new RPC params, preserve compatibility handling

### 16.2 Flutter — Find Loads filter and feed (trucker)

- [ ] `TranZfort/lib/src/features/trucker/presentation/widgets/marketplace_filter_bar.dart`
  - keep `Any` default and compact chip row
  - add summary chips (`+N more` behavior)
  - wire drawer entrypoints for large option sets
- [ ] `TranZfort/lib/src/features/trucker/presentation/trucker_find_loads_support.dart`
  - preserve pinned layout style and compact height
  - support optional summary line without grid expansion
- [ ] `TranZfort/lib/src/features/trucker/providers/find_loads_provider.dart`
  - support staged/draft filter updates for drawer + explicit apply
  - keep normalization when `Any` is selected
- [ ] `TranZfort/lib/src/features/trucker/data/trucker_marketplace_repository.dart`
  - map new filter fields to feed RPC
  - support legacy fallback window
- [ ] `TranZfort/lib/src/shared/widgets/marketplace_load_card.dart`
  - update fact chips to W/T-safe labels and new summary inputs

### 16.3 Flutter — Fleet add/edit and verification

- [ ] `TranZfort/lib/src/features/trucker/presentation/trucker_fleet_screen.dart`
  - keep form rhythm, add compact summary tile + drawer selection
- [ ] `TranZfort/lib/src/features/trucker/providers/trucker_fleet_provider.dart`
  - support category/body/config/passing state model
  - remove dependence on static small-list assumptions
- [ ] `TranZfort/lib/src/features/trucker/data/trucker_fleet_repository.dart`
  - send/receive new truck classification fields
- [ ] `TranZfort/lib/src/features/verification/presentation/verification_screen_sections.dart`
  - align truck section selector with fleet flow and W/T notation

### 16.4 Flutter — Detail, booking, TTS, share, admin-facing labels

- [ ] `TranZfort/lib/src/features/trucker/data/trucker_load_detail_repository.dart`
  - update matching input mapping and compatibility handling
- [ ] `TranZfort/lib/src/features/trucker/providers/trucker_load_detail_provider.dart`
  - expose mismatch reasons using new model
- [ ] `TranZfort/lib/src/features/trucker/presentation/trucker_load_detail_screen.dart`
  - update requirement display chips/summary
- [ ] `TranZfort/lib/src/features/shell/presentation/supplier_shell_load_detail_sections.dart`
  - align supplier load detail labels with new fields
- [ ] `TranZfort/lib/src/features/tts/data/load_marketplace_card_tts_builder.dart`
  - enforce W/T script and separate wheels vs tons semantics
- [ ] `TranZfort/lib/src/shared/widgets/tts_card_speaker_button.dart`
  - verify no copy regressions in trigger contexts
- [ ] `TranZfort/lib/src/features/trucker/data/trucker_load_share_service.dart`
  - normalize outgoing share strings to W/T notation

### 16.5 Localization and copy

- [ ] `TranZfort/lib/l10n/app_en.arb`
- [ ] `TranZfort/lib/l10n/app_hi.arb`
- [ ] regenerate localizations after new keys

### 16.6 Supabase SQL — existing migration files to update/reference

- [ ] `supabase/migrations/20260531120000_load_marketplace_listing_phase_a.sql`
- [ ] `supabase/migrations/20260531130000_load_marketplace_listing_phase_b.sql`
- [ ] `supabase/migrations/20260531140000_load_marketplace_listing_phase_c_d.sql`
- [ ] `supabase/migrations/20260531150000_get_trucker_load_detail_marketplace_guard.sql`
- [ ] `supabase/migrations/20260530100000_rpc_get_trucker_load_detail.sql`
- [ ] `supabase/migrations/20260517090002_rpc_add_truck.sql`
- [ ] `supabase/migrations/20260517090003_rpc_update_truck.sql`
- [ ] `supabase/migrations/20260529140000_restore_fleet_rpcs_and_fix_verification_submit.sql`
- [ ] `supabase/migrations/20260428000003_update_create_load_accept_per_ton.sql`

Note: do not edit rollback artifacts for re-adding dropped program slices; add new forward migrations for this restart.

### 16.7 Supabase SQL — new forward migrations to create

- [ ] `supabase/migrations/<timestamp>_lp2_material_catalog.sql`
  - `material_groups`, `materials`, seed 800+ materials, indexes
- [ ] `supabase/migrations/<timestamp>_lp2_vehicle_catalog.sql`
  - vehicle category/body/config tables, seed and indexes
- [ ] `supabase/migrations/<timestamp>_lp2_load_columns_and_rpcs.sql`
  - load/truck new columns and RPC extensions (with compatibility window)
- [ ] `supabase/migrations/<timestamp>_lp2_matching_alignment.sql`
  - matching and booking guard alignment to new model

### 16.8 QA and regression files (targeted)

- [ ] `TranZfort/test/features/supplier/providers/post_load_provider_test.dart`
- [ ] `TranZfort/test/features/supplier/presentation/post_load_screen_test.dart`
- [ ] `TranZfort/test/features/trucker/providers/find_loads_provider_test.dart`
- [ ] `TranZfort/test/features/trucker/presentation/trucker_find_loads_screen_test.dart`
- [ ] `TranZfort/test/features/trucker/data/trucker_marketplace_repository_test.dart`
- [ ] `TranZfort/test/features/trucker/data/trucker_load_detail_repository_test.dart`

Implementation order should follow section 9.1 rollout sequence.

