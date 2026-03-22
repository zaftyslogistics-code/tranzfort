-- ============================================================================
-- TranZfort Rebuild — Phase 10: Onboarding profile upsert RPC
-- Purpose: let the signed-in user create or repair their own profile row during onboarding
-- ============================================================================

CREATE OR REPLACE FUNCTION public.upsert_current_user_profile(
  p_user_role_type user_role DEFAULT NULL,
  p_full_name TEXT DEFAULT NULL,
  p_mobile TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_existing_profile profiles%ROWTYPE;
  v_email TEXT;
  v_full_name TEXT;
  v_mobile TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_existing_profile
  FROM public.profiles
  WHERE id = v_user_id;

  v_email := COALESCE(
    NULLIF(BTRIM(COALESCE(v_existing_profile.email, '')), ''),
    NULLIF(BTRIM(COALESCE(auth.jwt() ->> 'email', '')), '')
  );

  v_full_name := COALESCE(
    NULLIF(BTRIM(COALESCE(p_full_name, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.full_name, '')), ''),
    NULLIF(BTRIM(SPLIT_PART(COALESCE(v_email, ''), '@', 1)), ''),
    'User'
  );

  v_mobile := COALESCE(
    NULLIF(BTRIM(COALESCE(p_mobile, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.mobile, '')), '')
  );

  -- Check for mobile uniqueness before upsert
  IF v_mobile IS NOT NULL AND v_mobile <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE mobile = v_mobile AND id <> v_user_id
    ) THEN
      RAISE EXCEPTION 'This mobile number is already registered to another account.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  -- Check for email uniqueness before upsert
  IF v_email IS NOT NULL AND v_email <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE email = v_email AND id <> v_user_id
    ) THEN
      RAISE EXCEPTION 'This email address is already registered to another account.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  INSERT INTO public.profiles (
    id,
    full_name,
    mobile,
    email,
    user_role_type
  )
  VALUES (
    v_user_id,
    v_full_name,
    v_mobile,
    v_email,
    p_user_role_type
  )
  ON CONFLICT (id) DO UPDATE
  SET full_name = EXCLUDED.full_name,
      mobile = COALESCE(EXCLUDED.mobile, public.profiles.mobile),
      email = COALESCE(EXCLUDED.email, public.profiles.email),
      user_role_type = COALESCE(EXCLUDED.user_role_type, public.profiles.user_role_type),
      updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
