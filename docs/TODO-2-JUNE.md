# TODO-2-JUNE — LOADPOST-2 Execution Checklist

**Date:** 2 June 2026  
**Program:** LOADPOST-2 (fresh restart)  
**Status:** Active planning + controlled execution

---

## 1) Rollback safety (read first)

If LOADPOST-2 implementation becomes unstable and we decide to scrap the entire program work, rollback to:

- **Rollback baseline commit:** `40d6961`
- **Reason:** Last known stable state before LOADPOST-2 feature implementation slices.

Recommended rollback command (only when explicitly approved):

```bash
git reset --hard 40d6961
```

Use this only as a full scrap fallback. Prefer slice-level revert first.

---

## 2) Global working rules (must follow every day)

- [ ] Do not start coding before reading `docs/LOADPOST-2-JUNE.md`.
- [ ] Keep current layout shell intact (no major structural redesign in phase-1).
- [ ] Enforce notation lock globally: **W = wheels**, **T = tons**.
- [ ] No free-text material posting; only master-table selection.
- [ ] Do not bypass drawer pattern when option sets are large.
- [ ] Use forward migrations only (never re-apply removed rollbacked LP files).

---

## 3) Before starting any new slice (hard gate)

- [ ] `git status` clean or intentionally scoped.
- [ ] Confirm previous slice smoke test is green.
- [ ] Confirm pending lints for touched files are resolved.
- [ ] Confirm rollout order dependencies are satisfied.
- [ ] Confirm rollback path is known for this slice.
- [ ] Write slice objective + done criteria in this file before implementation.

---

## 4) Mandatory smoke test checklist (run on every slice)

### Post Load smoke

- [ ] Open Post Load screen without crash.
- [ ] Route fields still work as before.
- [ ] Cargo Details renders correctly (no overflow/clip).
- [ ] Vehicle Requirements renders compact summary and opens drawer.
- [ ] Submit validation messages are correct.

### Find Loads smoke

- [ ] Pinned filter loads with **Any** default selected.
- [ ] Pinned filter height remains compact.
- [ ] Drawer opens from filter edit action.
- [ ] Show loads apply works and returns data.

### Fleet + booking smoke

- [ ] Add/Edit truck flow opens selector drawer.
- [ ] Truck save succeeds with required fields.
- [ ] Load detail renders new requirement summary correctly.
- [ ] Booking allows matching truck and blocks mismatched truck with clear reason.

---

## 5) UI-UX guardrails (implementation constraints)

- [ ] Keep compact card rhythm and spacing.
- [ ] Keep existing pinned filter structure; do not replace with large grid blocks.
- [ ] Inline chips only for selected/high-value states.
- [ ] Long option sets must use drawer/sheet.
- [ ] Show summary chips (`+N more`) instead of long chip overflow.
- [ ] Keep dark-surface filter visuals consistent in Find Loads.
- [ ] Keep `Show loads` explicit apply flow.

### Do not merge if any of these happen

- [ ] Pinned filter becomes multi-row heavy by default.
- [ ] New UI introduces mixed notation like `12T` for wheels.
- [ ] Selection requires scrolling huge inline chip collections.
- [ ] Existing marketplace card hierarchy gets visually broken.

---

## 6) Code quality rules (mandatory)

- [ ] No hardcoded long lists in UI widgets.
- [ ] All material and vehicle options are catalog-driven.
- [ ] Use typed models for catalog items (`code`, `label`, `active`).
- [ ] Keep compatibility mapping centralized.
- [ ] Avoid duplicated mapping logic across screens.
- [ ] Add/adjust tests for each affected provider/repository.
- [ ] Keep l10n keys aligned in EN and HI.
- [ ] Run lint checks for all touched files.

---

## 7) Slice plan and execution tracker

## Slice A — Material catalog + typeahead

**Goal:** Replace material dropdown with table-backed typeahead and remove "other".  
**Pre-req:** materials table + search RPC ready.

- [ ] Backend: materials schema + index + search RPC.
- [ ] Flutter: typeahead field in Cargo Details.
- [ ] Provider: `materialCode` + strict validation.
- [ ] Smoke tests complete.
- [ ] Lints/tests pass.

## Slice B — Vehicle selector compact summary + drawer

**Goal:** Preserve vehicle section layout, move heavy selection into drawer.

- [ ] Build summary tile + edit drawer flow.
- [ ] Keep compact in-card state.
- [ ] W/T notation validated in labels.
- [ ] Smoke tests complete.
- [ ] Lints/tests pass.

## Slice C — Find Loads filter parity (compact pinned + drawer)

**Goal:** Same visual pattern as today, richer data via drawer.

- [ ] Keep Any default.
- [ ] Add summary chips and drawer edit.
- [ ] Ensure explicit apply flow.
- [ ] Smoke tests complete.
- [ ] Lints/tests pass.

## Slice D — Fleet add/edit + verification alignment

**Goal:** Truck data model aligns with load matching model.

- [ ] Fleet forms support category/body/config/passing fields.
- [ ] Verification truck section aligned.
- [ ] Save/edit operations stable.
- [ ] Smoke tests complete.
- [ ] Lints/tests pass.

## Slice E — Detail/cards/TTS/share/admin alignment

**Goal:** Unified rendering and semantics across all read surfaces.

- [ ] Load cards use normalized summary + W/T labels.
- [ ] Load details aligned for supplier/trucker.
- [ ] TTS and share text updated.
- [ ] Admin labels resolved via catalog.
- [ ] Smoke tests complete.
- [ ] Lints/tests pass.

---

## 8) Pre-merge checklist for every LOADPOST-2 PR/commit

- [ ] Scope is single slice or clearly bounded.
- [ ] No unrelated files changed.
- [ ] Rollback instructions updated if needed.
- [ ] Smoke tests documented in commit notes.
- [ ] No pending critical TODOs left in code.

---

## 9) Notes log

Use this section to append quick run notes per day/slice:

- 2026-06-02: Initialized LOADPOST-2 execution checklist and rollback baseline.
