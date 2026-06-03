# TODO-2-JUNE — LOADPOST-2 Execution Checklist

**Date:** 2 June 2026  
**Program:** LOADPOST-2 (fresh restart)  
**Status:** Active planning + controlled execution

---

## 1) Rollback safety (read first)

If LOADPOST-2 implementation becomes unstable and we decide to scrap the entire program work, rollback to:

- **Rollback checkpoint commit:** `d6ccdd6`
- **Reason:** Captures agreed LOADPOST-2 planning docs + guardrails + immediate stabilization fix, before implementation slices.

Recommended rollback command (only when explicitly approved):

```bash
git reset --hard d6ccdd6
```

Use this only as a full scrap fallback. Prefer slice-level revert first.

---

## 2) Global working rules (must follow every day)

- [ ] Do not start coding before reading `docs/LOADPOST-2-JUNE.md`.
- [ ] Keep current layout shell intact (no major structural redesign in phase-1).
- [ ] Enforce notation lock globally: **W = wheels**, **T = tons**.
- [ ] No free-text material posting; only master-table selection.
- [ ] Do not bypass drawer pattern when option sets are large.
- [ ] Use forward migrations only (never re-apply removed rollbacked LP files).
- [ ] Always update this checklist immediately after a slice is completed.
- [ ] Always run small targeted tests first to save time.
- [ ] If failures are from legacy/old `*test.dart` setup, log them in section 9 and fix in a later cleanup slice.

---

## 3) Before starting any new slice (hard gate)

- [ ] `git status` clean or intentionally scoped.
- [ ] Confirm previous slice smoke test is green.
- [ ] Confirm pending lints for touched files are resolved.
- [ ] Confirm rollout order dependencies are satisfied.
- [ ] Confirm rollback path is known for this slice.
- [ ] Write slice objective + done criteria in this file before implementation.

---

## 4) Mandatory smoke test checklist (run on every slice)

### Post Load smoke

- [ ] Open Post Load screen without crash.
- [ ] Route fields still work as before.
- [ ] Cargo Details renders correctly (no overflow/clip).
- [ ] Vehicle Requirements renders compact summary and opens drawer.
- [ ] Submit validation messages are correct.

### Find Loads smoke

- [ ] Header shows **From** + **To** only; scrolls away with intro (not pinned).
- [ ] **Advanced search** opens dark drawer (material, sort, price, extended vehicle + body/config).
- [ ] Advanced button shows badge when non-route filters are active.
- [ ] Pinned filter shows **Any** selected by default (legacy body-type row).
- [ ] Pinned row 1: **Any, Open, Container, Trailer, Tanker, Reefer** — immediate apply on tap.
- [ ] Pinned row 2: tyre chips **6, 10, 12, 14, 16, 18, 22** when a body type is selected.
- [ ] Pinned maps legacy chips → catalog `vehicleCategoryCode` + legacy RPC fields.
- [ ] Extended categories (LCV, Bulker, Tipper, Parcel, ODC) only in Advanced search drawer.
- [ ] Pinned height dynamic (one row ~52px; two rows ~92px).
- [ ] Drawer uses dark ink theme (matches Load Detail widgets/chips).

### Fleet + booking smoke

- [ ] Add/Edit truck flow opens selector drawer.
- [ ] Truck save succeeds with required fields.
- [ ] Load detail renders new requirement summary correctly.
- [ ] Booking allows matching truck and blocks mismatched truck with clear reason.

---

## 5) UI-UX guardrails (implementation constraints)

- [ ] Keep compact card rhythm and spacing.
- [ ] Keep existing pinned filter structure; do not replace with large grid blocks.
- [ ] Pinned Find Loads filter uses **legacy body-type chips** (Any + Open/Container/Trailer/Tanker/Reefer); extended catalog types live in Advanced search drawer.
- [ ] Inline chips only for selected/high-value states.
- [ ] Long option sets must use drawer/sheet.
- [ ] Show summary chips (`+N more`) instead of long chip overflow.
- [ ] Keep dark-surface filter visuals consistent in Find Loads.
- [ ] Vehicle catalog drawers/sheets use the same **ink dark** palette as Load Detail (`inkHeroCard`, `inkFilterChip`, `primaryOnDark`).
- [ ] Keep `Show loads` explicit apply flow (or document if auto-apply is chosen for category-only taps).

