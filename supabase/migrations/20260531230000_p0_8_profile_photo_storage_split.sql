-- P0-8: Profile photos in profile-photos bucket; KYC docs owner + admin only.

DROP POLICY IF EXISTS "Anyone can view profile photos" ON storage.objects;
DROP POLICY IF EXISTS "ver_docs_profile_photos_public_read" ON storage.objects;

-- Legacy profile photos still under verification-documents: owner read only.
CREATE POLICY "ver_docs_user_read_own_legacy_profile_photo"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'verification-documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
  AND name LIKE '%/profile_photo/%'
);

-- Marketplace / public profile avatars: authenticated read on profile-photos only.
CREATE POLICY "profile_photos_authenticated_read"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'profile-photos');
