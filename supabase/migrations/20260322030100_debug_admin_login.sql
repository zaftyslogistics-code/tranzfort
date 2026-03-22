-- Migration: Add diagnostic RPC for admin login debugging
-- Created: March 22, 2026

-- Create a function to verify admin login state
CREATE OR REPLACE FUNCTION public.debug_admin_login(p_email TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_auth_user_id UUID;
    v_admin_row JSONB;
    v_is_admin_result BOOLEAN;
BEGIN
    -- Find auth user by email (from auth.users via auth.identities or auth.users lookup)
    -- Note: We can't directly query auth.users from client, but we can check if the user exists in admin_users
    -- by trying to match against auth.uid() when called from authenticated context
    
    -- Get current auth uid (will be null if not authenticated)
    v_auth_user_id := auth.uid();
    
    -- Check admin_users for this auth uid
    SELECT jsonb_build_object(
        'id', id,
        'email', email,
        'role', role,
        'is_active', is_active,
        'auth_user_id', auth_user_id
    ) INTO v_admin_row
    FROM admin_users
    WHERE auth_user_id = v_auth_user_id;
    
    -- Test is_admin() function
    v_is_admin_result := is_admin();
    
    RETURN jsonb_build_object(
        'current_auth_uid', v_auth_user_id,
        'admin_row_found', v_admin_row IS NOT NULL,
        'admin_row', v_admin_row,
        'is_admin_result', v_is_admin_result,
        'email_requested', p_email
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.debug_admin_login(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.debug_admin_login(TEXT) TO anon;

-- Create a more permissive RLS policy for admin_users during login
-- Drop existing restrictive policy if still exists
DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;

-- Policy: Allow authenticated users to read their own row
CREATE POLICY "admin_users_select_own" ON admin_users
  FOR SELECT
  USING (auth_user_id = auth.uid());

-- Also update the is_admin function to be more robust
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
