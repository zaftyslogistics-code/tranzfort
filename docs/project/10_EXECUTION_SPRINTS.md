# 10: Execution Sprints (The Roadmap)

**Status:** LOCKED  
**Audience:** All Developers, AI Coding Agents  
**Objective:** Provide a foolproof, step-by-step implementation guide with exact file deliverables and test criteria per sprint. A junior developer should execute these sprints sequentially and produce a shippable V1.

---

## The Rule of Advancement

**DO NOT start a sprint until the Definition of Done (DoD) for the previous sprint is 100% complete and validated.** Skipping steps will cause architectural collapse.

**Validation per sprint:**
1. `flutter analyze` → 0 errors (info/warnings tolerated).
2. `python scripts/check_layer_boundaries.py` → PASS (no illegal imports).
3. All DoD criteria manually tested on a real device or emulator.

---

## Sprint 1: Project Setup & Core Spine

**Goal:** Establish the foundation. No UI work yet.
**Duration:** 2-3 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 1.1 | `flutter create tranzfort_v1` with package name `com.tranzfort.app` | 00 §1 |
| 1.2 | Add all dependencies to `pubspec.yaml` (see package list in 00 §7) | 00 §7 |
| 1.3 | Create folder structure: `lib/src/core/`, `lib/src/features/`, all sub-features | 00 §2 |
| 1.4 | Implement `ThemeData` with exact hex codes from design system | 01 §2 |
| 1.5 | Build `PrimaryButton`, `OutlineButton`, `StatusBadge`, `EmptyStateView` | 01 §5 |
| 1.6 | Create `AppFailureType` enum + `Result<T>` wrapper | 00 §4 |
| 1.7 | Setup `GoRouter` with `/splash` route and `ProviderScope` | 00 §3 |
| 1.8 | Create `SupabaseConfig` with default URL/anon key | 00 §6 |

### File Deliverables
```
lib/
  main.dart
  src/
    core/
      config/supabase_config.dart
      errors/app_failure_type.dart
      errors/result.dart
      router/app_router.dart
      theme/app_theme.dart
      theme/app_colors.dart
      theme/app_text_styles.dart
    shared/
      widgets/primary_button.dart
      widgets/outline_button.dart
      widgets/status_badge.dart
      widgets/empty_state_view.dart
    features/
      splash/
        presentation/splash_screen.dart
```

### DoD
- [ ] App compiles and runs.
- [ ] `/splash` shows the TranZfort logo centered on screen.
- [ ] `flutter analyze` → 0 errors.
- [ ] Theme colors match design system hex codes.
- [ ] `PrimaryButton` renders with correct height (48px), radius (12px), and color.

---

## Sprint 2: Supabase Schema & Auth Repository

**Goal:** Secure the database and establish the auth layer.
**Duration:** 3-4 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 2.1 | Execute ALL SQL migrations from `02_DATABASE_SCHEMA_AND_RLS.md` | 02 |
| 2.2 | Verify all RLS policies are active | 02 §RLS |
| 2.3 | Create `AuthRepository` (Google Sign-In, Phone OTP, Sign Out) | 03 §2-4 |
| 2.4 | Create `DatabaseService` (base Supabase CRUD methods) | 00 §3 |
| 2.5 | Create `authSessionProvider`, `userRoleProvider`, `userProfileProvider` | 03 §6 |
| 2.6 | Create `updated_at` triggers on all tables | 02 §Triggers |

### File Deliverables
```
supabase/
  migrations/
    (all .sql files executed)
lib/src/
  core/
    services/
      auth_repository.dart
      database_service.dart
    providers/
      auth_service_provider.dart
  features/
    auth/
      data/auth_repository_impl.dart
```

### DoD
- [ ] All migrations applied successfully (no SQL errors).
- [ ] `SELECT * FROM profiles` returns empty table with correct columns.
- [ ] Google Sign-In creates a session and inserts a `profiles` row.
- [ ] RLS prevents user A from reading user B's private data.
- [ ] `check_layer_boundaries.py` → PASS.

