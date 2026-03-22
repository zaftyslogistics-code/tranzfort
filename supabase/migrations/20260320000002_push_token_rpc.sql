-- P2-3: RPC to set or clear push_token on the current user's profile.
-- Replaces direct table writes that may bypass RLS.

CREATE OR REPLACE FUNCTION set_push_token(p_token TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE profiles
  SET push_token = p_token
  WHERE id = auth.uid();
END;
$$;
