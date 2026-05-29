-- P3.1.3 — RPC to record user consent
-- Replaces direct table INSERT in AuthProfileRepository.recordTermsAcceptance()

CREATE OR REPLACE FUNCTION record_user_consent(
  p_consent_type TEXT DEFAULT 'terms_of_service',
  p_consent_version TEXT DEFAULT 'v1',
  p_source_context TEXT DEFAULT 'onboarding_profile'
)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  INSERT INTO user_consents (
    profile_id,
    consent_type,
    consent_version,
    source_context
  ) VALUES (
    v_user_id,
    p_consent_type,
    p_consent_version,
    p_source_context
  )
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION record_user_consent IS
  'Records a user consent entry with idempotent ON CONFLICT DO NOTHING. Replaces direct table INSERT in Flutter backend.';
