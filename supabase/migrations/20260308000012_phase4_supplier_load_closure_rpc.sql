CREATE OR REPLACE FUNCTION close_load_filled_outside_app(p_load_id UUID)
RETURNS VOID AS $$
DECLARE
  v_load RECORD;
BEGIN
  SELECT * INTO v_load FROM loads WHERE id = p_load_id FOR UPDATE;
  IF v_load IS NULL THEN RAISE EXCEPTION 'Load not found'; END IF;
  IF v_load.supplier_id != auth.uid() AND NOT is_admin() THEN RAISE EXCEPTION 'Not authorized'; END IF;
  IF v_load.status != 'active' THEN RAISE EXCEPTION 'Load cannot be closed as filled outside app in current state'; END IF;

  UPDATE loads
  SET status = 'filled_outside_app'
  WHERE id = p_load_id;

  UPDATE suppliers
  SET active_loads_count = GREATEST(active_loads_count - 1, 0)
  WHERE id = v_load.supplier_id;

  UPDATE booking_requests
  SET status = 'superseded'
  WHERE load_id = p_load_id AND status = 'submitted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
