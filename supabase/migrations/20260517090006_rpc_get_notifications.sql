-- Migration: Create RPC get_notifications
-- Purpose: Fetch notifications with pagination (replaces direct table read)
-- Created: May 17, 2026
-- Part of: P3.8 - Notification RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: get_notifications
-- Returns: List of notifications for the authenticated user
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION get_notifications(
    p_user_id UUID,
    p_limit INT DEFAULT 30,
    p_before_created_at TIMESTAMPTZ DEFAULT NULL,
    p_before_id UUID DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_notifications JSONB;
BEGIN
    SELECT jsonb_agg(
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
        )
    ) INTO v_notifications
    FROM notifications n
    WHERE n.target_profile_id = p_user_id
      AND (p_before_created_at IS NULL OR n.created_at < p_before_created_at)
      AND (p_before_id IS NULL OR n.id < p_before_id)
    ORDER BY n.created_at DESC, n.id DESC
    LIMIT p_limit;

    RETURN COALESCE(v_notifications, '[]'::jsonb);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_notifications(UUID, INT, TIMESTAMPTZ, UUID) TO authenticated;
