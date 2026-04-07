-- Extend onboarding profile upsert RPC to support profile-level location fields.

CREATE OR REPLACE FUNCTION public.upsert_current_user_profile(
  p_user_role_type user_role DEFAULT NULL,
  p_full_name TEXT DEFAULT NULL,
  p_mobile TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_state TEXT DEFAULT NULL,
  p_location_lat DOUBLE PRECISION DEFAULT NULL,
  p_location_lng DOUBLE PRECISION DEFAULT NULL,
  p_location_source TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_existing_profile profiles%ROWTYPE;
  v_email TEXT;
  v_full_name TEXT;
  v_mobile TEXT;
  v_city TEXT;
  v_state TEXT;
  v_location_source TEXT;
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

  v_city := COALESCE(
    NULLIF(BTRIM(COALESCE(p_city, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.city, '')), '')
  );

  v_state := COALESCE(
    NULLIF(BTRIM(COALESCE(p_state, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.state, '')), '')
  );

  v_location_source := COALESCE(
    NULLIF(BTRIM(COALESCE(p_location_source, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.location_source, '')), '')
  );

  IF v_mobile IS NOT NULL AND v_mobile <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE mobile = v_mobile AND id <> v_user_id
    ) THEN
      RAISE EXCEPTION 'This mobile number is already registered to another account.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

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
    user_role_type,
    city,
    state,
    location_lat,
    location_lng,
    location_source
  )
  VALUES (
    v_user_id,
    v_full_name,
    v_mobile,
    v_email,
    p_user_role_type,
    v_city,
    v_state,
    COALESCE(p_location_lat, v_existing_profile.location_lat),
    COALESCE(p_location_lng, v_existing_profile.location_lng),
    v_location_source
  )
  ON CONFLICT (id) DO UPDATE
  SET full_name = EXCLUDED.full_name,
      mobile = COALESCE(EXCLUDED.mobile, public.profiles.mobile),
      email = COALESCE(EXCLUDED.email, public.profiles.email),
      user_role_type = COALESCE(EXCLUDED.user_role_type, public.profiles.user_role_type),
      city = COALESCE(EXCLUDED.city, public.profiles.city),
      state = COALESCE(EXCLUDED.state, public.profiles.state),
      location_lat = COALESCE(EXCLUDED.location_lat, public.profiles.location_lat),
      location_lng = COALESCE(EXCLUDED.location_lng, public.profiles.location_lng),
      location_source = COALESCE(EXCLUDED.location_source, public.profiles.location_source),
      updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
