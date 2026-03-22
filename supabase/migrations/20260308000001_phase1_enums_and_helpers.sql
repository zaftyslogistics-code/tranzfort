-- ============================================================================
-- TranZfort Rebuild — Phase 1: Core Enums & Helper Functions
-- Source of truth: docs/33-schema-enum-and-state-transition-catalog.md
-- EVERY enum value here is LOCKED. Do not add values without updating doc 33.
-- ============================================================================

-- ─── User Roles ───
CREATE TYPE user_role AS ENUM ('supplier', 'trucker');
CREATE TYPE admin_role AS ENUM ('ops_admin', 'super_admin');

-- ─── Verification ───
CREATE TYPE verification_status AS ENUM ('unverified', 'pending', 'verified', 'rejected');

-- ─── Trucks ───
CREATE TYPE truck_status AS ENUM ('pending', 'verified', 'rejected', 'edited_pending_reapproval', 'archived');

-- ─── Loads ───
CREATE TYPE load_status AS ENUM (
  'draft', 'active', 'assigned_partial', 'assigned_full',
  'in_transit', 'completed', 'filled_outside_app',
  'cancelled', 'expired', 'deactivated'
);

CREATE TYPE super_load_status AS ENUM (
  'none', 'request_submitted', 'under_review',
  'approved_payment_pending', 'active', 'rejected', 'expired_or_closed'
);

-- ─── Booking ───
CREATE TYPE booking_status AS ENUM ('submitted', 'approved', 'rejected', 'withdrawn', 'superseded');

-- ─── Trips ───
CREATE TYPE trip_stage AS ENUM (
  'assigned', 'pickup_pending', 'picked_up', 'in_transit',
  'delivered', 'proof_submitted', 'completed', 'disputed', 'cancelled'
);

-- ─── Support ───
CREATE TYPE support_ticket_status AS ENUM ('open', 'in_progress', 'waiting_for_user', 'resolved', 'closed');
CREATE TYPE support_ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');

-- ─── Operational Cases ───
CREATE TYPE operational_case_status AS ENUM (
  'queued', 'claimed', 'in_review', 'waiting_for_user',
  'waiting_for_external', 'escalated', 'resolved', 'rejected', 'closed'
);

-- ─── Notifications ───
CREATE TYPE notification_type AS ENUM (
  'verification_update', 'booking_update', 'trip_update', 'proof_update',
  'super_load_update', 'message_received', 'support_update',
  'dispute_update', 'account_update', 'system_notice', 'load_expiry_warning'
);
CREATE TYPE notification_priority AS ENUM ('low', 'medium', 'high');

-- ─── Messages ───
CREATE TYPE message_type AS ENUM ('text', 'voice', 'location', 'document', 'map_card', 'truck_card', 'system');

-- ─── Trust & Safety ───
CREATE TYPE trust_safety_status AS ENUM ('normal', 'warned', 'restricted', 'suspended', 'banned');

-- ─── Account Deletion ───
CREATE TYPE account_deletion_status AS ENUM (
  'active', 'deletion_requested', 'blocked_by_dependency',
  'deactivated_pending_cleanup', 'permanently_deleted'
);

-- ─── Verification Cases ───
CREATE TYPE verification_case_status AS ENUM (
  'submitted', 'queued', 'in_review', 'waiting_for_resubmission',
  'approved', 'rejected', 'escalated', 'closed'
);

CREATE TYPE verification_event_type AS ENUM (
  'submitted', 'claimed', 'reviewed', 'approved', 'rejected',
  'sent_back', 'escalated', 'resubmitted', 'overridden'
);

-- ─── Audit ───
CREATE TYPE audit_action_type AS ENUM (
  'user_verification_approved', 'user_verification_rejected', 'user_verification_escalated',
  'truck_verification_approved', 'truck_verification_rejected',
  'user_banned', 'user_unbanned', 'user_suspended', 'user_restricted',
  'admin_created', 'admin_deactivated', 'admin_role_changed',
  'load_deactivated_by_admin', 'trip_cancelled_by_admin',
  'super_load_approved', 'super_load_rejected',
  'case_escalated', 'case_resolved', 'deletion_request_processed', 'override_action'
);

-- ─── Dispute Categories ───
CREATE TYPE dispute_category AS ENUM (
  'loaded_quantity_mismatch', 'unloaded_quantity_mismatch', 'document_mismatch',
  'non_payment', 'fake_payout_proof', 'delay_or_no_show',
  'damage_or_shortage', 'abusive_behavior', 'spam_or_scam', 'other'
);

-- ─── Price Type ───
CREATE TYPE price_type AS ENUM ('fixed', 'negotiable');

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Auto-update updated_at timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper: check if current user is an admin (for RLS policies)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users
    WHERE auth_user_id = auth.uid()
      AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: get current admin role
CREATE OR REPLACE FUNCTION get_admin_role()
RETURNS admin_role AS $$
DECLARE
  _role admin_role;
BEGIN
  SELECT role INTO _role FROM admin_users
  WHERE auth_user_id = auth.uid() AND is_active = TRUE;
  RETURN _role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
