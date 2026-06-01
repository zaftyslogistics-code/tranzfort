-- CTO rollback: undo entire LOADPOST / LP / LP-BB program.
-- Target: git 86f6184 (migration 20260603120000).

DROP TABLE IF EXISTS public.load_stops CASCADE;
ALTER TABLE public.trucks DROP CONSTRAINT IF EXISTS trucks_configuration_code_fkey;
ALTER TABLE public.trucks DROP COLUMN IF EXISTS configuration_code;
ALTER TABLE public.loads DROP CONSTRAINT IF EXISTS loads_material_code_fkey;
ALTER TABLE public.loads DROP COLUMN IF EXISTS route_mode;
ALTER TABLE public.loads DROP COLUMN IF EXISTS material_code;
ALTER TABLE public.loads DROP COLUMN IF EXISTS required_vehicle_category_code;
ALTER TABLE public.loads DROP COLUMN IF EXISTS required_body_style_codes;
ALTER TABLE public.loads DROP COLUMN IF EXISTS required_configuration_codes;
ALTER TABLE public.loads DROP COLUMN IF EXISTS cargo_weight_tonnes;
ALTER TABLE public.loads DROP COLUMN IF EXISTS min_passing_ton;
ALTER TABLE public.loads DROP COLUMN IF EXISTS max_passing_ton;
ALTER TABLE public.trucks DROP COLUMN IF EXISTS vehicle_category_code;
ALTER TABLE public.trucks DROP COLUMN IF EXISTS vehicle_body_style_code;
ALTER TABLE public.trucks DROP COLUMN IF EXISTS passing_tonnes;
DROP TABLE IF EXISTS public.vehicle_configurations CASCADE;
DROP TABLE IF EXISTS public.vehicle_category_body_styles CASCADE;
DROP TABLE IF EXISTS public.vehicle_body_styles CASCADE;
DROP TABLE IF EXISTS public.vehicle_categories CASCADE;
DROP TABLE IF EXISTS public.materials CASCADE;
DROP TABLE IF EXISTS public.material_groups CASCADE;
DROP FUNCTION IF EXISTS public.get_materials(TEXT, INT);
DROP FUNCTION IF EXISTS public.get_vehicle_catalog();
DROP FUNCTION IF EXISTS public.lp_passing_bounds_from_tyres(INTEGER[]);
DROP TYPE IF EXISTS public.load_route_mode CASCADE;
DROP FUNCTION IF EXISTS public.create_load CASCADE;
DROP FUNCTION IF EXISTS public.get_marketplace_feed CASCADE;
DROP FUNCTION IF EXISTS add_truck CASCADE;
DROP FUNCTION IF EXISTS update_truck CASCADE;

