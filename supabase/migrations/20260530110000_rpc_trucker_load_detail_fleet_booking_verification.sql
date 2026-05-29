-- §H-2.4b: Trucker load detail — fleet + latest booking via RPC
-- §H-3.1 (reads): Verification wizard profile/supplier/truck counts via RPC

-- Extend fleet RPC with truck_models fields used by load-detail booking UI
CREATE OR REPLACE FUNCTION get_trucker_fleet(
  p_user_id UUID,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_trucks JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user_id IS DISTINCT FROM auth.uid() AND NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized to view this fleet';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'truck_model_id', t.truck_model_id,
      'truck_number', t.truck_number,
      'body_type', t.body_type,
      'tyres', t.tyres,
      'capacity_tonnes', t.capacity_tonnes,
      'rc_document_path', t.rc_document_path,
      'status', t.status,
      'rejection_reason', t.rejection_reason,
      'verification_feedback_json', t.verification_feedback_json,
      'verified_at', t.verified_at,
      'created_at', t.created_at,
      'updated_at', t.updated_at,
      'truck_models', jsonb_build_object(
        'make', tm.make,
        'model', tm.model,
        'axles', tm.axles,
        'payload_kg', tm.payload_kg,
        'mileage_empty_kmpl', tm.mileage_empty_kmpl,
        'mileage_loaded_kmpl', tm.mileage_loaded_kmpl
      )
    )
  )
  INTO v_trucks
  FROM (
    SELECT t.*
    FROM trucks t
    WHERE t.owner_id = p_user_id
      AND t.status != 'archived'
    ORDER BY t.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t
  LEFT JOIN truck_models tm ON tm.id = t.truck_model_id;

  RETURN COALESCE(v_trucks, '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION get_trucker_latest_booking_for_load(p_load_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(br)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      truck_id,
      status,
      decision_reason,
      created_at,
      decided_at
    FROM booking_requests
    WHERE load_id = p_load_id
      AND trucker_id = auth.uid()
    ORDER BY created_at DESC
    LIMIT 1
  ) br;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION get_trucker_latest_booking_for_load IS
  'Latest booking request by current trucker for a load. Replaces direct booking_requests read in load detail.';

GRANT EXECUTE ON FUNCTION get_trucker_latest_booking_for_load(UUID) TO authenticated;

-- Verification wizard: own profile (sensitive verification fields only)
CREATE OR REPLACE FUNCTION get_verification_profile()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_result JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(p)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      user_role_type,
      verification_status,
      verification_rejection_reason,
      verification_feedback_json,
      aadhaar_last4,
      aadhaar_front_document_path,
      aadhaar_back_document_path,
      pan_last4,
      pan_number,
      pan_document_path,
      profile_photo_document_path
    FROM profiles
    WHERE id = v_user_id
  ) p;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION get_verification_profile IS
  'Verification wizard profile row for the authenticated user only.';

GRANT EXECUTE ON FUNCTION get_verification_profile() TO authenticated;

-- Verification wizard: own supplier extension (document paths + location)
CREATE OR REPLACE FUNCTION get_supplier_verification_extension()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_result JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(s)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      company_name,
      business_licence_document_path,
      gst_certificate_document_path,
      verification_location_city,
      verification_location_state,
      verification_location_lat,
      verification_location_lng,
      business_licence_number,
      gst_number
    FROM suppliers
    WHERE id = v_user_id
  ) s;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION get_supplier_verification_extension IS
  'Supplier verification extension for the authenticated supplier only.';

GRANT EXECUTE ON FUNCTION get_supplier_verification_extension() TO authenticated;

CREATE OR REPLACE FUNCTION get_trucker_truck_verification_counts()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_approved INT;
  v_ready INT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT COUNT(*)::INT
  INTO v_approved
  FROM trucks
  WHERE owner_id = v_user_id
    AND status = 'verified';

  SELECT COUNT(*)::INT
  INTO v_ready
  FROM trucks
  WHERE owner_id = v_user_id
    AND status != 'archived'
    AND COALESCE(BTRIM(rc_document_path), '') <> '';

  RETURN jsonb_build_object(
    'approved_count', COALESCE(v_approved, 0),
    'verification_ready_count', COALESCE(v_ready, 0)
  );
END;
$$;

COMMENT ON FUNCTION get_trucker_truck_verification_counts IS
  'Truck counts for verification wizard (approved + RC-ready non-archived).';

GRANT EXECUTE ON FUNCTION get_trucker_truck_verification_counts() TO authenticated;
