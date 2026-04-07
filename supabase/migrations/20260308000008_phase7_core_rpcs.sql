-- ============================================================================
-- TranZfort Rebuild — Phase 7b: Core RPCs
-- Source of truth: docs/32-schema-rpc-catalog.md
-- docs/33-schema-enum-and-state-transition-catalog.md §3
-- RULE: Critical transitions MUST use RPCs, not direct table writes.
-- ============================================================================

-- ═══════════════════════════════════════════════
-- RPC: create_load (Supplier posts a new load)
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION create_load(
  p_origin_label TEXT, p_origin_city TEXT, p_origin_state TEXT,
  p_origin_lat DOUBLE PRECISION, p_origin_lng DOUBLE PRECISION,
  p_destination_label TEXT, p_destination_city TEXT, p_destination_state TEXT,
  p_destination_lat DOUBLE PRECISION, p_destination_lng DOUBLE PRECISION,
  p_route_distance_km NUMERIC, p_route_duration_minutes INTEGER,
  p_route_polyline TEXT, p_route_snapshot_source TEXT,
  p_material TEXT, p_weight_tonnes NUMERIC,
  p_required_body_type TEXT, p_required_tyres INTEGER[],
  p_trucks_needed INTEGER, p_price_amount NUMERIC,
  p_price_type price_type, p_advance_percentage INTEGER,
  p_pickup_date DATE
)
RETURNS UUID AS $$
DECLARE
  v_load_id UUID;
  v_supplier_id UUID;
BEGIN
  -- Verify caller is a supplier
  SELECT id INTO v_supplier_id FROM suppliers WHERE id = auth.uid();
  IF v_supplier_id IS NULL THEN
    RAISE EXCEPTION 'Not a supplier';
  END IF;

  INSERT INTO loads (
    supplier_id, origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage,
    pickup_date, status, published_at
  ) VALUES (
    v_supplier_id, p_origin_label, p_origin_city, p_origin_state, p_origin_lat, p_origin_lng,
    p_destination_label, p_destination_city, p_destination_state, p_destination_lat, p_destination_lng,
    p_route_distance_km, p_route_duration_minutes, p_route_polyline, p_route_snapshot_source,
    p_material, p_weight_tonnes, p_required_body_type, p_required_tyres,
    p_trucks_needed, p_price_amount, p_price_type, p_advance_percentage,
    p_pickup_date, 'active', NOW()
  ) RETURNING id INTO v_load_id;

  -- Update supplier counters
  UPDATE suppliers SET
    total_loads_posted = total_loads_posted + 1,
    active_loads_count = active_loads_count + 1
  WHERE id = v_supplier_id;

  RETURN v_load_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: submit_booking_request (Trucker books a load)
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION submit_booking_request(
  p_load_id UUID, p_truck_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_booking_id UUID;
  v_trucker_id UUID;
  v_load RECORD;
  v_truck RECORD;
BEGIN
  v_trucker_id := auth.uid();

  -- Verify trucker is verified
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_trucker_id AND verification_status = 'verified') THEN
    RAISE EXCEPTION 'Trucker not verified';
  END IF;

  -- Lock and validate load
  SELECT * INTO v_load FROM loads WHERE id = p_load_id AND parent_load_id IS NULL FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.status NOT IN ('active', 'assigned_partial') THEN RAISE EXCEPTION 'Load not available for booking'; END IF;
  IF v_load.trucks_booked >= v_load.trucks_needed THEN RAISE EXCEPTION 'Load fully booked'; END IF;

  -- Verify truck is verified and owned by trucker
  SELECT * INTO v_truck FROM trucks WHERE id = p_truck_id AND owner_id = v_trucker_id;
  IF v_truck IS NULL THEN RAISE EXCEPTION 'Truck not found'; END IF;
  IF v_truck.status != 'verified' THEN RAISE EXCEPTION 'Truck not verified'; END IF;

  -- Check no duplicate active booking
  IF EXISTS (SELECT 1 FROM booking_requests WHERE load_id = p_load_id AND trucker_id = v_trucker_id AND status = 'submitted') THEN
    RAISE EXCEPTION 'Already booked this load';
  END IF;

  INSERT INTO booking_requests (load_id, trucker_id, truck_id, status)
  VALUES (p_load_id, v_trucker_id, p_truck_id, 'submitted')
  RETURNING id INTO v_booking_id;

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: approve_booking_request (Supplier approves → creates trip + child load)
-- Per doc 33 §3.3 and §3.5
-- ═══════════════════════════════════════════════
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

  -- Lock booking
  SELECT * INTO v_booking FROM booking_requests WHERE id = p_booking_id FOR UPDATE;
  IF v_booking IS NULL THEN RAISE EXCEPTION 'Booking not found'; END IF;
  IF v_booking.status != 'submitted' THEN RAISE EXCEPTION 'Booking not in submitted state'; END IF;

  -- Lock parent load and verify ownership
  SELECT * INTO v_load FROM loads WHERE id = v_booking.load_id FOR UPDATE;
  IF v_load.supplier_id != v_supplier_id THEN RAISE EXCEPTION 'Not your load'; END IF;
  IF v_load.status NOT IN ('active', 'assigned_partial') THEN RAISE EXCEPTION 'Load not available'; END IF;

  -- Approve the booking
  UPDATE booking_requests SET status = 'approved', decided_at = NOW() WHERE id = p_booking_id;

  -- Create child load for this assignment
  INSERT INTO loads (
    supplier_id, parent_load_id,
    origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    trucks_needed, price_amount, price_type, advance_percentage, pickup_date,
    status, assigned_trucker_id, assigned_truck_id, published_at,
    is_super_load, super_status
  ) SELECT
    supplier_id, v_load.id,
    origin_label, origin_city, origin_state, origin_lat, origin_lng,
    destination_label, destination_city, destination_state, destination_lat, destination_lng,
    route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source,
    material, weight_tonnes, required_body_type, required_tyres,
    1, price_amount, price_type, advance_percentage, pickup_date,
    'assigned_full', v_booking.trucker_id, v_booking.truck_id, NOW(),
    is_super_load, super_status
  FROM loads WHERE id = v_load.id
  RETURNING id INTO v_child_load_id;

  -- Create trip
  INSERT INTO trips (load_id, supplier_id, trucker_id, truck_id, stage, assigned_at)
  VALUES (v_child_load_id, v_supplier_id, v_booking.trucker_id, v_booking.truck_id, 'assigned', NOW())
  RETURNING id INTO v_trip_id;

  -- Update parent load counters
  UPDATE loads SET
    trucks_booked = trucks_booked + 1,
    status = CASE
      WHEN trucks_booked + 1 >= trucks_needed THEN 'assigned_full'::load_status
      ELSE 'assigned_partial'::load_status
    END
  WHERE id = v_load.id;

  -- Supersede other submitted bookings if load is now fully booked
  IF (v_load.trucks_booked + 1 >= v_load.trucks_needed) THEN
    UPDATE booking_requests SET status = 'superseded'
    WHERE load_id = v_load.id AND status = 'submitted' AND id != p_booking_id;
  END IF;

  RETURN v_trip_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: reject_booking_request
