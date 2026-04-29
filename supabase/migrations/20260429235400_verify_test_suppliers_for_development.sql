-- Verify test suppliers for development/testing
-- This migration updates test supplier accounts to have verification_status = 'verified'
-- so they can post loads that appear in the marketplace during development
-- Legitimate data seeding for development environment

UPDATE profiles
SET verification_status = 'verified',
    verification_rejection_reason = NULL,
    verification_feedback_json = NULL,
    updated_at = NOW()
WHERE user_role_type = 'supplier'
  AND verification_status = 'unverified'
  AND (email LIKE '%@test.com' OR email LIKE '%@example.com' OR full_name LIKE 'Test%');
