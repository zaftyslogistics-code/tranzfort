-- Restore Admin login authorization path:
-- 1) allow authenticated users to read their own admin_users row
-- 2) ensure seeded super-admin row exists/is active for known test account

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'admin_users'
      AND policyname = 'Authenticated users can view their own admin row'
  ) THEN
    CREATE POLICY "Authenticated users can view their own admin row"
      ON public.admin_users
      FOR SELECT
      TO authenticated
      USING (auth.uid() = auth_user_id);
  END IF;
END;
$$;

DO $$
DECLARE
  v_target_email CONSTANT text := 'zaftyslogistics@gmail.com';
  v_auth_user_id uuid;
  v_row_by_auth uuid;
  v_row_by_email uuid;
BEGIN
  SELECT id
  INTO v_auth_user_id
  FROM auth.users
  WHERE lower(email) = lower(v_target_email)
  LIMIT 1;

  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'No auth.users row found for %; skipping admin_users sync.', v_target_email;
    RETURN;
  END IF;

  SELECT id
  INTO v_row_by_auth
  FROM public.admin_users
  WHERE auth_user_id = v_auth_user_id
  LIMIT 1;

  SELECT id
  INTO v_row_by_email
  FROM public.admin_users
  WHERE lower(email) = lower(v_target_email)
  LIMIT 1;

  IF v_row_by_auth IS NOT NULL
     AND v_row_by_email IS NOT NULL
     AND v_row_by_auth <> v_row_by_email THEN
    RAISE EXCEPTION
      'Conflicting admin_users rows for % (by auth_user_id: %, by email: %). Resolve duplicates first.',
      v_target_email,
      v_row_by_auth,
      v_row_by_email;
  END IF;

  IF v_row_by_auth IS NOT NULL THEN
    UPDATE public.admin_users
    SET
      email = v_target_email,
      role = 'super_admin',
      is_active = true,
      full_name = COALESCE(NULLIF(full_name, ''), 'Zafty Logistics'),
      updated_at = now()
    WHERE id = v_row_by_auth;
  ELSIF v_row_by_email IS NOT NULL THEN
    UPDATE public.admin_users
    SET
      auth_user_id = v_auth_user_id,
      role = 'super_admin',
      is_active = true,
      full_name = COALESCE(NULLIF(full_name, ''), 'Zafty Logistics'),
      updated_at = now()
    WHERE id = v_row_by_email;
  ELSE
    INSERT INTO public.admin_users (
      auth_user_id,
      full_name,
      email,
      role,
      is_active
    ) VALUES (
      v_auth_user_id,
      'Zafty Logistics',
      v_target_email,
      'super_admin',
      true
    );
  END IF;
END;
$$;
