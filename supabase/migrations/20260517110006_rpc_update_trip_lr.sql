-- P3.4.7 — RPC to update trip LR document path with stage validation
-- Replaces direct table UPDATE in SupabaseTruckerTripsBackend.uploadTripLr()

CREATE OR REPLACE FUNCTION update_trip_lr(
  p_trip_id UUID,
  p_lr_document_path TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_trip RECORD;
  v_allowed_stages TEXT[] := ARRAY['assigned', 'pickup_initiated', 'lr_uploaded'];
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT id, stage, trucker_id INTO v_trip
  FROM trips
  WHERE id = p_trip_id;

  IF v_trip IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  IF v_trip.trucker_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Trip does not belong to current user';
  END IF;

  IF NOT (v_trip.stage = ANY(v_allowed_stages)) THEN
    RAISE EXCEPTION 'LR upload not allowed in current trip stage: %', v_trip.stage;
  END IF;

  UPDATE trips
  SET lr_document_path = p_lr_document_path,
      updated_at = NOW()
  WHERE id = p_trip_id
  RETURNING id INTO v_trip.id;

  RETURN jsonb_build_object('id', v_trip.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_trip_lr IS
  'Updates LR document path for a trip with stage validation. Replaces direct table UPDATE in Flutter backend.';
