-- ============================================================================
-- FIX TEST ACCOUNT DATA - 21 March 2026
-- Ensures supplier@example.com has proper supplier profile record
-- ============================================================================

-- Get the user ID for supplier@example.com and ensure they have a suppliers record
DO $$
DECLARE
  v_supplier_id UUID;
  v_email TEXT := 'supplier@example.com';
BEGIN
  -- Find the supplier user ID
  SELECT id INTO v_supplier_id 
  FROM auth.users 
  WHERE email = v_email;
  
  IF v_supplier_id IS NULL THEN
    RAISE NOTICE 'Supplier user not found in auth.users';
    RETURN;
  END IF;
  
  -- Ensure profile exists with supplier role
  INSERT INTO profiles (id, full_name, mobile, user_role_type, verification_status, created_at)
  VALUES (v_supplier_id, 'Test Supplier', '9876543210', 'supplier', 'unverified', NOW())
  ON CONFLICT (id) DO UPDATE SET
    user_role_type = 'supplier',
    verification_status = COALESCE(profiles.verification_status, 'unverified');
  
  -- Ensure supplier extension record exists (only with existing columns)
  INSERT INTO suppliers (id, company_name, total_loads_posted, active_loads_count)
  VALUES (v_supplier_id, 'Test Supplier Company', 0, 0)
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'Supplier test account data fixed for %', v_email;
END $$;

-- Also ensure trucker@example.com has proper records
DO $$
DECLARE
  v_trucker_id UUID;
  v_email TEXT := 'trucker@example.com';
BEGIN
  -- Find the trucker user ID
  SELECT id INTO v_trucker_id 
  FROM auth.users 
  WHERE email = v_email;
  
  IF v_trucker_id IS NULL THEN
    RAISE NOTICE 'Trucker user not found in auth.users';
    RETURN;
  END IF;
  
  -- Ensure profile exists with trucker role
  INSERT INTO profiles (id, full_name, mobile, user_role_type, verification_status, created_at)
  VALUES (v_trucker_id, 'Test Trucker', '9876543211', 'trucker', 'unverified', NOW())
  ON CONFLICT (id) DO UPDATE SET
    user_role_type = 'trucker',
    verification_status = COALESCE(profiles.verification_status, 'unverified');
  
  -- Ensure trucker extension record exists (only with existing columns)
  INSERT INTO truckers (id, completed_trips)
  VALUES (v_trucker_id, 0)
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'Trucker test account data fixed for %', v_email;
END $$;

-- ============================================================================
-- END OF TEST DATA FIX
-- ============================================================================
