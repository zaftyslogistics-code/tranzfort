-- P3 RPC Smoke Test — May 17, 2026
-- Run this in Supabase SQL Editor to verify all new RPCs exist and are callable

-- 1. Verify RPCs exist in schema
SELECT 
  proname AS rpc_name,
  pg_get_function_arguments(oid) AS args,
  pg_get_function_result(oid) AS return_type
FROM pg_proc
WHERE proname IN (
  'get_supplier_loads_list',
  'get_supplier_load_detail',
  'get_supplier_linked_trips',
  'get_trucker_trips',
  'get_trip_detail',
  'update_trip_lr',
  'get_own_rating',
  'get_support_tickets',
  'get_support_ticket_detail',
  'get_support_ticket_messages',
  'get_current_user_profile',
  'record_user_consent',
  'get_supplier_extension'
)
ORDER BY proname;

-- Expected: 13 rows, all SECURITY DEFINER

-- 2. Verify get_current_user_profile returns empty when not authenticated
-- (Run this as anon or service role to test auth gate)
-- Should return: ERROR: Authentication required

-- 3. Verify record_user_consent is idempotent
-- (Requires authenticated session)
-- Should succeed or do nothing on duplicate

-- 4. Verify get_supplier_extension returns correct shape
-- SELECT get_supplier_extension('00000000-0000-0000-0000-000000000000'::uuid);
-- Expected: {"id": null, "company_name": null} or valid data

-- 5. Verify get_support_ticket_messages uses composite cursor
-- Check function source contains composite cursor logic:
SELECT prosrc 
FROM pg_proc 
WHERE proname = 'get_support_ticket_messages';
-- Should contain: created_at < p_before_created_at OR (created_at = p_before_created_at AND id < ...)
