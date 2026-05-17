-- P3.1.1 — RPC to fetch current user's profile
-- Replaces direct table read in AuthProfileRepository.getCurrentProfile()

CREATE OR REPLACE FUNCTION get_current_user_profile()
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID;
  v_result JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(p)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      full_name,
      mobile,
      email,
      user_role_type,
      preferred_language,
      is_banned,
      account_deletion_status,
      trust_safety_status,
      ban_reason,
      data_deletion_requested_at,
      avatar_url,
      profile_photo_document_path
    FROM profiles
    WHERE id = v_user_id
  ) p;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_current_user_profile IS
  'Returns the current authenticated users profile. Replaces direct table read in Flutter backend.';
