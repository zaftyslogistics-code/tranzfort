# Final polish — trucker marketplace & release tail

**Created:** 2026-05-30  
**Updated:** 2026-05-30 (FP-13 dashboard route-search hero; FP-10 pull-to-refresh; FP-11 notification badge; FP-12 dark ink heroes; FP-9 truck wizard TTS)  
**Status:** **FP-0 + FP-1 + FP-2 + FP-3 complete**; **FP-5 in progress** (chat QA pending); **FP-6 kept**; **FP-7 code complete** (device QA pending); **FP-8 code complete**; **FP-9 code complete** (device Hindi TTS QA pending); **FP-10 + FP-11 + FP-12 + FP-13 code complete** (device QA pending); **FP-4 deferred** (body/tyre filter bar on dashboard — superseded for route by FP-13); **Voice (Speaker) system deferred**  
**Git branch:** `final-polish` — pushed to `origin`  
**Source checklist:** [TODO-29-may.md](./TODO-29-may.md)  
**Related:** [TTS-29-may.md](./TTS-29-may.md) · [DATA-ACCESS-ALIGNMENT.md](./DATA-ACCESS-ALIGNMENT.md) · [TTS-ARB-GUIDE.md](./TTS-ARB-GUIDE.md) · **[hindi-improvement.md](./hindi-improvement.md)** (FP-9 spec)

---

## Purpose

This document is the **single plan** for the “final polish” sprint:

1. **Carry over** every still-open item from `TODO-29-may.md` (ship gate, QA, TTS, l10n, docs).
2. **Redesign** four trucker-facing surfaces for a more compact, scannable UI — **no new business fields or chips**.
3. **Branch discipline:** all implementation on **`final-polish`**; merge to `main` only after device QA on that branch.

### Sprint goals (measurable)

| Goal | How we know it’s done |
|------|------------------------|
| Faster marketplace scan | Card header ≤ ~120px; no per-card diesel/profit calc on list |
| Filters without friction | Truck type + tyres visible on Find Loads + dashboard without bottom sheet |
| Cleaner load detail | No in-app map; external maps one tap away; profit only on detail |
| Release-ready branch | Device QA + automated tests green; Play internal upload |

---

## Branch workflow

| Step | Action | Owner |
|------|--------|-------|
| 1 | `git checkout main && git pull origin main` | Dev |
| 2 | `git checkout -b final-polish` (done) | Dev |
| 3 | Implement epics in order: FP-1 → FP-3 → FP-4 → FP-2 | Dev |
| 4 | `build-apk.bat` + device smoke (Find Loads, detail, dashboard) | Dev + QA |
| 5 | PR / merge to `main` | Dev |

Do **not** mix unrelated Play Console or Supabase migration work on this branch unless required for the redesign.

---

## Design system alignment (read before UI changes)

**Rule:** Extend centralized tokens and shared widgets — do **not** paste one-off gradient `BoxDecoration`s into feature screens.

### Layer map (TranZfort user app)

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Tokens** | `lib/src/core/theme/app_colors.dart` | Colors, `heroCta` (teal→orange), `heroCardWash`, chip bg tokens |
| **Tokens** | `app_spacing.dart` | 4px scale; `screenHorizontal` = 16px; `AppRadius.card` = 16 |
| **Tokens** | `app_typography.dart`, `app_shadows.dart` | Type + elevation |
| **Theme** | `app_theme.dart` | Material defaults (inputs use **solid** primary focus border — not gradient) |
| **Cards** | `shared/widgets/content_cards.dart` | `HeroActionCard`, `StandardListCard`, `DetailSectionCard`, `StatCard` |
| **Status** | `shared/widgets/status_components.dart` | `StatusChip` — **semantic** colors (active=green, pending=amber, etc.) |
| **Actions** | `shared/widgets/action_buttons.dart` | **`PrimaryButton`** = filled `heroCta` + white label (`AppTypography.button`); **`GradientButton`** delegates to `PrimaryButton` |
| **Marketplace** | `shared/widgets/marketplace/*`, `app_decorations.dart` | `BrandAccentChip`, `MarketplacePriceFactRow`, `StatusChip` on card |

Source comments point to `docs/38-ui-ux-color-typography-and-elevation-system.md` and `docs/39-ui-ux-layout-spacing-and-component-composition.md` (design intent lives there even if files are gitignored).

### What already uses brand gradient correctly

| Widget | Pattern |
|--------|---------|
| `PrimaryButton` / `GradientButton` | Filled `AppColors.heroCta` + `AppShadows.heroCta` + **`AppTypography.button`** (white) |
| Dark `HeroActionCard` | `heroDark` + `heroDarkGlow` radial wash (not border) |
| Light `HeroActionCard` | Subtle `heroCardWash` fill + `divider` border |
| Onboarding role cards | `BrandGradientBorder` + light card fill (FP-7) |

### What was teal-only (fixed on `final-polish`)

| Widget | Was | Now |
|--------|-----|-----|
| `LoadInfoChip` / fact chips | `primary @ 20%` | **`BrandAccentChip`** (mini) via `AppDecorations` |
| `_CompactStatusChip` | Custom teal duplicate | **Removed** — status **dropped from list card** (TTS still reads status) |
| Card shell border | `divider` only | **`brandGradientBorderOuter`** (1.2px teal→orange stroke) |
| Footer Call/Details/Chat | Gradient pills (trial) | **Reverted** — plain icon + text + vertical dividers |

### Critical: two chip systems (locked decision)

```
StatusChip (status_components.dart)     LoadInfoChip (marketplace_chips.dart)
├─ Used 30+ screens                     ├─ Marketplace load card only
├─ Semantic: active → GREEN             ├─ Brand-ish: teal tint
├─ pending → amber, error → red         └─ Material / weight / body type
└─ Trips, verification, admin, detail
```

**Decision for FP-1 (locked):**

- **Material / truck type / tyres** → **`BrandAccentChip`** (teal→orange gradient fill, `mini: true` on price row).
- **Load status (“Active”, etc.)** → **not shown on list card** (removed after device review); TTS speaker top-right in header row.

### Safe extension: `AppDecorations` (FP-0 — done)

Add **`lib/src/core/theme/app_decorations.dart`** — **implemented** with:

| Helper | Use |
|--------|-----|
| `brandGradient()` | Returns `AppColors.heroCta` (single source) |
| `brandGradientChipDecoration({required bool onDark, BorderRadius? radius})` | Teal→orange **fill** for marketplace fact chips |
| `brandGradientBorderDecoration({required Widget child surface, double width, BorderRadius radius})` | Gradient **stroke** wrapper pattern (outer gradient container + inner inset) |
| `brandGradientBorderWidth` | Token = `1.2` (matches existing `StandardListCard` border weight) |

Then **consume** from shared widgets — never duplicate gradient math in feature files.

### Phased rollout (do not “change entire app” in one commit)

| Phase | Scope | Files | Breaking risk |
|-------|--------|-------|---------------|
| **FP-0** | Theme helpers | `app_decorations.dart` | **Done** |
| **FP-1a–c** | Marketplace card + feed | chips, header, price row, full-bleed | **Done** |
| **FP-2+** | Optional `useBrandBorder` on `DetailSectionCard`, `StandardListCard` | `content_cards.dart` | Medium — default **false** |
| **Later** | Supplier lists, trips, chat | Screen-by-screen QA | High if rushed |

### Widgets that must **NOT** get brand gradient border/fill

- `WarningBlock`, error banners (semantic warning/error colors)
- `StatusChip` semantic backgrounds (unless explicit new `BrandAccentChip` variant)
- Chat message bubbles (`primaryChipBg` / `subtleSurface`)
- Form inputs (`InputDecorationTheme` — solid focus ring)
- Admin app (separate codebase)

### Layout: full-bleed vs global padding

```
CORRECT                              WRONG
─────────────────────────           ─────────────────────────
Find Loads list sliver: 0px pad     Changing AppSpacing.screenHorizontal
Hero + filters: keep 16px pad       Removing padding from DetailSectionCard
Card: edge-to-edge in list          Making all cards 0 radius globally
```

Card gap: use `AppSpacing.cardGap` (12) between full-bleed cards — not side inset + large vertical gap.

---

## Shipped on `final-polish` (changelog)

*Summary of code changes merged on branch so far — for device QA and PR description.*

### Branch & hygiene

| Item | Detail |
|------|--------|
| Branch | `final-polish` created from latest `main` |
| l10n fix | `flutter gen-l10n` — removed duplicate `commonFromLabel` / `commonToLabel` in generated Dart |
| Legacy delete | `load_card_dark_header.dart` removed (unused duplicate) |

### FP-0 — `AppDecorations`

| File | Change |
|------|--------|
| `lib/src/core/theme/app_decorations.dart` | **New:** `brandGradientChipDecoration`, `brandGradientBorderOuter`, `marketplaceCardSurface`, `BrandAccentChip` (`compact` / `mini`), `BrandGradientBorder` |

### FP-1 — Marketplace load card

| File | Change |
|------|--------|
| `marketplace_load_card.dart` | Full-bleed gradient border shell; meta row only below price; simple footer (no gradient) |
| `marketplace/marketplace_dark_header.dart` | Supplier (15.6px) + avatar (15.6 radius) + route; **TTS speaker** top-right; no status chip |
| `marketplace/marketplace_price_fact_row.dart` | **New:** price (21px) + mini **`BrandAccentChip`** row (material, body type, tyres) |
| `marketplace/marketplace_route_line.dart` | City names **19px**; state **10px** |
| `marketplace/marketplace_chips.dart` | Primary → **`BrandAccentChip`**; secondary text-only |
| `trucker_find_loads_screen.dart` | Load list **0px horizontal** padding; `cardGap` between cards |

