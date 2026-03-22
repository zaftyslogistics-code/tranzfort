CREATE OR REPLACE FUNCTION cancel_account_deletion_request()
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID;
  v_profile RECORD;
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

  IF v_profile.account_deletion_status <> 'deactivated_pending_cleanup' THEN
    RETURN jsonb_build_object(
      'status', COALESCE(v_profile.account_deletion_status::TEXT, 'active'),
      'blocked', false,
      'message', 'Account deletion is not pending cleanup'
    );
  END IF;

  UPDATE profiles
  SET account_deletion_status = 'active',
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
    'deletion_request_cancelled',
    'profile',
    v_user_id,
    'User cancelled account deletion request',
    jsonb_build_object(
      'account_deletion_status', 'active'
    ),
    'internal'
  );

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
    'medium',
    'Deletion Request Cancelled',
    'Your account deletion request was cancelled and your account is active again.',
    '/profile'
  );

  RETURN jsonb_build_object(
    'status', 'active',
    'blocked', false,
    'message', 'Account deletion request cancelled and account restored to active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
