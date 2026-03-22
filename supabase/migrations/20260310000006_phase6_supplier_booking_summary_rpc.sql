CREATE OR REPLACE FUNCTION get_supplier_booking_requests(p_load_id UUID)
RETURNS TABLE (
  id UUID,
  load_id UUID,
  trucker_id UUID,
  truck_id UUID,
  status booking_status,
  decision_reason TEXT,
  created_at TIMESTAMPTZ,
  decided_at TIMESTAMPTZ,
  trucker_name TEXT,
  trucker_verification_status verification_status,
  trucker_rating NUMERIC,
  truck_number TEXT,
  truck_body_type TEXT,
  truck_tyres INTEGER,
  truck_model_label TEXT
) AS $$
DECLARE
  v_supplier_id UUID;
BEGIN
  v_supplier_id := auth.uid();

  IF NOT EXISTS (
    SELECT 1
    FROM loads
    WHERE id = p_load_id
      AND supplier_id = v_supplier_id
  ) THEN
    RAISE EXCEPTION 'Load not found';
  END IF;

  RETURN QUERY
  SELECT
    br.id,
    br.load_id,
    br.trucker_id,
    br.truck_id,
    br.status,
    br.decision_reason,
    br.created_at,
    br.decided_at,
    COALESCE(NULLIF(p.full_name, ''), 'Trucker') AS trucker_name,
    COALESCE(p.verification_status, 'unverified'::verification_status) AS trucker_verification_status,
    COALESCE(tkr.rating, 0) AS trucker_rating,
    tr.truck_number,
    tr.body_type AS truck_body_type,
    tr.tyres AS truck_tyres,
    CASE
      WHEN tm.make IS NOT NULL AND tm.model IS NOT NULL THEN tm.make || ' ' || tm.model
      WHEN tm.make IS NOT NULL THEN tm.make
      WHEN tm.model IS NOT NULL THEN tm.model
      ELSE NULL
    END AS truck_model_label
  FROM booking_requests br
  JOIN loads l
    ON l.id = br.load_id
  LEFT JOIN profiles p
    ON p.id = br.trucker_id
  LEFT JOIN truckers tkr
    ON tkr.id = br.trucker_id
  LEFT JOIN trucks tr
    ON tr.id = br.truck_id
  LEFT JOIN truck_models tm
    ON tm.id = tr.truck_model_id
  WHERE br.load_id = p_load_id
    AND l.supplier_id = v_supplier_id
  ORDER BY br.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