**Card layout (current — as built)**

```
┌───────────────────────────────────────────────  full width
│ [av] Supplier · 2h                    [🔊]   │  avatar + name +20%; TTS top-right
│ FROM  Mumbai  →  TO  Delhi                   │  cities 19px
│ ₹12,500/T  [Cement][Open][14T]               │  price + mini gradient chips, one row
│ Today · 20% adv                              │  plain meta
│  📞 Call  │  ℹ Details  │  💬 Chat           │  plain footer (no gradient bg)
└───────────────────────────────────────────────
```

**Explicitly not shipped / reverted**

- Load value + est. profit on list card (removed v1)
- Per-card `TripCostingService` / diesel on feed (removed v1)
- Gradient background on footer actions (tried → **reverted** per product)
- Weight/capacity chip on price row (material + body + **tyres** only)

### FP-3 — Find Loads filters (**done** + dark ink pass)

| File | Change |
|------|--------|
| `presentation/widgets/marketplace_filter_bar.dart` | **Any** chip (default); body types; **tyres when a specific type selected** (hidden for Any); counts from `truckerFleetTyreOptions` (6–22) |
| `trucker_find_loads_support.dart` | Dark ink tabs + pinned bar (full-bleed gradient border); `_pinnedTruckFilterHeight` 53px / 94px (+20%) |
| `trucker_find_loads_screen.dart` | Dark ink hero (`useInkGradient`); dark search fields + **sort dropdown**; minimal gap to load cards |
| `find_loads_provider.dart` | Clear tyres when body type = Any (empty) |
| `app_decorations.dart` | `inkHeroCard`, `inkFilterChip`, `inkAccentInset` helpers |
| `form_inputs.dart` | `AppSearchField` / `AppDropdown` **`onDarkSurface`** |
| `content_cards.dart` | `HeroActionCard.useInkGradient`; `DetailSectionCard.useInkGradient` |

**Find Loads layout (at top — as built)**

```
┌─────────────────────────────────────────────┐
│ FIND LOADS hero (dark ink, origin/dest…)     │  ← scrolls away
│ [ All loads ] [ Super loads ]  (dark tabs)   │  ← scrolls away
├─────────────────────────────────────────────┤
│ PINNED: [Any][Open][Container]…            │  ← full-bleed; tyres row if type ≠ Any
├─────────────────────────────────────────────┤
│ LOAD CARD (edge-to-edge)                     │
└─────────────────────────────────────────────┘
```

**Advanced filters sheet:** min/max price only (body + tyres live in pinned bar).

**Still open (non-blocking):** FP-3.8 filter TTS copy, FP-3.9 a11y hints, remaining widget test overflow cases

### FP-2 — Load detail (**done** — dark ink + maps + costing)

| File | Change |
|------|--------|
| `trucker_load_detail_primary_sections.dart` | Compact route hero v2 (ink gradient, fare panel, fact grid, arc, Google Maps CTA) |
| `trucker_load_detail_shared.dart` | `_EarningsEstimateCard`; `_InkDetailFactChip` / `_InkDetailMetricTile`; dark status pills |
| `trucker_load_detail_sections.dart` | Ink sections: truck requirements, supplier, trip-cost unavailable |
| `load_detail_tts_builder.dart` | Hero TTS = overview + chat hint only (no duplicate truck block) |
| `drive_time_estimate.dart` | Drive time in **days** @ 300 km/day |
| `trip_costing_service` + `app_config.dart` | Default diesel **₹100/L**; fixed vs per-ton fare in estimate |
| `diesel_price_repository.dart` | `estimateDieselPricePerLitre` floors legacy DB values below ₹100/L |
| `google_maps_open_button.dart` | Teal inset maps button matching fare panel |
| `profile_avatar_merge.dart` | Supplier avatar on detail + public profile |
| `polish_ui_responsive_smoke_test.dart` | 320dp filter bar responsive smoke |

**Signed off:** device QA (maps, booking, TTS, earnings @ ₹100/L, responsive filter bar).

### Deferred

- **FP-4** — dashboard `MarketplaceFilterBar` (post–final-polish merge)

### FP-5 — Chat UX polish (**in progress**)

Source: `docs/TODO&Progress/phase-07-communication-chat-bot.md` § Chat-Improvement (CI-1–CI-14).

| # | Task | Status |
|---|------|--------|
| FP-5.1 / CI-1 | WhatsApp edge alignment (receiver left, sender right) | [x] |
| FP-5.2 / CI-2 | Screen-based bubble max width (76%, 420px cap) | [x] |
| FP-5.3 / CI-3 | Asymmetric bubble corners | [x] |
| FP-5.4 / CI-4 | Consecutive message grouping + tighter spacing | [x] |
| FP-5.5 / CI-5 | Reliable scroll-to-latest (double post-frame) | [x] |
| FP-5.6 / CI-6 | List bottom anchor padding | [x] |
| FP-5.7 / CI-7 | Persistent new-message pill + arrow | [x] |
| FP-5.8 / CI-8 | Scroll-to-bottom FAB when reading history | [x] |
| FP-5.9 / CI-9 | Long-press mic to record (tap fallback kept) | [x] |
| FP-5.10 / CI-10 | Composer capsule + top shadow | [x] |
| FP-5.11 / CI-11 | Long-press text → copy sheet | [x] |
| FP-5.12 / CI-12 | Compact text bubble padding | [x] |
| FP-5.13 / CI-13 | Load-older compact pill | [x] |
| FP-5.14 / CI-14 | Empty state quick-reply chips + error retry | [x] |
| FP-5.15 | Device QA + chat widget tests | [ ] |

**Files:** `chat_screen.dart`, `chat_message_sections.dart`, `chat_screen_sections.dart`, `chat_screen_action_extensions.dart`, `app_en.arb`, `app_hi.arb`

### FP-7 — Auth onboarding plain language + UI (**code complete**)

| File | Change |
|------|--------|
| `onboarding_screens.dart` | Find Loads card first; `BrandGradientBorder` on role cards; `GradientButton` Continue |
| `app_en.arb`, `app_hi.arb` | Plain-language headings, card titles, errors, discard dialog (no trucker/supplier jargon) |
| `tts/tts_en.arb`, `tts/tts_hi.arb` | `ttsOnboardingChooseRole` — load dhoondhna / post karna (not “trucker/supplier”) |
| `tool/gen_tts_l10n.ps1` | **Required** after TTS ARB edits — regenerates `tts_localizations_*.dart` (separate from app `gen-l10n`) |

**Copy (shipped)**

| Surface | EN | HI |
|---------|----|----|
| Question | Do you want to find loads or post a load? | भाड़ा खोजना है या पोस्ट करना है? |
| Find Loads card | Find Loads — Bhada khoje | भाड़ा खोजें |
| Post a Load card | Post a Load — Bhada post kare | भाड़ा पोस्ट करें |
| TTS (HI) | Apna role chunein. Load dhoondhna hai ya load post karna hai? … | (Roman Hindi in `tts_hi.arb`) |

**UI polish**

- Role cards: `BrandGradientBorder`; per-card `TtsCardSpeakerButton` (Find Loads / Post Load)
- **Continue:** brand gradient fill + **white** label (matches Book This Load)
- Profile step: `OnboardingFieldSection` (gradient border + field speakers); enlarged inputs; single scroll (keyboard no longer hides name field)

**Open:** FP-7.4 device QA (EN + HI + TTS auto-read)

### FP-8 — Primary CTA gradient unification (**code complete**)

Unified all trucker-facing **primary** CTAs to match **Book This Load** (`GradientButton` reference).

| File | Change |
|------|--------|
| `action_buttons.dart` | `PrimaryButton` → `heroCta` gradient + `AppTypography.button` (white); `_ActionButtonFrame` forces light `DefaultTextStyle`; `GradientButton` → delegates to `PrimaryButton` |
| `trucker_route_preview_screen.dart` | Open in Google Maps → **`OutlineButton`** (utility — excluded) |
| `chat_screen_action_extensions.dart` | Reject booking confirm → **`DestructiveButton`** |
| `step_business_details.dart` | Open Settings (GPS) → **`OutlineButton`** |

**Now gradient (via `PrimaryButton` / `GradientButton`)**

- Find Loads: Apply filters, empty-state CTAs
- Load detail: Book This Load, confirm-booking dialogs, Open fleet dialog, system share sheet
- Fleet: Save truck, Take photo (camera) in bottom sheet
- Trip detail: stage advance, Upload POD, Take photo sheet
- Chat: Approve booking (inline + dialog)
- Verification / support / reviews / auth: submit & continue actions
- Onboarding: Continue, Save and continue

**Explicitly NOT gradient (utility / secondary)**

- Open in Google Maps (`OutlineButton` or `GoogleMapsOpenButton` inset on dark cards)
- Call supplier, chat, LR upload, retry, gallery picker, WhatsApp share
- Reject booking dialog (`DestructiveButton`)

### FP-9 — Hindi language & TTS improvements (**code complete**)

**Spec:** [hindi-improvement.md](./hindi-improvement.md)

