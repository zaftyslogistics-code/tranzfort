# 02: Database Schema & RPC Authority

**Status:** LOCKED  
**Audience:** All Developers  
**Objective:** Define the complete Supabase Postgres schema — every table, column, enum, index, trigger, RPC, RLS policy, storage bucket, and pg_cron job for TranZfort V1. A junior developer should be able to run these migrations and have a fully functional backend.

---

## 1. Core Principles

- **Foreign Keys (FKs):** All relationships enforced at DB level. No orphaned records.
- **Row-Level Security (RLS):** ALL tables have RLS enabled. The Dart client NEVER bypasses.
- **Atomic Operations (RPCs):** Complex mutations (booking, approval) use Postgres `FOR UPDATE` row locking.
- **Edge Functions:** Admin-only operations use `service_role` key to bypass RLS.
- **updated_at trigger:** Every mutable table has an auto-trigger that sets `updated_at = NOW()` on UPDATE.

---

## 2. Global Enums

```sql
CREATE TYPE user_role AS ENUM ('supplier', 'trucker');
CREATE TYPE verification_status AS ENUM ('unverified', 'pending', 'verified', 'rejected');
CREATE TYPE super_trucker_status AS ENUM ('none', 'pending', 'approved', 'rejected');
CREATE TYPE truck_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE body_type AS ENUM ('open', 'container', 'trailer', 'tanker', 'refrigerated');
CREATE TYPE load_status AS ENUM ('active', 'pending_approval', 'booked', 'in_transit', 'completed', 'cancelled', 'expired');
CREATE TYPE super_status AS ENUM ('none', 'requested', 'processing', 'assigned', 'in_transit', 'pod_uploaded', 'completed');
CREATE TYPE price_type AS ENUM ('fixed', 'negotiable');
CREATE TYPE message_type AS ENUM ('text', 'voice', 'truck_card', 'location', 'document', 'map_card', 'system');
CREATE TYPE payout_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE admin_role AS ENUM ('super_admin', 'ops_admin', 'support_agent');
CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE trip_stage AS ENUM ('at_pickup', 'in_transit', 'delivered', 'pod_uploaded', 'completed');
```

### Enum Usage Rules
| Enum | Where Used | Notes |
|------|-----------|-------|
| `user_role` | `profiles.user_role_type` | Set during onboarding. Never changes. |
| `verification_status` | `profiles.verification_status` | Admin sets via verification queue. |
| `truck_status` | `trucks.status` | `pending` → admin verifies → `verified` or `rejected`. |
| `load_status` | `loads.status` | Core marketplace lifecycle (see §4). |
| `super_status` | `loads.super_status` | Super Load lifecycle (see §4). |
| `trip_stage` | `trips.stage` | Trip execution lifecycle (see §5). |
| `admin_role` | `admin_users.role` | RBAC for admin app (see 09_ADMIN). |

---

## 3. Core Tables

### 3.1 `profiles` — Unified User Record
Every authenticated user has exactly one profile, auto-created by trigger on `auth.users` INSERT.

```sql
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    mobile VARCHAR(15) UNIQUE,                       -- NULL for new Google users
    email VARCHAR(255) UNIQUE,                       -- NULL for Phone OTP users
    user_role_type user_role,                        -- NULL during onboarding
    avatar_url TEXT,
    
    verification_status verification_status DEFAULT 'unverified',
    verification_rejection_reason TEXT,
    verified_at TIMESTAMP,
    
    aadhaar_number VARCHAR(12),                      -- Stored for verification
    aadhaar_last4 VARCHAR(4),                        -- Display-safe (last 4 digits)
    aadhaar_front_photo_url TEXT,
    aadhaar_back_photo_url TEXT,
    pan_number VARCHAR(10),
    pan_photo_url TEXT,
    
    push_token TEXT,                                 -- FCM token for push notifications
    
    privacy_consent_at TIMESTAMP,
    privacy_consent_version VARCHAR(10),
    preferred_language VARCHAR(5) DEFAULT 'en',
    country_code VARCHAR(5) DEFAULT '+91',
    
    last_known_lat DOUBLE PRECISION,                 -- Bounded GPS update
    last_known_lng DOUBLE PRECISION,
    last_location_at TIMESTAMPTZ,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT,
    data_deletion_requested_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_profiles_role ON profiles(user_role_type);
CREATE INDEX idx_profiles_verification ON profiles(verification_status);
CREATE INDEX idx_profiles_mobile ON profiles(mobile);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_push_token ON profiles(push_token);
```

