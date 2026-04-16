-- ============================================================================
-- TranZfort Rebuild — Drop ALL old tables for fresh start
-- Keeps auth.users alive (existing Google auth users preserved)
-- Only drops public schema objects from the old app
-- ============================================================================

-- Drop old triggers first (if they exist)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Only drop the ratings trigger if the ratings table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ratings') THEN
        DROP TRIGGER IF EXISTS trg_update_trucker_rating ON ratings;
    END IF;
END $$;

-- Drop old tables in reverse dependency order (cascade handles FKs)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS operational_case_events CASCADE;
DROP TABLE IF EXISTS operational_cases CASCADE;
DROP TABLE IF EXISTS support_ticket_messages CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS ratings CASCADE;
DROP TABLE IF EXISTS trips CASCADE;
DROP TABLE IF EXISTS booking_requests CASCADE;
DROP TABLE IF EXISTS loads CASCADE;
DROP TABLE IF EXISTS trucks CASCADE;
DROP TABLE IF EXISTS truck_models CASCADE;
DROP TABLE IF EXISTS verification_case_events CASCADE;
DROP TABLE IF EXISTS verification_cases CASCADE;
DROP TABLE IF EXISTS user_consents CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS admin_users CASCADE;
DROP TABLE IF EXISTS truckers CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS payout_profiles CASCADE;
DROP TABLE IF EXISTS diesel_prices CASCADE;

-- Drop old enum types (if they exist)
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS admin_role CASCADE;
DROP TYPE IF EXISTS verification_status CASCADE;
DROP TYPE IF EXISTS truck_status CASCADE;
DROP TYPE IF EXISTS load_status CASCADE;
DROP TYPE IF EXISTS super_load_status CASCADE;
DROP TYPE IF EXISTS booking_status CASCADE;
DROP TYPE IF EXISTS trip_stage CASCADE;
DROP TYPE IF EXISTS support_ticket_status CASCADE;
DROP TYPE IF EXISTS support_ticket_priority CASCADE;
DROP TYPE IF EXISTS operational_case_status CASCADE;
DROP TYPE IF EXISTS notification_type CASCADE;
DROP TYPE IF EXISTS notification_priority CASCADE;
DROP TYPE IF EXISTS message_type CASCADE;
DROP TYPE IF EXISTS trust_safety_status CASCADE;
DROP TYPE IF EXISTS account_deletion_status CASCADE;
DROP TYPE IF EXISTS verification_case_status CASCADE;
DROP TYPE IF EXISTS verification_event_type CASCADE;
DROP TYPE IF EXISTS audit_action_type CASCADE;
DROP TYPE IF EXISTS dispute_category CASCADE;
DROP TYPE IF EXISTS price_type CASCADE;

-- Drop old functions
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS is_admin() CASCADE;
DROP FUNCTION IF EXISTS get_admin_role() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_trucker_rating() CASCADE;

-- Drop any other old functions that might exist from old-app
DROP FUNCTION IF EXISTS book_load(UUID, UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS approve_booking(UUID) CASCADE;
DROP FUNCTION IF EXISTS reject_booking(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS start_trip(UUID) CASCADE;
DROP FUNCTION IF EXISTS mark_delivered(UUID) CASCADE;
DROP FUNCTION IF EXISTS complete_trip(UUID) CASCADE;
DROP FUNCTION IF EXISTS auto_complete_delivered_trips() CASCADE;
DROP FUNCTION IF EXISTS get_loads_assigned_to_trucker(UUID) CASCADE;
