DROP POLICY IF EXISTS "loads_trucker_select" ON loads;

CREATE POLICY "loads_trucker_select" ON loads FOR SELECT USING (
  status IN ('active', 'assigned_partial')
  AND parent_load_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = auth.uid()
      AND user_role_type = 'trucker'
  )
);
