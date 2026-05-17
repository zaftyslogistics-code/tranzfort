# RPC Migration - Staging Validation Plan

**Date:** May 17, 2026
**Branch:** feature/play-store-readiness-2026-05-16
**Build:** Flutter APK with `--dart-define=USE_RPC_MIGRATION=true`

---

## Summary

**RPC Migration Status:**
- ✅ P3.0 - Pre-migration audit & safety measures (COMPLETE)
- ✅ P3.5 - Fleet RPCs (4 RPCs - COMPLETE)
- ✅ P3.8 - Notification RPCs (2 RPCs - COMPLETE)
- ✅ P3.6 - Chat RPCs (2 RPCs - COMPLETE, CRITICAL C-003 FIX)
- ⏳ P3.2 - Supplier Load RPCs (PENDING)
- ⏳ P3.3-P3.4 - Trucker RPCs (PENDING)
- ⏳ P3.7 - Support RPCs (PENDING)
- ⏳ P3.1 - Auth/Profile RPCs (PENDING)

**Total RPCs Created:** 10 (4 Fleet + 2 Notifications + 2 Chat + 2 Rollback)

**Critical Fix:** C-003 Chat Pagination Cursor Bug - Now uses composite cursor `(created_at, id)` instead of two independent filters.

---

## Staging Validation Plan

### 1. Build & Deploy
- ✅ Build APK with `--dart-define=USE_RPC_MIGRATION=true`
- ⏭️ Deploy APK to staging environment
- ⏭️ Verify app launches successfully

### 2. Fleet Feature Validation (P3.5)
**Test Steps:**
- Login as trucker user
- Navigate to Fleet Management screen
- **Test 1:** View fleet list
  - Verify all trucks are displayed
  - Verify pagination works (if fleet has >50 trucks)
- **Test 2:** Add new truck
  - Fill in truck details
  - Submit and verify truck appears in list with 'pending' status
- **Test 3:** Edit verified truck (critical field change)
  - Edit truck number, body type, tyres, or capacity
  - Verify status changes to 'edited_pending_reapproval'
  - Verify verification fields are cleared
- **Test 4:** Archive truck
  - Archive a truck
  - Verify it's excluded from fleet list (RPC filters archived trucks)
- **Test 5:** Reactivate archived truck
  - Reactivate truck
  - Verify status changes to 'pending'

**Expected Behavior:** All fleet operations work correctly with RPCs enabled.

**Rollback Plan:** If issues occur, rebuild with `--dart-define=USE_RPC_MIGRATION=false`.

### 3. Notification Feature Validation (P3.8)
**Test Steps:**
- Ensure user has some notifications
- **Test 1:** View notification list
  - Navigate to Notifications screen
  - Verify all notifications are displayed
  - Verify pagination works (if >30 notifications)
- **Test 2:** View unread count badge
  - Verify unread count is displayed correctly
  - Mark all as read
  - Verify count goes to 0
- **Test 3:** Mark notification as read
  - Tap on a notification
  - Verify it's marked as read
  - Verify unread count decreases

**Expected Behavior:** All notification operations work correctly with RPCs enabled.

**Rollback Plan:** If issues occur, rebuild with `--dart-define=USE_RPC_MIGRATION=false`.

### 4. Chat Feature Validation (P3.6) - CRITICAL C-003 FIX
**Test Steps:**
- Ensure user has active conversations with messages
- **Test 1:** View conversation messages
  - Navigate to a conversation
  - Verify all messages are displayed
  - Verify they're in ascending order (oldest first)
- **Test 2:** Message pagination (CRITICAL FOR C-003)
  - Create multiple messages with identical timestamps (simulate rapid sending)
  - Scroll to load more messages
  - **CRITICAL CHECK:** Verify pagination works correctly even with identical timestamps
  - **CRITICAL CHECK:** Verify no messages are skipped or duplicated
- **Test 3:** Mark messages as read
  - Mark conversation as read
  - Verify all messages from other sender are marked as read
  - Verify read status is persisted

**Expected Behavior:** 
- Pagination works correctly even with identical timestamps (C-003 fix)
- No messages are skipped or duplicated
- Mark as read works correctly

**Rollback Plan:** If issues occur, rebuild with `--dart-define=USE_RPC_MIGRATION=false`.

---

## Success Criteria

### Fleet (P3.5)
- [ ] Fleet list displays correctly
- [ ] Add truck works correctly
- [ ] Edit truck with critical field change changes status to edited_pending_reapproval
- [ ] Archive truck excludes from list
- [ ] Reactivate truck works correctly

### Notifications (P3.8)
- [ ] Notification list displays correctly
- [ ] Pagination works correctly
- [ ] Unread count badge works correctly
- [ ] Mark as read works correctly

### Chat (P3.6) - CRITICAL
- [ ] Messages display correctly in ascending order
- [ ] **Pagination works correctly with identical timestamps (C-003 fix)**
- [ ] **No messages skipped or duplicated during pagination**
- [ ] Mark as read works correctly

---

## Rollback Procedure

If any feature fails validation:

1. **Immediate Rollback:**
   ```bash
   flutter build apk --dart-define=USE_RPC_MIGRATION=false
   ```
   This will disable RPCs and revert to direct table reads.

2. **Investigate Root Cause:**
   - Check Supabase logs for RPC errors
   - Check Flutter logs for RPC call failures
   - Verify migration files were applied correctly in Supabase

3. **Fix and Retest:**
   - Fix the issue in the RPC or migration file
   - Create new migration file if needed
   - Rebuild with RPCs enabled
   - Retest in staging

---

## Post-Validation Decision

### If All Features Pass Validation:
- ✅ Proceed with P3.2 (Supplier Loads) - Core business logic
- ✅ Proceed with P3.3-P3.4 (Trucker) - Core business logic
- ✅ Keep RPCs enabled for all future features

### If Any Feature Fails Validation:
- ⚠️ Rollback to direct table reads for the failing feature
- ⚠️ Investigate and fix the issue
- ⚠️ Retest before proceeding to next feature
- ⚠️ Consider pausing RPC migration until root cause is understood

---

## Notes

- **Feature Flag:** `USE_RPC_MIGRATION=true` enables RPCs, `false` disables them
- **Rollback Migrations:** Available for all 3 features (Fleet, Notifications, Chat)
- **Old Implementations:** Kept as fallback in Dart code
- **Safety:** Feature flag allows instant rollback without code changes

---

## Next Steps After Validation

1. **If validation succeeds:** Continue with P3.2 (Supplier Loads) per gradual rollout strategy
2. **If validation fails:** Investigate, fix, and retest before proceeding
