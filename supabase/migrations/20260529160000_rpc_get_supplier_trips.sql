-- P3.4.9 / supplier parity — RPC to fetch supplier's trips (align with get_trucker_trips).
-- Replaces direct trips table read in SupabaseSupplierTripsBackend.fetchTrips().

CREATE OR REPLACE FUNCTION get_supplier_trips(
  p_supplier_id UUID,
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

  IF p_supplier_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Trip list is only available for the signed-in supplier';
  END IF;

  SELECT jsonb_agg(row_to_json(t))
  INTO v_results
  FROM (
    SELECT
      t.id,
      t.load_id,
      t.trucker_id,
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
        'destination_label', l.destination_label,
        'material', l.material
      ) AS loads
    FROM trips t
    INNER JOIN loads l ON l.id = t.load_id
    WHERE t.supplier_id = p_supplier_id
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

COMMENT ON FUNCTION get_supplier_trips IS
  'Returns paginated list of trips for a supplier with optional stage filtering. Replaces direct table read in Flutter backend.';

GRANT EXECUTE ON FUNCTION get_supplier_trips(UUID, TEXT[], INT, INT) TO authenticated;
