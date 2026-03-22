# TODO Gap Fix — 17 March

**Status:** Active
**Scope:** Verification rework + audit-driven stabilization
**Source inputs:** `docs/code-review-17-march.md`, `docs/TODO&Progress/master-todo.md`, `docs/TODO&Progress/master-todo-beta-version.md`

---

## Locked Verification Requirements

### Trucker verification

- Must complete **one combined verification packet**
- Packet must include:
  - Aadhaar details
  - PAN details
  - At least **one truck**
- Each required identity item must support:
  - number field
  - image attachment
- Truck packet must support:
  - truck number
  - body type
  - tyres
  - capacity
  - RC image attachment
- Submission gating should depend on **one complete truck packet**, not on an already-approved truck
- Post-submission product gating can still depend on admin approval where appropriate

### Supplier verification

- Must complete one supplier verification packet
- Required:
  - Aadhaar details
  - PAN details
  - business licence details
- Optional:
  - GST details
- Each identity/business item must support:
  - number field
  - image attachment
- Supplier packet should continue to capture business context and verification location where needed

---

## Architecture Decision

### Keep

- Current feature structure: `verification`, `trucker fleet`, `supplier profile`
- Current document upload services
- Current verification case submission RPC pattern
- Current admin review model

### Change

- Verification data model must store **identifier values**, not only image paths
- Verification submit logic must validate the new packet shape server-side
- Trucker submission readiness must be based on **complete truck packet count** rather than approved truck count
- Verification UI must become a **packet editor** rather than only an upload checklist
- Fleet and verification must be logically linked so trucker sees one verification journey

---

## Gap List

### G-1 Data model gaps

- [x] Add profile-level identifier fields for verification:
  - [x] `aadhaar_number`
  - [x] `aadhaar_last4`
  - [x] `pan_number`
- [ ] Confirm supplier-level fields already sufficient:
  - [x] `business_licence_number`
  - [x] `gst_number`
- [ ] Decide whether trucker-specific identity numbers beyond PAN/Aadhaar remain needed in beta
- [x] Expose identifier fields in repository/domain models

### G-2 Verification submission logic gaps

- [x] Replace `approvedTruckCount` submission dependency with `verificationReadyTruckCount`
- [ ] Keep `approvedTruckCount` for downstream booking/chat gating where still valid
- [x] Update client-side `canSubmitForReview`
- [x] Update client-side blocked reason copy
- [x] Update server-side `submit_verification_for_review()` validation to match packet rules

### G-3 UI/UX verification gaps

- [x] Add packet detail fields to current verification screen
  - [x] Aadhaar number
  - [x] PAN number
  - [x] Supplier company/business fields
  - [x] Business licence number
  - [x] GST number optional
- [x] Add save action for packet details before submission
- [x] Make trucker verification surface clearly indicate one-truck requirement
- [x] Evaluate embedded mini truck form vs linked fleet form and implement the chosen approach
- [x] Remove misleading “approved truck required before verification submit” copy

### G-4 Fleet integration gaps

- [x] Count trucks that are verification-ready (`rc_document_path` present and not archived)
- [x] Show clearer truck packet readiness in verification UI
- [x] Consider pre-filling fleet add flow from verification journey
- [x] Implement the chosen fleet continuity approach

### G-5 Audit-driven stabilization gaps

- [x] Fix `preferred_language` missing from auth profile select
- [x] Verify `pushRuntimeLifecycleProvider` is actually activated
- [x] Verify push token persistence to server
- [x] Remove dead `assistantPath`
- [x] Remove dead placeholder screens from `shell_destinations.dart`
- [x] Remove hardcoded Google OAuth fallback client ID from source
- [x] Replace critical `dynamic` localization casts with typed `AppLocalizations`
- [x] Add release build validation

### G-6 Structural debt gaps

- [x] Split oversized verification-related files after logic stabilizes
  - [x] `verification_screen.dart`
  - [x] `verification_repository.dart`
  - [x] `supplier_shell_screens.dart`
  - [x] `trucker_trip_detail_screen.dart`
  - [x] `chat_screen.dart`
  - [x] `chat_repository.dart`
