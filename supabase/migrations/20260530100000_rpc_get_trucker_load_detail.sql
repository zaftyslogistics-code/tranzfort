-- P3.3 — RPC for trucker marketplace load detail (replaces direct loads SELECT)
-- Visibility matches loads_trucker_select RLS: active/assigned_partial parent loads only.

CREATE OR REPLACE FUNCTION get_trucker_load_detail(p_load_id UUID)
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
      is_super_load,
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

COMMENT ON FUNCTION get_trucker_load_detail IS
  'Marketplace load detail for authenticated truckers. Replaces direct loads table read in Flutter.';

GRANT EXECUTE ON FUNCTION get_trucker_load_detail(UUID) TO authenticated;
