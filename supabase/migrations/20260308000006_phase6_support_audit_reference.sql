-- ============================================================================
-- TranZfort Rebuild — Phase 6: Support, Ops Cases, Audit & Reference Tables
-- Source of truth: docs/28-schema-tables-support-and-ops-cases.md
-- docs/29-schema-tables-audit-core.md
-- docs/61-missing-feature-specs-and-schemas.md §2 (diesel_prices)
-- ============================================================================

-- ─── support_tickets ───
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_profile_id UUID NOT NULL REFERENCES profiles(id),
  category TEXT NOT NULL,
  status support_ticket_status NOT NULL DEFAULT 'open',
  priority support_ticket_priority DEFAULT 'medium',
  related_load_id UUID REFERENCES loads(id),
  related_trip_id UUID REFERENCES trips(id),
  resolution_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_support_tickets_owner ON support_tickets(owner_profile_id, created_at DESC);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_priority ON support_tickets(priority);

CREATE TRIGGER trg_support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── support_ticket_messages ───
CREATE TABLE support_ticket_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  support_ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender_profile_id UUID REFERENCES profiles(id),
  sender_admin_user_id UUID REFERENCES admin_users(id),
  message_body TEXT,
  attachment_path TEXT,
  visibility_class TEXT DEFAULT 'visible',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stm_ticket_created ON support_ticket_messages(support_ticket_id, created_at);

-- ─── operational_cases ───
CREATE TABLE operational_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_type TEXT NOT NULL,
  primary_object_type TEXT NOT NULL,
  primary_object_id UUID NOT NULL,
  queue_classification TEXT,
  status operational_case_status NOT NULL DEFAULT 'queued',
  claimed_by_admin_user_id UUID REFERENCES admin_users(id),
  claimed_at TIMESTAMPTZ,
  waiting_reason TEXT,
  escalated_to_admin_user_id UUID REFERENCES admin_users(id),
  resolution_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_ops_cases_status ON operational_cases(status);
CREATE INDEX idx_ops_cases_queue ON operational_cases(queue_classification);
CREATE INDEX idx_ops_cases_claimed ON operational_cases(claimed_by_admin_user_id);
CREATE INDEX idx_ops_cases_status_claimed ON operational_cases(status, claimed_by_admin_user_id);

CREATE TRIGGER trg_operational_cases_updated_at
  BEFORE UPDATE ON operational_cases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── operational_case_events ───
CREATE TABLE operational_case_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operational_case_id UUID NOT NULL REFERENCES operational_cases(id) ON DELETE CASCADE,
  actor_admin_user_id UUID REFERENCES admin_users(id),
  event_type TEXT NOT NULL,
  event_summary TEXT,
  internal_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_oce_case_created ON operational_case_events(operational_case_id, created_at);
CREATE INDEX idx_oce_event_type ON operational_case_events(event_type);

-- ─── audit_logs ───
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_admin_user_id UUID REFERENCES admin_users(id),
  actor_type TEXT NOT NULL,
  actor_role TEXT,
  action_type audit_action_type NOT NULL,
  target_object_type TEXT,
  target_object_id UUID,
  secondary_object_type TEXT,
  secondary_object_id UUID,
  summary_text TEXT,
  payload_json JSONB,
  visibility_class TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_actor ON audit_logs(actor_admin_user_id);
CREATE INDEX idx_audit_action ON audit_logs(action_type);
CREATE INDEX idx_audit_target ON audit_logs(target_object_type, target_object_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);

-- ─── diesel_prices ───
-- Reference table for trip cost estimation (doc 61 §2)
CREATE TABLE diesel_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state TEXT NOT NULL UNIQUE,
  price_per_litre NUMERIC NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed diesel prices for Indian states
INSERT INTO diesel_prices (state, price_per_litre) VALUES
  ('Andhra Pradesh', 92.50), ('Arunachal Pradesh', 87.00), ('Assam', 89.50),
  ('Bihar', 91.00), ('Chhattisgarh', 90.50), ('Goa', 88.50),
  ('Gujarat', 90.00), ('Haryana', 89.00), ('Himachal Pradesh', 87.50),
  ('Jharkhand', 91.50), ('Karnataka', 90.50), ('Kerala', 93.00),
  ('Madhya Pradesh', 91.00), ('Maharashtra', 90.00), ('Manipur', 88.00),
  ('Meghalaya', 87.50), ('Mizoram', 88.00), ('Nagaland', 87.50),
  ('Odisha', 89.50), ('Punjab', 88.50), ('Rajasthan', 92.00),
  ('Sikkim', 88.00), ('Tamil Nadu', 91.50), ('Telangana', 92.50),
  ('Tripura', 88.50), ('Uttar Pradesh', 89.00), ('Uttarakhand', 88.50),
  ('West Bengal', 90.50), ('Delhi', 87.50), ('Chandigarh', 87.00),
  ('Jammu and Kashmir', 88.00), ('Ladakh', 88.50),
  ('Puducherry', 91.00), ('Lakshadweep', 92.00);
