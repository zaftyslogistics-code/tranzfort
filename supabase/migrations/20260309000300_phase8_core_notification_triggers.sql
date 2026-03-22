CREATE OR REPLACE FUNCTION submit_booking_request(
  p_load_id UUID, p_truck_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_booking_id UUID;
  v_trucker_id UUID;
  v_load RECORD;
  v_truck RECORD;
  v_trucker_name TEXT;
BEGIN
  v_trucker_id := auth.uid();

  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_trucker_id AND verification_status = 'verified') THEN
    RAISE EXCEPTION 'Trucker not verified';
  END IF;

  SELECT * INTO v_load FROM loads WHERE id = p_load_id AND parent_load_id IS NULL FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.status NOT IN ('active', 'assigned_partial') THEN RAISE EXCEPTION 'Load not available for booking'; END IF;
  IF v_load.trucks_booked >= v_load.trucks_needed THEN RAISE EXCEPTION 'Load fully booked'; END IF;

  SELECT * INTO v_truck FROM trucks WHERE id = p_truck_id AND owner_id = v_trucker_id;
  IF v_truck IS NULL THEN RAISE EXCEPTION 'Truck not found'; END IF;
  IF v_truck.status != 'verified' THEN RAISE EXCEPTION 'Truck not verified'; END IF;

  IF EXISTS (SELECT 1 FROM booking_requests WHERE load_id = p_load_id AND trucker_id = v_trucker_id AND status = 'submitted') THEN
    RAISE EXCEPTION 'Already booked this load';
  END IF;

  INSERT INTO booking_requests (load_id, trucker_id, truck_id, status)
  VALUES (p_load_id, v_trucker_id, p_truck_id, 'submitted')
  RETURNING id INTO v_booking_id;

  SELECT COALESCE(NULLIF(full_name, ''), 'A trucker')
  INTO v_trucker_name
  FROM profiles
  WHERE id = v_trucker_id;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    action_route_hint
  ) VALUES (
    v_load.supplier_id,
    'booking_update',
    'medium',
    'New Booking Request',
    COALESCE(v_trucker_name, 'A trucker') || ' wants to book your ' || COALESCE(v_load.material, 'active') || ' load',
    p_load_id,
    '/load-detail/' || p_load_id::text
  );

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION approve_booking_request(p_booking_id UUID)
RETURNS UUID AS $$
DECLARE
  v_booking RECORD;
  v_load RECORD;
  v_child_load_id UUID;
  v_trip_id UUID;
  v_supplier_id UUID;
