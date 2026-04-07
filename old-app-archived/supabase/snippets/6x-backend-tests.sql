-- 6.x backend/Supabase checks (local only)
BEGIN;

CREATE TEMP TABLE test_ids AS
SELECT
  gen_random_uuid() AS supplier_id,
  gen_random_uuid() AS trucker_id,
  gen_random_uuid() AS admin_auth_id,
  gen_random_uuid() AS admin_id,
  gen_random_uuid() AS truck_id,
  gen_random_uuid() AS load_id,
  gen_random_uuid() AS super_load_id;

-- Seed auth users (profiles auto-created via trigger)
INSERT INTO auth.users (id, aud, role, email, raw_user_meta_data, created_at, updated_at)
SELECT supplier_id, 'authenticated', 'authenticated',
       'supplier_test@local',
       jsonb_build_object('full_name', 'Supplier Test'),
       now(), now()
FROM test_ids;

INSERT INTO auth.users (id, aud, role, email, raw_user_meta_data, created_at, updated_at)
SELECT trucker_id, 'authenticated', 'authenticated',
       'trucker_test@local',
       jsonb_build_object('full_name', 'Trucker Test'),
       now(), now()
FROM test_ids;

INSERT INTO auth.users (id, aud, role, email, raw_user_meta_data, created_at, updated_at)
SELECT admin_auth_id, 'authenticated', 'authenticated',
       'admin_test@local',
       jsonb_build_object('full_name', 'Admin Test'),
       now(), now()
FROM test_ids;

-- Ensure profiles exist (6.6 handle_new_auth_user)
DO $$
DECLARE
  ids RECORD;
  profile_count int;
BEGIN
  SELECT * INTO ids FROM test_ids;
  SELECT count(*) INTO profile_count
  FROM public.profiles
  WHERE id IN (ids.supplier_id, ids.trucker_id, ids.admin_auth_id);
  IF profile_count <> 3 THEN
    RAISE EXCEPTION 'handle_new_auth_user failed, profiles created: %', profile_count;
  END IF;
END $$;

UPDATE public.profiles
SET user_role_type = 'supplier', verification_status = 'verified', full_name = 'Supplier Test'
WHERE id = (SELECT supplier_id FROM test_ids);

UPDATE public.profiles
SET user_role_type = 'trucker', verification_status = 'verified', full_name = 'Trucker Test'
WHERE id = (SELECT trucker_id FROM test_ids);

INSERT INTO public.suppliers (id, company_name)
SELECT supplier_id, 'Test Logistics'
FROM test_ids;

INSERT INTO public.truckers (id, dl_number)
SELECT trucker_id, 'DL123'
FROM test_ids;

INSERT INTO public.admin_users (id, auth_user_id, full_name, email, role, is_active)
SELECT admin_id, admin_auth_id, 'Admin Test', 'admin_test@local', 'super_admin', true
FROM test_ids;

INSERT INTO public.trucks (
  id,
  owner_id,
  truck_number,
  body_type,
  tyres,
  capacity_tonnes,
  status
)
SELECT
  truck_id,
  trucker_id,
  'TESTTRUCK1',
  'open',
  10,
  18,
  'verified'
FROM test_ids;

INSERT INTO public.loads (
  id,
  supplier_id,
  origin_city,
  origin_state,
  dest_city,
  dest_state,
  material,
  weight_tonnes,
  price,
  pickup_date,
  status,
  trucks_needed,
  trucks_booked,
  required_truck_type,
  is_super_load,
  super_status
)
SELECT
  load_id,
  supplier_id,
  'Mumbai',
  'MH',
  'Pune',
  'MH',
  'Steel',
  12,
  15000,
  current_date + 1,
  'active',
  1,
  0,
  'open',
  false,
  'none'
FROM test_ids;

INSERT INTO public.loads (
  id,
  supplier_id,
  origin_city,
  origin_state,
  dest_city,
  dest_state,
  material,
  weight_tonnes,
  price,
  pickup_date,
  status,
  trucks_needed,
  trucks_booked,
  required_truck_type,
  is_super_load,
  super_status
)
SELECT
  super_load_id,
  supplier_id,
  'Delhi',
  'DL',
  'Jaipur',
  'RJ',
  'Cement',
  16,
  22000,
  current_date + 2,
  'active',
  1,
  0,
  'open',
  true,
  'requested'
FROM test_ids;

-- 6.1 book_load RPC
DO $$
DECLARE
  ids RECORD;
  result jsonb;
BEGIN
  SELECT * INTO ids FROM test_ids;
  result := public.book_load(ids.load_id, ids.trucker_id, ids.truck_id);
  IF result->>'success' <> 'true' THEN
    RAISE EXCEPTION 'book_load failed: %', result;
  END IF;
END $$;

