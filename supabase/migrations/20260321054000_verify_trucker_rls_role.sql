-- ============================================================================
-- VERIFY AND FIX TRUCKER ROLE FOR RLS - 21 March 2026
-- The loads_trucker_select RLS policy requires user_role_type = 'trucker'
-- ============================================================================

-- Fix trucker profile to ensure role is set correctly
DO $$
DECLARE
  v_trucker_id UUID;
BEGIN
  -- Find trucker user
  SELECT id INTO v_trucker_id 
  FROM auth.users 
  WHERE email = 'trucker@example.com';
  
  IF v_trucker_id IS NULL THEN
    RAISE NOTICE 'Trucker user not found';
    RETURN;
  END IF;
  
  -- Ensure profile has correct role
  UPDATE profiles 
  SET user_role_type = 'trucker',
      verification_status = COALESCE(verification_status, 'unverified'),
      full_name = COALESCE(full_name, 'Test Trucker'),
      mobile = COALESCE(mobile, '9876543211')
  WHERE id = v_trucker_id;
  
  -- If no profile exists, create one
  IF NOT FOUND THEN
    INSERT INTO profiles (id, full_name, mobile, user_role_type, verification_status, created_at)
    VALUES (v_trucker_id, 'Test Trucker', '9876543211', 'trucker', 'unverified', NOW());
  END IF;
  
  RAISE NOTICE 'Trucker profile verified for %', v_trucker_id;
END $$;

-- Also verify supplier profile
DO $$
DECLARE
  v_supplier_id UUID;
BEGIN
  SELECT id INTO v_supplier_id 
  FROM auth.users 
  WHERE email = 'supplier@example.com';
  
  IF v_supplier_id IS NULL THEN
    RAISE NOTICE 'Supplier user not found';
    RETURN;
  END IF;
  
  UPDATE profiles 
  SET user_role_type = 'supplier',
      verification_status = COALESCE(verification_status, 'unverified'),
      full_name = COALESCE(full_name, 'Test Supplier'),
      mobile = COALESCE(mobile, '9876543210')
  WHERE id = v_supplier_id;
  
  IF NOT FOUND THEN
    INSERT INTO profiles (id, full_name, mobile, user_role_type, verification_status, created_at)
    VALUES (v_supplier_id, 'Test Supplier', '9876543210', 'supplier', 'unverified', NOW());
  END IF;
  
  RAISE NOTICE 'Supplier profile verified for %', v_supplier_id;
END $$;
