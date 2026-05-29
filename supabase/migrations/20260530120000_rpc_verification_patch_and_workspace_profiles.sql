-- §H-3.1b: Verification draft writes via RPC (whitelisted patches)
-- §H-3.2: Own workspace profile reads (supplier/trucker settings)

-- Extend current-user profile with verification_status for settings screens
CREATE OR REPLACE FUNCTION get_current_user_profile()
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
      full_name,
      mobile,
      email,
      user_role_type,
      verification_status,
      preferred_language,
      is_banned,
      account_deletion_status,
      trust_safety_status,
      ban_reason,
      data_deletion_requested_at,
      avatar_url,
      profile_photo_document_path
    FROM profiles
    WHERE id = v_user_id
  ) p;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION get_supplier_workspace_profile()
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
      business_licence_number,
      gst_number,
      total_loads_posted,
      active_loads_count
    FROM suppliers
    WHERE id = v_user_id
  ) s;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION get_supplier_workspace_profile IS
  'Supplier workspace fields for the authenticated supplier (settings / profile screen).';

GRANT EXECUTE ON FUNCTION get_supplier_workspace_profile() TO authenticated;

CREATE OR REPLACE FUNCTION get_trucker_workspace_profile()
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

  SELECT row_to_json(t)::jsonb
  INTO v_result
  FROM (
    SELECT id, dl_number, rating, total_trips, completed_trips
    FROM truckers
    WHERE id = v_user_id
  ) t;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION get_trucker_workspace_profile IS
  'Trucker workspace fields for the authenticated trucker (settings / profile screen).';

GRANT EXECUTE ON FUNCTION get_trucker_workspace_profile() TO authenticated;

-- Truck counts: add total (non-archived) for profile screen
CREATE OR REPLACE FUNCTION get_trucker_truck_verification_counts()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_approved INT;
  v_ready INT;
  v_total INT;
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

  SELECT COUNT(*)::INT
  INTO v_total
  FROM trucks
  WHERE owner_id = v_user_id;

  RETURN jsonb_build_object(
    'approved_count', COALESCE(v_approved, 0),
    'verification_ready_count', COALESCE(v_ready, 0),
    'total_count', COALESCE(v_total, 0)
  );
END;
$$;