- [ ] Split oversized admin repositories/screens later in separate cleanup lane

### G-7 Auth, onboarding, and session hardening gaps

- [x] Restart the auth system around a reduced beta scope
  - [x] lock the beta auth methods to only:
    - [x] Google auth
    - [x] email/password sign-in
    - [x] email/password sign-up with Supabase email verification
  - [x] defer phone/mobile auth completely from the user app active flow
  - [x] remove phone auth from active auth UX copy, routing, and validation scope
- [x] Simplify the public auth route surface
  - [x] decide the final public auth route list
  - [x] remove `/auth/phone` from active routing
  - [x] remove `/auth/otp` from active routing
  - [x] keep `/auth` as the auth entry route
  - [x] decide whether manual auth stays at `/auth/password` or is split into dedicated sign-in and sign-up routes
- [x] Simplify the auth entry experience
  - [x] remove the phone CTA from `AuthEntryScreen`
  - [x] update the entry screen spoken prompt so it no longer references phone auth
  - [x] keep only Google and email/manual auth CTAs on the entry screen
  - [x] re-check the entry screen layout after removing the phone CTA
- [x] Reshape manual auth into an explicit email verification flow
  - [x] split current combined password auth UX into explicit states
  - [x] define the sign-in state UX
  - [x] define the sign-up state UX
  - [x] define the post-sign-up check-email state UX
  - [x] define the resend / back-to-sign-in behavior
  - [x] ensure sign-up success does not pretend the user is signed in when email verification is still pending
- [x] Align manual auth behavior with Supabase email verification
  - [x] verify Supabase email confirmation is the source of truth for manual sign-up completion
  - [x] make sign-up success show explicit email-verification instructions
  - [x] make sign-in handle unverified-email outcomes clearly
  - [ ] decide whether the app needs a deep-link return flow now or can use verify-then-sign-in for beta
- [ ] Reduce auth repository responsibilities
  - [ ] separate active auth methods from deferred auth methods
  - [ ] keep Google auth active
  - [ ] keep email/password auth active
  - [x] mark phone auth methods as deferred or remove them from active call sites
  - [ ] review whether onboarding/profile mutation methods should remain in `AuthRepository` or move later into a dedicated account/onboarding repository
- [ ] Lock the backend identity contract needed by the simplified auth flow
  - [ ] confirm how `profiles` rows are created for new auth users
  - [ ] confirm whether `profiles` creation is trigger-driven, RPC-driven, or still client-compensated
  - [ ] confirm the minimum required fields on initial profile creation
  - [ ] confirm role remains nullable until onboarding role selection
  - [ ] confirm `email` should be populated from auth for manual and Google sign-ins
- [ ] Lock the onboarding handoff after authentication
  - [ ] define the route behavior for authenticated users with no role
  - [ ] define the route behavior for authenticated users with role but incomplete profile
  - [ ] define the route behavior for authenticated users with complete profile
  - [ ] re-check banned and deactivated user precedence against the simplified auth flow
- [ ] Re-audit remaining auth/profile scope decisions still open in beta
  - [ ] `avatar_url` mapping / usage decision
  - [ ] explicit account deletion schema dependency verification
  - [ ] align TTS onboarding prompts with selected / preferred language
- [ ] Rebuild auth validation around the simplified flow
  - [x] update auth entry widget tests for Google + email only
  - [x] remove phone-flow expectations from active auth tests
  - [x] add explicit manual-auth sign-up verification-state tests
  - [x] add explicit manual-auth sign-in tests
  - [x] add router tests proving deferred phone routes are no longer part of the active public flow

---

## Execution Plan

### Phase A — Verification contract correction

- [x] Add migration for verification identifier fields
- [x] Extend repository/backend models with identifier fields and truck packet counts
- [x] Update submit-readiness logic
- [x] Update tests for new readiness rules

### Phase B — Verification packet editing UI

