-- Marketplace / call supplier: expose mobile only to authenticated truckers for active marketplace suppliers

CREATE OR REPLACE FUNCTION get_supplier_contact_mobile(p_supplier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND user_role_type = 'trucker'
  ) THEN
    RAISE EXCEPTION 'Trucker role required';
  END IF;

  SELECT jsonb_build_object('id', p.id, 'mobile', NULLIF(BTRIM(p.mobile), ''))
  INTO v_result
  FROM profiles p
  WHERE p.id = p_supplier_id
    AND p.user_role_type = 'supplier'
    AND EXISTS (
      SELECT 1
      FROM loads l
      WHERE l.supplier_id = p_supplier_id
        AND l.status IN ('active', 'assigned_partial')
        AND l.parent_load_id IS NULL
    );

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION get_supplier_contact_mobile(UUID) TO authenticated;