### Do not merge if any of these happen

- [ ] Pinned filter becomes multi-row heavy by default.
- [ ] New UI introduces mixed notation like `12T` for wheels.
- [ ] Selection requires scrolling huge inline chip collections.
- [ ] Existing marketplace card hierarchy gets visually broken.

---

## 6) Code quality rules (mandatory)

- [ ] No hardcoded long lists in UI widgets.
- [ ] All material and vehicle options are catalog-driven.
- [ ] Use typed models for catalog items (`code`, `label`, `active`).
- [ ] Keep compatibility mapping centralized.
- [ ] Avoid duplicated mapping logic across screens.
- [ ] Add/adjust tests for each affected provider/repository.
- [ ] Keep l10n keys aligned in EN and HI.
- [ ] Run lint checks for all touched files.

---

## 7) Slice plan and execution tracker

## Slice A — Material catalog + typeahead

**Goal:** Replace material dropdown with table-backed typeahead and remove "other".  
**Pre-req:** materials table + search RPC ready.

- [x] Backend: materials schema + index + search RPC.
- [x] Flutter: typeahead field in Cargo Details.
- [x] Provider: `materialCode` + strict validation.
- [x] Smoke tests complete.
- [x] Lints/tests pass.

## Slice B — Vehicle selector compact summary + drawer

**Goal:** Preserve vehicle section layout, move heavy selection into drawer.

- [x] Build summary tile + edit drawer flow.
- [x] Keep compact in-card state.
- [x] W/T notation validated in labels.
- [x] Smoke tests complete.
- [x] Lints/tests pass.

## Slice C — Find Loads filter parity (compact pinned + drawer)

**Goal:** Same visual pattern as today, richer data via drawer.

- [x] Keep Any default.
- [x] Add summary chips and drawer edit.
- [x] Ensure explicit apply flow.
- [ ] **Follow-up (Slice K):** Replace interim summary + Edit bar with catalog category chip row.
- [ ] Smoke tests complete (manual §4 still open).
- [x] Lints/tests pass.

## Slice D — Fleet add/edit + verification alignment

**Goal:** Truck data model aligns with load matching model.

- [x] Fleet forms moved to compact summary + drawer editor for truck body/tyre selection.
- [x] Verification truck section aligned to same compact summary + drawer interaction.
- [x] Save/edit operations remain stable with existing truck schema fields.
- [x] Smoke tests complete (targeted checks).
- [x] Lints/tests pass (with known legacy GoRouter harness issue in fleet widget test).

## Slice E — Detail/cards/TTS/share/admin alignment

**Goal:** Unified rendering and semantics across all read surfaces.

- [x] Load cards/chips standardized to W notation for tyre labels.
- [x] Supplier + trucker load detail tyre rendering aligned to W notation.
- [x] Share payload text updated to W/T compact notation.
- [x] Admin-facing label parity resolved through shared rendering formatters (no separate app admin module in this repo path).
- [x] Smoke tests complete (targeted checks).
- [x] Lints/tests pass.

## Slice F — Vehicle catalog schema + seed (capacity master)

**Goal:** Move from legacy body/tyre model to catalog tables using `docs/tranzfort_capacity_master_uiux.txt`.

- [x] Create vehicle catalog tables (`vehicle_categories`, `vehicle_body_styles`, `vehicle_category_body_styles`, `vehicle_configurations`).
- [x] Seed LCV/Open/Trailer/Container/Bulker/Tanker/Tipper/Reefer/Parcel/ODC mappings.
- [x] Add new load/truck columns for category/body-style/configuration linkage.
- [x] Add `get_vehicle_catalog()` RPC and required indexes.
- [x] Smoke tests complete.
- [x] Lints/tests pass.

## Slice G — Shared state-aware vehicle drawer engine

**Goal:** One reusable drawer contract for Post Load, Find Loads, Fleet, and Verification.

- [x] Implement shared selection state object (category + body style + configuration + derived wheels/feet/tons).
- [x] Add category-aware control logic (Open vs Container vs LCV, etc.).
- [x] Add compact summary formatter with locked notation (`W`, `T`, `FT`).
- [x] Smoke tests complete.
- [x] Lints/tests pass.

## Slice H — Post Load + Find Loads catalog integration

**Goal:** Replace legacy body/tyre-only vehicle filters with full catalog selection.

