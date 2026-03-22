-- ============================================================================
-- FIX MISSING SUPPLIER PROFILE - 21 March 2026
-- The supplier_id in loads table doesn't have a matching profile
-- ============================================================================

-- Create profile for the supplier UUID that's referenced in loads
INSERT INTO profiles (id, full_name, mobile, user_role_type, verification_status, created_at)
VALUES ('a81ec79b-a795-475f-b96c-71666a9b7538', 'Test Supplier', '9876543210', 'supplier', 'unverified', NOW())
ON CONFLICT (id) DO UPDATE SET
    user_role_type = 'supplier',
    verification_status = COALESCE(profiles.verification_status, 'unverified');

-- Create supplier extension record
INSERT INTO suppliers (id, company_name, total_loads_posted, active_loads_count)
VALUES ('a81ec79b-a795-475f-b96c-71666a9b7538', 'Test Supplier Company', 0, 0)
ON CONFLICT (id) DO NOTHING;
