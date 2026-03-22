-- ============================================================================
-- TranZfort Rebuild — Phase 7a: Row-Level Security Policies
-- Source of truth: docs/31-schema-rls-matrix.md
-- RULE: Prefer simple ownership checks. Use secure backend for privileged ops.
-- ============================================================================

-- Enable RLS on ALL tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE truckers ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_case_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE truck_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE trucks ENABLE ROW LEVEL SECURITY;
ALTER TABLE loads ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE operational_case_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE diesel_prices ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════
-- PROFILES
-- ═══════════════════════════════════════════════
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "profiles_admin_select" ON profiles FOR SELECT USING (is_admin());

-- ═══════════════════════════════════════════════
-- SUPPLIERS
-- ═══════════════════════════════════════════════
CREATE POLICY "suppliers_select_own" ON suppliers FOR SELECT USING (id = auth.uid());
CREATE POLICY "suppliers_update_own" ON suppliers FOR UPDATE USING (id = auth.uid());
CREATE POLICY "suppliers_admin_select" ON suppliers FOR SELECT USING (is_admin());

-- ═══════════════════════════════════════════════
-- TRUCKERS
-- ═══════════════════════════════════════════════
CREATE POLICY "truckers_select_own" ON truckers FOR SELECT USING (id = auth.uid());
CREATE POLICY "truckers_update_own" ON truckers FOR UPDATE USING (id = auth.uid());
CREATE POLICY "truckers_admin_select" ON truckers FOR SELECT USING (is_admin());

-- ═══════════════════════════════════════════════
-- ADMIN_USERS (no end-user access)
-- ═══════════════════════════════════════════════
CREATE POLICY "admin_users_admin_select" ON admin_users FOR SELECT USING (is_admin());

-- ═══════════════════════════════════════════════
-- USER_CONSENTS
-- ═══════════════════════════════════════════════
CREATE POLICY "consents_select_own" ON user_consents FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "consents_insert_own" ON user_consents FOR INSERT WITH CHECK (profile_id = auth.uid());

-- ═══════════════════════════════════════════════
-- VERIFICATION_CASES (no end-user raw access, admin only)
-- ═══════════════════════════════════════════════
CREATE POLICY "vcases_admin_select" ON verification_cases FOR SELECT USING (is_admin());
CREATE POLICY "vcases_admin_all" ON verification_cases FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════
-- VERIFICATION_CASE_EVENTS (admin only)
-- ═══════════════════════════════════════════════
CREATE POLICY "vevents_admin_select" ON verification_case_events FOR SELECT USING (is_admin());
CREATE POLICY "vevents_admin_insert" ON verification_case_events FOR INSERT WITH CHECK (is_admin());

-- ═══════════════════════════════════════════════
-- TRUCK_MODELS (authenticated read-only)
-- ═══════════════════════════════════════════════
CREATE POLICY "truck_models_authenticated_read" ON truck_models FOR SELECT USING (auth.uid() IS NOT NULL);

-- ═══════════════════════════════════════════════
-- TRUCKS
-- ═══════════════════════════════════════════════
CREATE POLICY "trucks_select_own" ON trucks FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "trucks_insert_own" ON trucks FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "trucks_update_own" ON trucks FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "trucks_admin_select" ON trucks FOR SELECT USING (is_admin());
CREATE POLICY "trucks_admin_update" ON trucks FOR UPDATE USING (is_admin());

-- ═══════════════════════════════════════════════
-- LOADS
-- ═══════════════════════════════════════════════
-- Supplier: full ownership on own loads
CREATE POLICY "loads_supplier_select" ON loads FOR SELECT USING (supplier_id = auth.uid());
CREATE POLICY "loads_supplier_insert" ON loads FOR INSERT WITH CHECK (supplier_id = auth.uid());
CREATE POLICY "loads_supplier_update" ON loads FOR UPDATE USING (supplier_id = auth.uid());

-- Trucker: read marketplace-visible loads (active, assigned_partial)
CREATE POLICY "loads_trucker_select" ON loads FOR SELECT USING (
  status IN ('active', 'assigned_partial') AND parent_load_id IS NULL
);

-- Admin: operational access
CREATE POLICY "loads_admin_select" ON loads FOR SELECT USING (is_admin());
CREATE POLICY "loads_admin_update" ON loads FOR UPDATE USING (is_admin());

-- ═══════════════════════════════════════════════
-- BOOKING_REQUESTS
-- ═══════════════════════════════════════════════
-- Trucker: own bookings
CREATE POLICY "bookings_trucker_select" ON booking_requests FOR SELECT USING (trucker_id = auth.uid());
CREATE POLICY "bookings_trucker_insert" ON booking_requests FOR INSERT WITH CHECK (trucker_id = auth.uid());

-- Supplier: bookings on own loads
CREATE POLICY "bookings_supplier_select" ON booking_requests FOR SELECT USING (
  load_id IN (SELECT id FROM loads WHERE supplier_id = auth.uid())
);
CREATE POLICY "bookings_supplier_update" ON booking_requests FOR UPDATE USING (
  load_id IN (SELECT id FROM loads WHERE supplier_id = auth.uid())
);

