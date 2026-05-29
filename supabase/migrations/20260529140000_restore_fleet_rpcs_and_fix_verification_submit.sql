-- Restore fleet RPCs dropped by 20260517090005_rollback_fleet_rpcs.sql
-- Align submit_verification_for_review with P0.7 (last4 + documents) and supplier/trucker packet rules

-- ═══════════════════════════════════════════════════════════════════════════════
-- Fleet RPCs
-- ═══════════════════════════════════════════════════════════════════════════════

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
        'model', tm.model
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

DROP FUNCTION IF EXISTS add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT);

CREATE OR REPLACE FUNCTION add_truck(
  p_truck_number TEXT,
  p_body_type TEXT,
  p_tyres INTEGER,
  p_capacity_tonnes NUMERIC,
  p_rc_document_path TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_truck_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_truck_number IS NULL OR BTRIM(p_truck_number) = '' THEN
    RAISE EXCEPTION 'Truck number is required';
  END IF;

  IF p_body_type IS NULL OR BTRIM(p_body_type) = '' THEN
    RAISE EXCEPTION 'Body type is required';
  END IF;

  IF p_tyres IS NULL OR p_tyres <= 0 THEN
    RAISE EXCEPTION 'Tyres must be a positive integer';
  END IF;

  IF p_capacity_tonnes IS NULL OR p_capacity_tonnes <= 0 THEN
    RAISE EXCEPTION 'Capacity must be a positive number';
  END IF;

  INSERT INTO trucks (
    owner_id,
    truck_number,
    body_type,
    tyres,
    capacity_tonnes,
    rc_document_path,
    status
  )
  VALUES (
    v_user_id,
    UPPER(BTRIM(p_truck_number)),
    BTRIM(p_body_type),
    p_tyres,
    p_capacity_tonnes,
    BTRIM(p_rc_document_path),
    'pending'
  )
  RETURNING id INTO v_truck_id;

  RETURN jsonb_build_object('id', v_truck_id);
END;
$$;

CREATE OR REPLACE FUNCTION update_truck(
  p_truck_id UUID,
  p_truck_number TEXT,
  p_body_type TEXT,
  p_tyres INTEGER,
  p_capacity_tonnes NUMERIC,
  p_rc_document_path TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_existing_truck RECORD;
  v_critical_fields_changed BOOLEAN;
  v_next_status TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT *
  INTO v_existing_truck
  FROM trucks
  WHERE id = p_truck_id
    AND owner_id = v_user_id
  FOR UPDATE;

  IF v_existing_truck IS NULL THEN
    RAISE EXCEPTION 'Truck not found or not owned by user';
  END IF;

  v_critical_fields_changed := (
    v_existing_truck.truck_number != UPPER(BTRIM(p_truck_number))
    OR v_existing_truck.body_type != BTRIM(p_body_type)
    OR v_existing_truck.tyres != p_tyres
    OR v_existing_truck.capacity_tonnes != p_capacity_tonnes
    OR COALESCE(v_existing_truck.rc_document_path, '') != BTRIM(p_rc_document_path)
  );

  IF v_existing_truck.status = 'verified' AND v_critical_fields_changed THEN
    v_next_status := 'edited_pending_reapproval';
    UPDATE trucks
    SET
      truck_number = UPPER(BTRIM(p_truck_number)),
      body_type = BTRIM(p_body_type),
      tyres = p_tyres,
      capacity_tonnes = p_capacity_tonnes,
      rc_document_path = BTRIM(p_rc_document_path),
      status = v_next_status,
      rejection_reason = NULL,
      verification_feedback_json = NULL,
      verified_at = NULL,
      verified_by_admin_user_id = NULL,
      updated_at = NOW()
    WHERE id = p_truck_id;
  ELSE
    UPDATE trucks
    SET
      truck_number = UPPER(BTRIM(p_truck_number)),
      body_type = BTRIM(p_body_type),
      tyres = p_tyres,
      capacity_tonnes = p_capacity_tonnes,
      rc_document_path = BTRIM(p_rc_document_path),
      updated_at = NOW()
    WHERE id = p_truck_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION archive_truck(p_truck_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE trucks
  SET status = 'archived',
      updated_at = NOW()
  WHERE id = p_truck_id
    AND owner_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Truck not found or not owned by user';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION get_trucker_fleet(UUID, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_truck(UUID, TEXT, TEXT, INTEGER, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION archive_truck(UUID) TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════
-- submit_verification_for_review — P0.7 identity + packet validation
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION submit_verification_for_review()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile RECORD;
  v_supplier RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_subject_type TEXT;
  v_ready_truck_exists BOOLEAN := FALSE;
BEGIN
  SELECT *
  INTO v_profile
  FROM profiles
  WHERE id = auth.uid()
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_profile.user_role_type = 'supplier' THEN
    v_subject_type := 'supplier_profile';
  ELSIF v_profile.user_role_type = 'trucker' THEN
    v_subject_type := 'trucker_profile';
  ELSE
    RAISE EXCEPTION 'User role is not configured for verification';
  END IF;

  IF v_profile.verification_status = 'verified' THEN
    RAISE EXCEPTION 'Profile is already verified';
  END IF;

  IF v_profile.verification_status = 'pending' THEN
    RAISE EXCEPTION 'Verification is already under review';
  END IF;

  -- P0.7: accept last4 columns or legacy full-number columns
  IF NOT (
    length(COALESCE(BTRIM(v_profile.aadhaar_last4), '')) >= 4
    OR length(COALESCE(BTRIM(v_profile.aadhaar_number), '')) >= 4
  ) THEN
    RAISE EXCEPTION 'Aadhaar number is required';
  END IF;

  IF NOT (
    length(COALESCE(BTRIM(v_profile.pan_last4), '')) >= 4
    OR length(COALESCE(BTRIM(v_profile.pan_number), '')) >= 4
  ) THEN
    RAISE EXCEPTION 'PAN number is required';
  END IF;

  IF COALESCE(BTRIM(v_profile.aadhaar_front_document_path), '') = '' THEN
    RAISE EXCEPTION 'Aadhaar front document is required';
  END IF;

  IF COALESCE(BTRIM(v_profile.aadhaar_back_document_path), '') = '' THEN
    RAISE EXCEPTION 'Aadhaar back document is required';
  END IF;

  IF COALESCE(BTRIM(v_profile.pan_document_path), '') = '' THEN
    RAISE EXCEPTION 'PAN document is required';
  END IF;

  IF v_profile.user_role_type = 'supplier' THEN
    SELECT *
    INTO v_supplier
    FROM suppliers
    WHERE id = auth.uid()
    FOR UPDATE;

    IF v_supplier IS NULL THEN
      RAISE EXCEPTION 'Supplier profile not found';
    END IF;

    IF COALESCE(BTRIM(v_supplier.business_licence_number), '') = '' THEN
      RAISE EXCEPTION 'Business licence number is required';
    END IF;

    IF COALESCE(BTRIM(v_supplier.business_licence_document_path), '') = '' THEN
      RAISE EXCEPTION 'Business licence document is required';
    END IF;

    IF COALESCE(BTRIM(v_supplier.verification_location_city), '') = ''
      OR v_supplier.verification_location_lat IS NULL
      OR v_supplier.verification_location_lng IS NULL THEN
      RAISE EXCEPTION 'Supplier verification location is required';
    END IF;
  END IF;

  IF v_profile.user_role_type = 'trucker' THEN
    SELECT EXISTS (
      SELECT 1
      FROM trucks
      WHERE owner_id = auth.uid()
        AND status != 'archived'
        AND COALESCE(BTRIM(truck_number), '') != ''
        AND COALESCE(BTRIM(body_type), '') != ''
        AND COALESCE(tyres, 0) > 0
        AND COALESCE(capacity_tonnes, 0) > 0
        AND COALESCE(BTRIM(rc_document_path), '') != ''
    )
    INTO v_ready_truck_exists;

    IF NOT v_ready_truck_exists THEN
      RAISE EXCEPTION 'At least one complete truck with RC document is required';
    END IF;
  END IF;

  SELECT *
  INTO v_case
  FROM verification_cases
  WHERE subject_type = v_subject_type
    AND subject_id = auth.uid()
    AND review_type = 'full_verification'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NOT NULL
    AND v_case.case_status IN (
      'submitted',
      'queued',
      'in_review',
      'waiting_for_resubmission',
      'approved'
    ) THEN
    RAISE EXCEPTION 'Verification case is already active';
  END IF;

  IF v_case IS NOT NULL AND v_case.case_status = 'rejected' THEN
    UPDATE verification_cases
    SET case_status = 'submitted',
        assigned_admin_user_id = NULL,
        last_reviewed_at = NULL,
        current_decision_summary = NULL,
        current_review_feedback_json = NULL,
        escalated_to_admin_user_id = NULL,
        submitted_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.id;

    v_case_id := v_case.id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    )
    VALUES (
      v_case_id,
      'resubmitted',
      'Verification resubmitted'
    );
  ELSE
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      review_type,
      case_status
    )
    VALUES (
      v_subject_type,
      auth.uid(),
      'full_verification',
      'submitted'
    )
    RETURNING id INTO v_case_id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    )
    VALUES (
      v_case_id,
      'submitted',
      'Verification submitted'
    );
  END IF;

  UPDATE profiles
  SET verification_status = 'pending',
      verification_rejection_reason = NULL,
      verification_feedback_json = NULL,
      updated_at = NOW()
  WHERE id = auth.uid();

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    secondary_object_type,
    secondary_object_id,
    summary_text,
    payload_json,
    visibility_class
  )
  VALUES (
    NULL,
    'user',
    NULL,
    'override_action',
    'profile',
    auth.uid(),
    'verification_case',
    v_case_id,
    'User submitted verification for review',
    jsonb_build_object(
      'subject_type', v_subject_type,
      'review_type', 'full_verification'
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'verification_update',
    'medium',
    'New Verification',
    v_profile.full_name || ' submitted verification',
    v_case_id,
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_case_id;
END;
$$;

CREATE OR REPLACE FUNCTION resubmit_verification_case()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN submit_verification_for_review();
END;
$$;

GRANT EXECUTE ON FUNCTION submit_verification_for_review() TO authenticated;
GRANT EXECUTE ON FUNCTION resubmit_verification_case() TO authenticated;
