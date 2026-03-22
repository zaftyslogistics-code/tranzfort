CREATE OR REPLACE FUNCTION cancel_trip(p_trip_id UUID)
RETURNS VOID AS $$
DECLARE
  v_trip RECORD;
  v_child_load RECORD;
  v_parent_load RECORD;
  v_remaining_booked INTEGER;
  v_has_active_children BOOLEAN;
  v_has_started_children BOOLEAN;
  v_has_completed_children BOOLEAN;
  v_body TEXT;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  IF v_trip.supplier_id != auth.uid() AND NOT is_admin() THEN
    RAISE EXCEPTION 'Not your trip';
  END IF;

  IF v_trip.stage IN ('completed', 'cancelled') THEN
    RAISE EXCEPTION 'Trip cannot be cancelled in current state';
  END IF;

  SELECT * INTO v_child_load FROM loads WHERE id = v_trip.load_id FOR UPDATE;
  IF v_child_load IS NULL THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  IF v_child_load.parent_load_id IS NOT NULL THEN
    SELECT * INTO v_parent_load FROM loads WHERE id = v_child_load.parent_load_id FOR UPDATE;
  END IF;

  UPDATE trips
  SET stage = 'cancelled'
  WHERE id = p_trip_id;

  UPDATE loads
  SET status = 'cancelled'
  WHERE id = v_child_load.id;

  IF v_parent_load IS NOT NULL THEN
    v_remaining_booked := GREATEST(COALESCE(v_parent_load.trucks_booked, 0) - 1, 0);

    SELECT EXISTS (
      SELECT 1
      FROM loads child
      JOIN trips t ON t.load_id = child.id
      WHERE child.parent_load_id = v_parent_load.id
        AND t.stage NOT IN ('completed', 'cancelled')
    ) INTO v_has_active_children;

    SELECT EXISTS (
      SELECT 1
      FROM loads child
      JOIN trips t ON t.load_id = child.id
      WHERE child.parent_load_id = v_parent_load.id
        AND t.stage IN ('picked_up', 'in_transit', 'delivered', 'proof_submitted', 'disputed')
    ) INTO v_has_started_children;

    SELECT EXISTS (
      SELECT 1
      FROM loads child
      JOIN trips t ON t.load_id = child.id
      WHERE child.parent_load_id = v_parent_load.id
        AND t.stage = 'completed'
    ) INTO v_has_completed_children;

    UPDATE loads
    SET trucks_booked = v_remaining_booked,
        status = CASE
          WHEN v_has_active_children AND v_has_started_children THEN 'in_transit'::load_status
          WHEN v_has_active_children AND v_remaining_booked >= trucks_needed THEN 'assigned_full'::load_status
          WHEN v_has_active_children AND v_remaining_booked > 0 THEN 'assigned_partial'::load_status
          WHEN NOT v_has_active_children AND v_has_completed_children THEN 'completed'::load_status
          ELSE 'active'::load_status
        END
    WHERE id = v_parent_load.id;
  END IF;

  v_body := 'Trip for ' || COALESCE(v_child_load.material, 'your load') || ' ' || COALESCE(v_child_load.origin_label, 'origin') || '→' || COALESCE(v_child_load.destination_label, 'destination') || ' has been cancelled';

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES
  (
    v_trip.trucker_id,
    'trip_update',
    'high',
    'Trip Cancelled',
    v_body,
    v_child_load.id,
    v_trip.id,
    '/trip-detail/{tripId}'
  ),
  (
    v_trip.supplier_id,
    'trip_update',
    'high',
    'Trip Cancelled',
    v_body,
    v_child_load.id,
    v_trip.id,
    '/trip-detail/{tripId}'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