| Phase | Task | Status |
|-------|------|--------|
| 1 | Devanagari rewrite of `tts/tts_hi.arb` + regen via `gen_tts_l10n.ps1` | [x] |
| 1 | Conversational simplification of 15+ keys in `app_hi.arb` | [x] |
| 2 | `DocumentUploadBox` optional `ttsMessage` + verification wizard speakers | [x] |
| 2 | Aadhaar/PAN field TTS on identity step | [x] |
| 2 | Conversational shell tab summaries (`user_app_shell.dart`) | [x] |
| 3 | `TtsTermLocalizer` for material/body type in TTS builders | [x] |
| 3 | Load detail truck requirements + trip estimate section speakers | [x] |
| 3 | Load detail truck requirements + trip estimate section speakers | [x] |
| 3 | Incoming chat text bubble on-demand TTS | [x] |
| 2+ | **Truck verification wizard** — speakers on truck number, body type, tyres, capacity, RC, truck photo | [x] |

**New TTS keys (truck wizard):** `ttsFieldTruckNumberInputDescription`, `ttsFieldTruckBodyTypeDescription`, `ttsFieldTruckTyresDescription`, `ttsFieldTruckCapacityInputDescription`, `ttsFieldUploadTruckPhotoPrompt`

**Files:** `tts_hi.arb`, `tts_en.arb`, `app_hi.arb`, `tts_term_localizer.dart`, `load_*_tts_builder.dart`, `document_upload_box.dart`, `step_identity_documents.dart`, `step_truck_details.dart`, `step_profile_photo.dart`, `user_app_shell.dart`, `trucker_load_detail_sections.dart`, `trucker_load_detail_shared.dart`, `marketplace_load_card.dart`, `chat_message_sections.dart`, `onboarding_screens.dart`, `onboarding_profile_completion.dart`, `onboarding_ui_widgets.dart`

**Open:** FP-9 device QA — Hindi TTS on marketplace card, load detail sections, verification uploads (identity + **truck step**), tab auto-read (B-6.9)

### FP-10 — Pull-to-refresh (**code complete**)

| Screen | Mechanism | File |
|--------|-----------|------|
| Trucker dashboard | `ShellScrollView.onRefresh` → `ref.invalidate` dashboard + profile | `trucker_dashboard_screen.dart` |
| Supplier dashboard | Same → dashboard + profile + recent loads | `supplier_shell_dashboard_sections.dart` |
| Find Loads (marketplace) | `RefreshIndicator` on `CustomScrollView` → `loadInitial()` | `trucker_find_loads_screen.dart` |
| Trucker trips | `ShellScrollView.onRefresh` → `truckerTripsProvider.load()` | `trucker_trips_screen.dart` |
| Supplier trips | Same pattern | `supplier_shell_trip_sections.dart` |
| Notifications | `RefreshIndicator` on list → `notificationsProvider.load()` | `notifications_screen.dart` |
| Supplier My Loads | Already had `RefreshIndicator` (unchanged) | `supplier_shell_my_loads_sections.dart` |

**Shared:** `ShellScrollView` now accepts optional `onRefresh` and uses `AlwaysScrollableScrollPhysics` so pull works on short pages.

**Open:** FP-10.1 device QA — pull on dashboard + Find Loads + notifications

### FP-11 — Notification badge count fix (**code complete**)

**Problem:** Bell showed stale count (e.g. 2) after tapping a notification — list updated optimistically but badge lagged or stuck.

**Root cause:** `shellUnreadNotificationCountProvider` counted unread rows from Supabase realtime stream (incomplete snapshot), diverging from RPC total and from `notificationsProvider` optimistic `markRead`.

**Fixes:**

| Change | File |
|--------|------|
| `watchUnreadCount()` re-fetches authoritative RPC on each table change (not row-count from stream) | `notification_repository.dart` |
| Stream merge preserves local `isRead: true` when realtime is briefly stale | `notification_providers.dart` |
| `ref.invalidate(shellUnreadNotificationCountProvider)` after mark read / mark all read | `notifications_screen.dart` |
| Notifications overview uses same provider as shell bell (single source of truth) | `notifications_screen.dart` |

**Open:** FP-11.1 device QA — 2 unread → tap one → bell drops to 1 immediately (G-2.6 adjacent)

### FP-12 — Dark ink hero headers (**code complete**)

Align list/detail screen **top widgets** with load-detail dark ink pattern: `HeroActionCard(useDarkTheme: true, useInkGradient: true)` + `StatusBadge` / `FilterChipBar` chips.

**Reference:** Find Loads hero + load detail `_LoadRoutePriceSection` / `_InkDetailFactChip`.

| Screen | Was | Now | File |
|--------|-----|-----|------|
| Trucker Trips | Light `DetailSectionCard` | Dark ink hero + filter chips | `trucker_trips_screen.dart` |
| Notifications | Light `SectionCard` | Dark ink hero + unread/high-priority badges | `notifications_screen.dart` |
| Profile | Light `SectionCard` only | Dark ink hero + readiness badges; detail rows below | `shell_profile_screen.dart` |
| Settings | Light `SectionCard` only | Dark ink hero (UI + voice language chips) | `shell_settings_screen.dart` |
| Supplier My Loads | Light header | Dark ink hero + Active/Completed tabs | `supplier_shell_my_loads_sections.dart` |
| Supplier Trips | Light header | Dark ink hero + filter chips | `supplier_shell_trip_sections.dart` |
| Post Load | Light hero | Dark ink hero | `post_load_screen.dart` |
| Supplier Load Detail | Light hero | Dark ink hero + status badges | `supplier_shell_load_detail_sections.dart` |

**Already dark (unchanged):** Trucker/supplier dashboard, Find Loads, Messages, Fleet, Trip detail, Support, Chat context banner, Trucker load detail.

**Left light / special (intentional):** Verification status banners (`VerificationBanner`), Route Preview (plain title), wizard step headers.

**Open:** FP-12.1 visual QA on 360dp — trips, notifications, profile, settings, supplier lists

### FP-13 — Dashboard route-search hero (**code complete**)

Replace the trucker dashboard welcome poster with a **route search home** — same dark ink hero as Find Loads, but **From | To only** (no body type, tyres, or advanced filters on dashboard).

**Product direction:**

| Element | Was | Now |
|---------|-----|-----|
| Hero role | Large “Welcome back” + text badges + duplicate Find Loads CTA | Route search + single “Search loads” CTA |
| Greeting | Dominant title | Secondary subtitle — “Namaste, {name}” |
| Trust | Full `StatusBadge` text | Compact icon chips (verified ✓ + truck count) with tooltips |
| Search | None on dashboard | `MarketplaceRouteSearchFields` — origin/destination + city suggestions |
| CTA | Full-width Find Loads in hero | “Search loads” / “Load khojein” → Find Loads tab with route prefilled |
| Filters hint | — | “Truck type and filters on Find Loads tab” (11px) |
| Quick Actions | Unchanged | Find Loads, Fleet, Trips, Chat grid below hero |

**Implementation:**

| Change | File |
|--------|------|
| Dashboard hero widget (greeting, trust row, route fields, CTA) | `widgets/dashboard_route_search_hero.dart` |
| Shared From \| To search + suggestions | `widgets/marketplace_route_search_fields.dart`, `widgets/city_suggestion_list.dart` |
| Route prefill across tab navigation (`autoDispose` safe) | `find_loads_provider.dart` — `marketplaceRoutePrefillProvider` |
| Dashboard screen wiring | `trucker_dashboard_screen.dart` |
| l10n | `truckerDashboardHeroGreeting`, `truckerDashboardSearchLoadsAction`, `truckerDashboardFiltersOnFindLoadsHint` |

**Open:** FP-13.1 device QA — enter origin/dest on dashboard → tap Search loads → Find Loads tab shows fields + filtered feed; trust tooltips readable on 360dp

**Deferred (separate epic):** Voice (Speaker) system — Stop, Replay, persistent Mute, voice strip in app bar (not FP-13)

### Not started (release tail)

- Ship gate, full device QA matrix, Play upload

---

## Epic overview (UI work)

| Epic | ID | Summary | Status |
|------|-----|---------|--------|
| Theme helpers | **FP-0** | `AppDecorations` + `BrandAccentChip` | **Done** |
| Marketplace load card | **FP-1** | Full-bleed card, price+facts row, TTS header | **Done** |
| Find Loads filters | **FP-3** | Dark ink hero/tabs/pinned; Any + conditional tyres | **Done** |
| Load detail | **FP-2** | Map removed; dark ink sections; costing/TTS | **Done** |
| Chat UX polish | **FP-5** | Centered lane, scroll, composer, grouping | **In progress** |
| Load card light theme | **FP-6** | Light surface + brand gradient border | **Kept** |
| Onboarding plain language | **FP-7** | Bhada khoje / post kare; brand cards + gradient Continue | **Code complete** (QA pending) |
| Primary CTA gradient | **FP-8** | `PrimaryButton` = heroCta + white text app-wide | **Code complete** |
| Hindi TTS + l10n | **FP-9** | Devanagari TTS, conversational HI, verification/load/chat speakers | **Code complete** (QA pending) |
| Pull-to-refresh | **FP-10** | Dashboard, Find Loads, trips, notifications | **Code complete** |
| Notification badge | **FP-11** | Bell count sync with mark-read | **Code complete** |
| Dark ink heroes | **FP-12** | List screen top widgets match load-detail style | **Code complete** |
| Dashboard route search | **FP-13** | Dashboard hero = From/To search + prefill Find Loads | **Code complete** |
| Dashboard Find Loads | **FP-4** | Reuse filter bar on dashboard (body/tyres) | **Deferred** — route covered by FP-13 |

