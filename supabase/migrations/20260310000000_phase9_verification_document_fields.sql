ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS aadhaar_front_document_path TEXT,
ADD COLUMN IF NOT EXISTS aadhaar_back_document_path TEXT,
ADD COLUMN IF NOT EXISTS pan_document_path TEXT,
ADD COLUMN IF NOT EXISTS profile_photo_document_path TEXT;

ALTER TABLE suppliers
ADD COLUMN IF NOT EXISTS business_licence_document_path TEXT,
ADD COLUMN IF NOT EXISTS gst_certificate_document_path TEXT;
