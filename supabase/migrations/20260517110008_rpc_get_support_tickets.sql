-- P3.7.1 — RPC to fetch user's support tickets with pagination
-- Replaces direct table read in SupabaseSupportBackend.fetchTickets()

CREATE OR REPLACE FUNCTION get_support_tickets(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_before_updated_at TIMESTAMPTZ DEFAULT NULL
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
      category,
      status,
      priority,
      related_load_id,
      related_trip_id,
      resolution_summary,
      created_at,
      updated_at,
      resolved_at
    FROM support_tickets
    WHERE owner_profile_id = p_user_id
      AND (
        p_before_updated_at IS NULL
        OR updated_at < p_before_updated_at
      )
    ORDER BY updated_at DESC
    LIMIT p_limit
  ) t;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_support_tickets IS
  'Returns paginated list of support tickets for the current user. Replaces direct table read in Flutter backend.';
