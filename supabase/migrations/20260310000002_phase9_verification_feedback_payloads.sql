ALTER TABLE verification_cases
ADD COLUMN IF NOT EXISTS current_review_feedback_json JSONB;

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS verification_feedback_json JSONB;

ALTER TABLE trucks
ADD COLUMN IF NOT EXISTS verification_feedback_json JSONB;

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

  UPDATE profiles
  SET verification_status = 'verified',
      verification_rejection_reason = NULL,
      verification_feedback_json = NULL,
      updated_at = NOW()
  WHERE id = v_case.subject_id;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary
  ) VALUES (
    p_case_id,
    'approved',
    v_admin_user_id,
    'Verification approved'
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
    'Verification approved',
    jsonb_build_object(
      'subject_type', v_case.subject_type
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
    'Account Verified',
    'You can now use all TranZfort features',
    p_case_id,
    '/profile'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

  v_feedback_summary := NULLIF(btrim(COALESCE(v_feedback_json ->> 'summary', '')), '');
  v_feedback_next_step := NULLIF(btrim(COALESCE(v_feedback_json ->> 'next_step', '')), '');
  v_feedback_json := v_feedback_json || jsonb_build_object(
    'summary', COALESCE(v_feedback_summary, v_reason),
    'next_step', COALESCE(v_feedback_next_step, 'Replace the affected verification items and resubmit for review.')
  );

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

  UPDATE verification_cases
  SET case_status = 'rejected',
      assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
      last_reviewed_at = NOW(),
      current_decision_summary = v_reason,
      current_review_feedback_json = v_feedback_json,
      updated_at = NOW()
  WHERE id = p_case_id;

  UPDATE profiles
  SET verification_status = 'rejected',
      verification_rejection_reason = v_reason,
      verification_feedback_json = v_feedback_json,
      updated_at = NOW()
  WHERE id = v_case.subject_id;

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
    'Verification rejected',
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
    'Verification rejected',
    jsonb_build_object(
      'subject_type', v_case.subject_type,
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
    'Verification Update',
    'Please review your verification feedback and resubmit the affected items.',
    p_case_id,
    '/verification'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION update_truck_verification_state(
  p_truck_id UUID,
  p_next_status truck_status,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_truck RECORD;
  v_case RECORD;
  v_reason TEXT;
  v_event_type verification_event_type;
  v_notification_title TEXT;
  v_notification_body TEXT;
  v_priority notification_priority;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF p_next_status NOT IN ('verified', 'rejected') THEN
    RAISE EXCEPTION 'Truck verification updates only support verified or rejected';
  END IF;

  v_reason := NULLIF(btrim(COALESCE(p_reason, '')), '');
  IF p_next_status = 'rejected' AND v_reason IS NULL THEN
    RAISE EXCEPTION 'Rejection reason is required';
  END IF;

  SELECT * INTO v_truck
  FROM trucks
  WHERE id = p_truck_id
  FOR UPDATE;

  IF v_truck IS NULL THEN
    RAISE EXCEPTION 'Truck not found';
  END IF;

  IF v_truck.status NOT IN ('pending', 'edited_pending_reapproval', 'rejected') THEN
    RAISE EXCEPTION 'Truck is not awaiting verification review';
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = 'truck'
    AND subject_id = p_truck_id
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NULL THEN
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      case_status,
      assigned_admin_user_id,
      submitted_at,
      last_reviewed_at,
      current_decision_summary,
      current_review_feedback_json
    ) VALUES (
      'truck',
      p_truck_id,
      CASE WHEN p_next_status = 'verified' THEN 'approved' ELSE 'rejected' END,
      v_admin_user_id,
      NOW(),
      NOW(),
      CASE WHEN p_next_status = 'verified' THEN 'Truck approved' ELSE v_reason END,
      CASE WHEN p_next_status = 'rejected'
        THEN jsonb_build_object(
          'summary', v_reason,
          'next_step', 'Update the rejected truck details or documents and resubmit for review.'
        )
        ELSE NULL
      END
    ) RETURNING * INTO v_case;
  ELSE
    UPDATE verification_cases
    SET case_status = CASE WHEN p_next_status = 'verified' THEN 'approved' ELSE 'rejected' END,
        assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
        last_reviewed_at = NOW(),
        current_decision_summary = CASE WHEN p_next_status = 'verified' THEN 'Truck approved' ELSE v_reason END,
        current_review_feedback_json = CASE WHEN p_next_status = 'rejected'
          THEN jsonb_build_object(
            'summary', v_reason,
            'next_step', 'Update the rejected truck details or documents and resubmit for review.'
          )
          ELSE NULL
        END,
        updated_at = NOW()
    WHERE id = v_case.id
    RETURNING * INTO v_case;
  END IF;

  UPDATE trucks
  SET status = p_next_status,
      rejection_reason = CASE WHEN p_next_status = 'rejected' THEN v_reason ELSE NULL END,
      verification_feedback_json = CASE WHEN p_next_status = 'rejected'
        THEN jsonb_build_object(
          'summary', v_reason,
          'next_step', 'Update the rejected truck details or documents and resubmit for review.'
        )
        ELSE NULL
      END,
      verified_at = CASE WHEN p_next_status = 'verified' THEN NOW() ELSE NULL END,
      verified_by_admin_user_id = CASE WHEN p_next_status = 'verified' THEN v_admin_user_id ELSE NULL END,
      updated_at = NOW()
  WHERE id = p_truck_id;

  v_event_type := CASE WHEN p_next_status = 'verified' THEN 'approved' ELSE 'rejected' END;
  v_notification_title := CASE WHEN p_next_status = 'verified' THEN 'Truck Approved' ELSE 'Truck Verification Update' END;
  v_notification_body := CASE
    WHEN p_next_status = 'verified' THEN 'Your truck is verified and ready for booking workflows.'
    ELSE 'Please review the truck verification feedback and resubmit the affected details.'
  END;
  v_priority := CASE WHEN p_next_status = 'verified' THEN 'medium' ELSE 'high' END;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    actor_admin_user_id,
    event_summary,
    internal_note
  ) VALUES (
    v_case.id,
    v_event_type,
    v_admin_user_id,
    CASE WHEN p_next_status = 'verified' THEN 'Truck verification approved' ELSE 'Truck verification rejected' END,
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
    CASE WHEN p_next_status = 'verified' THEN 'truck_verification_approved' ELSE 'truck_verification_rejected' END,
    'verification_case',
    v_case.id,
    'truck',
    p_truck_id,
    CASE WHEN p_next_status = 'verified' THEN 'Truck verification approved' ELSE 'Truck verification rejected' END,
    jsonb_build_object(
      'next_status', p_next_status,
      'reason', v_reason
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
    v_truck.owner_id,
    'verification_update',
    v_priority,
    v_notification_title,
    v_notification_body,
    v_case.id,
    '/trucker-verification'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS submit_verification_for_review();

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
      'subject_type', v_subject_type
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
