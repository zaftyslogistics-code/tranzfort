-- Migration: Ensure admin user exists and fix login
-- Created: March 22, 2026

-- First, let's create a function to safely check/create admin access
-- This uses SECURITY DEFINER to bypass RLS completely

-- Function to verify admin access during login (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_admin_for_login(p_email TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Direct query bypassing RLS due to SECURITY DEFINER
    SELECT jsonb_build_object(
        'id', id,
        'email', email,
        'role', role,
        'is_active', is_active,
        'auth_user_id', auth_user_id
    ) INTO v_result
    FROM admin_users
    WHERE email = p_email;
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_admin_for_login(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_for_login(TEXT) TO anon;

-- Ensure RLS is properly configured
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_self" ON admin_users;
DROP POLICY IF EXISTS "admin_users_admin_select_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_select_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_insert" ON admin_users;

-- Create policy: Allow authenticated users to read their own row by auth_user_id
CREATE POLICY "admin_users_select_by_auth_id" ON admin_users
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Create policy: Allow reading own row by email match (for login verification)
CREATE POLICY "admin_users_select_by_email" ON admin_users
  FOR SELECT
  TO authenticated
  USING (email = auth.jwt() ->> 'email');

-- Create policy: Super admins can read all
CREATE POLICY "admin_users_super_read_all" ON admin_users
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

-- Grant permissions
GRANT SELECT ON admin_users TO authenticated;
GRANT UPDATE (is_active, role) ON admin_users TO authenticated;

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
