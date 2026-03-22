# TranZfort Beta Version — Master TODO

**Date:** 2026-03-17  
**Updated:** 2026-03-22  
**Status:** Active - Phase A & B Complete, Ready for Phase C Manual Testing  
**Priority:** Beta launch ASAP
**Execution mode:** User app first -> Minimum Admin second -> Manual testing third

---

## Git Repository Details

| Field | Value |
|-------|-------|
| **Repository URL** | `https://github.com/zaftyslogistics-code/tranzfort.git` |
| **GitHub User ID** | `zaftyslogistics-code` |
| **GitHub Email** | `zaftyslogistics@gmail.com` |
| **Current Branch** | `feature/codebase-refactoring` |
| **First Commit** | `3cb2bb8` (Initial commit: TranZfort logistics platform) |
| **Excluded from Git** | `docs/`, `old-app/`, `.env`, sensitive credentials |

---

## Executive Summary (March 22)

| Phase | Status | Notes |
|-------|--------|-------|
| A - User app beta completion | COMPLETE | All critical flows truthful and route-complete |
| B - Minimum Admin beta | COMPLETE | Operational baseline locked |
| C - Manual testing | READY TO START | All automated tests passing |

### Recent Completions (March 22)
- Button gradient fix - All CTAs now use teal+orange gradient
- Database RPC fix - get_linked_trips_for_supplier created
- Widget tests: 643/643 passing
- Integration tests: 9/9 U-FLOW passing
- flutter analyze: No issues

---

## 1. Beta product direction

### Core launch decision

TranZfort beta will be defined as:

- a **comprehensive User app** for Supplier and Trucker critical workflows
- a **minimum important Admin app** for operations, verification, support, and oversight
- an **Android-first beta**
- a **truthful beta**, meaning no misleading placeholder-like production paths in critical flows

### Beta execution rule

Do not resume broad feature development.

From now on, work must follow this order only:

1. tighten and complete missing **User app beta-critical flows**
2. complete the **minimum Admin beta baseline** only
3. run structured **manual testing and release-readiness validation**
4. defer all non-beta breadth until after beta

---

## 2. Locked beta scope

## 2.1 User app — must be comprehensive for beta

### Supplier beta scope

Must be present and trustworthy:

- auth and onboarding
- supplier verification
- supplier dashboard
- post load
- my loads
- supplier load detail
- booking review and approval/rejection
- supplier trips list
- supplier trip detail
- dispute raise flow
- report issue flow
- support list/detail/reply
- notifications inbox
- messages/chat
- account/profile/settings/support/delete-account minimum surfaces

### Trucker beta scope

Must be present and trustworthy:

- auth and onboarding
- trucker verification
- fleet add/edit/review states
- trucker dashboard
- find loads
- trucker load detail
- booking flow
- trucker trips list
- trucker trip detail
- POD/LR proof flow
- dispute/report issue flow
- support list/detail/reply
- notifications inbox
- messages/chat
- account/profile/settings/support/delete-account minimum surfaces

### User app quality rule

For beta, user flows must be:

- route-complete
- state-complete for loading/empty/error/success
- blocked honestly where backend authority is incomplete
- free from misleading placeholder behavior in critical paths

## 2.2 Admin app — minimum important beta only

The Admin app only needs the minimum important operational baseline:

- admin login
- RBAC
- dashboard
- user management list/detail
- ban/unban baseline
- verification queue + detail + approve/reject
- support queue + detail + visible reply baseline
- operational cases queue/detail/lifecycle baseline
- Super Ops request review + payment confirmation + dispatch baseline
- load management read/detail + cancel baseline
- audit log visibility

### Admin beta rule

Admin should be treated as:

- operationally useful
- not fully feature-complete
- honest about any contract-limited actions

If an admin feature is not needed to operate beta safely, defer it.

---

## 3. Explicit beta deferrals

These are intentionally **not required before beta launch** unless they block truthful operation:

