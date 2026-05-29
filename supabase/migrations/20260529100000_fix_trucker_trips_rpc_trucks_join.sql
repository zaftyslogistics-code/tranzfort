-- Fix get_trucker_trips and get_trip_detail: truck_id references trucks.id, not truckers.id.
-- Previous joins used truckers.truck_number (column does not exist), breaking the Trips list RPC.

CREATE OR REPLACE FUNCTION get_trucker_trips(
  p_trucker_id UUID,
  p_stage_filter TEXT[] DEFAULT NULL,
  p_limit INT DEFAULT 15,
  p_offset INT DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT jsonb_agg(row_to_json(t))
  INTO v_results
  FROM (
    SELECT
      t.id,
      t.load_id,
      t.truck_id,
      t.stage,
      t.assigned_at,
      t.delivered_at,
      t.pod_uploaded_at,
      t.completed_at,
      t.lr_document_path,
      t.pod_document_path,
      t.load_snapshot_summary,
      jsonb_build_object(
        'origin_label', l.origin_label,
        'origin_lat', l.origin_lat,
        'origin_lng', l.origin_lng,
        'destination_label', l.destination_label,
        'destination_lat', l.destination_lat,
        'destination_lng', l.destination_lng,
        'material', l.material
      ) AS loads,
      jsonb_build_object(
        'truck_number', tr.truck_number
      ) AS trucks
    FROM trips t
    INNER JOIN loads l ON l.id = t.load_id
    LEFT JOIN trucks tr ON tr.id = t.truck_id
    WHERE t.trucker_id = p_trucker_id
      AND (
        p_stage_filter IS NULL
        OR p_stage_filter = '{}'
        OR t.stage = ANY(p_stage_filter)
      )
    ORDER BY t.assigned_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    LEFT JOIN trucks tr ON tr.id = t.truck_id
    WHERE t.id = p_trip_id
      AND t.trucker_id = p_trucker_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_trucker_trips IS
  'Returns paginated list of trips for a trucker with optional stage filtering. Joins trucks (not truckers) for fleet metadata.';

COMMENT ON FUNCTION get_trip_detail IS
  'Returns trip detail with load and truck context for a trucker-owned trip. Joins trucks (not truckers) for fleet metadata.';

GRANT EXECUTE ON FUNCTION get_trucker_trips(UUID, TEXT[], INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_detail(UUID, UUID) TO authenticated;