BEGIN
  v_supplier_id := auth.uid();

  SELECT * INTO v_booking FROM booking_requests WHERE id = p_booking_id FOR UPDATE;
  IF v_booking IS NULL THEN RAISE EXCEPTION 'Booking not found'; END IF;
  IF v_booking.status != 'submitted' THEN RAISE EXCEPTION 'Booking not in submitted state'; END IF;

  SELECT * INTO v_load FROM loads WHERE id = v_booking.load_id FOR UPDATE;
  IF v_load.supplier_id != v_supplier_id THEN RAISE EXCEPTION 'Not your load'; END IF;
  IF v_load.status NOT IN ('active', 'assigned_partial') THEN RAISE EXCEPTION 'Load not available'; END IF;

  UPDATE booking_requests SET status = 'approved', decided_at = NOW() WHERE id = p_booking_id;

  INSERT INTO loads (
    supplier_id, parent_load_id,
    origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage, pickup_date,
    status, assigned_trucker_id, assigned_truck_id, published_at
  ) SELECT
    supplier_id, v_load.id,
    origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    1, price_amount, price_type, advance_percentage, pickup_date,
    'assigned_full', v_booking.trucker_id, v_booking.truck_id, NOW()
  FROM loads WHERE id = v_load.id
  RETURNING id INTO v_child_load_id;

  INSERT INTO trips (load_id, supplier_id, trucker_id, truck_id, stage, assigned_at)
  VALUES (v_child_load_id, v_supplier_id, v_booking.trucker_id, v_booking.truck_id, 'assigned', NOW())
  RETURNING id INTO v_trip_id;

  UPDATE loads SET
    trucks_booked = trucks_booked + 1,
    status = CASE
      WHEN trucks_booked + 1 >= trucks_needed THEN 'assigned_full'::load_status
      ELSE 'assigned_partial'::load_status
    END
  WHERE id = v_load.id;

  IF (v_load.trucks_booked + 1 >= v_load.trucks_needed) THEN
    UPDATE booking_requests SET status = 'superseded'
    WHERE load_id = v_load.id AND status = 'submitted' AND id != p_booking_id;
  END IF;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    v_booking.trucker_id,
    'booking_update',
    'high',
    'Booking Approved!',
    'Head to pickup for ' || COALESCE(v_load.material, 'your load') || ' ' || COALESCE(v_load.origin_label, 'origin') || '→' || COALESCE(v_load.destination_label, 'destination'),
    v_child_load_id,
    v_trip_id,
    '/trip-detail/' || v_trip_id::text
  );

  RETURN v_trip_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION reject_booking_request(p_booking_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
  v_booking RECORD;
  v_load RECORD;
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
    'Your booking for ' || COALESCE(v_load.material, 'this load') || ' was not approved',
    v_booking.load_id,
    '/find-loads'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION advance_trip_stage(
  p_trip_id UUID,
  p_new_stage trip_stage,
  p_gps_lat DOUBLE PRECISION DEFAULT NULL,
  p_gps_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_trip RECORD;
  v_destination_label TEXT;
  v_trucker_name TEXT;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.trucker_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;

  IF NOT (
    (v_trip.stage = 'assigned' AND p_new_stage = 'pickup_pending') OR
    (v_trip.stage = 'pickup_pending' AND p_new_stage = 'picked_up') OR
    (v_trip.stage = 'picked_up' AND p_new_stage = 'in_transit') OR
    (v_trip.stage = 'in_transit' AND p_new_stage = 'delivered')
  ) THEN
    RAISE EXCEPTION 'Invalid stage transition from % to %', v_trip.stage, p_new_stage;
  END IF;

  UPDATE trips SET
    stage = p_new_stage,
    started_at = CASE WHEN p_new_stage = 'in_transit' THEN NOW() ELSE started_at END,
    delivered_at = CASE WHEN p_new_stage = 'delivered' THEN NOW() ELSE delivered_at END,
    gps_pickup_lat = CASE WHEN p_new_stage = 'pickup_pending' THEN p_gps_lat ELSE gps_pickup_lat END,
    gps_pickup_lng = CASE WHEN p_new_stage = 'pickup_pending' THEN p_gps_lng ELSE gps_pickup_lng END,
    gps_loaded_lat = CASE WHEN p_new_stage = 'picked_up' THEN p_gps_lat ELSE gps_loaded_lat END,
    gps_loaded_lng = CASE WHEN p_new_stage = 'picked_up' THEN p_gps_lng ELSE gps_loaded_lng END,
    gps_delivered_lat = CASE WHEN p_new_stage = 'delivered' THEN p_gps_lat ELSE gps_delivered_lat END,
    gps_delivered_lng = CASE WHEN p_new_stage = 'delivered' THEN p_gps_lng ELSE gps_delivered_lng END
  WHERE id = p_trip_id;

  IF p_new_stage = 'in_transit' THEN
    UPDATE loads SET status = 'in_transit'
    WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
      AND status IN ('assigned_partial', 'assigned_full');
  END IF;

  IF p_new_stage IN ('in_transit', 'delivered') THEN
    SELECT COALESCE(destination_label, 'destination')
    INTO v_destination_label
    FROM loads
    WHERE id = v_trip.load_id;

    SELECT COALESCE(NULLIF(full_name, ''), 'Your trucker')
    INTO v_trucker_name
    FROM profiles
    WHERE id = v_trip.trucker_id;

    INSERT INTO notifications (
      target_profile_id,
      notification_type,
      notification_priority,
      title_text,
      body_text,
      related_load_id,
      related_trip_id,
      action_route_hint
    ) VALUES (
      v_trip.supplier_id,
      'trip_update',
      'medium',
      CASE WHEN p_new_stage = 'in_transit' THEN 'Trip Started' ELSE 'Cargo Delivered' END,
      CASE
        WHEN p_new_stage = 'in_transit' THEN COALESCE(v_trucker_name, 'Your trucker') || ' has started the trip to ' || COALESCE(v_destination_label, 'destination')
        ELSE COALESCE(v_trucker_name, 'Your trucker') || ' has delivered at ' || COALESCE(v_destination_label, 'destination')
      END,
      v_trip.load_id,
      p_trip_id,
      '/trip-detail/' || p_trip_id::text
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION upload_trip_proof(
  p_trip_id UUID,
  p_pod_path TEXT,
  p_lr_path TEXT DEFAULT NULL,
  p_gps_lat DOUBLE PRECISION DEFAULT NULL,
  p_gps_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_trip RECORD;
  v_material TEXT;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.trucker_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;
  IF v_trip.stage != 'delivered' THEN RAISE EXCEPTION 'Trip must be in delivered stage to upload proof'; END IF;

  UPDATE trips SET
    stage = 'proof_submitted',
    pod_document_path = p_pod_path,
    lr_document_path = COALESCE(p_lr_path, lr_document_path),
    pod_uploaded_at = NOW(),
    gps_pod_lat = p_gps_lat,
    gps_pod_lng = p_gps_lng
  WHERE id = p_trip_id;

  SELECT COALESCE(material, 'this trip')
  INTO v_material
  FROM loads
  WHERE id = v_trip.load_id;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    v_trip.supplier_id,
    'proof_update',
    'high',
    'POD Uploaded',
    'Review proof of delivery for ' || COALESCE(v_material, 'this trip'),
    v_trip.load_id,
    p_trip_id,
    '/trip-detail/' || p_trip_id::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION confirm_trip_delivery(p_trip_id UUID)
RETURNS VOID AS $$
DECLARE
  v_trip RECORD;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.supplier_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;
  IF v_trip.stage != 'proof_submitted' THEN RAISE EXCEPTION 'Trip not in proof_submitted stage'; END IF;

  UPDATE trips SET stage = 'completed', completed_at = NOW() WHERE id = p_trip_id;

  UPDATE truckers SET completed_trips = completed_trips + 1 WHERE id = v_trip.trucker_id;

  PERFORM 1 FROM loads child
  JOIN trips t ON t.load_id = child.id
  WHERE child.parent_load_id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
    AND t.stage NOT IN ('completed', 'cancelled')
  LIMIT 1;

  IF NOT FOUND THEN
    UPDATE loads SET status = 'completed'
    WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id);
  END IF;

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    action_route_hint
  ) VALUES (
    v_trip.trucker_id,
    'trip_update',
    'medium',
    'Trip Completed!',
    'Rate your experience for this completed trip.',
    v_trip.load_id,
    p_trip_id,
    '/trip-detail/' || p_trip_id::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION auto_complete_delivered_trips()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_trip RECORD;
BEGIN
  FOR v_trip IN
    SELECT id, supplier_id, trucker_id, load_id FROM trips
    WHERE stage = 'proof_submitted'
      AND pod_uploaded_at < NOW() - INTERVAL '48 hours'
  LOOP
    UPDATE trips SET stage = 'completed', completed_at = NOW() WHERE id = v_trip.id;
    UPDATE truckers SET completed_trips = completed_trips + 1 WHERE id = v_trip.trucker_id;

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
      'medium',
      'Trip Auto-Completed',
      'Trip completed automatically after 48h.',
      v_trip.load_id,
      v_trip.id,
      '/trip-detail/' || v_trip.id::text
    ),
    (
      v_trip.supplier_id,
      'trip_update',
      'medium',
      'Trip Auto-Completed',
      'Trip completed automatically after 48h.',
      v_trip.load_id,
      v_trip.id,
      '/trip-detail/' || v_trip.id::text
    );

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
