-- ============================================================================
-- EMERGENCY SCHEMA FIXES - 21 March 2026
-- Fixes 10 critical bugs found during microscopic testing
-- ============================================================================

-- Bug 7: Add missing enum values to load_status
-- Check if 'booked' exists, if not add it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'booked' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'load_status')
  ) THEN
    ALTER TYPE load_status ADD VALUE 'booked' AFTER 'active';
  END IF;
END $$;

-- Bug 8: Add missing enum values to booking_status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'cancelled' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'booking_status')
  ) THEN
    ALTER TYPE booking_status ADD VALUE 'cancelled' AFTER 'rejected';
  END IF;
END $$;

-- Bug 9: Add missing enum values to trip_stage
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'pickup' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'trip_stage')
  ) THEN
    ALTER TYPE trip_stage ADD VALUE 'pickup' AFTER 'assigned';
  END IF;
END $$;

-- Bug 3: Add has_business_license column to profiles (or suppliers table)
-- First check if it should be in profiles or suppliers
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'has_business_license'
  ) THEN
    ALTER TABLE profiles ADD COLUMN has_business_license BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Bug 4: Add type column to notifications
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'type'
  ) THEN
    ALTER TABLE notifications ADD COLUMN type TEXT;
    
    -- Add index for performance
    CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
  END IF;
END $$;

-- Note: profiles.role should NOT be added - use user_role_type instead
-- Note: profiles.approved_truck_count should NOT be added - compute from trucks table

-- ============================================================================
-- END OF EMERGENCY FIXES
-- ============================================================================
