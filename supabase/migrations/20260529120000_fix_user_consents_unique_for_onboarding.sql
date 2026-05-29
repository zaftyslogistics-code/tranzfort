-- Fix onboarding profile submit: upsert_current_user_profile records terms with
-- ON CONFLICT (profile_id, consent_type), but only a non-unique index existed.

DELETE FROM public.user_consents stale
USING public.user_consents keep
WHERE stale.profile_id = keep.profile_id
  AND stale.consent_type = keep.consent_type
  AND stale.created_at < keep.created_at;

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_consents_profile_id_consent_type_unique
  ON public.user_consents (profile_id, consent_type);
