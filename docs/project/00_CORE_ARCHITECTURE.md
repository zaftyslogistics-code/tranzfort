# 00: Core Architecture & System Spine

**Status:** LOCKED  
**Audience:** All Developers (Junior to Lead)  
**Objective:** Define the non-negotiable rules for how code is structured, how state is managed, how errors are handled, and how external services interact in TranZfort V1.

---

## 1. Product Identity

TranZfort is a **load-matching marketplace for the Indian trucking market**. It connects suppliers who have cargo with verified truckers who have trucks.

TranZfort is **NOT** a navigation app, **NOT** an AI assistant, and **NOT** an offline-first platform. It is a **connected marketplace with contextual road intelligence and Hindi voice accessibility**.

### Revenue Model
- The platform is free for both Suppliers and Truckers.
- Revenue: **5% commission on Super Loads** — premium loads where TranZfort guarantees trucker payment.

### The V1 Core Loop (Everything serves this)
```
Supplier posts load
  → Trucker finds load (with trip cost estimate)
    → Trucker books load (GPS captured)
      → Supplier approves booking
        → Trucker starts trip (GPS captured)
          → Trucker delivers + uploads POD
            → Supplier confirms delivery
              → Trip complete (rating + feedback)
```

---

## 2. The 4-Layer System Spine

Every feature must strictly follow this 4-layer unidirectional data flow. **No layer is allowed to skip the layer directly below it.**

```
┌──────────────────────────────────────────────────┐
│  Layer 4: UI / Presentation                      │
│  Renders state. Dispatches intents. Dumb.        │
│  ref.watch() for data, ref.read().notifier for   │
│  actions. NEVER imports supabase_flutter.         │
├──────────────────────────────────────────────────┤
│  Layer 3: State Provider (Riverpod)              │
│  Holds isLoading, isSubmitting, lastError.       │
│  Consumes Repository. Exposes Intent methods.    │
│  Owns realtime subscriptions. No setState().     │
├──────────────────────────────────────────────────┤
│  Layer 2: Repository                             │
│  Fetches data from Supabase. Maps JSON to Dart   │
│  models. Catches raw exceptions. Returns         │
│  Result<T> (Success or Failure). NEVER leaks     │
│  PostgrestException, SocketException, etc.       │
├──────────────────────────────────────────────────┤
│  Layer 1: Database (Supabase)                    │
│  Absolute source of truth. RLS enforces access.  │
│  RPCs handle atomic operations. Edge Functions   │
│  handle push notifications + admin ops.          │
└──────────────────────────────────────────────────┘
```

### Layer Rules (Violation = PR Reject)

| Rule | Description |
|------|-------------|
| UI cannot import `supabase_flutter` | All DB access goes through Repository |
| UI cannot use `setState()` for network calls | All async state lives in Provider |
| Repository must return `Result<T>` | No raw exceptions leak to Provider |
| Provider owns all async mutations | No `Future` chains in widgets |
| Provider owns Realtime subscriptions | No channel subscribe/unsubscribe in widgets |
| No `e.toString()` in UI | All errors mapped via `AppFailureType` |

---

## 3. Project Directory Structure

We use a **Feature-First** architecture. Two Flutter projects exist: the **User App** and the **Admin App**.

