-- P0-2: Restore notification list/count RPCs with auth.uid() guard (rolled back in 20260517090008).

CREATE OR REPLACE FUNCTION get_notifications(
    p_user_id UUID,
    p_limit INT DEFAULT 30,
    p_before_created_at TIMESTAMPTZ DEFAULT NULL,
    p_before_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_notifications JSONB;
    v_caller UUID := auth.uid();
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;
    IF p_user_id IS DISTINCT FROM v_caller THEN
        RAISE EXCEPTION 'forbidden';
    END IF;

    SELECT jsonb_agg(row_data ORDER BY created_at DESC, id DESC)
    INTO v_notifications
    FROM (
        SELECT
            jsonb_build_object(
                'id', n.id,
                'notification_type', n.notification_type,
                'notification_priority', n.notification_priority,
                'title_text', n.title_text,
                'body_text', n.body_text,
                'related_load_id', n.related_load_id,
                'related_trip_id', n.related_trip_id,
                'related_case_id', n.related_case_id,
                'action_route_hint', n.action_route_hint,
                'is_read', n.is_read,
                'read_at', n.read_at,
                'created_at', n.created_at
            ) AS row_data,
            n.created_at,
            n.id
        FROM notifications n
        WHERE n.target_profile_id = v_caller
          AND (p_before_created_at IS NULL OR n.created_at < p_before_created_at)
          AND (p_before_id IS NULL OR n.id < p_before_id)
        ORDER BY n.created_at DESC, n.id DESC
        LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 30), 100))
    ) ordered_rows;

    RETURN COALESCE(v_notifications, '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count INT;
    v_caller UUID := auth.uid();
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;
    IF p_user_id IS DISTINCT FROM v_caller THEN
        RAISE EXCEPTION 'forbidden';
    END IF;

    SELECT COUNT(*)::INT
    INTO v_count
    FROM notifications
    WHERE target_profile_id = v_caller
      AND is_read = false;

    RETURN COALESCE(v_count, 0);
END;
$$;

REVOKE ALL ON FUNCTION get_notifications(UUID, INT, TIMESTAMPTZ, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_unread_notification_count(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_notifications(UUID, INT, TIMESTAMPTZ, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notification_count(UUID) TO authenticated;
