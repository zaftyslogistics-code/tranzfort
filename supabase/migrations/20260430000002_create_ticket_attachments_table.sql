-- Create ticket_attachments table to support multiple attachments per support ticket
-- This replaces the single attachment_path column in support_tickets table
-- Supports metadata, scan status, and retry tracking

-- Drop old single attachment column (data migration first)
-- ALTER TABLE public.support_tickets DROP COLUMN IF EXISTS attachment_path;

CREATE TABLE IF NOT EXISTS public.ticket_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- File metadata
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL, -- Storage path in Supabase Storage
  file_size BIGINT NOT NULL, -- Size in bytes
  mime_type TEXT NOT NULL, -- e.g., 'image/jpeg', 'application/pdf'
  file_hash TEXT, -- SHA-256 hash for deduplication
  
  -- Upload status
  upload_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'uploading', 'uploaded', 'failed'
  upload_error_message TEXT,
  retry_count INT DEFAULT 0,
  max_retries INT DEFAULT 3,
  
  -- Scan status (for security scanning)
  scan_status TEXT DEFAULT 'pending', -- 'pending', 'scanning', 'clean', 'infected', 'failed'
  scan_result TEXT, -- JSONB with scan details
  scanned_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT ticket_attachments_upload_status_check CHECK (upload_status IN ('pending', 'uploading', 'uploaded', 'failed')),
  CONSTRAINT ticket_attachments_scan_status_check CHECK (scan_status IN ('pending', 'scanning', 'clean', 'infected', 'failed'))
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_ticket_id ON public.ticket_attachments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_uploaded_by ON public.ticket_attachments(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_status ON public.ticket_attachments(upload_status);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_scan_status ON public.ticket_attachments(scan_status);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_file_hash ON public.ticket_attachments(file_hash);

-- Enable RLS
ALTER TABLE public.ticket_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view attachments for their own tickets" ON public.ticket_attachments
  FOR SELECT USING (
    ticket_id IN (
      SELECT id FROM public.support_tickets
      WHERE owner_profile_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert attachments for their own tickets" ON public.ticket_attachments
  FOR INSERT WITH CHECK (
    ticket_id IN (
      SELECT id FROM public.support_tickets
      WHERE owner_profile_id = auth.uid()
    )
    AND uploaded_by = auth.uid()
  );

CREATE POLICY "Users can update their own attachments" ON public.ticket_attachments
  FOR UPDATE USING (
    uploaded_by = auth.uid()
  );

CREATE POLICY "Users can delete their own attachments" ON public.ticket_attachments
  FOR DELETE USING (
    uploaded_by = auth.uid()
  );

-- Grant permissions
GRANT ALL ON TABLE public.ticket_attachments TO authenticated;
GRANT ALL ON TABLE public.ticket_attachments TO anon; -- For public access if needed

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_ticket_attachments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER ticket_attachments_updated_at
BEFORE UPDATE ON public.ticket_attachments
FOR EACH ROW
EXECUTE FUNCTION public.update_ticket_attachments_updated_at();
