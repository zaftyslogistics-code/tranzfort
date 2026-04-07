-- Restore automatic supplier/trucker extension row creation in the canonical onboarding RPC.
-- Also harden create_load so legacy supplier accounts without a suppliers row can recover.

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
  v_effective_role user_role;
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

  v_effective_role := COALESCE(p_user_role_type, v_existing_profile.user_role_type);

  IF v_effective_role = 'supplier' THEN
    INSERT INTO public.suppliers (id)
    VALUES (v_user_id)
    ON CONFLICT (id) DO NOTHING;
  ELSIF v_effective_role = 'trucker' THEN
    INSERT INTO public.truckers (id)
    VALUES (v_user_id)
    ON CONFLICT (id) DO NOTHING;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_load(
  p_origin_label TEXT, p_origin_city TEXT, p_origin_state TEXT,
  p_origin_lat DOUBLE PRECISION, p_origin_lng DOUBLE PRECISION,
  p_destination_label TEXT, p_destination_city TEXT, p_destination_state TEXT,
  p_destination_lat DOUBLE PRECISION, p_destination_lng DOUBLE PRECISION,
  p_route_distance_km NUMERIC, p_route_duration_minutes INTEGER,
  p_route_polyline TEXT, p_route_snapshot_source TEXT,
  p_material TEXT, p_weight_tonnes NUMERIC,
  p_required_body_type TEXT, p_required_tyres INTEGER[],
  p_trucks_needed INTEGER, p_price_amount NUMERIC,
  p_price_type price_type, p_advance_percentage INTEGER,
  p_pickup_date DATE
)
RETURNS UUID AS $$
DECLARE
  v_load_id UUID;
  v_supplier_id UUID := auth.uid();
  v_role user_role;
BEGIN
  IF v_supplier_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT user_role_type INTO v_role
  FROM profiles
  WHERE id = v_supplier_id;

  IF v_role IS DISTINCT FROM 'supplier' THEN
    RAISE EXCEPTION 'Not a supplier';
  END IF;

  INSERT INTO suppliers (id)
  VALUES (v_supplier_id)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO loads (
    supplier_id, origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage,
    pickup_date, status, published_at
  ) VALUES (
    v_supplier_id, p_origin_label, p_origin_city, p_origin_state, p_origin_lat, p_origin_lng,
    p_destination_label, p_destination_city, p_destination_state, p_destination_lat, p_destination_lng,
    p_route_distance_km, p_route_duration_minutes, p_route_polyline, p_route_snapshot_source,
    p_material, p_weight_tonnes, p_required_body_type, p_required_tyres,
    p_trucks_needed, p_price_amount, p_price_type, p_advance_percentage,
    p_pickup_date, 'active', NOW()
  ) RETURNING id INTO v_load_id;

  UPDATE suppliers SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_load_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