---

## Sprint 3: The Onboarding Funnel

**Goal:** New users are forced through phone + role selection. Returning users skip to dashboard.
**Duration:** 3-4 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 3.1 | Build Auth Screen (`/auth`) with Google + Phone buttons | 03 §2.1 |
| 3.2 | Build Phone Entry Screen (`/onboarding/phone`) | 03 §2.3 |
| 3.3 | Build OTP Verification Screen (`/onboarding/otp`) | 03 §2.4 |
| 3.4 | Build Role Selection Screen (`/onboarding/role`) | 03 §2.5 |
| 3.5 | Build Google Complete Registration Screen | 03 §2.2 |
| 3.6 | Implement Profile Completeness Gate in GoRouter redirect | 03 §3 |
| 3.7 | Implement BanCheckWrapper | 03 §5 |
| 3.8 | Implement Privacy Consent dialog | 03 §4 |
| 3.9 | Wire TTS on auth/role screens | 03 §TTS |

### File Deliverables
```
lib/src/features/
  auth/
    presentation/
      auth_screen.dart
      otp_verification_screen.dart
      google_complete_registration_screen.dart
    providers/
      auth_entry_provider.dart
      auth_otp_verification_provider.dart
      auth_google_complete_registration_provider.dart
  onboarding/
    presentation/
      phone_entry_screen.dart
      role_selection_screen.dart
    providers/
      onboarding_provider.dart
  shared/
    widgets/
      ban_check_wrapper.dart
      privacy_consent_dialog.dart
```

### DoD
- [ ] New Google user → forced to enter phone → OTP → select role → dashboard.
- [ ] Returning user → splash → dashboard (skips all onboarding).
- [ ] User without mobile → redirected to `/onboarding/phone`.
- [ ] User without role → redirected to `/onboarding/role`.
- [ ] Banned user → sees ban dialog → signed out.
- [ ] TTS speaks on auth screen (if not muted).

---

## Sprint 4: Verification & Fleet

**Goal:** Users can submit KYC documents. Truckers can add trucks.
**Duration:** 4-5 days.

### Tasks
| # | Task | Blueprint Ref | Status |
|---|------|--------------|--------|
| 4.1 | Create Supabase Storage buckets: `verification-docs`, `truck-photos`, `profile-photos` | 04 §2.3, §3.3 | ✅ |
| 4.2 | Build Supplier Verification Screen with all form fields | 04 §2 | ✅ |
| 4.3 | Build Trucker Verification Screen with all form fields | 04 §3 | ✅ |
| 4.4 | Build image picker + compressor utility (1200×1200, 85%) | 04 §2.4 | ✅ |
| 4.5 | Build My Fleet Screen (`/my-fleet`) | 04 §5.1 | ✅ |
| 4.6 | Build Add Truck Screen with Make/Model dropdowns from `truck_models` | 04 §5.2 | ✅ |
| 4.7 | Create `TruckModelService` with in-memory cache | 04 §5.6 | ✅ |
| 4.8 | Build Dashboard Banner (verification status) | 04 §4.2 | ✅ |
| 4.9 | Implement `loadExistingData()` for re-submission flow | 04 §4.4 | ✅ |
| 4.10 | Build Payout Profile Screen | 04 §6 | ✅ |
| 4.11 | Build Profile Screen (`/profile`) | 04 §7 | ✅ |

### File Deliverables
```
lib/src/features/
  verification/
    presentation/
      supplier_verification_screen.dart
      trucker_verification_screen.dart
    providers/
      supplier_verification_provider.dart
      trucker_verification_provider.dart
  fleet/
    presentation/
      my_fleet_screen.dart
      add_truck_screen.dart
    providers/
      fleet_provider.dart
      add_truck_provider.dart
      truck_catalog_provider.dart
    services/
      truck_model_service.dart
  payout/
    presentation/payout_profile_screen.dart
    providers/payout_profile_provider.dart
  profile/
    presentation/profile_screen.dart
    providers/user_profile_provider.dart
  shared/
    utils/image_compressor.dart
    widgets/dashboard_banner.dart
```

