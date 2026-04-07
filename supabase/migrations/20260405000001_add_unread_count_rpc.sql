-- Migration: Add server-side unread count RPC
-- Phase 3-F: Move client-side unread counts to server-side RPC

DROP FUNCTION IF EXISTS public.get_current_user_unread_conversation_count();

CREATE OR REPLACE FUNCTION public.get_current_user_unread_conversation_count()
RETURNS INTEGER AS $$
DECLARE
  unread_count INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT COUNT(DISTINCT c.id)
  INTO unread_count
  FROM conversations c
  WHERE (c.supplier_id = auth.uid() OR c.trucker_id = auth.uid())
    AND EXISTS (
      SELECT 1
      FROM messages m
      WHERE m.conversation_id = c.id
        AND m.sender_profile_id IS DISTINCT FROM auth.uid()
        AND m.is_read = FALSE
      LIMIT 1
    );

  RETURN COALESCE(unread_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_current_user_unread_conversation_count() TO authenticated;

COMMENT ON FUNCTION public.get_current_user_unread_conversation_count() IS 
  'Returns the count of conversations with unread messages for the current user. Phase 3-F optimization.';
