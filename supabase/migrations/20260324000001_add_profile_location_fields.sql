-- Migration: Add location fields to profiles table for streamlined onboarding
-- Created: March 24, 2026

-- Add location fields to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS location_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_lng DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_source TEXT; -- 'gps', 'manual', null

-- Add comments for documentation
COMMENT ON COLUMN profiles.city IS 'Operating city captured during onboarding';
COMMENT ON COLUMN profiles.state IS 'Operating state captured during onboarding';
COMMENT ON COLUMN profiles.location_lat IS 'GPS latitude if captured via auto-detect';
COMMENT ON COLUMN profiles.location_lng IS 'GPS longitude if captured via auto-detect';
COMMENT ON COLUMN profiles.location_source IS 'How location was captured: gps, manual, or null';

-- Create index for location-based queries (useful for load matching)
CREATE INDEX IF NOT EXISTS idx_profiles_city ON profiles(city);
CREATE INDEX IF NOT EXISTS idx_profiles_state ON profiles(state);

-- Update the handle_new_user trigger to initialize location fields as null
-- (no change needed, new columns are nullable)

-- Note: Existing users will have null values, which is fine
-- Verification flow will check both profile location AND supplier verification_location
