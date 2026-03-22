ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS aadhaar_number TEXT,
ADD COLUMN IF NOT EXISTS aadhaar_last4 TEXT,
ADD COLUMN IF NOT EXISTS pan_number TEXT;

DROP FUNCTION IF EXISTS submit_verification_for_review();

CREATE OR REPLACE FUNCTION submit_verification_for_review()
RETURNS UUID AS $$
DECLARE
  v_profile RECORD;
  v_supplier RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_subject_type TEXT;
  v_ready_truck_exists BOOLEAN := FALSE;
BEGIN
  SELECT * INTO v_profile
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

  IF COALESCE(BTRIM(v_profile.aadhaar_number), '') = '' THEN
    RAISE EXCEPTION 'Aadhaar number is required';
  END IF;

  IF COALESCE(BTRIM(v_profile.pan_number), '') = '' THEN
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
    SELECT * INTO v_supplier
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

    IF COALESCE(BTRIM(v_supplier.verification_location_city), '') = '' OR
       v_supplier.verification_location_lat IS NULL OR
       v_supplier.verification_location_lng IS NULL THEN
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
    ) INTO v_ready_truck_exists;

    IF NOT v_ready_truck_exists THEN
      RAISE EXCEPTION 'At least one complete truck with RC document is required';
    END IF;
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = v_subject_type
    AND subject_id = auth.uid()
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'approved') THEN
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
    ) VALUES (
      v_case_id,
      'resubmitted',
      'Verification resubmitted'
    );
  ELSE
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      case_status
    ) VALUES (
      v_subject_type,
      auth.uid(),
      'submitted'
    ) RETURNING id INTO v_case_id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    ) VALUES (
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
  ) VALUES (
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
      'truck_packet_required', v_profile.user_role_type = 'trucker'
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS resubmit_verification_case();

CREATE OR REPLACE FUNCTION resubmit_verification_case()
RETURNS UUID AS $$
BEGIN
  RETURN submit_verification_for_review();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
