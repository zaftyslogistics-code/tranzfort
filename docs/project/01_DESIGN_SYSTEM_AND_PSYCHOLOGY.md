# 01: Design System, UI/UX & User Psychology

**Status:** LOCKED  
**Audience:** All Developers, UI Designers  
**Objective:** Define every visual rule, widget specification, screen layout convention, and psychological principle for TranZfort V1. A junior developer should be able to build pixel-consistent screens using only this document.

---

## 1. User Psychology (The Two Personas)

TranZfort serves two distinct users. Every UI decision must respect their psychological needs, technical literacy, and working conditions.

### 1.1 The Supplier (The Dispatcher / Factory Manager)
- **Profile:** 30-50 years old. Office or site-based. Uses the app on a mid-range phone. Literate in English and Hindi.
- **Goal:** Efficiency, tracking, and reliability. They are managing 50 trucks at once for the same route.
- **Tone:** Professional, data-rich, and dashboard-oriented.
- **UI Needs:**
  - Grouped lists (Bulk loads showing `12/50 booked`).
  - Clear statuses (Pending / In Transit / Delivered) with color-coded badges.
  - Batch actions — they do NOT want to see 50 individual chat threads for the same route.
  - Quick access to "Post Load" — the primary revenue action.
- **Language:** English-first. Professional terms: "Fulfillment", "Advance", "POD", "Booking Request".
- **Trust Signals:** Verified Trucker badges, Truck RC photo, Rating stars.
- **Frustration Points:** Not knowing if a trucker is on the way. Not knowing how many trucks have been booked out of 50.

### 1.2 The Trucker (The Driver / Fleet Owner)
- **Profile:** 25-45 years old. On the road, often at a dhaba or truck stop. Uses a budget phone (₹8,000-15,000, 32GB storage, 3-4GB RAM). Semi-literate in Hindi, may struggle with English.
- **Goal:** Profitability, quick decisions, and trust. They need to know in 3-5 seconds if a load is worth taking.
- **Tone:** Direct, scannable, and trust-building.
- **UI Needs:**
  - Big buttons (minimum 48x48 touch targets). They have thick fingers and may be tapping while moving.
  - Clear numbers: Total ₹, Diesel Cost Estimate ₹, Advance %.
  - High-contrast badges: `Verified Supplier` (blue), `Super Load` (gold).
  - Minimal typing. Voice notes in chat. Tap-to-select truck. One-tap booking.
- **Language:** Hinglish / Hindi-first. Terms: "Bhada" (freight), "Advance", "Gaadi" (truck/vehicle). Avoid complex jargon.
- **Trust Signals:** Super Load badge (guaranteed payment), Verified Supplier badge, Trip Cost Estimate (transparency).
- **Frustration Points:** Hidden costs. Not knowing if the load is profitable. Complicated forms.

### 1.3 The Admin (The Operations Team)
- **Profile:** TranZfort internal staff. Desktop or tablet use. English-only.
- **Goal:** Speed and accuracy. Process verification queues, dispatch Super Loads, resolve tickets.
- **UI Needs:** Dense data tables. Batch actions. SLA indicators (amber/red for overdue items). Quick search.

---

## 2. Color Palette (The Hex Codes)

**RULE:** Never use raw hex codes in widgets. Always use `AppColors.primary`, `AppColors.success`, etc. from `lib/src/core/theme/app_colors.dart`.

### 2.1 Brand Colors
| Name | Hex | Dart | Usage |
|------|-----|------|-------|
| **Primary** | `#1E3A8A` | `Color(0xFF1E3A8A)` | AppBars, primary CTAs (Supplier side), brand identity, links |
| **Primary Light** | `#3B82F6` | `Color(0xFF3B82F6)` | Hover states, selected tabs, active filters |
| **Secondary / Amber** | `#F59E0B` | `Color(0xFFF59E0B)` | Super Load badges, urgency indicators, "Make Super" CTA |
| **Surface** | `#FFFFFF` | `Color(0xFFFFFFFF)` | Card backgrounds, input fields, bottom sheets |
| **Background** | `#F3F4F6` | `Color(0xFFF3F4F6)` | Scaffold background (makes white cards pop) |
| **On Surface** | `#111827` | `Color(0xFF111827)` | Primary text on white/light backgrounds |

