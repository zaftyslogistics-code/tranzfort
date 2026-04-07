ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS profile_photo_review_status verification_case_status,
ADD COLUMN IF NOT EXISTS profile_photo_rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS profile_photo_feedback_json JSONB,
ADD COLUMN IF NOT EXISTS profile_photo_submitted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS profile_photo_last_reviewed_at TIMESTAMPTZ;

ALTER TABLE verification_cases
ADD COLUMN IF NOT EXISTS review_type TEXT NOT NULL DEFAULT 'full_verification';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'verification_cases_review_type_check'
  ) THEN
    ALTER TABLE verification_cases
    ADD CONSTRAINT verification_cases_review_type_check
    CHECK (review_type IN ('full_verification', 'profile_photo_update'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_verification_cases_subject_review_type
  ON verification_cases(subject_type, subject_id, review_type);

UPDATE verification_cases
SET review_type = 'full_verification'
WHERE COALESCE(BTRIM(review_type), '') = '';

CREATE OR REPLACE FUNCTION submit_verification_for_review()
RETURNS UUID AS $$
DECLARE
  v_profile RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_subject_type TEXT;
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

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = v_subject_type
    AND subject_id = auth.uid()
    AND review_type = 'full_verification'
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
      review_type,
      case_status
    ) VALUES (
      v_subject_type,
      auth.uid(),
      'full_verification',
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION resubmit_verification_case()
RETURNS UUID AS $$
BEGIN
  RETURN submit_verification_for_review();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION submit_profile_photo_for_review()
RETURNS UUID AS $$
DECLARE
  v_profile RECORD;
  v_case RECORD;
  v_case_id UUID;
  v_subject_type TEXT;
BEGIN
  SELECT * INTO v_profile
  FROM profiles
  WHERE id = auth.uid()
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF COALESCE(BTRIM(v_profile.profile_photo_document_path), '') = '' THEN
    RAISE EXCEPTION 'Upload a profile photo before submitting for review';
  END IF;

  IF v_profile.user_role_type = 'supplier' THEN
    v_subject_type := 'supplier_profile';
  ELSIF v_profile.user_role_type = 'trucker' THEN
    v_subject_type := 'trucker_profile';
  ELSE
    RAISE EXCEPTION 'User role is not configured for profile photo review';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = v_subject_type
    AND subject_id = auth.uid()
    AND review_type = 'profile_photo_update'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'approved') THEN
    RAISE EXCEPTION 'Profile photo review is already active';
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
      'Profile photo review resubmitted'
    );
  ELSE
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      review_type,
      case_status
    ) VALUES (
      v_subject_type,
      auth.uid(),
      'profile_photo_update',
      'submitted'
    ) RETURNING id INTO v_case_id;

    INSERT INTO verification_case_events (
      verification_case_id,
      event_type,
      event_summary
    ) VALUES (
      v_case_id,
      'submitted',
      'Profile photo review submitted'
    );
  END IF;

  UPDATE profiles
  SET profile_photo_review_status = 'submitted',
      profile_photo_rejection_reason = NULL,
      profile_photo_feedback_json = NULL,
      profile_photo_submitted_at = NOW(),
      profile_photo_last_reviewed_at = NULL,
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
    'User submitted profile photo for review',
    jsonb_build_object(
      'subject_type', v_subject_type,
      'review_type', 'profile_photo_update'
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
    'Profile Photo Update',
    v_profile.full_name || ' submitted a profile photo update',
    v_case_id,
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_case_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS approve_verification_case(UUID);

CREATE OR REPLACE FUNCTION approve_verification_case(
  p_case_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Verification case not found';
  END IF;

  IF v_case.subject_type NOT IN ('supplier_profile', 'trucker_profile') THEN
    RAISE EXCEPTION 'approve_verification_case only supports profile verification cases';
  END IF;

  IF v_case.case_status NOT IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission') THEN
    RAISE EXCEPTION 'Verification case is not awaiting review';
  END IF;

  UPDATE verification_cases
  SET case_status = 'approved',
      assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
      last_reviewed_at = NOW(),
      current_decision_summary = 'Approved',
      current_review_feedback_json = NULL,
      updated_at = NOW()
  WHERE id = p_case_id;

  IF COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN
    UPDATE profiles
    SET avatar_url = profile_photo_document_path,
        profile_photo_review_status = 'approved',
        profile_photo_rejection_reason = NULL,
        profile_photo_feedback_json = NULL,
        profile_photo_last_reviewed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  ELSE
    UPDATE profiles
    SET verification_status = 'verified',
        verification_rejection_reason = NULL,
        verification_feedback_json = NULL,
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  END IF;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary
  ) VALUES (
    p_case_id,
    'approved',
    v_admin_user_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo approved'
      ELSE 'Verification approved'
    END
  );

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
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'user_verification_approved',
    'verification_case',
    p_case_id,
    'profile',
    v_case.subject_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo approved'
      ELSE 'Verification approved'
    END,
    jsonb_build_object(
      'subject_type', v_case.subject_type,
      'review_type', COALESCE(v_case.review_type, 'full_verification')
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_case.subject_id,
    'verification_update',
    'high',
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile Photo Approved'
      ELSE 'Account Verified'
    END,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Your new profile photo is now live.'
      ELSE 'You can now use all TranZfort features'
    END,
    p_case_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN '/profile'
      ELSE '/profile'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS reject_verification_case(UUID, TEXT, JSONB);
DROP FUNCTION IF EXISTS reject_verification_case(UUID, TEXT);

CREATE OR REPLACE FUNCTION reject_verification_case(
  p_case_id UUID,
  p_reason TEXT,
  p_feedback_json JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_reason TEXT;
  v_feedback_json JSONB;
  v_feedback_summary TEXT;
  v_feedback_next_step TEXT;
  v_default_next_step TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_reason := btrim(COALESCE(p_reason, ''));
  IF char_length(v_reason) < 5 THEN
    RAISE EXCEPTION 'Rejection reason is too short';
  END IF;

  v_feedback_json := COALESCE(p_feedback_json, '{}'::jsonb);
  IF jsonb_typeof(v_feedback_json) <> 'object' THEN
    RAISE EXCEPTION 'Verification feedback payload must be a JSON object';
  END IF;
  IF v_feedback_json ? 'documents' AND jsonb_typeof(v_feedback_json -> 'documents') <> 'object' THEN
    RAISE EXCEPTION 'Verification feedback documents payload must be a JSON object';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Verification case not found';
  END IF;

  IF v_case.subject_type NOT IN ('supplier_profile', 'trucker_profile') THEN
    RAISE EXCEPTION 'reject_verification_case only supports profile verification cases';
  END IF;

  IF v_case.case_status NOT IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission') THEN
    RAISE EXCEPTION 'Verification case is not awaiting review';
  END IF;

  v_default_next_step := CASE
    WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update'
      THEN 'Replace the profile photo and resubmit it for review.'
    ELSE 'Replace the affected verification items and resubmit for review.'
  END;

  v_feedback_summary := NULLIF(btrim(COALESCE(v_feedback_json ->> 'summary', '')), '');
  v_feedback_next_step := NULLIF(btrim(COALESCE(v_feedback_json ->> 'next_step', '')), '');
  v_feedback_json := v_feedback_json || jsonb_build_object(
    'summary', COALESCE(v_feedback_summary, v_reason),
    'next_step', COALESCE(v_feedback_next_step, v_default_next_step)
  );

  UPDATE verification_cases
  SET case_status = 'rejected',
      assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
      last_reviewed_at = NOW(),
      current_decision_summary = v_reason,
      current_review_feedback_json = v_feedback_json,
      updated_at = NOW()
  WHERE id = p_case_id;

  IF COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN
    UPDATE profiles
    SET profile_photo_review_status = 'rejected',
        profile_photo_rejection_reason = v_reason,
        profile_photo_feedback_json = v_feedback_json,
        profile_photo_last_reviewed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  ELSE
    UPDATE profiles
    SET verification_status = 'rejected',
        verification_rejection_reason = v_reason,
        verification_feedback_json = v_feedback_json,
        updated_at = NOW()
    WHERE id = v_case.subject_id;
  END IF;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    'rejected',
    v_admin_user_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo rejected'
      ELSE 'Verification rejected'
    END,
    v_reason
  );

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
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    'user_verification_rejected',
    'verification_case',
    p_case_id,
    'profile',
    v_case.subject_id,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile photo rejected'
      ELSE 'Verification rejected'
    END,
    jsonb_build_object(
      'subject_type', v_case.subject_type,
      'review_type', COALESCE(v_case.review_type, 'full_verification'),
      'reason', v_reason,
      'feedback', v_feedback_json
    ),
    'internal'
  );

  INSERT INTO notifications (
    target_profile_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_case_id,
    action_route_hint
  ) VALUES (
    v_case.subject_id,
    'verification_update',
    'high',
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Profile Photo Update'
      ELSE 'Verification Update'
    END,
    CASE
      WHEN COALESCE(v_case.review_type, 'full_verification') = 'profile_photo_update' THEN 'Please review your profile photo feedback and resubmit the photo update.'
      ELSE 'Please review your verification feedback and resubmit the affected items.'
    END,
    p_case_id,
    '/profile'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
