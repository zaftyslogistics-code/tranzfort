-- Migration: Sync Supplier Verification Location to Profile
-- Date: April 11, 2026
-- Purpose: Trigger to automatically copy supplier verification location to profiles table
-- Note: city/state columns and RPCs already exist from previous migrations

-- ============================================================
-- 1. Trigger Function: Sync supplier verification location to profile
-- NOTE: This is now a no-op since profiles table doesn't have city/state columns
-- Location data is stored in suppliers table (verification_location_city, verification_location_state)
-- ============================================================
create or replace function sync_supplier_location_to_profile()
returns trigger as $$
begin
  -- No-op: profiles table doesn't have city/state columns
  return new;
end;
$$ language plpgsql;

-- Drop if exists to allow recreation
drop trigger if exists trg_sync_supplier_location on suppliers;

-- Create trigger on suppliers table (no-op but kept for structure)
create trigger trg_sync_supplier_location
after update of verification_location_city, verification_location_state on suppliers
for each row execute function sync_supplier_location_to_profile();

-- ============================================================
-- 2. Initial Sync: No-op since profiles table doesn't have city/state columns
-- ============================================================
-- Skipping initial sync - profiles table doesn't have city/state columns

-- Add comment for documentation
comment on function sync_supplier_location_to_profile() is 'No-op: profiles table doesn''t have city/state columns';
