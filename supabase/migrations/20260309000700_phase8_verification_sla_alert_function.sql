CREATE OR REPLACE FUNCTION notify_verification_sla_approaching()
RETURNS INTEGER AS $$
DECLARE
  v_case_count INTEGER := 0;
  v_notification_count INTEGER := 0;
BEGIN
  SELECT COUNT(*) INTO v_case_count
  FROM verification_cases
  WHERE case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission')
    AND submitted_at <= NOW() - INTERVAL '20 hours'
    AND submitted_at > NOW() - INTERVAL '24 hours';

  IF v_case_count = 0 THEN
    RETURN 0;
  END IF;

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'system_notice',
    'medium',
    'SLA Alert',
    v_case_count::text || ' verifications approaching 24h SLA',
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM notifications
      WHERE target_admin_user_id = admin_users.id
        AND notification_type = 'system_notice'
        AND title_text = 'SLA Alert'
        AND action_route_hint = '/admin/verification-queue'
        AND created_at::date = CURRENT_DATE
    );

  GET DIAGNOSTICS v_notification_count = ROW_COUNT;
  RETURN v_notification_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
