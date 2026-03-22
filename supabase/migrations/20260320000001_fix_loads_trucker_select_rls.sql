-- P1-1: Fix loads_trucker_select RLS policy — add role check
-- Previously ANY authenticated user could read active loads via this policy.
-- Suppliers could see other suppliers' active loads (data leakage).
-- Now only truckers can use this policy path.

DROP POLICY IF EXISTS "loads_trucker_select" ON loads;

CREATE POLICY "loads_trucker_select" ON loads FOR SELECT USING (
  status IN ('active', 'assigned_partial')
  AND parent_load_id IS NULL
  AND (SELECT user_role_type FROM profiles WHERE id = auth.uid()) = 'trucker'
);