### DoD
- [x] Supplier submits Aadhaar + PAN + selfie → data appears in Supabase Storage + DB.
- [x] Trucker submits Aadhaar + PAN + DL + selfie → data in Storage + DB.
- [x] `verification_status` changes to `'pending'` after submission.
- [x] Re-opening form pre-fills previously submitted data.
- [x] Trucker adds truck via Make/Model dropdowns → auto-fills specs.
- [x] Manual entry fallback works when "not in list" toggled.
- [x] RC photo uploaded to `truck-photos/{truck_id}/rc.jpg`.
- [x] Dashboard shows correct verification banner per status.

---

## Sprint 5: The Marketplace

**Goal:** Suppliers post loads. Truckers find and browse them.
**Duration:** 4-5 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 5.1 | Build Post Load 4-step wizard | 05 §2 |
| 5.2 | Integrate Google Places Autocomplete for city search | 05 §2.1 |
| 5.3 | Build offline city JSON fallback | 08 §7 |
| 5.4 | Build Find Loads screen with filters + infinite scroll | 05 §3 |
| 5.5 | Build `RichLoadCard` widget (exact data hierarchy from 05 §4) | 05 §4 |
| 5.6 | Build My Loads screen (supplier) with Active/Completed tabs | 05 §6 |
| 5.7 | Build Load Detail screen (trucker view + supplier view) | 05 §5 |
| 5.8 | Implement truck match badges on load cards | 05 §3.3 |
| 5.9 | Implement `TripCostingService` for cost estimates on cards | 08 §3 |

### File Deliverables
```
lib/src/features/
  loads/
    presentation/
      post_load_screen.dart (4-step wizard)
      find_loads_screen.dart
      my_loads_screen.dart
      load_detail_screen.dart
    providers/
      post_load_provider.dart
      find_loads_search_provider.dart
      my_loads_provider.dart
      load_detail_provider.dart
    widgets/
      rich_load_card.dart
      city_autocomplete_field.dart
  shared/
    widgets/
      load_constants.dart
lib/src/core/
  services/
    trip_costing_service.dart
```

### DoD
- [ ] Supplier posts a load with all fields → appears in `loads` table.
- [ ] Trucker sees load in Find Loads feed.
- [ ] Filters work: changing origin/dest/material resets and re-fetches.
- [ ] `RichLoadCard` shows all data fields per §4 spec.
- [ ] Trip cost estimate appears on card (or "Trip cost unavailable" if no distance).
- [ ] My Loads shows progress bar `12/50 trucks booked`.
- [ ] Infinite scroll loads more pages correctly.

---

## Sprint 6: Booking Engine & Trips

**Goal:** The complete lifecycle from booking to trip completion.
**Duration:** 5-6 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 6.1 | Deploy `book_load` RPC to Supabase | 02 §RPCs, 06 §2.1 |
| 6.2 | Deploy `approve_booking` and `reject_booking` RPCs | 06 §2.2-2.3 |
| 6.3 | Build booking flow (truck selection bottom sheet) | 06 §7 (was 05 §7) |
| 6.4 | Build supplier approve/reject UI on Load Detail | 06 §2.2 |
| 6.5 | Build My Trips screen (trucker) | 06 §4 |
| 6.6 | Build Trip Detail screen per stage | 06 §3.1-3.5 |
| 6.7 | Implement stage transitions: Start Trip, Mark Delivered, Upload POD, Confirm | 06 §3 |
| 6.8 | Implement GPS bounded triggers at 4 moments | 06 §5 |
| 6.9 | Build LR/POD upload with camera | 06 §6 |
| 6.10 | Build rating flow (5-star + comment) | 06 §7 |
| 6.11 | Deploy `auto_complete_delivered_trips` pg_cron job | 02 §pg_cron |

