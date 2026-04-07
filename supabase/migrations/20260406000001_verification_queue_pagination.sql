-- ============================================================================
-- Migration: Verification queue server-side pagination
-- Phase 3-G: Push filtering/sorting/pagination to SQL query with LIMIT/OFFSET
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_verification_queue(TEXT, TEXT, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION public.get_verification_queue(
  p_status_filter TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'created_at',
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  user_role_type TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  rejection_reason TEXT,
  full_name TEXT,
  email TEXT,
  avatar_url TEXT
) AS $$
DECLARE
  v_order_column TEXT;
  v_order_direction TEXT;
  v_sql TEXT;
BEGIN
  -- Validate sort column to prevent SQL injection
  v_order_column := CASE p_sort_by
    WHEN 'created_at' THEN 'created_at'
    WHEN 'updated_at' THEN 'updated_at'
    WHEN 'status' THEN 'status'
    ELSE 'created_at'
  END;
  
  v_order_direction := 'DESC';
  
  v_sql := format(
    'SELECT 
      v.id,
      v.user_id,
      v.user_role_type,
      v.status,
      v.created_at,
      v.updated_at,
      v.rejection_reason,
      p.full_name,
      p.email,
      p.avatar_url
    FROM verification_cases v
    LEFT JOIN profiles p ON p.id = v.user_id
    WHERE ($1 IS NULL OR v.status = $1)
    ORDER BY %I %s
    LIMIT $2 OFFSET $3',
    v_order_column,
    v_order_direction
  );
  
  RETURN QUERY EXECUTE v_sql USING p_status_filter, p_limit, p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also create a count function for pagination metadata
CREATE OR REPLACE FUNCTION public.get_verification_queue_count(
  p_status_filter TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM verification_cases v
  WHERE p_status_filter IS NULL OR v.status = p_status_filter;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_verification_queue(TEXT, TEXT, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_verification_queue_count(TEXT) TO authenticated;

COMMENT ON FUNCTION public.get_verification_queue(TEXT, TEXT, INTEGER, INTEGER) IS 
  'Returns paginated verification queue with profile joins. Replaces client-side pagination.';
COMMENT ON FUNCTION public.get_verification_queue_count(TEXT) IS 
  'Returns total count for pagination metadata.';
