CREATE OR REPLACE FUNCTION current_admin_user_id()
RETURNS UUID AS $$
DECLARE
  v_admin_user_id UUID;
BEGIN
  SELECT id INTO v_admin_user_id
  FROM admin_users
  WHERE auth_user_id = auth.uid()
    AND is_active = TRUE;

  RETURN v_admin_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION claim_operational_case(
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
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'queued' THEN
    RAISE EXCEPTION 'Only queued cases can be claimed';
  END IF;

  IF v_case.claimed_by_admin_user_id IS NOT NULL THEN
    RAISE EXCEPTION 'Operational case is already claimed';
  END IF;

  UPDATE operational_cases
  SET status = 'claimed',
      claimed_by_admin_user_id = v_admin_user_id,
      claimed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_claimed',
    'Operational case claimed'
  );

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
    'override_action',
    'operational_case',
    p_case_id,
    'Operational case claimed',
    '{}'::jsonb,
    'internal'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION release_operational_case(
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
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'claimed' THEN
    RAISE EXCEPTION 'Only claimed cases can be released';
  END IF;

  IF v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id
     AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only the claimed admin or a super admin can release this case';
  END IF;

  UPDATE operational_cases
  SET status = 'queued',
      claimed_by_admin_user_id = NULL,
      claimed_at = NULL,
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_released',
    'Operational case released back to queue'
  );

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
    'override_action',
    'operational_case',
    p_case_id,
    'Operational case released',
    '{}'::jsonb,
    'internal'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION transition_operational_case(
  p_case_id UUID,
  p_next_status operational_case_status,
  p_event_summary TEXT DEFAULT NULL,
  p_internal_note TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_ticket RECORD;
  v_summary TEXT;
  v_note TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_summary := NULLIF(btrim(COALESCE(p_event_summary, '')), '');
  v_note := NULLIF(btrim(COALESCE(p_internal_note, '')), '');

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF NOT (
    (v_case.status = 'claimed' AND p_next_status = 'in_review') OR
    (v_case.status = 'in_review' AND p_next_status IN ('waiting_for_user', 'waiting_for_external')) OR
    (v_case.status = 'waiting_for_user' AND p_next_status = 'in_review') OR
    (v_case.status = 'waiting_for_external' AND p_next_status = 'in_review') OR
    (v_case.status = 'escalated' AND p_next_status = 'in_review') OR
    (v_case.status = 'resolved' AND p_next_status = 'closed') OR
    (v_case.status = 'rejected' AND p_next_status = 'closed')
  ) THEN
    RAISE EXCEPTION 'Unsupported operational case transition';
  END IF;

  IF v_case.status IN ('claimed', 'in_review')
     AND v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id
     AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only the claimed admin or a super admin can transition this case';
  END IF;

  IF v_case.status = 'escalated' AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only a super admin can take over an escalated case';
  END IF;

  UPDATE operational_cases
  SET status = p_next_status,
      claimed_by_admin_user_id = CASE
        WHEN v_case.status = 'escalated' AND p_next_status = 'in_review' THEN v_admin_user_id
        ELSE claimed_by_admin_user_id
      END,
      claimed_at = CASE
        WHEN v_case.status = 'escalated' AND p_next_status = 'in_review' THEN NOW()
        ELSE claimed_at
      END,
      waiting_reason = CASE
        WHEN p_next_status = 'waiting_for_user' THEN COALESCE(v_note, v_summary)
        WHEN p_next_status = 'waiting_for_external' THEN COALESCE(v_note, v_summary)
        ELSE NULL
      END,
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_transition',
    COALESCE(v_summary, 'Operational case moved to ' || p_next_status::text),
    v_note
  );

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
    'override_action',
    'operational_case',
    p_case_id,
    COALESCE(v_summary, 'Operational case moved to ' || p_next_status::text),
    jsonb_build_object(
      'from_status', v_case.status,
      'to_status', p_next_status,
      'internal_note', v_note
    ),
    'internal'
  );

  IF p_next_status = 'waiting_for_user'
     AND v_case.case_type = 'trip_dispute'
     AND v_case.primary_object_type = 'trip' THEN
    SELECT * INTO v_ticket
    FROM support_tickets
    WHERE related_trip_id = v_case.primary_object_id
      AND category = 'trip_dispute'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_ticket IS NOT NULL THEN
      UPDATE support_tickets
      SET status = 'waiting_for_user',
          updated_at = NOW()
      WHERE id = v_ticket.id;

      INSERT INTO notifications (
        target_profile_id,
        notification_type,
        notification_priority,
        title_text,
        body_text,
        related_load_id,
        related_trip_id,
        related_case_id,
        action_route_hint
      ) VALUES (
        v_ticket.owner_profile_id,
        'dispute_update',
        'high',
        'Evidence Needed',
        'Please provide additional proof for your dispute',
        v_ticket.related_load_id,
        v_ticket.related_trip_id,
        v_ticket.id,
        '/support-ticket/' || v_ticket.id::text
      );
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION reply_to_support_ticket(
  p_support_ticket_id UUID,
  p_message_body TEXT,
  p_visibility_class TEXT DEFAULT 'visible',
  p_attachment_path TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_admin_user_id UUID;
  v_ticket RECORD;
  v_message_id UUID;
  v_message_body TEXT;
  v_visibility_class TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_message_body := btrim(COALESCE(p_message_body, ''));
  IF char_length(v_message_body) < 2 THEN
    RAISE EXCEPTION 'Reply is too short';
  END IF;

  v_visibility_class := lower(btrim(COALESCE(p_visibility_class, 'visible')));
  IF v_visibility_class NOT IN ('visible', 'internal') THEN
    RAISE EXCEPTION 'Unsupported visibility class';
  END IF;

  SELECT * INTO v_ticket
  FROM support_tickets
  WHERE id = p_support_ticket_id
  FOR UPDATE;

  IF v_ticket IS NULL THEN
    RAISE EXCEPTION 'Support ticket not found';
  END IF;

  INSERT INTO support_ticket_messages (
    support_ticket_id,
    sender_admin_user_id,
    message_body,
    attachment_path,
    visibility_class
  ) VALUES (
    p_support_ticket_id,
    v_admin_user_id,
    v_message_body,
    p_attachment_path,
    v_visibility_class
  ) RETURNING id INTO v_message_id;

  UPDATE support_tickets
  SET status = CASE
        WHEN status IN ('open', 'waiting_for_user') THEN 'in_progress'::support_ticket_status
        ELSE status
      END,
      updated_at = NOW()
  WHERE id = p_support_ticket_id;

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
    'override_action',
    'support_ticket',
    p_support_ticket_id,
    'support_ticket_message',
    v_message_id,
    'Admin replied to support ticket',
    jsonb_build_object(
      'visibility_class', v_visibility_class,
      'has_attachment', p_attachment_path IS NOT NULL
    ),
    'internal'
  );

  IF v_visibility_class = 'visible' THEN
    INSERT INTO notifications (
      target_profile_id,
      notification_type,
      notification_priority,
      title_text,
      body_text,
      related_load_id,
      related_trip_id,
      related_case_id,
      action_route_hint
    ) VALUES (
      v_ticket.owner_profile_id,
      'support_update',
      'medium',
      'Support Reply',
      'Your ticket has a new response',
      v_ticket.related_load_id,
      v_ticket.related_trip_id,
      p_support_ticket_id,
      '/support-ticket/' || p_support_ticket_id::text
    );
  END IF;

  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION escalate_operational_case(
  p_case_id UUID,
  p_target_admin_user_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_target_admin RECORD;
  v_admin_name TEXT;
  v_reason TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF get_admin_role() != 'ops_admin' THEN
    RAISE EXCEPTION 'Only ops admins can escalate cases';
  END IF;

  v_reason := NULLIF(btrim(COALESCE(p_reason, '')), '');

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'in_review' THEN
    RAISE EXCEPTION 'Operational case must be in review to escalate';
  END IF;

  IF v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id THEN
    RAISE EXCEPTION 'Only the claimed admin can escalate this case';
  END IF;

  SELECT id, full_name, role, is_active INTO v_target_admin
  FROM admin_users
  WHERE id = p_target_admin_user_id
  FOR UPDATE;

  IF v_target_admin IS NULL OR v_target_admin.is_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'Target admin is not active';
  END IF;

  IF v_target_admin.role != 'super_admin' THEN
    RAISE EXCEPTION 'Cases can only be escalated to a super admin';
  END IF;

  SELECT full_name INTO v_admin_name
  FROM admin_users
  WHERE id = v_admin_user_id;

  UPDATE operational_cases
  SET status = 'escalated',
      escalated_to_admin_user_id = p_target_admin_user_id,
      updated_at = NOW()
  WHERE id = p_case_id;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    'case_escalated',
    'Case escalated to super admin',
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
    'case_escalated',
    'operational_case',
    p_case_id,
    'admin_user',
    p_target_admin_user_id,
    'Operational case escalated to super admin',
    jsonb_build_object(
      'reason', v_reason
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
  ) VALUES (
    p_target_admin_user_id,
    'support_update',
    'high',
    'Case Escalated',
    'Case #' || p_case_id::text || ' escalated by ' || COALESCE(NULLIF(v_admin_name, ''), 'Ops Admin'),
    p_case_id,
    '/admin/case/' || p_case_id::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION resolve_operational_case(
  p_case_id UUID,
  p_resolution_summary TEXT,
  p_resolution_status operational_case_status DEFAULT 'resolved'
)
RETURNS VOID AS $$
DECLARE
  v_admin_user_id UUID;
  v_case RECORD;
  v_trip RECORD;
  v_resolution_summary TEXT;
  v_event_type TEXT;
  v_event_summary TEXT;
  v_notification_title TEXT;
  v_notification_body TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  IF v_admin_user_id IS NULL THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  v_resolution_summary := btrim(COALESCE(p_resolution_summary, ''));
  IF char_length(v_resolution_summary) < 5 THEN
    RAISE EXCEPTION 'Resolution summary is too short';
  END IF;

  IF p_resolution_status NOT IN ('resolved', 'rejected') THEN
    RAISE EXCEPTION 'Resolution status must be resolved or rejected';
  END IF;

  SELECT * INTO v_case
  FROM operational_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF v_case IS NULL THEN
    RAISE EXCEPTION 'Operational case not found';
  END IF;

  IF v_case.status != 'in_review' THEN
    RAISE EXCEPTION 'Operational case must be in review to resolve';
  END IF;

  IF v_case.claimed_by_admin_user_id IS DISTINCT FROM v_admin_user_id
     AND get_admin_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only the claimed admin or a super admin can resolve this case';
  END IF;

  UPDATE operational_cases
  SET status = p_resolution_status,
      resolution_summary = v_resolution_summary,
      resolved_at = NOW(),
      waiting_reason = NULL,
      updated_at = NOW()
  WHERE id = p_case_id;

  v_event_type := CASE
    WHEN p_resolution_status = 'resolved' THEN 'case_resolved'
    ELSE 'case_rejected'
  END;

  v_event_summary := CASE
    WHEN p_resolution_status = 'resolved' THEN 'Operational case resolved'
    ELSE 'Operational case rejected'
  END;

  INSERT INTO operational_case_events (
    operational_case_id,
    actor_admin_user_id,
    event_type,
    event_summary,
    internal_note
  ) VALUES (
    p_case_id,
    v_admin_user_id,
    v_event_type,
    v_event_summary,
    v_resolution_summary
  );

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
    CASE
      WHEN p_resolution_status = 'resolved' THEN 'case_resolved'::audit_action_type
      ELSE 'override_action'::audit_action_type
    END,
    'operational_case',
    p_case_id,
    v_event_summary,
    jsonb_build_object(
      'resolution_status', p_resolution_status,
      'resolution_summary', v_resolution_summary
    ),
    'internal'
  );

  IF v_case.case_type = 'trip_dispute' AND v_case.primary_object_type = 'trip' THEN
    SELECT * INTO v_trip
    FROM trips
    WHERE id = v_case.primary_object_id;

    IF v_trip IS NOT NULL THEN
      UPDATE support_tickets
      SET status = 'resolved',
          resolution_summary = v_resolution_summary,
          resolved_at = NOW(),
          updated_at = NOW()
      WHERE related_trip_id = v_case.primary_object_id
        AND category = 'trip_dispute'
        AND resolved_at IS NULL;

      v_notification_title := CASE
        WHEN p_resolution_status = 'resolved' THEN 'Dispute Resolved'
        ELSE 'Report reviewed and closed'
      END;

      v_notification_body := CASE
        WHEN p_resolution_status = 'resolved' THEN 'Your dispute has been resolved'
        ELSE 'Your dispute report has been reviewed and closed'
      END;

      INSERT INTO notifications (
        target_profile_id,
        notification_type,
        notification_priority,
        title_text,
        body_text,
        related_load_id,
        related_trip_id,
        related_case_id,
        action_route_hint
      ) VALUES
      (
        v_trip.supplier_id,
        'dispute_update',
        'medium',
        v_notification_title,
        v_notification_body,
        v_trip.load_id,
        v_trip.id,
        p_case_id,
        '/trip-detail/' || v_trip.id::text
      ),
      (
        v_trip.trucker_id,
        'dispute_update',
        'medium',
        v_notification_title,
        v_notification_body,
        v_trip.load_id,
        v_trip.id,
        p_case_id,
        '/trip-detail/' || v_trip.id::text
      );
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