### User App (`TranZfort/`)
```text
lib/
├── main.dart                          # App entry, Supabase init, ProviderScope
├── src/
│   ├── core/                          # Shared spine (Used by ALL features)
│   │   ├── config/
│   │   │   └── supabase_config.dart   # Supabase URL, anon key, --dart-define vars
│   │   ├── error/
│   │   │   ├── app_failure.dart       # AppFailureType enum + classifyError()
│   │   │   └── result.dart            # Result<T> = Success<T> | Failure
│   │   ├── models/
│   │   │   ├── profile.dart           # Profile (id, role, mobile, name, avatar)
│   │   │   ├── load.dart              # Load (route, material, price, bulk fields)
│   │   │   ├── truck.dart             # Truck (number, model, body_type, status)
│   │   │   ├── trip.dart              # Trip (stage, lr, pod, timestamps)
│   │   │   ├── conversation.dart      # Conversation (load_id, supplier_id, trucker_id)
│   │   │   └── message.dart           # Message (type, content, sender_id)
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart   # Google sign-in, OTP, profile CRUD
│   │   │   ├── load_repository.dart   # Post/edit/find/book loads, RPCs
│   │   │   ├── truck_repository.dart  # Fleet CRUD, truck_models catalog
│   │   │   ├── trip_repository.dart   # Stage transitions, document uploads
│   │   │   ├── chat_repository.dart   # Conversations, messages, realtime
│   │   │   ├── notification_repository.dart  # In-app notifications CRUD
│   │   │   └── support_repository.dart       # Tickets, messages
│   │   ├── routing/
│   │   │   └── app_router.dart        # GoRouter config, redirect guards
│   │   ├── services/
│   │   │   ├── storage_service.dart   # Supabase Storage upload/download
│   │   │   ├── trip_costing_service.dart  # Diesel + toll estimation
│   │   │   ├── location_service.dart  # Geolocator wrapper (4 bounded triggers)
│   │   │   └── tts_service.dart       # flutter_tts wrapper for screen reading
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # All Hex codes (see 01_DESIGN_SYSTEM)
│   │   │   ├── app_typography.dart    # TextStyles
│   │   │   └── app_theme.dart         # ThemeData composition
│   │   └── utils/
│   │       ├── formatters.dart        # Currency (₹), date, phone formatters
│   │       ├── validators.dart        # Phone, PAN, Aadhaar, truck number
│   │       └── constants.dart         # API URLs, bucket names, enums
│   │
│   ├── shared/                        # Reusable UI (Used across features)
│   │   └── widgets/
│   │       ├── primary_button.dart
│   │       ├── outline_button.dart
│   │       ├── status_badge.dart
│   │       ├── rich_load_card.dart
│   │       ├── empty_state_view.dart
│   │       ├── connectivity_banner.dart
│   │       ├── loading_overlay.dart
│   │       └── lifecycle_timeline.dart   # Visual stage progress bar
│   │
│   └── features/
│       ├── auth/
│       │   ├── providers/
│       │   │   ├── auth_session_provider.dart
│       │   │   ├── auth_entry_provider.dart
│       │   │   ├── auth_otp_provider.dart
│       │   │   └── auth_role_provider.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── splash_screen.dart
│       │       │   ├── auth_continue_screen.dart
│       │       │   ├── otp_verification_screen.dart
│       │       │   ├── phone_capture_screen.dart
│       │       │   └── role_selection_screen.dart
│       │       └── widgets/
│       │           └── google_sign_in_button.dart
│       │
│       ├── supplier/
│       │   ├── providers/
│       │   │   ├── post_load_provider.dart
│       │   │   ├── my_loads_provider.dart
│       │   │   ├── load_detail_provider.dart
│       │   │   ├── booking_action_provider.dart
│       │   │   ├── super_load_provider.dart
│       │   │   ├── supplier_dashboard_provider.dart
│       │   │   └── supplier_verification_provider.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── supplier_dashboard_screen.dart
│       │       │   ├── post_load_screen.dart
│       │       │   ├── my_loads_screen.dart
│       │       │   ├── load_detail_screen.dart
│       │       │   ├── booking_request_screen.dart
│       │       │   ├── super_load_request_screen.dart
│       │       │   ├── super_dashboard_screen.dart
│       │       │   ├── supplier_verification_screen.dart
│       │       │   ├── supplier_profile_screen.dart
│       │       │   └── payout_profile_screen.dart
│       │       └── widgets/
│       │           ├── load_form_step_1.dart
│       │           ├── load_form_step_2.dart
│       │           ├── load_form_step_3.dart
│       │           ├── load_form_step_4.dart
│       │           └── bulk_progress_card.dart
│       │
│       ├── trucker/
│       │   ├── providers/
│       │   │   ├── find_loads_provider.dart
│       │   │   ├── fleet_provider.dart
│       │   │   ├── add_truck_provider.dart
│       │   │   ├── truck_catalog_provider.dart
│       │   │   ├── my_trips_provider.dart
│       │   │   ├── trip_action_provider.dart
│       │   │   ├── trucker_dashboard_provider.dart
│       │   │   └── trucker_verification_provider.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── trucker_dashboard_screen.dart
│       │       │   ├── find_loads_screen.dart
│       │       │   ├── my_fleet_screen.dart
│       │       │   ├── add_truck_screen.dart
│       │       │   ├── my_trips_screen.dart
│       │       │   ├── trip_transit_screen.dart
│       │       │   ├── trucker_verification_screen.dart
│       │       │   └── trucker_profile_screen.dart
│       │       └── widgets/
│       │           ├── filter_sheet.dart
│       │           ├── truck_selection_sheet.dart
│       │           └── trip_stage_cta.dart
│       │
│       ├── chat/
│       │   ├── providers/
│       │   │   ├── chat_inbox_provider.dart
│       │   │   ├── chat_conversation_provider.dart
│       │   │   └── chat_typing_provider.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── chat_list_screen.dart
│       │       │   └── chat_screen.dart
│       │       └── widgets/
│       │           ├── message_bubble.dart
│       │           ├── voice_recorder.dart
│       │           ├── map_message_card.dart
│       │           └── load_context_header.dart
│       │
│       ├── bot/
│       │   ├── providers/
│       │   │   └── bot_runtime_provider.dart
│       │   ├── services/
│       │   │   ├── bot_engine.dart         # Conversation state machine
│       │   │   ├── intent_detector.dart    # Pattern matching, keyword extraction
│       │   │   ├── slot_schema.dart        # Slot definitions per intent
│       │   │   ├── slot_validator.dart     # Type checking, fuzzy matching
│       │   │   └── response_templates.dart # All localized bot text
│       │   └── presentation/
│       │       ├── screens/
│       │       │   └── bot_chat_screen.dart
│       │       └── widgets/
│       │           └── quick_action_chips.dart
│       │
│       ├── notifications/
│       │   ├── providers/
│       │   │   └── notification_provider.dart
│       │   └── presentation/
│       │       └── screens/
│       │           └── notifications_screen.dart
│       │
│       └── support/
│           ├── providers/
│           │   └── support_provider.dart
│           └── presentation/
│               └── screens/
│                   ├── help_support_screen.dart
│                   ├── my_tickets_screen.dart
│                   └── ticket_detail_screen.dart
```