---

## FP-1 — Marketplace load post card (compact redesign)

### Current implementation (as of 2026-05-30)

| Piece | Location | Role |
|-------|----------|------|
| Header | `marketplace_dark_header.dart` | Supplier (15.6px), avatar (15.6 radius), route, **TTS speaker** — no status chip |
| Card shell | `marketplace_load_card.dart` | Gradient border + ink fill; full-bleed in feed |
| Price + facts | `marketplace/marketplace_price_fact_row.dart` | Price 21px + mini **`BrandAccentChip`** (material, body, tyres) |
| Route | `marketplace_route_line.dart` | Cities 19px |
| Footer | `marketplace_load_card.dart` | Call / Details / Chat — plain, 40px, dividers |
| Feed | `trucker_find_loads_screen.dart` | No horizontal pad on list; `cardGap` between cards |
| TTS | `load_marketplace_card_tts_builder.dart` | Route, material, truck, rate (no profit) |

**Removed (v1):** `_MoneyRow`, `TripCostingService` / `dieselPrice` on card, `load_card_dark_header.dart`.

### Product direction (shipped)

- **Drop** load value and estimated profit from list card.
- **Full-bleed** card in Find Loads list.
- **Typography:** route cities **19px**, rate **21px**; supplier **15.6px** (+20%); meta **11px**; footer **12px**.
- **Price row:** price left; **material + body type + tyres** as mini gradient chips on same line (horizontal scroll if tight).
- **Status:** **not shown** on list card; TTS speaker top-right (status still in spoken summary).
- **Card shell:** brand gradient border 1.2px.
- **Footer:** plain actions (gradient footer **reverted**).
- Profit context on load detail only (FP-2).

### Layout wire (current — shipped)

```
┌───────────────────────────────────────────────
│ [av] Supplier · 2h                    [🔊]   │
│ FROM  Mumbai  ──────►  TO  Delhi             │
│ ₹12,500/T   [Cement][Open][14T]              │
│ Today · 20% adv · 1/2 trucks                   │
│  📞 Call  │  ℹ Details  │  💬 Chat            │
└───────────────────────────────────────────────
```

### Task breakdown

| # | Task | Detail | Status |
|---|------|--------|--------|
| FP-1.1 | Remove `_MoneyRow` | Delete 3-column gradient; no `totalLoadValue` / `costEstimate` in header | [x] |
| FP-1.2 | Add `_CompactRateRow` | Single line: `₹X/T` or `₹XK Fixed`; reuse `formatAmount` | [x] |
| FP-1.3 | Drop costing from card | Remove `tripCostingService`, `dieselPrice` from `MarketplaceLoadCard` | [x] |
| FP-1.4 | Unwire Find Loads list | Remove `dieselPriceMapProvider` / `tripCostingServiceProvider` from feed screen | [x] |
| FP-1.5 | Header sizing | Avatar radius **15.6**; supplier name **15.6px** (+20%) | [x] |
| FP-0.1 | Add `AppDecorations` | Gradient chip + border helpers in `core/theme/` | [x] |
| FP-1.6 | Gradient chips | `LoadInfoChip` → `BrandAccentChip` via `AppDecorations` | [x] |
| FP-1.7 | Full-bleed list | Remove horizontal `SliverPadding` on load list only | [x] |
| FP-1.8 | Card gradient border | Marketplace shell via `AppDecorations.brandGradientBorderOuter` | [x] |
| FP-1.9 | Typography v2 | Route cities 19px; rate 21px; supplier/meta/footer smaller | [x] |
| FP-1.10 | Legacy cleanup | Deleted unused `load_card_dark_header.dart` | [x] |
| FP-1.11 | Drop list status chip | Remove Active/`StatusChip` from card; TTS speaker top-right | [x] |
| FP-1.12 | Price + facts row | `MarketplacePriceFactRow`: material, body, tyres beside price | [x] |
| FP-1.13 | l10n for “Fixed” | `supplierPostLoadPriceTypeValue('fixed')` on fixed-price loads | [x] |
| FP-1.14 | Footer gradient trial | Reverted — keep plain Call/Details/Chat | [x] n/a |
| FP-1.15 | TTS verify | Manual on device | [x] |
| FP-1.16 | Widget / golden tests | EN/HI overflow at 360dp | [ ] |
| FP-1.17 | Device check | Per-ton + fixed; tap, TTS, footer | [x] |

### Files to touch

- `core/theme/app_decorations.dart`
- `marketplace/marketplace_price_fact_row.dart` (**new**)
- `marketplace/marketplace_chips.dart`
- `marketplace/marketplace_dark_header.dart`
- `marketplace_load_card.dart`
- `marketplace/marketplace_route_line.dart`
- `trucker_find_loads_screen.dart`
- `load_marketplace_card_tts_builder.dart`
- ~~`load_card_dark_header.dart`~~ (deleted)
- **Later (opt-in):** `content_cards.dart` — `useBrandBorder` on `DetailSectionCard` / `StandardListCard`
- **Do not edit in FP-1:** `status_components.dart` global palettes (unless adding optional variant)

### Acceptance criteria

- [x] No UI for **load value** or **est. profit** on marketplace card.
- [x] Per-ton and fixed loads show correct price label (l10n for Fixed).
- [x] Card tap → detail; speaker → TTS; footer actions — device verify.
- [x] List scroll performance unchanged (no costing rebuild per card).
- [x] Hindi + English: no overflow on 360dp width — device verify.

---

## FP-2 — Trucker load detail page (layout + maps)

### Current implementation (2026-05-29)

| Piece | Location | Role today |
|-------|----------|------------|
| Screen | `trucker_load_detail_screen.dart` | Reduced top padding; hero TTS via `buildTruckerHeroSummary` |
| Hero route + price | `_LoadRoutePriceSection` | Ink gradient v2; fare teal inset; distance + **drive days**; compact arc; Google Maps |
| In-app map | — | **Removed** (`flutter_map` / `latlong2` dropped from pubspec) |
| Maps launcher | `google_maps_open_button.dart` | Teal inset button; `MapsLauncherService` |
| Truck requirements | `DetailSectionCard.useInkGradient` | Horizontal fact pills + 2-col metric tiles |
| Costing | `_EarningsEstimateCard` | Ink gradient; ₹100/L default; fixed vs per-ton load value |
| Supplier | Ink section + `profile_avatar_merge` | Verified pill; chat |
| Next step | `_LoadNextStepSection` | Ink section; **dark truck dropdown** |
| TTS | `load_detail_tts_builder.dart` | No duplicate truck-requirements read on hero |

### Product direction

- **Remove** embedded `_LoadRouteMapSection` (`FlutterMap` removed from app — **`flutter_map` / `latlong2` dropped from `pubspec.yaml`**).
- **Maps:** **Google Maps only** via `MapsLauncherService.buildDirectionsUri` + `commonOpenInGoogleMapsAction`. No “Open in Maps” system picker, no in-app tile map.
- **Redesign** vertical hierarchy: route hero → fact chips → truck match / booking → costing → supplier.
- Reuse existing chips, `DetailSectionCard`, `StatusChip` — **no new data fields**.
- Consistent horizontal padding: `AppSpacing.lg`.
- TTS “read all” + section speakers unchanged.

### Proposed layout (wire-level)

**Full page scroll (top → bottom)**

```
┌─────────────────────────────────────────────┐
│ ← Load detail                    [share][⋯] │  ← app bar (existing shell)
├─────────────────────────────────────────────┤
│ [ 🔊 Read all ]                             │
├─────────────────────────────────────────────┤
│ ┌─ ROUTE HERO (dark gradient) ────────────┐ │
│ │ Mumbai, MH → Delhi, DL          [TTS]   │ │
│ │ [SUPER] [Open load] [Posted]            │ │
│ │                                         │ │
│ │ ₹12,500 / ton                           │ │  ← price 28–32px
│ │ Pickup: Tue, 3 Jun                      │ │
│ │ ─────────────────────────────────────── │ │
│ │ 📍 1,420 km  ·  ⏱ ~22 hr                │ │  ← distance / duration row
│ │                                         │ │
│ │ [🗺 Open in Google Maps]                    │ │  ← single CTA when coords exist
│ └─────────────────────────────────────────┘ │
│                                             │
│   (NO FlutterMap block — removed)           │
│                                             │
├─────────────────────────────────────────────┤
│ Truck requirements                   [TTS]  │
│ [Open] [14 tyres] [12-18T] [Cement]         │
├─────────────────────────────────────────────┤
│ Your truck match                     [TTS]  │
│ ○ MH-12-AB-1234 · Open · 14T               │
│ [ Book this load ]                          │
├─────────────────────────────────────────────┤
│ Trip estimate                        [TTS]  │
│ Diesel · Toll · Driver · Revenue            │
│ ┌─────────────────────────────────────────┐ │
│ │ Est. profit        ₹18,400              │ │  ← profit lives HERE only
│ └─────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│ Supplier                             [TTS]  │
│ [av] Acme Logistics · ★ · Call · Chat      │
└─────────────────────────────────────────────┘
```

**Route hero detail (FP-2.2 focus area)**

