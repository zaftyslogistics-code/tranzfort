-- P3.4.5 — RPC to fetch a user's own rating for a load
-- Replaces direct table read in SupabaseTruckerTripsBackend.fetchOwnRating()

CREATE OR REPLACE FUNCTION get_own_rating(
  p_reviewer_id UUID,
  p_load_id UUID
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
    SELECT id, score, comment, created_at
    FROM ratings
    WHERE reviewer_id = p_reviewer_id
      AND load_id = p_load_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_own_rating IS
  'Returns a users own rating for a specific load. Replaces direct table read in Flutter backend.';
