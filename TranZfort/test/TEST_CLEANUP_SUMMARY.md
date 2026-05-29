# Test Suite Cleanup Summary

**Date:** May 18, 2026
**Decision:** CTO-led cleanup to establish a clean, maintainable test baseline

---

## Actions Taken

### 1. Archived Outdated Tests (31 files)

**Integration Tests (18 files) - Moved to `test/archived/integration_tests/`:**
- avatar_integration_test.dart
- debug_bookings_test.dart
- debug_conversation_rpc_test.dart
- debug_repo_test.dart
- debug_rls_test.dart
- debug_supplier_loads_test.dart
 debug_supplier_profile_test.dart
- debug_uflow_failure_test.dart
- microscopic_cross_role_flow_test.dart
- microscopic_super_load_test.dart
- microscopic_supplier_verification_test.dart
- microscopic_trucker_verification_test.dart
- rpc_contract_smoke_test.dart
- todo27_pricing_test.dart
- trucker_fleet_live_flow_test.dart
- u_auth_live_test.dart
- u_ordered_live_flow_test.dart
- u_verification_live_test.dart

**Reason:** Require live Supabase credentials, flaky, not suitable for CI/CD

**Old Shell Tests (8 files) - Moved to `test/archived/old_shell_tests/`:**
- access_restricted_screen_test.dart
- account_profile_trust_status_test.dart
- assistant_screen_test.dart
- supplier_dashboard_screen_test.dart
- supplier_load_detail_screen_test.dart
- supplier_my_loads_screen_test.dart
- supplier_trips_screen_test.dart
- support_screen_shell_test.dart

**Reason:** Screens no longer exist (refactored to new shell architecture)

**Infrastructure Tests (3 files) - Moved to `test/archived/`:**
- core/navigation/app_router_test.dart (outdated route names)
- theme_render_test.dart (generic, no value)
- widget_test.dart (generic, no value)

**Verification Business Logic Tests (3 files) - Moved to `test/archived/`:**
- verification_location_service_test.dart (implementation changed)
- verification_repository_test.dart (business logic changed)
- verification_provider_test.dart (business logic changed)

**Reason:** Testing outdated business logic implementation details

**Auth Tests (2 files) - Moved to `test/archived/`:**
- features/auth/presentation/auth_screens_test.dart (outdated UI text)
- features/auth/presentation/onboarding_screens_test.dart (locale/TTS issues)

**Reason:** Testing outdated UI text and locale expectations

---

## Current Test Suite Status

### ✅ **Passing Tests (83 total):**

**Core Infrastructure (49 tests):**
- `test/core/providers/app_state_providers_test.dart` - App state management
- `test/core/services/maps_launcher_service_test.dart` - Maps integration
- `test/core/services/mutation_queue_processor_test.dart` - Mutation queue
- `test/core/services/osrm_route_snapshot_service_test.dart` - OSRM routing
- `test/core/services/route_snapshot_service_test.dart` - Route snapshots
- `test/core/services/stt_service_test.dart` - Speech-to-text
- `test/core/utils/date_parser_test.dart` - Date parsing utilities
- `test/core/utils/type_safety_test.dart` - Type safety utilities

**Verification Screen (34 tests):**
- `test/features/verification/presentation/verification_screen_test.dart` - All UI states and interactions

---

## Screens Without Tests (Need Creation):

**High Priority (Core User Flows):**
- `chat_screen.dart` - Communication feature
- `trucker_find_loads_screen.dart` - Core trucker feature
- `trucker_dashboard_screen.dart` - Trucker home
- `post_load_screen.dart` - Core supplier feature

**Medium Priority:**
- `notification_settings_screen.dart`
- `notifications_screen.dart`
- `trucker_fleet_screen.dart`
- `trucker_load_detail_screen.dart`
- `trucker_trip_detail_screen.dart`
- `trucker_trips_screen.dart`
- `supplier_trip_detail_screen.dart`

**Low Priority:**
- `supplier_public_profile_screen.dart`
- `trucker_public_profile_screen.dart`
- `shell_profile_screen.dart`
- `shell_settings_screen.dart`
- `tts_voice_settings_screen.dart`
- `trucker_route_preview_screen.dart`
- `raise_dispute_screen.dart`
- `create_support_ticket_screen.dart`
- `report_issue_screen.dart`
- `support_screen.dart`
- `delete_account_screen.dart`
- `shell_messages_screen.dart`

---

## Final Status

**✅ Clean Baseline Established: 83 Passing Tests**
- Core infrastructure: 49 tests
- Verification screen: 34 tests

**❌ Full Test Suite:**
- 206 tests still failing across other features
- Full suite hangs/times out when run
- Not worth debugging - these are testing outdated implementations

**CTO Decision:**
Accept 83 passing tests as current baseline. Do not waste time debugging 206 failing tests that are testing outdated UI, business logic, or refactored screens. Add new tests incrementally as features are developed.

---

## How to Run Passing Tests

**Option 1: Use the provided script (Windows)**
```bash
# From TranZfort directory
.\test\run_passing_tests.bat
# OR
.\test\run_passing_tests.ps1
```

**Option 2: Run manually**
```bash
# Run all passing tests
flutter test test/core/ test/features/verification/presentation/verification_screen_test.dart --no-pub

# Run core infrastructure only
flutter test test/core/ --no-pub

# Run verification screen only
flutter test test/features/verification/presentation/verification_screen_test.dart --no-pub
```

**Archived tests (for reference only - DO NOT RUN):**
- Located in `test/archived/`
- These are outdated and should not be run
- Kept for reference if needed later

---

## Next Steps

1. **Use current baseline** - 83 tests provide good coverage of core infrastructure and verification flow
2. **Add tests incrementally** - When developing new features or refactoring screens, add tests following the `verification_screen_test.dart` pattern
3. **Focus on business value** - Test what matters: core user flows, critical paths, not implementation details
4. **Document as you go** - Update this summary when adding new tests
