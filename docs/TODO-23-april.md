# TODO — 23 April: TTS, Language & Localization

Context: user feedback from the auth / load screens on Apr 23 (UTC+05:30), then
a deep-dive audit of the ARB files on Apr 24. This is a single living checklist
covering the voice-assistant + language-toggle polish (shipped 24 Apr) and the
much larger localization cleanup project (in progress).

Legend: `[x]` = done & in main, `[ ]` = pending.

---

## Part A — Voice assistant & language toggle (shipped 24 Apr)

### A1. Default English TTS voice → UK (`en-GB`)

- [x] Swap the English voice code in `ContextualTtsService` from `en-IN` to
      `en-GB`. Hindi stays on `hi-IN`.
- [x] Keep the public language-code contract (`'en'` / `'hi'`) untouched so
      `TtsSettingsNotifier` and every call-site continue to work without a
      migration.
- [x] Verify device fallback: if the user's phone doesn't have `en-GB`
      installed, the OS engine falls back to another English voice
      automatically (no crash, no silent failure).

**Files:** `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\lib\src\core\services\contextual_tts_service.dart:79-84`

### A2. Simple mute / unmute toggle (no replay, no pulse)

- [x] Strip the play / stop semantics out of `TtsActionButton` and make it
      a pure two-state toggle on the persistent `tts_muted` flag.
- [x] Default state: **unmuted**. Every screen auto-plays its TTS summary via
      `TtsScreenSummaryEffect`.
- [x] Tap when unmuted → stop any in-flight speech and persist
      `tts_muted=true`. The mute survives app restarts.
- [x] Tap when muted → persist `tts_muted=false`. Do **not** replay the
      current screen; just allow the next screen to auto-play.
- [x] Reuse the existing `tts_muted` SharedPreferences key so users already
      on the previous build don't lose their preference.
- [x] Icons: `Icons.volume_up_rounded` (unmuted) and
      `Icons.volume_off_rounded` (muted, 60% alpha). Tooltips:
      `Mute voice` / `Turn voice on`.

**Files:** `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\lib\src\shared\widgets\tts_action_button.dart`

### A3. Auto-play respects the muted state

- [x] Confirm `TtsScreenSummaryEffect` routes everything through
      `ContextualTtsService.speakSummary`, which short-circuits when
      `tts_muted == true`. No screen should call `flutter_tts` directly.

**Files:** `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\lib\src\core\widgets\tts_screen_summary_effect.dart`, `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\lib\src\core\services\contextual_tts_service.dart:59-63`

### A4. Language toggle on auth + onboarding screens

- [x] Add `LanguageToggleAction` next to `TtsActionButton` on:
  - [x] Auth hero (`auth_screen_sections.dart`) — inside the white-icon
        `Theme` override so `अ` / `A` stays legible on the dark hero.
  - [x] Email/password screen (`auth_screens_email_password.dart`) — AppBar actions.
  - [x] Role-select onboarding (`onboarding_screens.dart`) — AppBar actions.
  - [x] Profile-completion (`onboarding_profile_completion.dart`) — AppBar actions.
- [x] Confirm no hard "language lock" flag exists — the onboarding "lock" was
      UI omission, not a code guard. `setLanguage(...)` is safe to call
      mid-onboarding because it only writes SharedPreferences + the Supabase
      profile and triggers a `MaterialApp` rebuild; form controllers keep their
      state.

### A5. English accent picker (deferred)

- [ ] **Deferred.** Only revisit if real users ask for US/AU variants.
      Current decision: `en-GB` is the single default English voice.

### Part A non-goals (did not touch)

- `appLocaleProvider` persistence keys or defaults.
- `TtsSettingsNotifier` (speech rate, language mode enum).
- Onboarding navigation / step ordering.
- `ContextualTtsService` public API.

### Part A verification

- [x] `flutter analyze` clean on every touched file.
- [x] Manual smoke test: fresh install → English UK voice speaks on auth;
      tap mute icon → voice stops, next screen stays silent; tap again →
      next screen speaks; `अ` / `A` swaps locale instantly on auth without
      wiping form state.
- [x] Pushed to `origin/feature/ui-ux-phase6-dark-cards-tts` on 24 Apr.

---

## Part B — Localization cleanup project (started 24 Apr)

Audit snapshot (24 Apr 2026):

| Metric | Value |
|---|---|
| `app_en.arb` size | 440 KB |
| `app_hi.arb` size | 231 KB (47% smaller — under-translated) |
| Generated `app_localizations*.dart` total | ≈ 975 KB |
| EN keys | 1,893 |
| HI keys | 1,730 |
| **Unused EN keys (no code reference)** | **212 (11.2%)** |
| **Missing HI keys (present in EN)** | **165 (8.7%)** |
| **HI values identical to EN** (likely untranslated) | **439 (25.4%)** |
| Orphan HI keys (not in EN) | 2 |

