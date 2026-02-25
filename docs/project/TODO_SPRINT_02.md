# TODO - Sprint 2: Supabase Schema & Auth Repository

## Scope
Apply DB schema and implement authentication repository + core services.

## Tasks
- [x] Execute SQL migrations from `02_DATABASE_SCHEMA_AND_RLS.md`
- [x] Verify RLS policies
- [x] Implement `AuthRepository` in `lib/src/core/repositories/`
- [x] Implement base `DatabaseService` (Supabase wrapper) in `lib/src/core/services/`
- [x] Add auth providers (`authSessionProvider`, `userRoleProvider`, `userProfileProvider`)
- [x] Add `updated_at` triggers on all tables

## Definition of Done
- [x] All migrations applied with no errors
- [x] Google sign-in creates session + profile
- [x] RLS validated for cross-user access
- [x] `check_layer_boundaries.py` → PASS
