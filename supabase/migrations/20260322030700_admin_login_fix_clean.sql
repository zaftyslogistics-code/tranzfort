-- Migration: FINAL FIX for admin login - Clean version
-- Created: March 22, 2026

-- Clean up all existing policies (drop if exists handles errors gracefully)
DO $$
BEGIN
  DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_select_self" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_self_select" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_admin_select_all" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_super_select_all" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_super_insert" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_super_read_all" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_read_own" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_own_read" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_super_read" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_select_by_auth_id" ON admin_users;
  DROP POLICY IF EXISTS "admin_users_select_by_email" ON admin_users;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Some policies did not exist, continuing...';
END $$;

-- Enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Create correct policy: Users can read their own row
CREATE POLICY "admin_users_own_read" ON admin_users
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Create policy for super admins to read all
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

-- Fix is_admin function
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

-- Create RPC function for admin verification
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

GRANT EXECUTE ON FUNCTION verify_admin_after_auth(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION verify_admin_after_auth(UUID) TO anon;

-- Grant table permissions
GRANT SELECT ON admin_users TO authenticated;
GRANT UPDATE (is_active, role) ON admin_users TO authenticated;

-- Ensure admin user exists
DO $$
DECLARE
  v_auth_uid UUID;
BEGIN
  SELECT id INTO v_auth_uid
  FROM auth.users
  WHERE email = 'zaftyslogistics@gmail.com';
  
  IF v_auth_uid IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM admin_users WHERE email = 'zaftyslogistics@gmail.com'
    ) THEN
      INSERT INTO admin_users (auth_user_id, full_name, email, role, is_active, created_by)
      VALUES (v_auth_uid, 'Super Admin', 'zaftyslogistics@gmail.com', 'super_admin', true, NULL);
    END IF;
  END IF;
END $$;