**Auto-Create Trigger:** On `auth.users` INSERT, a profile row is created:
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, mobile)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NULLIF(NEW.email, ''),
        NULLIF(NEW.phone, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 3.2 `suppliers` — Supplier Extension
Created when user selects `role = 'supplier'` during onboarding.

```sql
CREATE TABLE public.suppliers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_name VARCHAR(255),                       -- Nullable (some suppliers are individuals)
    
    business_licence_number VARCHAR(100),
    business_licence_doc_url TEXT,
    gst_number VARCHAR(15),
    gst_photo_url TEXT,
    
    total_loads_posted INTEGER DEFAULT 0,
    active_loads_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 3.3 `truckers` — Trucker Extension
Created when user selects `role = 'trucker'` during onboarding.

```sql
CREATE TABLE public.truckers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    dl_number VARCHAR(20),
    dl_front_photo_url TEXT,
    dl_back_photo_url TEXT,
    
    insurance_doc_url TEXT,
    permit_doc_url TEXT,
    
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_trips INTEGER DEFAULT 0,
    completed_trips INTEGER DEFAULT 0,
    super_trucker_status super_trucker_status DEFAULT 'none',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_truckers_rating ON truckers(rating DESC);
CREATE INDEX idx_truckers_super_status ON truckers(super_trucker_status);
```

### 3.4 `admin_users` — Admin Team
Separate from `profiles`. Admin accounts are created via Edge Function invite.

```sql
CREATE TABLE public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role admin_role NOT NULL,                        -- super_admin, ops_admin, support_agent
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_admin_users_role ON admin_users(role);
CREATE INDEX idx_admin_users_active ON admin_users(is_active);
```

---

## 4. Fleet Tables

### 4.1 `truck_models` — Master Catalog (50 Indian Vehicles)
Pre-seeded with 50 Indian commercial vehicles. Read-only for app.

```sql
CREATE TABLE public.truck_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    make VARCHAR(100) NOT NULL,                      -- Tata, Ashok Leyland, Eicher...
    model VARCHAR(100) NOT NULL,
    body_type body_type NOT NULL,
    axles INTEGER NOT NULL DEFAULT 2,
    gvw_kg INTEGER,                                  -- Gross Vehicle Weight
    payload_kg INTEGER,                              -- Max payload capacity
    length_ft DECIMAL(4,1),
    width_ft DECIMAL(4,1),
    height_ft DECIMAL(4,1),
    mileage_empty_kmpl DECIMAL(4,2),                 -- km/L empty
    mileage_loaded_kmpl DECIMAL(4,2),                -- km/L fully loaded
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(make, model)
);
```

### 4.2 `trucks` — User's Fleet
Each trucker can have multiple trucks. Trucks must be verified by admin before use.

```sql
CREATE TABLE public.trucks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.truckers(id) ON DELETE CASCADE,
    truck_model_id UUID REFERENCES public.truck_models(id),  -- Master catalog link
    
    truck_number VARCHAR(20) NOT NULL UNIQUE,         -- e.g., "MH 12 AB 1234"
    body_type body_type NOT NULL,
    tyres INTEGER NOT NULL CHECK (tyres >= 4 AND tyres <= 22),
    capacity_tonnes DECIMAL(5,2) NOT NULL,
    
    rc_photo_url TEXT,                                -- RC document photo
    
    status truck_status DEFAULT 'pending',            -- pending → verified/rejected
    rejection_reason TEXT,
    verified_by UUID REFERENCES public.admin_users(id),
    verified_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_trucks_owner ON trucks(owner_id);