CREATE OR REPLACE FUNCTION patch_verification_profile_fields(p_patch JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_key TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_patch IS NULL OR p_patch = '{}'::jsonb THEN
    RETURN '{}'::jsonb;
  END IF;

  FOR v_key IN SELECT jsonb_object_keys(p_patch)
  LOOP
    IF v_key NOT IN (
      'aadhaar_last4',
      'pan_last4',
      'pan_number',
      'aadhaar_front_document_path',
      'aadhaar_back_document_path',
      'pan_document_path',
      'profile_photo_document_path'
    ) THEN
      RAISE EXCEPTION 'Invalid profile field: %', v_key;
    END IF;
  END LOOP;

  UPDATE profiles
  SET
    aadhaar_last4 = CASE WHEN p_patch ? 'aadhaar_last4' THEN NULLIF(p_patch->>'aadhaar_last4', '') ELSE aadhaar_last4 END,
    pan_last4 = CASE WHEN p_patch ? 'pan_last4' THEN NULLIF(p_patch->>'pan_last4', '') ELSE pan_last4 END,
    pan_number = CASE WHEN p_patch ? 'pan_number' THEN NULLIF(p_patch->>'pan_number', '') ELSE pan_number END,
    aadhaar_front_document_path = CASE WHEN p_patch ? 'aadhaar_front_document_path' THEN NULLIF(p_patch->>'aadhaar_front_document_path', '') ELSE aadhaar_front_document_path END,
    aadhaar_back_document_path = CASE WHEN p_patch ? 'aadhaar_back_document_path' THEN NULLIF(p_patch->>'aadhaar_back_document_path', '') ELSE aadhaar_back_document_path END,
    pan_document_path = CASE WHEN p_patch ? 'pan_document_path' THEN NULLIF(p_patch->>'pan_document_path', '') ELSE pan_document_path END,
    profile_photo_document_path = CASE WHEN p_patch ? 'profile_photo_document_path' THEN NULLIF(p_patch->>'profile_photo_document_path', '') ELSE profile_photo_document_path END,
    updated_at = NOW()
  WHERE id = v_user_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

COMMENT ON FUNCTION patch_verification_profile_fields IS
  'Whitelisted profile field updates for verification wizard drafts (auth user only).';

GRANT EXECUTE ON FUNCTION patch_verification_profile_fields(JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION patch_verification_supplier_fields(p_patch JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_key TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_patch IS NULL OR p_patch = '{}'::jsonb THEN
    RETURN '{}'::jsonb;
  END IF;

  FOR v_key IN SELECT jsonb_object_keys(p_patch)
  LOOP
    IF v_key NOT IN (
      'company_name',
      'business_licence_number',
      'gst_number',
      'business_licence_document_path',
      'gst_certificate_document_path',
      'verification_location_city',
      'verification_location_state',
      'verification_location_lat',
      'verification_location_lng'
    ) THEN
      RAISE EXCEPTION 'Invalid supplier field: %', v_key;
    END IF;
  END LOOP;

  UPDATE suppliers
  SET
    company_name = CASE WHEN p_patch ? 'company_name' THEN NULLIF(p_patch->>'company_name', '') ELSE company_name END,
    business_licence_number = CASE WHEN p_patch ? 'business_licence_number' THEN NULLIF(p_patch->>'business_licence_number', '') ELSE business_licence_number END,
    gst_number = CASE WHEN p_patch ? 'gst_number' THEN NULLIF(p_patch->>'gst_number', '') ELSE gst_number END,
    business_licence_document_path = CASE WHEN p_patch ? 'business_licence_document_path' THEN NULLIF(p_patch->>'business_licence_document_path', '') ELSE business_licence_document_path END,
    gst_certificate_document_path = CASE WHEN p_patch ? 'gst_certificate_document_path' THEN NULLIF(p_patch->>'gst_certificate_document_path', '') ELSE gst_certificate_document_path END,
    verification_location_city = CASE WHEN p_patch ? 'verification_location_city' THEN NULLIF(p_patch->>'verification_location_city', '') ELSE verification_location_city END,
    verification_location_state = CASE WHEN p_patch ? 'verification_location_state' THEN NULLIF(p_patch->>'verification_location_state', '') ELSE verification_location_state END,
    verification_location_lat = CASE WHEN p_patch ? 'verification_location_lat' THEN (p_patch->>'verification_location_lat')::DOUBLE PRECISION ELSE verification_location_lat END,
    verification_location_lng = CASE WHEN p_patch ? 'verification_location_lng' THEN (p_patch->>'verification_location_lng')::DOUBLE PRECISION ELSE verification_location_lng END,
    updated_at = NOW()
  WHERE id = v_user_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

COMMENT ON FUNCTION patch_verification_supplier_fields IS
  'Whitelisted supplier field updates for verification wizard drafts (auth user only).';

GRANT EXECUTE ON FUNCTION patch_verification_supplier_fields(JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION update_supplier_business_fields(
  p_company_name TEXT,
  p_business_licence_number TEXT DEFAULT NULL,
  p_gst_number TEXT DEFAULT NULL
)
RETURNS JSONB
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

  UPDATE suppliers
  SET
    company_name = NULLIF(BTRIM(p_company_name), ''),
    business_licence_number = NULLIF(BTRIM(p_business_licence_number), ''),
    gst_number = NULLIF(BTRIM(p_gst_number), ''),
    updated_at = NOW()
  WHERE id = v_user_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

GRANT EXECUTE ON FUNCTION update_supplier_business_fields(TEXT, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION update_trucker_dl_number(p_dl_number TEXT)
RETURNS JSONB
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

  UPDATE truckers
  SET
    dl_number = NULLIF(BTRIM(p_dl_number), ''),
    updated_at = NOW()
  WHERE id = v_user_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

GRANT EXECUTE ON FUNCTION update_trucker_dl_number(TEXT) TO authenticated;
