-- ============================================================================
-- Phase 3 Migration 3: Update create_load RPC to normalize per_ton / negotiable
-- Date: 2026-04-28
-- ============================================================================
-- The RPC now accepts 'per_ton' directly (enum was updated in migration 1).
-- During the 1-week buffer, if an old Flutter build sends 'negotiable',
-- the RPC normalizes it to 'per_ton' so all new rows use the canonical value.
-- After the buffer, 'negotiable' can be dropped from the enum.
-- ============================================================================

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
  v_supplier_id UUID;
  v_canonical_price_type price_type;
BEGIN
  -- Normalize legacy 'negotiable' to canonical 'per_ton' during buffer period
  v_canonical_price_type := CASE
    WHEN p_price_type = 'negotiable' THEN 'per_ton'::price_type
    ELSE p_price_type
  END;

  -- Verify caller is a supplier
  SELECT id INTO v_supplier_id FROM suppliers WHERE id = auth.uid();
  IF v_supplier_id IS NULL THEN
    RAISE EXCEPTION 'Not a supplier';
  END IF;

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
    p_trucks_needed, p_price_amount, v_canonical_price_type, p_advance_percentage,
    p_pickup_date, 'active', NOW()
  ) RETURNING id INTO v_load_id;

  -- Update supplier counters
  UPDATE suppliers SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_load_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_load(
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION,
  NUMERIC, INTEGER, TEXT, TEXT,
  TEXT, NUMERIC, TEXT, INTEGER[],
  INTEGER, NUMERIC, price_type, INTEGER, DATE
) TO authenticated;
