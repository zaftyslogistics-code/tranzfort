-- P0-7: Deny cross-user direct SELECT on profiles (IDOR / DPDP).
-- Cross-role display continues via SECURITY DEFINER RPCs (get_public_profile, feeds, trips).

DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_select" ON public.profiles;

CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "profiles_admin_select" ON public.profiles
  FOR SELECT
  USING (public.is_admin());

-- Avatar paths for marketplace/chat (no gov ID fields).
CREATE OR REPLACE FUNCTION public.get_profile_avatar_fields(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'avatar_url', p.avatar_url,
    'profile_photo_document_path', p.profile_photo_document_path
  )
  INTO v_result
  FROM public.profiles p
  WHERE p.id = p_user_id;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile_avatar_fields(UUID) TO authenticated;

COMMENT ON FUNCTION public.get_profile_avatar_fields IS
  'Returns avatar_url and profile_photo_document_path only. Used after profiles RLS narrow.';
