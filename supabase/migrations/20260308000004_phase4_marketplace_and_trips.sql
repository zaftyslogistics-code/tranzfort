-- ============================================================================
-- TranZfort Rebuild — Phase 4: Marketplace Loads, Booking & Trips
-- Source of truth: docs/24-schema-tables-marketplace-loads.md
-- docs/25-schema-tables-booking-and-trips.md
-- docs/61-missing-feature-specs-and-schemas.md §3 (ratings), §4 (GPS)
-- ============================================================================

-- ─── loads ───
-- Canonical marketplace and pre-trip operational load object
CREATE TABLE loads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  parent_load_id UUID REFERENCES loads(id),

  -- Route fields (aligned with shared-route-data-spec.md)
  origin_label TEXT NOT NULL,
  origin_city TEXT NOT NULL,
  origin_state TEXT,
  origin_lat DOUBLE PRECISION,
  origin_lng DOUBLE PRECISION,
  destination_label TEXT NOT NULL,
  destination_city TEXT NOT NULL,
  destination_state TEXT,
  destination_lat DOUBLE PRECISION,
  destination_lng DOUBLE PRECISION,
  route_distance_km NUMERIC,
  route_duration_minutes INTEGER,
  route_polyline TEXT,
  route_snapshot_source TEXT,

  -- Cargo & requirements
  material TEXT NOT NULL,
  weight_tonnes NUMERIC NOT NULL CHECK (weight_tonnes > 0),
  required_body_type TEXT,
  required_tyres INTEGER[],
  trucks_needed INTEGER NOT NULL DEFAULT 1 CHECK (trucks_needed >= 1),
  trucks_booked INTEGER NOT NULL DEFAULT 0 CHECK (trucks_booked >= 0),

  -- Pricing
  price_amount NUMERIC NOT NULL CHECK (price_amount > 0),
  price_type price_type NOT NULL DEFAULT 'negotiable',
  advance_percentage INTEGER CHECK (advance_percentage BETWEEN 0 AND 100),

  -- Schedule
  pickup_date DATE NOT NULL,

  -- Status (canonical source: doc 33)
  status load_status NOT NULL DEFAULT 'draft',
  is_super_load BOOLEAN NOT NULL DEFAULT FALSE,
  super_status super_load_status NOT NULL DEFAULT 'none',

  -- Assignment references
  assigned_trucker_id UUID REFERENCES truckers(id),
  assigned_truck_id UUID REFERENCES trucks(id),

  -- Timestamps
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_loads_supplier ON loads(supplier_id);
CREATE INDEX idx_loads_status ON loads(status);
CREATE INDEX idx_loads_pickup_date ON loads(pickup_date);
CREATE INDEX idx_loads_origin_city ON loads(origin_city);
CREATE INDEX idx_loads_destination_city ON loads(destination_city);
CREATE INDEX idx_loads_is_super ON loads(is_super_load);
CREATE INDEX idx_loads_super_status ON loads(super_status);
CREATE INDEX idx_loads_parent ON loads(parent_load_id);
CREATE INDEX idx_loads_status_pickup ON loads(status, pickup_date);

CREATE TRIGGER trg_loads_updated_at
  BEFORE UPDATE ON loads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── booking_requests ───
-- Durable booking intent from trucker to supplier
CREATE TABLE booking_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  load_id UUID NOT NULL REFERENCES loads(id) ON DELETE CASCADE,
  trucker_id UUID NOT NULL REFERENCES truckers(id),
  truck_id UUID NOT NULL REFERENCES trucks(id),
  status booking_status NOT NULL DEFAULT 'submitted',
  decision_reason TEXT,
  decided_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_booking_load ON booking_requests(load_id);
CREATE INDEX idx_booking_trucker ON booking_requests(trucker_id);
CREATE INDEX idx_booking_truck ON booking_requests(truck_id);
CREATE INDEX idx_booking_status ON booking_requests(status);

CREATE TRIGGER trg_booking_requests_updated_at
  BEFORE UPDATE ON booking_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── trips ───
-- Canonical execution object after assignment
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  load_id UUID NOT NULL REFERENCES loads(id),
  supplier_id UUID NOT NULL REFERENCES suppliers(id),
  trucker_id UUID NOT NULL REFERENCES truckers(id),
  truck_id UUID NOT NULL REFERENCES trucks(id),
  stage trip_stage NOT NULL DEFAULT 'assigned',

  -- Stage timestamps
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  pod_uploaded_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  -- Proof documents
  lr_document_path TEXT,
  pod_document_path TEXT,

  -- GPS bounded captures (doc 61 §4)
  gps_pickup_lat DOUBLE PRECISION,
  gps_pickup_lng DOUBLE PRECISION,
  gps_loaded_lat DOUBLE PRECISION,
  gps_loaded_lng DOUBLE PRECISION,
  gps_delivered_lat DOUBLE PRECISION,
  gps_delivered_lng DOUBLE PRECISION,
  gps_pod_lat DOUBLE PRECISION,
  gps_pod_lng DOUBLE PRECISION,

  -- Snapshots for historical correctness
  route_snapshot_summary JSONB,
  load_snapshot_summary JSONB,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_load ON trips(load_id);
CREATE INDEX idx_trips_supplier ON trips(supplier_id);
CREATE INDEX idx_trips_trucker ON trips(trucker_id);
CREATE INDEX idx_trips_truck ON trips(truck_id);
CREATE INDEX idx_trips_stage ON trips(stage);
CREATE INDEX idx_trips_trucker_stage ON trips(trucker_id, stage);
CREATE INDEX idx_trips_supplier_stage ON trips(supplier_id, stage);
CREATE INDEX idx_trips_assigned_at ON trips(assigned_at);

CREATE TRIGGER trg_trips_updated_at
  BEFORE UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── ratings ───
-- Post-trip mutual rating system (doc 61 §3)
CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  load_id UUID NOT NULL REFERENCES loads(id),
  trip_id UUID REFERENCES trips(id),
  reviewer_id UUID NOT NULL REFERENCES profiles(id),
  reviewee_id UUID NOT NULL REFERENCES profiles(id),
  reviewer_role user_role NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(load_id, reviewer_id)
);

CREATE INDEX idx_ratings_reviewee ON ratings(reviewee_id);
CREATE INDEX idx_ratings_load ON ratings(load_id);

-- Trigger: auto-update trucker aggregate rating after new rating
CREATE OR REPLACE FUNCTION update_trucker_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE truckers
  SET rating = (
    SELECT COALESCE(AVG(r.score), 0)
    FROM ratings r
    WHERE r.reviewee_id = NEW.reviewee_id
  )
  WHERE id = NEW.reviewee_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_trucker_rating
  AFTER INSERT ON ratings
  FOR EACH ROW
  WHEN (NEW.reviewer_role = 'supplier')
  EXECUTE FUNCTION update_trucker_rating();
