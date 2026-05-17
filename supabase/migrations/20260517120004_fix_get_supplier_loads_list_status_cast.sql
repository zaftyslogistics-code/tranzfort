-- Fix: Cast status to text in get_supplier_loads_list RPC
-- Issue: status column is enum type, cannot directly compare with TEXT[] using = ANY()
-- Fix: Cast status::text before comparison

CREATE OR REPLACE FUNCTION get_supplier_loads_list(
  p_supplier_id UUID,
  p_status_filter TEXT[] DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20,
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
      id,
      origin_label,
      destination_label,
      material,
      weight_tonnes,
      trucks_needed,
      trucks_booked,
      price_amount,
      price_type,
      pickup_date,
      status,
      required_body_type,
      required_tyres,
      is_super_load,
      super_status,
      published_at
    FROM loads
    WHERE supplier_id = p_supplier_id
      AND (
        p_status_filter IS NULL
        OR p_status_filter = '{}'
        OR status::text = ANY(p_status_filter)
      )
      AND (
        p_search_query IS NULL
        OR p_search_query = ''
        OR material ILIKE '%' || p_search_query || '%'
        OR origin_city ILIKE '%' || p_search_query || '%'
        OR destination_city ILIKE '%' || p_search_query || '%'
        OR origin_label ILIKE '%' || p_search_query || '%'
        OR destination_label ILIKE '%' || p_search_query || '%'
      )
    ORDER BY pickup_date DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_supplier_loads_list IS
  'Returns paginated list of loads for a supplier with optional status filtering and search. Replaces direct table read in Flutter backend.';