CREATE INDEX idx_trucks_status ON trucks(status);
CREATE INDEX idx_trucks_number ON trucks(truck_number);
```

### 4.3 `diesel_prices` — State-wise Fuel Prices
Pre-seeded with 34 Indian states. Updated manually or via API.

```sql
CREATE TABLE public.diesel_prices (
    state VARCHAR(100) PRIMARY KEY,
    price_per_litre DECIMAL(6,2) NOT NULL,           -- e.g., 89.50
    updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## 5. Marketplace Tables

### 5.1 `loads` — The Core Entity
Handles both single loads and bulk via a **Parent/Child** model.
- **Parent Load:** `parent_load_id IS NULL`, holds requirement-level data and `trucks_needed`/`trucks_booked` counters.
- **Child Load:** `parent_load_id = {parent_id}`, created per trucker booking request.

```sql
CREATE TABLE public.loads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
    parent_load_id UUID REFERENCES public.loads(id) ON DELETE CASCADE, -- NULL for Parent loads, set for Child loads
    
    -- Route
    origin_city VARCHAR(255) NOT NULL,
    origin_state VARCHAR(100) NOT NULL,
    dest_city VARCHAR(255) NOT NULL,
    dest_state VARCHAR(100) NOT NULL,
    origin_lat DOUBLE PRECISION,                     -- For map display + cost calc
    origin_lng DOUBLE PRECISION,
    dest_lat DOUBLE PRECISION,
    dest_lng DOUBLE PRECISION,
    distance_km DECIMAL(8,2),                        -- OSRM or Haversine
    duration_hours DECIMAL(6,2),
    route_polyline TEXT,                              -- Encoded polyline for static map
    
    -- Cargo
    material VARCHAR(255) NOT NULL,
    weight_tonnes DECIMAL(5,2) NOT NULL,
    
    -- Truck Requirements
    required_truck_type body_type,
    required_tyres INTEGER[],                         -- Array of accepted tyre counts
    trucks_needed INTEGER DEFAULT 1,                  -- Bulk: > 1
    trucks_booked INTEGER DEFAULT 0,                  -- Incremented on booking
    
    -- Pricing
    price DECIMAL(10,2) NOT NULL,                     -- Total price (₹)
    price_type price_type DEFAULT 'negotiable',
    advance_percentage INTEGER,                       -- e.g., 80
    
    -- Schedule
    pickup_date DATE NOT NULL,
    
    -- Status
    status load_status DEFAULT 'active',
    is_super_load BOOLEAN DEFAULT FALSE,
    super_status super_status DEFAULT 'none',
    
    -- Assignment (set on booking/approval)
    assigned_trucker_id UUID REFERENCES public.truckers(id),
    assigned_truck_id UUID REFERENCES public.trucks(id),
    assigned_by UUID REFERENCES public.admin_users(id),  -- Super Load dispatch
    booking_truck_snapshot JSONB,                     -- Snapshot of truck details at booking time
    
    -- Documents
    pod_photo_url TEXT,
    lr_photo_url TEXT,
    
    -- Metrics
    views_count INTEGER DEFAULT 0,
    responses_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
    completed_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_loads_supplier ON loads(supplier_id);
CREATE INDEX idx_loads_status ON loads(status);
CREATE INDEX idx_loads_super ON loads(is_super_load);
CREATE INDEX idx_loads_origin ON loads(origin_city);
CREATE INDEX idx_loads_dest ON loads(dest_city);
CREATE INDEX idx_loads_pickup_date ON loads(pickup_date);
CREATE INDEX idx_loads_created ON loads(created_at DESC);
CREATE INDEX idx_loads_assigned_trucker ON loads(assigned_trucker_id);
```

### Load Status Lifecycle
```
Parent Load:
active ──→ booked (when trucks_booked >= trucks_needed)
  │
  ├──→ expired (pg_cron: 30d old OR pickup_date + 3d passed)
  └──→ cancelled (supplier deactivates)

Child Load:
pending_approval ──→ booked (supplier approves)
      │                 └──→ in_transit (trucker starts trip)
      │                      └──→ completed (POD confirmed)
      └──→ cancelled (supplier rejects / pre-transit cancel)
```

### Super Status Lifecycle
```
none ──→ requested (supplier taps "Make Super")
          ──→ processing (ops admin picks up)
              ──→ assigned (ops admin assigns trucker)
                  ──→ in_transit (trucker starts trip)
                      ──→ pod_uploaded (trucker uploads POD)
                          ──→ completed (ops admin confirms + marks payout)
```

### 5.2 `trips` — Trip Execution
Created when a load becomes `booked` (supplier approves booking).

```sql
CREATE TABLE public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    load_id UUID NOT NULL UNIQUE REFERENCES public.loads(id) ON DELETE CASCADE,
    trucker_id UUID NOT NULL REFERENCES public.truckers(id),
    truck_id UUID NOT NULL REFERENCES public.trucks(id),
    
    stage trip_stage DEFAULT 'at_pickup',
    
    lr_number TEXT,
    lr_photo_url TEXT,
    pod_photo_url TEXT,
    
    start_time TIMESTAMPTZ,                          -- When trucker taps "Start Trip"
    end_time TIMESTAMPTZ,                            -- When trip completes
    
    last_known_lat DOUBLE PRECISION,                 -- Bounded GPS for this trip
    last_known_lng DOUBLE PRECISION,
    last_location_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trips_load ON trips(load_id);
CREATE INDEX idx_trips_trucker ON trips(trucker_id);
CREATE INDEX idx_trips_stage ON trips(stage);
```

### Trip Stage Lifecycle
```
at_pickup ──→ in_transit (trucker taps "Start Trip")
               ──→ delivered (trucker taps "Mark Delivered")
                    ──→ pod_uploaded (trucker uploads POD)
                         ──→ completed (supplier confirms OR auto-complete 48h)
```

---

## 6. Communications Tables

### 6.1 `conversations` — Context-Grouped Chat
One conversation per (load, supplier, trucker) triple. UNIQUE constraint enforces this.

```sql
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    load_id UUID NOT NULL REFERENCES public.loads(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
    trucker_id UUID NOT NULL REFERENCES public.truckers(id) ON DELETE CASCADE,
    
    is_active BOOLEAN DEFAULT TRUE,
    last_message_at TIMESTAMP,
    last_message_text TEXT,                           -- Preview text for inbox
    
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(load_id, supplier_id, trucker_id)
);

CREATE INDEX idx_conversations_load ON conversations(load_id);
CREATE INDEX idx_conversations_supplier ON conversations(supplier_id);
CREATE INDEX idx_conversations_trucker ON conversations(trucker_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);
```

### 6.2 `messages`
```sql
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    message_type message_type NOT NULL,               -- text, voice, location, map_card, system, etc.
    text_content TEXT,
    payload JSONB,                                    -- Structured data (location coords, map card, etc.)
    
    voice_url TEXT,                                   -- Supabase Storage path for voice messages
    voice_duration_seconds INTEGER,
    
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_unread ON messages(is_read) WHERE is_read = FALSE;
```

**Auto-Update Trigger:** On new message INSERT, update conversation's `last_message_at` and `last_message_text`:
```sql
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET last_message_at = NEW.created_at,
        last_message_text = CASE
            WHEN NEW.message_type = 'text' THEN LEFT(NEW.text_content, 100)
            WHEN NEW.message_type = 'voice' THEN 'Voice message'
            WHEN NEW.message_type = 'map_card' THEN 'Route shared'
            WHEN NEW.message_type = 'location' THEN 'Location shared'
            ELSE 'New message'
        END
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 6.3 `notifications` — In-App Notifications
```sql
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,                        -- booking_new, booking_approved, verification_done, etc.
    data JSONB,                                       -- Deep link data: {load_id, trip_id, ticket_id}
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = FALSE;
```

---

## 7. Support & Ratings Tables

### 7.1 `support_tickets`
```sql
CREATE TABLE public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100),
    status ticket_status DEFAULT 'open',
    priority ticket_priority DEFAULT 'medium',
    assigned_to UUID REFERENCES public.admin_users(id),
    resolved_by UUID REFERENCES public.admin_users(id),
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

