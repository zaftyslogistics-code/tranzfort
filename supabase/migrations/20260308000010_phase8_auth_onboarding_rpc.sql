-- ============================================================================
-- TranZfort Rebuild — Phase 8: Auth & Onboarding RPC
-- Purpose: create role extension row for the signed-in user during onboarding
-- ============================================================================

CREATE OR REPLACE FUNCTION ensure_role_extension(p_role user_role)
RETURNS VOID AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_role = 'supplier' THEN
    INSERT INTO suppliers (id)
    VALUES (auth.uid())
    ON CONFLICT (id) DO NOTHING;
    RETURN;
  END IF;

  IF p_role = 'trucker' THEN
    INSERT INTO truckers (id)
    VALUES (auth.uid())
    ON CONFLICT (id) DO NOTHING;
    RETURN;
  END IF;

  RAISE EXCEPTION 'Unsupported role extension request';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
