CREATE OR REPLACE FUNCTION get_trip_dispute_summary(
  p_trip_id UUID
)
RETURNS TABLE (
  category TEXT,
  status TEXT,
  updated_at TIMESTAMPTZ
) AS $$
DECLARE
  v_trip RECORD;
BEGIN
  SELECT id, supplier_id, trucker_id
  INTO v_trip
  FROM trips
  WHERE id = p_trip_id;

  IF v_trip IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  IF auth.uid() IS DISTINCT FROM v_trip.supplier_id
     AND auth.uid() IS DISTINCT FROM v_trip.trucker_id THEN
    RAISE EXCEPTION 'Not allowed to view this trip dispute summary';
  END IF;

  RETURN QUERY
  SELECT
    st.category::TEXT,
    st.status::TEXT,
    st.updated_at
  FROM support_tickets st
  WHERE st.related_trip_id = p_trip_id
    AND st.category IN (
      'loaded_quantity_mismatch',
      'unloaded_quantity_mismatch',
      'document_mismatch',
      'non_payment',
      'fake_payout_proof',
      'delay_or_no_show',
      'damage_or_shortage',
      'abusive_behavior',
      'spam_or_scam',
      'other',
      'trip_dispute'
    )
  ORDER BY st.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