CREATE INDEX idx_tickets_user ON support_tickets(user_id);
CREATE INDEX idx_tickets_status ON support_tickets(status);
CREATE INDEX idx_tickets_assigned ON support_tickets(assigned_to);
CREATE INDEX idx_tickets_created ON support_tickets(created_at DESC);
```

### 7.2 `support_ticket_messages` — Thread replies
```sql
CREATE TABLE public.support_ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id),
    sender_role TEXT NOT NULL CHECK (sender_role IN ('user', 'admin')),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stm_ticket ON support_ticket_messages(ticket_id, created_at);
```

### 7.3 `ratings` — Post-Trip Reviews
```sql
CREATE TABLE public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    load_id UUID NOT NULL REFERENCES public.loads(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES auth.users(id),
    reviewee_id UUID NOT NULL REFERENCES auth.users(id),
    reviewer_role TEXT NOT NULL CHECK (reviewer_role IN ('supplier', 'trucker')),
    score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(load_id, reviewer_id)                      -- One rating per reviewer per load
);

CREATE INDEX idx_ratings_reviewee ON ratings(reviewee_id);
CREATE INDEX idx_ratings_load ON ratings(load_id);
```

**Auto-Update Trigger:** After supplier rates trucker, update `truckers.rating` aggregate:
```sql
CREATE OR REPLACE FUNCTION public.update_trucker_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.truckers
    SET rating = (
        SELECT COALESCE(AVG(score), 0)
        FROM public.ratings
        WHERE reviewee_id = NEW.reviewee_id
          AND reviewer_role = 'supplier'
    )
    WHERE id = NEW.reviewee_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_trucker_rating
    AFTER INSERT ON public.ratings
    FOR EACH ROW WHEN (NEW.reviewer_role = 'supplier')
    EXECUTE FUNCTION public.update_trucker_rating();
