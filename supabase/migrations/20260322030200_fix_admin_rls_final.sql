-- Migration: Fix admin_users RLS for login flow
-- Created: March 22, 2026
-- Issue: Admin login fails because RLS policy prevents reading admin_users during login

-- Step 1: Enable RLS on admin_users (ensure it's on)
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop all existing policies on admin_users to start fresh
DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;
DROP POLICY IF EXISTS "admin_users_admin_select_all" ON admin_users;

-- Step 3: Create permissive policy allowing authenticated users to read their own row
-- This is needed for the login flow - after auth.signInWithPassword, we need to verify admin access
CREATE POLICY "admin_users_select_self" ON admin_users
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Step 4: Create policy allowing super_admins to read all admin rows
CREATE POLICY "admin_users_super_select_all" ON admin_users
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

-- Step 5: Create policy allowing super_admins to insert new admins
CREATE POLICY "admin_users_super_insert" ON admin_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users self
      WHERE self.auth_user_id = auth.uid()
        AND self.is_active = TRUE
        AND self.role = 'super_admin'
    )
  );

-- Step 6: Ensure proper grants
GRANT SELECT ON admin_users TO authenticated;
GRANT UPDATE (is_active, role) ON admin_users TO authenticated;

-- Step 7: Verify the is_admin() function is correct
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

COMMENT ON FUNCTION is_admin() IS 'Checks if current user is an active admin';
