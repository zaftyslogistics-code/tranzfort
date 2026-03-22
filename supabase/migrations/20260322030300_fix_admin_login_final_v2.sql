-- Migration: Final fix for admin login with comprehensive verification
-- Created: March 22, 2026

-- Step 1: Drop ALL existing policies on admin_users
DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;
DROP POLICY IF EXISTS "admin_users_admin_select_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_self" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_select_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_insert" ON admin_users;

-- Step 2: Disable RLS temporarily to verify data (we'll re-enable with correct policy)
ALTER TABLE admin_users DISABLE ROW LEVEL SECURITY;

-- Step 3: Ensure is_admin() function works correctly
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

-- Step 4: Re-enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Step 5: Create policy allowing authenticated users to read their own row
-- This is the KEY fix - users need to read their own row to verify admin status
CREATE POLICY "admin_users_select_self" ON admin_users
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Step 6: Create policy allowing super_admins to read all rows
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

-- Step 7: Grant proper permissions
GRANT SELECT ON admin_users TO authenticated;
GRANT UPDATE (is_active, role) ON admin_users TO authenticated;

-- Step 8: Create a function to safely verify admin access during login
-- This function uses SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION public.verify_admin_access(p_auth_user_id UUID)
RETURNS TABLE (
  role TEXT,
  is_active BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.role::TEXT,
    au.is_active
  FROM admin_users au
  WHERE au.auth_user_id = p_auth_user_id
  LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_admin_access(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_admin_access(UUID) TO anon;
