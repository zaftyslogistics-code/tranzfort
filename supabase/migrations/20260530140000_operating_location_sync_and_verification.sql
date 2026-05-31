-- FP-14: Operating location canonical on profiles; auto-sync to supplier verification mirror.
-- Fixes duplicate location capture after onboarding and submit failures when only profile has coords.

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. Sync helper: profiles → suppliers.verification_location_*
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.sync_profile_operating_location_to_supplier(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile profiles%ROWTYPE;
BEGIN
  SELECT *
  INTO v_profile
  FROM public.profiles
  WHERE id = p_profile_id;

  IF NOT FOUND OR v_profile.user_role_type <> 'supplier' THEN
    RETURN;
  END IF;

  IF COALESCE(BTRIM(v_profile.city), '') = ''
     OR v_profile.location_lat IS NULL
     OR v_profile.location_lng IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.suppliers
  SET
    verification_location_city = v_profile.city,
    verification_location_state = v_profile.state,
    verification_location_lat = v_profile.location_lat,
    verification_location_lng = v_profile.location_lng,
    updated_at = NOW()
  WHERE id = p_profile_id
    AND (
      verification_location_city IS DISTINCT FROM v_profile.city
      OR verification_location_state IS DISTINCT FROM v_profile.state
      OR verification_location_lat IS DISTINCT FROM v_profile.location_lat
      OR verification_location_lng IS DISTINCT FROM v_profile.location_lng
    );
END;
$$;

COMMENT ON FUNCTION public.sync_profile_operating_location_to_supplier(UUID) IS
  'Mirrors profiles operating location to suppliers.verification_location_* for supplier users.';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. Trigger: keep supplier mirror in sync when profile location changes
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.trg_sync_profile_location_to_supplier()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.user_role_type = 'supplier' THEN
    PERFORM public.sync_profile_operating_location_to_supplier(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profile_location_to_supplier ON public.profiles;

CREATE TRIGGER trg_profile_location_to_supplier
AFTER INSERT OR UPDATE OF city, state, location_lat, location_lng, user_role_type
ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_profile_location_to_supplier();

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. Backfill existing suppliers with profile location but empty mirror
--    (disable reciprocal triggers to avoid profile↔supplier sync loop)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.sync_supplier_location_to_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.verification_location_city IS NOT NULL THEN
    UPDATE public.profiles
    SET
      city = NEW.verification_location_city,
      state = NEW.verification_location_state
    WHERE id = NEW.id
      AND (
        city IS DISTINCT FROM NEW.verification_location_city
        OR state IS DISTINCT FROM NEW.verification_location_state
      );
  END IF;
  RETURN NEW;
END;
$$;

ALTER TABLE public.suppliers DISABLE TRIGGER trg_sync_supplier_location;
ALTER TABLE public.profiles DISABLE TRIGGER trg_profile_location_to_supplier;

UPDATE public.suppliers s
SET
  verification_location_city = p.city,
  verification_location_state = p.state,
  verification_location_lat = p.location_lat,
  verification_location_lng = p.location_lng,
  updated_at = NOW()
FROM public.profiles p
WHERE s.id = p.id
  AND p.user_role_type = 'supplier'
  AND COALESCE(BTRIM(p.city), '') <> ''
  AND p.location_lat IS NOT NULL
  AND p.location_lng IS NOT NULL
  AND (
    COALESCE(BTRIM(s.verification_location_city), '') = ''
    OR s.verification_location_lat IS NULL
    OR s.verification_location_lng IS NULL
  );

ALTER TABLE public.suppliers ENABLE TRIGGER trg_sync_supplier_location;
ALTER TABLE public.profiles ENABLE TRIGGER trg_profile_location_to_supplier;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. upsert_current_user_profile — sync supplier mirror after onboarding save
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.upsert_current_user_profile(
  p_user_role_type user_role DEFAULT NULL,
  p_full_name TEXT DEFAULT NULL,
  p_mobile TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_state TEXT DEFAULT NULL,
  p_location_lat DOUBLE PRECISION DEFAULT NULL,
  p_location_lng DOUBLE PRECISION DEFAULT NULL,
  p_location_source TEXT DEFAULT NULL,
  p_record_terms BOOLEAN DEFAULT FALSE
)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_existing_profile profiles%ROWTYPE;
  v_email TEXT;
  v_full_name TEXT;
  v_mobile TEXT;
  v_city TEXT;
  v_state TEXT;
  v_location_source TEXT;
  v_location_lat DOUBLE PRECISION;
  v_location_lng DOUBLE PRECISION;
  v_role user_role;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_existing_profile
  FROM public.profiles
  WHERE id = v_user_id;

  v_email := COALESCE(
    NULLIF(BTRIM(COALESCE(v_existing_profile.email, '')), ''),
    NULLIF(BTRIM(COALESCE(auth.jwt() ->> 'email', '')), '')
  );

  v_full_name := COALESCE(
    NULLIF(BTRIM(COALESCE(p_full_name, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.full_name, '')), ''),
    NULLIF(BTRIM(SPLIT_PART(COALESCE(v_email, ''), '@', 1)), ''),
    'User'
  );

  v_mobile := COALESCE(
    NULLIF(BTRIM(COALESCE(p_mobile, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.mobile, '')), '')
  );

  v_city := COALESCE(
    NULLIF(BTRIM(COALESCE(p_city, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.city, '')), '')
  );

  v_state := COALESCE(
    NULLIF(BTRIM(COALESCE(p_state, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.state, '')), '')
  );

  v_location_source := COALESCE(
    NULLIF(BTRIM(COALESCE(p_location_source, '')), ''),
    NULLIF(BTRIM(COALESCE(v_existing_profile.location_source, '')), '')
  );

  v_location_lat := COALESCE(p_location_lat, v_existing_profile.location_lat);
  v_location_lng := COALESCE(p_location_lng, v_existing_profile.location_lng);

  IF v_mobile IS NOT NULL AND v_mobile <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE mobile = v_mobile AND id <> v_user_id
    ) THEN
      RAISE EXCEPTION 'This mobile number is already registered to another account.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  IF v_email IS NOT NULL AND v_email <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE email = v_email AND id <> v_user_id
    ) THEN
      RAISE EXCEPTION 'This email address is already registered to another account.'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  INSERT INTO public.profiles (
    id,
    full_name,
    mobile,
    email,
    user_role_type,
    city,
    state,
    location_lat,
    location_lng,
    location_source
  )
  VALUES (
    v_user_id,
    v_full_name,
    v_mobile,
    v_email,
    p_user_role_type,
    v_city,
    v_state,
    v_location_lat,
    v_location_lng,
    v_location_source
  )
  ON CONFLICT (id) DO UPDATE
  SET full_name = EXCLUDED.full_name,
      mobile = COALESCE(EXCLUDED.mobile, public.profiles.mobile),
      email = COALESCE(EXCLUDED.email, public.profiles.email),
      user_role_type = COALESCE(EXCLUDED.user_role_type, public.profiles.user_role_type),
      city = COALESCE(EXCLUDED.city, public.profiles.city),
      state = COALESCE(EXCLUDED.state, public.profiles.state),
      location_lat = COALESCE(EXCLUDED.location_lat, public.profiles.location_lat),
      location_lng = COALESCE(EXCLUDED.location_lng, public.profiles.location_lng),
      location_source = COALESCE(EXCLUDED.location_source, public.profiles.location_source),
      updated_at = NOW();

  v_role := COALESCE(p_user_role_type, v_existing_profile.user_role_type);

  IF v_role = 'supplier' THEN
    INSERT INTO public.suppliers (id)
    VALUES (v_user_id)
    ON CONFLICT (id) DO NOTHING;
  ELSIF v_role = 'trucker' THEN
    INSERT INTO public.truckers (id)
    VALUES (v_user_id)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  IF v_role = 'supplier' THEN
    PERFORM public.sync_profile_operating_location_to_supplier(v_user_id);
  END IF;

  IF p_record_terms THEN
    INSERT INTO public.user_consents (profile_id, consent_type, consent_version, source_context)
    VALUES (v_user_id, 'terms_of_service', 'v1', 'onboarding_profile')
    ON CONFLICT (profile_id, consent_type) DO NOTHING;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. get_verification_profile — expose profile operating location to app
