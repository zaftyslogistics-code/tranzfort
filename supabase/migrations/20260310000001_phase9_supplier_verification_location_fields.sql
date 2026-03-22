ALTER TABLE suppliers
ADD COLUMN IF NOT EXISTS verification_location_city TEXT,
ADD COLUMN IF NOT EXISTS verification_location_state TEXT,
ADD COLUMN IF NOT EXISTS verification_location_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS verification_location_lng DOUBLE PRECISION;
