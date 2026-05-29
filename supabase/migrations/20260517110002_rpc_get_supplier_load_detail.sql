-- P3.2.2 — RPC to fetch single load detail for supplier
-- Replaces direct table read in SupabaseSupplierLoadBackend.fetchLoadDetail()

CREATE OR REPLACE FUNCTION get_supplier_load_detail(
  p_load_id UUID,
  p_supplier_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
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
      AND supplier_id = p_supplier_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_supplier_load_detail IS
  'Returns full load detail for a supplier-owned load. Replaces direct table read in Flutter backend.';