- full conversational bot
- iOS Firebase/APNs setup
- post-beta architecture cleanup/refactors
- broader localization polish beyond launch-critical truthfulness
- deeper admin invite/deactivate-admin management flows
- richer post-beta Super Load automation breadth
- full multi-proof dispute evidence model if current backend contract does not support it cleanly

---

## 4. Current known launch-truth gaps to fix first

## 4.1 User app highest-priority gaps

- [x] Replace the supplier load detail `StubScreen` naming/ownership with a proper beta-safe supplier load detail surface
- [x] Decide beta handling for `Assistant`: primary top-app-bar and drawer surfacing is now removed for beta, notification route resolution no longer treats it as a standard beta destination, and the remaining routed screen is now relabeled as `Guided help` so it no longer presents itself as a shipped bot-equivalent while the underlying route remains available for controlled/internal follow-through
- [ ] Re-audit all user critical routes so no critical CTA leads to misleading or transitional behavior
- [ ] Reconfirm supplier and trucker critical flows against current phase trackers and live route wiring
- [ ] Tighten any remaining user-facing gaps that block a full walkthrough of Supplier and Trucker critical journeys

## 4.2 Admin highest-priority gaps

- [ ] Decide whether beta requires support assign/status/priority/resolve or whether visible reply baseline is sufficient for beta operations
- [ ] Decide whether beta requires Super Load POD approval/dispute admin actions or whether Super Load can remain limited/manual during beta
- [ ] Confirm verification approve/reject-only baseline is acceptable for beta if escalate/request-more-details remain unavailable
- [ ] Keep admin static/minimal utility surfaces from being misrepresented as complete modules

---

## 5. Ordered execution plan

## Phase A — User app beta completion first

### A1. User app truth cleanup
- [x] Fix supplier load detail beta-safe ownership/naming and review its route truth
- [x] Decide and implement Assistant beta behavior
- [x] Recheck critical user utility routes and connected exits — first beta truth batch is landed: supplier load-detail route naming is clean, Assistant is removed from primary navigation, and notification route resolution no longer treats Assistant as a standard beta destination. Continue from the remaining live routed user surfaces only.

### A2. Supplier critical walkthrough completion
- [x] Supplier: dashboard -> post load -> my loads -> load detail -> booking review -> trip detail — post-load blocked-state guidance is tightened so profile-unavailable users now get a Support exit instead of a dead-end blocker, supplier profile-load failures on `PostLoadScreen` now get the same `Support` recovery path instead of explanation-only blocked copy, disputed supplier trip detail now exposes a direct Support handoff during review, supplier trip-detail not-found now routes users back to supplier trips instead of collapsing into a generic failure state, raise-dispute missing-trip context now routes users back to supplier trips instead of showing only a generic unavailable state, stage-blocked `RaiseDisputeScreen` warnings now expose `Support`, stale `ChatScreen` conversation handoff now routes users back to messages instead of leaving them on an explanation-only dead end, empty `Messages` inbox now routes suppliers back to `My Loads` instead of stopping at explanation-only copy, empty `Notifications` now routes suppliers back to `My Loads` instead of stopping at explanation-only copy, and `DeleteAccountScreen` no longer leaks backend-shaped outcome text in blocked/cancelled/accepted lifecycle states. Supplier dispute/report/support, notifications/chat handoff, and delete-account lifecycle routing have been rechecked as truthful.
- [x] Supplier: dispute/report/support flows
- [x] Supplier: notifications/chat handoff verification
- [x] Supplier: delete-account lifecycle walkthrough verification