```
┌─────────────────────────────────────────────┐
│ Origin City, ST  →  Dest City, ST    [🔊]  │
│ [badge] [badge] [badge]                     │
│ ₹85,000 fixed                               │
│ Pickup · Wed, 4 Jun                         │
├─────────────────────────────────────────────┤
│  📍 842 km          ⏱ ~14 hr               │
├─────────────────────────────────────────────┤
│ ┌─────────────┐                              │
│ │ Google Maps │                              │  ← single outline/full-width button
│ └─────────────┘                              │
└─────────────────────────────────────────────┘
```

**Maps behavior (unchanged logic, clearer UI)**

```
Coordinates present?
  ├─ yes → show **Open in Google Maps** (external URI)
  └─ no  → hide maps button; route text + distance only
```

### Task breakdown

| # | Task | Detail | Status |
|---|------|--------|--------|
| FP-2.1 | Remove in-app map | Delete `_LoadRouteMapSection`; remove `flutter_map` + `latlong2` from pubspec | [x] |
| FP-2.2 | Enhance route hero | Ink gradient v2; distance/drive-days row; fare inset; compact arc | [x] |
| FP-2.3 | Maps CTA | `GoogleMapsOpenButton` teal inset | [x] |
| FP-2.4 | Section spacing audit | `AppSpacing.lg` horizontal; consistent `sectionGap` between cards | [x] |
| FP-2.5 | Keep costing block | ₹100/L diesel; fixed vs per-ton; drive days helper | [x] |
| FP-2.6 | Dark ink body sections | Truck req, supplier, next step via `useInkGradient` | [x] |
| FP-2.7 | TTS dedupe | Hero/speaker skips truck-requirements repeat | [x] |
| FP-2.8 | Update tests | `drive_time_estimate_test`, `trip_costing_service_test`, `diesel_price_repository_test`, responsive smoke | [x] |
| FP-2.9 | Device QA | External maps; booking + TTS regression; ₹100/L earnings | [x] |

### Files to touch

- `trucker_load_detail_sections.dart`
- `trucker_load_detail_primary_sections.dart`
- `trucker_load_detail_screen.dart`
- `route_preview_screen.dart` (verify only)
- `test/.../trucker_load_detail_screen_test.dart`

### Acceptance criteria

- [x] No `FlutterMap` on trucker load detail.
- [x] Coordinates present → Google Maps launch via inset CTA.
- [x] Dark ink sections for truck requirements, supplier, next step, earnings.
- [x] All detail chips and booking flows — device verify.
- [x] TTS hero without duplicate truck-requirements block.

---

## FP-3 — Find Loads header filters (truck type + tyres) — **done**

### Current implementation (2026-05-29)

| Piece | Location | Role |
|-------|----------|------|
| Screen | `trucker_find_loads_screen.dart` | Dark ink hero + tabs; pinned truck filter; tight gap to cards |
| Hero | `HeroActionCard` (`useInkGradient`) | Origin/dest/material; dark **sort dropdown** |
| Filter bar | `marketplace_filter_bar.dart` | **[Any]** (default) + body types; tyres when type ≠ Any |
| Tabs | `_FindLoadsFeedTabs` | All / Super — dark ink, full-bleed, scroll away |
| Pinned | `_PinnedTruckFilterBar` | Full-bleed ink; 53px (Any) / 94px (+ tyres) |
| Provider | `find_loads_provider.dart` | Clears tyres when body type = Any |

### Product direction (shipped)

1. **Truck-type filter** pinned: **Any** (default) · Open · Container · Trailer · Tanker.
2. **Tyre row** visible only when a **specific** body type is selected (not Any); counts from fleet DB list (6, 10, 12, 14, 16, 18, 22).
3. **Find Loads hero** (dark ink) scrolls away; **All / Super** tabs scroll with hero.
4. **Advanced sheet:** min/max price only.

### Layout wire (at top)

```
┌─────────────────────────────────────────────┐
│ Find Loads hero (origin/dest, material)     │
│ [ All loads ] [ Super loads ]               │
├─────────────────────────────────────────────┤
│ PINNED: [Any][Open][Container][Trailer]…    │
│         (tyres row if type ≠ Any)           │
├─────────────────────────────────────────────┤
│ LOAD CARD                                    │
└─────────────────────────────────────────────┘
```

### Layout wire (scrolled down)

```
┌─────────────────────────────────────────────┐
│ PINNED: [Any][Open][Container][Trailer]…    │
│         (tyres row if type ≠ Any)           │
├─────────────────────────────────────────────┤
│ LOAD CARD                                    │
└─────────────────────────────────────────────┘
```

### Task breakdown

| # | Task | Detail | Status |
|---|------|--------|--------|
| FP-3.1 | Extract `MarketplaceFilterBar` | Shared widget under `presentation/widgets/` | [x] |
| FP-3.2 | Wire pinned truck filter | Provider callbacks; separate from tabs | [x] |
| FP-3.3 | Clear tyres on Any | `find_loads_provider` clears tyres when body type empty | [x] |
| FP-3.4 | Fix pinned header height | 53px (Any) / 94px (+ tyres); +20% for tyre row | [x] |
| FP-3.12 | Dark ink UI | Hero, tabs, pinned bar match load-detail ink gradient | [x] |
| FP-3.13 | Any chip + tyre rules | Any default; tyres for specific types only; fleet tyre list | [x] |
| FP-3.5 | Scroll-hide behavior | Hero + tabs scroll; truck filter pinned | [x] |
| FP-3.6 | Restore search hero | Scrollable origin/dest/material/sort; price-only advanced sheet | [x] |
| FP-3.7 | Remove active filter summary | No extra row under tabs | [x] |
| FP-3.8 | Filter TTS update | `FindLoadsTabTtsBuilder` | [ ] |
| FP-3.9 | l10n hints (optional) | Filter bar a11y labels | [ ] |
| FP-3.10 | Fix widget tests | Scroll-collapse test + TTS delegates; some overflow cases remain | [x] partial |
| FP-3.11 | Device QA | Filter → feed RPC; super tab; scroll header | [x] |

### Acceptance criteria

- [x] Truck type visible without opening bottom sheet.
- [x] **Any** default; tyre filter visible for specific body types only.
- [x] Tyre counts match `truckerFleetTyreOptions` (6–22).
- [x] Dark ink hero, tabs, pinned filter; dark sort dropdown.
- [x] Filters apply to feed via existing RPC params.
- [x] Hero + tabs scroll away; truck filter stays pinned.
- [x] Super loads tab works.
- [x] Empty state reset clears filters via provider.

---

## FP-6 — Marketplace load card light theme (**kept**)

> **Decision (2026-05-30):** Device review approved light card on Find Loads feed. Revert anytime: `AppDecorations.marketplaceLoadCardLightExperiment = false`.

Ref: FP-1 shipped dark ink card; `docs/loadpost-ui-ux.md` original spec used light `surfaceBase` + divider.

### What FP-1 shipped (before experiment)

| Piece | Detail |
|-------|--------|
| Shell | `brandGradientBorderOuter` — teal→orange **1.2px stroke** (unchanged) |
| Fill | `marketplaceCardSurface()` — dark ink gradient (`inkSurface` → `inkMid`) |
| Text | `inkTextPrimary` / `inkTextSecondary` throughout header, route, price, footer |
| Chips | `BrandAccentChip` mini row (material, body, tyres) — unchanged |
| Layout | Full-bleed in Find Loads; no status chip; TTS top-right |

### Experiment change

| Piece | Dark (default) | Light experiment |
|-------|----------------|------------------|
| Fill | `marketplaceCardSurface()` | `marketplaceCardLightSurface()` — `cardSurface` + `elevation1` |
| Text | `inkText*` | `textPrimary` / `textSecondary` via `AppDecorations.marketplaceCardText*` |
| Border | Brand gradient outer | **Same** — `brandGradientBorderOuter` |
| Toggle | — | `AppDecorations.marketplaceLoadCardLightExperiment` |

### Task breakdown

| # | Task | Status |
|---|------|--------|
| FP-6.1 | Centralized light fill + text helpers in `AppDecorations` | [x] |
| FP-6.2 | `marketplaceCardFill()` switch on experiment flag | [x] |
| FP-6.3 | `onDarkSurface` on header, route, price row, footer, TTS | [x] |
| FP-6.4 | Device QA — light card on Find Loads feed (EN/HI) | [x] |
| FP-6.5 | Keep or revert experiment | [x] keep |

### Acceptance criteria

- [x] Brand gradient border unchanged on full-bleed card.
- [x] Light fill uses `AppColors.cardSurface` (not ad-hoc hex).
- [x] All card text/icons respect `onDarkSurface` / centralized color helpers.
- [x] Readable on Find Loads dark ink hero + pinned filter background.
- [x] Revert is one boolean flip with no other file edits.

### FP-3 follow-up — pinned truck filter height (+20%)

| Change | Was | Now |
|--------|-----|-----|
| Pinned height (Any) | 44px | **53px** |
| Pinned height (+ tyres) | 78px | **94px** |
| Tyre row gap | `AppSpacing.xs` | **`AppSpacing.sm`** |
| Tyre chip padding / icon | xs / 14px | **5px vertical / 16px icon** |

Files: `trucker_find_loads_support.dart`, `marketplace_filter_bar.dart`

---

## FP-7 — Auth onboarding plain language (**code complete**)

Ref: `RoleSelectionScreen` — first choice after sign-in for new users.

