-- Allow authenticated users to read profile photos from verification-documents bucket
-- This enables displaying supplier profile photos in marketplace and public profiles

-- Drop existing restrictive policy for profile photos
DROP POLICY IF EXISTS "ver_docs_user_read" ON storage.objects;

-- Create new policy: Users can read their own verification documents
CREATE POLICY "ver_docs_user_read"
ON storage.objects FOR SELECT
TO public
USING (
  bucket_id = 'verification-documents'
  AND (storage.foldername(name))[1] = (auth.uid())::text
  AND name NOT LIKE '%/profile_photo/%'
);

-- Create policy: Authenticated users can read all profile photos
CREATE POLICY "ver_docs_profile_photos_public_read"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'verification-documents'
  AND name LIKE '%/profile_photo/%'
);

-- Keep existing upload policy
DROP POLICY IF EXISTS "ver_docs_user_upload" ON storage.objects;
CREATE POLICY "ver_docs_user_upload"
ON storage.objects FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'verification-documents'
  AND (storage.foldername(name))[1] = (auth.uid())::text
);

-- Keep admin read policy
DROP POLICY IF EXISTS "ver_docs_admin_read" ON storage.objects;
CREATE POLICY "ver_docs_admin_read"
ON storage.objects FOR SELECT
TO public
USING (
  bucket_id = 'verification-documents'
  AND is_admin()
);