-- Admin
CREATE POLICY "bookings_admin_all" ON booking_requests FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════
-- TRIPS
-- ═══════════════════════════════════════════════
CREATE POLICY "trips_trucker_select" ON trips FOR SELECT USING (trucker_id = auth.uid());
CREATE POLICY "trips_trucker_update" ON trips FOR UPDATE USING (trucker_id = auth.uid());
CREATE POLICY "trips_supplier_select" ON trips FOR SELECT USING (supplier_id = auth.uid());
CREATE POLICY "trips_supplier_update" ON trips FOR UPDATE USING (supplier_id = auth.uid());
CREATE POLICY "trips_admin_all" ON trips FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════
-- RATINGS
-- ═══════════════════════════════════════════════
CREATE POLICY "ratings_insert_own" ON ratings FOR INSERT WITH CHECK (reviewer_id = auth.uid());
CREATE POLICY "ratings_select_own" ON ratings FOR SELECT USING (
  reviewer_id = auth.uid() OR reviewee_id = auth.uid()
);
CREATE POLICY "ratings_admin_select" ON ratings FOR SELECT USING (is_admin());

-- ═══════════════════════════════════════════════
-- CONVERSATIONS (participant-only)
-- ═══════════════════════════════════════════════
CREATE POLICY "conversations_participant_select" ON conversations FOR SELECT USING (
  supplier_id = auth.uid() OR trucker_id = auth.uid()
);
CREATE POLICY "conversations_participant_insert" ON conversations FOR INSERT WITH CHECK (
  supplier_id = auth.uid() OR trucker_id = auth.uid()
);

-- ═══════════════════════════════════════════════
-- MESSAGES (participant-only via conversation)
-- ═══════════════════════════════════════════════
CREATE POLICY "messages_participant_select" ON messages FOR SELECT USING (
  conversation_id IN (
    SELECT id FROM conversations WHERE supplier_id = auth.uid() OR trucker_id = auth.uid()
  )
);
CREATE POLICY "messages_participant_insert" ON messages FOR INSERT WITH CHECK (
  sender_profile_id = auth.uid() AND
  conversation_id IN (
    SELECT id FROM conversations WHERE supplier_id = auth.uid() OR trucker_id = auth.uid()
  )
);
CREATE POLICY "messages_update_read" ON messages FOR UPDATE USING (
  conversation_id IN (
    SELECT id FROM conversations WHERE supplier_id = auth.uid() OR trucker_id = auth.uid()
  )
);

-- ═══════════════════════════════════════════════
-- NOTIFICATIONS (target-actor-only)
-- ═══════════════════════════════════════════════
CREATE POLICY "notifications_user_select" ON notifications FOR SELECT USING (target_profile_id = auth.uid());
CREATE POLICY "notifications_user_update" ON notifications FOR UPDATE USING (target_profile_id = auth.uid());
CREATE POLICY "notifications_admin_select" ON notifications FOR SELECT USING (
  is_admin() AND target_admin_user_id IS NOT NULL
);
CREATE POLICY "notifications_admin_update" ON notifications FOR UPDATE USING (
  is_admin() AND target_admin_user_id IS NOT NULL
);

-- ═══════════════════════════════════════════════
-- SUPPORT_TICKETS
-- ═══════════════════════════════════════════════
CREATE POLICY "tickets_user_select" ON support_tickets FOR SELECT USING (owner_profile_id = auth.uid());
CREATE POLICY "tickets_user_insert" ON support_tickets FOR INSERT WITH CHECK (owner_profile_id = auth.uid());
CREATE POLICY "tickets_admin_all" ON support_tickets FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════
-- SUPPORT_TICKET_MESSAGES
-- ═══════════════════════════════════════════════
CREATE POLICY "stm_user_select" ON support_ticket_messages FOR SELECT USING (
  support_ticket_id IN (SELECT id FROM support_tickets WHERE owner_profile_id = auth.uid())
  AND visibility_class = 'visible'
);
CREATE POLICY "stm_user_insert" ON support_ticket_messages FOR INSERT WITH CHECK (
  sender_profile_id = auth.uid()
);
CREATE POLICY "stm_admin_all" ON support_ticket_messages FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════
-- OPERATIONAL_CASES (no end-user access)
-- ═══════════════════════════════════════════════
CREATE POLICY "opcases_admin_all" ON operational_cases FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════
-- OPERATIONAL_CASE_EVENTS (no end-user access)
-- ═══════════════════════════════════════════════
CREATE POLICY "opevents_admin_all" ON operational_case_events FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════
-- AUDIT_LOGS (no end-user, admin scoped)
-- ═══════════════════════════════════════════════
CREATE POLICY "audit_admin_select" ON audit_logs FOR SELECT USING (is_admin());

-- ═══════════════════════════════════════════════
-- DIESEL_PRICES (authenticated read-only)
-- ═══════════════════════════════════════════════
CREATE POLICY "diesel_prices_read" ON diesel_prices FOR SELECT USING (auth.uid() IS NOT NULL);
