-- ============================================================================
-- Fix: auto_complete_delivered_trips skips parent load completion (F-B9-002)
-- Previously: updated trip to completed but did NOT update parent load status
-- Now: matches confirm_trip_delivery logic — checks if all child trips done
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_complete_delivered_trips()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_trip RECORD;
  v_parent_load_id UUID;
BEGIN
  FOR v_trip IN
    SELECT id, trucker_id, load_id FROM trips
    WHERE stage = 'proof_submitted'
      AND pod_uploaded_at < NOW() - INTERVAL '48 hours'
  LOOP
    UPDATE trips SET stage = 'completed', completed_at = NOW() WHERE id = v_trip.id;
    UPDATE truckers SET completed_trips = completed_trips + 1 WHERE id = v_trip.trucker_id;

    -- Check if all child trips for the parent load are now completed/cancelled
    SELECT parent_load_id INTO v_parent_load_id FROM loads WHERE id = v_trip.load_id;

    IF v_parent_load_id IS NOT NULL THEN
      PERFORM 1 FROM loads child
      JOIN trips t ON t.load_id = child.id
      WHERE child.parent_load_id = v_parent_load_id
        AND t.stage NOT IN ('completed', 'cancelled')
      LIMIT 1;

      IF NOT FOUND THEN
        UPDATE loads SET status = 'completed'
        WHERE id = v_parent_load_id
          AND status NOT IN ('completed', 'cancelled');
      END IF;
    END IF;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
