ALTER TABLE booking_requests
ADD COLUMN IF NOT EXISTS booking_gps_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS booking_gps_lng DOUBLE PRECISION;

CREATE OR REPLACE FUNCTION submit_booking_request(
  p_load_id UUID,
  p_truck_id UUID,
  p_booking_gps_lat DOUBLE PRECISION DEFAULT NULL,
  p_booking_gps_lng DOUBLE PRECISION DEFAULT NULL
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

  IF (p_booking_gps_lat IS NULL) <> (p_booking_gps_lng IS NULL) THEN
    RAISE EXCEPTION 'Booking GPS latitude/longitude must be provided together';
  END IF;

  INSERT INTO booking_requests (
    load_id,
    trucker_id,
    truck_id,
    status,
    booking_gps_lat,
    booking_gps_lng
  )
  VALUES (
    p_load_id,
    v_trucker_id,
    p_truck_id,
    'submitted',
    p_booking_gps_lat,
    p_booking_gps_lng
  )
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
