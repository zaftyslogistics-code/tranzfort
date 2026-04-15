-- Fix all RPCs to use null for city/state (profiles table may not have these columns)
-- This ensures consistency across all RPCs that reference profile location

-- Fix get_public_profile RPC
create or replace function get_public_profile(
    p_user_id uuid,
    p_viewer_id uuid default null
)
returns jsonb as $$
declare
  v_profile jsonb;
  v_role text;
  v_is_self boolean;
  v_trust_scores jsonb;
  v_role_specific jsonb;
  v_fleet jsonb;
  v_trips_count int;
begin
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
    -- Get fleet for trucker
    select jsonb_agg(
        jsonb_build_object(
            'id', t.id,
            'truck_number', t.truck_number,
            'body_type', t.body_type,
            'tyres', t.tyres,
            'capacity_tonnes', t.capacity_tonnes,
            'status', t.status
        )
    ) into v_fleet
    from trucks t
    where t.owner_id = p_user_id and t.status = 'verified';
    
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
  
  -- Build final profile with location set to null (profiles table may not have city/state columns)
  select jsonb_build_object(
      'id', p.id,
      'full_name', p.full_name,
      'company_name', s.company_name,
      'role', p.user_role_type,
      'verification_status', p.verification_status,
      'location', null,  -- profiles table may not have city/state columns
      'member_since', p.created_at,
      'is_self', v_is_self,
      'trust_scores', v_trust_scores,
      'role_specific', v_role_specific
  ) into v_profile
  from profiles p
  left join suppliers s on s.id = p.id
  where p.id = p_user_id;
  
  return v_profile;
end;
$$ language plpgsql security definer;

-- Fix get_profile_reviews RPC
create or replace function get_profile_reviews(
    p_user_id uuid,
    p_limit int default 5,
    p_offset int default 0
)
returns jsonb as $$
declare
  v_reviews jsonb;
begin
  -- Use a subquery to order the results before aggregating
  select jsonb_agg(
      jsonb_build_object(
          'id', sub.id,
          'reviewed_user_id', sub.reviewed_user_id,
          'reviewer_id', sub.reviewer_id,
          'reviewer_name', sub.full_name,
          'reviewer_role', sub.reviewer_role,
          'reviewer_avg_rating', coalesce(sub.avg_rating, 0),
          'reviewer_review_count', coalesce(sub.review_count, 0),
          'reviewer_location', null,  -- profiles table may not have city/state columns
          'reviewer_member_since', sub.reviewer_created_at,
          'context_type', sub.context_type,
          'context_id', sub.context_id,
          'rating', sub.rating,
          'comment', sub.comment,
          'reply', sub.reply,
          'reply_at', sub.reply_at,
          'created_at', sub.created_at
      )
  ) into v_reviews
  from (
    select r.*, p.full_name, p.created_at as reviewer_created_at, pts.avg_rating, pts.review_count
    from reviews r
    join profiles p on p.id = r.reviewer_id
    left join profile_trust_scores pts on pts.user_id = r.reviewer_id
    where r.reviewed_user_id = p_user_id
    order by r.created_at desc
    limit p_limit offset p_offset
  ) sub;

  return coalesce(v_reviews, '[]'::jsonb);
end;
$$ language plpgsql security definer;
