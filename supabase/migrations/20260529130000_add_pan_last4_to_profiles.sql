-- P0.7: Flutter verification reads/writes pan_last4; column was never added.
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS pan_last4 TEXT;

UPDATE public.profiles
SET pan_last4 = RIGHT(BTRIM(pan_number), 4)
WHERE pan_last4 IS NULL
  AND pan_number IS NOT NULL
  AND LENGTH(BTRIM(pan_number)) >= 4;
