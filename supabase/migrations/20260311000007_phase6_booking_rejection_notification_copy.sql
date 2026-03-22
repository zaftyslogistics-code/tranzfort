CREATE OR REPLACE FUNCTION reject_booking_request(p_booking_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
  v_booking RECORD;
  v_load RECORD;
  v_body TEXT;
BEGIN
  SELECT * INTO v_booking FROM booking_requests WHERE id = p_booking_id;
  IF v_booking IS NULL OR v_booking.status != 'submitted' THEN
    RAISE EXCEPTION 'Booking not found or not in submitted state';
  END IF;

  SELECT * INTO v_load FROM loads WHERE id = v_booking.load_id;
  IF v_load.supplier_id != auth.uid() THEN RAISE EXCEPTION 'Not your load'; END IF;

  UPDATE booking_requests SET
    status = 'rejected', decision_reason = p_reason, decided_at = NOW()
  WHERE id = p_booking_id;

  v_body := 'Your booking for ' || COALESCE(v_load.material, 'this load') || ' was not approved';
  IF NULLIF(BTRIM(COALESCE(p_reason, '')), '') IS NOT NULL THEN
    v_body := v_body || '. Reason: ' || BTRIM(p_reason);
  END IF;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_booking.trucker_id,
    'booking_update',
    'high',
    'Booking Rejected',
    v_body,
    v_booking.load_id,
    '/find-loads'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