### Admin App (`Admin/`)
```text
lib/
├── main.dart
├── src/
│   ├── core/
│   │   ├── config/             # Supabase config (same project, service_role key)
│   │   ├── routing/            # Admin GoRouter
│   │   ├── theme/              # Admin theme (same design system)
│   │   └── models/             # Shared models (can import from shared package)
│   └── features/
│       ├── auth/               # Email/password login
│       ├── dashboard/          # KPI cards, live feed
│       ├── verification/       # Supplier/Trucker/Truck queues
│       ├── users/              # User list, detail, ban/unban
│       ├── super_ops/          # 4-tab console, dispatch, post-on-behalf
│       └── support/            # Ticket queue, reply, resolve
```

---

## 4. File Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Screen | `snake_case_screen.dart` | `find_loads_screen.dart` |
| Widget | `snake_case.dart` | `rich_load_card.dart` |
| Provider | `snake_case_provider.dart` | `find_loads_provider.dart` |
| Repository | `snake_case_repository.dart` | `load_repository.dart` |
| Model (Freezed) | `snake_case.dart` | `load.dart` |
| Service | `snake_case_service.dart` | `trip_costing_service.dart` |

### Class Naming
- Screens: `FindLoadsScreen` (suffix `Screen`)
- Providers: `FindLoadsNotifier` (suffix `Notifier`), registered as `findLoadsProvider`
- Repositories: `LoadRepository` (suffix `Repository`)
- Models: `Load`, `Trip`, `Truck` (no suffix)

---

## 5. Error Handling Taxonomy

Raw backend errors (e.g., `PostgrestException 42501`) must never reach users.

### The `AppFailureType` Enum
```dart
enum AppFailureType {
  network,     // No internet, timeout
  auth,        // Session expired, invalid token
  validation,  // Invalid input (phone, PAN, etc.)
  conflict,    // Duplicate mobile, already booked
  notFound,    // Resource deleted or doesn't exist
  forbidden,   // RLS denied, banned user
  serverError, // 500, unexpected backend crash
  unknown,     // Catch-all
}
```

### User-Facing Messages (Localized)
| Type | English | Hindi |
|------|---------|-------|
| `network` | "Please check your internet connection." | "Kripya apna internet connection check karein." |
| `auth` | "Your session expired. Please sign in again." | "Aapka session khatam ho gaya. Phir se login karein." |
| `validation` | "Please check the highlighted fields." | "Kripya highlighted fields check karein." |
| `conflict` | "This number is linked to a Google account." | "Yeh number ek Google account se juda hai." |
| `notFound` | "This item is no longer available." | "Yeh item ab uplabdh nahi hai." |
| `forbidden` | "You don't have permission for this action." | "Aapko is action ki anumati nahi hai." |
| `serverError` | "Something went wrong. We're looking into it." | "Kuch galat ho gaya. Hum ise dekh rahe hain." |
| `unknown` | "Something went wrong. Please try again." | "Kuch galat ho gaya. Phir se koshish karein." |