-- ═══════════════════════════════════════════════════════════════════════════════

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
      profile_photo_document_path,
      city,
      state,
      location_lat,
      location_lng,
      location_source
    FROM profiles
    WHERE id = v_user_id
  ) p;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION get_verification_profile IS
  'Verification wizard profile row for the authenticated user (includes operating location from onboarding).';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. submit_verification_for_review — sync mirror + effective location check
--    (full function preserved from 20260529140000; supplier block only extended)
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
  v_effective_city TEXT;
  v_effective_lat DOUBLE PRECISION;
  v_effective_lng DOUBLE PRECISION;
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
    PERFORM public.sync_profile_operating_location_to_supplier(auth.uid());

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

    v_effective_city := COALESCE(
      NULLIF(BTRIM(v_supplier.verification_location_city), ''),
      NULLIF(BTRIM(v_profile.city), '')
    );
    v_effective_lat := COALESCE(v_supplier.verification_location_lat, v_profile.location_lat);
    v_effective_lng := COALESCE(v_supplier.verification_location_lng, v_profile.location_lng);

    IF COALESCE(BTRIM(v_effective_city), '') = ''
      OR v_effective_lat IS NULL
      OR v_effective_lng IS NULL THEN
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

GRANT EXECUTE ON FUNCTION submit_verification_for_review() TO authenticated;
