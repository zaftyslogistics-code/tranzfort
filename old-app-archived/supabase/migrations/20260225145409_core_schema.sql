-- 1. Global Enums
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

-- 2. Core Tables

-- 2.1 profiles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    mobile VARCHAR(15) UNIQUE,
    email VARCHAR(255) UNIQUE,
    user_role_type user_role,
    avatar_url TEXT,
    
    verification_status verification_status DEFAULT 'unverified',
    verification_rejection_reason TEXT,
    verified_at TIMESTAMP,
    
    aadhaar_number VARCHAR(12),
    aadhaar_last4 VARCHAR(4),
    aadhaar_front_photo_url TEXT,
    aadhaar_back_photo_url TEXT,
    pan_number VARCHAR(10),
    pan_photo_url TEXT,
    
    push_token TEXT,
    
    privacy_consent_at TIMESTAMP,
    privacy_consent_version VARCHAR(10),
    preferred_language VARCHAR(5) DEFAULT 'en',
    country_code VARCHAR(5) DEFAULT '+91',
    
    last_known_lat DOUBLE PRECISION,
    last_known_lng DOUBLE PRECISION,
    last_location_at TIMESTAMPTZ,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT,
    data_deletion_requested_at TIMESTAMP
);

CREATE INDEX idx_profiles_role ON profiles(user_role_type);
CREATE INDEX idx_profiles_verification ON profiles(verification_status);
CREATE INDEX idx_profiles_mobile ON profiles(mobile);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_push_token ON profiles(push_token);

-- Auto-Create Trigger for profiles
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

-- 2.2 suppliers
CREATE TABLE public.suppliers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_name VARCHAR(255),
    
    business_licence_number VARCHAR(100),
    business_licence_doc_url TEXT,
    gst_number VARCHAR(15),
    gst_photo_url TEXT,
    
    total_loads_posted INTEGER DEFAULT 0,
    active_loads_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2.3 truckers
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

-- 2.4 admin_users
CREATE TABLE public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role admin_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_admin_users_role ON admin_users(role);
CREATE INDEX idx_admin_users_active ON admin_users(is_active);

-- 3. Fleet Tables

-- 3.1 truck_models
CREATE TABLE public.truck_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    body_type body_type NOT NULL,
    axles INTEGER NOT NULL DEFAULT 2,
    gvw_kg INTEGER,
    payload_kg INTEGER,
    length_ft DECIMAL(4,1),
    width_ft DECIMAL(4,1),
    height_ft DECIMAL(4,1),
    mileage_empty_kmpl DECIMAL(4,2),
    mileage_loaded_kmpl DECIMAL(4,2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(make, model)
);

-- 3.2 trucks
CREATE TABLE public.trucks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.truckers(id) ON DELETE CASCADE,
    truck_model_id UUID REFERENCES public.truck_models(id),
    
    truck_number VARCHAR(20) NOT NULL UNIQUE,
    body_type body_type NOT NULL,
    tyres INTEGER NOT NULL CHECK (tyres >= 4 AND tyres <= 22),
    capacity_tonnes DECIMAL(5,2) NOT NULL,
    
    rc_photo_url TEXT,
    
    status truck_status DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by UUID REFERENCES public.admin_users(id),
    verified_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_trucks_owner ON trucks(owner_id);
CREATE INDEX idx_trucks_status ON trucks(status);
CREATE INDEX idx_trucks_number ON trucks(truck_number);

-- 3.3 diesel_prices
CREATE TABLE public.diesel_prices (
    state VARCHAR(100) PRIMARY KEY,
    price_per_litre DECIMAL(6,2) NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Marketplace Tables

-- 4.1 loads
CREATE TABLE public.loads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
    parent_load_id UUID REFERENCES public.loads(id) ON DELETE CASCADE,
    
    origin_city VARCHAR(255) NOT NULL,
    origin_state VARCHAR(100) NOT NULL,
    dest_city VARCHAR(255) NOT NULL,
    dest_state VARCHAR(100) NOT NULL,
    origin_lat DOUBLE PRECISION,
    origin_lng DOUBLE PRECISION,
    dest_lat DOUBLE PRECISION,
    dest_lng DOUBLE PRECISION,
    distance_km DECIMAL(8,2),
    duration_hours DECIMAL(6,2),
    route_polyline TEXT,
    
    material VARCHAR(255) NOT NULL,
    weight_tonnes DECIMAL(5,2) NOT NULL,
    
    required_truck_type body_type,
    required_tyres INTEGER[],
    trucks_needed INTEGER DEFAULT 1,
    trucks_booked INTEGER DEFAULT 0,
    
    price DECIMAL(10,2) NOT NULL,
    price_type price_type DEFAULT 'negotiable',
    advance_percentage INTEGER,
    
    pickup_date DATE NOT NULL,
    
    status load_status DEFAULT 'active',
    is_super_load BOOLEAN DEFAULT FALSE,
    super_status super_status DEFAULT 'none',
    
    assigned_trucker_id UUID REFERENCES public.truckers(id),
    assigned_truck_id UUID REFERENCES public.trucks(id),
    assigned_by UUID REFERENCES public.admin_users(id),
    booking_truck_snapshot JSONB,
    
    pod_photo_url TEXT,
    lr_photo_url TEXT,
    
    views_count INTEGER DEFAULT 0,
    responses_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
    completed_at TIMESTAMP
);

