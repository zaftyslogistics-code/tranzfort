-- Rollback migration for P3.1, P3.2, P3.4, P3.7 core business RPCs
-- Run this to revert all new RPCs if issues occur in production

DROP FUNCTION IF EXISTS get_current_user_profile();
DROP FUNCTION IF EXISTS record_user_consent(TEXT, TEXT, TEXT);

DROP FUNCTION IF EXISTS get_supplier_loads_list(UUID, TEXT[], TEXT, INT, INT);
DROP FUNCTION IF EXISTS get_supplier_load_detail(UUID, UUID);
DROP FUNCTION IF EXISTS get_supplier_linked_trips(UUID, UUID);

DROP FUNCTION IF EXISTS get_trucker_trips(UUID, TEXT[], INT, INT);
DROP FUNCTION IF EXISTS get_trip_detail(UUID, UUID);
DROP FUNCTION IF EXISTS update_trip_lr(UUID, TEXT);
DROP FUNCTION IF EXISTS get_own_rating(UUID, UUID);
DROP FUNCTION IF EXISTS get_supplier_extension(UUID);

DROP FUNCTION IF EXISTS get_support_tickets(UUID, INT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS get_support_ticket_detail(UUID, UUID);
DROP FUNCTION IF EXISTS get_support_ticket_messages(UUID, UUID, INT, TIMESTAMPTZ, UUID);
