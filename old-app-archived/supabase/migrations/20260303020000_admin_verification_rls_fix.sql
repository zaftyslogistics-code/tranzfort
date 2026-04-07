-- Fix Admin verification queue access:
-- 1) Allow active admins to read profiles for supplier/trucker verification queues.
-- 2) Allow active admins to update profiles (approve/reject verification_status).
-- 3) Allow active admins to update trucks (approve/reject status).

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'Active admins can view profiles for verification'
  ) THEN
    CREATE POLICY "Active admins can view profiles for verification"
      ON public.profiles
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.auth_user_id = auth.uid()
            AND au.is_active = true
            AND au.role IN ('super_admin', 'ops_admin')
        )
      );
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'Active admins can update verification status'
  ) THEN
    CREATE POLICY "Active admins can update verification status"
      ON public.profiles
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.auth_user_id = auth.uid()
            AND au.is_active = true
            AND au.role IN ('super_admin', 'ops_admin')
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.auth_user_id = auth.uid()
            AND au.is_active = true
            AND au.role IN ('super_admin', 'ops_admin')
        )
      );
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trucks'
      AND policyname = 'Active admins can update truck verification status'
  ) THEN
    CREATE POLICY "Active admins can update truck verification status"
      ON public.trucks
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.auth_user_id = auth.uid()
            AND au.is_active = true
            AND au.role IN ('super_admin', 'ops_admin')
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.auth_user_id = auth.uid()
            AND au.is_active = true
            AND au.role IN ('super_admin', 'ops_admin')
        )
      );
  END IF;
END;
$$;
