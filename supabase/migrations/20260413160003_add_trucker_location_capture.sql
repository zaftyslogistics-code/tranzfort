-- Add location columns to truckers table for verification location capture
-- This enables truckers to have location data that can sync to profiles

ALTER TABLE truckers ADD COLUMN IF NOT EXISTS verification_location_city TEXT;
ALTER TABLE truckers ADD COLUMN IF NOT EXISTS verification_location_state TEXT;
ALTER TABLE truckers ADD COLUMN IF NOT EXISTS verification_location_lat DOUBLE PRECISION;
ALTER TABLE truckers ADD COLUMN IF NOT EXISTS verification_location_lng DOUBLE PRECISION;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_truckers_location_city ON truckers(verification_location_city);

-- Add comments
COMMENT ON COLUMN truckers.verification_location_city IS 'Trucker verification location city';
COMMENT ON COLUMN truckers.verification_location_state IS 'Trucker verification location state';
COMMENT ON COLUMN truckers.verification_location_lat IS 'Trucker verification location latitude';
COMMENT ON COLUMN truckers.verification_location_lng IS 'Trucker verification location longitude';
