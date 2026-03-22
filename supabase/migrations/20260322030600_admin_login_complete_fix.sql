-- Migration: FINAL FIX for admin login
-- Created: March 22, 2026
-- Purpose: Fix RLS circular dependency preventing admin login

-- ============================================
-- STEP 1: Clean up - Drop ALL conflicting policies
-- ============================================
DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_self" ON admin_users;
DROP POLICY IF EXISTS "admin_users_self_select" ON admin_users;
DROP POLICY IF EXISTS "admin_users_admin_select_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_select_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_insert" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_read_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_read_own" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_by_auth_id" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_by_email" ON admin_users;

-- ============================================
-- STEP 2: Ensure RLS is enabled
-- ============================================
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 3: Create CORRECT RLS policies
-- ============================================

-- Policy 1: Users can read their own row by auth_user_id
-- This is the KEY fix - allows login verification
CREATE POLICY "admin_users_own_read" ON admin_users
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Policy 2: Super admins can read ALL admin rows
CREATE POLICY "admin_users_super_read" ON admin_users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users self
      WHERE self.auth_user_id = auth.uid()
        AND self.is_active = TRUE
        AND self.role = 'super_admin'
    )
  );

-- ============================================
-- STEP 4: Create/replace helper functions
-- ============================================

-- Function to check if user is admin (for other RLS policies)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users
    WHERE auth_user_id = auth.uid()
      AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify admin after auth (used by Admin app)
-- This bypasses RLS completely via SECURITY DEFINER
CREATE OR REPLACE FUNCTION verify_admin_after_auth(p_auth_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'found', true,
    'role', role,
    'is_active', is_active,
    'email', email
  ) INTO v_result
  FROM admin_users
  WHERE auth_user_id = p_auth_user_id
    AND is_active = true;
  
  IF v_result IS NULL THEN
    RETURN jsonb_build_object('found', false);
  END IF;
  
  RETURN v_result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION verify_admin_after_auth(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION verify_admin_after_auth(UUID) TO anon;

-- ============================================
-- STEP 5: Grant table permissions
-- ============================================
GRANT SELECT ON admin_users TO authenticated;
GRANT UPDATE (is_active, role) ON admin_users TO authenticated;

-- ============================================
-- STEP 6: Verify admin user exists (create if missing)
-- ============================================

-- Note: This requires the auth user to already exist in auth.users
-- If zaftyslogistics@gmail.com doesn't exist in auth.users, 
-- admin must sign up via Supabase Auth first, then insert here

-- Check if our admin user exists
DO $$
DECLARE
  v_auth_uid UUID;
BEGIN
  -- Try to find the auth user by email
  SELECT id INTO v_auth_uid
  FROM auth.users
  WHERE email = 'zaftyslogistics@gmail.com';
  
  IF v_auth_uid IS NOT NULL THEN
    -- Check if admin_users row exists
    IF NOT EXISTS (
      SELECT 1 FROM admin_users WHERE email = 'zaftyslogistics@gmail.com'
    ) THEN
      -- Create admin user
      INSERT INTO admin_users (
        auth_user_id,
        full_name,
        email,
        role,
        is_active,
        created_by
      ) VALUES (
        v_auth_uid,
        'Super Admin',
        'zaftyslogistics@gmail.com',
        'super_admin',
        true,
        NULL
      );
      
      RAISE NOTICE 'Created admin user for zaftyslogistics@gmail.com';
    ELSE
      RAISE NOTICE 'Admin user already exists for zaftyslogistics@gmail.com';
    END IF;
  ELSE
    RAISE NOTICE 'Auth user zaftyslogistics@gmail.com not found in auth.users - need to sign up first';
  END IF;
END $$;
