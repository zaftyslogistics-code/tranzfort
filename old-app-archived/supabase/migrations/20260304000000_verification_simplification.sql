-- Migration: Verification Simplification
-- Date: 4 March 2026
-- Purpose: Add DL expiry date to truckers table and TAN support for suppliers

-- 1. Add DL expiry date to truckers table
ALTER TABLE public.truckers 
ADD COLUMN IF NOT EXISTS dl_expiry_date DATE;

-- 2. Add TAN support for suppliers (alternative to PAN)
ALTER TABLE public.suppliers 
ADD COLUMN IF NOT EXISTS tan_number VARCHAR(10),
ADD COLUMN IF NOT EXISTS tan_photo_url TEXT;

-- 3. Add index for TAN lookup
CREATE INDEX IF NOT EXISTS idx_suppliers_tan ON public.suppliers(tan_number);

-- 4. Add comments for documentation
COMMENT ON COLUMN public.truckers.dl_expiry_date IS 'Driving license expiry date for trucker verification';
COMMENT ON COLUMN public.suppliers.tan_number IS 'Tax Deduction Account Number (alternative to PAN)';
COMMENT ON COLUMN public.suppliers.tan_photo_url IS 'URL to uploaded TAN card photo';

-- Note: RLS policies remain unchanged as they operate at table level
-- Note: Either PAN or TAN validation will be enforced at application level
