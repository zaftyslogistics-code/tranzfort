-- P0-7: Own-profile RPC exposes last4/masked PAN only — never full Aadhaar/PAN or doc paths via this RPC.

CREATE OR REPLACE FUNCTION public.get_current_user_profile()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_result JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT jsonb_build_object(
    'id', p.id,
    'full_name', p.full_name,
    'mobile', p.mobile,
    'email', p.email,
    'user_role_type', p.user_role_type,
    'preferred_language', p.preferred_language,
    'is_banned', p.is_banned,
    'account_deletion_status', p.account_deletion_status,
    'trust_safety_status', p.trust_safety_status,
    'ban_reason', p.ban_reason,
    'data_deletion_requested_at', p.data_deletion_requested_at,
    'avatar_url', p.avatar_url,
    'profile_photo_document_path', p.profile_photo_document_path,
    'city', p.city,
    'state', p.state,
    'verification_status', p.verification_status,
    'aadhaar_last4', p.aadhaar_last4,
    'pan_number_masked', CASE
      WHEN NULLIF(btrim(COALESCE(p.pan_number, '')), '') IS NULL THEN NULL
      ELSE 'XXXXXX' || RIGHT(btrim(p.pan_number), 4)
    END
  )
  INTO v_result
  FROM public.profiles p
  WHERE p.id = v_user_id;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_current_user_profile() TO authenticated;
