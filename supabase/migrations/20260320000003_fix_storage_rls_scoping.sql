-- ============================================================================
-- Fix: Storage RLS too permissive for 3 buckets (F-B9-001)
-- Previously: auth.uid() IS NOT NULL — any authenticated user can read/write
-- Now: scoped to owner/participant via folder-path matching
-- ============================================================================

-- ═══════════════════════════════════════════════
-- trip-proof-documents: scoped to trip participants
-- Path convention: trip-proof-documents/{trip_id}/{purpose}/{file}
-- Only trucker or supplier linked to the trip may read/write
-- ═══════════════════════════════════════════════
DROP POLICY IF EXISTS "trip_proof_upload" ON storage.objects;
DROP POLICY IF EXISTS "trip_proof_read" ON storage.objects;

CREATE POLICY "trip_proof_upload_v2" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'trip-proof-documents'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM trips
      WHERE id::TEXT = (storage.foldername(name))[1]
        AND (trucker_id = auth.uid() OR supplier_id = auth.uid())
    )
  );

CREATE POLICY "trip_proof_read_v2" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'trip-proof-documents'
    AND (
      EXISTS (
        SELECT 1 FROM trips
        WHERE id::TEXT = (storage.foldername(name))[1]
          AND (trucker_id = auth.uid() OR supplier_id = auth.uid())
      )
      OR is_admin()
    )
  );

-- ═══════════════════════════════════════════════
-- communication-media: scoped to conversation participants
-- Path convention: communication-media/{conversation_id}/{message_id}/{file}
-- Only supplier or trucker in the conversation may read/write
-- ═══════════════════════════════════════════════
DROP POLICY IF EXISTS "comm_media_upload" ON storage.objects;
DROP POLICY IF EXISTS "comm_media_read" ON storage.objects;

CREATE POLICY "comm_media_upload_v2" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'communication-media'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE id::TEXT = (storage.foldername(name))[1]
        AND (supplier_id = auth.uid() OR trucker_id = auth.uid())
    )
  );

CREATE POLICY "comm_media_read_v2" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'communication-media'
    AND (
      EXISTS (
        SELECT 1 FROM conversations
        WHERE id::TEXT = (storage.foldername(name))[1]
          AND (supplier_id = auth.uid() OR trucker_id = auth.uid())
      )
      OR is_admin()
    )
  );

-- ═══════════════════════════════════════════════
-- support-attachments: scoped to ticket owner + admin
-- Path convention: support-attachments/{ticket_id}/{file}
-- Only ticket owner or admin may read/write
-- ═══════════════════════════════════════════════
DROP POLICY IF EXISTS "support_attach_upload" ON storage.objects;
DROP POLICY IF EXISTS "support_attach_read" ON storage.objects;
DROP POLICY IF EXISTS "support_attach_admin" ON storage.objects;

CREATE POLICY "support_attach_upload_v2" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'support-attachments'
    AND auth.uid() IS NOT NULL
    AND (
      EXISTS (
        SELECT 1 FROM support_tickets
        WHERE id::TEXT = (storage.foldername(name))[1]
          AND owner_profile_id = auth.uid()
      )
      OR is_admin()
    )
  );

CREATE POLICY "support_attach_read_v2" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'support-attachments'
    AND (
      EXISTS (
        SELECT 1 FROM support_tickets
        WHERE id::TEXT = (storage.foldername(name))[1]
          AND owner_profile_id = auth.uid()
      )
      OR is_admin()
    )
  );
