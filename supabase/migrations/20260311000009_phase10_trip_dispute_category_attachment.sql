CREATE OR REPLACE FUNCTION raise_trip_dispute(
  p_trip_id UUID,
  p_category TEXT,
  p_reason TEXT,
  p_attachment_path TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_trip RECORD;
  v_reason TEXT;
  v_category TEXT;
  v_support_ticket_id UUID;
  v_operational_case_id UUID;
BEGIN
  v_reason := btrim(COALESCE(p_reason, ''));
  v_category := lower(btrim(COALESCE(p_category, '')));

  IF v_category NOT IN (
    'loaded_quantity_mismatch',
    'unloaded_quantity_mismatch',
    'document_mismatch',
    'non_payment',
    'fake_payout_proof',
    'delay_or_no_show',
    'damage_or_shortage',
    'abusive_behavior',
    'spam_or_scam',
    'other'
  ) THEN
    RAISE EXCEPTION 'Unsupported dispute category';
  END IF;

  IF char_length(v_reason) < 10 THEN
    RAISE EXCEPTION 'Dispute reason too short';
  END IF;

  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.supplier_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;
  IF v_trip.stage != 'proof_submitted' THEN RAISE EXCEPTION 'Trip not in proof_submitted stage'; END IF;

  INSERT INTO support_tickets (
    owner_profile_id,
    category,
    status,
    priority,
    related_load_id,
    related_trip_id
  ) VALUES (
    auth.uid(),
    v_category,
    'open',
    'high',
    v_trip.load_id,
    p_trip_id
  ) RETURNING id INTO v_support_ticket_id;

  INSERT INTO support_ticket_messages (
    support_ticket_id,
    sender_profile_id,
    message_body,
    attachment_path,
    visibility_class
  ) VALUES (
    v_support_ticket_id,
    auth.uid(),
    v_reason,
    NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
    'visible'
  );

  INSERT INTO operational_cases (
    case_type,
    primary_object_type,
    primary_object_id,
    queue_classification,
    status
  ) VALUES (
    'trip_dispute',
    'trip',
    p_trip_id,
    NULL,
    'queued'
  ) RETURNING id INTO v_operational_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    v_operational_case_id,
    'case_created',
    'Supplier raised POD dispute: ' || replace(v_category, '_', ' '),
    v_reason
  );

  UPDATE trips
  SET stage = 'disputed'
  WHERE id = p_trip_id;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_trip.trucker_id,
    'dispute_update',
    'high',
    'Supplier raised a trip dispute',
    'A proof-of-delivery dispute was raised for your trip. Open trip detail for the latest review status.',
    v_trip.load_id,
    p_trip_id,
    v_operational_case_id,
    '/trip-detail/' || p_trip_id::text
  );

  RETURN v_support_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION raise_trip_dispute(
  p_trip_id UUID,
  p_reason TEXT
)
RETURNS UUID AS $$
BEGIN
  RETURN raise_trip_dispute(
    p_trip_id := p_trip_id,
    p_category := 'document_mismatch',
    p_reason := p_reason,
    p_attachment_path := NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