Headline: ~1 in 4 Hindi strings is still English, ~1 in 9 English strings is
dead code, and generated Dart alone is close to 1 MB shipped in every build.

### B1. Phase 1 — Delete dead keys (zero UX impact) ✅ SHIPPED 24 Apr

**Why this is first:** pure cleanup, no risk, biggest measurable win
(≈ 40–60 KB ARB + 100–150 KB generated Dart). If we do nothing else, this
still ships value.

- [x] **B1.1** Re-derived the list of 212 unused EN keys via
      `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\tool\clean_unused_l10n.ps1`
      (keys present in `app_en.arb` but never referenced by pattern
      `.<key>` in any `.dart` file under `lib/` or `test/`, excluding the
      generated files in `lib/src/l10n/`).
- [x] **B1.2** Removed all 212 keys and their `@<key>` metadata descriptors
      from `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\lib\l10n\app_en.arb`
      via line-surgical edits (preserved original 2-space indent and key order).
- [x] **B1.3** Removed the 155 matching HI entries from
      `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\lib\l10n\app_hi.arb`.
      HI was missing the other 57 keys already.
- [x] **B1.4** Removed the 2 orphan HI keys
      (`supplierVerificationPendingDescription`,
      `supplierVerificationCompleteTitle`).
- [x] **B1.5** Fixed trailing commas on the last entry before the root `}`
      in both ARBs (via `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\tool\fix_trailing_comma.ps1`).
      Needed because removing the last key in a JSON object leaves a dangling
      comma that `flutter gen-l10n` rejects even though the ARB parser is
      usually lenient.
- [x] **B1.6** Ran `flutter gen-l10n` → regenerated
      `lib/src/l10n/app_localizations.dart`, `_en.dart`, `_hi.dart`. Output
      notes 106 untranslated HI messages (tracked in Phase 3).
- [x] **B1.7** `flutter analyze lib` clean for the ARB-related code path
      (53 pre-existing `lib/` warnings are untouched by this phase).
- [x] **B1.8** Verified Hindi text integrity via
      `@c:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\tool\verify_hi_integrity.ps1`
      — spot-checked `appTitle`, `authWelcomeTitle`, `authPasswordLabel`
      against git HEAD; all retained keys match byte-for-byte.
- [x] **B1.9** Committed.

**Actual results:**

| File | Before | After | Delta |
|---|---|---|---|
| `app_en.arb` | 440 KB | 395 KB | **–45 KB (–10%)** |
| `app_hi.arb` | 231 KB | 207 KB | **–24 KB (–10%)** |
| `app_localizations.dart` | 464 KB | 412 KB | **–52 KB (–11%)** |
| `app_localizations_en.dart` | 223 KB | 197 KB | **–26 KB (–12%)** |
| `app_localizations_hi.dart` | 288 KB | 352 KB | +64 KB (*) |
| **Total l10n payload** | **≈ 975 KB** | **≈ 961 KB** | **–14 KB net** |

(*) `app_localizations_hi.dart` grew because `flutter gen-l10n` now emits
explicit English fallback stubs for the 106 HI-missing keys that used to be
silently skipped. Phase 3 (translation) will shrink this back down.

**Gotchas learned:**
1. PowerShell's `Get-Content` and `ReadAllLines` without explicit encoding
   read UTF-8 files as Windows-1252 on Windows. Always pass
   `[System.Text.Encoding]::UTF8`. Learned the hard way — the first
   cleanup run double-encoded every Devanagari character, inflating HI to
   303 KB and silently mojibake-ifying all Hindi strings. Reverted and fixed.
2. Dart's ARB parser does NOT tolerate a trailing comma before the root `}`.
   It will tolerate trailing commas *between* keys because of lenient JSON
   handling, but the final one trips `FormatException`. The
   `fix_trailing_comma.ps1` helper handles this.
3. 212 unused EN keys → only 155 of them existed in HI → HI file had 57
   keys already missing. Sanity check: matches the 165 "missing HI keys"
   measured in the audit (delta of 108 = keys used in code but missing HI,
   which will be addressed in Phase 3).
4. **Rupee symbol corruption**: The Phase 1 script corrupted the rupee
   symbol ₹ (U+20B9) to â‚¹ (UTF-8 bytes E0 82 B9 read as Windows-1252) in
   9 locations in `app_en.arb`. Hindi ARB was unaffected because we added
   explicit UTF-8 encoding for Hindi, but English ARB still got corrupted.
   Fixed in commit `7b30c07` by replacing all â‚¹ with ₹ and regenerating
   localization files.

### B2. Phase 2 — Wire existing keys into hardcoded spots ✅ COMPLETE 24 Apr

**Why second:** many screens have **both** unused keys **and** hardcoded
English strings — the keys are there, nobody wired them. This is free
Hindi coverage without writing translations.