### Problem

“Trucker / Supplier / role / workflows” jargon is unclear for many drivers and load owners.

### Product direction (shipped in copy)

| Old label | New label (EN) | New label (HI) |
|-----------|------------------|----------------|
| Trucker | **Find Loads** (+ Bhada khoje hint) | **भाड़ा खोजें** |
| Supplier | **Post a Load** (+ Bhada post kare hint) | **भाड़ा पोस्ट करें** |
| Choose role | **Get started** / find vs post question | **शुरू करें** / **भाड़ा खोजना है या पोस्ट करना है?** |
| TTS (HI) | — | *Apna role chunein. Load dhoondhna hai ya load post karna hai?* |

### UI (shipped)

```
┌─────────────────────────────────────────────┐
│ Get started                          [TTS]  │
│ Do you want to find loads or post a load?   │
│ Tap the option that matches your work…      │
├─────────────────────────────────────────────┤
│ ┌─ gradient border ─────────────────────┐   │
│ │ 🚛 Find Loads                         │   │  ← first (most truckers)
│ │    Bhada khoje — …                    │   │
│ └───────────────────────────────────────┘   │
│ ┌─ gradient border ─────────────────────┐   │
│ │ 📦 Post a Load                        │   │
│ │    Bhada post kare — …                │   │
│ └───────────────────────────────────────┘   │
│ ┌───────────────────────────────────────┐   │
│ │         Continue  (gradient + white)    │   │
│ └───────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Task breakdown

| # | Task | Status |
|---|------|--------|
| FP-7.1 | Plain-language ARB (EN + HI) for role cards, headings, errors, discard dialog | [x] |
| FP-7.2 | TTS `ttsOnboardingChooseRole` (EN + HI) — load find/post not trucker/supplier | [x] |
| FP-7.2b | Regenerate TTS Dart via `tool/gen_tts_l10n.ps1` (fixes stale “trucker hain ya supplier”) | [x] |
| FP-7.3 | UI: Find Loads card first; `BrandGradientBorder`; icon chips; spacing/semantics | [x] |
| FP-7.3b | Continue + profile Save: `GradientButton` / `PrimaryButton` with white label | [x] |
| FP-7.4 | Device QA — low-literacy walkthrough EN + HI (cards + TTS) | [ ] |
| FP-7.5 | Optional: per-card TTS on tap | [ ] |

### Files

- `onboarding_screens.dart`, `onboarding_profile_completion.dart`
- `app_en.arb`, `app_hi.arb`, `tts/tts_en.arb`, `tts/tts_hi.arb`
- `app_decorations.dart` (`BrandGradientBorder`)
- `action_buttons.dart` (Continue styling — see FP-8)

---

## FP-8 — Primary CTA gradient unification (**code complete**)

Ref: **Book This Load** on trucker load detail — teal→orange fill, white label.

### Problem

Mixed primary styles: solid teal `PrimaryButton` vs gradient `GradientButton`; onboarding Continue label could inherit dark theme text.

### Shipped

| Change | Detail |
|--------|--------|
| `PrimaryButton` | `AppColors.heroCta` gradient + `AppShadows.heroCta` |
| Label color | `AppTypography.button` (`textOnPrimary` / white) |
| Frame | `_ActionButtonFrame` wraps label in `DefaultTextStyle` + `IconTheme` so parent theme cannot override |
| `GradientButton` | Thin delegate to `PrimaryButton` (single implementation) |

### Exclusions (stay outline / destructive / custom)

| Pattern | Widget |
|---------|--------|
| Open in Google Maps | `OutlineButton` or `GoogleMapsOpenButton` |
| Open Settings (GPS dialogs) | `OutlineButton` |
| Reject booking confirm | `DestructiveButton` |
| Secondary actions | `OutlineButton`, `TextActionButton` |

### Task breakdown

| # | Task | Status |
|---|------|--------|
| FP-8.1 | Unify `PrimaryButton` gradient + white typography | [x] |
| FP-8.2 | `GradientButton` → delegate to `PrimaryButton` | [x] |
| FP-8.3 | Demote utility primaries (Maps route preview, GPS settings) | [x] |
| FP-8.4 | Reject booking → `DestructiveButton` | [x] |
| FP-8.5 | Device spot-check: onboarding Continue, Book This Load, fleet save, trip POD | [ ] |

### Files

- `lib/src/shared/widgets/action_buttons.dart`
- `trucker_route_preview_screen.dart`
- `chat_screen_action_extensions.dart`
- `wizard_steps/step_business_details.dart`

---

## FP-5 — Chat UX polish (CI-1–CI-14)

Ref: `docs/TODO&Progress/phase-07-communication-chat-bot.md` § Chat-Improvement

### Product direction

- Center conversation like **WhatsApp**: other party **far left**, you **far right** (small edge inset only).
- **Group** consecutive same-sender messages with tighter vertical spacing.
- **Scroll-to-latest** must be reliable after send/receive; persistent new-message pill when reading history.
- **Composer:** capsule input, long-press mic, circular send button.
- **Empty / error:** quick-reply chips; retry on load failure.

### Task breakdown

| # | Task | Detail | Status |
|---|------|--------|--------|
| FP-5.1 | Edge-aligned bubbles | Receiver `Align.centerLeft`, sender `Align.centerRight`; 8px screen inset | [x] |
| FP-5.2 | Screen-based bubble width | `min((screen - inset) * 0.76, 420)` | [x] |
| FP-5.3 | Asymmetric bubble shape | 18px corners, 6px tail on sender side | [x] |
| FP-5.4 | Message grouping | 4px within group, 10px between senders; timestamp on last | [x] |
| FP-5.5 | Scroll-to-latest | Double post-frame scroll; force on own send | [x] |
| FP-5.6 | Bottom list padding | Extra 16px below last bubble | [x] |
| FP-5.7 | New-message pill | Persistent until tap/scroll near bottom; ↓ icon | [x] |
| FP-5.8 | Scroll-down FAB | Shown when scrolled up without new messages | [x] |
| FP-5.9 | Long-press voice | Hold mic → record, release → send; tap fallback | [x] |
| FP-5.10 | Composer polish | Top shadow, rounded input capsule, disable while sending | [x] |
| FP-5.11 | Long-press actions | Copy text via bottom sheet | [x] |
| FP-5.12 | Text padding | 12×10 for text; full pad for cards/voice | [x] |
| FP-5.13 | Load older pill | Compact centered chip instead of plain text button | [x] |
| FP-5.14 | Empty + error UX | Quick-reply chips; retry on messages load failure | [x] |
| FP-5.15 | Tests + device QA | Chat screen/widget tests; manual thread QA | [ ] |

### Acceptance criteria

- [x] Sender/receiver bubbles readable inside centered lane (not extreme edges).
- [x] Own message scrolls into view immediately after send.
- [x] Incoming messages auto-scroll only when user is near bottom.
- [x] Persistent pill/FAB when reading older messages.
- [x] Voice, map card, truck card, document, system types still render.
- [ ] Device QA on supplier + trucker threads.

---

## FP-4 — Trucker dashboard “Find loads” widget — **deferred**

> **Decision (2026-05-29):** Ship `final-polish` without dashboard filter embed. Revisit on a follow-up branch after merge to `main`.

### Current implementation

| Piece | Location | Role today |
|-------|----------|------------|
| Dashboard | `trucker_dashboard_screen.dart` | `HeroActionCard` + `GradientButton` → `findLoadsPath` |
| Hero child | `_HeroSummary` | Verification + approved truck badges only |
| Filters | — | User must open Find Loads tab to filter |

### Product direction

- Embed **same `MarketplaceFilterBar` as FP-3** inside dashboard hero.
- On **Find loads** tap: `findLoadsProvider.notifier.updateFilters(...)` then `context.go(findLoadsPath)`.
- Keep hero compact: welcome + badges + filter strip + primary CTA.
- Single source of truth: `MarketplaceSearchFilters` via provider only.

### Proposed layout (wire-level)

**Dashboard hero (target)**

```
┌─────────────────────────────────────────────┐
│ Good morning, Rajesh                        │
├─────────────────────────────────────────────┤
│ ┌─ HERO CARD (dark) ───────────────────────┐ │
│ │ ✓ Verified  ·  🚛 2 trucks approved     │ │  ← _HeroSummary badges
│ │                                         │ │
│ │ Filter loads for your truck:            │ │  ← optional hint (l10n)
│ │ [Open][Container][Trailer][Tanker] →    │ │  ← MarketplaceFilterBar
│ │ [6][10][12][14][18]  (if Open)          │ │
│ │                                         │ │
│ │ ┌─────────────────────────────────────┐ │ │
│ │ │         Find loads  →               │ │ │  ← GradientButton
│ │ └─────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│ Overview                                    │  ← existing stats (unchanged)
│ [Active trips] [Pending] …                  │
├─────────────────────────────────────────────┤
│ Quick actions                               │  ← existing grid (unchanged)
└─────────────────────────────────────────────┘
```

**Navigation flow**

```
Dashboard                          Find Loads tab
┌──────────────────┐              ┌──────────────────┐
│ User picks Open  │              │ Same filters     │
│ + 14 tyres       │  ──go──►     │ pre-applied      │
│ taps Find loads  │              │ feed filtered    │
└──────────────────┘              └──────────────────┘
        │
        └─ updateFilters() before navigation
           (no query params in v1)