-- ═══════════════════════════════════════════════
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: advance_trip_stage (Trucker advances trip through stages)
-- Per doc 33 §3.6
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION advance_trip_stage(
  p_trip_id UUID,
  p_new_stage trip_stage,
  p_gps_lat DOUBLE PRECISION DEFAULT NULL,
  p_gps_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_trip RECORD;
BEGIN
  SELECT * INTO v_trip FROM trips WHERE id = p_trip_id FOR UPDATE;
  IF v_trip IS NULL THEN RAISE EXCEPTION 'Trip not found'; END IF;
  IF v_trip.trucker_id != auth.uid() THEN RAISE EXCEPTION 'Not your trip'; END IF;

  -- Validate allowed transitions per doc 33 §3.6
  IF NOT (
    (v_trip.stage = 'assigned' AND p_new_stage = 'pickup_pending') OR
    (v_trip.stage = 'pickup_pending' AND p_new_stage = 'picked_up') OR
    (v_trip.stage = 'picked_up' AND p_new_stage = 'in_transit') OR
    (v_trip.stage = 'in_transit' AND p_new_stage = 'delivered')
  ) THEN
    RAISE EXCEPTION 'Invalid stage transition from % to %', v_trip.stage, p_new_stage;
  END IF;

  -- Update trip stage + GPS + timestamps
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

  -- Update parent load status to in_transit if first trip starts
  IF p_new_stage = 'in_transit' THEN
    UPDATE loads SET status = 'in_transit'
    WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
      AND status NOT IN ('completed', 'cancelled', 'in_transit');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: upload_trip_proof (POD/LR upload → proof_submitted)
-- ═══════════════════════════════════════════════
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: confirm_trip_delivery (Supplier confirms → completed)
-- ═══════════════════════════════════════════════
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

  -- Increment trucker completed trips counter
  UPDATE truckers SET completed_trips = completed_trips + 1 WHERE id = v_trip.trucker_id;

  -- Update parent load to completed if all child trips are done
  PERFORM 1 FROM loads child
  JOIN trips t ON t.load_id = child.id
  WHERE child.parent_load_id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
    AND t.stage NOT IN ('completed', 'cancelled')
  LIMIT 1;

  IF NOT FOUND THEN
    UPDATE loads SET status = 'completed'
    WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: cancel_load (Supplier cancels a load)
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION cancel_load(p_load_id UUID)
RETURNS VOID AS $$
DECLARE
  v_load RECORD;
BEGIN
  SELECT * INTO v_load FROM loads WHERE id = p_load_id FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.supplier_id != auth.uid() AND NOT is_admin() THEN RAISE EXCEPTION 'Not authorized'; END IF;
  IF v_load.status NOT IN ('active', 'draft') THEN RAISE EXCEPTION 'Load cannot be cancelled in current state'; END IF;

  UPDATE loads SET status = 'cancelled' WHERE id = p_load_id;

  -- Update supplier counters
  IF v_load.status = 'active' THEN
    UPDATE suppliers SET active_loads_count = GREATEST(active_loads_count - 1, 0)
    WHERE id = v_load.supplier_id;
  END IF;

  -- Cancel pending bookings
  UPDATE booking_requests SET status = 'superseded'
  WHERE load_id = p_load_id AND status = 'submitted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: create_or_get_conversation (Chat with uniqueness enforcement)
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION create_or_get_conversation(
  p_supplier_id UUID, p_trucker_id UUID, p_load_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_conv_id UUID;
BEGIN
  -- Check existing
  SELECT id INTO v_conv_id FROM conversations
  WHERE supplier_id = p_supplier_id AND trucker_id = p_trucker_id AND load_id = p_load_id;

  IF v_conv_id IS NOT NULL THEN RETURN v_conv_id; END IF;

  -- Create new
  INSERT INTO conversations (supplier_id, trucker_id, load_id)
  VALUES (p_supplier_id, p_trucker_id, p_load_id)
  RETURNING id INTO v_conv_id;

  RETURN v_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: send_message (Chat message with participant validation)
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION send_message(
  p_conversation_id UUID,
  p_message_type message_type,
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

  -- Verify sender is a participant
  IF auth.uid() NOT IN (v_conv.supplier_id, v_conv.trucker_id) THEN
    RAISE EXCEPTION 'Not a participant in this conversation';
  END IF;

  INSERT INTO messages (conversation_id, sender_profile_id, message_type, text_body, attachment_path, structured_payload)
  VALUES (p_conversation_id, auth.uid(), p_message_type, p_text_body, p_attachment_path, p_structured_payload)
  RETURNING id INTO v_msg_id;

  -- Update conversation last_message_at
  UPDATE conversations SET last_message_at = NOW() WHERE id = p_conversation_id;

  RETURN v_msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: mark_notification_read / mark_all_notifications_read
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE notifications SET is_read = TRUE, read_at = NOW()
  WHERE id = p_notification_id AND target_profile_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS VOID AS $$
BEGIN
  UPDATE notifications SET is_read = TRUE, read_at = NOW()
  WHERE target_profile_id = auth.uid() AND is_read = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: submit_rating
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION submit_rating(
  p_load_id UUID, p_score INTEGER, p_comment TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_rating_id UUID;
  v_trip RECORD;
  v_reviewer_role user_role;
  v_reviewee_id UUID;
BEGIN
  -- Find completed trip for this load where caller is a participant
  SELECT t.* INTO v_trip FROM trips t
  WHERE t.load_id = p_load_id AND t.stage = 'completed'
    AND (t.trucker_id = auth.uid() OR t.supplier_id = auth.uid())
  LIMIT 1;

  IF v_trip IS NULL THEN RAISE EXCEPTION 'No completed trip found for rating'; END IF;

  -- Determine roles
  IF v_trip.trucker_id = auth.uid() THEN
    v_reviewer_role := 'trucker';
    v_reviewee_id := v_trip.supplier_id;
  ELSE
    v_reviewer_role := 'supplier';
    v_reviewee_id := v_trip.trucker_id;
  END IF;

  INSERT INTO ratings (load_id, trip_id, reviewer_id, reviewee_id, reviewer_role, score, comment)
  VALUES (p_load_id, v_trip.id, auth.uid(), v_reviewee_id, v_reviewer_role, p_score, p_comment)
  RETURNING id INTO v_rating_id;

  RETURN v_rating_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════
-- RPC: auto_complete_delivered_trips (pg_cron job — 48h auto-complete)
-- Per doc 61 §7
-- ═══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION auto_complete_delivered_trips()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_trip RECORD;
BEGIN
  FOR v_trip IN
    SELECT id, trucker_id, load_id FROM trips
    WHERE stage = 'proof_submitted'
      AND pod_uploaded_at < NOW() - INTERVAL '48 hours'
  LOOP
    UPDATE trips SET stage = 'completed', completed_at = NOW() WHERE id = v_trip.id;
    UPDATE truckers SET completed_trips = completed_trips + 1 WHERE id = v_trip.trucker_id;
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
