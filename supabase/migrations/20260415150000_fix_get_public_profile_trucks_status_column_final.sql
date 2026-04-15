-- Fix get_public_profile RPC - trucks.status should be trucks.verification_status
-- This migration ensures the fix is applied correctly even if previous migrations had conflicts

CREATE OR REPLACE FUNCTION get_public_profile(
    p_user_id uuid,
    p_viewer_id uuid default null
)
RETURNS jsonb AS $$
DECLARE
  v_profile jsonb;
  v_role text;
  v_is_self boolean;
  v_trust_scores jsonb;
  v_role_specific jsonb;
  v_fleet jsonb;
  v_trips_count int;
  v_avatar_url text;
BEGIN
  -- Check if self
  v_is_self := (p_viewer_id = p_user_id);

  -- Get user role
  select user_role_type into v_role from profiles where id = p_user_id;

  if v_role is null then
    return null;
  end if;

  -- Get trust scores
  select jsonb_build_object(
      'avg_rating', coalesce(pts.avg_rating, 0),
      'review_count', coalesce(pts.review_count, 0)
  ) into v_trust_scores
  from profile_trust_scores pts
  where pts.user_id = p_user_id;

  if v_trust_scores is null then
    v_trust_scores := jsonb_build_object('avg_rating', 0, 'review_count', 0);
  end if;

  -- Get completed trips count (trips has 'stage' column, not 'status')
  select count(*) into v_trips_count
  from trips tr
  where tr.trucker_id = p_user_id and tr.stage = 'completed';

  -- Build role-specific data
  if v_role = 'trucker' then
    -- Get fleet for trucker (FIXED: use verification_status instead of status)
    select jsonb_agg(
        jsonb_build_object(
            'id', t.id,
            'truck_number', t.truck_number,
            'body_type', t.body_type,
            'tyres', t.tyres,
            'capacity_tonnes', t.capacity_tonnes,
            'status', t.verification_status
        )
    ) into v_fleet
    from trucks t
    where t.owner_id = p_user_id and t.verification_status = 'verified';

    v_role_specific := jsonb_build_object(
        'truck_count', coalesce(jsonb_array_length(coalesce(v_fleet, '[]'::jsonb)), 0),
        'fleet', coalesce(v_fleet, '[]'::jsonb),
        'completed_trips_count', v_trips_count
    );
  elsif v_role = 'supplier' then
    -- Get supplier metrics
    select jsonb_build_object(
        'total_loads_posted', coalesce(s.total_loads_posted, 0),
        'active_loads_count', coalesce(s.active_loads_count, 0),
        'is_super_load_eligible', false
    ) into v_role_specific
    from suppliers s
    where s.id = p_user_id;
  end if;

  -- Get avatar URL with fallback to profile_photo_document_path
  select coalesce(p.avatar_url, p.profile_photo_document_path) into v_avatar_url
  from profiles p
  where p.id = p_user_id;

  -- Build final profile with location from profiles.city/state and avatar_url
  select jsonb_build_object(
      'id', p.id,
      'full_name', p.full_name,
      'avatar_url', v_avatar_url,
      'profile_photo_document_path', p.profile_photo_document_path,
      'company_name', s.company_name,
      'role', p.user_role_type,
      'verification_status', p.verification_status,
      'location', nullif(concat_ws(', ', nullif(trim(p.city), ''), nullif(trim(p.state), '')), ''),
      'member_since', p.created_at,
      'is_self', v_is_self,
      'trust_scores', v_trust_scores,
      'role_specific', v_role_specific
  ) into v_profile
  from profiles p
  left join suppliers s on s.id = p.id
  where p.id = p_user_id;

  return v_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
grant execute on function get_public_profile(uuid, uuid) to authenticated;
