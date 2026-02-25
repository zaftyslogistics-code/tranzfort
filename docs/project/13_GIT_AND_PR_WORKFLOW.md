# 13: Git, Branching & PR Workflow

**Status:** WORKING
**Audience:** All Developers
**Objective:** Keep development predictable and prevent architectural drift.

---

## 1. Branching

- Default branch: `main`
- Feature branches: `feature/<short-name>`
- Fix branches: `fix/<short-name>`

---

## 2. Commit Messages

Use clear intent-based messages.

- Prefer: `feat: ...`, `fix: ...`, `refactor: ...`, `chore: ...`

---

## 3. Pull Request Rules

### 3.1 PR size

- Prefer small PRs per sprint deliverable.
- Avoid mixing unrelated changes.

### 3.2 PR must include

- What changed
- Manual testing notes
- Screenshots (UI changes)

### 3.3 Required checks

- `flutter analyze` → 0 errors
- `dart format .` applied
- `python scripts/check_layer_boundaries.py` → PASS

---

## 4. Architecture Review Checklist

- UI does not import `supabase_flutter`
- Async state is provider-owned
- Repository returns `Result<T>`
- Errors mapped via `AppFailureType`
- Realtime subscriptions are provider-owned

---

## 5. Merging

- Squash merge preferred unless a PR intentionally contains multiple reviewable commits.
- Do not merge if Sprint DoD is incomplete.