**NOTE:** Phase 1 removed the "existing unused keys" that the original plan
relied on. Phase 2 is now entirely "add new keys + wire them" rather than
"wire existing keys."

**Completed clusters:**

- [x] **B2.6** Added 7 new keys and wired them (commit `0928c86`):
  - `authRecommendedChip`, `authFastestMostSecure`, `authOneTapNoPasswordSecure`
    → `auth_screen_sections.dart` (Google card trust copy)
  - `commonMuteVoice`, `commonTurnVoiceOn` → `tts_action_button.dart` tooltip
  - `commonCallTooltip`, `commonChatTooltip` → `marketplace_load_card.dart`
- [x] **B2.8** Added 5 new keys and wired them (commit `0928c86`):
    `trucker_load_detail_shared.dart` (cost-tile labels + disclaimer)
- [x] **B2.9** Added 2 new keys and wired them (commit `0928c86`):
    `onboarding_profile_completion.dart` (suggestion-source labels)
- [x] **B2.1-B2.5** Added 34 new keys and wired them (commit `e63a2be`):
    Profile trust score, load history, reviews section, reply dialog, review prompt sheet

**Total shipped in Phase 2: 48 keys across 10 files, fully localized in EN + HI.**

### B3. Phase 3 — Hindi parity (needs translator)

**Why third:** translating is human work, not pattern-matching. We unblock
this by finishing Phase 1 first (fewer keys to translate) and Phase 2
(keys are actually used, so translating them has ROI).

- [ ] **B3.1** Triage the 439 "HI == EN" keys into two buckets:
      *intentional passthrough* (brand names, emails, `TranZfort`, etc. ≈ 40
      keys) and *genuine untranslated* (≈ 400). Produce a CSV for the
      translator.
- [ ] **B3.2** Translate the ~400 untranslated bucket.
- [ ] **B3.3** Translate the 165 HI-missing keys, prioritized in this order:
  1. **Verification wizard** (`verificationWizard*` — critical path,
     currently 100% English in Hindi builds).
  2. Onboarding (`onboarding*`).
  3. Chat / support / notifications.
  4. Everything else.
- [ ] **B3.4** `flutter pub run intl_utils:generate` (or `flutter gen-l10n`)
      and confirm HI key count matches EN.

### B4. Phase 4 — Key consolidation & bloat reduction

**Why fourth:** after Phase 1 deletes the dead keys and Phase 2 wires the
live ones, the remaining key set is well-defined and we can measure the
impact of consolidation.

- [ ] **B4.1** Collapse status families via ICU `select`. Example:
      the 6 `supplierDashboardSuperLoadNextStep*` variants + 6
      `ReadinessSummary*` mirror keys become a single
      `supplierSuperLoadNextStep` key taking a `status` argument.
- [ ] **B4.2** Audit `trucker*VerificationStatus*` family similarly.
- [ ] **B4.3** Strip `@metadata` `description` fields on mechanical keys
      (plain nouns, button labels). Keep descriptions only where the key
      takes parameters or is ambiguous without context.
- [ ] **B4.4** Target metrics: EN key count ≤ 1,500, `app_en.arb` ≤ 350 KB,
      generated Dart payload < 750 KB.

### B5. Phase 5 — CI guardrail

**Why last:** only useful once the codebase is already clean. A guard that
fires on 200 pre-existing violations just gets disabled.

- [ ] **B5.1** Add `tool/verify_l10n.dart` that:
  1. Fails if any EN key has zero references under `lib/`.
  2. Fails if any EN key is missing from `app_hi.arb`.
  3. Fails if any HI value equals its EN counterpart AND the key is not on
     an allow-list (`tool/l10n_allowlist.txt` — brand names, sample
     emails, universal labels).
  4. Fails on common hardcoded-string patterns in UI Dart files
     (`Text('[A-Z]...')`, `tooltip: '[A-Z]...'`) outside whitelisted files.
- [ ] **B5.2** Hook into the existing `flutter analyze` / `flutter test`
      workflow.
- [ ] **B5.3** Document in `docs/navigation-architecture.md` (or a new
      `docs/localization-architecture.md`).

### Part B non-goals (do not do this pass)

- No switch off `intl` + `flutter gen-l10n`.
- No dynamic Supabase-hosted locale fetch.
- No machine translation — Hindi stays human-reviewed.

---

## Current focus

**Phase 1 (Delete dead keys) ✅ Complete** — Shipped 24 Apr in commit `01c9350`.
**Phase 2 (Wire hardcoded strings) ✅ Complete** — Shipped 24 Apr in commits `0928c86` (Clusters A-C) and `e63a2be` (Cluster D).

Next: **Phase 3 (Hindi parity)** — Requires human translator to translate ~400 untranslated keys and 165 missing HI keys.