CREATE INDEX idx_loads_supplier ON loads(supplier_id);
CREATE INDEX idx_loads_status ON loads(status);
CREATE INDEX idx_loads_super ON loads(is_super_load);
CREATE INDEX idx_loads_origin ON loads(origin_city);
CREATE INDEX idx_loads_dest ON loads(dest_city);
CREATE INDEX idx_loads_pickup_date ON loads(pickup_date);
CREATE INDEX idx_loads_created ON loads(created_at DESC);
CREATE INDEX idx_loads_assigned_trucker ON loads(assigned_trucker_id);

-- 4.2 trips
CREATE TABLE public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    load_id UUID NOT NULL UNIQUE REFERENCES public.loads(id) ON DELETE CASCADE,
    trucker_id UUID NOT NULL REFERENCES public.truckers(id),
    truck_id UUID NOT NULL REFERENCES public.trucks(id),
    
    stage trip_stage DEFAULT 'at_pickup',
    
    lr_number TEXT,
    lr_photo_url TEXT,
    pod_photo_url TEXT,
    
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    
    last_known_lat DOUBLE PRECISION,
    last_known_lng DOUBLE PRECISION,
    last_location_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trips_load ON trips(load_id);
CREATE INDEX idx_trips_trucker ON trips(trucker_id);
CREATE INDEX idx_trips_stage ON trips(stage);

-- 5. Communications Tables

-- 5.1 conversations
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    load_id UUID NOT NULL REFERENCES public.loads(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
    trucker_id UUID NOT NULL REFERENCES public.truckers(id) ON DELETE CASCADE,
    
    is_active BOOLEAN DEFAULT TRUE,
    last_message_at TIMESTAMP,
    last_message_text TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(load_id, supplier_id, trucker_id)
);

CREATE INDEX idx_conversations_load ON conversations(load_id);
CREATE INDEX idx_conversations_supplier ON conversations(supplier_id);
CREATE INDEX idx_conversations_trucker ON conversations(trucker_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);

-- 5.2 messages
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    message_type message_type NOT NULL,
    text_content TEXT,
    payload JSONB,
    
    voice_url TEXT,
    voice_duration_seconds INTEGER,
    
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_unread ON messages(is_read) WHERE is_read = FALSE;

-- Auto-Update Trigger for conversations
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

CREATE TRIGGER trg_update_conversation_timestamp
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();

-- 5.3 notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = FALSE;

-- 6. Support & Ratings Tables

-- 6.1 support_tickets
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

-- 6.2 support_ticket_messages
CREATE TABLE public.support_ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id),
    sender_role TEXT NOT NULL CHECK (sender_role IN ('user', 'admin')),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stm_ticket ON support_ticket_messages(ticket_id, created_at);

-- 6.3 ratings
CREATE TABLE public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    load_id UUID NOT NULL REFERENCES public.loads(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES auth.users(id),
    reviewee_id UUID NOT NULL REFERENCES auth.users(id),
    reviewer_role TEXT NOT NULL CHECK (reviewer_role IN ('supplier', 'trucker')),
    score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(load_id, reviewer_id)
);

CREATE INDEX idx_ratings_reviewee ON ratings(reviewee_id);
CREATE INDEX idx_ratings_load ON ratings(load_id);

-- Auto-Update Trigger for trucker rating
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

-- 7. Other Tables

-- 7.1 payout_profiles
CREATE TABLE public.payout_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    account_holder_name VARCHAR(255) NOT NULL,
    account_number_last4 VARCHAR(4) NOT NULL,
    ifsc_code VARCHAR(11) NOT NULL,
    bank_name VARCHAR(255),
    status payout_status DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by UUID REFERENCES public.admin_users(id),
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 7.2 audit_logs
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

-- 7.3 user_consents
CREATE TABLE public.user_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    consent_type VARCHAR(50) NOT NULL,
    consent_version VARCHAR(10) NOT NULL,
    consented_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- 7.4 feature_flags
CREATE TABLE public.feature_flags (
    name TEXT PRIMARY KEY,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
