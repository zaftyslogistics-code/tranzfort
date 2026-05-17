-- P3.4.2 — RPC to fetch single trip detail for trucker
-- Replaces direct table read in SupabaseTruckerTripsBackend.fetchTripDetail()
-- Note: get_trip_detail_with_supplier already exists for full context; this is a lightweight variant

CREATE OR REPLACE FUNCTION get_trip_detail(
  p_trip_id UUID,
  p_trucker_id UUID
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
      t.id,
      t.load_id,
      t.supplier_id,
      t.truck_id,
      t.stage,
      t.assigned_at,
      t.started_at,
      t.delivered_at,
      t.pod_uploaded_at,
      t.completed_at,
      t.lr_document_path,
      t.pod_document_path,
      t.load_snapshot_summary,
      jsonb_build_object(
        'origin_label', l.origin_label,
        'origin_city', l.origin_city,
        'origin_state', l.origin_state,
        'origin_lat', l.origin_lat,
        'origin_lng', l.origin_lng,
        'destination_label', l.destination_label,
        'destination_city', l.destination_city,
        'destination_state', l.destination_state,
        'destination_lat', l.destination_lat,
        'destination_lng', l.destination_lng,
        'route_distance_km', l.route_distance_km,
        'route_duration_minutes', l.route_duration_minutes,
        'route_snapshot_source', l.route_snapshot_source,
        'material', l.material,
        'pickup_date', l.pickup_date
      ) AS loads,
      jsonb_build_object(
        'truck_number', tr.truck_number,
        'body_type', tr.body_type,
        'tyres', tr.tyres
      ) AS trucks
    FROM trips t
    INNER JOIN loads l ON l.id = t.load_id
    LEFT JOIN truckers tr ON tr.id = t.truck_id
    WHERE t.id = p_trip_id
      AND t.trucker_id = p_trucker_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_trip_detail IS
  'Returns trip detail with load and truck context for a trucker-owned trip. Replaces direct table read in Flutter backend.';