- [x] Add packet details section to `verification_screen.dart`
- [x] Add provider actions for saving identifiers/business numbers
- [x] Add success/failure feedback on save
- [x] Ensure rejected users can edit and resubmit

### Phase C — Server-side truth alignment

- [x] Update submission RPC validation to match the packet contract
- [x] Ensure resubmission follows same validation
- [x] Ensure admin review surfaces receive enough context for numbers + attachments

### Phase D — Trucker one-flow continuity

- [x] Make verification screen show truck packet requirement clearly
- [x] Improve fleet return path back into verification
- [x] Evaluate embedded mini truck form vs linked fleet form
- [x] Implement the chosen approach

### Phase E — Audit critical fixes

- [x] Auth profile select fix
- [x] Push lifecycle verification
- [x] Push token persistence verification
- [x] Dead route cleanup
- [x] Dead placeholder screens cleanup
- [x] OAuth source cleanup

### Phase F — Structural cleanup

- [x] Split oversized verification files
- [x] Split related repositories/screens
- [x] Keep behavior unchanged during splitting

### Phase G — Auth and startup hardening

- [x] Rewrite the auth scope around two methods only: Google + email/password
- [x] Defer phone/mobile auth completely from the active user flow
- [x] Simplify auth entry routing and UX
- [x] Implement explicit manual auth verification states for Supabase email verification
- [ ] Confirm backend profile provisioning assumptions for the simplified auth flow
- [x] Rebuild auth test coverage around the simplified flow

### Phase H — Auth restart and simplification

- [x] Remove phone auth from the auth entry screen
- [x] Remove phone auth from active public auth routing
- [x] Keep Google auth working after the auth entry simplification
- [x] Keep manual auth route reachable after removing phone auth
- [x] Decide whether manual auth is one screen with explicit modes or split screens
- [x] Implement explicit post-sign-up check-email behavior
- [x] Re-run targeted auth analyzer and auth/router tests after each auth slice

---

## First Implementation Slice

### In progress now

- [x] Map current verification/fleet/schema reality against the new requirement
- [x] Reuse old-app verification field patterns as reference only
- [x] Add identifier fields to live schema/model
- [x] Switch trucker submission gating to complete truck packet readiness
- [x] Start exposing packet fields in current verification flow

### Current auth restart slice

- [x] Rewrite the auth plan in microscopic tasks before changing behavior
- [x] Remove phone auth from the auth entry screen
- [x] Remove phone auth from active public auth routing
- [x] Keep Google auth working after the auth entry simplification
- [x] Keep manual auth route reachable after removing phone auth
- [x] Decide whether manual auth is one screen with explicit modes or split screens
- [x] Implement explicit post-sign-up check-email behavior
- [x] Re-run targeted auth analyzer and auth/router tests after each auth slice

---

## Testing Checklist

### Verification tests

- [x] Repository tests updated for identifier fields
- [x] Provider tests updated for packet save actions
- [x] Screen tests updated for new trucker blocked reason
- [x] Screen tests updated for supplier/business number requirements

### Runtime checks

- [x] Trucker can save Aadhaar/PAN numbers and images
- [x] Trucker cannot submit without one truck packet
- [x] Trucker can submit with one complete truck packet even if truck is not yet approved
- [x] Supplier can save business licence number + document
- [x] GST remains optional
- [x] Rejected verification can be corrected and resubmitted

### Regression checks

- [x] Existing fleet add/edit still works
- [x] Existing supplier profile business update still works
- [x] Verification review status rendering still works
- [ ] Admin verification queue still receives new submissions

---

## Notes

- The old app used richer verification number fields; the current rebuild regressed to path-only storage.
- The fastest safe repair path is to restore number-field support into the current architecture rather than restore the old screens wholesale.
- Trucker booking should remain gated by verified profile + verified truck, but **verification submission itself** should not require a pre-approved truck.
- Remaining unchecked work is now limited to a final end-to-end/admin-queue submission receipt check that is still better treated as manual or integration validation because current automated coverage does not prove fresh user submissions surface in the Admin queue end-to-end.