### 2.2 Status Colors
| Name | Hex | Dart | Usage |
|------|-----|------|-------|
| **Success / Green** | `#10B981` | `Color(0xFF10B981)` | "Delivered", "Approved", "Verified", Trucker "Book Load" button |
| **Warning / Orange** | `#F59E0B` | `Color(0xFFF59E0B)` | "Pending", "In Transit", missing profile data banners |
| **Error / Red** | `#EF4444` | `Color(0xFFEF4444)` | "Rejected", "Failed", destructive actions (Delete Truck, Reject Booking) |
| **Neutral / Gray** | `#6B7280` | `Color(0xFF6B7280)` | Secondary text, disabled buttons, "Draft" status |
| **Neutral Light** | `#D1D5DB` | `Color(0xFFD1D5DB)` | Dividers, borders, disabled input fields |

### 2.3 Special Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Super Gold** | `#F59E0B` on `#FEF3C7` background | Super Load badge (gold text on light yellow pill) |
| **Verified Blue** | `#3B82F6` on `#EFF6FF` background | Verified Supplier/Trucker badge |
| **Chat Sender** | `#DCFCE7` (light green) | Current user's message bubble background |
| **Chat Receiver** | `#FFFFFF` (white) | Other user's message bubble background |

---

## 3. Typography

**Font Family:** `Inter` — Clean, modern, highly legible on cheap Android screens with low pixel density.

| Style Name | Size | Weight | Usage |
|------------|------|--------|-------|
| `headlineLarge` | 28sp | Bold (700) | Screen titles (e.g., "Find Loads", "My Trips") |
| `headlineMedium` | 24sp | Bold (700) | Section headers, Load Prices (e.g., **₹62,500**) |
| `titleLarge` | 20sp | SemiBold (600) | Card titles, Trucker/Supplier names |
| `titleMedium` | 16sp | SemiBold (600) | Subtitles, form section labels |
| `bodyLarge` | 16sp | Regular (400) | Primary body text, descriptions |
| `bodyMedium` | 14sp | Regular (400) | Secondary body text, dates, material names |
| `bodySmall` | 12sp | Regular (400) | Captions, timestamps, "Posted 2h ago" |
| `labelLarge` | 14sp | Medium (500) | Button text |
| `labelSmall` | 11sp | Medium (500), uppercase, letterSpacing 1.2 | Badges: `VERIFIED`, `SUPER LOAD`, `PENDING` |

---

## 4. Spacing (The 8pt Grid System)

All padding and margins MUST be multiples of 8. No exceptions.

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4.0 | Icon-to-text gap inside badges |
| `sm` | 8.0 | Tight internal padding (inside chips, between badge items) |
| `md` | 16.0 | Standard card internal padding, gap between list items |
| `lg` | 24.0 | Screen edge horizontal padding, section gaps |
| `xl` | 32.0 | Top padding on main screens, large section separators |
| `xxl` | 48.0 | Splash screen logo top margin |

### Card Elevation & Radius
- **Card elevation:** `2.0` (subtle shadow on `Background` scaffold).
- **Card border radius:** `12.0` (all cards).
- **Button border radius:** `12.0`.
- **Input field border radius:** `8.0`.
- **Badge/Chip border radius:** `20.0` (fully rounded pill).

---

## 5. Standard UI Components (The Widget Toolkit)

All shared widgets live in `lib/src/shared/widgets/`. **Do NOT build custom buttons or cards from scratch.**

### 5.1 `PrimaryButton`
- **Width:** Full width (`double.infinity`).
- **Height:** 52.0 logical pixels.
- **Color:** `AppColors.primary` (default) or `AppColors.success` (for "Book Load").
- **Text:** `labelLarge`, white, centered.
- **Border Radius:** 12.0.
- **Loading State:** When `isLoading: true`, text is replaced by a white `CircularProgressIndicator(strokeWidth: 2.5)`. Button is disabled (opacity 0.6).
- **Disabled State:** Opacity 0.4, ignores taps.

### 5.2 `OutlineButton`
- **Width:** Full width.
- **Height:** 52.0.
- **Color:** Transparent background, `AppColors.primary` border (1.5px).
- **Text:** `labelLarge`, `AppColors.primary`.
- **Usage:** Secondary actions: "Chat with Supplier", "Edit Load", "View Profile".