-- Restored RPCs (86f6184)
CREATE OR REPLACE FUNCTION public.clone_load_for_repost(
  p_source_load_id UUID,
  p_pickup_date DATE,
  p_listing_duration public.load_listing_duration DEFAULT '7_days'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_source public.loads%ROWTYPE;
  v_supplier_id UUID;
  v_new_id UUID;
  v_posted_today INTEGER;
  v_daily_limit CONSTANT INTEGER := 20;
  v_visible_until TIMESTAMPTZ;
BEGIN
  v_supplier_id := auth.uid();
  IF v_supplier_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = v_supplier_id AND p.verification_status = 'verified'
  ) THEN
    RAISE EXCEPTION 'Supplier verification required';
  END IF;

  SELECT * INTO v_source
  FROM public.loads
  WHERE id = p_source_load_id
    AND supplier_id = v_supplier_id
    AND parent_load_id IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF public.load_is_on_marketplace(v_source) THEN
    RAISE EXCEPTION 'Load is still on marketplace';
  END IF;

  v_posted_today := public.supplier_loads_posted_today_count(v_supplier_id);
  IF v_posted_today >= v_daily_limit THEN
    RAISE EXCEPTION 'daily_post_limit_reached';
  END IF;

  v_visible_until := NOW() + public.listing_duration_interval(p_listing_duration);

  INSERT INTO public.loads (
    supplier_id, parent_load_id, reposted_from_load_id,
    origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, trucks_booked, price_amount, price_type, advance_percentage,
    pickup_date, status, is_super_load, super_status,
    published_at, listing_duration, marketplace_visible_until
  ) VALUES (
    v_supplier_id, NULL, p_source_load_id,
    v_source.origin_label, v_source.origin_city, v_source.origin_state,
    v_source.origin_lat, v_source.origin_lng,
    v_source.destination_label, v_source.destination_city, v_source.destination_state,
    v_source.destination_lat, v_source.destination_lng,
    v_source.route_distance_km, v_source.route_duration_minutes,
    v_source.route_polyline, v_source.route_snapshot_source,
    v_source.material, v_source.weight_tonnes, v_source.required_body_type, v_source.required_tyres,
    v_source.trucks_needed, 0, v_source.price_amount, v_source.price_type, v_source.advance_percentage,
    p_pickup_date, 'active', v_source.is_super_load, 'none',
    NOW(), p_listing_duration, v_visible_until
  ) RETURNING id INTO v_new_id;

  UPDATE public.suppliers SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.clone_load_for_repost(UUID, DATE, public.load_listing_duration) TO authenticated;