### The `Result<T>` Pattern
```dart
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}
class Failure<T> extends Result<T> {
  final AppFailureType type;
  final String? debugMessage; // For logging only, NEVER shown to user
  const Failure(this.type, {this.debugMessage});
}
```

### The `classifyError()` Function (Used in EVERY Repository)
```dart
AppFailureType classifyError(Object error) {
  if (error is SocketException || error is TimeoutException) {
    return AppFailureType.network;
  }
  if (error is AuthException) {
    return AppFailureType.auth;
  }
  if (error is PostgrestException) {
    if (error.code == '23505') return AppFailureType.conflict;  // UNIQUE violation
    if (error.code == '42501') return AppFailureType.forbidden;  // RLS denied
    if (error.code == 'PGRST116') return AppFailureType.notFound;
    return AppFailureType.serverError;
  }
  return AppFailureType.unknown;
}
```

---

## 6. State Management Rules (Riverpod)

### Rule 1: No Parallel Boolean Flags in Widgets
```dart
// ❌ FORBIDDEN — widget-owned network state
class _MyScreenState extends State<MyScreen> {
  bool _isLoading = false;
  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await repo.submit();
    setState(() => _isLoading = false);
  }
}

// ✅ CORRECT — provider-owned network state
class MyNotifier extends _$MyNotifier {
  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true);
    final result = await ref.read(myRepoProvider).submit();
    state = state.copyWith(isSubmitting: false);
  }
}
// Widget just reads: final isSubmitting = ref.watch(myProvider).isSubmitting;
```

### Rule 2: One Domain = One Owner Provider
| Domain | Owner Provider | Owns |
|--------|---------------|------|
| Auth Session | `authSessionProvider` | Current user, sign-out |
| Auth Entry | `authEntryProvider` | Google/OTP loading states |
| Supplier My Loads | `myLoadsProvider` | Load list, deactivate |
| Trucker Find Loads | `findLoadsProvider` | Search, pagination, filters |
| Trucker My Trips | `myTripsProvider` | Trip list, refresh |
| Chat Inbox | `chatInboxProvider` | Conversation list, archive, realtime |
| Chat Detail | `chatConversationProvider(id)` | Messages, send, realtime stream |

### Rule 3: Realtime Subscriptions Are Provider-Owned
```dart
// Provider subscribes to chat messages on build, unsubscribes on dispose
@riverpod
class ChatConversationNotifier extends _$ChatConversationNotifier {
  RealtimeChannel? _channel;

  @override
  ChatConversationState build(String conversationId) {
    _subscribeToMessages(conversationId);
    ref.onDispose(() => _channel?.unsubscribe());
    return ChatConversationState.initial();
  }
}
```

### Rule 4: GoRouter is a Singleton
- GoRouter is created once and NEVER recreated.
- Auth state changes trigger `router.refresh()` via a `Listenable`, not by rebuilding the router.
- Redirect closure uses `ref.read()` (not `ref.watch()`) to get current values dynamically.

---

## 7. External Services & Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                    MOBILE APPS                          │
│  ┌─────────────┐          ┌─────────────────┐          │
│  │  User App   │          │   Admin App     │          │
│  │  (Flutter)  │          │   (Flutter)     │          │
│  └──────┬──────┘          └────────┬────────┘          │
└─────────┼──────────────────────────┼────────────────────┘
          │                          │
          ▼                          ▼