### File Deliverables
```
lib/src/features/
  booking/
    providers/
      book_load_provider.dart
  trips/
    presentation/
      my_trips_screen.dart
      trip_detail_screen.dart
    providers/
      trucker_my_trips_provider.dart
      trip_detail_provider.dart
      trip_action_provider.dart
  rating/
    presentation/rating_widget.dart
    providers/rating_provider.dart
  shared/
    widgets/
      truck_selection_sheet.dart
lib/src/core/
  services/
    location_service.dart
```

### DoD
- [ ] Trucker books a load → `book_load` RPC succeeds → `trucks_booked` increments.
- [ ] Supplier approves → trip created with `stage = 'at_pickup'`.
- [ ] Supplier rejects → `trucks_booked` decrements, load returns to `'active'`.
- [ ] Trucker advances through all 4 stages to `'completed'`.
- [ ] POD photo uploaded to `load-documents/{load_id}/pod.jpg`.
- [ ] GPS captured at each trigger point (or gracefully skipped).
- [ ] Rating submitted after completion → trucker aggregate updates.
- [ ] Error states show correct messages (already booked, fully booked, etc.).

---

## Sprint 7: Chat & Bot

**Goal:** Real-time communication + voice bot.
**Duration:** 5-6 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 7.1 | Build Supplier Inbox (2-level grouped by load) | 07 §1.2 |
| 7.2 | Build Trucker Inbox (flat list) | 07 §1.3 |
| 7.3 | Build Chat Screen with all message types | 07 §2 |
| 7.4 | Implement Supabase Realtime subscriptions for messages | 07 §3 |
| 7.5 | Implement optimistic updates + read receipts | 07 §3.2-3.3 |
| 7.6 | Build voice message recording + playback | 07 §2.5 |
| 7.7 | Auto-send map_card on conversation creation | 07 §2.6 |
| 7.8 | Build in-chat approve/reject for supplier | 07 §4 |
| 7.9 | Build Bot Chat screen | 07 §5.2 |
| 7.10 | Implement rule-based `BasicBotService` with all intents | 07 §5.3 |
| 7.11 | Implement `EntityExtractor` with fuzzy matching | 07 §5.4 |
| 7.12 | Implement `BotSttService` (speech_to_text) | 07 §6.3 |
| 7.13 | Implement `BotTtsService` (flutter_tts) with emoji stripping | 07 §6.2 |

### File Deliverables
```
lib/src/features/
  chat/
    presentation/
      chat_list_screen.dart (inbox)
      chat_screen.dart (conversation)
    providers/
      chat_inbox_provider.dart
      chat_conversation_meta_provider.dart
      chat_messages_provider.dart
      chat_send_provider.dart
    widgets/
      message_bubble.dart
      voice_message_bubble.dart
      map_message_card.dart
  bot/
    presentation/
      bot_chat_screen.dart
    services/
      basic_bot_service.dart
      entity_extractor.dart
      bot_stt_service.dart
      bot_tts_service.dart
      conversation_state.dart
    models/
      bot_intent.dart
```

### DoD
- [ ] Supplier and trucker exchange real-time text messages.
- [ ] Supplier inbox groups conversations by load.
- [ ] map_card auto-sent on first conversation.
- [ ] Voice message records, uploads, and plays back.
- [ ] Read receipts show blue ticks.
- [ ] Bot responds to "load dhundho" with slot-filling flow.
- [ ] Bot navigates to Find Loads with pre-filled params.
- [ ] TTS speaks bot responses in Hindi.
- [ ] STT captures trucker's speech and sends as text.

---

## Sprint 8: Tooling & Polish

