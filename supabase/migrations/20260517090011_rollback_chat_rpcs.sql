-- Migration: Rollback P3.6 Chat RPCs
-- Purpose: Drop chat RPCs created in P3.6 (rollback)
-- Created: May 17, 2026
-- Part of: P3.6 - Chat RPCs (Rollback)

-- ═══════════════════════════════════════════════════════════════════════════════
-- Rollback: Drop chat RPCs (existing RPCs remain: create_or_get_conversation, send_message, get_current_user_conversation_summaries, get_conversation_summary, get_current_user_unread_conversation_count)
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS get_conversation_messages(UUID, UUID, INT, TIMESTAMPTZ, UUID);
DROP FUNCTION IF EXISTS mark_conversation_messages_read(UUID, UUID);
