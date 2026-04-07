-- Enable admin-authenticated access to audit_logs so runtime admin actions can be persisted and verified.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'audit_logs'
      AND policyname = 'Active admins can view audit logs'
  ) THEN
    CREATE POLICY "Active admins can view audit logs"
      ON public.audit_logs
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.id = audit_logs.admin_id
            AND au.auth_user_id = auth.uid()
            AND au.is_active = true
        )
        OR EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.auth_user_id = auth.uid()
            AND au.is_active = true
            AND au.role IN ('super_admin', 'ops_admin', 'support_agent')
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
      AND tablename = 'audit_logs'
      AND policyname = 'Active admins can insert audit logs'
  ) THEN
    CREATE POLICY "Active admins can insert audit logs"
      ON public.audit_logs
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.admin_users au
          WHERE au.id = audit_logs.admin_id
            AND au.auth_user_id = auth.uid()
            AND au.is_active = true
        )
      );
  END IF;
END;
$$;
