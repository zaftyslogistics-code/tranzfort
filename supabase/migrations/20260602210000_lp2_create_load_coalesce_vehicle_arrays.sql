-- LP2: create_load must not insert NULL into NOT NULL array columns on loads.
BEGIN;

CREATE OR REPLACE FUNCTION public.create_load(
  p_origin_label TEXT,
  p_origin_city TEXT,
  p_origin_state TEXT,
  p_origin_lat DOUBLE PRECISION,
  p_origin_lng DOUBLE PRECISION,
  p_destination_label TEXT,
  p_destination_city TEXT,
  p_destination_state TEXT,
  p_destination_lat DOUBLE PRECISION,
  p_destination_lng DOUBLE PRECISION,
  p_route_distance_km NUMERIC,
  p_route_duration_minutes INTEGER,
  p_route_polyline TEXT,
  p_route_snapshot_source TEXT,
  p_material TEXT,
  p_weight_tonnes NUMERIC,
  p_required_body_type TEXT,
  p_required_tyres INTEGER[],
  p_trucks_needed INTEGER,
  p_price_amount NUMERIC,
  p_price_type public.price_type,
  p_advance_percentage INTEGER,
  p_pickup_date DATE,
  p_listing_duration public.load_listing_duration DEFAULT '7_days',
  p_material_code TEXT DEFAULT NULL,
  p_required_vehicle_category_code TEXT DEFAULT NULL,
  p_required_body_style_codes TEXT[] DEFAULT NULL,
  p_required_configuration_codes TEXT[] DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_load_id UUID;
  v_supplier_id UUID;
  v_canonical_price_type public.price_type;
  v_body_type TEXT;
  v_verification public.verification_status;
  v_posted_today INTEGER;
  v_daily_limit CONSTANT INTEGER := 20;
  v_visible_until TIMESTAMPTZ;
  v_material_code TEXT;
  v_material_name TEXT;
  v_body_style_codes TEXT[];
  v_configuration_codes TEXT[];
BEGIN
  v_supplier_id := auth.uid();
  IF v_supplier_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT p.verification_status
  INTO v_verification
  FROM public.profiles p
  WHERE p.id = v_supplier_id;

  IF v_verification IS DISTINCT FROM 'verified' THEN
    RAISE EXCEPTION 'Supplier verification required';
  END IF;

  v_posted_today := public.supplier_loads_posted_today_count(v_supplier_id);
  IF v_posted_today >= v_daily_limit THEN
    RAISE EXCEPTION 'daily_post_limit_reached'
      USING HINT = format('Posted %s of %s loads today (IST)', v_posted_today, v_daily_limit);
  END IF;

  v_canonical_price_type := CASE
    WHEN p_price_type = 'negotiable' THEN 'per_ton'::public.price_type
    ELSE p_price_type
  END;

  v_body_type := NULLIF(TRIM(LOWER(COALESCE(p_required_body_type, ''))), '');
  IF v_body_type IN ('any', '') THEN
    v_body_type := NULL;
  END IF;

  v_material_code := NULLIF(TRIM(COALESCE(p_material_code, '')), '');
  IF v_material_code IS NOT NULL THEN
    SELECT m.name_en
    INTO v_material_name
    FROM public.materials m
    WHERE m.code = v_material_code
      AND m.is_active = TRUE;
    IF v_material_name IS NULL THEN
      RAISE EXCEPTION 'Invalid material_code';
    END IF;
  ELSE
    v_material_name := NULLIF(TRIM(COALESCE(p_material, '')), '');
  END IF;

  IF v_material_name IS NULL THEN
    RAISE EXCEPTION 'Material is required';
  END IF;

  v_body_style_codes := COALESCE(p_required_body_style_codes, '{}');
  v_configuration_codes := COALESCE(p_required_configuration_codes, '{}');

  v_visible_until := NOW() + public.listing_duration_interval(p_listing_duration);

  IF NOT EXISTS (SELECT 1 FROM public.suppliers WHERE id = v_supplier_id) THEN
    INSERT INTO public.suppliers (id) VALUES (v_supplier_id)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  INSERT INTO public.loads (
    supplier_id,
    origin_label,
    origin_city,
    origin_state,
    origin_lat,
    origin_lng,
    destination_label,
    destination_city,
    destination_state,
    destination_lat,
    destination_lng,
    route_distance_km,
    route_duration_minutes,
    route_polyline,
    route_snapshot_source,
    material,
    material_code,
    weight_tonnes,
    required_body_type,
    required_tyres,
    required_vehicle_category_code,
    required_body_style_codes,
    required_configuration_codes,
    trucks_needed,
    price_amount,
    price_type,
    advance_percentage,
    pickup_date,
    status,
    published_at,
    listing_duration,
    marketplace_visible_until
  ) VALUES (
    v_supplier_id,
    p_origin_label,
    p_origin_city,
    p_origin_state,
    p_origin_lat,
    p_origin_lng,
    p_destination_label,
    p_destination_city,
    p_destination_state,
    p_destination_lat,
    p_destination_lng,
    p_route_distance_km,
    p_route_duration_minutes,
    p_route_polyline,
    p_route_snapshot_source,
    v_material_name,
    v_material_code,
    p_weight_tonnes,
    v_body_type,
    p_required_tyres,
    NULLIF(TRIM(COALESCE(p_required_vehicle_category_code, '')), ''),
    v_body_style_codes,
    v_configuration_codes,
    p_trucks_needed,
    p_price_amount,
    v_canonical_price_type,
    p_advance_percentage,
    p_pickup_date,
    'active',
    NOW(),
    p_listing_duration,
    v_visible_until
  ) RETURNING id INTO v_load_id;

  UPDATE public.suppliers
  SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_load_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_load(
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  NUMERIC, INTEGER, TEXT, TEXT,
  TEXT, NUMERIC, TEXT, INTEGER[],
  INTEGER, NUMERIC, public.price_type, INTEGER, DATE,
  public.load_listing_duration, TEXT, TEXT, TEXT[], TEXT[]
) TO authenticated;

COMMIT;
