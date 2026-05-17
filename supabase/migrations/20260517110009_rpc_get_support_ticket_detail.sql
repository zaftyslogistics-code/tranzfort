-- P3.7.2 — RPC to fetch single support ticket detail with messages
-- Replaces direct table reads in SupabaseSupportBackend.fetchTicket() + fetchTicketMessages()

CREATE OR REPLACE FUNCTION get_support_ticket_detail(
  p_ticket_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_ticket JSONB;
  v_messages JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Verify ownership
  SELECT row_to_json(t)::jsonb
  INTO v_ticket
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
    WHERE id = p_ticket_id
      AND owner_profile_id = p_user_id
  ) t;

  IF v_ticket IS NULL THEN
    RAISE EXCEPTION 'Ticket not found or access denied';
  END IF;

  SELECT jsonb_agg(row_to_json(m))
  INTO v_messages
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
    ORDER BY created_at ASC
    LIMIT 50
  ) m;

  RETURN jsonb_build_object(
    'ticket', COALESCE(v_ticket, '{}'::jsonb),
    'messages', COALESCE(v_messages, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_support_ticket_detail IS
  'Returns support ticket detail with up to 50 messages. Replaces direct table reads in Flutter backend.';