### 5.3 `DestructiveButton`
- Same as `PrimaryButton` but `AppColors.error` background.
- **Usage:** "Delete Truck", "Reject Booking", "Deactivate Load".

### 5.4 `StatusBadge`
- **Shape:** Pill (borderRadius 20.0).
- **Padding:** `EdgeInsets.symmetric(horizontal: 12, vertical: 4)`.
- **Text:** `labelSmall`, uppercase.
- **Color mapping (auto from enum):**

| Status | Background | Text Color | Icon |
|--------|-----------|------------|------|
| `draft` | `#F3F4F6` | `#6B7280` | `Icons.edit_outlined` |
| `active` | `#EFF6FF` | `#3B82F6` | `Icons.circle` (filled) |
| `pending_approval` | `#FEF3C7` | `#D97706` | `Icons.hourglass_top` |
| `assigned` | `#DCFCE7` | `#16A34A` | `Icons.check_circle` |
| `in_transit` | `#FEF3C7` | `#D97706` | `Icons.local_shipping` |
| `delivered` | `#DCFCE7` | `#16A34A` | `Icons.inventory` |
| `completed` | `#DCFCE7` | `#16A34A` | `Icons.done_all` |
| `rejected` | `#FEE2E2` | `#DC2626` | `Icons.cancel` |
| `cancelled` | `#F3F4F6` | `#6B7280` | `Icons.block` |

### 5.5 `RichLoadCard` (The Masterpiece)
See `05_MARKETPLACE_AND_BULK.md` Section 2.2 for the full data hierarchy. Summary:
- **Height:** Dynamic (content-driven), approximately 280-320px.
- **Sections (top to bottom):**
  1. Badges Row: Super Load (gold pill), Verified Supplier (blue pill), TimeAgo (right-aligned, gray).
  2. Route Block: Green dot → Origin. Red dot → Destination. Distance in center. Faded polyline graphic on right.
  3. Cargo Block: Material icon + name, Weight, Vehicle type + tyres, Pickup date.
  4. Financial Block: Rate, Total Value (bold, large), Advance %, Estimated Trip Cost (USP).
  5. Action Row: `OutlineButton("Chat")` left, `PrimaryButton("Book Load", color: success)` right.

### 5.6 `EmptyStateView`
- **Layout:** Centered column: Icon (64x64, gray), Title (`titleLarge`), Subtitle (`bodyMedium`, gray), optional CTA button.
- **Usage:** Empty lists (no loads found, no trips, no trucks, no tickets).
- **Example text:** "No loads match your filters. Try changing your search criteria."

### 5.7 `ConnectivityBanner`
- **Position:** Top of scaffold, below AppBar.
- **Color:** `AppColors.error` background, white text.
- **Text:** "No internet connection" / "Internet nahi hai".
- **Behavior:** Appears when connectivity is lost. Disappears when restored. Disables all action CTAs while visible.

### 5.8 `LifecycleTimeline`
- **Usage:** Visual step indicator for trip progress and load lifecycle.
- **Layout:** Horizontal row of circles connected by lines. Completed steps are `AppColors.success` (filled). Current step is `AppColors.warning` (pulsing). Future steps are `AppColors.neutralLight`.
- **Labels below circles:** `Booked → Pickup → In Transit → Delivered → Completed`.

---

## 6. Screen Layout Conventions

### 6.1 AppBar Rules
| Screen Type | AppBar Style |
|-------------|-------------|
| Top-level (Dashboard, Find Loads, My Trips, Messages) | `title` = Screen name. `leading` = Drawer icon or back. `actions` = notification bell + profile avatar. |
| Detail (Load Detail, Chat, Trip Transit) | `title` = Context (e.g., "Coal: Chandrapur → Mumbai"). `leading` = back arrow. |
| Form (Post Load, Add Truck, Verification) | `title` = Form name. `leading` = back arrow with "Discard changes?" confirmation. |
| Auth (Splash, Continue, OTP, Role) | No AppBar. Full-screen immersive layout. |

### 6.2 Bottom Navigation Bar

