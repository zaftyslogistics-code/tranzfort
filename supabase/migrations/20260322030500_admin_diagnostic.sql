-- Migration: Comprehensive admin login diagnostic and fix
-- Created: March 22, 2026

-- Create a diagnostic function that will check all aspects of admin login
CREATE OR REPLACE FUNCTION public.diagnose_admin_login(p_email TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_result JSONB := '{}';
    v_admin_row RECORD;
    v_count INT;
BEGIN
    -- Check 1: Does any admin user exist?
    SELECT COUNT(*) INTO v_count FROM admin_users;
    v_result := v_result || jsonb_build_object('total_admin_users', v_count);
    
    -- Check 2: Find admin by email (bypassing RLS with SECURITY DEFINER)
    SELECT * INTO v_admin_row
    FROM admin_users
    WHERE email = p_email;
    
    IF v_admin_row IS NULL THEN
        v_result := v_result || jsonb_build_object('admin_found', false);
        
        -- List all admin emails for debugging
        v_result := v_result || jsonb_build_object(
            'all_admin_emails', 
            (SELECT jsonb_agg(email) FROM admin_users)
        );
    ELSE
        v_result := v_result || jsonb_build_object(
            'admin_found', true,
            'admin_id', v_admin_row.id,
            'admin_email', v_admin_row.email,
            'admin_role', v_admin_row.role,
            'admin_is_active', v_admin_row.is_active,
            'admin_auth_user_id', v_admin_row.auth_user_id::TEXT
        );
    END IF;
    
    -- Check 3: RLS policies on admin_users
    v_result := v_result || jsonb_build_object(
        'rls_enabled', (
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'admin_users'
        )
    );
    
    -- Check 4: List all RLS policies on admin_users
    v_result := v_result || jsonb_build_object(
        'rls_policies', (
            SELECT jsonb_agg(jsonb_build_object(
                'name', polname,
                'cmd', polcmd,
                'permissive', polpermissive
            ))
            FROM pg_policy
            WHERE polrelid = 'admin_users'::regclass
        )
    );
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.diagnose_admin_login(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.diagnose_admin_login(TEXT) TO authenticated;

-- Create RPC that app can call to verify admin access safely
CREATE OR REPLACE FUNCTION public.verify_admin_after_auth(p_auth_user_id UUID)
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

GRANT EXECUTE ON FUNCTION public.verify_admin_after_auth(UUID) TO anon;
GRANT EXECUTE ON FUNCTION public.verify_admin_after_auth(UUID) TO authenticated;

-- Ensure the most permissive RLS policy exists
-- This allows any authenticated user to read their own row
DROP POLICY IF EXISTS "admin_users_select_self" ON admin_users;
DROP POLICY IF EXISTS "admin_users_select_own" ON admin_users;
DROP POLICY IF EXISTS "admin_users_admin_select" ON admin_users;

CREATE POLICY "admin_users_self_select" ON admin_users
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Re-enable RLS to be sure
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Grant select permission explicitly
GRANT SELECT ON admin_users TO authenticated;