- [x] Wire Post Load provider/screen + DTO/RPC params to new vehicle requirement fields.
- [x] Wire Find Loads filter model/drawer + feed RPC params to category/body/config (compatibility mapping remains for fallback rendering fields).
- [x] Keep compact pinned UX with explicit apply flow.
- [x] Smoke tests complete.
- [x] Lints/tests pass.

## Slice I — Fleet + Verification catalog integration

**Goal:** Truck add/edit and verification truck step use same full selector model.

- [x] Extend truck provider/model/backend with category/body-style/configuration fields.
- [x] Upgrade Fleet and Verification drawer flows to category-aware logic.
- [x] Ensure save/edit and verification readiness rules are stable.
- [x] Smoke tests complete.
- [x] Lints/tests pass.

## Slice J — Matching + read-surface normalization + compatibility

**Goal:** End-to-end matching and all read surfaces honor the new vehicle matrix while preserving legacy records.

- [x] Update truck/load matching RPC + app-side guard to category/body/config/ton logic.
- [x] Normalize cards/details/TTS/share formatting from catalog data.
- [x] Keep backward compatibility fallback for legacy loads/trucks.
- [x] Smoke tests complete (targeted unit tests; manual §4 still open).
- [x] Lints/tests pass.

## Slice K — Find Loads split UX (legacy pinned + Advanced search drawer)

**Goal:** Restore familiar **pinned legacy vehicle filter** with immediate apply; move route-adjacent and deep filters to a redesigned header + Advanced search drawer.

**Decisions locked (2 Jun):**
- Pinned apply: **immediate on chip tap** (old UX).
- Header: **From + To** scroll away (not pinned); no inline material/sort expand.
- Advanced badge: active-count on button when material/sort/price/extended-vehicle filters set.
- Tyre row: fleet options **6, 10, 12, 14, 16, 18, 22**.

**Target UX:**

*Header (scrolls away):*
- From | To city fields with typeahead.
- **Advanced search** → dark drawer.

*Pinned (always visible):*
- Row 1: Any + Open + Container + Trailer + Tanker + Reefer (`MarketplaceFilterBar`, ink dark).
- Row 2: tyre chips when body type selected.
- Immediate `updateFilters` on chip tap; maps legacy → `vehicleCategoryCode` + RPC compat.

*Advanced search drawer:*
- Material, sort, min/max price.
- Extended catalog categories only: LCV, Bulker, Tipper, Parcel, ODC.
- Body style + configuration (`VehicleCatalogSelectorSheet`, dark, single Apply at bottom).

**Tasks:**
- [x] Wire `MarketplaceFilterBar` into pinned `SliverPersistentHeader` with dynamic height.
- [x] Add legacy ↔ catalog mapping helpers; immediate apply handlers.
- [x] Slim header: remove `AnimatedCrossFade` advanced expand.
- [x] Build `_AdvancedSearchSheet` (dark) replacing split advanced/truck sheets.
- [x] Advanced search badge count (exclude From/To).
- [x] Remove broken `_PinnedTruckFilterBar` + inline Apply on pinned row.
- [ ] Widget/provider tests for pinned Any/body/tyre apply.
- [ ] Manual smoke §4 Find Loads.

## Slice L — Dark theme vehicle drawers + sheet unification

**Goal:** All vehicle-catalog drawers and related bottom sheets use the **ink dark** visual system (Load Detail / Find Loads marketplace band), not light `cardSurface` + default Material chips.

**Reference styling (source of truth):**
- `AppDecorations.inkHeroCard()` / `inkHeroGradient`
- `AppDecorations.inkFilterChip(selected: …)`
- `AppColors.inkSurface`, `inkDeep`, `inkTextPrimary`, `primaryOnDark`
- `AppTextField` / `AppDropdown` with `onDarkSurface: true`
- Existing dark chips: `layout_components.dart` `InkSegmentTabBar`, `marketplace_filter_bar.dart` `_BodyTypeChip`

**Drawer / sheet inventory (vehicle + shared shells):**