```

---

## 8. Other Tables

### 8.1 `payout_profiles` — Bank Details for Super Load Payouts
```sql
CREATE TABLE public.payout_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_holder_name VARCHAR(255) NOT NULL,
    account_number_last4 VARCHAR(4) NOT NULL,         -- Only last 4 digits stored
    ifsc_code VARCHAR(11) NOT NULL,
    bank_name VARCHAR(255),
    status payout_status DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by UUID REFERENCES public.admin_users(id),
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 8.2 `audit_logs` — Admin Action Trail
```sql
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.admin_users(id),
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_admin ON audit_logs(admin_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
```

### 8.3 `user_consents` — Privacy/DPDP Audit Trail
```sql
CREATE TABLE public.user_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    consent_type VARCHAR(50) NOT NULL,
    consent_version VARCHAR(10) NOT NULL,
    consented_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);
```

### 8.4 `feature_flags`
```sql
CREATE TABLE public.feature_flags (
    name TEXT PRIMARY KEY,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Seed: ('super_loads', TRUE), ('advanced_search', FALSE)
```

---

## 9. Atomic RPCs (Concurrency Guards)
### 9.1 `book_load(p_parent_load_id UUID, p_trucker_id UUID, p_truck_id UUID)`
**Problem:** Two truckers can book the same slot simultaneously.
**Solution:** Lock Parent row (`FOR UPDATE`), create Child row atomically, increment Parent counters.

