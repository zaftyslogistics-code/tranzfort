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
      updated_at = NOW()
  WHERE id = p_case_id;

  UPDATE profiles
  SET verification_status = 'verified',
      verification_rejection_reason = NULL,
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

CREATE OR REPLACE FUNCTION reject_verification_case(
  p_case_id UUID,
  p_reason TEXT
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_reason TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_reason := btrim(COALESCE(p_reason, ''));
  IF char_length(v_reason) < 5 THEN
    RAISE EXCEPTION 'Rejection reason is too short';
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

  UPDATE verification_cases
  SET case_status = 'rejected',
      assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
      last_reviewed_at = NOW(),
      current_decision_summary = v_reason,
      updated_at = NOW()
  WHERE id = p_case_id;

  UPDATE profiles
  SET verification_status = 'rejected',
      verification_rejection_reason = v_reason,
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
    v_case.subject_id,
    'verification_update',
    'high',
    'Verification Update',
    'Please re-upload: ' || v_reason,
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

  UPDATE trucks
  SET status = p_next_status,
      rejection_reason = CASE WHEN p_next_status = 'rejected' THEN v_reason ELSE NULL END,
      verified_at = CASE WHEN p_next_status = 'verified' THEN NOW() ELSE NULL END,
      verified_by_admin_user_id = CASE WHEN p_next_status = 'verified' THEN v_admin_user_id ELSE NULL END,
      updated_at = NOW()
  WHERE id = p_truck_id;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = 'truck'
    AND subject_id = p_truck_id
    AND case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission')
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF p_next_status = 'verified' THEN
    v_event_type := 'approved';
    v_notification_title := 'Truck Verified';
    v_notification_body := v_truck.truck_number || ' has been approved';
    v_priority := 'medium';
  ELSE
    v_event_type := 'rejected';
    v_notification_title := 'Truck Rejected';
    v_notification_body := v_truck.truck_number || ': ' || v_reason;
    v_priority := 'high';
  END IF;

  IF v_case IS NOT NULL THEN
    UPDATE verification_cases
    SET case_status = CASE
          WHEN p_next_status = 'verified' THEN 'approved'::verification_case_status
          ELSE 'rejected'::verification_case_status
        END,
        assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
        last_reviewed_at = NOW(),
        current_decision_summary = CASE
          WHEN p_next_status = 'verified' THEN 'Truck approved'
          ELSE v_reason
        END,
        updated_at = NOW()
    WHERE id = v_case.id;

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
      CASE
        WHEN p_next_status = 'verified' THEN 'Truck approved'
        ELSE 'Truck rejected'
      END,
      CASE
        WHEN p_next_status = 'verified' THEN NULL
        ELSE v_reason
      END
    );
  END IF;

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
    CASE
      WHEN p_next_status = 'verified' THEN 'truck_verification_approved'::audit_action_type
      ELSE 'truck_verification_rejected'::audit_action_type
    END,
    'truck',
    p_truck_id,
    'verification_case',
    v_case.id,
    CASE
      WHEN p_next_status = 'verified' THEN 'Truck approved'
      ELSE 'Truck rejected'
    END,
    jsonb_build_object(
      'truck_number', v_truck.truck_number,
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
    '/my-fleet'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
