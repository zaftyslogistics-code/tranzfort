# TODO - Sprint 1: Project Setup & Core Spine

## Scope
Establish the foundation for TranZfort V1 user app. No feature UI beyond splash.

## Tasks
- [x] Create Flutter project for user app (package: `com.tranzfort.app`)
- [x] Add dependencies listed in `00_CORE_ARCHITECTURE.md` (Sprint 1 subset)
- [x] Create folder structure per `00_CORE_ARCHITECTURE.md` (Sprint 1 subset)
- [x] Implement theme tokens per `01_DESIGN_SYSTEM_AND_PSYCHOLOGY.md`
- [x] Build shared widgets: `PrimaryButton`, `OutlineButton`, `StatusBadge`, `EmptyStateView`
- [x] Implement `AppFailureType` + `Result<T>`
- [x] Setup GoRouter with `/splash`
- [x] Setup Supabase config reading from `--dart-define`

## Definition of Done
- [x] App compiles and runs
- [x] `/splash` renders
- [x] `flutter analyze` → 0 errors
- [x] Theme colors match spec
- [x] Shared widgets match sizing rules

## Notes
- Follow Option A ownership: repositories in `core/repositories/`, utilities in `core/services/`
