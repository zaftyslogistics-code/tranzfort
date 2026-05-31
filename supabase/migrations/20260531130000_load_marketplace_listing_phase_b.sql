-- P1-LOAD Phase B: create_load listing duration + IST daily cap (20) + quota RPC
-- Requires: 20260531120000_load_marketplace_listing_phase_a.sql

-- ─── Helpers ───
CREATE OR REPLACE FUNCTION public.listing_duration_interval(p_duration public.load_listing_duration)
RETURNS INTERVAL
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_duration
    WHEN '48_hours' THEN INTERVAL '48 hours'
    WHEN '7_days' THEN INTERVAL '7 days'
    WHEN '30_days' THEN INTERVAL '30 days'
  END;
$$;

CREATE OR REPLACE FUNCTION public.supplier_loads_posted_today_count(p_supplier_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::INTEGER
  FROM public.loads l
  WHERE l.supplier_id = p_supplier_id
    AND l.parent_load_id IS NULL
    AND l.published_at IS NOT NULL
    AND (l.published_at AT TIME ZONE 'Asia/Kolkata')::date =
        (NOW() AT TIME ZONE 'Asia/Kolkata')::date;
$$;

CREATE OR REPLACE FUNCTION public.get_supplier_post_load_quota()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_supplier_id UUID;
  v_posted INTEGER;
  v_limit CONSTANT INTEGER := 20;
  v_verification public.verification_status;
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
    RETURN jsonb_build_object(
      'loads_posted_today', 0,
      'loads_daily_limit', v_limit,
      'loads_remaining_today', 0,
      'can_post_today', FALSE,
      'verification_required', TRUE
    );
  END IF;

  v_posted := public.supplier_loads_posted_today_count(v_supplier_id);

  RETURN jsonb_build_object(
    'loads_posted_today', v_posted,
    'loads_daily_limit', v_limit,
    'loads_remaining_today', GREATEST(v_limit - v_posted, 0),
    'can_post_today', v_posted < v_limit,
    'verification_required', FALSE
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_supplier_post_load_quota() TO authenticated;

-- ─── create_load: duration, visibility, daily cap, any → NULL ───
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

-- ─── Dashboard stats: posts today meter ───
CREATE OR REPLACE FUNCTION public.get_supplier_dashboard_stats(p_supplier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active_loads BIGINT;
  v_pending_bookings BIGINT;
  v_in_transit_trips BIGINT;
  v_completed_trips BIGINT;
  v_posted_today INTEGER;
  v_daily_limit CONSTANT INTEGER := 20;
BEGIN
  IF p_supplier_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT COUNT(*) INTO v_active_loads FROM public.loads
  WHERE supplier_id = p_supplier_id
    AND status IN ('active', 'assigned_partial', 'assigned_full', 'in_transit');

  SELECT COUNT(*) INTO v_pending_bookings FROM public.booking_requests br
  JOIN public.loads l ON l.id = br.load_id
  WHERE l.supplier_id = p_supplier_id AND br.status = 'submitted';

  SELECT COUNT(*) INTO v_in_transit_trips FROM public.trips
  WHERE supplier_id = p_supplier_id AND stage = 'in_transit';

  SELECT COUNT(*) INTO v_completed_trips FROM public.trips
  WHERE supplier_id = p_supplier_id AND stage = 'completed';

  v_posted_today := public.supplier_loads_posted_today_count(p_supplier_id);

  RETURN jsonb_build_object(
    'active_loads', v_active_loads,
    'pending_bookings', v_pending_bookings,
    'in_transit_trips', v_in_transit_trips,
    'completed_trips', v_completed_trips,
    'loads_posted_today', v_posted_today,
    'loads_daily_limit', v_daily_limit,
    'loads_remaining_today', GREATEST(v_daily_limit - v_posted_today, 0)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_supplier_dashboard_stats(UUID) TO authenticated;
