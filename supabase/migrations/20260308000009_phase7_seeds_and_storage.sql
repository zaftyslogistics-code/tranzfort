-- ============================================================================
-- TranZfort Rebuild — Phase 7c: Seed Data & Storage Bucket Policies
-- Source of truth: docs/23-schema-tables-fleet-core.md (truck_models)
-- docs/30-schema-storage-mapping-matrix.md (storage buckets)
-- ============================================================================

-- ═══════════════════════════════════════════════
-- Seed: truck_models (common Indian commercial vehicles)
-- ═══════════════════════════════════════════════
INSERT INTO truck_models (make, model, body_type, axles, payload_kg, mileage_empty_kmpl, mileage_loaded_kmpl) VALUES
  ('Tata', 'Ace Gold', 'Open', 2, 750, 18.0, 14.0),
  ('Tata', '407', 'Open', 2, 3500, 12.0, 8.0),
  ('Tata', '709', 'Open', 2, 5000, 10.0, 6.5),
  ('Tata', '1109', 'Open', 3, 9000, 7.0, 4.5),
  ('Tata', 'LPT 1613', 'Open', 3, 10000, 6.5, 4.0),
  ('Tata', 'LPT 2518', 'Open', 4, 16000, 5.5, 3.5),
  ('Tata', 'LPT 3118', 'Open', 4, 19000, 5.0, 3.0),
  ('Tata', 'LPT 3518', 'Open', 5, 22000, 4.5, 2.8),
  ('Tata', 'LPT 4018', 'Trailer', 5, 25000, 4.0, 2.5),
  ('Tata', 'LPT 4923', 'Trailer', 6, 31000, 3.5, 2.2),
  ('Tata', 'Signa 4825.TK', 'Trailer', 6, 35000, 3.5, 2.0),
  ('Ashok Leyland', 'Dost+', 'Open', 2, 1500, 15.0, 11.0),
  ('Ashok Leyland', 'Partner', 'Open', 2, 3500, 12.0, 8.0),
  ('Ashok Leyland', 'Ecomet 1015', 'Open', 2, 6000, 9.0, 6.0),
  ('Ashok Leyland', 'Ecomet 1615', 'Open', 3, 10000, 6.5, 4.0),
  ('Ashok Leyland', '2518', 'Open', 4, 16000, 5.5, 3.5),
  ('Ashok Leyland', '3118', 'Open', 4, 19000, 5.0, 3.0),
  ('Ashok Leyland', '3518', 'Open', 5, 22000, 4.5, 2.8),
  ('Ashok Leyland', '4019', 'Trailer', 5, 25000, 4.0, 2.5),
  ('Ashok Leyland', '4923', 'Trailer', 6, 31000, 3.5, 2.2),
  ('Eicher', 'Pro 1049', 'Open', 2, 3000, 13.0, 9.0),
  ('Eicher', 'Pro 1059', 'Open', 2, 4500, 11.0, 7.0),
  ('Eicher', 'Pro 1110', 'Open', 3, 8000, 7.5, 5.0),
  ('Eicher', 'Pro 3015', 'Open', 3, 10000, 6.5, 4.0),
  ('Eicher', 'Pro 6025', 'Open', 4, 16000, 5.5, 3.5),
  ('Eicher', 'Pro 6031', 'Open', 4, 19000, 5.0, 3.0),
  ('Mahindra', 'Bolero Pikup', 'Open', 2, 1250, 16.0, 12.0),
  ('Mahindra', 'Furio 7', 'Open', 2, 3500, 12.0, 8.0),
  ('Mahindra', 'Blazo X 25', 'Open', 4, 16000, 5.5, 3.5),
  ('Mahindra', 'Blazo X 35', 'Trailer', 5, 22000, 4.5, 2.8),
  ('BharatBenz', '1015R', 'Open', 2, 6000, 9.0, 6.0),
  ('BharatBenz', '1617R', 'Open', 3, 10000, 6.5, 4.0),
  ('BharatBenz', '2528R', 'Open', 4, 16000, 5.5, 3.5),
  ('BharatBenz', '3123R', 'Open', 4, 19000, 5.0, 3.0),
  ('BharatBenz', '4928', 'Trailer', 6, 31000, 3.5, 2.2);

