DROP FUNCTION IF EXISTS create_or_get_conversation(UUID, UUID, UUID);

CREATE OR REPLACE FUNCTION create_or_get_conversation(
  p_supplier_id UUID,
  p_trucker_id UUID,
  p_load_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_conv_id UUID;
  v_load RECORD;
  v_route_label TEXT;
BEGIN
  SELECT id INTO v_conv_id
  FROM conversations
  WHERE supplier_id = p_supplier_id AND trucker_id = p_trucker_id AND load_id = p_load_id;

  IF v_conv_id IS NOT NULL THEN
    RETURN v_conv_id;
  END IF;

  INSERT INTO conversations (supplier_id, trucker_id, load_id)
  VALUES (p_supplier_id, p_trucker_id, p_load_id)
  RETURNING id INTO v_conv_id;

  SELECT
    origin_label,
    origin_state,
    destination_label,
    destination_state,
    route_distance_km,
    route_duration_minutes,
    material,
    weight_tonnes,
    price_amount
  INTO v_load
  FROM loads
  WHERE id = p_load_id;

  v_route_label := CONCAT_WS(' → ', v_load.origin_label, v_load.destination_label);

  INSERT INTO messages (
    conversation_id,
    sender_profile_id,
    message_type,
    text_body,
    attachment_path,
    structured_payload,
    is_read,
    read_at
  )
  VALUES (
    v_conv_id,
    NULL,
    'map_card',
    v_route_label,
    NULL,
    jsonb_strip_nulls(
      jsonb_build_object(
        'route_label', v_route_label,
        'material', v_load.material,
        'weight_tonnes', v_load.weight_tonnes,
        'price_amount', v_load.price_amount,
        'route_distance_km', v_load.route_distance_km,
        'route_duration_minutes', v_load.route_duration_minutes,
        'origin_state', v_load.origin_state,
        'destination_state', v_load.destination_state
      )
    ),
    TRUE,
    NOW()
  );

  UPDATE conversations SET last_message_at = NOW() WHERE id = v_conv_id;

  RETURN v_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
