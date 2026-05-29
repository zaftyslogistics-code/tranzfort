# Tasks completed — 29 May 2026

**Branch:** `feature/play-store-readiness-2026-05-16`  
**Remote Supabase project:** `jgtgdfhdtjhidywpautk` (see `TranZfort/build-apk.bat`)  
**Apps touched:** TranZfort (trucker + supplier), Admin (verification queue review), Supabase migrations

---

## 1. UI flicker / loading stability

- Applied provider timing fixes from `backup-before-ui-restore` to reduce list flicker on play-store readiness work.
- **Supplier:** Trips and My Loads sections — debounced errors, minimum loading display, `hasResolvedInitialLoad` where applicable.
- **Trucker:** Trips screen — same loading/error stabilization pattern.
- **Notifications:** Provider + screen tests aligned with debounced error / initial-load behavior.
- Related shared UI: `content_cards.dart`, `layout_components.dart`, `marketplace_load_card.dart`.
- Lifecycle status constants updated for consistent trip/load status display (`lifecycle_status_constants.dart`).

---

## 2. Signup & onboarding

- **Root cause:** `user_consents` missing unique constraint caused `upsert_current_user_profile` to fail when recording terms during onboarding.
- **App:** `auth_repository_profile_ops.dart` — safer profile upsert (city/state/role), `recordTerms: false` on profile upsert then separate `record_user_consent`, more resilient `get_current_user_profile` parsing.
- **Migration:** `supabase/migrations/20260529120000_fix_user_consents_unique_for_onboarding.sql` — pushed to remote.

---

## 3. Trucker verification — “Unable to load verification state”

- **Root cause:** Flutter queried non-existent `pan_last4` on `profiles` (schema had `pan_number` / `aadhaar_last4` only).
- **Migration:** `20260529130000_add_pan_last4_to_profiles.sql` — added column; pushed to remote.
- **App:** `verification_repository_backend.dart`, `verification_repository_models.dart` — fallback from `pan_number`, save writes `pan_last4` + last-4 `pan_number`.

---

## 4. Supplier verification alignment

- Reviewed supplier path for same profile/RPC/document issues as trucker; confirmed shared verification repository and wizard; no separate supplier-only schema gap beyond business/location fields.

---

## 5. Admin verification pipeline

- Confirmed Admin app reads `verification_cases` directly (`admin_verification_repository_backend.dart`) for Suppliers / Truckers / Trucks queue tabs.
- Verified end-to-end intent: TranZfort submit → `verification_cases` (`submitted`) + profile `pending` + admin notifications.

---

## 6. Fleet RPCs & verification submit (backend)

- **Issue:** Rollback migration had dropped `add_truck`, `get_trucker_fleet`, etc.; `submit_verification_for_review` expected full Aadhaar/PAN while app stores last4.
- **Migration:** `20260529140000_restore_fleet_rpcs_and_fix_verification_submit.sql`:
  - Restored fleet RPCs; `add_truck` returns `JSONB {"id": "..."}`.
  - `submit_verification_for_review` validates last4 + required docs, supplier licence/location, trucker ready truck, admin notifications; `GRANT` to `authenticated`.
- **`supabase db push`** run against remote; confirmed database up to date.

---

## 7. Document & profile photo upload UX

- Profile photo, identity, and business wizard steps lacked clear success/error feedback; Android `mimeType` often null caused silent validation failures; canceling picker gave no feedback.
- **Added:** `verification_wizard_upload_feedback.dart` (banners + snackbars).
- **Unified:** `verification_wizard_provider.upload_handlers.dart` upload result handling.
- **MIME:** `ImageUploadServiceDefaults.resolveImageMimeType` in `image_upload_service.dart` (verification + truck uploads).
- **Tests:** `verification_document_upload_service_test.dart` (cancel pick, mime fallback, storage path).

---

## 8. Trucker fleet (TranZfort app)

- `trucker_fleet_repository.dart` — `add_truck` accepts Map or UUID string response; `get_trucker_fleet` handles List response shape from RPC.

---

## 9. Full verification flow review (trucker + supplier)

End-to-end review of wizard → save → `submit_verification_for_review` → Admin queue. Fixes implemented:

| Area | Change |
|------|--------|
| Draft clear | `VerificationDraft` / `TruckDraft` `copyWith` `clear*` flags so removing photos/docs works |
| Wizard stability | `verificationWizardProvider` uses `ref.read(verificationProvider)` so parent refresh does not reset wizard |
| Terms | Enforced on submit via `validateAll(..., termsAccepted:)` |
| Resubmission | `isResubmission` set when status is `rejected` |
| `canSubmitForReview` | `hasIdentityNumbers` uses `aadhaarLast4` / `panLast4` (P0.7 — no full numbers in DB) |
| Truck step | `hasTruckComplete` requires capacity; hydrate truck from fleet on load |
| Duplicate trucks | Skip `createTruck` if fleet already has ready truck (same number + RC + capacity) |
| Field errors | `verification_wizard_field_errors.dart` maps repository keys (e.g. `rc_document_path`) to wizard fields |
| Submit save failures | Mapped field errors shown on review step |

**Files (main):** `verification_wizard_*.dart`, `verification_repository_models.dart`, `verification_wizard_validation_helper.dart`, wizard step screens.

---

## 10. Supplier / trucker shell & trips (in progress on branch)

- `supplier_shell_my_loads_sections.dart`, `supplier_shell_trip_sections.dart`
- `supplier_trip_repository.dart`, `supplier_trip_repository_backend.dart`
- `trucker_trips_screen.dart`, `trucker_trip_detail_provider.dart`
- Localization updates: `app_localizations.dart`, `_en.dart`, `_hi.dart`

---

## Migrations applied to remote (29 May)

| Migration | Purpose |
|-----------|---------|
| `20260529120000_fix_user_consents_unique_for_onboarding.sql` | Onboarding / terms consent upsert |
| `20260529130000_add_pan_last4_to_profiles.sql` | Verification profile load |
| `20260529140000_restore_fleet_rpcs_and_fix_verification_submit.sql` | Fleet + submit for review |

---

## Verification checklist (manual — confirmed working by team)

- [x] Signup / onboarding completes
- [x] Trucker verification loads and submits
- [x] Supplier verification path reviewed
- [x] Document uploads show feedback
- [ ] Full resubmit-after-reject regression (recommended before release)
- [ ] Admin queue spot-check per role after each test submit

---

## Known follow-ups (not blocking current testing)

- Profile photo step “quality” indicators are cosmetic only.
- Truck photo optional in UI; not persisted on `create_truck`.
- Wizard requires supplier company name; RPC may not — align if product requires parity.
- Rejected users re-enter full Aadhaar/PAN in wizard (DB stores last4 only — by design for P0.7).
- Optional: RPC checks for `company_name` / `profile_photo_document_path`; extra wizard/submit unit tests.

---

## Deploy note

Rebuild TranZfort APK after pulling app changes:

```bat
TranZfort\build-apk.bat
```

---

*Document created: 29 May 2026 — summarizes work completed in session on play-store readiness branch.*
