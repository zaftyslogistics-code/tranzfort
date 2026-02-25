-- Create storage buckets for Sprint 4 (Verification & Fleet)

-- Verification Docs Bucket (Aadhaar, PAN, DL, RC, Insurance, etc.)
INSERT INTO storage.buckets (id, name, public) VALUES ('verification-docs', 'verification-docs', false) ON CONFLICT DO NOTHING;

-- Profile Photos Bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', true) ON CONFLICT DO NOTHING;

-- Truck Photos Bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('truck-photos', 'truck-photos', true) ON CONFLICT DO NOTHING;

-- Setup RLS Policies for Storage
-- (Only the user who owns the document can read/write their own verification docs)

-- Verification Docs: Users can upload and read their own docs. Admins can read all (handled by service_role).
CREATE POLICY "Users can upload their own verification docs" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'verification-docs' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own verification docs" 
ON storage.objects FOR SELECT 
USING (
  bucket_id = 'verification-docs' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Profile Photos: Anyone can view, users can upload their own
CREATE POLICY "Anyone can view profile photos" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'profile-photos');

CREATE POLICY "Users can upload their own profile photos" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'profile-photos' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Truck Photos: Anyone can view, users can upload their own
CREATE POLICY "Anyone can view truck photos" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'truck-photos');

CREATE POLICY "Users can upload their own truck photos" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'truck-photos' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);
