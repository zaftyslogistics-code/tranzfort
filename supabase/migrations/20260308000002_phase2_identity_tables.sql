-- ============================================================================
-- TranZfort Rebuild — Phase 2: Identity Tables
-- Source of truth: docs/20-schema-tables-identity-core.md
-- docs/21-schema-tables-identity-supporting.md
-- ============================================================================

-- ─── profiles ───
-- Canonical auth-linked identity anchor for all end users
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  mobile TEXT UNIQUE,
  email TEXT UNIQUE,
  user_role_type user_role,
  avatar_url TEXT,
  preferred_language TEXT NOT NULL DEFAULT 'en',
  verification_status verification_status NOT NULL DEFAULT 'unverified',
  verification_rejection_reason TEXT,
  trust_safety_status trust_safety_status NOT NULL DEFAULT 'normal',
  is_banned BOOLEAN NOT NULL DEFAULT FALSE,
  ban_reason TEXT,
  push_token TEXT,
  last_login_at TIMESTAMPTZ,
  data_deletion_requested_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_user_role_type ON profiles(user_role_type);
CREATE INDEX idx_profiles_verification_status ON profiles(verification_status);
CREATE INDEX idx_profiles_is_banned ON profiles(is_banned);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── suppliers ───
-- Supplier-specific extension of profiles
CREATE TABLE suppliers (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  company_name TEXT,
  business_licence_number TEXT,
  gst_number TEXT,
  total_loads_posted INTEGER NOT NULL DEFAULT 0,
  active_loads_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── truckers ───
-- Trucker-specific extension of profiles
CREATE TABLE truckers (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  dl_number TEXT,
  rating NUMERIC(3,2) NOT NULL DEFAULT 0,
  total_trips INTEGER NOT NULL DEFAULT 0,
  completed_trips INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_truckers_updated_at
  BEFORE UPDATE ON truckers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── admin_users ───
-- Admin identity and authority anchor (separate from end-user roles)
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role admin_role NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_admin_users_role ON admin_users(role);
CREATE INDEX idx_admin_users_is_active ON admin_users(is_active);

CREATE TRIGGER trg_admin_users_updated_at
  BEFORE UPDATE ON admin_users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── user_consents ───
-- Append-only consent acceptance evidence
CREATE TABLE user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL,
  consent_version TEXT NOT NULL,
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  source_context TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_consents_profile_id ON user_consents(profile_id);
CREATE INDEX idx_user_consents_profile_type ON user_consents(profile_id, consent_type);

-- ─── Profile creation trigger ───
-- Auto-create profiles row when new auth user is created
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email, mobile)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    NEW.email,
    NEW.phone
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
