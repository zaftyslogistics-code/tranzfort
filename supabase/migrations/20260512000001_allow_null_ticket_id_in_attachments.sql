-- Allow ticket_id to be NULL in ticket_attachments table
-- This enables draft attachment uploads before ticket creation
-- Part of Phase 7.2: Redesign Support Attachment Lifecycle

-- Step 1: Drop NOT NULL constraint on ticket_id
ALTER TABLE public.ticket_attachments ALTER COLUMN ticket_id DROP NOT NULL;

-- Step 2: Add index for efficient cleanup of orphaned attachments
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_orphaned 
ON public.ticket_attachments(ticket_id) 
WHERE ticket_id IS NULL;

-- Step 3: Add comment to document the change
COMMENT ON COLUMN public.ticket_attachments.ticket_id IS 
'Can be NULL for draft attachments before ticket creation. Finalized via finalize_ticket_attachments RPC.';
