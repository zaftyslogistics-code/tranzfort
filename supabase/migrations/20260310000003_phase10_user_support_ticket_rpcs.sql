CREATE OR REPLACE FUNCTION create_support_ticket(
  p_category TEXT,
  p_message_body TEXT,
  p_related_load_id UUID DEFAULT NULL,
  p_related_trip_id UUID DEFAULT NULL,
  p_attachment_path TEXT DEFAULT NULL,
  p_priority TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
  v_category TEXT;
  v_message_body TEXT;
  v_related_load_id UUID;
  v_related_trip_id UUID;
  v_support_ticket_id UUID;
  v_priority support_ticket_priority;
  v_trip RECORD;
  v_load RECORD;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  v_category := lower(btrim(COALESCE(p_category, '')));
  IF v_category NOT IN (
    'general',
    'account',
    'load',
    'trip',
    'payment',
    'technical',
    'other',
    'loaded_quantity_mismatch',
    'unloaded_quantity_mismatch',
    'document_mismatch',
    'non_payment',
    'fake_payout_proof',
    'delay_or_no_show',
    'damage_or_shortage',
    'abusive_behavior',
    'spam_or_scam',
    'trip_dispute'
  ) THEN
    RAISE EXCEPTION 'Unsupported support category';
  END IF;

  v_message_body := btrim(COALESCE(p_message_body, ''));
  IF char_length(v_message_body) < 10 THEN
    RAISE EXCEPTION 'Support description too short';
  END IF;

  v_related_load_id := p_related_load_id;
  v_related_trip_id := p_related_trip_id;

  IF v_related_trip_id IS NOT NULL THEN
    SELECT id, load_id, supplier_id, trucker_id INTO v_trip
    FROM trips
    WHERE id = v_related_trip_id
    FOR UPDATE;

    IF v_trip IS NULL THEN
      RAISE EXCEPTION 'Trip not found';
    END IF;

    IF v_trip.supplier_id IS DISTINCT FROM v_user_id
       AND v_trip.trucker_id IS DISTINCT FROM v_user_id THEN
      RAISE EXCEPTION 'Trip does not belong to current user';
    END IF;

    IF v_related_load_id IS NOT NULL AND v_related_load_id IS DISTINCT FROM v_trip.load_id THEN
      RAISE EXCEPTION 'Related load does not match trip context';
    END IF;

    v_related_load_id := v_trip.load_id;
  END IF;

  IF v_related_load_id IS NOT NULL THEN
    SELECT id, supplier_id INTO v_load
    FROM loads
    WHERE id = v_related_load_id
    FOR UPDATE;

    IF v_load IS NULL THEN
      RAISE EXCEPTION 'Load not found';
    END IF;

    IF v_load.supplier_id IS DISTINCT FROM v_user_id
       AND NOT EXISTS (
         SELECT 1
         FROM trips
         WHERE load_id = v_related_load_id
           AND (supplier_id = v_user_id OR trucker_id = v_user_id)
       ) THEN
      RAISE EXCEPTION 'Load does not belong to current user';
    END IF;
  END IF;

  IF NULLIF(btrim(COALESCE(p_priority, '')), '') IS NOT NULL THEN
    CASE lower(btrim(p_priority))
      WHEN 'low' THEN v_priority := 'low';
      WHEN 'medium' THEN v_priority := 'medium';
      WHEN 'high' THEN v_priority := 'high';
      WHEN 'urgent' THEN v_priority := 'urgent';
      ELSE RAISE EXCEPTION 'Unsupported support priority';
    END CASE;
  ELSE
    v_priority := CASE
      WHEN v_category IN ('spam_or_scam', 'abusive_behavior', 'fake_payout_proof') THEN 'urgent'::support_ticket_priority
      WHEN v_category IN (
        'payment',
        'non_payment',
        'loaded_quantity_mismatch',
        'unloaded_quantity_mismatch',
        'document_mismatch',
        'delay_or_no_show',
        'damage_or_shortage',
        'trip_dispute'
      ) THEN 'high'::support_ticket_priority
      ELSE 'medium'::support_ticket_priority
    END;
  END IF;

  INSERT INTO support_tickets (
    owner_profile_id,
    category,
    status,
    priority,
    related_load_id,
    related_trip_id
  ) VALUES (
    v_user_id,
    v_category,
    'open',
    v_priority,
    v_related_load_id,
    v_related_trip_id
  ) RETURNING id INTO v_support_ticket_id;

  INSERT INTO support_ticket_messages (
    support_ticket_id,
    sender_profile_id,
    message_body,
    attachment_path,
    visibility_class
  ) VALUES (
    v_support_ticket_id,
    v_user_id,
    v_message_body,
    NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
    'visible'
  );

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'support_update',
    CASE
      WHEN v_priority IN ('high', 'urgent') THEN 'high'::notification_priority
      ELSE 'medium'::notification_priority
    END,
    'New Support Ticket',
    'A user opened a new support ticket requiring review.',
    v_related_load_id,
    v_related_trip_id,
    v_support_ticket_id,
    '/admin/support'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_support_ticket_id;
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
  v_user_id UUID;
  v_ticket RECORD;
  v_message_id UUID;
  v_message_body TEXT;
  v_visibility_class TEXT;
BEGIN
  v_admin_user_id := current_admin_user_id();
  v_user_id := auth.uid();

  IF v_admin_user_id IS NULL AND v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  v_message_body := btrim(COALESCE(p_message_body, ''));
  IF char_length(v_message_body) < 2 THEN
    RAISE EXCEPTION 'Reply is too short';
  END IF;

  v_visibility_class := lower(btrim(COALESCE(p_visibility_class, 'visible')));
  IF v_admin_user_id IS NOT NULL AND v_visibility_class NOT IN ('visible', 'internal') THEN
    RAISE EXCEPTION 'Unsupported visibility class';
  END IF;
  IF v_admin_user_id IS NULL AND v_visibility_class != 'visible' THEN
    RAISE EXCEPTION 'Users can only send visible replies';
  END IF;

  SELECT * INTO v_ticket
  FROM support_tickets
  WHERE id = p_support_ticket_id
  FOR UPDATE;

  IF v_ticket IS NULL THEN
    RAISE EXCEPTION 'Support ticket not found';
  END IF;

  IF v_admin_user_id IS NOT NULL THEN
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
      NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
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
        'has_attachment', NULLIF(btrim(COALESCE(p_attachment_path, '')), '') IS NOT NULL
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
        '/support'
      );
    END IF;

    RETURN v_message_id;
  END IF;

  IF v_ticket.owner_profile_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Support ticket does not belong to current user';
  END IF;

  IF v_ticket.status IN ('resolved', 'closed') THEN
    RAISE EXCEPTION 'Support ticket is already closed';
  END IF;

  INSERT INTO support_ticket_messages (
    support_ticket_id,
    sender_profile_id,
    message_body,
    attachment_path,
    visibility_class
  ) VALUES (
    p_support_ticket_id,
    v_user_id,
    v_message_body,
    NULLIF(btrim(COALESCE(p_attachment_path, '')), ''),
    'visible'
  ) RETURNING id INTO v_message_id;

  UPDATE support_tickets
  SET status = CASE
        WHEN status = 'waiting_for_user' THEN 'in_progress'::support_ticket_status
        ELSE status
      END,
      updated_at = NOW()
  WHERE id = p_support_ticket_id;

  INSERT INTO notifications (
    target_admin_user_id,
    notification_type,
    notification_priority,
    title_text,
    body_text,
    related_load_id,
    related_trip_id,
    related_case_id,
    action_route_hint
  )
  SELECT
    admin_users.id,
    'support_update',
    CASE
      WHEN v_ticket.priority IN ('high', 'urgent') THEN 'high'::notification_priority
      ELSE 'medium'::notification_priority
    END,
    'User Reply',
    'A support ticket has a new user reply.',
    v_ticket.related_load_id,
    v_ticket.related_trip_id,
    p_support_ticket_id,
    '/admin/support'
  FROM admin_users
  WHERE admin_users.is_active = TRUE;

  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
