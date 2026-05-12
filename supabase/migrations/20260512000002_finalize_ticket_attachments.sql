-- RPC to finalize draft attachments to a ticket
-- Part of Phase 7.2: Redesign Support Attachment Lifecycle
-- Called after ticket creation to link draft attachments

CREATE OR REPLACE FUNCTION public.finalize_ticket_attachments(
  p_ticket_id UUID,
  p_session_id TEXT
)
RETURNS INT AS $$
DECLARE
  v_count INT;
  v_user_id UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  
  -- Finalize all user's draft attachments for this session
  UPDATE public.ticket_attachments
  SET 
    ticket_id = p_ticket_id,
    upload_status = 'uploaded',
    updated_at = NOW()
  WHERE 
    uploaded_by = v_user_id
    AND ticket_id IS NULL
    AND file_path LIKE '%' || p_session_id || '%';
  
  -- Return count of finalized attachments
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.finalize_ticket_attachments(UUID, TEXT) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.finalize_ticket_attachments IS 
'Finalizes draft attachments (uploaded before ticket creation) to a specific ticket.
Updates ticket_id and upload_status for all attachments matching the session_id.
Returns the count of attachments finalized.';
