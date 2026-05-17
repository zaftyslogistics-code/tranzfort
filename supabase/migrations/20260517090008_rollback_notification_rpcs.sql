-- Migration: Rollback P3.8 Notification RPCs
-- Purpose: Drop notification RPCs created in P3.8 (rollback)
-- Created: May 17, 2026
-- Part of: P3.8 - Notification RPCs (Rollback)

-- ═══════════════════════════════════════════════════════════════════════════════
-- Rollback: Drop notification RPCs (mark_notification_read and mark_all_notifications_read remain as they were pre-existing)
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS get_notifications(UUID, INT, TIMESTAMPTZ, UUID);
DROP FUNCTION IF EXISTS get_unread_notification_count(UUID);
