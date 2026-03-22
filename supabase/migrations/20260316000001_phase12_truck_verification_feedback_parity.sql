CREATE OR REPLACE FUNCTION update_truck_verification_state(
  p_truck_id UUID,
  p_next_status truck_status,
  p_reason TEXT DEFAULT NULL,
  p_feedback_json JSONB DEFAULT NULL
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
  v_feedback JSONB;
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

  IF p_next_status = 'rejected' THEN
    v_feedback := COALESCE(
      p_feedback_json,
      jsonb_build_object(
        'summary', v_reason,
        'next_step', 'Update the rejected truck details or documents and resubmit for review.'
      )
    );
    v_feedback := jsonb_set(
      v_feedback,
      '{summary}',
      to_jsonb(COALESCE(NULLIF(btrim(COALESCE(v_feedback->>'summary', '')), ''), v_reason))
    );
    IF COALESCE(NULLIF(btrim(COALESCE(v_feedback->>'next_step', '')), ''), '') = '' THEN
      v_feedback := jsonb_set(
        v_feedback,
        '{next_step}',
        to_jsonb('Update the rejected truck details or documents and resubmit for review.'::TEXT)
      );
    END IF;
  ELSE
    v_feedback := NULL;
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
      v_feedback
    ) RETURNING * INTO v_case;
  ELSE
    UPDATE verification_cases
    SET case_status = CASE WHEN p_next_status = 'verified' THEN 'approved' ELSE 'rejected' END,
        assigned_admin_user_id = COALESCE(assigned_admin_user_id, v_admin_user_id),
        last_reviewed_at = NOW(),
        current_decision_summary = CASE WHEN p_next_status = 'verified' THEN 'Truck approved' ELSE v_reason END,
        current_review_feedback_json = v_feedback,
        updated_at = NOW()
    WHERE id = v_case.id
    RETURNING * INTO v_case;
  END IF;

  UPDATE trucks
  SET status = p_next_status,
      rejection_reason = CASE WHEN p_next_status = 'rejected' THEN v_reason ELSE NULL END,
      verification_feedback_json = v_feedback,
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
      'reason', v_reason,
      'feedback', v_feedback
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