```

**Small screen (360dp) — horizontal scroll on filter chips**

```
[Open●][Container][Trailer]→
[10●][12][14]→
[ Find loads → ]
```

### Task breakdown

| # | Task | Detail | Status |
|---|------|--------|--------|
| FP-4.1 | Local filter state on dashboard | `ConsumerStatefulWidget` or hold selection until navigate | [ ] |
| FP-4.2 | Compose `MarketplaceFilterBar` | Inside `HeroActionCard` child, above CTA | [ ] |
| FP-4.3 | Navigate with filters | `updateFilters` then `context.go(findLoadsPath)` | [ ] |
| FP-4.4 | Verify provider sync | Find Loads tab shows same body/tyre after navigation | [ ] |
| FP-4.5 | Layout at 360dp | Horizontal scroll; no overflow | [ ] |
| FP-4.6 | Optional `restoreFilters` | Helper on provider if dashboard needs read-back | [ ] |
| FP-4.7 | Device QA | Dashboard → Find Loads filter continuity | [ ] |

### Files to touch

- `trucker_dashboard_screen.dart`
- `presentation/widgets/marketplace_filter_bar.dart` (shared)
- `find_loads_provider.dart` (optional helper)

### Acceptance criteria

- [ ] Dashboard filters match Find Loads tab state after navigation.
- [ ] No second source of truth for `MarketplaceSearchFilters`.
- [ ] Layout acceptable on small screens (wrap or horizontal scroll).

---

## Carry-over from TODO-29-may.md (expanded)

*Check `[x]` here and in TODO-29-may when each item completes.*

### Ship gate (human)

| ID | Task | Expanded steps | Owner | Status |
|----|------|----------------|-------|--------|
| A-5.1 | Pull latest on build machine | `git checkout main && git pull origin main` before APK build | Dev | [ ] |
| A-5.5 | Optional RC tag | `git tag v1.x-rc1 && git push origin v1.x-rc1` after QA sign-off | Dev | [ ] |
| A-5.6 | Play internal upload | Run `build-apk.bat`; upload AAB to Play Console → Internal testing | Dev | [ ] |
| A-5.7 | Play release notes | Paste EN (+ HI if required) notes from changelog / sprint summary | Dev | [ ] |
| R-1 | Merge play-store → main | **Done on main** — update TODO checkbox only | — | [x] |
| R-2 | Push main | **Done** — update TODO checkbox only | — | [x] |
| R-3 | Optional tag | Same as A-5.5 | Dev | [ ] |

### Device QA

| ID | Task | Expanded steps | Status |
|----|------|----------------|--------|
| G-2.6 | Messages ↔ Trips ↔ Notifications flicker | Rapid tab switch 10×; note jank, wrong tab highlight, or stale badge counts | [ ] |
| B-6.8 | App bar mute stops auto speech | Enable TTS auto-read; tap mute; confirm no further utterances until unmute | [ ] |
| B-6.9 | Hindi voice test | Voice settings → Hindi; sample marketplace card + detail section | [ ] |
| B-6.10 | English voice test | Same flows in English locale | [ ] |

### Verification backlog (deferred v1 — only if product reopens)

| ID | Task | Notes |
|----|------|-------|
| A-1.4.2–A-1.4.7 | Server-required `company_name` / `profile_photo` | Wizard + RPC alignment |
| A-1.5.2–A-1.5.3, A-1.5.5 | Persist truck photo on RPC | Supabase migration + client upload |
| A-1.6.1–A-1.6.3 | Profile photo quality step honesty | UX copy + validation |

### TTS — planning & widgets

| ID | Task | Expanded steps | Priority |
|----|------|----------------|----------|
| C-0.1 | Team review `TTS-29-may.md` | Walkthrough with product; sign off scope for v1 | High |
| C-0.7 | Optional GitHub milestone | Group C-* issues under “TTS polish” milestone | Low |
| C-1.5.1–C-1.5.2 | `TtsIconButton` / `TtsSpeakableCard` | Optional abstractions; `TtsCardSpeakerButton` is standard today | Low |
| C-1.6.4 | Manual HI marketplace card TTS | Device: Hindi locale, speaker on FP-1 card | High |
| C-2.1.5 | Manual EN/HI supplier load list | Supplier My Loads card TTS | Medium |
| C-2.3.2 | Stop TTS when card off-screen | Optional ListView visibility hook | Low |
| C-3.2.3 | Supplier trip detail payment/documents TTS | Deferred post-v1 | — |
| C-4.5 | `tts_focus_field` on post load | Optional a11y for post-load form | Low |
| C-4.10–C-4.11 | Public profile TTS | Trucker views supplier profile | Medium |
| C-5.3–C-5.8 | Analytics, multi-OEM, Hindi currency, a11y footer | See TTS-29-may §C-5 | Medium |
| C-6.1–C-6.8 | Full TTS device regression matrix | Run checklist on `final-polish` APK before merge | High |

### Localization hygiene (§D)

| ID | Task | Expanded steps | Status |
|----|------|----------------|--------|
| D-1 | PR checklist: spoken strings in `tts_*.arb` only | Add checkbox to PR template | [ ] |
| D-2 | Grep audit `lib/src/features/**` | Find string interpolations in UI code | [ ] |
| D-3 | Grep audit `lib/src/shared/widgets/**` | Same for shared widgets | [ ] |
| D-4 | Fix top 5 card title interpolations | Per D-2/D-3 findings | [ ] |
| D-6 | ARB split by feature | Epic; defer if risky before release | [ ] |
| D-7–D-8 | gen-l10n + commit generated Dart | `flutter gen-l10n` after any ARB edit | [x] partial |
| D-9 | CI: fail if ARB edited without regen | Optional Localization Guardrail enhancement | [ ] |
| D-10 | Remove duplicate/unused l10n keys | After D-2/D-3 audit | [ ] |
| D-11–D-12 | TTS label rules + commodity lookup | Document in TTS-ARB-GUIDE | [ ] |

*Include final-polish new strings (filter hints, “Fixed” rate label) in D-7/D-8.*

### Docs & repo (§F)

| ID | Task | Expanded steps | Status |
|----|------|----------------|--------|
| F-4 | Force-add docs | `git add -f docs/*.md` including this file | [ ] |
| F-5 | Push docs commit | After F-4 on `final-polish` or `main` | [ ] |
| F-6 | Un-ignore `docs/` or document force-add | Update `.gitignore` or README note | [ ] |

---

## Suggested implementation order

| Order | Epic / track | Status |
|-------|----------------|--------|
| 0 | **FP-0** AppDecorations | **Done** |
| 1 | **FP-1** Load card | **Done** |
| 2 | **FP-3** Find Loads filters | **Done** |
| 3 | **FP-2** Load detail | **Done** |
| 4 | **FP-5** Chat UX polish | **In progress** |
| 5 | **FP-6** Light load card | **Kept** |
| 6 | **FP-7 / FP-8** Onboarding + primary CTA | **Code complete** (device QA pending) |
| 7 | **G-2.6, B-6.8–10, C-6** | QA pass |
| — | **FP-4** Dashboard filters | **Deferred** (post-merge) |
| 8 | **D-4, D-7–D-8** | l10n hygiene |
| 9 | **A-5.6–7, F-4–5** | Play upload + docs commit |

---

## Testing plan (branch `final-polish`)

### Automated

| Command | Scope |
|---------|--------|
| `dart tool/verify_l10n.dart` | ARB parity, unused keys |
| `flutter gen-l10n` | Regenerate app l10n after `app_*.arb` edits |
| `powershell tool/gen_tts_l10n.ps1` | Regenerate TTS l10n after `tts_*.arb` edits (FP-7) |
| `flutter test test/features/tts/load_marketplace_card_tts_builder_test.dart` | Card TTS |
| `flutter test test/features/trucker/presentation/trucker_find_loads_screen_test.dart` | Find Loads UI — **see Notes** |
| `flutter test test/.../trucker_load_detail_screen_test.dart` | Detail after FP-2 |
| Localization Guardrail CI | On PR |

### Manual (trucker account)

1. **Find Loads:** scroll hero + tabs; pinned truck/tyre; cards full-bleed.
2. **Marketplace card:** price + material/body/tyre chips; no status chip; TTS top-right; footer plain.
3. **Load detail:** no in-app map; external maps; booking unchanged.
4. **TTS:** speaker on card + detail sections; HI + EN.
5. **Nav regression:** Messages / Trips / Notifications (G-2.6).
6. **Onboarding (FP-7):** role cards readable EN/HI; TTS says load find/post not trucker/supplier; Continue white on gradient; profile step scrollable with field speakers.
7. **Primary CTAs (FP-8):** Book This Load, fleet save, trip stage button — all gradient + white label; Maps stays outline/inset.
8. **Hindi TTS (FP-9):** marketplace card + load detail sections + verification wizard (identity **and truck step**) in HI voice.
9. **Pull-to-refresh (FP-10):** dashboard + Find Loads + notifications pull down reloads data.
10. **Notifications (FP-11):** tap notification → bell count decrements without lag.
11. **Dark heroes (FP-12):** Trips, Notifications, Profile, Settings tops match dark ink chip style.

### Regression

- Supplier post load sets `required_body_type` / `required_tyres` → feed RPC respects filters.
- Call / chat from card (`get_supplier_contact_mobile` RPC).

---

## Out of scope (this polish)

- Supplier-side load card redesign (`StandardListCard` in My Loads).
- New map SDK or in-app turn-by-turn.
- Marketplace RPC contract changes (unless body type enum normalization required).
- Admin app UI.

---

## Progress log

| Date | Note |
|------|------|
| 2026-05-30 | Initial plan from codebase review + TODO-29-may pending inventory |
| 2026-05-29 | Branch `final-polish` created; FP-1 compact card + FP-3 filter bar scaffold |
| 2026-05-29 | l10n regen: removed duplicate `commonFromLabel` / `commonToLabel` in generated Dart |
| 2026-05-29 | Doc expanded: task breakdowns + wire layouts for FP-1–FP-4 |
| 2026-05-29 | FP-1 v2: price+facts row (`MarketplacePriceFactRow`); footer gradient reverted |
| 2026-05-29 | FP-3: removed Find Loads search hero + active filter summary; fixed pinned header gap |
| 2026-05-30 | FP-3 scroll header: hero + tabs scroll; truck filter pinned; chip vertical center |
| 2026-05-30 | FP-1 polish: drop Active status chip; TTS top-right; avatar/name +20% |
| 2026-05-30 | Device QA sign-off FP-0/FP-1/FP-3; doc marked complete |
| 2026-05-29 | FP-2: remove in-app map; dark ink route hero + body sections; earnings ₹100/L; drive days; TTS dedupe; supplier avatar merge |
| 2026-05-29 | Find Loads dark ink pass: hero/tabs/pinned filter; Any chip; conditional tyres; dark dropdowns; gap to cards reduced |
| 2026-05-29 | FP-2 complete: diesel ₹100/L floor + migration; device QA sign-off; FP-4 dashboard filters deferred |
| 2026-05-29 | FP-5 chat UX polish: grouping, scroll/FAB/pill, composer, quick replies; WhatsApp edge alignment (receiver left / sender right) |
| 2026-05-29 | **Session pause** — branch pushed; resume FP-5.15 device QA + release tail |
| 2026-05-29 | FP-6 experiment: light marketplace load card + brand gradient border (revert via `marketplaceLoadCardLightExperiment`) |
| 2026-05-30 | FP-6 kept after device review; FP-3 pinned filter +20%; FP-7 onboarding plain language (Bhada khoje / post kare) |
| 2026-05-30 | FP-7 UI: `BrandGradientBorder` role cards; gradient Continue; TTS regen via `gen_tts_l10n.ps1` |
| 2026-05-30 | FP-8: `PrimaryButton` unified to heroCta gradient + white `AppTypography.button`; utility CTAs demoted |
| 2026-05-30 | FP-9: Devanagari `tts_hi.arb`; conversational `app_hi.arb`; verification/load-detail/chat TTS speakers; shell tab summaries — see [hindi-improvement.md](./hindi-improvement.md) |
| 2026-05-30 | FP-9b: Truck verification wizard TTS — number, body type, tyres, capacity, RC, truck photo speakers |
| 2026-05-30 | FP-7: onboarding profile scroll/keyboard fix; `OnboardingFieldSection` + enlarged fields; per-card TTS on role cards |
| 2026-05-30 | FP-10: pull-to-refresh on trucker/supplier dashboard, Find Loads, trips, notifications; `ShellScrollView.onRefresh` |
| 2026-05-30 | FP-11: notification bell count — RPC-based unread stream, merge fix, invalidate on mark read |
| 2026-05-30 | FP-12: dark ink `HeroActionCard` top headers on trips, notifications, profile, settings, supplier my loads/trips/post load/load detail |
| 2026-05-30 | FP-13: trucker dashboard route-search hero — Namaste greeting, icon trust row, From/To fields, Search loads CTA, `marketplaceRoutePrefillProvider` |

---

## Resume (latest)

### Done on branch `final-polish` (not yet merged to `main`)

- [x] FP-0–FP-3 — marketplace card, Find Loads filters, load detail dark ink
- [x] FP-2 — diesel ₹100/L, external maps, earnings card
- [x] FP-5 CI-1–CI-14 — chat grouping, scroll, composer, quick replies, incoming message TTS (FP-9)
- [x] FP-6 — light load card + brand gradient border **kept**
- [x] FP-7 — onboarding plain language; brand gradient role cards; gradient Continue; profile field speakers + scroll fix
- [x] FP-8 — unified `PrimaryButton` / `GradientButton` heroCta + white label
- [x] FP-9 — Hindi Devanagari TTS, conversational `app_hi.arb`, verification identity + **truck** speakers, load detail/chat TTS, shell tab summaries — [hindi-improvement.md](./hindi-improvement.md)
- [x] FP-10 — pull-to-refresh (dashboard, Find Loads, trips, notifications)
- [x] FP-11 — notification bell count sync with mark-read
- [x] FP-12 — dark ink hero headers on remaining list/detail screen tops
- [x] FP-13 — dashboard route-search hero (From/To + prefill Find Loads)
- [ ] **Commit + push** full batch
- [ ] Device QA sign-off (see pick-up table below)

### Pick up here

| Priority | Task | Notes |
|----------|------|--------|
| 1 | **Push** FP-7 through FP-13 batch | After commit on `final-polish` |
| 2 | **FP-13.1** device QA | Dashboard route search → Find Loads prefill |
| 3 | **FP-10.1** device QA | Pull refresh on dashboard + Find Loads |
| 4 | **FP-11.1** device QA | Notification bell decrements on tap (2 → 1) |
| 5 | **FP-12.1** device QA | Dark ink heroes on trips, notifications, profile, settings |
| 6 | **FP-9 / B-6.9** device QA | Hindi TTS: marketplace, load detail, verification (identity + truck), tab auto-read |
| 7 | **FP-5.15** device QA | Supplier + trucker chat threads |
| 8 | **FP-7.4 / FP-8.5** | Onboarding EN/HI + primary button spot-check |
| 9 | Apply diesel migration | `20260529120100_update_diesel_prices_to_100.sql` |
| 10 | Release QA matrix | G-2.6, B-6.8–10, C-6 |
| 11 | `build-apk.bat` → Play internal | After QA sign-off |
| 12 | PR `final-polish` → `main` | After device QA green |

### Deferred (post-merge)

- **FP-4** — dashboard body/tyre `MarketplaceFilterBar` (route search shipped as FP-13)
- **Voice (Speaker) system** — Stop, Replay, persistent Mute, expanded app-bar controls
- **P7.7** — full bot chat (`phase-07-communication-chat-bot.md`)
- **FP-12 follow-up** — dark ink on verification status banners, route preview (if product wants)

### Known test gaps (non-blocking)

- `chat_screen_test.dart` — Supabase init in harness
- `trucker_find_loads_screen_test.dart` — 4 overflow/harness failures
- TTS builder tests updated for Devanagari (`test/features/tts/`) — passing

---

## Notes

### Design system compliance

All marketplace gradient styling goes through **`AppDecorations`** / **`BrandAccentChip`**. Primary filled CTAs go through **`PrimaryButton`** / **`GradientButton`** in `action_buttons.dart` — do not hand-roll gradient buttons in feature screens. List cards do **not** show load status — use **`StatusChip`** on detail/trips/admin only.

### TTS l10n regen (FP-7 / FP-9)

TTS strings live in `lib/l10n/tts/*.arb` and compile to `lib/src/l10n/tts_localizations_*.dart` via a **separate** config (`l10n_tts.yaml`). After editing TTS ARB:

```powershell
cd TranZfort
powershell -ExecutionPolicy Bypass -File tool/gen_tts_l10n.ps1
```

App UI strings still use `flutter gen-l10n` only. Stale TTS Dart caused onboarding to speak old “trucker hain ya supplier” copy until regen (FP-7.2b).

### Pull-to-refresh (FP-10)

Use `ShellScrollView(onRefresh: ...)` for tab screens built on a single scroll column. For `CustomScrollView` feeds (Find Loads), wrap with `RefreshIndicator` + `AlwaysScrollableScrollPhysics`.

### Notification badge (FP-11)

Shell bell uses `shellUnreadNotificationCountProvider` (RPC + realtime). After any `markRead` / `markAllRead`, invalidate that provider — do not count unread from stream row snapshots alone.

### Dark ink heroes (FP-12)

List screen tops: `HeroActionCard(useDarkTheme: true, useInkGradient: true, titleIcon: ...)` with `FilterChipBar` or `StatusBadge` chips in `child`. Match Find Loads / load detail — do not add one-off ink `BoxDecoration`s in feature files.

### Dashboard route search (FP-13)

Trucker dashboard hero is a **route search home**, not a welcome poster. Reuse `MarketplaceRouteSearchFields` for From/To; navigate via `marketplaceRoutePrefillProvider` so Find Loads receives origin/destination after tab switch (`findLoadsProvider` is `autoDispose`). Body type and tyre filters stay on Find Loads only.

### Widget tests

Scroll-collapse test passes with TTS delegates in harness. Some `trucker_find_loads_screen_test.dart` overflow cases may remain (FP-3.10 partial) — not blocking merge.

### l10n duplicate keys (fixed)

Generated files had stale duplicate getters for `commonFromLabel` / `commonToLabel` (top of file + alphabetical position). **Fix:** `flutter gen-l10n` from `TranZfort/`. ARB source had single keys; only generated Dart was out of sync. `dart tool/verify_l10n.dart` passes; TTS builder tests pass.

---

*Link PR to this doc when opening merge request from `final-polish`.*
