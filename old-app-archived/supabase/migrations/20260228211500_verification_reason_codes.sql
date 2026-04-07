-- Structured verification rejection reason codes storage for admin rejection workflow

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS verification_rejection_reason_codes JSONB
DEFAULT '[]'::jsonb;

ALTER TABLE public.trucks
ADD COLUMN IF NOT EXISTS rejection_reason_codes JSONB
DEFAULT '[]'::jsonb;
