-- Phase D: trucker load detail visible on marketplace OR existing booking/trip

CREATE OR REPLACE FUNCTION public.get_trucker_load_detail(p_load_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_trucker_id UUID := auth.uid();
BEGIN
  IF v_trucker_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_trucker_id AND user_role_type = 'trucker'
  ) THEN
    RAISE EXCEPTION 'Trucker role required';
  END IF;

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT
      l.id,
      l.supplier_id,
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
      l.status,
      l.is_super_load,
      l.super_status,
      l.assigned_trucker_id,
      l.assigned_truck_id,
      l.published_at,
      l.listing_duration,
      l.marketplace_visible_until,
      l.created_at,
      l.updated_at
    FROM public.loads l
    WHERE l.id = p_load_id
      AND l.parent_load_id IS NULL
      AND (
        public.load_is_on_marketplace(l)
        OR EXISTS (
          SELECT 1 FROM public.booking_requests br
          WHERE br.load_id = l.id
            AND br.trucker_id = v_trucker_id
        )
        OR EXISTS (
          SELECT 1 FROM public.trips t
          WHERE t.trucker_id = v_trucker_id
            AND (
              t.load_id = l.id
              OR t.load_id IN (
                SELECT c.id FROM public.loads c WHERE c.parent_load_id = l.id
              )
            )
        )
      )
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION public.get_trucker_load_detail(UUID) IS
  'Trucker load detail when on marketplace or trucker has booking/trip on parent/child loads.';

GRANT EXECUTE ON FUNCTION public.get_trucker_load_detail(UUID) TO authenticated;