| Surface | File | Host | Theme today | Action |
|--------|------|------|-------------|--------|
| Vehicle catalog selector | `shared/widgets/vehicle_catalog_selector.dart` | Post Load, Find Loads, Fleet, Verification | **Light** | Add dark variant; ink chips for body + config |
| App bottom sheet shell | `shared/widgets/layout_components.dart` → `AppBottomSheet` | Find Loads, Verification truck | **Light** (`AppColors.cardSurface`) | Add dark variant using `inkHeroCard` |
| Post Load vehicle editor | `supplier/presentation/post_load_screen.dart` | `showModalBottomSheet` | **Light** | Dark sheet wrapper |
| Find Loads truck filter | `trucker_find_loads_support.dart` | `showAppBottomSheet` | **Light** shell + selector | Dark shell + selector |
| Fleet vehicle editor | `trucker/presentation/trucker_fleet_screen.dart` | `showModalBottomSheet` | **Light** | Dark sheet + selector |
| Verification truck step | `verification/presentation/verification_screen_sections.dart` | `showAppBottomSheet` | **Light** | Dark shell + selector |
| Legacy filter bar (unused) | `trucker/presentation/widgets/marketplace_filter_bar.dart` | Not mounted | **Dark-ready** | Reuse chip pattern for Slice K |

**Out of scope for Slice L:** image-source pickers, repost sheet, review prompt, chat actions — separate pass if dark parity needed.

**Tasks:**
- [x] Add `VehicleCatalogSelectorSheet` parameter `onDarkSurface` (default `true` for vehicle flows).
- [x] Dark mode: ink-styled chips instead of raw `FilterChip` (match `_BodyTypeChip`).
- [x] Dark mode: `AppDropdown` + labels use `onDarkSurface: true`.
- [x] Extend `showAppBottomSheet` / `AppBottomSheet` with dark variant.
- [x] Migrate Post Load, Find Loads, Fleet, Verification vehicle entry points to dark sheet + selector.
- [x] Post Load form card stays light; only drawer is dark.
- [ ] Verify keyboard inset + scroll on small screens.
- [ ] Manual smoke: open drawer from all four flows.

## Slice M — LOADPOST-2 gap closure (backend + validation)

**Goal:** Close remaining “same family as load post” issues from review.

- [x] `create_load` COALESCE for NOT NULL vehicle array columns (`20260602210000`).
- [x] Post Load requires vehicle category + configuration.
- [x] Post Load syncs legacy body/tyre from catalog selection.
- [x] `clone_load_for_repost` + supplier RPC catalog fields (`20260602220000`).
- [x] Find Loads marketplace RPC catalog-first filtering.
- [ ] Supplier load detail **UI** shows catalog requirement summary (RPC ready; UI still legacy body type in `supplier_shell_load_detail_sections.dart`).
- [ ] Fleet save validation: require category + body + config (match verification readiness).
- [ ] Fix stale tests: GoRouter widget harnesses (`post_load_screen_test.dart`, `trucker_fleet_screen_test.dart`).
- [ ] Manual smoke §4 full pass.

---

## 8) Pre-merge checklist for every LOADPOST-2 PR/commit

- [ ] Scope is single slice or clearly bounded.
- [ ] No unrelated files changed.
- [ ] Rollback instructions updated if needed.
- [ ] Smoke tests documented in commit notes.
- [ ] No pending critical TODOs left in code.

---

## 9) Notes log

Use this section to append quick run notes per day/slice:

