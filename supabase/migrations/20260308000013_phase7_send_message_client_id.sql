DROP FUNCTION IF EXISTS send_message(UUID, message_type, TEXT, TEXT, JSONB);

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

  RETURN v_msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
