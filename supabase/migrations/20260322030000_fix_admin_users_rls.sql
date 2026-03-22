-- Migration: Fix admin_users RLS policy for login
-- Created: March 22, 2026
-- Purpose: Allow authenticated users to read their own admin_users row during login

-- Drop the restrictive policy
DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;

-- Create a new policy that allows authenticated users to read their own row
-- This is needed for the login flow where we verify admin access
CREATE POLICY "admin_users_select_own" ON admin_users
  FOR SELECT
  USING (auth_user_id = auth.uid());

-- Also allow admins to read all admin rows (for admin management features)
CREATE POLICY "admin_users_admin_select_all" ON admin_users
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE auth_user_id = auth.uid()
        AND is_active = TRUE
        AND role = 'super_admin'
    )
  );

-- Grant appropriate permissions
GRANT SELECT ON admin_users TO authenticated;