-- 6.2 admin_force_assign_super_load RPC
DO $$
DECLARE
  ids RECORD;
  result jsonb;
BEGIN
  SELECT * INTO ids FROM test_ids;
  result := public.admin_force_assign_super_load(
    ids.super_load_id,
    ids.trucker_id,
    ids.truck_id,
    ids.admin_id
  );
  IF result->>'success' <> 'true' THEN
    RAISE EXCEPTION 'admin_force_assign_super_load failed: %', result;
  END IF;
END $$;

-- 6.3 get_loads_assigned_to_trucker RPC
DO $$
DECLARE
  ids RECORD;
  load_count int;
BEGIN
  SELECT * INTO ids FROM test_ids;
  SELECT count(*) INTO load_count
  FROM public.get_loads_assigned_to_trucker(ids.trucker_id, NULL);
  IF load_count < 1 THEN
    RAISE EXCEPTION 'get_loads_assigned_to_trucker returned no rows';
  END IF;
END $$;

-- 6.4/6.5 RLS checks (profiles + loads)
DO $$
DECLARE
  ids RECORD;
  own_count int;
  other_count int;
  row_count int;
BEGIN
  SELECT * INTO ids FROM test_ids;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', ids.supplier_id::text, true);

  SELECT count(*) INTO own_count FROM public.profiles WHERE id = ids.supplier_id;
  SELECT count(*) INTO other_count FROM public.profiles WHERE id = ids.trucker_id;
  IF own_count <> 1 OR other_count <> 0 THEN
    RAISE EXCEPTION 'Profiles RLS failed (own %, other %)', own_count, other_count;
  END IF;

  PERFORM set_config('request.jwt.claim.sub', ids.trucker_id::text, true);
  UPDATE public.loads SET status = 'cancelled' WHERE id = ids.load_id;
  GET DIAGNOSTICS row_count = ROW_COUNT;
  IF row_count <> 0 THEN
    RAISE EXCEPTION 'Loads RLS failed (trucker updated supplier load)';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', ids.supplier_id::text, true);
  UPDATE public.loads SET status = 'active' WHERE id = ids.load_id;
  GET DIAGNOSTICS row_count = ROW_COUNT;
  IF row_count <> 1 THEN
    RAISE EXCEPTION 'Loads RLS failed (supplier update blocked)';
  END IF;

  EXECUTE 'RESET ROLE';
END $$;

-- 6.7 in-app notifications trigger
DO $$
DECLARE
  ids RECORD;
  notif_count int;
BEGIN
  SELECT * INTO ids FROM test_ids;
  SELECT count(*) INTO notif_count
  FROM public.notifications
  WHERE user_id = ids.supplier_id
    AND type = 'booking_new';
  IF notif_count < 1 THEN
    RAISE EXCEPTION 'Notification trigger did not fire (booking_new)';
  END IF;
END $$;

-- Cleanup
DELETE FROM public.notifications
WHERE user_id IN (SELECT supplier_id FROM test_ids)
   OR user_id IN (SELECT trucker_id FROM test_ids);

DELETE FROM public.trips
WHERE trucker_id IN (SELECT trucker_id FROM test_ids)
   OR load_id IN (SELECT load_id FROM test_ids)
   OR load_id IN (SELECT super_load_id FROM test_ids);

DELETE FROM public.loads
WHERE supplier_id IN (SELECT supplier_id FROM test_ids)
   OR assigned_trucker_id IN (SELECT trucker_id FROM test_ids)
   OR parent_load_id IN (SELECT load_id FROM test_ids)
   OR parent_load_id IN (SELECT super_load_id FROM test_ids)
   OR id IN (SELECT load_id FROM test_ids)
   OR id IN (SELECT super_load_id FROM test_ids);

DELETE FROM public.trucks
WHERE owner_id IN (SELECT trucker_id FROM test_ids)
   OR id IN (SELECT truck_id FROM test_ids);

DELETE FROM public.suppliers
WHERE id IN (SELECT supplier_id FROM test_ids);

DELETE FROM public.truckers
WHERE id IN (SELECT trucker_id FROM test_ids);

DELETE FROM public.admin_users
WHERE id IN (SELECT admin_id FROM test_ids)
   OR auth_user_id IN (SELECT admin_auth_id FROM test_ids);

DELETE FROM public.profiles
WHERE id IN (
  SELECT supplier_id FROM test_ids
  UNION ALL
  SELECT trucker_id FROM test_ids
  UNION ALL
  SELECT admin_auth_id FROM test_ids
);

DELETE FROM auth.users
WHERE id IN (
  SELECT supplier_id FROM test_ids
  UNION ALL
  SELECT trucker_id FROM test_ids
  UNION ALL
  SELECT admin_auth_id FROM test_ids
);

COMMIT;