**Goal:** Route preview, notifications, settings, and final UX polish.
**Duration:** 3-4 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 8.1 | Build Route Preview screen with flutter_map + OSRM | 08 §2 |
| 8.2 | Implement OSRM polyline fetcher + Haversine fallback | 08 §2.3 |
| 8.3 | Build deep link to Google Maps | 08 §4 |
| 8.4 | Setup FCM + push token storage | 08 §5 |
| 8.5 | Build In-App Notifications screen | 08 §6 |
| 8.6 | Build Settings screen with TTS mute toggle | 08 §8 |
| 8.7 | Implement Delete Account flow | 08 §8.2 |
| 8.8 | Add notification badges on bottom nav tabs | 07 §7 |
| 8.9 | Wire all 14 push notification triggers | 08 §5.2 |
| 8.10 | Final `flutter analyze` cleanup | — |

### File Deliverables
```
lib/src/features/
  navigation/
    presentation/
      route_preview_screen.dart
    providers/
      route_preview_provider.dart
  notifications/
    presentation/
      notifications_screen.dart
    providers/
      notifications_provider.dart
      fcm_token_provider.dart
  settings/
    presentation/
      settings_screen.dart
    providers/
      settings_provider.dart
lib/src/core/
  services/
    osrm_service.dart
```

### DoD
- [ ] Route Preview shows polyline on flutter_map with origin/dest pins.
- [ ] Trip cost breakdown card shows diesel + tolls + total.
- [ ] "Open in Google Maps" launches external app with dest coords.
- [ ] Push notifications received for booking approved, new message, etc.
- [ ] In-app notification list shows history with deep links.
- [ ] Settings TTS toggle works — muting prevents all auto-speak.
- [ ] Delete Account sets `data_deletion_requested_at` and signs out.

---

## Sprint 9: The Admin App

**Goal:** Build the separate back-office control center.
**Duration:** 5-7 days.

### Tasks
| # | Task | Blueprint Ref |
|---|------|--------------|
| 9.1 | `flutter create tranzfort_admin` with package name `com.tranzfort.admin` | 09 §1 |
| 9.2 | Setup same Supabase connection | 09 §1.1 |
| 9.3 | Build Admin Login (email + password) | 09 §2 |
| 9.4 | Build Dashboard with KPI cards + SLA alerts | 09 §3 |
| 9.5 | Build Verification Queues (3 tabs) | 09 §4 |
| 9.6 | Build Verification Detail with image viewer + approve/reject | 09 §4.3 |
| 9.7 | Build User Management list + detail | 09 §5 |
| 9.8 | Build Ban/Unban flow | 09 §5.3 |
| 9.9 | Build Support Ticket queue + detail | 09 §6 |
| 9.10 | Build Super Ops Console (4 tabs) | 09 §7 |
| 9.11 | Build Force Assign dispatch flow | 09 §7.3 |
| 9.12 | Build POD Review + payout confirmation | 09 §7.4 |
| 9.13 | Build Post on Behalf flow | 09 §7.5 |
| 9.14 | Build Admin Management (super admin only) | 09 §9 |
| 9.15 | Build Audit Logs viewer | 09 §10 |
| 9.16 | Implement RBAC sidebar navigation | 09 §11 |

### Admin File Deliverables
```
Admin/lib/
  main.dart
  src/
    core/
      config/supabase_config.dart
      router/admin_router.dart
      theme/admin_theme.dart
    features/
      auth/
        presentation/admin_login_screen.dart
        providers/admin_auth_provider.dart
      dashboard/
        presentation/dashboard_screen.dart
        providers/dashboard_kpi_provider.dart
      verification/
        presentation/
          verification_queue_screen.dart
          verification_detail_screen.dart
        providers/verification_queue_provider.dart
      users/
        presentation/
          user_list_screen.dart
          user_detail_screen.dart
        providers/
          user_list_provider.dart
          user_detail_provider.dart
      support/
        presentation/
          support_queue_screen.dart
          support_detail_screen.dart
        providers/
          support_queue_provider.dart
          ticket_detail_provider.dart
      super_ops/
        presentation/
          super_ops_screen.dart
          dispatch_screen.dart
          pod_review_screen.dart
          post_on_behalf_screen.dart
        providers/super_ops_provider.dart
      admin_management/
        presentation/admin_management_screen.dart
        providers/admin_management_provider.dart
      audit/
        presentation/audit_logs_screen.dart
        providers/audit_log_provider.dart
    shared/
      widgets/
        admin_sidebar.dart
        data_table_widget.dart
        image_viewer.dart
```