### A3. Trucker critical walkthrough completion
- [x] Trucker: dashboard -> find loads -> load detail -> booking -> trips -> trip stages -> proof — disputed trucker trip detail now exposes a direct Support handoff during review, blocked trip-detail communication now routes users toward `Open verification` or `Open fleet` instead of leaving chat gating as explanation-only text, trucker trip-detail not-found now routes users back to trips instead of collapsing into a generic failure state, `ChatScreen` now keeps thread-load failures visible, uses sanitized failure copy, and routes stale conversation handoffs back to messages instead of leaking backend-shaped detail or leaving users stranded, empty `Messages` inbox now routes truckers back to `Find Loads` instead of stopping at explanation-only copy, empty `Notifications` now routes truckers back to `Find Loads` instead of stopping at explanation-only copy, filtered-empty `Find Loads` marketplace states now expose `Reset filters` when active filters cause zero results, empty `Fleet` now exposes `Add truck` directly from the `My trucks` empty state instead of forcing the user to scroll back to the hero action, `DeleteAccountScreen` no longer leaks backend-shaped outcome text in blocked/cancelled/accepted lifecycle states, trucker dashboard `Recent activity` failures now expose `Retry` instead of stopping at explanation-only copy, fleet/verification blocked-unblocked routing is verified through dashboard, fleet, verification, and load-detail handoffs, dispute/report/support routing is verified through trip detail and report-issue/support paths, notifications/chat handoffs are verified through trucker empty-state and stale-conversation recoveries, and trucker delete-account lifecycle blockers are verified through trips/support routes.
- [x] Trucker: fleet -> verification -> blocked/unblocked flow truth
- [x] Trucker: dispute/report/support flows
- [x] Trucker: notifications/chat handoff verification
- [x] Trucker: delete-account lifecycle walkthrough verification

### A4. User app runtime readiness
- [x] Android-first notification/runtime validation plan — documented in `docs/TODO&Progress/android-first-notification-runtime-validation-plan.md` against the current push runtime, notification route resolver, and settings push-status surface.
- [x] Confirm no critical placeholder-like user route remains in production beta paths — the last live `Assistant` production route and shell entry points have been removed from the user beta shell/router.
- [x] Confirm no critical raw backend error leaks in user app core flows — support ticket list and selected-ticket detail failure states are sanitized, `ChatScreen` no longer leaks raw backend-shaped failure text in thread load, booking-action warning, or send-failure snackbar states, `DeleteAccountScreen` no longer leaks backend outcome text in blocked/cancelled/accepted lifecycle states, and the latest supplier/trucker walkthrough closeout audit did not surface any remaining critical raw backend leaks in live user beta routes.
- [x] Fix first-run auth -> onboarding -> dashboard flow truth — role selection now persists through both auth metadata and the current profile row, `OnboardingGateScreen` no longer bounces known-role users back to role selection, and the new onboarding helper migration `supabase/migrations/20260318000000_phase10_onboarding_profile_upsert_rpc.sql` lets fresh accounts create or repair their current profile row during onboarding so new signup can complete role selection once and continue to profile/dashboard truthfully.

## Phase B — Minimum Admin beta second

### B1. Admin baseline lock
- [x] Lock which contract-limited admin actions are acceptable for beta — accept the currently routed and authority-bounded admin lane only: login + RBAC, dashboard, verification queue/detail with approve/reject and structured rejection feedback, support queue/detail with visible admin replies, operational case queue/detail with claim/release/waiting/review/resolve/reject/escalate where current contracts allow, Super Load queue/readiness/activation with current backend contracts, load management list/detail inspection plus shared cancellation where backend status allows it, users/detail contextual review, audit logs, settings, notifications, and super-admin-only admin-management read visibility.
- [x] Remove ambiguity between “minimum operationally useful” and “fully complete admin” — beta admin means contract-limited operational usefulness only, not full back-office completion. Deferred actions such as admin invite/deactivate, support assignment/status/priority/resolve, verification request-more-details/escalate outside live authority, payout completion, and broader admin object mutation remain explicitly out of scope until dedicated backend authority lands.

