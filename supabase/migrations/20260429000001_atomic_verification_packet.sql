-- P1 6.3: Atomic verification packet submission
-- One transaction: identity + docs + location + truck + case creation.

CREATE OR REPLACE FUNCTION submit_verification_packet(
  p_aadhaar_number TEXT DEFAULT NULL,
  p_pan_number TEXT DEFAULT NULL,
  p_aadhaar_front_document_path TEXT DEFAULT NULL,
  p_aadhaar_back_document_path TEXT DEFAULT NULL,
  p_pan_document_path TEXT DEFAULT NULL,
  p_profile_photo_document_path TEXT DEFAULT NULL,
  p_company_name TEXT DEFAULT NULL,
  p_business_licence_number TEXT DEFAULT NULL,
  p_gst_number TEXT DEFAULT NULL,
  p_business_licence_document_path TEXT DEFAULT NULL,
  p_gst_certificate_document_path TEXT DEFAULT NULL,
  p_verification_location_city TEXT DEFAULT NULL,
  p_verification_location_state TEXT DEFAULT NULL,
  p_verification_location_lat NUMERIC DEFAULT NULL,
  p_verification_location_lng NUMERIC DEFAULT NULL,
  p_truck_number TEXT DEFAULT NULL,
  p_truck_body_type TEXT DEFAULT NULL,
  p_truck_tyres INTEGER DEFAULT NULL,
  p_truck_capacity_tonnes NUMERIC DEFAULT NULL,
  p_truck_rc_document_path TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_profile RECORD;
  v_supplier RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_truck_id UUID;
  v_subject_type TEXT;
  v_ready_truck_exists BOOLEAN := FALSE;
BEGIN
  SELECT * INTO v_profile FROM profiles WHERE id = auth.uid() FOR UPDATE;
  IF v_profile IS NULL THEN RAISE EXCEPTION 'Profile not found'; END IF;

  IF v_profile.user_role_type = 'supplier' THEN v_subject_type := 'supplier_profile';
  ELSIF v_profile.user_role_type = 'trucker' THEN v_subject_type := 'trucker_profile';
  ELSE RAISE EXCEPTION 'User role is not configured for verification'; END IF;

  IF v_profile.verification_status = 'verified' THEN RAISE EXCEPTION 'Profile is already verified'; END IF;
  IF v_profile.verification_status = 'pending' THEN RAISE EXCEPTION 'Verification is already under review'; END IF;

  -- Update identity + docs on profiles
  UPDATE profiles SET
    aadhaar_number = COALESCE(p_aadhaar_number, aadhaar_number),
    aadhaar_last4 = CASE WHEN p_aadhaar_number IS NOT NULL AND LENGTH(p_aadhaar_number) >= 4 THEN RIGHT(p_aadhaar_number, 4) ELSE aadhaar_last4 END,
    pan_number = COALESCE(p_pan_number, pan_number),
    aadhaar_front_document_path = COALESCE(p_aadhaar_front_document_path, aadhaar_front_document_path),
    aadhaar_back_document_path = COALESCE(p_aadhaar_back_document_path, aadhaar_back_document_path),
    pan_document_path = COALESCE(p_pan_document_path, pan_document_path),
    profile_photo_document_path = COALESCE(p_profile_photo_document_path, profile_photo_document_path),
    updated_at = NOW()
  WHERE id = auth.uid();

  -- Supplier extension update
  IF v_profile.user_role_type = 'supplier' THEN
    UPDATE suppliers SET
      company_name = COALESCE(p_company_name, company_name),
      business_licence_number = COALESCE(p_business_licence_number, business_licence_number),
      gst_number = COALESCE(p_gst_number, gst_number),
      business_licence_document_path = COALESCE(p_business_licence_document_path, business_licence_document_path),
      gst_certificate_document_path = COALESCE(p_gst_certificate_document_path, gst_certificate_document_path),
      verification_location_city = COALESCE(p_verification_location_city, verification_location_city),
      verification_location_state = COALESCE(p_verification_location_state, verification_location_state),
      verification_location_lat = COALESCE(p_verification_location_lat, verification_location_lat),
      verification_location_lng = COALESCE(p_verification_location_lng, verification_location_lng),
      updated_at = NOW()
    WHERE id = auth.uid();

    SELECT * INTO v_supplier FROM suppliers WHERE id = auth.uid();
    IF COALESCE(BTRIM(v_supplier.business_licence_number), '') = '' THEN RAISE EXCEPTION 'Business licence number is required'; END IF;
    IF COALESCE(BTRIM(v_supplier.business_licence_document_path), '') = '' THEN RAISE EXCEPTION 'Business licence document is required'; END IF;
    IF COALESCE(BTRIM(v_supplier.verification_location_city), '') = '' OR v_supplier.verification_location_lat IS NULL OR v_supplier.verification_location_lng IS NULL THEN
      RAISE EXCEPTION 'Supplier verification location is required';
    END IF;
  END IF;

  -- Trucker: create truck if draft provided
  IF v_profile.user_role_type = 'trucker' AND COALESCE(BTRIM(p_truck_number), '') != '' AND COALESCE(BTRIM(p_truck_body_type), '') != ''
     AND COALESCE(p_truck_tyres, 0) > 0 AND COALESCE(p_truck_capacity_tonnes, 0) > 0 THEN
    INSERT INTO trucks (owner_id, truck_number, body_type, tyres, capacity_tonnes, rc_document_path, status)
    VALUES (auth.uid(), p_truck_number, p_truck_body_type, p_truck_tyres, p_truck_capacity_tonnes, p_truck_rc_document_path, 'pending')
    RETURNING id INTO v_truck_id;
  END IF;

  -- Validate required docs from (now-updated) profile
  SELECT * INTO v_profile FROM profiles WHERE id = auth.uid();
  IF COALESCE(BTRIM(v_profile.aadhaar_number), '') = '' THEN RAISE EXCEPTION 'Aadhaar number is required'; END IF;
  IF COALESCE(BTRIM(v_profile.pan_number), '') = '' THEN RAISE EXCEPTION 'PAN number is required'; END IF;
  IF COALESCE(BTRIM(v_profile.aadhaar_front_document_path), '') = '' THEN RAISE EXCEPTION 'Aadhaar front document is required'; END IF;
  IF COALESCE(BTRIM(v_profile.aadhaar_back_document_path), '') = '' THEN RAISE EXCEPTION 'Aadhaar back document is required'; END IF;
  IF COALESCE(BTRIM(v_profile.pan_document_path), '') = '' THEN RAISE EXCEPTION 'PAN document is required'; END IF;

  -- Trucker: verify at least one complete truck exists
  IF v_profile.user_role_type = 'trucker' THEN
    SELECT EXISTS (SELECT 1 FROM trucks WHERE owner_id = auth.uid() AND status != 'archived'
      AND COALESCE(BTRIM(truck_number), '') != '' AND COALESCE(BTRIM(body_type), '') != ''
      AND COALESCE(tyres, 0) > 0 AND COALESCE(capacity_tonnes, 0) > 0 AND COALESCE(BTRIM(rc_document_path), '') != '')
    INTO v_ready_truck_exists;
    IF NOT v_ready_truck_exists THEN RAISE EXCEPTION 'At least one complete truck with RC document is required'; END IF;
  END IF;

  -- Case management (same logic as submit_verification_for_review)
  SELECT * INTO v_case FROM verification_cases WHERE subject_type = v_subject_type AND subject_id = auth.uid()
  ORDER BY created_at DESC LIMIT 1 FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted','queued','in_review','waiting_for_resubmission','approved') THEN
    RAISE EXCEPTION 'Verification case is already active';
  END IF;

  IF v_case IS NOT NULL AND v_case.case_status = 'rejected' THEN
    UPDATE verification_cases SET case_status = 'submitted', assigned_admin_user_id = NULL,
      last_reviewed_at = NULL, current_decision_summary = NULL, current_review_feedback_json = NULL,
      escalated_to_admin_user_id = NULL, submitted_at = NOW(), updated_at = NOW() WHERE id = v_case.id;
    v_case_id := v_case.id;
    INSERT INTO verification_case_events (verification_case_id, event_type, event_summary)
    VALUES (v_case_id, 'resubmitted', 'Verification resubmitted');
  ELSE
    INSERT INTO verification_cases (subject_type, subject_id, case_status)
    VALUES (v_subject_type, auth.uid(), 'submitted') RETURNING id INTO v_case_id;
    INSERT INTO verification_case_events (verification_case_id, event_type, event_summary)
    VALUES (v_case_id, 'submitted', 'Verification submitted');
  END IF;

  UPDATE profiles SET verification_status = 'pending', verification_rejection_reason = NULL,
    verification_feedback_json = NULL, updated_at = NOW() WHERE id = auth.uid();

  RETURN v_case_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_verification_packet(
  TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,
  TEXT,TEXT,NUMERIC,NUMERIC,TEXT,TEXT,INTEGER,NUMERIC,TEXT
) TO authenticated;
