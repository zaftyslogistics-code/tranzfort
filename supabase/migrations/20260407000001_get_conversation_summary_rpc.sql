-- Get single conversation summary with supplier mobile
-- This RPC mirrors get_current_user_conversation_summaries but for a single conversation
DROP FUNCTION IF EXISTS public.get_conversation_summary(UUID);

CREATE OR REPLACE FUNCTION public.get_conversation_summary(p_conversation_id UUID)
RETURNS TABLE (
  id UUID,
  supplier_id UUID,
  trucker_id UUID,
  load_id UUID,
  trip_id UUID,
  route_label TEXT,
  load_material TEXT,
  load_price_amount NUMERIC,
  load_status_label TEXT,
  pickup_date DATE,
  supplier_name TEXT,
  supplier_mobile TEXT,
  supplier_company_name TEXT,
  trucker_name TEXT,
  trucker_mobile TEXT,
  truck_display_label TEXT,
  booking_request_id UUID,
  booking_status_label TEXT,
  latest_message_type message_type,
  latest_message_text TEXT,
  last_message_at TIMESTAMPTZ,
  has_unread BOOLEAN,
  is_archived BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.supplier_id,
    c.trucker_id,
    c.load_id,
    c.trip_id,
    COALESCE(
      NULLIF(CONCAT_WS(' → ', NULLIF(BTRIM(l.origin_label), ''), NULLIF(BTRIM(l.destination_label), '')), ''),
      NULLIF(BTRIM(l.origin_label), ''),
      'Load'
    ) AS route_label,
    l.material AS load_material,
    l.price_amount AS load_price_amount,
    l.status::TEXT AS load_status_label,
    l.pickup_date AS pickup_date,
    COALESCE(NULLIF(BTRIM(supplier_profile.full_name), ''), 'Supplier') AS supplier_name,
    NULLIF(BTRIM(supplier_profile.mobile), '') AS supplier_mobile,
    NULLIF(BTRIM(supplier_extension.company_name), '') AS supplier_company_name,
    COALESCE(NULLIF(BTRIM(trucker_profile.full_name), ''), 'Trucker') AS trucker_name,
    NULLIF(BTRIM(trucker_profile.mobile), '') AS trucker_mobile,
    CASE
      WHEN NULLIF(BTRIM(booking_summary.truck_number), '') IS NOT NULL
        AND NULLIF(BTRIM(CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))), '') IS NOT NULL
        THEN booking_summary.truck_number || ' • ' || CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))
      WHEN NULLIF(BTRIM(booking_summary.truck_number), '') IS NOT NULL
        THEN booking_summary.truck_number
      WHEN NULLIF(BTRIM(CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))), '') IS NOT NULL
        THEN CONCAT_WS(' ', NULLIF(BTRIM(booking_summary.truck_make), ''), NULLIF(BTRIM(booking_summary.truck_model), ''))
      ELSE NULL
    END AS truck_display_label,
    booking_summary.booking_request_id,
    booking_summary.booking_status_label,
    latest_message.message_type AS latest_message_type,
    latest_message.text_body AS latest_message_text,
    COALESCE(c.last_message_at, latest_message.created_at) AS last_message_at,
    EXISTS (
      SELECT 1
      FROM messages unread_message
      WHERE unread_message.conversation_id = c.id
        AND unread_message.sender_profile_id IS DISTINCT FROM auth.uid()
        AND unread_message.is_read IS NOT TRUE
    ) AS has_unread,
    c.is_archived,
    c.created_at
  FROM conversations c
  LEFT JOIN loads l ON l.id = c.load_id
  LEFT JOIN profiles supplier_profile ON supplier_profile.id = c.supplier_id
  LEFT JOIN suppliers supplier_extension ON supplier_extension.id = c.supplier_id
  LEFT JOIN profiles trucker_profile ON trucker_profile.id = c.trucker_id
  LEFT JOIN LATERAL (
    SELECT
      br.id AS booking_request_id,
      br.status::TEXT AS booking_status_label,
      tr.truck_number,
      tm.make AS truck_make,
      tm.model AS truck_model
    FROM booking_requests br
    LEFT JOIN trucks tr ON tr.id = br.truck_id
    LEFT JOIN truck_models tm ON tm.id = tr.truck_model_id
    WHERE br.load_id = c.load_id
      AND br.trucker_id = c.trucker_id
    ORDER BY br.created_at DESC
    LIMIT 1
  ) booking_summary ON true
  LEFT JOIN LATERAL (
    SELECT m.message_type, m.text_body, m.created_at
    FROM messages m
    WHERE m.conversation_id = c.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) latest_message ON true
  WHERE c.id = p_conversation_id
    AND (c.supplier_id = auth.uid() OR c.trucker_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_conversation_summary(UUID) TO authenticated;
