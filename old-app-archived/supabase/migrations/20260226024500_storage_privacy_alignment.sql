-- Align storage privacy with locked schema expectations.
-- Buckets that must NOT be public: truck-photos, load-documents, voice-messages.

UPDATE storage.buckets
SET public = false
WHERE id IN ('truck-photos', 'load-documents', 'voice-messages');

-- Remove previously broad/public-facing policies.
DROP POLICY IF EXISTS "Anyone can view truck photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload load documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view load documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload voice messages" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view voice messages" ON storage.objects;

-- Truck photos: authenticated users only (non-public bucket).
CREATE POLICY "Authenticated users can view truck photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'truck-photos');

CREATE POLICY "Authenticated users can upload truck photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'truck-photos');

-- Load documents (LR/POD): authenticated users only (non-public bucket).
CREATE POLICY "Authenticated users can upload load documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'load-documents');

CREATE POLICY "Authenticated users can view load documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'load-documents');

-- Voice messages: authenticated users only (non-public bucket).
CREATE POLICY "Authenticated users can upload voice messages"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'voice-messages');

CREATE POLICY "Authenticated users can view voice messages"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'voice-messages');
