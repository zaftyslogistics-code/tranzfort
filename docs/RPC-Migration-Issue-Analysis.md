# RPC Migration Issue Analysis - May 17, 2026

## Issue Summary
**Problem:** Supplier dashboard "Recent Loads" section showing "Recent Loads Unavailable" after P3.2 RPC migration.

## Root Cause Analysis

### What Was Missing
The `get_supplier_loads_list` RPC migration had a parameter type mismatch issue:
- **RPC expects:** `p_status_filter` as `TEXT[]` (PostgreSQL array) or `NULL`
- **Backend was passing:** Empty array `[]` when `filters.hasStatuses` was true but `statuses` list was empty

### Why It Occurred
1. **Original condition:** `filters.hasStatuses ? filters.statuses : null`
2. **Problem scenario:** When user filters are applied but the filter list is empty (e.g., cleared filters but flag still set)
3. **Result:** Backend passed empty array `[]` to RPC
4. **SQL condition failure:** The SQL check `p_stage_filter = '{}'` may not match the empty array passed from Dart/Supabase client
5. **RPC returns:** Empty result or error, causing "Recent Loads Unavailable"

### How We Fixed It
**Fix applied to:** `supplier_load_repository_backend.dart`

```dart
// Before (incorrect):
'p_status_filter': filters.hasStatuses ? filters.statuses : null

// After (correct):
'p_status_filter': (filters.hasStatuses && filters.statuses.isNotEmpty) ? filters.statuses : null
```

**Additional fix:** Added comprehensive debug logging to help diagnose future RPC failures:
- Log all RPC parameters before call
- Log response type and row count
- Catch and log RPC errors
- This will help identify similar issues quickly

## Codebase Review for Similar Issues

### RPCs Reviewed

| RPC | Array Parameter | Backend Check | Status |
|-----|-----------------|---------------|--------|
| `get_supplier_loads_list` | `p_status_filter: TEXT[]` | ✅ Fixed | Was broken |
| `get_trucker_trips` | `p_stage_filter: TEXT[]` | ✅ Already correct | Good |
| `get_supplier_load_detail` | No arrays | N/A | Good |
| `get_supplier_linked_trips` | No arrays | N/A | Good |
| `get_trip_detail` | No arrays | N/A | Good |
| `update_trip_lr` | No arrays | N/A | Good |
| `get_own_rating` | No arrays | N/A | Good |
| `get_support_tickets` | No arrays | N/A | Good |
| `get_support_ticket_detail` | No arrays | N/A | Good |
| `get_support_ticket_messages` | No arrays | N/A | Good |
| `get_current_user_profile` | No arrays | N/A | Good |
| `record_user_consent` | No arrays | N/A | Good |
| `get_supplier_extension` | No arrays | N/A | Good |

### Detailed Findings

#### ✅ `get_trucker_trips` (P3.4.1)
**Backend code:** `trucker_trip_repository_backend.dart`
```dart
'p_stage_filter': stages.isEmpty ? null : stages,
```
**Status:** Already has correct check - no fix needed

#### ✅ Other RPCs
All other RPCs either:
- Have no array parameters (simple UUID, INT, TEXT types)
- Already have correct empty array checks
- Don't have filter parameters at all

## Lessons Learned

### 1. Array Parameter Handling
**Rule:** When passing array parameters to PostgreSQL RPCs from Dart:
- ✅ Pass `null` for empty arrays
- ❌ Never pass empty array `[]` 
- ✅ Check: `array.isNotEmpty ? array : null`

### 2. SQL Array Condition Matching
**Problem:** PostgreSQL array condition `p_filter = '{}'` may not match empty array from Dart
**Solution:** Always pass `null` instead of empty array

### 3. RPC Parameter Validation
**Best practice:** Add validation in backend before calling RPC:
```dart
// Validate array parameters before RPC call
final statusFilter = (filters.hasStatuses && filters.statuses.isNotEmpty) 
    ? filters.statuses 
    : null;
```

### 4. Debug Logging
**Critical:** Add debug logging for all RPC calls:
- Log parameters before call
- Log response type and count
- Catch and log errors
- Helps diagnose issues quickly in production

## Recommendations

### Immediate Actions
1. ✅ Fix applied to `get_supplier_loads_list`
2. ✅ Debug logging added to `fetchMyLoads`
3. ✅ Similar RPCs reviewed - no other issues found

### Future RPC Migrations
When creating new RPCs with array parameters:
1. **In SQL:** Use `p_filter IS NULL` instead of `p_filter = '{}'`
2. **In Dart:** Always check `array.isNotEmpty` before passing
3. **In Testing:** Test with empty array scenario
4. **In Logging:** Add comprehensive debug logging

### Code Review Checklist
- [ ] All RPC calls with array parameters have `isNotEmpty` check
- [ ] Debug logging added to all new RPC backend methods
- [ ] Empty array scenarios tested
- [ ] SQL conditions use `IS NULL` instead of `= '{}'`

## Files Modified

1. `TranZfort/lib/src/features/supplier/data/supplier_load_repository_backend.dart`
   - Fixed array parameter check
   - Added debug logging
   - Added error handling

## Testing Plan

1. **Test supplier dashboard with no filters** - Should work
2. **Test supplier dashboard with active filters** - Should work
3. **Test supplier dashboard with cleared filters** - Should work (this was the bug)
4. **Test trucker trips with no stage filters** - Should work
5. **Test trucker trips with stage filters** - Should work
6. **Test trucker trips with cleared stage filters** - Should work
