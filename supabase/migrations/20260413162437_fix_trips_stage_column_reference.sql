-- Fix trips table column reference - trips has 'stage' not 'status'
-- This fixes "column tr.status does not exist" error

-- Fix get_public_profile to use trips.stage instead of trips.status
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
  
  -- Build final profile with location from profiles.city/state
  select jsonb_build_object(
      'id', p.id,
      'full_name', p.full_name,
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
end;
$$ language plpgsql security definer;

-- Fix get_trip_detail_with_supplier to use trips.stage instead of trips.status
create or replace function get_trip_detail_with_supplier(
    p_trip_id uuid,
    p_trucker_id uuid
)
returns jsonb as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
      'trip', jsonb_build_object(
          'id', t.id,
          'status', t.stage,
          'created_at', t.created_at,
          'started_at', t.started_at,
          'completed_at', t.completed_at
      ),
      'supplier', jsonb_build_object(
          'id', p.id,
          'full_name', p.full_name,
          'mobile', case 
              when p.mobile is not null then 
                  overlay(p.mobile placing '****' from 3 for 4)
              else null
          end,
          'city', p.city,
          'state', p.state,
          'company_name', s.company_name,
          'verification_status', p.verification_status,
          'avg_rating', coalesce(pts.avg_rating, 0),
          'review_count', coalesce(pts.review_count, 0)
      ),
      'load', jsonb_build_object(
          'origin_label', l.origin_label,
          'origin_city', l.origin_city,
          'origin_state', l.origin_state,
          'origin_lat', l.origin_lat,
          'origin_lng', l.origin_lng,
          'destination_label', l.destination_label,
          'destination_city', l.destination_city,
          'destination_state', l.destination_state,
          'destination_lat', l.destination_lat,
          'destination_lng', l.destination_lng,
          'route_distance_km', l.route_distance_km,
          'route_duration_minutes', l.route_duration_minutes,
          'route_snapshot_source', l.route_snapshot_source,
          'material', l.material,
          'pickup_date', l.pickup_date
      ),
      'truck', jsonb_build_object(
          'truck_number', tr.truck_number,
          'body_type', tr.body_type,
          'tyres', tr.tyres
      )
  )
  into v_result
  from trips t
  join loads l on l.id = t.load_id
  join profiles p on p.id = t.supplier_id
  left join suppliers s on s.id = t.supplier_id
  left join profile_trust_scores pts on pts.user_id = t.supplier_id
  left join trucks tr on tr.id = t.truck_id
  where t.id = p_trip_id
  and t.trucker_id = p_trucker_id;
  
  return v_result;
end;
$$ language plpgsql security definer;