### B2. Admin execution completion
- [x] Finish only the admin features required for beta operations — the current routed admin shell already exposes the minimum operational surfaces required for beta operations under live contracts, and this lane is now locked to those surfaces instead of full admin completion.
- [x] Keep all unsupported actions explicitly truthful — current admin screens already surface contract-limited boundaries for deferred actions instead of implying unsupported mutations are available.
- [x] Tighten verification/support/ops/super-load/load-management walkthroughs — walkthrough truth is locked around the current live contracts: verification approve/reject only, support browse/detail/reply only, operational cases through live lifecycle contracts, Super Load readiness/activation via current backend contracts, and load management as inspection-first with shared cancel only where backend authority allows it.
- [x] Fix admin dashboard mobile rendering truth — `AdminAppShell` now switches to drawer-first compact navigation on phone widths and the dashboard metric/quick-navigation cards now adapt to narrow surfaces so the current admin beta shell no longer overflows on smaller Android screens.

## Phase C — Manual testing and launch-readiness third

### Status: 🔄 READY TO START (March 22)
All automated validation complete. Manual walkthroughs are the remaining gate.

### C1. User app manual test pack
- [ ] Supplier full walkthrough: dashboard → post load → my loads → load detail → booking review → trip detail → dispute/support
- [ ] Trucker full walkthrough: dashboard → find loads → load detail → booking → trips → trip stages → POD/LR proof → dispute/support
- [ ] Notifications/chat/deep-link walkthrough
- [ ] Trust-gating and blocked-state walkthrough (verification, fleet, account)
- [ ] Settings, profile, delete-account flows

### C2. Admin app manual test pack
- [ ] Login + RBAC walkthrough
- [ ] Verification queue → detail → approve/reject with feedback
- [ ] Support queue → detail → reply
- [ ] Operational cases queue → detail → lifecycle
- [ ] Super Ops walkthrough
- [ ] Load management → detail → cancel
- [ ] Users management → detail

### C3. Release baseline (COMPLETE)
- [x] Confirm analyze/test/build baseline for both apps — `flutter analyze`, `flutter test`, `flutter build apk` all passing
- [x] Confirm Android APK/manual readiness — debug APKs building successfully
- [x] Automated test suite: 643 widget tests + 9 integration tests all passing

---

## 6. Beta launch blockers (UPDATED March 22)

| Blocker | Status | Resolution |
|---------|--------|------------|
| User app critical flows not walkthroughable | 🔄 IN PROGRESS | Automated tests pass. Manual walkthrough remains. |
| Supplier load detail transitional/stub | ✅ RESOLVED | Production route clean, truthful |
| Assistant route ambiguity | ✅ RESOLVED | Removed from primary navigation |
| Admin baseline not locked | ✅ RESOLVED | Minimum operational truth locked |
| Android-first runtime testing | 🔄 READY | Device ready (89P7MZVWV4Z9C6GE) |
| Phase 15 beta-critical validation | ✅ RESOLVED | Button gradients, RPCs fixed |

---

## 7. Next Steps Decision Matrix

| Option | Work Required | Confidence | Recommendation |
|--------|---------------|------------|----------------|
| **A. Start Manual Testing** | Execute Phase C walkthroughs | HIGH | ⭐ RECOMMENDED - All automated tests passing |
| **B. Additional Automated Tests** | Expand test coverage | MEDIUM | Can parallel with manual testing |
| **C. Polish Pass** | UI refinements, animations | LOW | Defer until after manual validation |
| **D. Admin Expansion** | Add deferred admin features | LOW | Out of scope for beta |

---

## 7. Beta acceptance criteria

Beta can be considered ready only when:

- [ ] Supplier critical workflow is fully walkthroughable
- [ ] Trucker critical workflow is fully walkthroughable
- [ ] Support/dispute/report flows are walkthroughable for users
- [ ] Admin minimum operational workflow is walkthroughable
- [ ] No critical production route behaves like a placeholder or misleading transitional screen
- [ ] Android-first manual testing baseline is complete
- [ ] Both apps are stable enough for controlled beta walkthroughs

---

## 8. CTO/Product operating rule from now

When choosing work, prioritize in this order:

1. user flow completeness
2. truthfulness of production routes and CTAs
3. minimum admin operational usefulness
4. manual testing readiness
5. polish only after the above are stable
