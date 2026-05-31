-- P1-LOAD Phase C–D: clone repost, supplier list/detail fields, booking + RLS guards

-- ─── clone_load_for_repost ───
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

-- ─── Supplier loads list: marketplace fields ───
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

-- ─── Supplier load detail: marketplace fields ───
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

-- ─── Server-side truck/load fit (P0-6) ───
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
  'Mirrors Flutter truckMatchesLoad — body, tyres, capacity.';

-- ─── submit_booking_request: marketplace + truck fit + GPS + notify ───
DROP FUNCTION IF EXISTS public.submit_booking_request(UUID, UUID);

CREATE OR REPLACE FUNCTION public.submit_booking_request(
  p_load_id UUID,
  p_truck_id UUID,
  p_booking_gps_lat DOUBLE PRECISION DEFAULT NULL,
  p_booking_gps_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking_id UUID;
  v_trucker_id UUID;
  v_load public.loads%ROWTYPE;
  v_truck public.trucks%ROWTYPE;
  v_trucker_name TEXT;
BEGIN
  v_trucker_id := auth.uid();

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_trucker_id AND verification_status = 'verified'
  ) THEN
    RAISE EXCEPTION 'Trucker not verified';
  END IF;

  SELECT * INTO v_load
  FROM public.loads
  WHERE id = p_load_id AND parent_load_id IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF NOT public.load_is_on_marketplace(v_load) THEN
    RAISE EXCEPTION 'Load not available for booking';
  END IF;

  SELECT * INTO v_truck
  FROM public.trucks
  WHERE id = p_truck_id AND owner_id = v_trucker_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Truck not found';
  END IF;

  IF v_truck.status != 'verified' THEN
    RAISE EXCEPTION 'Truck not verified';
  END IF;

  IF NOT public.truck_matches_load_requirements(v_truck, v_load) THEN
    RAISE EXCEPTION 'truck_load_mismatch';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.booking_requests
    WHERE load_id = p_load_id AND trucker_id = v_trucker_id AND status = 'submitted'
  ) THEN
    RAISE EXCEPTION 'Already booked this load';
  END IF;

  IF (p_booking_gps_lat IS NULL) <> (p_booking_gps_lng IS NULL) THEN
    RAISE EXCEPTION 'Booking GPS latitude/longitude must be provided together';
  END IF;

  INSERT INTO public.booking_requests (
    load_id,
    trucker_id,
    truck_id,
    status,
    booking_gps_lat,
    booking_gps_lng
  )
  VALUES (
    p_load_id,
    v_trucker_id,
    p_truck_id,
    'submitted',
    p_booking_gps_lat,
    p_booking_gps_lng
  )
  RETURNING id INTO v_booking_id;

  SELECT COALESCE(NULLIF(full_name, ''), 'A trucker')
  INTO v_trucker_name
  FROM public.profiles
  WHERE id = v_trucker_id;

  INSERT INTO public.notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'booking_update',
    'medium',
    'New Booking Request',
    COALESCE(v_trucker_name, 'A trucker') || ' wants to book your ' || COALESCE(v_load.material, 'active') || ' load',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );

  RETURN v_booking_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_booking_request(UUID, UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- ─── RLS: trucker select aligned with feed ───
DROP POLICY IF EXISTS "loads_trucker_select" ON public.loads;

CREATE POLICY "loads_trucker_select" ON public.loads FOR SELECT USING (
  public.load_is_on_marketplace(loads)
  AND (SELECT user_role_type FROM public.profiles WHERE id = auth.uid()) = 'trucker'
);
