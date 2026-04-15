-- Add city and state columns to profiles table as canonical location source
-- This is the production-ready solution for location data architecture

-- Add location columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS state TEXT;

-- Create indexes for location-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_city ON profiles(city);
CREATE INDEX IF NOT EXISTS idx_profiles_state ON profiles(state);

-- Migrate existing supplier verification locations to profiles
UPDATE profiles p
SET 
  city = s.verification_location_city,
  state = s.verification_location_state
FROM suppliers s
WHERE s.id = p.id 
  AND s.verification_location_city IS NOT NULL
  AND p.city IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN profiles.city IS 'User location city (canonical source for public profiles)';
COMMENT ON COLUMN profiles.state IS 'User location state (canonical source for public profiles)';
