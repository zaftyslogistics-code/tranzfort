-- Storage Bucket for Voice Messages
INSERT INTO storage.buckets (id, name, public) 
VALUES ('voice-messages', 'voice-messages', true) 
ON CONFLICT DO NOTHING;

-- RLS for Voice Messages Bucket (Any authenticated user can read/write)
CREATE POLICY "Authenticated users can upload voice messages" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'voice-messages');

CREATE POLICY "Authenticated users can view voice messages" 
ON storage.objects FOR SELECT 
TO authenticated 
USING (bucket_id = 'voice-messages');
