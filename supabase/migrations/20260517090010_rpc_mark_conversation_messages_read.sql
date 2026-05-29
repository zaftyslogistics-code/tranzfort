-- Migration: Create RPC mark_conversation_messages_read
-- Purpose: Mark all messages in a conversation as read (replaces direct table update)
-- Created: May 17, 2026
-- Part of: P3.6 - Chat RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: mark_conversation_messages_read
-- Returns: VOID (success/failure)
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION mark_conversation_messages_read(
    p_conversation_id UUID,
    p_reader_id UUID
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Mark all messages in the conversation as read
    -- Only mark messages where the sender is not the reader
    UPDATE messages
    SET is_read = true,
        read_at = NOW()
    WHERE conversation_id = p_conversation_id
      AND sender_profile_id != p_reader_id
      AND is_read = false;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION mark_conversation_messages_read(UUID, UUID) TO authenticated;
