-- P2-1: Stop retaining full Aadhaar in profiles; expose masked PAN only via verification RPC.

-- Backfill: drop legacy full Aadhaar when last4 already captured.
UPDATE public.profiles
SET aadhaar_number = NULL
WHERE NULLIF(btrim(aadhaar_last4), '') IS NOT NULL
  AND NULLIF(btrim(aadhaar_number), '') IS NOT NULL
  AND length(btrim(aadhaar_number)) > 4;

-- Normalize legacy full PAN values to masked tail (matches get_current_user_profile).
UPDATE public.profiles
SET pan_number = 'XXXXXX' || RIGHT(btrim(pan_number), 4)
WHERE NULLIF(btrim(pan_number), '') IS NOT NULL
  AND length(btrim(pan_number)) > 4
  AND btrim(pan_number) NOT LIKE 'XXXXXX%';

CREATE OR REPLACE FUNCTION public.get_verification_profile()
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

  SELECT row_to_json(p)::jsonb
  INTO v_result
  FROM (
    SELECT
      id,
      user_role_type,
      verification_status,
      verification_rejection_reason,
      verification_feedback_json,
      aadhaar_last4,
      aadhaar_front_document_path,
      aadhaar_back_document_path,
      pan_last4,
      CASE
        WHEN NULLIF(btrim(COALESCE(pan_last4, '')), '') IS NOT NULL THEN
          'XXXXXX' || btrim(pan_last4)
        WHEN NULLIF(btrim(COALESCE(pan_number, '')), '') IS NULL THEN NULL
        WHEN btrim(pan_number) LIKE 'XXXXXX%' THEN btrim(pan_number)
        ELSE 'XXXXXX' || RIGHT(btrim(pan_number), 4)
      END AS pan_number_masked,
      pan_document_path,
      profile_photo_document_path,
      city,
      state,
      location_lat,
      location_lng,
      location_source
    FROM profiles p
    WHERE p.id = v_user_id
  ) p;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION public.get_verification_profile IS
  'Verification wizard profile for auth user (last4 Aadhaar, masked PAN only — no full ID numbers).';

GRANT EXECUTE ON FUNCTION public.get_verification_profile() TO authenticated;
