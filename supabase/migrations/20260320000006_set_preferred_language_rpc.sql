-- P3-17: route preferred language updates through RPC (no direct profiles upsert from client)

CREATE OR REPLACE FUNCTION public.set_current_user_preferred_language(
  p_preferred_language TEXT
)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_language TEXT := LOWER(BTRIM(COALESCE(p_preferred_language, '')));
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_language NOT IN ('en', 'hi') THEN
    RAISE EXCEPTION 'Unsupported language. Supported values: en, hi.'
      USING ERRCODE = '22023';
  END IF;

  -- Ensure the profile row exists and respects the existing onboarding upsert logic.
  PERFORM public.upsert_current_user_profile();

  UPDATE public.profiles
  SET preferred_language = v_language,
      updated_at = NOW()
  WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