```sql
CREATE OR REPLACE FUNCTION public.book_load(
    p_parent_load_id UUID,
    p_trucker_id UUID,
    p_truck_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_parent RECORD;
    v_truck RECORD;
    v_child_id UUID;
BEGIN
    -- 1) Lock Parent Load
    SELECT * INTO v_parent
    FROM public.loads
    WHERE id = p_parent_load_id
      AND parent_load_id IS NULL
    FOR UPDATE;

    IF v_parent IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid parent load');
    END IF;

    IF v_parent.status <> 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load no longer active');
    END IF;

    IF v_parent.trucks_booked >= v_parent.trucks_needed THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load fully booked');
    END IF;

    -- 2) Verify truck ownership + status
    SELECT * INTO v_truck
    FROM public.trucks
    WHERE id = p_truck_id
      AND owner_id = p_trucker_id
      AND status = 'verified';

    IF v_truck IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Truck not found or not verified');
    END IF;

    -- 3) Create Child Load (pending supplier approval)
    INSERT INTO public.loads (
        supplier_id,
        parent_load_id,
        origin_city, origin_state, dest_city, dest_state,
        origin_lat, origin_lng, dest_lat, dest_lng,
        distance_km, duration_hours, route_polyline,
        material, weight_tonnes,
        required_truck_type, required_tyres,
        price, price_type, advance_percentage,
        pickup_date,
        status,
        trucks_needed, trucks_booked,
        is_super_load, super_status,
        assigned_trucker_id, assigned_truck_id,
        booking_truck_snapshot
    ) VALUES (
        v_parent.supplier_id,
        v_parent.id,
        v_parent.origin_city, v_parent.origin_state, v_parent.dest_city, v_parent.dest_state,
        v_parent.origin_lat, v_parent.origin_lng, v_parent.dest_lat, v_parent.dest_lng,
        v_parent.distance_km, v_parent.duration_hours, v_parent.route_polyline,
        v_parent.material, v_parent.weight_tonnes,
        v_parent.required_truck_type, v_parent.required_tyres,
        v_parent.price, v_parent.price_type, v_parent.advance_percentage,
        v_parent.pickup_date,
        'pending_approval',
        1, 0,
        v_parent.is_super_load, v_parent.super_status,
        p_trucker_id, p_truck_id,
        jsonb_build_object(
            'truck_number', v_truck.truck_number,
            'body_type', v_truck.body_type::text,
            'tyres', v_truck.tyres,
            'capacity_tonnes', v_truck.capacity_tonnes,
            'rc_photo_url', v_truck.rc_photo_url
        )
    ) RETURNING id INTO v_child_id;

    -- 4) Increment Parent counters
    UPDATE public.loads
    SET trucks_booked = trucks_booked + 1,
        status = CASE
            WHEN trucks_booked + 1 >= trucks_needed THEN 'booked'::load_status
            ELSE status
        END,
        updated_at = NOW()
    WHERE id = p_parent_load_id;

    RETURN jsonb_build_object('success', true, 'child_load_id', v_child_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 9.2 `approve_booking(p_child_load_id UUID)`
**Problem:** Supplier approval must atomically advance booking and create trip.

```sql
CREATE OR REPLACE FUNCTION public.approve_booking(
    p_child_load_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_child RECORD;
BEGIN
    SELECT * INTO v_child
    FROM public.loads
    WHERE id = p_child_load_id
      AND parent_load_id IS NOT NULL
    FOR UPDATE;

    IF v_child IS NULL OR v_child.status <> 'pending_approval' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load not in pending approval state');
    END IF;

    INSERT INTO public.trips (load_id, trucker_id, truck_id)
    VALUES (p_child_load_id, v_child.assigned_trucker_id, v_child.assigned_truck_id);

    UPDATE public.loads
    SET status = 'booked', updated_at = NOW()
    WHERE id = p_child_load_id;

    RETURN jsonb_build_object('success', true, 'child_load_id', p_child_load_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 9.3 `reject_booking(p_child_load_id UUID)`
```sql
CREATE OR REPLACE FUNCTION public.reject_booking(
    p_child_load_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_child RECORD;
BEGIN
    SELECT * INTO v_child
    FROM public.loads
    WHERE id = p_child_load_id
      AND parent_load_id IS NOT NULL
    FOR UPDATE;

    IF v_child IS NULL OR v_child.status <> 'pending_approval' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid child load');
    END IF;

    -- 1) Cancel Child Load
    UPDATE public.loads
    SET status = 'cancelled', updated_at = NOW()
    WHERE id = p_child_load_id;

    -- 2) Decrement Parent Load counters
    UPDATE public.loads
    SET trucks_booked = GREATEST(trucks_booked - 1, 0),
        status = 'active',
        updated_at = NOW()
    WHERE id = v_child.parent_load_id;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 9.4 `admin_force_assign_super_load(p_parent_load_id UUID, p_trucker_id UUID, p_truck_id UUID, p_admin_id UUID)`
**Problem:** Admin needs to dispatch a trucker to a Super Load without waiting for them to request it.

```sql
CREATE OR REPLACE FUNCTION public.admin_force_assign_super_load(
    p_parent_load_id UUID,
    p_trucker_id UUID,
    p_truck_id UUID,
    p_admin_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_parent RECORD;
    v_truck RECORD;
    v_child_id UUID;
BEGIN
    SELECT * INTO v_parent FROM public.loads WHERE id = p_parent_load_id FOR UPDATE;
    
    IF v_parent IS NULL OR v_parent.parent_load_id IS NOT NULL OR v_parent.is_super_load = FALSE THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid parent super load');
    END IF;
    
    IF v_parent.status != 'active' OR v_parent.trucks_booked >= v_parent.trucks_needed THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load not active or fully booked');
    END IF;

    SELECT * INTO v_truck FROM public.trucks
    WHERE id = p_truck_id AND owner_id = p_trucker_id AND status = 'verified';

    IF v_truck IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Truck not verified');
    END IF;

    -- 1. Create Child Load already in 'booked' state
    INSERT INTO public.loads (
        supplier_id, parent_load_id,
        origin_city, origin_state, dest_city, dest_state,
        origin_lat, origin_lng, dest_lat, dest_lng, distance_km, duration_hours, route_polyline,
        material, weight_tonnes, price, price_type, advance_percentage, pickup_date,
        status, is_super_load, super_status, trucks_needed, trucks_booked,
        assigned_trucker_id, assigned_truck_id, assigned_by, booking_truck_snapshot
    ) VALUES (
        v_parent.supplier_id, v_parent.id,
        v_parent.origin_city, v_parent.origin_state, v_parent.dest_city, v_parent.dest_state,
        v_parent.origin_lat, v_parent.origin_lng, v_parent.dest_lat, v_parent.dest_lng, v_parent.distance_km, v_parent.duration_hours, v_parent.route_polyline,
        v_parent.material, v_parent.weight_tonnes, v_parent.price, v_parent.price_type, v_parent.advance_percentage, v_parent.pickup_date,
        'booked', true, 'assigned', 1, 1,
        p_trucker_id, p_truck_id, p_admin_id,
        jsonb_build_object('truck_number', v_truck.truck_number, 'body_type', v_truck.body_type::text)
    ) RETURNING id INTO v_child_id;

    -- 2. Create Trip
    INSERT INTO public.trips (load_id, trucker_id, truck_id, stage)
    VALUES (v_child_id, p_trucker_id, p_truck_id, 'at_pickup');

    -- 3. Update Parent Load
    UPDATE public.loads SET
        trucks_booked = trucks_booked + 1,
        status = CASE WHEN trucks_booked + 1 >= trucks_needed THEN 'booked'::load_status ELSE status END,
        super_status = 'assigned',
        updated_at = NOW()
    WHERE id = p_parent_load_id;

    RETURN jsonb_build_object('success', true, 'child_load_id', v_child_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 9.5 `start_trip(p_trip_id UUID, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION)`
```sql
CREATE OR REPLACE FUNCTION public.start_trip(
    p_trip_id UUID, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION
) RETURNS JSONB AS $$
DECLARE v_trip RECORD;
BEGIN
    SELECT * INTO v_trip FROM public.trips WHERE id = p_trip_id FOR UPDATE;
    IF v_trip.stage != 'at_pickup' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Trip not at pickup stage');
    END IF;
    
    UPDATE public.trips SET
        stage = 'in_transit', start_time = NOW(),
        last_known_lat = p_lat, last_known_lng = p_lng, last_location_at = NOW()
    WHERE id = p_trip_id;
    
    UPDATE public.loads SET status = 'in_transit' WHERE id = v_trip.load_id;
    
    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 10. Row-Level Security (RLS) Policies

### RLS Helper Functions
```sql
-- Check if current user is an active admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE auth_user_id = auth.uid() AND is_active = TRUE
    );
$$ LANGUAGE sql SECURITY DEFINER;

-- Check if current user is active (not banned)
CREATE OR REPLACE FUNCTION public.is_user_active()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_banned = FALSE
    );
$$ LANGUAGE sql SECURITY DEFINER;
```

### Policy Summary Table
| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | Own row OR admin | Own row (via trigger) | Own row | Never |
| `suppliers` | Own row OR admin | Own row | Own row | Never |
| `truckers` | Own row OR admin | Own row | Own row | Never |
| `trucks` | Owner OR admin | Owner | Owner | Owner |
| `loads` | Active loads (all authenticated) OR own loads (supplier) OR assigned loads (trucker) OR admin | Supplier only | Supplier (own) OR via RPC | Never |
| `trips` | Trucker or supplier party OR admin | Via RPC only | Via RPC only | Never |
| `conversations` | Participant only | Participant | Participant | Never |
| `messages` | Conversation participant | Conversation participant | Sender only (mark read) | Never |
| `notifications` | Own only | System/RPC only | Own (mark read) | Never |
| `ratings` | Reviewer or reviewee OR admin | Own (reviewer_id = auth.uid()) | Never | Never |
| `support_tickets` | Own OR assigned admin OR admin | Own | Assigned admin | Never |
| `audit_logs` | Admin only | Admin only | Never | Never |
| `admin_users` | Admin only | Super admin only | Super admin only | Never |

---

## 11. Supabase Storage Buckets

| Bucket | Public? | Size Limit | Allowed MIME Types | Purpose |
|--------|---------|------------|-------------------|---------|
| `profile-photos` | Yes | 2MB | image/jpeg, image/png | User avatars |
| `verification-docs` | No | 5MB | image/jpeg, image/png, application/pdf | Aadhaar, PAN, DL, Business Licence |
| `truck-photos` | No | 5MB | image/jpeg, image/png | RC photos |
| `load-documents` | No | 5MB | image/jpeg, image/png | LR, POD photos |
| `voice-messages` | No | 5MB | audio/mp4, audio/aac, audio/m4a, audio/mpeg | Chat voice messages |

### Storage Path Convention
```
profile-photos/{user_id}/avatar.jpg
verification-docs/{user_id}/aadhaar_front.jpg
verification-docs/{user_id}/aadhaar_back.jpg
verification-docs/{user_id}/pan.jpg
verification-docs/{user_id}/dl_front.jpg
verification-docs/{user_id}/dl_back.jpg
verification-docs/{user_id}/business_licence.jpg
truck-photos/{truck_id}/rc.jpg
load-documents/{load_id}/lr.jpg
load-documents/{load_id}/pod.jpg
voice-messages/{conversation_id}/{message_id}.m4a
```

### Image Compression Rule
All images uploaded via the app must be compressed to **1200x1200 max resolution at 85% quality** before upload.

---

## 12. pg_cron Scheduled Jobs

| Job | Schedule | Function | Purpose |
|-----|----------|----------|---------|
| `expire-stale-loads` | Daily 2 AM IST | `run_load_expiry()` | Expire active loads > 30 days old OR pickup_date + 3 days passed |
| `auto-complete-delivered` | Every 6 hours | `auto_complete_delivered_trips()` | Complete `pod_uploaded` trips > 48h without supplier confirmation |

```sql
-- Auto-complete delivered trips after 48h
CREATE OR REPLACE FUNCTION public.auto_complete_delivered_trips()
RETURNS INTEGER AS $$
DECLARE completed_count INTEGER;
BEGIN
    UPDATE public.trips SET stage = 'completed', end_time = NOW()
    WHERE stage = 'pod_uploaded'
      AND updated_at < NOW() - INTERVAL '48 hours';
    GET DIAGNOSTICS completed_count = ROW_COUNT;
    
    -- Also update corresponding loads
    UPDATE public.loads SET status = 'completed', completed_at = NOW()
    WHERE id IN (
        SELECT load_id FROM public.trips
        WHERE stage = 'completed' AND end_time = NOW()
    );
    
    RETURN completed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 13. Edge Functions

| Function | Trigger | What It Does |
|----------|---------|-------------|
| `send-push-notification` | DB trigger / app call | Sends FCM push to user's `push_token` |
| `create-super-load` | Admin Super Ops Console | Creates/processes Super Load requests |
| `admin-promote-invite` | Admin Management screen | Creates new admin user + sends invite email |
| `admin-load-ops` | Admin "Post on Behalf" | Posts load for supplier via admin |

### Push Notification Trigger Points
| Event | Recipient | Notification Title | Data Payload |
|-------|-----------|-------------------|-------------|
| Trucker books load | Supplier | "New Booking Request" | `{load_id}` |
| Supplier approves | Trucker | "Booking Approved!" | `{load_id, trip_id}` |
| Supplier rejects | Trucker | "Booking Rejected" | `{load_id}` |
| Admin verifies user | User | "Account Verified" | `{}` |
| Admin rejects verification | User | "Verification Failed" | `{reason}` |
| Trucker uploads POD | Supplier | "Proof of Delivery Uploaded" | `{load_id}` |
| Supplier confirms delivery | Trucker | "Delivery Confirmed" | `{load_id}` |
| Super Load status change | Supplier | "Super Load Update" | `{load_id, super_status}` |
| Support ticket reply | User | "Support Reply" | `{ticket_id}` |
