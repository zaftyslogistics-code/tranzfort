-- Cast trip_stage when filtering by text[] stage list; enforce caller = signed-in trucker.

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

  IF p_trucker_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Trip list is only available for the signed-in trucker';
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
        OR t.stage::text = ANY(p_stage_filter)
      )
    ORDER BY t.assigned_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_trucker_trips(UUID, TEXT[], INT, INT) TO authenticated;
