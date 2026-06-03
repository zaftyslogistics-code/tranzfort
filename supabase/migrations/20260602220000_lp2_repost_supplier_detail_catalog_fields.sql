-- LP2: preserve catalog + material fields on repost and supplier read RPCs.
BEGIN;

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
    supplier_id,
    parent_load_id,
    reposted_from_load_id,
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
    trucks_booked,
    price_amount,
    price_type,
    advance_percentage,
    pickup_date,
    status,
    is_super_load,
    super_status,
    published_at,
    listing_duration,
    marketplace_visible_until
  ) VALUES (
    v_supplier_id,
    NULL,
    p_source_load_id,
    v_source.origin_label,
    v_source.origin_city,
    v_source.origin_state,
    v_source.origin_lat,
    v_source.origin_lng,
    v_source.destination_label,
    v_source.destination_city,
    v_source.destination_state,
    v_source.destination_lat,
    v_source.destination_lng,
    v_source.route_distance_km,
    v_source.route_duration_minutes,
    v_source.route_polyline,
    v_source.route_snapshot_source,
    v_source.material,
    v_source.material_code,
    v_source.weight_tonnes,
    v_source.required_body_type,
    v_source.required_tyres,
    v_source.required_vehicle_category_code,
    COALESCE(v_source.required_body_style_codes, '{}'),
    COALESCE(v_source.required_configuration_codes, '{}'),
    v_source.trucks_needed,
    0,
    v_source.price_amount,
    v_source.price_type,
    v_source.advance_percentage,
    p_pickup_date,
    'active',
    v_source.is_super_load,
    'none',
    NOW(),
    p_listing_duration,
    v_visible_until
  ) RETURNING id INTO v_new_id;

  UPDATE public.suppliers
  SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.clone_load_for_repost(UUID, DATE, public.load_listing_duration) TO authenticated;

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
      l.material_code,
      l.weight_tonnes,
      l.trucks_needed,
      l.trucks_booked,
      l.price_amount,
      l.price_type,
      l.pickup_date,
      l.status::text AS status,
      l.required_body_type,
      l.required_tyres,
      l.required_vehicle_category_code,
      l.required_body_style_codes,
      l.required_configuration_codes,
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
      l.material_code,
      l.weight_tonnes,
      l.required_body_type,
      l.required_tyres,
      l.required_vehicle_category_code,
      l.required_body_style_codes,
      l.required_configuration_codes,
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

COMMIT;