-- ΓöÇΓöÇΓöÇ Supplier loads list: marketplace fields ΓöÇΓöÇΓöÇ
CREATE OR REPLACE FUNCTION public.get_supplier_loads_list(
  p_supplier_id UUID,
  p_status_filter TEXT[] DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_supplier_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT jsonb_agg(row_to_json(t))
  INTO v_results
  FROM (
    SELECT
      l.id,
      l.origin_label,
      l.destination_label,
      l.material,
      l.weight_tonnes,
      l.trucks_needed,
      l.trucks_booked,
      l.price_amount,
      l.price_type,
      l.pickup_date,
      l.status::text AS status,
      l.required_body_type,
      l.required_tyres,
      l.is_super_load,
      l.super_status::text AS super_status,
      l.published_at,
      l.listing_duration::text AS listing_duration,
      l.marketplace_visible_until,
      public.load_is_on_marketplace(l) AS is_on_marketplace
    FROM public.loads l
    WHERE l.supplier_id = p_supplier_id
      AND l.parent_load_id IS NULL
      AND (
        p_status_filter IS NULL
        OR p_status_filter = '{}'
        OR l.status::text = ANY(p_status_filter)
      )
      AND (
        p_search_query IS NULL
        OR p_search_query = ''
        OR l.material ILIKE '%' || p_search_query || '%'
        OR l.origin_city ILIKE '%' || p_search_query || '%'
        OR l.destination_city ILIKE '%' || p_search_query || '%'
        OR l.origin_label ILIKE '%' || p_search_query || '%'
        OR l.destination_label ILIKE '%' || p_search_query || '%'
      )
    ORDER BY l.published_at DESC NULLS LAST, l.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_supplier_loads_list(UUID, TEXT[], TEXT, INT, INT) TO authenticated;

-- ΓöÇΓöÇΓöÇ Supplier load detail: marketplace fields ΓöÇΓöÇΓöÇ
CREATE OR REPLACE FUNCTION public.get_supplier_load_detail(
  p_load_id UUID,
  p_supplier_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_supplier_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT
      l.id,
      l.parent_load_id,
      l.origin_label,
      l.origin_city,
      l.origin_state,
      l.origin_lat,
      l.origin_lng,
      l.destination_label,
      l.destination_city,
      l.destination_state,
      l.destination_lat,
      l.destination_lng,
      l.route_distance_km,
      l.route_duration_minutes,
      l.route_polyline,
      l.route_snapshot_source,
      l.material,
      l.weight_tonnes,
      l.required_body_type,
      l.required_tyres,
      l.trucks_needed,
      l.trucks_booked,
      l.price_amount,
      l.price_type,
      l.advance_percentage,
      l.pickup_date,
      l.status::text AS status,
      l.is_super_load,
      l.super_status::text AS super_status,
      l.assigned_trucker_id,
      l.assigned_truck_id,
      l.published_at,
      l.created_at,
      l.updated_at,
      l.listing_duration::text AS listing_duration,
      l.marketplace_visible_until,
      l.reposted_from_load_id,
      public.load_is_on_marketplace(l) AS is_on_marketplace
    FROM public.loads l
    WHERE l.id = p_load_id
      AND l.supplier_id = p_supplier_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_supplier_load_detail(UUID, UUID) TO authenticated;

-- ΓöÇΓöÇΓöÇ Server-side truck/load fit (P0-6) ΓöÇΓöÇΓöÇ
CREATE OR REPLACE FUNCTION public.truck_matches_load_requirements(
  p_truck public.trucks,
  p_load public.loads
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT
    (
      p_load.required_body_type IS NULL
      OR TRIM(p_load.required_body_type) = ''
      OR LOWER(TRIM(p_load.required_body_type)) = LOWER(TRIM(p_truck.body_type::text))
    )
    AND (
      p_load.required_tyres IS NULL
      OR cardinality(p_load.required_tyres) = 0
      OR p_truck.tyres = ANY(p_load.required_tyres)
    )
    AND COALESCE(p_truck.capacity_tonnes, 0) >= COALESCE(p_load.weight_tonnes, 0);
$$;

COMMENT ON FUNCTION public.truck_matches_load_requirements(public.trucks, public.loads) IS
  'Mirrors Flutter truckMatchesLoad ΓÇö body, tyres, capacity.';

-- ΓöÇΓöÇΓöÇ submit_booking_request: marketplace + truck fit + GPS + notify ΓöÇΓöÇΓöÇ
DROP FUNCTION IF EXISTS public.submit_booking_request(UUID, UUID);

DROP FUNCTION IF EXISTS public.create_load(
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  NUMERIC, INTEGER, TEXT, TEXT,
  TEXT, NUMERIC, TEXT, INTEGER[],
  INTEGER, NUMERIC, public.price_type, INTEGER, DATE
);

CREATE OR REPLACE FUNCTION public.create_load(
  p_origin_label TEXT, p_origin_city TEXT, p_origin_state TEXT,
  p_origin_lat DOUBLE PRECISION, p_origin_lng DOUBLE PRECISION,
  p_destination_label TEXT, p_destination_city TEXT, p_destination_state TEXT,
  p_destination_lat DOUBLE PRECISION, p_destination_lng DOUBLE PRECISION,
  p_route_distance_km NUMERIC, p_route_duration_minutes INTEGER,
  p_route_polyline TEXT, p_route_snapshot_source TEXT,
  p_material TEXT, p_weight_tonnes NUMERIC,
  p_required_body_type TEXT, p_required_tyres INTEGER[],
  p_trucks_needed INTEGER, p_price_amount NUMERIC,
  p_price_type public.price_type, p_advance_percentage INTEGER,
  p_pickup_date DATE,
  p_listing_duration public.load_listing_duration DEFAULT '7_days'
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

  v_visible_until := NOW() + public.listing_duration_interval(p_listing_duration);

  IF NOT EXISTS (SELECT 1 FROM public.suppliers WHERE id = v_supplier_id) THEN
    INSERT INTO public.suppliers (id) VALUES (v_supplier_id)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  INSERT INTO public.loads (
    supplier_id, origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage,
    pickup_date, status, published_at,
    listing_duration, marketplace_visible_until
  ) VALUES (
    v_supplier_id, p_origin_label, p_origin_city, p_origin_state, p_origin_lat, p_origin_lng,
    p_destination_label, p_destination_city, p_destination_state, p_destination_lat, p_destination_lng,
    p_route_distance_km, p_route_duration_minutes, p_route_polyline, p_route_snapshot_source,
    p_material, p_weight_tonnes, v_body_type, p_required_tyres,
    p_trucks_needed, p_price_amount, v_canonical_price_type, p_advance_percentage,
    p_pickup_date, 'active', NOW(),
    p_listing_duration, v_visible_until
  ) RETURNING id INTO v_load_id;

  UPDATE public.suppliers SET
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
  public.load_listing_duration
) TO authenticated;

-- ΓöÇΓöÇΓöÇ Dashboard stats: posts today meter ΓöÇΓöÇΓöÇ

DROP FUNCTION IF EXISTS public.get_marketplace_feed(
  TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, BOOLEAN, INT[],
  TEXT, INT, INT
);

CREATE OR REPLACE FUNCTION public.get_marketplace_feed(
  p_origin_city         TEXT DEFAULT NULL,
  p_destination_city    TEXT DEFAULT NULL,
  p_material            TEXT DEFAULT NULL,
  p_body_type           TEXT DEFAULT NULL,
  p_min_price           NUMERIC DEFAULT NULL,
  p_max_price           NUMERIC DEFAULT NULL,
  p_super_loads_only    BOOLEAN DEFAULT FALSE,
  p_required_tyres      INT[] DEFAULT NULL,
  p_sort_by             TEXT DEFAULT 'newest',
  p_page_size           INT DEFAULT 20,
  p_page                INT DEFAULT 1
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset   INT := (p_page - 1) * p_page_size;
  v_total    BIGINT;
  v_results  JSONB;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM public.loads l
  WHERE public.load_is_on_marketplace(l)
    AND (p_origin_city IS NULL OR l.origin_city ILIKE '%' || p_origin_city || '%')
    AND (p_destination_city IS NULL OR l.destination_city ILIKE '%' || p_destination_city || '%')
    AND (p_material IS NULL OR l.material ILIKE '%' || p_material || '%')
    AND (p_body_type IS NULL OR l.required_body_type = p_body_type)
    AND (p_min_price IS NULL OR l.price_amount >= p_min_price)
    AND (p_max_price IS NULL OR l.price_amount <= p_max_price)
    AND (p_super_loads_only = FALSE OR public.load_is_public_super_load(l.is_super_load, l.super_status))
    AND (p_required_tyres IS NULL OR p_required_tyres = '{}'
         OR l.required_tyres && p_required_tyres);

  SELECT jsonb_agg(row_to_json(t) ORDER BY t.sort_key DESC)
  INTO v_results
  FROM (
    SELECT
      l.id,
      l.supplier_id,
      l.origin_label,
      l.origin_city,
      l.origin_state,
      l.origin_lat,
      l.origin_lng,
      l.destination_label,
      l.destination_city,
      l.destination_state,
      l.destination_lat,
      l.destination_lng,
      l.route_distance_km,
      l.route_duration_minutes,
      l.route_snapshot_source,
      l.material,
      l.weight_tonnes,
      l.required_body_type,
      l.required_tyres,
      l.trucks_needed,
      l.trucks_booked,
      l.price_amount,
      l.price_type,
      l.advance_percentage,
      l.pickup_date,
      l.status,
      public.load_is_public_super_load(l.is_super_load, l.super_status) AS is_super_load,
      l.super_status,
      l.created_at,
      l.parent_load_id,
      l.listing_duration,
      l.marketplace_visible_until,
      jsonb_build_object(
        'supplier_name',        p.full_name,
        'supplier_avatar_url',  p.avatar_url,
        'supplier_photo_path',  p.profile_photo_document_path,
        'supplier_mobile',      p.mobile,
        'supplier_trust_score', COALESCE((
          SELECT avg_rating FROM public.profile_trust_scores WHERE user_id = p.id
        ), 0)
      ) AS supplier_summary,
      CASE p_sort_by
        WHEN 'newest'      THEN extract(epoch from l.created_at)::BIGINT
        WHEN 'price_asc'   THEN -l.price_amount
        WHEN 'price_desc'  THEN l.price_amount
        WHEN 'pickup_date' THEN extract(epoch from l.pickup_date)::BIGINT
        ELSE extract(epoch from l.created_at)::BIGINT
      END AS sort_key
    FROM public.loads l
    JOIN public.profiles p ON p.id = l.supplier_id
    WHERE public.load_is_on_marketplace(l)
      AND (p_origin_city IS NULL OR l.origin_city ILIKE '%' || p_origin_city || '%')
      AND (p_destination_city IS NULL OR l.destination_city ILIKE '%' || p_destination_city || '%')
      AND (p_material IS NULL OR l.material ILIKE '%' || p_material || '%')
      AND (p_body_type IS NULL OR l.required_body_type = p_body_type)
      AND (p_min_price IS NULL OR l.price_amount >= p_min_price)
      AND (p_max_price IS NULL OR l.price_amount <= p_max_price)
      AND (p_super_loads_only = FALSE OR public.load_is_public_super_load(l.is_super_load, l.super_status))
      AND (p_required_tyres IS NULL OR p_required_tyres = '{}'
           OR l.required_tyres && p_required_tyres)
    ORDER BY sort_key DESC
    LIMIT p_page_size
    OFFSET v_offset
  ) t;

  RETURN jsonb_build_object(
    'loads',     COALESCE(v_results, '[]'::JSONB),
    'total',     v_total,
    'page',      p_page,
    'page_size', p_page_size,
    'has_more',  (v_total > v_offset + p_page_size)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_marketplace_feed(
  TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, BOOLEAN, INT[],
  TEXT, INT, INT
) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_trucker_load_detail(p_load_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = auth.uid()
      AND user_role_type = 'trucker'
  ) THEN
    RAISE EXCEPTION 'Trucker role required';
  END IF;

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      supplier_id,
      parent_load_id,
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
      weight_tonnes,
      required_body_type,
      required_tyres,
      trucks_needed,
      trucks_booked,
      price_amount,
      price_type,
      advance_percentage,
      pickup_date,
      status,
      public.load_is_public_super_load(is_super_load, super_status) AS is_super_load,
      super_status,
      assigned_trucker_id,
      assigned_truck_id,
      published_at,
      created_at,
      updated_at
    FROM loads
    WHERE id = p_load_id
      AND status IN ('active', 'assigned_partial')
      AND parent_load_id IS NULL
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION get_trucker_fleet(
  p_user_id UUID,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_trucks JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user_id IS DISTINCT FROM auth.uid() AND NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized to view this fleet';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'truck_model_id', t.truck_model_id,
      'truck_number', t.truck_number,
      'body_type', t.body_type,
      'tyres', t.tyres,
      'capacity_tonnes', t.capacity_tonnes,
      'rc_document_path', t.rc_document_path,
      'status', t.status,
      'rejection_reason', t.rejection_reason,
      'verification_feedback_json', t.verification_feedback_json,
      'verified_at', t.verified_at,
      'created_at', t.created_at,
      'updated_at', t.updated_at,
      'truck_models', jsonb_build_object(
        'make', tm.make,
        'model', tm.model,
        'axles', tm.axles,
        'payload_kg', tm.payload_kg,
        'mileage_empty_kmpl', tm.mileage_empty_kmpl,
        'mileage_loaded_kmpl', tm.mileage_loaded_kmpl
      )
    )
  )
  INTO v_trucks
  FROM (
    SELECT t.*
    FROM trucks t
    WHERE t.owner_id = p_user_id
      AND t.status != 'archived'
    ORDER BY t.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t
  LEFT JOIN truck_models tm ON tm.id = t.truck_model_id;

  RETURN COALESCE(v_trucks, '[]'::jsonb);
END;
$$;

DROP FUNCTION IF EXISTS add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT);

CREATE OR REPLACE FUNCTION add_truck(
  p_truck_number TEXT,
  p_body_type TEXT,
  p_tyres INTEGER,
  p_capacity_tonnes NUMERIC,
  p_rc_document_path TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_truck_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_truck_number IS NULL OR BTRIM(p_truck_number) = '' THEN
    RAISE EXCEPTION 'Truck number is required';
  END IF;

  IF p_body_type IS NULL OR BTRIM(p_body_type) = '' THEN
    RAISE EXCEPTION 'Body type is required';
  END IF;

  IF p_tyres IS NULL OR p_tyres <= 0 THEN
    RAISE EXCEPTION 'Tyres must be a positive integer';
  END IF;

  IF p_capacity_tonnes IS NULL OR p_capacity_tonnes <= 0 THEN
    RAISE EXCEPTION 'Capacity must be a positive number';
  END IF;

  INSERT INTO trucks (
    owner_id,
    truck_number,
    body_type,
    tyres,
    capacity_tonnes,
    rc_document_path,
    status
  )
  VALUES (
    v_user_id,
    UPPER(BTRIM(p_truck_number)),
    BTRIM(p_body_type),
    p_tyres,
    p_capacity_tonnes,
    BTRIM(p_rc_document_path),
    'pending'
  )
  RETURNING id INTO v_truck_id;

  RETURN jsonb_build_object('id', v_truck_id);
END;
$$;

CREATE OR REPLACE FUNCTION update_truck(
  p_truck_id UUID,
  p_truck_number TEXT,
  p_body_type TEXT,
  p_tyres INTEGER,
  p_capacity_tonnes NUMERIC,
  p_rc_document_path TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_existing_truck RECORD;
  v_critical_fields_changed BOOLEAN;
  v_next_status TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT *
  INTO v_existing_truck
  FROM trucks
  WHERE id = p_truck_id
    AND owner_id = v_user_id
  FOR UPDATE;

  IF v_existing_truck IS NULL THEN
    RAISE EXCEPTION 'Truck not found or not owned by user';
  END IF;

  v_critical_fields_changed := (
    v_existing_truck.truck_number != UPPER(BTRIM(p_truck_number))
    OR v_existing_truck.body_type != BTRIM(p_body_type)
    OR v_existing_truck.tyres != p_tyres
    OR v_existing_truck.capacity_tonnes != p_capacity_tonnes
    OR COALESCE(v_existing_truck.rc_document_path, '') != BTRIM(p_rc_document_path)
  );

  IF v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN
    v_next_status := 'edited_pending_reapproval';
    UPDATE trucks
    SET
      truck_number = UPPER(BTRIM(p_truck_number)),
      body_type = BTRIM(p_body_type),
      tyres = p_tyres,
      capacity_tonnes = p_capacity_tonnes,
      rc_document_path = BTRIM(p_rc_document_path),
      status = v_next_status,
      rejection_reason = NULL,
      verification_feedback_json = NULL,
      verified_at = NULL,
      verified_by_admin_user_id = NULL,
      updated_at = NOW()
    WHERE id = p_truck_id;
  ELSE
    UPDATE trucks
    SET
      truck_number = UPPER(BTRIM(p_truck_number)),
      body_type = BTRIM(p_body_type),
      tyres = p_tyres,
      capacity_tonnes = p_capacity_tonnes,
      rc_document_path = BTRIM(p_rc_document_path),
      updated_at = NOW()
    WHERE id = p_truck_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION archive_truck(p_truck_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE trucks
  SET status = 'archived',
      updated_at = NOW()
  WHERE id = p_truck_id
    AND owner_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Truck not found or not owned by user';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION get_trucker_fleet(UUID, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_truck(UUID, TEXT, TEXT, INTEGER, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION archive_truck(UUID) TO authenticated;