### DoD
- [ ] Admin logs in with email/password → sees dashboard with KPI cards.
- [ ] Pending verification count matches actual pending count.
- [ ] Admin approves a supplier → user app shows "Verified" banner instantly.
- [ ] Admin rejects a trucker → user app shows rejection reason.
- [ ] Admin bans a user → user's next app open forces sign out.
- [ ] Support ticket reply → push notification sent to user.
- [ ] Force Assign on Super Load → trucker receives notification.
- [ ] Audit log entry created for every admin action.
- [ ] RBAC: Support Agent cannot access Verification Queues.
- [ ] `flutter analyze` → 0 errors on Admin project.

---

## Sprint 10: Integration Testing & Release

**Goal:** End-to-end validation and APK build.
**Duration:** 2-3 days.

### Tasks
| # | Task |
|---|------|
| 10.1 | Full end-to-end test: Register → Verify → Post Load → Book → Trip → Complete → Rate |
| 10.2 | Full admin test: Login → Approve user → Approve truck → Super Ops dispatch |
| 10.3 | Test all error states (network off, banned user, expired load, duplicate booking) |
| 10.4 | Test TTS on key screens (auth, role, bot, booking notification) |
| 10.5 | Test bot slot-filling flow (find load, post load) |
| 10.6 | Test offline fallback (city search, trip cost defaults) |
| 10.7 | Run `flutter analyze` on both projects → 0 errors |
| 10.8 | Run `check_layer_boundaries.py` → PASS |
| 10.9 | Build release APK: `flutter build apk --release` for both apps |
| 10.10 | Verify APK sizes (User app target: < 80MB, Admin app target: < 50MB) |

### DoD
- [ ] Complete user journey works end-to-end on physical Android device.
- [ ] Complete admin journey works end-to-end.
- [ ] All push notifications fire correctly.
- [ ] Bot speaks and listens in Hindi.
- [ ] Trip cost estimates display on all load cards.
- [ ] Release APKs built successfully.
- [ ] APK sizes within targets.
- [ ] No crashes observed during 30-minute manual testing session.

---

## Cross-Sprint Validation Rules

| Rule | Applied When |
|------|-------------|
| `flutter analyze` → 0 errors | End of every sprint |
| `check_layer_boundaries.py` → PASS | End of every sprint |
| No `setState()` for network calls | Code review on every PR |
| No direct DB calls from UI layer | Code review on every PR |
| All async state in providers | Code review on every PR |
| Image compression before upload | Test on Sprint 4 |
| TTS emoji stripping | Test on Sprint 7 |
| GPS failure doesn't block trip actions | Test on Sprint 6 |

---

## Total Estimated Timeline

| Sprint | Duration | Cumulative |
|--------|----------|-----------|
| 1. Setup | 2-3 days | Week 1 |
| 2. Schema & Auth | 3-4 days | Week 1-2 |
| 3. Onboarding | 3-4 days | Week 2 |
| 4. Verification & Fleet | 4-5 days | Week 3 |
| 5. Marketplace | 4-5 days | Week 3-4 |
| 6. Booking & Trips | 5-6 days | Week 4-5 |
| 7. Chat & Bot | 5-6 days | Week 5-6 |
| 8. Tooling & Polish | 3-4 days | Week 7 |
| 9. Admin App | 5-7 days | Week 7-8 |
| 10. Testing & Release | 2-3 days | Week 9 |
| **Total** | **~9 weeks** | **Production-ready V1** |
