-- Sprint 6: Trip document storage bucket (LR/POD)

INSERT INTO storage.buckets (id, name, public)
VALUES ('load-documents', 'load-documents', true)
ON CONFLICT DO NOTHING;

-- Allow authenticated app users to upload trip/load documents.
CREATE POLICY "Authenticated users can upload load documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'load-documents');

-- Allow authenticated app users to read trip/load documents.
CREATE POLICY "Authenticated users can view load documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'load-documents');
