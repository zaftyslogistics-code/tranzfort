-- P3.2 — RPC to fetch trips linked to a supplier load (including parent/child loads)
-- Replaces direct table read in SupabaseSupplierLoadBackend.fetchLinkedTrips()

CREATE OR REPLACE FUNCTION get_supplier_linked_trips(
  p_load_id UUID,
  p_supplier_id UUID
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
      t.trucker_id,
      t.truck_id,
      t.stage,
      t.assigned_at,
      t.delivered_at,
      t.pod_uploaded_at,
      t.completed_at,
      t.lr_document_path,
      t.pod_document_path,
      jsonb_build_object(
        'id', l.id,
        'parent_load_id', l.parent_load_id,
        'origin_label', l.origin_label,
        'destination_label', l.destination_label,
        'material', l.material
      ) AS loads
    FROM trips t
    INNER JOIN loads l ON l.id = t.load_id
    WHERE t.supplier_id = p_supplier_id
      AND t.load_id IN (
        SELECT id FROM loads
        WHERE supplier_id = p_supplier_id
          AND (id = p_load_id OR parent_load_id = p_load_id)
      )
    ORDER BY t.assigned_at DESC
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_supplier_linked_trips IS
  'Returns all trips linked to a load and its parent/child loads. Replaces direct table read in Flutter backend.';
