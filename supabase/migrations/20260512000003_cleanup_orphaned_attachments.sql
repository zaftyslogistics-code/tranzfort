-- RPC to clean up orphaned attachments
-- Part of Phase 7.2: Redesign Support Attachment Lifecycle
-- Can be called periodically (e.g., via cron job) to delete old draft attachments

CREATE OR REPLACE FUNCTION public.cleanup_orphaned_attachments(
  p_hours_older_than INTEGER DEFAULT 24
)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  -- Delete attachments without ticket_id older than specified hours
  DELETE FROM public.ticket_attachments
  WHERE 
    ticket_id IS NULL
    AND created_at < NOW() - (p_hours_older_than || ' hours')::INTERVAL;
  
  -- Return count of deleted attachments
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users (for admin use)
GRANT EXECUTE ON FUNCTION public.cleanup_orphaned_attachments(INTEGER) TO authenticated;

-- Grant execute permission to service_role (for scheduled jobs)
GRANT EXECUTE ON FUNCTION public.cleanup_orphaned_attachments(INTEGER) TO service_role;

-- Add comment
COMMENT ON FUNCTION public.cleanup_orphaned_attachments IS 
'Deletes orphaned draft attachments (attachments without ticket_id) older than specified hours.
Default is 24 hours. Returns the count of attachments deleted.
Note: This only deletes database records. Storage files should be cleaned up separately.';
