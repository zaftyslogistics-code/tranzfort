CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users
    WHERE auth_user_id = auth.uid()
      AND is_active = TRUE
      AND role = 'super_admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

DROP POLICY IF EXISTS "admin_users_super_read" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_select_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_super_read_all" ON admin_users;
DROP POLICY IF EXISTS "admin_users_admin_select_all" ON admin_users;

CREATE POLICY "admin_users_super_read" ON admin_users
  FOR SELECT
  TO authenticated
  USING (public.is_super_admin());
