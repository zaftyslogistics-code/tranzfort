DROP FUNCTION IF EXISTS send_message(UUID, message_type, UUID, TEXT, TEXT, JSONB);

CREATE OR REPLACE FUNCTION send_message(
  p_conversation_id UUID,
  p_message_type message_type,
  p_message_id UUID DEFAULT NULL,
  p_text_body TEXT DEFAULT NULL,
  p_attachment_path TEXT DEFAULT NULL,
  p_structured_payload JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_msg_id UUID;
  v_conv RECORD;
  v_target_profile_id UUID;
  v_sender_name TEXT;
  v_preview TEXT;
BEGIN
  SELECT * INTO v_conv FROM conversations WHERE id = p_conversation_id;
  IF v_conv IS NULL THEN RAISE EXCEPTION 'Conversation not found'; END IF;

  IF auth.uid() NOT IN (v_conv.supplier_id, v_conv.trucker_id) THEN
    RAISE EXCEPTION 'Not a participant in this conversation';
  END IF;

  INSERT INTO messages (
    id,
    conversation_id,
    sender_profile_id,
    message_type,
    text_body,
    attachment_path,
    structured_payload
  )
  VALUES (
    COALESCE(p_message_id, gen_random_uuid()),
    p_conversation_id,
    auth.uid(),
    p_message_type,
    p_text_body,
    p_attachment_path,
    p_structured_payload
  )
  RETURNING id INTO v_msg_id;

  UPDATE conversations SET last_message_at = NOW() WHERE id = p_conversation_id;

  v_target_profile_id := CASE
    WHEN auth.uid() = v_conv.supplier_id THEN v_conv.trucker_id
    ELSE v_conv.supplier_id
  END;

  SELECT COALESCE(NULLIF(full_name, ''), 'New message')
  INTO v_sender_name
  FROM profiles
  WHERE id = auth.uid();

  v_preview := btrim(COALESCE(p_text_body, ''));
  IF v_preview = '' THEN
    v_preview := 'Sent you an attachment';
  END IF;
  v_preview := left(v_preview, 120);

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_target_profile_id,
    'message_received',
    'medium',
    'New Message',
    v_sender_name || ': ' || v_preview,
    v_conv.load_id,
    '/chat/' || p_conversation_id::text
  );

  RETURN v_msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
