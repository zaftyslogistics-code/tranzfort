-- Migrate existing single attachment_path in support_ticket_messages to ticket_attachments table
-- This preserves existing data while transitioning to the new multiple attachments system

-- Step 1: Migrate existing single attachments from support_ticket_messages
INSERT INTO public.ticket_attachments (
  ticket_id,
  uploaded_by,
  file_name,
  file_path,
  file_size,
  mime_type,
  upload_status,
  scan_status,
  created_at
)
SELECT 
  stm.support_ticket_id AS ticket_id,
  stm.sender_profile_id AS uploaded_by,
  COALESCE(
    SPLIT_PART(stm.attachment_path, '/', -1),
    'attachment'
  ) AS file_name,
  stm.attachment_path AS file_path,
  0 AS file_size, -- Unknown size for existing attachments
  'application/octet-stream' AS mime_type, -- Unknown mime type
  'uploaded' AS upload_status,
  'pending' AS scan_status, -- Not scanned previously
  stm.created_at
FROM public.support_ticket_messages stm
WHERE stm.attachment_path IS NOT NULL
  AND stm.attachment_path != '';

-- Step 2: Drop attachment_path column from support_ticket_messages
ALTER TABLE public.support_ticket_messages DROP COLUMN IF EXISTS attachment_path;

-- Step 3: Add a helper function to get all attachments for a ticket
CREATE OR REPLACE FUNCTION public.get_ticket_attachments(
  p_ticket_id UUID
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_attachments JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', ta.id,
      'ticket_id', ta.ticket_id,
      'uploaded_by', ta.uploaded_by,
      'file_name', ta.file_name,
      'file_path', ta.file_path,
      'file_size', ta.file_size,
      'mime_type', ta.mime_type,
      'file_hash', ta.file_hash,
      'upload_status', ta.upload_status,
      'upload_error_message', ta.upload_error_message,
      'retry_count', ta.retry_count,
      'max_retries', ta.max_retries,
      'scan_status', ta.scan_status,
      'scan_result', ta.scan_result,
      'scanned_at', ta.scanned_at,
      'created_at', ta.created_at,
      'updated_at', ta.updated_at,
      'uploader_name', p.full_name,
      'uploader_avatar', p.avatar_url
    )
    ORDER BY ta.created_at ASC
  ) INTO v_attachments
  FROM public.ticket_attachments ta
  JOIN public.profiles p ON p.id = ta.uploaded_by
  WHERE ta.ticket_id = p_ticket_id;

  RETURN COALESCE(v_attachments, '[]'::JSONB);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_ticket_attachments(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_ticket_attachments(UUID) TO anon;
