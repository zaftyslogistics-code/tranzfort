-- ============================================================================
-- TranZfort Rebuild — Phase 3: Verification & Fleet Tables
-- Source of truth: docs/22-schema-tables-verification-core.md
-- docs/23-schema-tables-fleet-core.md
-- ============================================================================

-- ─── verification_cases ───
CREATE TABLE verification_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type TEXT NOT NULL CHECK (subject_type IN ('supplier_profile', 'trucker_profile', 'truck')),
  subject_id UUID NOT NULL,
  case_status verification_case_status NOT NULL DEFAULT 'submitted',
  assigned_admin_user_id UUID REFERENCES admin_users(id),
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_reviewed_at TIMESTAMPTZ,
  current_decision_summary TEXT,
  escalated_to_admin_user_id UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verification_cases_subject ON verification_cases(subject_type, subject_id);
CREATE INDEX idx_verification_cases_status ON verification_cases(case_status);
CREATE INDEX idx_verification_cases_assigned ON verification_cases(assigned_admin_user_id);
CREATE INDEX idx_verification_cases_submitted ON verification_cases(submitted_at);

CREATE TRIGGER trg_verification_cases_updated_at
  BEFORE UPDATE ON verification_cases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── verification_case_events ───
CREATE TABLE verification_case_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_case_id UUID NOT NULL REFERENCES verification_cases(id) ON DELETE CASCADE,
  event_type verification_event_type NOT NULL,
  actor_admin_user_id UUID REFERENCES admin_users(id),
  event_summary TEXT,
  internal_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vce_case_created ON verification_case_events(verification_case_id, created_at);
CREATE INDEX idx_vce_event_type ON verification_case_events(event_type);

-- ─── truck_models ───
-- Reference catalog of commercial vehicle models
CREATE TABLE truck_models (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  body_type TEXT NOT NULL,
  axles INTEGER,
  payload_kg INTEGER,
  length_ft NUMERIC,
  width_ft NUMERIC,
  height_ft NUMERIC,
  mileage_empty_kmpl NUMERIC,
  mileage_loaded_kmpl NUMERIC,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_truck_models_body_type ON truck_models(body_type);
CREATE INDEX idx_truck_models_is_active ON truck_models(is_active);

-- ─── trucks ───
-- Trucker-owned operational truck records
CREATE TABLE trucks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES truckers(id) ON DELETE CASCADE,
  truck_model_id UUID REFERENCES truck_models(id),
  truck_number TEXT NOT NULL UNIQUE,
  body_type TEXT NOT NULL,
  tyres INTEGER NOT NULL,
  capacity_tonnes NUMERIC NOT NULL,
  rc_document_path TEXT,
  status truck_status NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  verified_at TIMESTAMPTZ,
  verified_by_admin_user_id UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trucks_owner ON trucks(owner_id);
CREATE INDEX idx_trucks_status ON trucks(status);
CREATE INDEX idx_trucks_body_type ON trucks(body_type);

CREATE TRIGGER trg_trucks_updated_at
  BEFORE UPDATE ON trucks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
