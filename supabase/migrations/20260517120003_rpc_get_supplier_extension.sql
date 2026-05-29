-- P3.4 — RPC to fetch supplier extension data (company name)
-- Replaces direct table read in SupabaseTruckerTripsBackend.fetchSupplierExtension()

CREATE OR REPLACE FUNCTION get_supplier_extension(p_supplier_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT row_to_json(s)::jsonb
  INTO v_result
  FROM (
    SELECT id, company_name
    FROM suppliers
    WHERE id = p_supplier_id
  ) s;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_supplier_extension IS
  'Returns supplier extension data (company name). Replaces direct table read in Flutter backend.';
