-- P3.7.3 — RPC to fetch support ticket messages with composite cursor pagination
-- CRITICAL FIX for SDN-002: uses composite cursor (created_at, id) instead of two independent filters
-- Replaces direct table read in SupabaseSupportBackend.fetchTicketMessagesPaginated()

CREATE OR REPLACE FUNCTION get_support_ticket_messages(
  p_ticket_id UUID,
  p_user_id UUID,
  p_limit INT DEFAULT 50,
  p_before_created_at TIMESTAMPTZ DEFAULT NULL,
  p_before_message_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_results JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Verify ticket ownership
  IF NOT EXISTS (
    SELECT 1 FROM support_tickets
    WHERE id = p_ticket_id AND owner_profile_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Ticket not found or access denied';
  END IF;

  SELECT jsonb_agg(row_to_json(m))
  INTO v_results
  FROM (
    SELECT
      id,
      support_ticket_id,
      sender_profile_id,
      sender_admin_user_id,
      message_body,
      attachment_path,
      visibility_class,
      created_at
    FROM support_ticket_messages
    WHERE support_ticket_id = p_ticket_id
      AND (
        p_before_created_at IS NULL
        OR (
          created_at < p_before_created_at
          OR (
            created_at = p_before_created_at
            AND (p_before_message_id IS NULL OR id < p_before_message_id)
          )
        )
      )
    ORDER BY created_at DESC, id DESC
    LIMIT p_limit
  ) m;

  RETURN COALESCE(v_results, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_support_ticket_messages IS
  'Returns paginated support ticket messages using composite cursor (created_at, id). Fixes SDN-002 cursor bug. Replaces direct table read in Flutter backend.';
