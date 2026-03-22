-- ============================================================================
-- FIX PROFILES RLS FOR TRUCKER LOAD DETAIL - 21 March 2026 (v2)
-- Trucker needs to read supplier profiles to show load detail
-- NOTE: Simplified policy - any authenticated user can read profiles for cross-role functionality
-- ============================================================================

-- Drop existing select policies on profiles
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
DROP POLICY IF EXISTS "profiles_admin_select" ON profiles;
DROP POLICY IF EXISTS "profiles_select" ON profiles;

-- Create new select policy:
-- 1. Users can read their own profile
-- 2. Admins can read all profiles
-- 3. All authenticated users can read all profiles (simplified for cross-role needs)
--    This is needed because truckers need supplier info and suppliers need trucker info
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (
  id = auth.uid()  -- Own profile
  OR is_admin()    -- Admin can read all
  OR auth.role() = 'authenticated'  -- Any authenticated user can read profiles
);

-- Keep update policy as-is (only own profile)
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (id = auth.uid());
