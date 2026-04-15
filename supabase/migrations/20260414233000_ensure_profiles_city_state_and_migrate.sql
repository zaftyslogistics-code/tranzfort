-- Ensure profiles.city/state columns exist and migrate data from suppliers
-- This is the canonical fix for location architecture

-- Step 1: Ensure columns exist (IF NOT EXISTS to be safe)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS state TEXT;

-- Step 2: Create indexes for location-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_city ON profiles(city);
CREATE INDEX IF NOT EXISTS idx_profiles_state ON profiles(state);

-- Step 3: Migrate supplier verification location to profiles for any suppliers missing location
UPDATE profiles p
SET 
  city = COALESCE(p.city, s.verification_location_city),
  state = COALESCE(p.state, s.verification_location_state)
FROM suppliers s
WHERE s.id = p.id 
  AND s.verification_location_city IS NOT NULL
  AND (p.city IS NULL OR p.state IS NULL);

-- Step 4: Add comments for documentation
COMMENT ON COLUMN profiles.city IS 'User location city (canonical source for all users)';
COMMENT ON COLUMN profiles.state IS 'User location state (canonical source for all users)';
