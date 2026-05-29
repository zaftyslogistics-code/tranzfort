-- Migration: Create RPC get_conversation_messages
-- Purpose: Fetch conversation messages with composite cursor pagination (fixes C-003)
-- Created: May 17, 2026
-- Part of: P3.6 - Chat RPCs

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: get_conversation_messages
-- Returns: List of messages with sender profile context
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION get_conversation_messages(
    p_conversation_id UUID,
    p_user_id UUID,
    p_limit INT DEFAULT 50,
    p_before_created_at TIMESTAMPTZ DEFAULT NULL,
    p_before_message_id UUID DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_messages JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', m.id,
            'conversation_id', m.conversation_id,
            'sender_profile_id', m.sender_profile_id,
            'message_type', m.message_type,
            'text_body', m.text_body,
            'attachment_path', m.attachment_path,
            'structured_payload', m.structured_payload,
            'is_read', m.is_read,
            'read_at', m.read_at,
            'created_at', m.created_at
        )
    ) INTO v_messages
    FROM messages m
    WHERE m.conversation_id = p_conversation_id
      AND (p_before_created_at IS NULL OR m.created_at < p_before_created_at)
      AND (p_before_message_id IS NULL OR m.id < p_before_message_id)
    ORDER BY m.created_at DESC, m.id DESC
    LIMIT p_limit;

    RETURN COALESCE(v_messages, '[]'::jsonb);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_conversation_messages(UUID, UUID, INT, TIMESTAMPTZ, UUID) TO authenticated;
