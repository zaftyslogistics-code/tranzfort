-- Migration: Create RPC get_unread_notification_count
-- Purpose: Get unread notification count (replaces direct table read)
-- Created: May 17, 2026
-- Part of: P3.8 - Notification RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: get_unread_notification_count
-- Returns: Count of unread notifications for the authenticated user
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM notifications
    WHERE target_profile_id = p_user_id
      AND is_read = false;

    RETURN v_count;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_unread_notification_count(UUID) TO authenticated;