- 2026-06-02: Initialized LOADPOST-2 execution checklist and rollback baseline.
- 2026-06-02: Slice A complete (material table/search + typeahead + create_load material_code).
- 2026-06-02: Slice B complete (Post Load vehicle summary tile + drawer editor).
- 2026-06-02: Slice C complete (Find Loads pinned compact summary + drawer editor + explicit apply).
- 2026-06-02: Legacy screen-test instability noted: `post_load_screen_test.dart` uses mixed `MaterialApp`/`GoRouter` contexts and throws `GoRouterState.of`/framework assertion chain in some test paths. Keep for dedicated test cleanup slice.
- 2026-06-02: Slice D complete for current fleet schema (compact truck requirement summary + drawer editor in Fleet and Verification truck step).
- 2026-06-02: Slice E in progress: W/T notation alignment completed for chips, load details, and share payload; admin catalog label wiring remains pending.
- 2026-06-02: Slice E completed: compact list tiles also moved to `/T`; admin label scope treated as shared formatter parity because no dedicated runtime admin module exists under `TranZfort/lib/src/features`.
- 2026-06-02: Legacy screen-test instability confirmed again in `trucker_fleet_screen_test.dart` (`GoRouterState.of` missing in widget harness paths), tracked for dedicated cleanup slice.
- 2026-06-02: Vehicle matrix gap confirmed against `docs/tranzfort_capacity_master_uiux.txt` (missing category/body-style variants, feet-based container configs, and state-aware rules). Added slices F→J for full catalog rollout.
- 2026-06-02: Slice F started — added migration `20260602161500_lp2_vehicle_catalog_schema_seed.sql` (vehicle catalog tables, core matrix seed, load/truck linkage columns, and `get_vehicle_catalog()` RPC). App data layer foundation started with vehicle catalog repository models and fetch method.
- 2026-06-02: Slice G core engine started — added shared `vehicle_catalog_selector.dart` and integrated Post Load vehicle selection state (category/body/config) with compatibility mapping.
- 2026-06-02: Small tests passed: `post_load_provider_test.dart`, `supplier_load_repository_test.dart`.
- 2026-06-02: Legacy widget test instability persists in `post_load_screen_test.dart` with `GoRouterState.of` context/harness failures; recorded for later dedicated test cleanup.
- 2026-06-02: Slice H progressed — Find Loads now carries category/body/config filter state with shared selector sheet and compact summary; currently maps selected config back to legacy body/tyre RPC fields until marketplace RPC expansion is completed.
- 2026-06-02: Small tests passed: `find_loads_provider_test.dart`.
- 2026-06-02: Added migration `20260602170000_lp2_marketplace_feed_vehicle_filters.sql` to extend `get_marketplace_feed` with vehicle category/body/config filter params and updated app RPC calls to pass new params.
- 2026-06-02: Slice I completed — Fleet repository/provider now carries vehicle category/body-style/config/passing-ton fields, and Fleet + Verification truck drawers now use the shared state-aware catalog selector.
- 2026-06-02: Slice J completed — app-side matching updated to include category/body-style/config with legacy body/tyre fallback, and migration `20260602193000_lp2_slice_i_j_fleet_matching_catalog.sql` added for fleet RPC payload/params and server-side matching parity.
- 2026-06-02: Small tests passed: `trucker_fleet_repository_test.dart`, `trucker_load_detail_repository_test.dart`.
- 2026-06-02: Remote DB push completed with `--include-all`; applied migrations `20260602161500`, `20260602170000`, `20260602193000`, and `20260602195500`.
- 2026-06-02: Added restore migration after rollback to re-enable material catalog/search RPC + latest `create_load` signature (`p_material_code` + vehicle catalog params).
- 2026-06-02: Small tests passed: `post_load_provider_test.dart`, `supplier_load_repository_test.dart`.
- 2026-06-02: Material catalog expanded from the comprehensive master list via migration `20260602200500_lp2_full_material_catalog_seed.sql` (839 source rows, dedup + code generation, pushed to remote).
- 2026-06-02: Load post NULL array fix — migration `20260602210000_lp2_create_load_coalesce_vehicle_arrays.sql` + app sends `[]` not `null`.
- 2026-06-02: Repost + supplier read RPC catalog fields — migration `20260602220000_lp2_repost_supplier_detail_catalog_fields.sql`.
- 2026-06-02: Find Loads pinned bar interim fix (height clipping, catalog summary); Edit visible but UX not final — **Slice K** added for category chip row (Any + LCV/Open/Trailer/…).
- 2026-06-02: Drawer audit — `VehicleCatalogSelectorSheet` + `AppBottomSheet` are light-themed; Load Detail uses ink dark chips. **Slice L** added for dark drawer unification across Post Load, Find Loads, Fleet, Verification.
- 2026-06-02: `MarketplaceFilterBar` has reusable dark chips but legacy body types only and is not mounted on Find Loads screen — reuse pattern in Slice K with catalog categories.
- 2026-06-02: **Slice K fix** — Refrigerated chip l10n; pinned uses legacy `p_body_type` only (tyres work again); tighter pinned bar height; migration `20260603180000` for case-insensitive + legacy/catalog body match.
- 2026-06-02: **Slice L** implemented — `showVehicleCatalogBottomSheet`, `onDarkSurface` on selector + `AppBottomSheet`; migrated Post Load, Find Loads, Fleet, Verification vehicle drawers.
- 2026-06-02: Fixed `find_loads_provider_test.dart` for new `MarketplaceLoadItem` catalog fields; targeted analyze clean on touched files.
