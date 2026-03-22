CREATE OR REPLACE FUNCTION request_account_deletion()
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID;
  v_profile RECORD;
  v_blocker TEXT;
  v_has_active_trips BOOLEAN;
  v_has_unresolved_disputes BOOLEAN;
  v_has_compliance_records BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_profile
  FROM profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_profile.account_deletion_status = 'permanently_deleted' THEN
    RAISE EXCEPTION 'Account is already permanently deleted';
  END IF;

  IF v_profile.account_deletion_status = 'deactivated_pending_cleanup' THEN
    RETURN jsonb_build_object(
      'status', 'deactivated_pending_cleanup',
      'blocked', false,
      'message', 'Account is already pending cleanup'
    );
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM trips
    WHERE (supplier_id = v_user_id OR trucker_id = v_user_id)
      AND stage NOT IN ('completed', 'cancelled')
  ) INTO v_has_active_trips;

  SELECT EXISTS (
    SELECT 1
    FROM support_tickets
    WHERE owner_profile_id = v_user_id
      AND status NOT IN ('resolved', 'closed')
  ) INTO v_has_unresolved_disputes;

  SELECT EXISTS (
    SELECT 1
    FROM verification_cases
    WHERE subject_id = v_user_id
      AND case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated')
  ) INTO v_has_compliance_records;

  IF v_has_active_trips THEN
    v_blocker := 'active trips';
  ELSIF v_has_unresolved_disputes THEN
    v_blocker := 'unresolved disputes';
  ELSIF v_has_compliance_records THEN
    v_blocker := 'compliance records';
  ELSE
    v_blocker := NULL;
  END IF;

  IF v_blocker IS NOT NULL THEN
    UPDATE profiles
    SET account_deletion_status = 'blocked_by_dependency',
        updated_at = NOW()
    WHERE id = v_user_id;

    INSERT INTO notifications (
      target_profile_id,
      notification_type,
      notification_priority,
      title_text,
      body_text,
      action_route_hint
    ) VALUES (
      v_user_id,
      'account_update',
      'high',
      'Deletion Blocked',
      'Active ' || v_blocker || ' prevents account deletion',
      '/profile'
    );

    RETURN jsonb_build_object(
      'status', 'blocked_by_dependency',
      'blocked', true,
      'blocker', v_blocker,
      'message', 'Account deletion is blocked by ' || v_blocker
    );
  END IF;

  UPDATE profiles
  SET account_deletion_status = 'deactivated_pending_cleanup',
      data_deletion_requested_at = COALESCE(data_deletion_requested_at, NOW()),
      updated_at = NOW()
  WHERE id = v_user_id;

  INSERT INTO audit_logs (
    actor_admin_user_id,
    actor_type,
    actor_role,
    action_type,
    target_object_type,
    target_object_id,
    summary_text,
    payload_json,
    visibility_class
  ) VALUES (
    NULL,
    'user',
    NULL,
    'deletion_request_processed',
    'profile',
    v_user_id,
    'User requested account deletion',
    jsonb_build_object(
      'account_deletion_status', 'deactivated_pending_cleanup'
    ),
    'internal'
  );

  RETURN jsonb_build_object(
    'status', 'deactivated_pending_cleanup',
    'blocked', false,
    'message', 'Account deletion requested and account deactivated pending cleanup'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
