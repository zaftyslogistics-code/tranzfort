# Load Post Card Visual Improvements

## Overview
This plan outlines visual improvements for the load post cards with minimal code changes. There are two card variants:
1. **Feed Card** - Shown in the "Find Loads" marketplace feed
2. **Detail Screen** - Shown when user taps "View Details"

---

## Current Architecture

### Feed Card
- **File:** [`TranZfort/lib/src/features/trucker/presentation/trucker_find_loads_screen.dart`](TranZfort/lib/src/features/trucker/presentation/trucker_find_loads_screen.dart:612)
- **Widget:** `_MarketplaceLoadCard`
- **Base:** `StandardListCard` with footer content

### Detail Screen
- **File:** [`TranZfort/lib/src/features/trucker/presentation/trucker_load_detail_sections.dart`](TranZfort/lib/src/features/trucker/presentation/trucker_load_detail_sections.dart:3)
- **Widget:** `_TruckerLoadDetailBody`
- **Components:** `HeroActionCard`, `DetailSectionCard` sections

---

## Feed Card Improvements

### 1. Add Quick Action Buttons (Chat & Call)

**Current:** Only "View Details" text button

**Proposed:** Add a row of quick action buttons below the main content:

```
┌─────────────────────────────────────┐
│ 📍 Origin > Destination    [Active] │
│ 123 km - 2h 30m                     │
│                                     │
│ ┌──────────┐  ┌────┐               │
│ │ ₹1200 /T │  │ 2d │               │
│ └──────────┘  └────┘               │
│                                     │
│ Total load value: ₹24000            │
│ Est. cost: ₹8,500                   │
│                                     │
│ [📦 Material] [⚖️ 20T] [🚛 Open]   │
│                                     │
│ ┌──────────┐ ┌──────────┐          │
│ │ 💬 Chat  │ │ 📞 Call  │          │  ← NEW
│ └──────────┘ └──────────┘          │
│                                     │
│      [View Details →]               │
└─────────────────────────────────────┘
```

**Implementation:**
- Add `Row` with two `OutlineButton.icon` widgets
- Chat button: Navigate to chat or create conversation
- Call button: Use `url_launcher` to open phone dialer with supplier's number

### 2. Improve Price Badge Visual

**Current:** Simple container with border

**Proposed:** Enhanced visual with subtle gradient and icon:

```dart
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  ),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
    ),
    borderRadius: BorderRadius.circular(AppRadius.button),
    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.currency_rupee, size: 16, color: AppColors.primary),
      const SizedBox(width: AppSpacing.xs),
      Text('₹${load.priceAmount.toStringAsFixed(0)} / T', ...),
    ],
  ),
),
```

### 3. Route Visual Enhancement

**Current:** Plain text "Origin > Destination"

**Proposed:** Add origin/destination icons:

```dart
Row(
  children: [
    Icon(Icons.location_on, size: 18, color: AppColors.success),
    const SizedBox(width: AppSpacing.xs),
    Expanded(child: Text('${load.originCity} > ${load.destinationCity}', ...)),
    Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
  ],
),
```

### 4. Meta Chips Enhancement

**Current:** Basic chips with outline icons

**Proposed:** Add color coding by type:
- Material chip: Blue accent
- Weight chip: Green accent  
- Body type chip: Orange accent

---

## Detail Screen Improvements

### 1. Hero Card Enhancement

**Current:** Plain white card with badges

**Proposed:** Add subtle background gradient and better badge layout:

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary.withOpacity(0.03),
        Colors.transparent,
      ],
    ),
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(color: AppColors.divider),
  ),
  child: Padding(
    // ... existing content with improved badge spacing
  ),
),
```

### 2. Supplier Contact Block

**Current:** Supplier name text with verification badge

**Proposed:** Dedicated contact section with action buttons:

```
┌─────────────────────────────────────┐
│ 👤 Contact Owner                     │
│                                     │
│  Rajesh Kumar [✓ Verified]          │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ 💬 Chat  │  │ 📞 Call  │        │
│  └──────────┘  └──────────┘        │
└─────────────────────────────────────┘
```

### 3. Section Card Header Icons

**Current:** Text-only section titles

**Proposed:** Add leading icons to each section:

| Section | Icon |
|---------|------|
| Route & Price Summary | `Icons.map_outlined` |
| Truck Requirements | `Icons.local_shipping_outlined` |
| Cargo Schedule | `Icons.schedule_outlined` |
| Trip Cost Estimate | `Icons.calculate_outlined` |
| Supplier Summary | `Icons.business_outlined` |
| Next Steps | `Icons.touch_app_outlined` |

### 4. Price Summary Enhancement

**Current:** Info background container

**Proposed:** More prominent display with larger typography:

```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.primary.withOpacity(0.08),
        AppColors.primary.withOpacity(0.02),
      ],
    ),
    borderRadius: BorderRadius.circular(AppRadius.card),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '₹${detail.summary.priceAmount.toStringAsFixed(0)}',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        'per tonne • ${_localizedLoadPriceType(...)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Pickup: ${_formatDate(...)}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  ),
),
```

---

## Implementation Order

1. **Feed Card Changes**
   - Add quick action buttons row
   - Enhance price badge with icon and gradient
   - Add route icons (origin/destination)
   - Color-code meta chips

2. **Detail Screen Changes**
   - Enhance hero card with gradient
   - Add supplier contact block with action buttons
   - Add icons to section headers
   - Enhance price summary display

---

## Files to Modify

| File | Changes |
|------|---------|
| `trucker_find_loads_screen.dart` | Feed card visual updates |
| `trucker_load_detail_sections.dart` | Detail screen visual updates |
| `content_cards.dart` | Optional: Add icon support to `DetailSectionCard` |

---

## Dependencies

- No new dependencies required
- Uses existing `url_launcher` for phone calls (if already in pubspec)
- Uses existing chat repository for chat functionality

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Card height increase | Use `SingleChildScrollView` if needed |
| Performance impact | Minimal - only visual changes |
| Localization | All new text uses existing l10n patterns |