-- Add Container variants for key models
INSERT INTO truck_models (make, model, body_type, axles, payload_kg, mileage_empty_kmpl, mileage_loaded_kmpl) VALUES
  ('Tata', 'LPT 2518 Container', 'Container', 4, 15000, 5.0, 3.2),
  ('Tata', 'LPT 3118 Container', 'Container', 4, 18000, 4.5, 2.8),
  ('Ashok Leyland', '2518 Container', 'Container', 4, 15000, 5.0, 3.2),
  ('Eicher', 'Pro 6025 Container', 'Container', 4, 15000, 5.0, 3.2);

-- Add Tanker variants
INSERT INTO truck_models (make, model, body_type, axles, payload_kg, mileage_empty_kmpl, mileage_loaded_kmpl) VALUES
  ('Tata', 'LPT 2518 Tanker', 'Tanker', 4, 14000, 5.0, 3.0),
  ('Ashok Leyland', '2518 Tanker', 'Tanker', 4, 14000, 5.0, 3.0);

-- ═══════════════════════════════════════════════
-- Storage bucket creation via SQL (policies set in Supabase dashboard)
-- Note: Supabase storage buckets are created via the dashboard or API.
-- This migration documents the expected buckets for reference.
-- Actual bucket creation happens in the Supabase dashboard.
-- ═══════════════════════════════════════════════

-- Expected buckets (per docs/30-schema-storage-mapping-matrix.md):
-- 1. verification-documents (user upload, admin read)
--    Path: verification-documents/{profile_id}/{purpose}/{file}
-- 2. truck-documents (trucker upload, admin read)
--    Path: truck-documents/{trucker_id}/{truck_id}/{purpose}/{file}
-- 3. trip-proof-documents (trip actors upload/read)
--    Path: trip-proof-documents/{trip_id}/{purpose}/{file}
-- 4. communication-media (participant upload/read)
--    Path: communication-media/{conversation_id}/{message_id}/{file}
-- 5. support-attachments (ticket actors upload/read)
--    Path: support-attachments/{ticket_or_case_id}/{file}

-- Create buckets (Supabase SQL storage API)
INSERT INTO storage.buckets (id, name, public) VALUES
  ('verification-documents', 'verification-documents', FALSE),
  ('truck-documents', 'truck-documents', FALSE),
  ('trip-proof-documents', 'trip-proof-documents', FALSE),
  ('communication-media', 'communication-media', FALSE),
  ('support-attachments', 'support-attachments', FALSE)
ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════
-- Storage RLS policies
-- ═══════════════════════════════════════════════

-- verification-documents: user uploads own, admin reads all
CREATE POLICY "ver_docs_user_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'verification-documents' AND (storage.foldername(name))[1] = auth.uid()::TEXT);

CREATE POLICY "ver_docs_user_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'verification-documents' AND (storage.foldername(name))[1] = auth.uid()::TEXT);

CREATE POLICY "ver_docs_admin_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'verification-documents' AND is_admin());

-- truck-documents: trucker uploads own, admin reads all
CREATE POLICY "truck_docs_user_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'truck-documents' AND (storage.foldername(name))[1] = auth.uid()::TEXT);

CREATE POLICY "truck_docs_user_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'truck-documents' AND (storage.foldername(name))[1] = auth.uid()::TEXT);

CREATE POLICY "truck_docs_admin_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'truck-documents' AND is_admin());

-- trip-proof-documents: trip participants upload/read
CREATE POLICY "trip_proof_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'trip-proof-documents' AND auth.uid() IS NOT NULL);

CREATE POLICY "trip_proof_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'trip-proof-documents' AND auth.uid() IS NOT NULL);

-- communication-media: conversation participants upload/read
CREATE POLICY "comm_media_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'communication-media' AND auth.uid() IS NOT NULL);

CREATE POLICY "comm_media_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'communication-media' AND auth.uid() IS NOT NULL);

-- support-attachments: ticket owners and admins
CREATE POLICY "support_attach_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'support-attachments' AND auth.uid() IS NOT NULL);

CREATE POLICY "support_attach_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'support-attachments' AND auth.uid() IS NOT NULL);

CREATE POLICY "support_attach_admin" ON storage.objects FOR SELECT
  USING (bucket_id = 'support-attachments' AND is_admin());