┌─────────────────────────────────────────────────────────┐
│                 SUPABASE BACKEND                        │
│  PostgreSQL (RLS + RPCs + pg_cron)                      │
│  Auth (Google, Phone OTP, Email for Admin)              │
│  Realtime (Chat messages, Notifications, Typing)        │
│  Storage (Documents, RC photos, POD images, Voice)      │
│  Edge Functions:                                        │
│    • send-push-notification (FCM trigger)               │
│    • create-super-load (Super Load ops)                 │
│    • admin-promote-invite (Admin management)            │
│    • admin-load-ops (Manual load operations)            │
└─────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│               EXTERNAL SERVICES                         │
│  Google Places API — City autocomplete (supplier)       │
│  OSRM — Static route polyline (display only)            │
│  Fast2SMS — OTP delivery (phone verification)           │
│  FCM — Push notifications                               │
│  Google Maps — Deep links only (no SDK embed)           │
│  Diesel Price API — Optional enrichment (₹90/L default) │
│  Geolocator — GPS at 4 bounded moments only             │
└─────────────────────────────────────────────────────────┘
```

### GPS Philosophy (4 Bounded Triggers ONLY)
| Trigger | When | Purpose |
|---------|------|---------|
| Load acceptance | Trucker taps "Book Load" | Capture trucker location at booking |
| Trip start | Trucker taps "Start Trip" | Capture pickup location |
| Manual update | Trucker taps "Update My Location" | Mid-trip trust signal |
| App foreground | App comes to foreground (max once per 2h) | Background-free freshness |

**Rules:** No background service. No continuous stream. No geo-fencing. No auto state changes. All state changes are user-initiated. GPS unavailable = silently skip.

### Trip Cost Philosophy
- Offline defaults **ALWAYS** work: ₹90/litre diesel, 2.5 km/litre mileage.
- APIs may **ENRICH** but must **NEVER BLOCK**.
- If OSRM unavailable → Haversine straight-line distance fallback.
- If diesel price API unavailable → ₹90/L default.

---

## 8. V1 Explicit Exclusions (DO NOT BUILD)

| Exclusion | Reason |
|-----------|--------|
| Turn-by-turn navigation | Google Maps does this |
| Background GPS tracking | Battery, policy, surveillance risk |
| Auto state changes from GPS | No geo-fencing, no auto-arrival |
| On-device LLM (TinyLlama) | 600MB, freezes budget phones |
| On-device STT (Whisper) | 75MB, 5.2s latency, unreliable |
| On-device TTS (Kokoro) | Broken ONNX bug, platform TTS works |
| Offline mode | Marketplace requires internet |
| Admin-to-user chat | Tables don't exist; use WhatsApp/phone |
| Payment gateway / UPI | Commission collected offline via GST invoice |
| Dark mode | Light theme only in V1 |
| Saved places | Not part of marketplace loop |
| Real-time live tracking map | Requires background GPS |
| Email/password login | Google + Phone OTP only |
| AI Settings screen | Nothing to configure in V1 |

---

## 9. Required Packages (pubspec.yaml)

| Package | Purpose | Required? |
|---------|---------|-----------|
| `supabase_flutter` | Backend (DB, Auth, Storage, Realtime) | Yes |
| `flutter_riverpod` + `riverpod_annotation` | State management | Yes |
| `go_router` | Routing + redirect guards | Yes |
| `freezed_annotation` + `json_annotation` | Immutable models | Yes |
| `google_sign_in` | Google OAuth | Yes |
| `flutter_tts` | Platform TTS for screen reading | Yes |
| `geolocator` | GPS for bounded location updates | Yes |
| `record` | Voice message recording in chat | Yes |
| `just_audio` | Voice message playback in chat | Yes |
| `flutter_map` | Static route polyline display | Yes |
| `image_picker` | Camera/gallery for document uploads | Yes |
| `intl` | Date/currency formatting + l10n | Yes |
| `flutter_local_notifications` | Local notification display | Yes |
| `firebase_messaging` | FCM push notifications | Yes |
| `speech_to_text` | Platform STT for bot (deferred) | Optional |

---

## 10. PR Review Gates (Definition of Done)

Before merging any code, every PR must pass:

| Gate | Check | Tool |
|------|-------|------|
| Layer Integrity | No `supabase_flutter` import in `/presentation/` | `check_layer_boundaries.py` |
| Truth Integrity | Feature uses documented Repository + Provider | Manual review |
| UI Integrity | No `e.toString()` visible to user | Manual review |
| Error Mapping | All errors classified via `AppFailureType` | Manual review |
| Linter | Zero errors | `flutter analyze` |
| Tests | All tests pass | `flutter test` |
| Formatting | Code formatted | `dart format .` |
| No Hardcoded Strings | User-facing text in `.arb` files (Tier A screens) | Manual review |

---

## 11. Localization (l10n) Strategy

- **ARB files:** `app_en.arb` (English) and `app_hi.arb` (Hindi).
- **Tier A screens (Must localize for V1):** Auth, Dashboard, Post Load, Find Loads, Load Detail, Booking, My Trips, Trip Transit, Chat.
- **Tier B screens (Post-launch):** Settings, Help, Notifications, Verification, Fleet, Bot.
- **TTS Rule:** All text passed to `flutter_tts` must be stripped of emojis. Use a `.ttsText` getter on localized strings.
- **Bot Strings:** All bot response templates are localized via `response_templates.dart` with hardcoded fallbacks via `_p()` / `_pc()` pattern.
