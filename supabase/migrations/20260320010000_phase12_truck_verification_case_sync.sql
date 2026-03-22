CREATE OR REPLACE FUNCTION sync_truck_verification_case_from_truck()
RETURNS TRIGGER AS $$
DECLARE
  v_case verification_cases%ROWTYPE;
  v_event_type verification_event_type;
  v_event_summary TEXT;
  v_notification_title TEXT;
  v_notification_body TEXT;
  v_owner_name TEXT;
BEGIN
  IF NEW.status NOT IN ('pending', 'edited_pending_reapproval') OR
     COALESCE(BTRIM(NEW.truck_number), '') = '' OR
     COALESCE(BTRIM(NEW.body_type), '') = '' OR
     COALESCE(NEW.tyres, 0) <= 0 OR
     COALESCE(NEW.capacity_tonnes, 0) <= 0 OR
     COALESCE(BTRIM(NEW.rc_document_path), '') = '' THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_case
  FROM verification_cases
  WHERE subject_type = 'truck'
    AND subject_id = NEW.id
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_case IS NOT NULL AND v_case.case_status IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated') THEN
    RETURN NEW;
  END IF;

  IF v_case IS NULL THEN
    INSERT INTO verification_cases (
      subject_type,
      subject_id,
      case_status
    ) VALUES (
      'truck',
      NEW.id,
      'submitted'
    ) RETURNING * INTO v_case;

    v_event_type := 'submitted';
    v_event_summary := 'Truck verification submitted';
    v_notification_title := 'New Truck Verification';
  ELSE
    UPDATE verification_cases
    SET case_status = 'submitted',
        assigned_admin_user_id = NULL,
        last_reviewed_at = NULL,
        current_decision_summary = NULL,
        current_review_feedback_json = NULL,
        escalated_to_admin_user_id = NULL,
        submitted_at = NOW(),
        updated_at = NOW()
    WHERE id = v_case.id
    RETURNING * INTO v_case;

    v_event_type := 'resubmitted';
    v_event_summary := 'Truck verification resubmitted';
    v_notification_title := 'Truck Verification Resubmitted';
  END IF;

  INSERT INTO verification_case_events (
    verification_case_id,
    event_type,
    event_summary
  ) VALUES (
    v_case.id,
    v_event_type,
    v_event_summary
  );

  SELECT full_name INTO v_owner_name
  FROM profiles
  WHERE id = NEW.owner_id;

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
    'truck',
    NEW.id,
    'verification_case',
    v_case.id,
    CASE
      WHEN v_event_type = 'submitted' THEN 'User submitted truck for verification'
      ELSE 'User resubmitted truck for verification'
    END,
    jsonb_build_object(
      'truck_number', NEW.truck_number,
      'status', NEW.status
    ),
    'internal'
  );

  v_notification_body := COALESCE(NULLIF(BTRIM(v_owner_name), ''), 'A trucker') ||
    CASE
      WHEN v_event_type = 'submitted' THEN ' submitted truck '
      ELSE ' resubmitted truck '
    END || COALESCE(NULLIF(BTRIM(NEW.truck_number), ''), 'for verification');

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
    v_notification_title,
    v_notification_body,
    v_case.id,
    '/admin/verification-queue'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_truck_verification_case ON trucks;

CREATE TRIGGER trg_sync_truck_verification_case
AFTER INSERT OR UPDATE OF status, truck_number, body_type, tyres, capacity_tonnes, rc_document_path ON trucks
FOR EACH ROW
EXECUTE FUNCTION sync_truck_verification_case_from_truck();

WITH ready_trucks AS (
  SELECT id
  FROM trucks
  WHERE status IN ('pending', 'edited_pending_reapproval')
    AND COALESCE(BTRIM(truck_number), '') <> ''
    AND COALESCE(BTRIM(body_type), '') <> ''
    AND COALESCE(tyres, 0) > 0
    AND COALESCE(capacity_tonnes, 0) > 0
    AND COALESCE(BTRIM(rc_document_path), '') <> ''
),
latest_cases AS (
  SELECT DISTINCT ON (subject_id)
    id,
    subject_id,
    case_status
  FROM verification_cases
  WHERE subject_type = 'truck'
  ORDER BY subject_id, created_at DESC
),
resubmitted_cases AS (
  UPDATE verification_cases vc
  SET case_status = 'submitted',
      assigned_admin_user_id = NULL,
      last_reviewed_at = NULL,
      current_decision_summary = NULL,
      current_review_feedback_json = NULL,
      escalated_to_admin_user_id = NULL,
      submitted_at = NOW(),
      updated_at = NOW()
  FROM latest_cases lc
  JOIN ready_trucks rt ON rt.id = lc.subject_id
  WHERE vc.id = lc.id
    AND lc.case_status NOT IN ('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'escalated')
  RETURNING vc.id
),
inserted_cases AS (
  INSERT INTO verification_cases (
    subject_type,
    subject_id,
    case_status
  )
  SELECT
    'truck',
    rt.id,
    'submitted'
  FROM ready_trucks rt
  LEFT JOIN latest_cases lc ON lc.subject_id = rt.id
  WHERE lc.id IS NULL
  RETURNING id
)
INSERT INTO verification_case_events (
  verification_case_id,
  event_type,
  event_summary
)
SELECT
  id,
  'resubmitted'::verification_event_type,
  'Truck verification resubmitted'
FROM resubmitted_cases
UNION ALL
SELECT
  id,
  'submitted'::verification_event_type,
  'Truck verification submitted'
FROM inserted_cases;