#### Supplier Bottom Nav (4 tabs)
| Tab | Icon | Label | Route |
|-----|------|-------|-------|
| Home | `Icons.home_outlined` / `Icons.home` | Home | `/supplier-dashboard` |
| My Loads | `Icons.inventory_2_outlined` / filled | My Loads | `/my-loads` |
| Super | `Icons.star_outline` / filled | Super | `/supplier/super-dashboard` |
| Messages | `Icons.chat_bubble_outline` / filled | Messages | `/messages` |

#### Trucker Bottom Nav (4 tabs)
| Tab | Icon | Label | Route |
|-----|------|-------|-------|
| Find Loads | `Icons.search` / filled | Find Loads | `/find-loads` |
| My Trips | `Icons.route_outlined` / filled | My Trips | `/my-trips` |
| Fleet | `Icons.local_shipping_outlined` / filled | Fleet | `/my-fleet` |
| Messages | `Icons.chat_bubble_outline` / filled | Messages | `/messages` |

**Note:** Trucker's primary home screen is `/find-loads`, NOT `/trucker-dashboard`. The dashboard is a secondary destination accessible from the profile/settings drawer.

### 6.3 Floating Action Button (FAB)
- **Supplier Dashboard:** FAB = "Post Load" (Primary color, `Icons.add`).
- **Trucker Dashboard:** FAB = "Bot Chat" (Secondary/Amber color, `Icons.smart_toy`).
- **All other screens:** No FAB.

### 6.4 Drawer / Settings
Accessed via the profile avatar in the AppBar or a hamburger menu.
- **Items:** Profile, Settings, Language, Help & Support, About, Sign Out.
- **Settings screen (`/settings`):** Language toggle (EN/HI), Voice toggle (TTS on/off), About, Support link.
- **No AI Settings screen in V1.**

---

## 7. Screen-by-Screen Layout Reference (User App)

### 7.1 Splash Screen (`/splash`)
```
┌────────────────────────────────────┐
│          (no AppBar)               │
│                                    │
│                                    │
│         [App Logo - 120x120]       │
│                                    │
│          "TranZfort"               │
│    (headlineLarge, primary)        │
│                                    │
│   [CircularProgressIndicator]      │
│                                    │
│                                    │
└────────────────────────────────────┘
```
- **TTS:** On first app open (not returning user), speak: "Namaste, TranZfort mein aapka swagat hai."
- **Logic:** Check auth session → redirect via Profile Completeness Gate.

### 7.2 Auth Continue Screen (`/auth`)
```
┌────────────────────────────────────┐
│          (no AppBar)               │
│                                    │
│         [App Logo - 80x80]         │
│                                    │
│     "Namaste! Welcome to"          │
│         "TranZfort"                │
│    (headlineMedium, center)        │
│                                    │
│  [G] Continue with Google          │
│  (PrimaryButton, full width,       │
│   Google logo asset on left)       │
│                                    │
│  [📱] Continue with Phone          │
│  (OutlineButton, full width)       │
│                                    │
│  "By continuing, you agree to"     │
│  "our Terms of Service"            │
│  (bodySmall, gray, tappable link)  │
│                                    │
└────────────────────────────────────┘
```
- **TTS:** Auto-speak: "Google se continue karein ya phone number se."

### 7.3 Supplier Dashboard (`/supplier-dashboard`)
```
┌────────────────────────────────────┐
│ [≡] Supplier Dashboard    [🔔][👤]│
├────────────────────────────────────┤
│ ┌──────────┐ ┌──────────┐         │
│ │Active    │ │Pending   │         │
│ │Loads: 5  │ │Bookings:3│         │
│ └──────────┘ └──────────┘         │
│ ┌──────────┐ ┌──────────┐         │
│ │In Transit│ │Completed │         │
│ │Trips: 2  │ │Trips: 47 │         │
│ └──────────┘ └──────────┘         │
├────────────────────────────────────┤
│ ⚠ Verification Under Review       │
│ (yellow banner if pending)         │
├────────────────────────────────────┤
│ "Needs Your Action" (section)      │
│ [BookingRequestCard x3]           │
│  - Trucker name, truck, actions    │
├────────────────────────────────────┤
│ "Recent Loads" (section)           │
│ [LoadSummaryCard x5]              │
│  - Route, status badge, booked/N   │
├────────────────────────────────────┤
│ [Home] [My Loads] [Super] [Chat]   │
│         (Bottom Nav)               │
└────────────────────────────────────┘
  [+ Post Load] (FAB, bottom right)
```

