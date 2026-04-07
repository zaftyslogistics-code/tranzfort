-- ═══════════════════════════════════════════════
-- Migration: Fix auto_complete_delivered_trips + reject_booking_request
-- Phase 1-A: auto_complete_delivered_trips now checks/updates parent load
--            to 'completed' when all child trips are done (mirrors
--            confirm_trip_delivery logic from phase7_core_rpcs.sql:300-311).
-- Phase 1-B: reject_booking_request now locks booking row with FOR UPDATE
--            to prevent concurrent reject race condition.
-- ═══════════════════════════════════════════════

-- Phase 1-A: auto_complete_delivered_trips — add parent load completion check
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

    -- Check if all sibling trips under the same parent load are now done
    PERFORM 1 FROM loads child
    JOIN trips t ON t.load_id = child.id
    WHERE child.parent_load_id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id)
      AND t.stage NOT IN ('completed', 'cancelled')
    LIMIT 1;

    IF NOT FOUND THEN
      UPDATE loads SET status = 'completed'
      WHERE id = (SELECT parent_load_id FROM loads WHERE id = v_trip.load_id);
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Phase 1-B: reject_booking_request — add FOR UPDATE row lock
CREATE OR REPLACE FUNCTION reject_booking_request(p_booking_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
  v_booking RECORD;
  v_load RECORD;
BEGIN
  SELECT * INTO v_booking FROM booking_requests WHERE id = p_booking_id FOR UPDATE;
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
