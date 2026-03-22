CREATE OR REPLACE FUNCTION update_trust_safety_status(
  p_profile_id UUID,
  p_next_status trust_safety_status,
  p_reason_summary TEXT,
  p_internal_note TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_profile RECORD;
  v_reason_summary TEXT;
  v_internal_note TEXT;
  v_action_label TEXT;
  v_audit_action audit_action_type;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_reason_summary := btrim(COALESCE(p_reason_summary, ''));
  IF char_length(v_reason_summary) < 3 THEN
    RAISE EXCEPTION 'Reason summary is too short';
  END IF;

  v_internal_note := NULLIF(btrim(COALESCE(p_internal_note, '')), '');

  SELECT * INTO v_profile
  FROM profiles
  WHERE id = p_profile_id
  FOR UPDATE;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF p_next_status = 'normal' THEN
    v_action_label := 'restored';
    v_audit_action := 'user_unbanned';
  ELSIF p_next_status = 'restricted' THEN
    v_action_label := 'restricted';
    v_audit_action := 'user_restricted';
  ELSIF p_next_status = 'suspended' THEN
    v_action_label := 'suspended';
    v_audit_action := 'user_suspended';
  ELSIF p_next_status = 'banned' THEN
    v_action_label := 'banned';
    v_audit_action := 'user_banned';
  ELSE
    v_action_label := 'warned';
    v_audit_action := 'override_action';
  END IF;

  UPDATE profiles
  SET trust_safety_status = p_next_status,
      is_banned = CASE WHEN p_next_status IN ('suspended', 'banned') THEN TRUE ELSE FALSE END,
      ban_reason = CASE
        WHEN p_next_status IN ('restricted', 'suspended', 'banned') THEN v_reason_summary
        ELSE NULL
      END,
      updated_at = NOW()
  WHERE id = p_profile_id;

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
    v_admin_user_id,
    'admin',
    get_admin_role()::text,
    v_audit_action,
    'profile',
    p_profile_id,
    'Trust-safety status updated to ' || p_next_status::text,
    jsonb_build_object(
      'previous_status', v_profile.trust_safety_status,
      'next_status', p_next_status,
      'reason_summary', v_reason_summary,
      'internal_note', v_internal_note
    ),
    'internal'
  );

  IF p_next_status IN ('restricted', 'suspended', 'banned') THEN
    INSERT INTO notifications (
      target_profile_id,
      notification_type,
      notification_priority,
      title_text,
      body_text,
      action_route_hint
    ) VALUES (
      p_profile_id,
      'account_update',
      'high',
      'Account Restriction',
      'Your account has been ' || v_action_label || ': ' || v_reason_summary,
      '/profile'
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