### 7.4 Trucker Find Loads (`/find-loads`)
```
┌────────────────────────────────────┐
│ Find Loads              [🔔][👤]  │
├────────────────────────────────────┤
│ [Origin ▼]  [Destination ▼]       │
│ [Material ▼] [Truck Type ▼]       │
│ [🔍 Search]                        │
├────────────────────────────────────┤
│ "245 loads found"  [Sort: Newest ▼]│
├────────────────────────────────────┤
│ [RichLoadCard]                     │
│ [RichLoadCard]                     │
│ [RichLoadCard]                     │
│ ... (infinite scroll, 50/page)     │
│ [Loading spinner at bottom]        │
├────────────────────────────────────┤
│ [Find] [My Trips] [Fleet] [Chat]  │
│         (Bottom Nav)               │
└────────────────────────────────────┘
  [🤖 Bot] (FAB, amber, bottom right)
```
- **Empty State:** `EmptyStateView("No loads match your filters.")`
- **Filter Logic:** Changing any filter resets `currentPage = 1` and triggers a fresh search.

---

## 8. Tone & Text Guidelines

### 8.1 CTA Button Text (Action-Oriented)
| Bad | Good |
|-----|------|
| `Submit` | `Post Load` |
| `Okay` | `Approve Booking` |
| `Next` | `Upload RC` |
| `Send` | `Send Message` |
| `Confirm` | `Start Trip` |
| `Delete` | `Remove Truck` |

### 8.2 Empty State Messages
| Screen | Title | Subtitle |
|--------|-------|----------|
| Find Loads (no results) | "No loads found" | "Try changing your filters or check back later." |
| My Trips (empty) | "No active trips" | "Book a load from Find Loads to start your first trip." |
| My Fleet (empty) | "No trucks yet" | "Add your first truck to start booking loads." |
| My Loads (empty) | "No loads posted" | "Post your first load to find truckers." |
| Messages (empty) | "No conversations yet" | "Start chatting with a supplier or trucker." |
| Notifications (empty) | "All caught up!" | "You have no new notifications." |

### 8.3 Verification Banners (Dashboard)
| Status | Color | Text |
|--------|-------|------|
| `pending` | Warning (amber bg) | "Verification Under Review — We'll notify you when approved." |
| `approved` | Success (green bg, fades after 24h) | "Verified Account ✓" |
| `rejected` | Error (red bg, tappable) | "Verification Failed: [Reason]. Tap to re-upload." |
| Not submitted | Neutral (gray bg) | "Complete verification to start booking loads." |

---

## 9. TTS (Text-to-Speech) Rules

### 9.1 When TTS Auto-Speaks
| Screen | TTS Text (Hindi) | Condition |
|--------|------------------|-----------|
| Splash (first open) | "Namaste, TranZfort mein aapka swagat hai." | First app open only (SharedPreferences flag) |
| Auth Continue | "Google se continue karein ya phone number se." | Every visit |
| Role Selection | "Aap supplier hain ya trucker? Chunein." | Every visit |
| Dashboard (first visit) | "Namaste {name}, TranZfort mein aapka swagat hai." | First dashboard visit after login |

### 9.2 TTS Implementation Rules
1. **Strip emojis** before passing text to TTS. Use a `.ttsText` getter.
2. **Respect mute setting.** Check `SharedPreferences('tts_enabled')` before speaking.
3. **Never overlap.** Cancel any running TTS before starting a new one.
4. **Language:** Use `flutter_tts.setLanguage('hi-IN')` for Hindi, `'en-IN'` for English.

---

## 10. Accessibility & Touch Targets

1. **Minimum touch target:** 48x48 logical pixels for ALL tappable elements (buttons, icons, list tiles, chips).
2. **Contrast ratio:** All text must be readable on its background. No light gray text on white. Use `AppColors.onSurface` (#111827) for primary text.
3. **Font scaling:** Respect the user's system font size setting. Use `sp` units, not fixed `px`.
4. **Loading feedback:** Every async action must show immediate visual feedback (spinner, disabled button, or skeleton loading).
5. **Error feedback:** Every failed action must show a Snackbar with a user-friendly message from `AppFailureType`.
